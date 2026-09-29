local Players=game:GetService("Players")
local SS=game:GetService("ServerStorage")
local Data=require(script.Parent:WaitForChild("PlayerDataService"))
local library=SS:WaitForChild("WeaponLibrary")
local TOOL_NAME="VB_EquippedWeaponV27"

local PROFILES={
    Bastion_LongSword_01={
        GripPoint=Vector3.new(-0.351921,0.000173,0.000365),
        RightAxis=Vector3.new(0.000011,-0.000047,-1),
        UpAxis=Vector3.new(-1,0.000195,-0.000011),
        Ratio=0.60,Min=3.25,Max=4.05,
    },
    Bastion_Warhammer_01={
        GripPoint=Vector3.new(-0.236239,-0.231890,-0.016489),
        RightAxis=Vector3.new(0.785159,-0.618839,-0.023751),
        UpAxis=Vector3.new(-0.619274,-0.784245,-0.038195),
        Ratio=0.56,Min=3.15,Max=3.95,
    },
    Eclaireur_Spear_01={
        GripPoint=Vector3.new(-0.161430,0.191800,0.228115),
        RightAxis=Vector3.new(0.766347,0.640131,-0.054274),
        UpAxis=Vector3.new(0.462752,-0.608640,-0.644529),
        Ratio=0.82,Min=4.55,Max=5.65,
    },
    Eclaireur_Glaive_01={
        GripPoint=Vector3.new(0.200336,-0.199818,0.000104),
        RightAxis=Vector3.new(0.676175,0.736734,0.003133),
        UpAxis=Vector3.new(-0.736737,0.676180,-0.000399),
        Ratio=0.72,Min=4.00,Max=5.00,
    },
    Arcaniste_Staff_01={
        GripPoint=Vector3.new(0.116950,-0.137063,-0.137338),
        RightAxis=Vector3.new(0.775471,0.614589,-0.144657),
        UpAxis=Vector3.new(-0.381871,0.638997,0.667725),
        Ratio=0.78,Min=4.35,Max=5.45,
    },
    Arcaniste_Scepter_01={
        GripPoint=Vector3.new(0.105363,-0.154260,-0.149286),
        RightAxis=Vector3.new(0.653145,0.688972,-0.314196),
        UpAxis=Vector3.new(-0.319634,0.626995,0.710431),
        Ratio=0.52,Min=2.95,Max=3.75,
    },
    Luminar_Mace_01={
        GripPoint=Vector3.new(-0.000044,0.128129,0.198894),
        RightAxis=Vector3.new(1,0.000376,0.000611),
        UpAxis=Vector3.new(-0.000712,0.620133,0.784496),
        Ratio=0.50,Min=2.90,Max=3.65,
    },
    Luminar_Crozier_01={
        GripPoint=Vector3.new(-0.161238,-0.154306,-0.008960),
        RightAxis=Vector3.new(0.743635,-0.668358,-0.017430),
        UpAxis=Vector3.new(0.668452,0.742713,0.039352),
        Ratio=0.76,Min=4.25,Max=5.30,
    },
}

local ITEMS={
    Bastion_Weapon_1={Class="Bastion",Asset="Bastion_LongSword_01"},
    Bastion_Weapon_2={Class="Bastion",Asset="Bastion_Warhammer_01"},
    Bastion_Weapon_3={Class="Bastion",Asset="Bastion_Warhammer_01"},
    Eclaireur_Weapon_1={Class="Eclaireur",Asset="Eclaireur_Spear_01"},
    Eclaireur_Weapon_2={Class="Eclaireur",Asset="Eclaireur_Glaive_01"},
    Eclaireur_Weapon_3={Class="Eclaireur",Asset="Eclaireur_Glaive_01"},
    Arcaniste_Weapon_1={Class="Arcaniste",Asset="Arcaniste_Staff_01"},
    Arcaniste_Weapon_2={Class="Arcaniste",Asset="Arcaniste_Scepter_01"},
    Arcaniste_Weapon_3={Class="Arcaniste",Asset="Arcaniste_Scepter_01"},
    Luminar_Weapon_1={Class="Luminar",Asset="Luminar_Mace_01"},
    Luminar_Weapon_2={Class="Luminar",Asset="Luminar_Crozier_01"},
    Luminar_Weapon_3={Class="Luminar",Asset="Luminar_Crozier_01"},
}

local lastEquipped={}

local function allParts(object)
    local r={}
    if object:IsA("BasePart") then table.insert(r,object) end
    for _,d in ipairs(object:GetDescendants()) do
        if d:IsA("BasePart") then table.insert(r,d) end
    end
    return r
end

local function firstPart(object)
    if object:IsA("BasePart") then return object end
    return object:FindFirstChildWhichIsA("MeshPart",true)
        or object:FindFirstChildWhichIsA("BasePart",true)
end

local function sizeOf(object)
    return object:IsA("Model") and object:GetExtentsSize()
        or (object:IsA("BasePart") and object.Size or Vector3.one)
end

local function scaleObject(object,factor)
    factor=math.clamp(factor,0.05,20)
    if object:IsA("Model") then
        local current=1
        pcall(function() current=object:GetScale() end)
        object:ScaleTo(current*factor)
    elseif object:IsA("BasePart") then
        object.Size*=factor
    end
end

local function pivotObject(object,cf)
    if object:IsA("Model") then object:PivotTo(cf)
    elseif object:IsA("BasePart") then object.CFrame=cf end
end

local function basis(r,u)
    r=r.Unit
    u=u-r*u:Dot(r)
    if u.Magnitude<0.001 then u=Vector3.yAxis end
    u=u.Unit
    local b=r:Cross(u).Unit
    u=b:Cross(r).Unit
    return r,u,b
end

local function bodyHeight(character)
    local total=0
    for _,name in ipairs({"Head","UpperTorso","LowerTorso","LeftUpperLeg","LeftLowerLeg","LeftFoot"}) do
        local p=character:FindFirstChild(name)
        if p and p:IsA("BasePart") then total+=p.Size.Y end
    end
    if total<4 then total=math.clamp(character:GetExtentsSize().Y,5,7) end
    return math.clamp(total,5,7.5)
end

local function clearWeapon(player)
    local character=player.Character
    if character then
        local tool=character:FindFirstChild(TOOL_NAME)
        if tool then tool:Destroy() end
        local legacy=character:FindFirstChild("VB_Equipment")
        if legacy then legacy:Destroy() end
    end
    local backpack=player:FindFirstChildOfClass("Backpack")
    if backpack then
        local tool=backpack:FindFirstChild(TOOL_NAME)
        if tool then tool:Destroy() end
    end
end

local function sourceFor(item)
    local folder=library:FindFirstChild(item.Class)
    return folder and folder:FindFirstChild(item.Asset)
end

local function makeTool(character,itemId)
    local item=ITEMS[itemId]
    local source=item and sourceFor(item)
    local profile=item and PROFILES[item.Asset]
    if not item or not source or not profile then return nil,"source/profil absent" end

    local tool=Instance.new("Tool")
    tool.Name=TOOL_NAME
    tool.RequiresHandle=true
    tool.CanBeDropped=false
    tool.ManualActivationOnly=true
    tool.ToolTip=itemId
    tool:SetAttribute("VBItemId",itemId)
    tool:SetAttribute("VBAsset",item.Asset)

    local handle=Instance.new("Part")
    handle.Name="Handle"
    handle.Size=Vector3.new(0.16,0.16,0.16)
    handle.Transparency=1
    handle.CanCollide=false
    handle.CanTouch=false
    handle.CanQuery=false
    handle.Massless=true
    handle.Anchored=true
    handle.CFrame=CFrame.new(0,1200,0)
    handle.Parent=tool

    local visual=source:Clone()
    visual.Name="WeaponVisual"
    visual.Parent=tool

    local primary=firstPart(visual)
    if not primary then tool:Destroy(); return nil,"MeshPart absent" end
    if visual:IsA("Model") then visual.PrimaryPart=primary end

    for _,d in ipairs(visual:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
    end

    local parts=allParts(visual)
    for _,part in ipairs(parts) do
        part.Anchored=true
        part.CanCollide=false
        part.CanTouch=false
        part.CanQuery=false
        part.Massless=true
    end

    local s=sizeOf(visual)
    local longest=math.max(s.X,s.Y,s.Z)
    local target=math.clamp(bodyHeight(character)*profile.Ratio,profile.Min,profile.Max)
    local scale=1
    if longest>0.001 then
        scale=target/longest
        scaleObject(visual,scale)
    end

    local right,up,back=basis(profile.RightAxis,profile.UpAxis)
    local grip=CFrame.fromMatrix(profile.GripPoint*scale,right,up,back)
    pivotObject(visual,handle.CFrame*grip:Inverse())

    for _,part in ipairs(allParts(visual)) do
        local weld=Instance.new("WeldConstraint")
        weld.Name="VB_InternalWeaponWeld"
        weld.Part0=handle
        weld.Part1=part
        weld.Parent=handle
    end

    handle.Anchored=false
    for _,part in ipairs(allParts(visual)) do part.Anchored=false end
    return tool
end

local function rightGrip(character,handle)
    local hand=character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if not hand then return nil end
    for _,d in ipairs(hand:GetDescendants()) do
        if (d:IsA("Weld") or d:IsA("Motor6D")) and d.Name=="RightGrip"
            and d.Part0==hand and d.Part1==handle then return d end
    end
    local direct=hand:FindFirstChild("RightGrip")
    if direct and (direct:IsA("Weld") or direct:IsA("Motor6D"))
        and direct.Part0==hand and direct.Part1==handle then return direct end
end

local function validate(player,tool)
    local character=player.Character
    if not character or tool.Parent~=character then return false,"Tool non équipé" end
    local handle=tool:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return false,"Handle absent" end
    if handle.Anchored or handle.CanCollide or not handle.Massless then return false,"Handle physique invalide" end
    if not rightGrip(character,handle) then return false,"RightGrip absent" end

    local hand=character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    local visual=tool:FindFirstChild("WeaponVisual")
    local center
    if visual and visual:IsA("Model") then center=select(1,visual:GetBoundingBox()).Position
    elseif visual and visual:IsA("BasePart") then center=visual.Position end
    if hand and center and (center-hand.Position).Magnitude>9 then
        return false,"arme trop éloignée de la main"
    end

    local root=character:FindFirstChild("HumanoidRootPart")
    if root and root.Anchored then return false,"HumanoidRootPart ancré" end
    for _,d in ipairs(tool:GetDescendants()) do
        if d:IsA("BasePart") and (d.Anchored or d.CanCollide or not d.Massless) then
            return false,"pièce arme physique invalide"
        end
    end
    return true
end

local function equip(player,itemId)
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local backpack=player:FindFirstChildOfClass("Backpack")
    if not character or not humanoid or not backpack or humanoid.Health<=0 then return end

    clearWeapon(player)
    local tool,err=makeTool(character,itemId)
    if not tool then
        warn("[Valbrume Weapon V2.7] Construction impossible :",itemId,err)
        return
    end

    tool.Parent=backpack
    humanoid:EquipTool(tool)

    task.delay(0.35,function()
        if not tool.Parent then return end
        local ok,reason=validate(player,tool)
        if not ok then
            warn("[Valbrume Weapon V2.7] Arme retirée par sécurité :",itemId,reason)
            tool:Destroy()
            return
        end
        tool:SetAttribute("VBValidated",true)
        print("[Valbrume Weapon V2.7] RightGrip validé :",player.Name,itemId)
    end)
end

local function desired(player)
    local p=Data.Get(player)
    local equipment=p and p.Equipment
    local itemId=type(equipment)=="table" and equipment.Weapon or nil
    local item=itemId and ITEMS[itemId]
    if not p or not p.Class or not item or item.Class~=p.Class then return nil end
    return itemId
end

local function refresh(player,force)
    local character=player.Character
    if not character then return end
    local itemId=desired(player)
    if not itemId then
        if force or lastEquipped[player]~=nil then clearWeapon(player); lastEquipped[player]=nil end
        return
    end

    local current=character:FindFirstChild(TOOL_NAME)
    local valid=current and current:GetAttribute("VBItemId")==itemId
        and current:GetAttribute("VBValidated")==true

    if force or lastEquipped[player]~=itemId or not valid then
        equip(player,itemId)
        lastEquipped[player]=itemId
    end
end

local function watch(player)
    player.CharacterAdded:Connect(function() task.wait(1.2); refresh(player,true) end)
    task.spawn(function()
        while player.Parent do task.wait(0.55); refresh(player,false) end
    end)
end

for _,player in ipairs(Players:GetPlayers()) do watch(player) end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(player) lastEquipped[player]=nil end)

print("[Valbrume V2.7] WeaponToolService actif — Tool/Handle/RightGrip natif.")
