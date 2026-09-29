local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local StarterGui=game:GetService("StarterGui")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local package=RS:WaitForChild("Valbrume")
local C=require(package:WaitForChild("Config"))
local Request=package:WaitForChild("Request")
local State=package:WaitForChild("State")
local JournalRemote=package:WaitForChild("JournalSyncRemoteV27")
local StoryRemote=package:FindFirstChild("StoryRemoteV23")
local ExpansionRemote=package:FindFirstChild("ExpansionStoryRemoteV26")
local PartyRemote=package:FindFirstChild("PartyRemote")

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)

local T={
    Bg=Color3.fromRGB(15,20,29),Panel=Color3.fromRGB(24,31,43),
    Panel2=Color3.fromRGB(33,43,58),Text=Color3.fromRGB(239,243,247),
    Muted=Color3.fromRGB(155,171,189),Gold=Color3.fromRGB(234,199,118),
    Green=Color3.fromRGB(102,193,137),Blue=Color3.fromRGB(99,159,220),
    Purple=Color3.fromRGB(177,126,226),Stroke=Color3.fromRGB(84,103,126),
}
local Rarity={
    [1]={Name="Commun",Color=Color3.fromRGB(210,216,223)},
    [2]={Name="Inhabituel",Color=Color3.fromRGB(105,206,133)},
    [3]={Name="Rare",Color=Color3.fromRGB(101,154,233)},
}
local WeaponNames={
    Bastion_Weapon_1="Lame du Veilleur",Bastion_Weapon_2="Marteau des Marches",
    Bastion_Weapon_3="Marteau runique de l'Écho",
    Eclaireur_Weapon_1="Lance des Sentiers",Eclaireur_Weapon_2="Glaive lunaire",
    Eclaireur_Weapon_3="Glaive de résonance",
    Arcaniste_Weapon_1="Bâton d'Astréa",Arcaniste_Weapon_2="Sceptre d'Archimage",
    Arcaniste_Weapon_3="Sceptre de l'Écho",
    Luminar_Weapon_1="Masse du pèlerin",Luminar_Weapon_2="Crosse du Luminar",
    Luminar_Weapon_3="Crosse astrale",
}
local ArmorNames={
    Bastion={"Harnois du Veilleur","Cuirasse des Marches","Armure runique"},
    Eclaireur={"Tenue des Sentiers","Cuir du Traqueur","Manteau de résonance"},
    Arcaniste={"Robe d'Astréa","Habit d'Archimage","Voile de l'Écho"},
    Luminar={"Aube du pèlerin","Plastron du Luminar","Regalia astrale"},
}
local ExpansionCatalog={
    S3={Name="Sylvebrume",Quests={"Des pas dans la mousse","Les racines parlent","Le bois se défend","Le Veilleur sylvestre"}},
    N4={Name="Caps de Nacre",Quests={"Au bord du vide","Trois signaux","La lentille des vents","Le Gardien de Nacre"}},
    O5={Name="Ormefer",Quests={"Chiens de rouille","Deux cœurs froids","Le creuset oublié","Le Maître-Fourneau"}},
    V6={Name="Profondeurs de l'Écho",Quests={"Résonances","Ceux qui n'ont plus de voix","Sous la veine","Le Noyau Résonant"}},
}

local packet,journalPacket,storyPacket,expansionPacket,partyPacket
local suppressConnections={}

local function New(className,parent,props)
    local o=Instance.new(className)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent
    return o
end
local function Round(p,r) return New("UICorner",p,{CornerRadius=UDim.new(0,r or 12)}) end
local function Stroke(p,t) return New("UIStroke",p,{Color=T.Stroke,Transparency=t or 0.55,Thickness=1}) end
local function Label(p,text,size,bold)
    return New("TextLabel",p,{BackgroundTransparency=1,Text=text or "",TextColor3=T.Text,
        Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextSize=size or 14,TextWrapped=true})
end
local function Button(p,text,r)
    local b=New("TextButton",p,{BackgroundColor3=T.Panel2,BorderSizePixel=0,AutoButtonColor=true,
        Text=text or "",TextColor3=T.Text,Font=Enum.Font.GothamBold,TextSize=13,TextWrapped=true})
    Round(b,r or 12); Stroke(b,0.68); return b
end
local function clearGui(parent)
    for _,c in ipairs(parent:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
end
local function tierOf(id) return math.clamp(tonumber(tostring(id):match("_(%d+)$")) or 1,1,3) end
local function displayName(id,item)
    if WeaponNames[id] then return WeaponNames[id] end
    local classId,tier=tostring(id):match("^(.+)_Armor_(%d+)$")
    tier=tonumber(tier)
    if classId and tier and ArmorNames[classId] and ArmorNames[classId][tier] then
        return ArmorNames[classId][tier]
    end
    return item and item.Name or id
end
local function itemStats(item)
    return item and item.Power or 0,item and item.Health or 0,item and item.Armor or 0
end

local function suppressLegacy()
    for _,c in ipairs(suppressConnections) do c:Disconnect() end
    table.clear(suppressConnections)
    local hud=playerGui:FindFirstChild("ValbrumeHUD")
    if not hud then return end
    local quick=hud:FindFirstChild("QuickMenu")
    if quick then quick.Visible=false end
    for _,name in ipairs({"QuestTracker","ModalDim"}) do
        local object=hud:FindFirstChild(name)
        if object then
            object.Visible=false
            table.insert(suppressConnections,object:GetPropertyChangedSignal("Visible"):Connect(function()
                if object.Visible then object.Visible=false end
            end))
        end
    end
end
playerGui.ChildAdded:Connect(function(child)
    if child.Name=="ValbrumeHUD" then task.defer(suppressLegacy)
    elseif child.Name=="ValbrumeExpansionUIV26" then child:Destroy() end
end)
task.defer(suppressLegacy)
local oldExpansionGui=playerGui:FindFirstChild("ValbrumeExpansionUIV26")
if oldExpansionGui then oldExpansionGui:Destroy() end

local old=playerGui:FindFirstChild("ValbrumeInterfaceV27")
if old then old:Destroy() end
local gui=New("ScreenGui",playerGui,{Name="ValbrumeInterfaceV27",ResetOnSpawn=false,DisplayOrder=24})
local quick=New("Frame",gui,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,14),
    Size=UDim2.fromOffset(286,44),BackgroundTransparency=1})
New("UIListLayout",quick,{FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,7)})
local charButton=Button(quick,"PERSO",14); charButton.Size=UDim2.fromOffset(78,42)
local journalButton=Button(quick,"JOURNAL",14); journalButton.Size=UDim2.fromOffset(88,42)
local recallButton=Button(quick,"RAPPEL",14); recallButton.Size=UDim2.fromOffset(78,42)

local dim=New("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),
    BackgroundTransparency=0.32,BorderSizePixel=0,Visible=false,ZIndex=100})
local function showModal(frame)
    dim.Visible=true
    for _,c in ipairs(dim:GetChildren()) do if c:IsA("Frame") then c.Visible=c==frame end end
end
local function closeModal() dim.Visible=false end

local characterPanel=New("Frame",dim,{Name="CharacterPanel",AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(850,530),
    BackgroundColor3=T.Bg,BorderSizePixel=0,Visible=false,ZIndex=101})
Round(characterPanel,22); Stroke(characterPanel,.35)
local charTitle=Label(characterPanel,"PERSONNAGE",20,true)
charTitle.Position=UDim2.fromOffset(18,13); charTitle.Size=UDim2.new(1,-74,0,30)
charTitle.TextXAlignment=Enum.TextXAlignment.Left; charTitle.TextColor3=T.Gold; charTitle.ZIndex=102
local charClose=Button(characterPanel,"×",12)
charClose.Position=UDim2.new(1,-52,0,10); charClose.Size=UDim2.fromOffset(40,34)
charClose.TextSize=20; charClose.ZIndex=103

local left=New("ScrollingFrame",characterPanel,{Position=UDim2.fromOffset(14,54),
    Size=UDim2.new(.36,-18,1,-68),BackgroundColor3=T.Panel,BorderSizePixel=0,
    ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),ZIndex=102})
Round(left,16); Stroke(left,.58)
local preview=New("ViewportFrame",left,{Position=UDim2.fromOffset(10,10),Size=UDim2.new(1,-20,.62,-8),
    BackgroundColor3=Color3.fromRGB(20,27,38),BorderSizePixel=0,
    Ambient=Color3.fromRGB(190,190,190),LightColor=Color3.fromRGB(255,244,220),
    LightDirection=Vector3.new(-1,-1,-1),ZIndex=103})
Round(preview,13)
local worldModel=Instance.new("WorldModel"); worldModel.Parent=preview
local previewCamera=Instance.new("Camera"); previewCamera.Parent=preview; preview.CurrentCamera=previewCamera
local identity=Label(left,"",13,true)
identity.Position=UDim2.new(0,12,.62,8); identity.Size=UDim2.new(1,-24,0,54)
identity.TextXAlignment=Enum.TextXAlignment.Left; identity.TextYAlignment=Enum.TextYAlignment.Top; identity.ZIndex=103
local statsText=Label(left,"",12,false)
statsText.Position=UDim2.new(0,12,.62,66); statsText.Size=UDim2.new(1,-24,.38,-78)
statsText.TextXAlignment=Enum.TextXAlignment.Left; statsText.TextYAlignment=Enum.TextYAlignment.Top
statsText.TextColor3=T.Muted; statsText.ZIndex=103

local middle=New("ScrollingFrame",characterPanel,{Position=UDim2.new(.36,4,0,54),
    Size=UDim2.new(.25,-8,1,-68),BackgroundTransparency=1,BorderSizePixel=0,
    ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),ZIndex=102})
local equippedHeader=Label(middle,"ÉQUIPÉ",12,true)
equippedHeader.Size=UDim2.new(1,0,0,22); equippedHeader.TextXAlignment=Enum.TextXAlignment.Left
equippedHeader.TextColor3=T.Muted; equippedHeader.ZIndex=103
local weaponSlot=Button(middle,"ARME\n—",14)
weaponSlot.Position=UDim2.fromOffset(0,30); weaponSlot.Size=UDim2.new(1,0,0,82); weaponSlot.TextSize=12; weaponSlot.ZIndex=103
local armorSlot=Button(middle,"ARMURE\n—",14)
armorSlot.Position=UDim2.fromOffset(0,120); armorSlot.Size=UDim2.new(1,0,0,82); armorSlot.TextSize=12; armorSlot.ZIndex=103
local futureHeader=Label(middle,"EMPLACEMENTS FUTURS",11,true)
futureHeader.Position=UDim2.fromOffset(0,218); futureHeader.Size=UDim2.new(1,0,0,18)
futureHeader.TextXAlignment=Enum.TextXAlignment.Left; futureHeader.TextColor3=T.Muted; futureHeader.ZIndex=103
for index,slotName in ipairs({"TÊTE","BOTTES","ANNEAU"}) do
    local slot=New("Frame",middle,{Position=UDim2.fromOffset(0,244+(index-1)*58),
        Size=UDim2.new(1,0,0,50),BackgroundColor3=T.Panel,BackgroundTransparency=.25,
        BorderSizePixel=0,ZIndex=103})
    Round(slot,12); Stroke(slot,.8)
    local label=Label(slot,slotName.."\nverrouillé",10,true)
    label.Size=UDim2.fromScale(1,1); label.TextColor3=T.Muted; label.ZIndex=104
end

local right=New("Frame",characterPanel,{Position=UDim2.new(.61,4,0,54),
    Size=UDim2.new(.39,-18,1,-68),BackgroundColor3=T.Panel,BorderSizePixel=0,ZIndex=102})
Round(right,16); Stroke(right,.58)
local inventoryTitle=Label(right,"INVENTAIRE",13,true)
inventoryTitle.Position=UDim2.fromOffset(12,9); inventoryTitle.Size=UDim2.new(1,-24,0,24)
inventoryTitle.TextXAlignment=Enum.TextXAlignment.Left; inventoryTitle.TextColor3=T.Gold; inventoryTitle.ZIndex=103
local itemDetails=Label(right,"Sélectionne un objet.",11,false)
itemDetails.Position=UDim2.fromOffset(12,36); itemDetails.Size=UDim2.new(1,-24,0,72)
itemDetails.TextXAlignment=Enum.TextXAlignment.Left; itemDetails.TextYAlignment=Enum.TextYAlignment.Top
itemDetails.TextColor3=T.Muted; itemDetails.ZIndex=103
local inventoryList=New("ScrollingFrame",right,{Position=UDim2.fromOffset(10,114),
    Size=UDim2.new(1,-20,1,-124),BackgroundTransparency=1,BorderSizePixel=0,
    ScrollBarThickness=4,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),ZIndex=103})
New("UIListLayout",inventoryList,{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})

local journalPanel=New("Frame",dim,{Name="JournalPanel",AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(860,540),
    BackgroundColor3=T.Bg,BorderSizePixel=0,Visible=false,ZIndex=101})
Round(journalPanel,22); Stroke(journalPanel,.35)
local journalTitle=Label(journalPanel,"JOURNAL DE QUÊTES",20,true)
journalTitle.Position=UDim2.fromOffset(18,13); journalTitle.Size=UDim2.new(1,-74,0,30)
journalTitle.TextXAlignment=Enum.TextXAlignment.Left; journalTitle.TextColor3=T.Gold; journalTitle.ZIndex=102
local journalClose=Button(journalPanel,"×",12)
journalClose.Position=UDim2.new(1,-52,0,10); journalClose.Size=UDim2.fromOffset(40,34)
journalClose.TextSize=20; journalClose.ZIndex=103

local arcTabs=New("ScrollingFrame",journalPanel,{Position=UDim2.fromOffset(14,54),
    Size=UDim2.new(.32,-18,1,-68),BackgroundColor3=T.Panel,BorderSizePixel=0,
    ScrollBarThickness=4,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),ZIndex=102})
Round(arcTabs,16); Stroke(arcTabs,.58)
local arcHeader=Label(arcTabs,"CHRONIQUES",12,true)
arcHeader.Position=UDim2.fromOffset(12,10); arcHeader.Size=UDim2.new(1,-24,0,22)
arcHeader.TextXAlignment=Enum.TextXAlignment.Left; arcHeader.TextColor3=T.Muted; arcHeader.ZIndex=103
local homeQuestList=New("ScrollingFrame",arcTabs,{Position=UDim2.fromOffset(9,40),
    Size=UDim2.new(1,-18,0,200),BackgroundTransparency=1,BorderSizePixel=0,
    ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),ZIndex=103})
New("UIListLayout",homeQuestList,{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
local expansionHeader=Label(arcTabs,"EXPANSION",12,true)
expansionHeader.Position=UDim2.fromOffset(12,250); expansionHeader.Size=UDim2.new(1,-24,0,22)
expansionHeader.TextXAlignment=Enum.TextXAlignment.Left; expansionHeader.TextColor3=T.Muted; expansionHeader.ZIndex=103
local expansionList=New("ScrollingFrame",arcTabs,{Position=UDim2.fromOffset(9,280),
    Size=UDim2.new(1,-18,0,196),BackgroundTransparency=1,BorderSizePixel=0,
    ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),ZIndex=103})
New("UIListLayout",expansionList,{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})

local questDetail=New("ScrollingFrame",journalPanel,{Position=UDim2.new(.32,4,0,54),
    Size=UDim2.new(.68,-18,1,-68),BackgroundColor3=T.Panel,BorderSizePixel=0,
    ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),ZIndex=102})
Round(questDetail,16); Stroke(questDetail,.58)
local detailStatus=Label(questDetail,"",11,true)
detailStatus.Position=UDim2.fromOffset(16,12); detailStatus.Size=UDim2.new(1,-32,0,20)
detailStatus.TextXAlignment=Enum.TextXAlignment.Left; detailStatus.TextColor3=T.Muted; detailStatus.ZIndex=103
local detailTitle=Label(questDetail,"Aucune quête sélectionnée",20,true)
detailTitle.Position=UDim2.fromOffset(16,38); detailTitle.Size=UDim2.new(1,-32,0,54)
detailTitle.TextXAlignment=Enum.TextXAlignment.Left; detailTitle.TextYAlignment=Enum.TextYAlignment.Top
detailTitle.TextColor3=T.Gold; detailTitle.ZIndex=103
local detailBody=Label(questDetail,"",13,false)
detailBody.Position=UDim2.fromOffset(16,98); detailBody.Size=UDim2.new(1,-32,0,0)
detailBody.AutomaticSize=Enum.AutomaticSize.Y
detailBody.TextXAlignment=Enum.TextXAlignment.Left; detailBody.TextYAlignment=Enum.TextYAlignment.Top
detailBody.ZIndex=103

local function rebuildPreview()
    worldModel:ClearAllChildren()
    local character=player.Character
    if not character then return end

    local oldArchivable=character.Archivable
    character.Archivable=true
    local clone=character:Clone()
    character.Archivable=oldArchivable
    clone.Name="PreviewCharacter"

    for _,d in ipairs(clone:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy()
        elseif d:IsA("BasePart") then
            d.Anchored=true; d.CanCollide=false; d.CanTouch=false; d.CanQuery=false
        end
    end

    clone.Parent=worldModel
    local cf,size=clone:GetBoundingBox()
    clone:PivotTo(CFrame.new(-cf.Position)*clone:GetPivot())
    local distance=math.max(7.5,size.Y*1.35)
    previewCamera.CFrame=CFrame.lookAt(
        Vector3.new(0,size.Y*.05,distance),
        Vector3.new(0,size.Y*.05,0)
    )
end

local function equippedItem(slot)
    local data=journalPacket and journalPacket.Player
    local equipment=data and data.Equipment
    local id=equipment and equipment[slot]
    return id,id and C.Items[id] or nil
end

local function updateItemDetails(id)
    if not id or not C.Items[id] then itemDetails.Text="Sélectionne un objet."; return end
    local item=C.Items[id]
    local p,h,a=itemStats(item)
    local rarity=Rarity[tierOf(id)]
    local equipped=journalPacket and journalPacket.Player and journalPacket.Player.Equipment
        and journalPacket.Player.Equipment[item.Slot]==id
    itemDetails.Text=string.format(
        "%s%s\n%s • Niv. %d\nPuissance +%d   PV +%d   Armure +%d",
        equipped and "✓ Équipé — " or "",rarity.Name,displayName(id,item),
        item.Level or 1,p,h,a
    )
    itemDetails.TextColor3=rarity.Color
end

local function renderInventory()
    clearGui(inventoryList)
    if not journalPacket or not journalPacket.Player then return end

    local data=journalPacket.Player
    local ids={}
    for id,owned in pairs(data.Inventory or {}) do
        if owned and C.Items[id] then table.insert(ids,id) end
    end
    table.sort(ids,function(a,b)
        local ia,ib=C.Items[a],C.Items[b]
        local sa=ia.Slot=="Weapon" and 1 or 2
        local sb=ib.Slot=="Weapon" and 1 or 2
        if sa~=sb then return sa<sb end
        if (ia.Level or 1)~=(ib.Level or 1) then return (ia.Level or 1)<(ib.Level or 1) end
        return a<b
    end)

    for index,id in ipairs(ids) do
        local item=C.Items[id]
        local equipped=data.Equipment and data.Equipment[item.Slot]==id
        local rarity=Rarity[tierOf(id)]
        local p,h,a=itemStats(item)
        local b=Button(inventoryList,string.format(
            "%s%s\nP +%d   PV +%d   ARM +%d",
            equipped and "✓ " or "",displayName(id,item),p,h,a
        ),12)
        b.Size=UDim2.new(1,-4,0,58); b.LayoutOrder=index; b.TextSize=11
        b.TextXAlignment=Enum.TextXAlignment.Left; b.TextColor3=rarity.Color; b.ZIndex=104
        b.Activated:Connect(function()
            updateItemDetails(id)
            if (item.Level or 1)<=(data.Level or 1) then
                Request:FireServer("Equip",id)
                task.delay(.25,function()
                    Request:FireServer("Sync")
                    JournalRemote:FireServer("Sync")
                end)
            end
        end)
    end

    if #ids==0 then
        local empty=Label(inventoryList,"Aucun équipement dans le sac.",12,false)
        empty.Size=UDim2.new(1,0,0,50); empty.TextColor3=T.Muted; empty.LayoutOrder=1; empty.ZIndex=104
    end
end

local function renderCharacter()
    if not journalPacket or not journalPacket.Player then return end
    local data=journalPacket.Player
    local class=data.Class and C.Classes[data.Class]
    local zone=data.Zone and C.Zones[data.Zone]

    identity.Text=string.format("%s\n%s • Niveau %d",
        class and class.Name or "Aventurier",zone and zone.Short or "Valbrume",data.Level or 1)

    local weaponId,weaponItem=equippedItem("Weapon")
    local armorId,armorItem=equippedItem("Armor")
    weaponSlot.Text="ARME\n"..(weaponId and displayName(weaponId,weaponItem) or "—")
    armorSlot.Text="ARMURE\n"..(armorId and displayName(armorId,armorItem) or "—")

    local power,health,armor=0,0,0
    for _,id in pairs(data.Equipment or {}) do
        local item=C.Items[id]
        if item then
            local p,h,a=itemStats(item)
            power+=p; health+=h; armor+=a
        end
    end

    local tool=player.Character and player.Character:FindFirstChild("VB_EquippedWeaponV27")
    local weaponState=tool and tool:GetAttribute("VBValidated")==true
        and "Arme 3D : RightGrip validé" or "Arme 3D : attente/fallback"

    statsText.Text=string.format(
        "OR  %d\n\nBONUS ÉQUIPEMENT\nPuissance  +%d\nPV  +%d\nArmure  +%d\n\n%s",
        data.Gold or 0,power,health,armor,weaponState
    )
    renderInventory()
    rebuildPreview()
end

weaponSlot.Activated:Connect(function()
    local id=equippedItem("Weapon"); updateItemDetails(id)
end)
armorSlot.Activated:Connect(function()
    local id=equippedItem("Armor"); updateItemDetails(id)
end)

local function statusText(status)
    if status=="Completed" then return "TERMINÉE",T.Green
    elseif status=="Active" then return "EN COURS",T.Gold
    elseif status=="Available" then return "DISPONIBLE",T.Blue end
    return "VERROUILLÉE",T.Muted
end

local function renderHomeDetail(index)
    local home=journalPacket and journalPacket.HomeArc
    local quest=home and home.Quests and home.Quests[index]
    if not quest then
        detailStatus.Text=""; detailTitle.Text="Aucune quête"; detailBody.Text=""; return
    end
    local status,color=statusText(quest.Status)
    detailStatus.Text=(home.ZoneName or home.Zone or "ORIGINE").."  •  "..status
    detailStatus.TextColor3=color
    detailTitle.Text=quest.Name
    local lines={}
    for _,obj in ipairs(quest.Objectives or {}) do
        local done=obj.Progress>=obj.Amount
        table.insert(lines,(done and "✓ " or "• ")..obj.Text.."   "..obj.Progress.."/"..obj.Amount)
    end
    table.insert(lines,"")
    table.insert(lines,string.format("Récompenses : %d XP • %d or%s",
        quest.Rewards and quest.Rewards.XP or 0,
        quest.Rewards and quest.Rewards.Gold or 0,
        quest.Rewards and quest.Rewards.Tier and (" • équipement palier "..quest.Rewards.Tier) or ""
    ))
    detailBody.Text=table.concat(lines,"\n")
end

local function renderJournal()
    clearGui(homeQuestList); clearGui(expansionList)
    local home=journalPacket and journalPacket.HomeArc
    if home and home.Quests then
        for index,quest in ipairs(home.Quests) do
            local status,color=statusText(quest.Status)
            local b=Button(homeQuestList,string.format("%02d  %s\n%s",index,quest.Name,status),10)
            b.Size=UDim2.new(1,-4,0,52); b.LayoutOrder=index; b.TextSize=10
            b.TextXAlignment=Enum.TextXAlignment.Left; b.TextColor3=color; b.ZIndex=104
            b.Activated:Connect(function() renderHomeDetail(index) end)
        end
        renderHomeDetail(math.clamp(home.QuestIndex or 1,1,#home.Quests))
    else
        detailStatus.Text=""; detailTitle.Text="Chronique indisponible"
        detailBody.Text="Choisis d'abord ton territoire et ta classe."
    end

    local currentZone=journalPacket and journalPacket.ExpansionZone
    for order,zoneId in ipairs({"S3","N4","O5","V6"}) do
        local catalog=ExpansionCatalog[zoneId]
        local current=currentZone==zoneId
        local b=Button(expansionList,(current and "◆ " or "◇ ")..zoneId.." — "..catalog.Name,10)
        b.Size=UDim2.new(1,-4,0,44); b.LayoutOrder=order; b.TextSize=10
        b.TextColor3=current and T.Purple or T.Muted; b.ZIndex=104
        b.Activated:Connect(function()
            detailStatus.Text=zoneId.." — EXPANSION"
            detailStatus.TextColor3=current and T.Purple or T.Muted
            if current and expansionPacket then
                detailTitle.Text=expansionPacket.QuestName or catalog.Name
                detailBody.Text=(expansionPacket.Progress or "").."\n\nArc :\n• "..table.concat(catalog.Quests,"\n• ")
            else
                detailTitle.Text=catalog.Name
                detailBody.Text="Chroniques :\n• "..table.concat(catalog.Quests,"\n• ")
                    .."\n\nVoyage dans cette région pour activer sa progression."
            end
        end)
    end

    if partyPacket and partyPacket.Started then
        detailBody.Text..="\n\nDONJON EN COURS\nGroupe actif • "..tostring(#(partyPacket.Members or {})).." joueur(s)"
    end
end

State.OnClientEvent:Connect(function(kind,value)
    if kind=="State" and type(value)=="table" then
        packet=value
        task.defer(function() JournalRemote:FireServer("Sync") end)
    end
end)
JournalRemote.OnClientEvent:Connect(function(kind,value)
    if kind=="State" and type(value)=="table" then
        journalPacket=value
        if dim.Visible and characterPanel.Visible then renderCharacter()
        elseif dim.Visible and journalPanel.Visible then renderJournal() end
    end
end)
if StoryRemote then
    StoryRemote.OnClientEvent:Connect(function(kind,value)
        if kind=="State" then
            storyPacket=value
            JournalRemote:FireServer("Sync")
            if dim.Visible and journalPanel.Visible then renderJournal() end
        end
    end)
end
if ExpansionRemote then
    ExpansionRemote.OnClientEvent:Connect(function(kind,value)
        if kind=="State" then
            expansionPacket=value
            if dim.Visible and journalPanel.Visible then renderJournal() end
        end
    end)
end
if PartyRemote then
    PartyRemote.OnClientEvent:Connect(function(kind,value)
        if kind=="State" then
            partyPacket=value
            if dim.Visible and journalPanel.Visible then renderJournal() end
        end
    end)
end

charButton.Activated:Connect(function()
    showModal(characterPanel); JournalRemote:FireServer("Sync"); task.delay(.15,renderCharacter)
end)
journalButton.Activated:Connect(function()
    showModal(journalPanel); JournalRemote:FireServer("Sync"); task.delay(.15,renderJournal)
end)
recallButton.Activated:Connect(function() Request:FireServer("Recall") end)
charClose.Activated:Connect(closeModal)
journalClose.Activated:Connect(closeModal)

UIS.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.I then
        if dim.Visible and characterPanel.Visible then closeModal()
        else showModal(characterPanel); JournalRemote:FireServer("Sync"); task.delay(.1,renderCharacter) end
    elseif input.KeyCode==Enum.KeyCode.J then
        if dim.Visible and journalPanel.Visible then closeModal()
        else showModal(journalPanel); JournalRemote:FireServer("Sync"); task.delay(.1,renderJournal) end
    elseif input.KeyCode==Enum.KeyCode.Escape and dim.Visible then closeModal() end
end)

player.CharacterAdded:Connect(function()
    task.wait(1.2)
    if dim.Visible and characterPanel.Visible then rebuildPreview() end
end)

task.spawn(function()
    while gui.Parent do
        task.wait(1.2)
        if dim.Visible then
            JournalRemote:FireServer("Sync")
            if characterPanel.Visible then renderCharacter()
            elseif journalPanel.Visible then renderJournal() end
        end
    end
end)

local function layout()
    local camera=workspace.CurrentCamera
    local size=camera and camera.ViewportSize or Vector2.new(1280,720)
    local mobile=size.X<760
    if mobile then
        quick.Size=UDim2.fromOffset(244,44)
        charButton.Size=UDim2.fromOffset(66,44)
        journalButton.Size=UDim2.fromOffset(80,44)
        recallButton.Size=UDim2.fromOffset(66,44)
        characterPanel.Size=UDim2.new(1,-18,1,-16)
        journalPanel.Size=UDim2.new(1,-18,1,-16)
        left.Size=UDim2.new(.34,-10,1,-68)
        middle.Position=UDim2.new(.34,4,0,54); middle.Size=UDim2.new(.24,-6,1,-68)
        right.Position=UDim2.new(.58,4,0,54); right.Size=UDim2.new(.42,-14,1,-68)
        identity.TextSize=11; statsText.TextSize=10; itemDetails.TextSize=10
        arcTabs.Size=UDim2.new(.36,-14,1,-68)
        questDetail.Position=UDim2.new(.36,4,0,54); questDetail.Size=UDim2.new(.64,-14,1,-68)
        detailTitle.TextSize=17; detailBody.TextSize=11
    else
        quick.Size=UDim2.fromOffset(286,44)
        charButton.Size=UDim2.fromOffset(78,44)
        journalButton.Size=UDim2.fromOffset(88,44)
        recallButton.Size=UDim2.fromOffset(78,44)
        characterPanel.Size=UDim2.fromOffset(math.min(850,size.X-42),math.min(530,size.Y-60))
        journalPanel.Size=UDim2.fromOffset(math.min(860,size.X-42),math.min(540,size.Y-60))
        left.Size=UDim2.new(.36,-18,1,-68)
        middle.Position=UDim2.new(.36,4,0,54); middle.Size=UDim2.new(.25,-8,1,-68)
        right.Position=UDim2.new(.61,4,0,54); right.Size=UDim2.new(.39,-18,1,-68)
        identity.TextSize=13; statsText.TextSize=12; itemDetails.TextSize=11
        arcTabs.Size=UDim2.new(.32,-18,1,-68)
        questDetail.Position=UDim2.new(.32,4,0,54); questDetail.Size=UDim2.new(.68,-18,1,-68)
        detailTitle.TextSize=20; detailBody.TextSize=13
    end
    quick.Position=UDim2.new(1,-14,0,size.Y>size.X and 136 or 14)
    local previewHeight=math.clamp(size.Y*.25,90,220)
    preview.Size=UDim2.new(1,-20,0,previewHeight)
    identity.Position=UDim2.fromOffset(12,previewHeight+18)
    statsText.Position=UDim2.fromOffset(12,previewHeight+80)
    statsText.Size=UDim2.new(1,-24,0,90)
    charClose.Size=UDim2.fromOffset(44,44)
    journalClose.Size=UDim2.fromOffset(44,44)
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(layout)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout) end
layout()

task.spawn(function()
    for _=1,12 do
        Request:FireServer("Sync")
        JournalRemote:FireServer("Sync")
        task.wait(1)
        if journalPacket then break end
    end
end)

print("[Valbrume V2.7] Interface Personnage + Journal active.")
