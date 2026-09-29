local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local package = game.ReplicatedStorage:WaitForChild("Valbrume")
local C = require(package:WaitForChild("Config"))
local Request = package:WaitForChild("Request")
local State = package:WaitForChild("State")
local Effects = package:WaitForChild("Effects")

local old = playerGui:FindFirstChild("ValbrumeHUD")
if old then old:Destroy() end

local packet
local storyPacket
local target
local selectedZone
local creationStep = 1
local bagSignature = ""
local messageUntil = 0
local lastViewport = Vector2.zero

local Theme = {
    Bg = Color3.fromRGB(18, 24, 34),
    Panel = Color3.fromRGB(28, 37, 51),
    Panel2 = Color3.fromRGB(37, 48, 65),
    Text = Color3.fromRGB(241, 244, 247),
    Muted = Color3.fromRGB(166, 181, 197),
    Gold = Color3.fromRGB(238, 202, 117),
    Red = Color3.fromRGB(216, 79, 92),
    HP = Color3.fromRGB(206, 71, 86),
    Mana = Color3.fromRGB(76, 143, 225),
    Stroke = Color3.fromRGB(87, 104, 126),
}

local function New(className, parent, props)
    local o = Instance.new(className)
    for k, v in pairs(props or {}) do
        o[k] = v
    end
    o.Parent = parent
    return o
end

local function Round(parent, px)
    return New("UICorner", parent, {CornerRadius = UDim.new(0, px or 14)})
end

local function Stroke(parent, transparency)
    return New("UIStroke", parent, {
        Color = Theme.Stroke,
        Transparency = transparency or 0.55,
        Thickness = 1,
    })
end

local function Label(parent, value, size, bold)
    return New("TextLabel", parent, {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = value or "",
        TextColor3 = Theme.Text,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize = size or 14,
        TextWrapped = true,
    })
end

local function Button(parent, value, radius)
    local b = New("TextButton", parent, {
        BackgroundColor3 = Theme.Panel2,
        BorderSizePixel = 0,
        Text = value or "",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextWrapped = true,
        AutoButtonColor = false,
    })
    Round(b, radius or 14)
    Stroke(b, 0.7)

    b.MouseEnter:Connect(function()
        if not UserInputService.TouchEnabled then
            TweenService:Create(b, TweenInfo.new(0.12), {
                BackgroundColor3 = Theme.Panel2:Lerp(Color3.new(1,1,1), 0.08)
            }):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Theme.Panel2}):Play()
    end)
    b.MouseButton1Down:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.06), {Rotation = -0.4}):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.10), {Rotation = 0}):Play()
    end)
    return b
end

local gui = New("ScreenGui", playerGui, {
    Name = "ValbrumeHUD",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
pcall(function()
    gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end)

-- ============================================================
-- HUD JOUEUR
-- ============================================================

local stats = New("Frame", gui, {
    Name = "PlayerCard",
    Position = UDim2.fromOffset(14, 14),
    Size = UDim2.fromOffset(260, 116),
    BackgroundColor3 = Theme.Bg,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
})
Round(stats, 17)
Stroke(stats, 0.5)

local statsHeader = Label(stats, "VALBRUME", 14, true)
statsHeader.Position = UDim2.fromOffset(14, 9)
statsHeader.Size = UDim2.new(1, -28, 0, 22)
statsHeader.TextXAlignment = Enum.TextXAlignment.Left
statsHeader.TextColor3 = Theme.Gold

local statsSub = Label(stats, "Connexion…", 13, true)
statsSub.Position = UDim2.fromOffset(14, 31)
statsSub.Size = UDim2.new(1, -28, 0, 20)
statsSub.TextXAlignment = Enum.TextXAlignment.Left

local function bar(parent, y, color)
    local bg = New("Frame", parent, {
        Position = UDim2.new(0, 14, 0, y),
        Size = UDim2.new(1, -28, 0, 14),
        BackgroundColor3 = Color3.fromRGB(10, 14, 21),
        BorderSizePixel = 0,
    })
    Round(bg, 7)
    local fill = New("Frame", bg, {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    })
    Round(fill, 7)
    local t = Label(bg, "", 10, true)
    t.ZIndex = 3
    t.TextStrokeTransparency = 0.5
    return fill, t
end

local hpFill, hpText = bar(stats, 57, Theme.HP)
local resourceFill, resourceText = bar(stats, 78, Theme.Mana)

local goldText = Label(stats, "Or 0", 12, true)
goldText.Position = UDim2.new(0, 14, 1, -23)
goldText.Size = UDim2.new(1, -28, 0, 16)
goldText.TextXAlignment = Enum.TextXAlignment.Left
goldText.TextColor3 = Theme.Gold

local xpBg = New("Frame", stats, {
    Position = UDim2.new(0, 0, 1, -4),
    Size = UDim2.new(1, 0, 0, 4),
    BackgroundColor3 = Color3.fromRGB(43, 51, 63),
    BorderSizePixel = 0,
})
Round(xpBg, 2)
local xpFill = New("Frame", xpBg, {
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = Theme.Gold,
    BorderSizePixel = 0,
})
Round(xpFill, 2)

-- Boutons secondaires : pilules arrondies.
local quick = New("Frame", gui, {
    Name = "QuickMenu",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -14, 0, 14),
    Size = UDim2.fromOffset(226, 44),
    BackgroundTransparency = 1,
})
local qLayout = New("UIListLayout", quick, {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0, 7),
})

local bagButton = Button(quick, "SAC", 15)
bagButton.Size = UDim2.fromOffset(64, 42)
local questButton = Button(quick, "QUÊTE", 15)
questButton.Size = UDim2.fromOffset(74, 42)
local recallButton = Button(quick, "RAPPEL", 15)
recallButton.Size = UDim2.fromOffset(74, 42)

-- Tracker réduit.
local questCard = New("Frame", gui, {
    Name = "QuestTracker",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -14, 0, 66),
    Size = UDim2.fromOffset(270, 94),
    BackgroundColor3 = Theme.Bg,
    BackgroundTransparency = 0.10,
    BorderSizePixel = 0,
})
Round(questCard, 16)
Stroke(questCard, 0.65)
local questText = Label(questCard, "Aucune quête suivie", 12, false)
questText.Position = UDim2.fromOffset(13, 10)
questText.Size = UDim2.new(1, -26, 1, -20)
questText.TextXAlignment = Enum.TextXAlignment.Left
questText.TextYAlignment = Enum.TextYAlignment.Top

-- Cible : invisible quand aucune cible.
local targetCard = New("Frame", gui, {
    Name = "TargetCard",
    Active = true,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -114),
    Size = UDim2.fromOffset(300, 50),
    BackgroundColor3 = Theme.Bg,
    BackgroundTransparency = 0.06,
    BorderSizePixel = 0,
    Visible = false,
})
Round(targetCard, 17)
Stroke(targetCard, 0.55)
local targetName = Label(targetCard, "", 13, true)
targetName.Position = UDim2.fromOffset(12, 5)
targetName.Size = UDim2.new(1, -24, 0, 19)
targetName.TextXAlignment = Enum.TextXAlignment.Left
local targetHpBg = New("Frame", targetCard, {
    Position = UDim2.fromOffset(12, 29),
    Size = UDim2.new(1, -24, 0, 11),
    BackgroundColor3 = Color3.fromRGB(12, 15, 21),
    BorderSizePixel = 0,
})
Round(targetHpBg, 6)
local targetHpFill = New("Frame", targetHpBg, {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Theme.HP,
    BorderSizePixel = 0,
})
Round(targetHpFill, 6)

-- Barre de compétences mobile : gros boutons centraux.
local abilityBar = New("Frame", gui, {
    Name = "AbilityBar",
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -22),
    Size = UDim2.fromOffset(310, 74),
    BackgroundTransparency = 1,
})
local abilityLayout = New("UIListLayout", abilityBar, {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 8),
})

local abilityButtons = {}
local abilityNames = {}
local abilityCosts = {}
local abilityCooldowns = {}

for i = 1, 4 do
    local b = Button(abilityBar, "", 18)
    b.Name = "Ability" .. i
    b.Size = UDim2.fromOffset(70, 70)

    local slot = Label(b, tostring(i), 10, true)
    slot.Position = UDim2.fromOffset(8, 5)
    slot.Size = UDim2.fromOffset(16, 15)
    slot.TextXAlignment = Enum.TextXAlignment.Left
    slot.TextColor3 = Theme.Muted

    local name = Label(b, "...", 11, true)
    name.Position = UDim2.fromOffset(4, 21)
    name.Size = UDim2.new(1, -8, 0, 27)

    local cost = Label(b, "", 9, false)
    cost.Position = UDim2.new(0, 4, 1, -18)
    cost.Size = UDim2.new(1, -8, 0, 14)
    cost.TextColor3 = Theme.Muted

    local cd = Label(b, "", 22, true)
    cd.BackgroundColor3 = Color3.fromRGB(9, 12, 18)
    cd.BackgroundTransparency = 0.17
    cd.Visible = false
    cd.ZIndex = 8
    Round(cd, 18)

    abilityButtons[i] = b
    abilityNames[i] = name
    abilityCosts[i] = cost
    abilityCooldowns[i] = cd
end

-- Cast bar.
local castCard = New("Frame", gui, {
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -169),
    Size = UDim2.fromOffset(280, 28),
    BackgroundColor3 = Theme.Bg,
    BorderSizePixel = 0,
    Visible = false,
})
Round(castCard, 13)
Stroke(castCard, 0.65)
local castFill = New("Frame", castCard, {
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = Color3.fromRGB(91, 128, 188),
    BorderSizePixel = 0,
})
Round(castFill, 13)
local castText = Label(castCard, "", 12, true)
castText.ZIndex = 4

local message = Label(gui, "", 16, true)
message.AnchorPoint = Vector2.new(0.5, 0)
message.Position = UDim2.new(0.5, 0, 0, 90)
message.Size = UDim2.new(0.72, 0, 0, 48)
message.TextColor3 = Theme.Gold
message.TextStrokeTransparency = 0.3
message.Visible = false
message.ZIndex = 90

-- Dialogue narratif V2.3B (reste caché si StoryService absent).
local dialogueCard = New("Frame", gui, {
    Name = "DialogueCard",
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -185),
    Size = UDim2.new(0.72, 0, 0, 118),
    BackgroundColor3 = Theme.Bg,
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 70,
})
Round(dialogueCard, 20)
Stroke(dialogueCard, 0.38)

local dialogueSpeaker = Label(dialogueCard, "", 14, true)
dialogueSpeaker.Position = UDim2.fromOffset(16, 11)
dialogueSpeaker.Size = UDim2.new(1, -118, 0, 22)
dialogueSpeaker.TextXAlignment = Enum.TextXAlignment.Left
dialogueSpeaker.TextColor3 = Theme.Gold

local dialogueBody = Label(dialogueCard, "", 13, false)
dialogueBody.Position = UDim2.fromOffset(16, 37)
dialogueBody.Size = UDim2.new(1, -32, 1, -50)
dialogueBody.TextXAlignment = Enum.TextXAlignment.Left
dialogueBody.TextYAlignment = Enum.TextYAlignment.Top

local dialogueClose = Button(dialogueCard, "CONTINUER", 13)
dialogueClose.AnchorPoint = Vector2.new(1, 0)
dialogueClose.Position = UDim2.new(1, -12, 0, 10)
dialogueClose.Size = UDim2.fromOffset(96, 30)
dialogueClose.TextSize = 10
dialogueClose.ZIndex = 72
dialogueClose.Activated:Connect(function() dialogueCard.Visible = false end)

-- ============================================================
-- SAC
-- ============================================================

local dim = New("Frame", gui, {
    Name = "ModalDim",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0,0,0),
    BackgroundTransparency = 0.38,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 40,
})

local bag = New("Frame", dim, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(460, 365),
    BackgroundColor3 = Theme.Bg,
    BorderSizePixel = 0,
    ZIndex = 41,
})
Round(bag, 21)
Stroke(bag, 0.4)

local bagTitle = Label(bag, "ÉQUIPEMENT", 17, true)
bagTitle.Position = UDim2.fromOffset(16, 12)
bagTitle.Size = UDim2.new(1, -70, 0, 28)
bagTitle.TextXAlignment = Enum.TextXAlignment.Left
bagTitle.TextColor3 = Theme.Gold

local bagClose = Button(bag, "×", 14)
bagClose.Position = UDim2.new(1, -50, 0, 10)
bagClose.Size = UDim2.fromOffset(38, 34)
bagClose.TextSize = 20

local bagList = New("ScrollingFrame", bag, {
    Position = UDim2.fromOffset(14, 54),
    Size = UDim2.new(1, -28, 1, -68),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.fromOffset(0,0),
    ZIndex = 42,
})
New("UIListLayout", bagList, {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

-- ============================================================
-- CRÉATION : ÉTAPE 1 ZONE, ÉTAPE 2 CLASSE
-- ============================================================

local creation = New("Frame", gui, {
    Name = "CharacterCreation",
    Size = UDim2.fromScale(1,1),
    BackgroundColor3 = Color3.fromRGB(8, 13, 21),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    ZIndex = 100,
})

local creationCard = New("Frame", creation, {
    AnchorPoint = Vector2.new(0.5,0.5),
    Position = UDim2.fromScale(0.5,0.5),
    Size = UDim2.fromOffset(640, 430),
    BackgroundColor3 = Theme.Bg,
    BorderSizePixel = 0,
    ZIndex = 101,
})
Round(creationCard, 24)
Stroke(creationCard, 0.35)

local creationTitle = Label(creationCard, "VALBRUME", 24, true)
creationTitle.Position = UDim2.fromOffset(20, 15)
creationTitle.Size = UDim2.new(1, -40, 0, 36)
creationTitle.TextColor3 = Theme.Gold

local creationSub = Label(creationCard, "Choisis ton origine", 14, false)
creationSub.Position = UDim2.fromOffset(20, 53)
creationSub.Size = UDim2.new(1, -40, 0, 26)
creationSub.TextColor3 = Theme.Muted

local zoneStep = New("Frame", creationCard, {
    Position = UDim2.fromOffset(20, 88),
    Size = UDim2.new(1, -40, 1, -108),
    BackgroundTransparency = 1,
    ZIndex = 102,
})

local zoneCards = {}
local zoneDescriptions = {
    A2 = "Vigiles d'Astréa — Elyndra\nVallées • forêts • ruines • brume",
    H2 = "Lignées de Khar — Varkhûn\nCendres • canyons • forges • basalte",
}

for index, zoneId in ipairs({"A2", "H2"}) do
    local zone = C.Zones[zoneId]
    local b = Button(zoneStep, zoneDescriptions[zoneId], 21)
    b.Name = "Zone" .. zoneId
    b.Position = UDim2.new((index-1)*0.5, index == 1 and 0 or 7, 0, 0)
    b.Size = UDim2.new(0.5, -7, 0, 210)
    b.TextColor3 = zone.Color
    b.TextSize = 17
    b.ZIndex = 103

    local code = Label(b, zoneId, 34, true)
    code.Position = UDim2.fromOffset(12, 12)
    code.Size = UDim2.new(1, -24, 0, 45)
    code.TextColor3 = zone.Color
    code.TextTransparency = 0.35

    zoneCards[zoneId] = b
end

local continueButton = Button(zoneStep, "CONTINUER", 17)
continueButton.AnchorPoint = Vector2.new(0.5,1)
continueButton.Position = UDim2.new(0.5,0,1,-8)
continueButton.Size = UDim2.fromOffset(220, 48)
continueButton.BackgroundColor3 = Theme.Gold
continueButton.TextColor3 = Theme.Bg
continueButton.Visible = false
continueButton.ZIndex = 104

local classStep = New("Frame", creationCard, {
    Position = UDim2.fromOffset(20, 88),
    Size = UDim2.new(1, -40, 1, -108),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 102,
})

local classGrid = New("Frame", classStep, {
    Size = UDim2.new(1,0,1,-58),
    BackgroundTransparency = 1,
    ZIndex = 103,
})
New("UIGridLayout", classGrid, {
    CellPadding = UDim2.fromOffset(10, 10),
    CellSize = UDim2.new(0.5, -5, 0.5, -5),
    FillDirectionMaxCells = 2,
    SortOrder = Enum.SortOrder.LayoutOrder,
})

for index, classId in ipairs(C.ClassOrder) do
    local class = C.Classes[classId]
    local b = Button(classGrid, class.Name .. "\n" .. class.Description, 19)
    b.LayoutOrder = index
    b.TextColor3 = class.Color
    b.TextSize = 14
    b.ZIndex = 104
    b.Activated:Connect(function()
        if selectedZone and packet and not packet.Class then
            Request:FireServer("ChooseClass", classId)
        end
    end)
end

local backButton = Button(classStep, "← CHANGER DE TERRITOIRE", 15)
backButton.AnchorPoint = Vector2.new(0,1)
backButton.Position = UDim2.new(0,0,1,-2)
backButton.Size = UDim2.fromOffset(210, 42)
backButton.ZIndex = 104

local function selectZone(zoneId)
    selectedZone = zoneId
    for id, b in pairs(zoneCards) do
        local selected = id == zoneId
        TweenService:Create(b, TweenInfo.new(0.16), {
            BackgroundColor3 = selected
                and C.Zones[id].Color:Lerp(Theme.Panel, 0.64)
                or Theme.Panel2,
        }):Play()
    end
    continueButton.Visible = true
end

for zoneId, b in pairs(zoneCards) do
    local id = zoneId
    b.Activated:Connect(function()
        selectZone(id)
    end)
end

continueButton.Activated:Connect(function()
    if not selectedZone then return end
    Request:FireServer("ChooseZone", selectedZone)
    creationStep = 2
    zoneStep.Visible = false
    classStep.Visible = true
    creationSub.Text = "Choisis ta classe — " .. C.Zones[selectedZone].Short
end)

backButton.Activated:Connect(function()
    creationStep = 1
    classStep.Visible = false
    zoneStep.Visible = true
    creationSub.Text = "Choisis ton origine"
end)

-- ============================================================
-- CIBLE / INPUT / COMBAT
-- ============================================================

local fxFolder = Instance.new("Folder")
fxFolder.Name = "VB_ClientEffects_V23"
fxFolder.Parent = workspace

local highlight = Instance.new("Highlight")
highlight.Name = "VB_Target"
highlight.FillTransparency = 0.90
highlight.OutlineColor = Theme.Gold
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Enabled = false
highlight.Parent = fxFolder

local markerPart = Instance.new("Part")
markerPart.Name = "QuestMarker"
markerPart.Size = Vector3.one
markerPart.Anchored = true
markerPart.Transparency = 1
markerPart.CanCollide = false
markerPart.CanQuery = false
markerPart.CanTouch = false
markerPart.Parent = fxFolder

local markerGui = New("BillboardGui", markerPart, {
    Adornee = markerPart,
    Size = UDim2.fromOffset(165, 43),
    AlwaysOnTop = true,
    MaxDistance = 900,
    Enabled = false,
})
local markerText = Label(markerGui, "", 13, true)
markerText.TextColor3 = Theme.Gold
markerText.TextStrokeTransparency = 0.3

local function showMessage(value)
    message.Text = tostring(value)
    message.Visible = true
    messageUntil = os.clock() + 4
end

local function enemyFolder()
    local world = workspace:FindFirstChild("ValbrumeWorld")
    return world and world:FindFirstChild("Enemies")
end

local function sameInstance(model)
    local myDungeon = player:GetAttribute("VBDungeonId")
    local enemyDungeon = model:GetAttribute("DungeonId")
    if myDungeon then
        return enemyDungeon == myDungeon
    end
    return enemyDungeon == nil
end

local function validTarget(model)
    local folder = enemyFolder()
    if not folder or not model or model.Parent ~= folder or not sameInstance(model) then
        return false
    end
    local h = model:FindFirstChildOfClass("Humanoid")
    local r = model:FindFirstChild("HumanoidRootPart")
    return h ~= nil and r ~= nil and h.Health > 0
end

local function setTarget(model)
    target = validTarget(model) and model or nil
    highlight.Adornee = target
    highlight.Enabled = target ~= nil
end

local function cycleTarget()
    local folder = enemyFolder()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not folder or not root then return setTarget(nil) end

    local candidates = {}
    for _, model in ipairs(folder:GetChildren()) do
        if validTarget(model) then
            local d = (model.HumanoidRootPart.Position - root.Position).Magnitude
            if d <= 105 then
                table.insert(candidates, {Model=model, Distance=d})
            end
        end
    end
    table.sort(candidates, function(a,b) return a.Distance < b.Distance end)
    if #candidates == 0 then return setTarget(nil) end

    local chosen = 1
    for i, item in ipairs(candidates) do
        if item.Model == target then
            chosen = i % #candidates + 1
            break
        end
    end
    setTarget(candidates[chosen].Model)
end

local function useAbility(index)
    if not packet or not packet.Class then return end
    local skill = C.Classes[packet.Class].Skills[index]
    if skill.Effect == "Damage" and not validTarget(target) then
        cycleTarget()
    end
    Request:FireServer("Ability", index, target)
end

for i, b in ipairs(abilityButtons) do
    local slot = i
    b.Activated:Connect(function() useAbility(slot) end)
end

targetCard.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        cycleTarget()
    end
end)

local function selectAt(pos)
    if creation.Visible or dim.Visible then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local ray = camera:ScreenPointToRay(pos.X, pos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = player.Character and {player.Character, fxFolder} or {fxFolder}
    local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
    if not result then return end
    local folder = enemyFolder()
    local obj = result.Instance
    while obj and obj ~= workspace do
        if obj:IsA("Model") and obj.Parent == folder then
            setTarget(obj)
            return
        end
        obj = obj.Parent
    end
end

local keySlots = {
    [Enum.KeyCode.One]=1,
    [Enum.KeyCode.Two]=2,
    [Enum.KeyCode.Three]=3,
    [Enum.KeyCode.Four]=4,
}

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        selectAt(UserInputService:GetMouseLocation())
        return
    end
    local slot = keySlots[input.KeyCode]
    if slot then
        useAbility(slot)
    elseif input.KeyCode == Enum.KeyCode.I then
        dim.Visible = not dim.Visible
    elseif input.KeyCode == Enum.KeyCode.J then
        questCard.Visible = not questCard.Visible
    elseif input.KeyCode == Enum.KeyCode.R then
        Request:FireServer("Recall")
    end
end)

UserInputService.TouchTapInWorld:Connect(function(pos, processed)
    if not processed then selectAt(pos) end
end)

ContextActionService:BindActionAtPriority(
    "ValbrumeTargetCycleV23",
    function(_, state)
        if state == Enum.UserInputState.Begin then cycleTarget() end
        return Enum.ContextActionResult.Sink
    end,
    false,
    3000,
    Enum.KeyCode.Tab
)

-- ============================================================
-- SAC / QUÊTES
-- ============================================================

local function renderBag()
    if not packet then return end
    local ids = {}
    for id, owned in pairs(packet.Inventory or {}) do
        if owned and C.Items[id] then table.insert(ids, id) end
    end
    table.sort(ids, function(a,b)
        local x, y = C.Items[a], C.Items[b]
        if x.Level == y.Level then return a < b end
        return x.Level < y.Level
    end)

    local sig = table.concat(ids,"|") .. tostring(packet.Equipment and packet.Equipment.Weapon)
        .. tostring(packet.Equipment and packet.Equipment.Armor) .. tostring(packet.Level)
    if sig == bagSignature then return end
    bagSignature = sig

    for _, child in ipairs(bagList:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    for index, id in ipairs(ids) do
        local itemId = id
        local item = C.Items[id]
        local equipped = packet.Equipment and packet.Equipment[item.Slot] == id
        local line = string.format(
            "%s%s   •   Niv. %d\nPuissance +%d   PV +%d   Armure +%d",
            equipped and "✓ " or "",
            item.Name,
            item.Level,
            item.Power,
            item.Health,
            item.Armor
        )
        local b = Button(bagList, line, 15)
        b.Size = UDim2.new(1, -5, 0, 62)
        b.LayoutOrder = index
        b.TextSize = 12
        if equipped then b.TextColor3 = Theme.Gold end
        if item.Level > (packet.Level or 1) then b.TextColor3 = Theme.Muted end
        b.Activated:Connect(function()
            Request:FireServer("Equip", itemId)
        end)
    end
end

bagButton.Activated:Connect(function()
    dim.Visible = true
    renderBag()
end)
bagClose.Activated:Connect(function() dim.Visible = false end)
dim.InputBegan:Connect(function(input)
    -- Le clic hors carte est volontairement ignoré sur mobile pour éviter les fermetures accidentelles.
end)
questButton.Activated:Connect(function() questCard.Visible = not questCard.Visible end)
recallButton.Activated:Connect(function() Request:FireServer("Recall") end)

-- Support StoryService V2.3B.
local function connectStoryRemote(storyRemote)
    if not storyRemote or storyRemote:GetAttribute("VBConnected") then return end
    storyRemote:SetAttribute("VBConnected", true)
    storyRemote.OnClientEvent:Connect(function(kind, value)
        if kind == "State" then
            storyPacket = value
        elseif kind == "Dialogue" then
            if type(value) == "table" then
                dialogueSpeaker.Text = value.Speaker or "Valbrume"
                dialogueBody.Text = value.Text or ""
                dialogueCard.Visible = true
            elseif type(value) == "string" then
                dialogueSpeaker.Text = "Valbrume"
                dialogueBody.Text = value
                dialogueCard.Visible = true
            end
        elseif kind == "Toast" then
            showMessage(value)
        end
    end)
    storyRemote:FireServer("Sync")
end

connectStoryRemote(package:FindFirstChild("StoryRemoteV23"))
package.ChildAdded:Connect(function(child)
    if child.Name == "StoryRemoteV23" and child:IsA("RemoteEvent") then
        connectStoryRemote(child)
    end
end)

-- ============================================================
-- STATE SERVEUR / EFFETS
-- ============================================================

local appliedZone
local colorEffect = Lighting:FindFirstChild("ValbrumeZoneColorV23")
if not colorEffect then
    colorEffect = Instance.new("ColorCorrectionEffect")
    colorEffect.Name = "ValbrumeZoneColorV23"
    colorEffect.Parent = Lighting
end

local function applyEnvironment(zoneId)
    if not zoneId or appliedZone == zoneId or not C.Zones[zoneId] then return end
    appliedZone = zoneId
    local z = C.Zones[zoneId]
    Lighting.ClockTime = z.ClockTime
    Lighting.Brightness = 2
    Lighting.Ambient = z.Ambient
    Lighting.OutdoorAmbient = z.OutdoorAmbient
    Lighting.FogColor = z.FogColor
    Lighting.FogStart = 180
    Lighting.FogEnd = 580
    if zoneId == "A2" then
        colorEffect.TintColor = Color3.fromRGB(226,246,239)
        colorEffect.Saturation = 0.04
        colorEffect.Contrast = 0.03
    else
        colorEffect.TintColor = Color3.fromRGB(255,221,193)
        colorEffect.Saturation = -0.02
        colorEffect.Contrast = 0.07
    end
end

State.OnClientEvent:Connect(function(kind, value)
    if kind == "Message" then
        showMessage(value)
        return
    end
    if kind ~= "State" or type(value) ~= "table" then return end

    packet = value
    if packet.Zone then
        selectedZone = packet.Zone
        applyEnvironment(packet.Zone)
    end

    creation.Visible = not (packet.Zone and packet.Class)
    if packet.Zone and not packet.Class and creationStep == 1 then
        selectZone(packet.Zone)
    end

    if packet.Class then
        local class = C.Classes[packet.Class]
        for i, skill in ipairs(class.Skills) do
            abilityNames[i].Text = skill.Name
            abilityCosts[i].Text = skill.Cost == 0 and "GRATUIT" or tostring(skill.Cost) .. " " .. class.Resource
        end
    end

    if dim.Visible then renderBag() end
end)

local function effectPart()
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Material = Enum.Material.Neon
    p.CastShadow = false
    p.Parent = fxFolder
    return p
end

Effects.OnClientEvent:Connect(function(info)
    if #fxFolder:GetChildren() > 130 then return end

    if info.Kind == "Bolt" then
        local p = effectPart()
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(0.7,0.7,0.7)
        p.Position = info.Position
        p.Color = info.Color
        TweenService:Create(p, TweenInfo.new(0.16), {Position=info.Target, Transparency=1}):Play()
        Debris:AddItem(p,0.22)

    elseif info.Kind == "Hit" then
        local anchor = effectPart()
        anchor.Transparency = 1
        anchor.Size = Vector3.one
        anchor.Position = info.Position
        local bb = New("BillboardGui", anchor, {
            Adornee=anchor,
            Size=UDim2.fromOffset(100,45),
            AlwaysOnTop=true,
        })
        local amount = Label(bb, (info.Healing and "+" or "-") .. tostring(info.Amount), 22, true)
        amount.TextColor3 = info.Color
        amount.TextStrokeTransparency = 0.3
        TweenService:Create(anchor,TweenInfo.new(0.75),{Position=info.Position+Vector3.new(0,3,0)}):Play()
        TweenService:Create(amount,TweenInfo.new(0.75),{TextTransparency=1,TextStrokeTransparency=1}):Play()
        Debris:AddItem(anchor,0.8)

    elseif info.Kind == "Ring" or info.Kind == "Warning" then
        local p = effectPart()
        p.Shape = Enum.PartType.Cylinder
        p.Size = Vector3.new(0.15, info.Radius*2, info.Radius*2)
        p.CFrame = CFrame.new(info.Position) * CFrame.Angles(0,0,math.pi/2)
        p.Color = info.Color
        p.Transparency = info.Kind == "Warning" and 0.42 or 0.72
        if info.Kind == "Ring" then
            TweenService:Create(p,TweenInfo.new(info.Duration),{Transparency=1}):Play()
        end
        Debris:AddItem(p,info.Duration)
    end
end)

-- ============================================================
-- RESPONSIVE
-- ============================================================

local function layout()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local size = camera.ViewportSize
    if size == lastViewport then return end
    lastViewport = size

    local small = size.X < 760
    local tiny = size.X < 600

    stats.Size = UDim2.fromOffset(tiny and 190 or (small and 215 or 260), small and 108 or 116)
    statsHeader.TextSize = tiny and 11 or 14
    statsSub.TextSize = tiny and 11 or 13

    questCard.Size = UDim2.fromOffset(tiny and 210 or 270, tiny and 80 or 94)
    questText.TextSize = tiny and 10 or 12

    local abilitySize = tiny and 58 or (small and 64 or 70)
    local gap = tiny and 5 or 8
    abilityLayout.Padding = UDim.new(0, gap)
    abilityBar.Size = UDim2.fromOffset(abilitySize*4 + gap*3 + 8, abilitySize + 4)
    for _, b in ipairs(abilityButtons) do
        b.Size = UDim2.fromOffset(abilitySize, abilitySize)
    end
    local abilityBottom = UserInputService.TouchEnabled and size.Y > size.X and 150 or 22
    abilityBar.Position = UDim2.new(0.5, 0, 1, -abilityBottom)
    targetCard.Position = UDim2.new(0.5,0,1,-(abilitySize + abilityBottom + 20))
    castCard.Position = UDim2.new(0.5,0,1,-(abilitySize + abilityBottom + 77))

    creationCard.Size = UDim2.fromOffset(
        math.min(640, size.X - 28),
        math.min(430, size.Y - 30)
    )

    bag.Size = UDim2.fromOffset(
        math.min(460, size.X - 30),
        math.min(365, size.Y - 40)
    )

    if tiny then
        quick.Size = UDim2.fromOffset(190, 40)
        bagButton.Size = UDim2.fromOffset(52, 38)
        questButton.Size = UDim2.fromOffset(62, 38)
        recallButton.Size = UDim2.fromOffset(66, 38)
    else
        quick.Size = UDim2.fromOffset(226, 44)
        bagButton.Size = UDim2.fromOffset(64, 42)
        questButton.Size = UDim2.fromOffset(74, 42)
        recallButton.Size = UDim2.fromOffset(74, 42)
    end
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(layout)
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
end
layout()

-- ============================================================
-- RENDER LOOP
-- ============================================================

RunService.RenderStepped:Connect(function()
    if message.Visible and os.clock() > messageUntil then message.Visible = false end
    if not packet or not packet.Class or not packet.Zone then return end

    local class = C.Classes[packet.Class]
    local zone = C.Zones[packet.Zone]
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local hp = humanoid and humanoid.Health or packet.Health or 0
    local maxHp = math.max(1, packet.MaxHealth or 1)

    statsHeader.Text = zone.Short
    statsSub.Text = class.Name .. "   •   Niv. " .. tostring(packet.Level or 1)
    hpFill.Size = UDim2.fromScale(math.clamp(hp/maxHp,0,1),1)
    hpText.Text = string.format("PV  %d / %d", math.ceil(hp), maxHp)
    resourceFill.Size = UDim2.fromScale(math.clamp((packet.Mana or 0)/100,0,1),1)
    resourceFill.BackgroundColor3 = class.Color:Lerp(Theme.Mana,0.35)
    resourceText.Text = class.Resource .. "  " .. math.floor(packet.Mana or 0) .. " / 100"
    goldText.Text = "Or  " .. tostring(packet.Gold or 0)
    xpFill.Size = UDim2.fromScale(
        (packet.Level or 1) >= C.MaxLevel and 1
        or math.clamp((packet.XP or 0)/math.max(1,packet.NextXP or 1),0,1),
        1
    )

    local time = workspace:GetServerTimeNow()
    for i=1,4 do
        local remaining = math.max(
            0,
            ((packet.Cooldowns and packet.Cooldowns[i]) or 0)-time,
            (packet.GCD or 0)-time,
            (packet.CastEnd or 0)-time
        )
        abilityCooldowns[i].Visible = remaining > 0.05
        abilityCooldowns[i].Text = remaining > 0.05 and string.format("%.1f",remaining) or ""
    end

    castCard.Visible = (packet.CastEnd or 0) > time
    if castCard.Visible then
        local duration = math.max(0.01,(packet.CastEnd or 0)-(packet.CastStart or 0))
        local progress = math.clamp((time-(packet.CastStart or 0))/duration,0,1)
        castFill.Size = UDim2.fromScale(progress,1)
        castText.Text = packet.CastName or "Incantation"
    end

    if target and not validTarget(target) then setTarget(nil) end
    targetCard.Visible = target ~= nil
    if target then
        local h = target:FindFirstChildOfClass("Humanoid")
        local def = C.Mobs[target:GetAttribute("MobId")]
        targetName.Text = def and def.Name or target.Name
        targetHpFill.Size = UDim2.fromScale(math.clamp(h.Health/math.max(1,h.MaxHealth),0,1),1)
    end

    -- Story V2.3B prend priorité sur les anciennes quêtes.
    if storyPacket then
        questText.Text = (storyPacket.Title or "VALBRUME")
            .. "\n" .. (storyPacket.ObjectiveText or "")
            .. (storyPacket.ProgressText and ("\n" .. storyPacket.ProgressText) or "")
        if storyPacket.Active and storyPacket.Goal and root then
            local goal = storyPacket.Goal
            local distance = math.floor((root.Position-goal).Magnitude)
            markerPart.Position = goal + Vector3.new(0,8,0)
            markerText.Text = "◇ " .. (storyPacket.GoalLabel or "Objectif") .. "\n" .. distance .. " studs"
            markerGui.Enabled = distance > 10
        else
            markerGui.Enabled = false
        end
    else
        local quest = C.Quests[packet.QuestIndex]
        if quest then
            if not packet.QuestActive then
                questText.Text = "PROCHAINE MISSION\nParle au donneur de quête.\n" .. quest.Name
            else
                questText.Text = quest.Name .. "\n" .. quest.Description
                    .. "\n" .. tostring(packet.QuestProgress or 0) .. "/" .. tostring(quest.Count)
            end

            if root then
                local returnToNPC = not packet.QuestActive or (packet.QuestProgress or 0) >= quest.Count
                local localGoal = returnToNPC and C.NoraPosition or quest.Goal
                local goal = zone.Origin + localGoal
                local distance = math.floor((root.Position-goal).Magnitude)
                markerPart.Position = goal + Vector3.new(0,8,0)
                markerText.Text = "◇ " .. (returnToNPC and "PNJ" or "Objectif") .. "\n" .. distance .. " studs"
                markerGui.Enabled = distance > 10
            end
        else
            questText.Text = "EXPÉDITION TERMINÉE\nExplore librement ou lance le donjon."
            markerGui.Enabled = false
        end
    end
end)

-- Désactivation du HUD Roblox standard.
task.spawn(function()
    for _=1,6 do
        local ok = pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,false)
        end)
        if ok then break end
        task.wait(0.8)
    end
end)

-- Demande un état initial.
task.spawn(function()
    for _=1,12 do
        Request:FireServer("Sync")
        if packet then return end
        task.wait(1.5)
    end
    showMessage("Pas de réponse serveur : regarde Output dans Studio.")
end)
