local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace.Terrain

local package = ReplicatedStorage:WaitForChild("Valbrume")
local C = require(package:WaitForChild("Config"))
local S = require(package:WaitForChild("StoryConfigV23"))
local Remote = package:WaitForChild("StoryRemoteV23")

local server = script.Parent
local Data = require(server:WaitForChild("PlayerDataService"))
local MobDied = server:WaitForChild("WorldMobDiedV23")
local Reward = server:WaitForChild("StoryRewardV23")

local Generation = require(script.Parent.WorldGeneration)
local world = Generation.Await("Population")
local npcs = world:WaitForChild("NPCs")
local collectibles = world:WaitForChild("Collectibles")
local sessions = {}

local function zoneConfig(profile)
    return profile.Zone and S.Zones[profile.Zone]
end

local function currentQuest(profile)
    local z=zoneConfig(profile)
    return z and z.Quests[profile.Story.QuestIndex]
end

local function absolutePoint(zoneId, pointId)
    local zone=C.Zones[zoneId]
    local point=S.Points[zoneId] and S.Points[zoneId][pointId]
    if not zone or not point then return nil end
    local x=zone.Origin.X+point.Position.X
    local z=zone.Origin.Z+point.Position.Z
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances={Terrain}
    local hit=workspace:Raycast(Vector3.new(x,260,z),Vector3.new(0,-520,0),params)
    return Vector3.new(x,hit and hit.Position.Y+2 or zone.GroundY+2,z),point.Label
end

local function ensureStory(profile)
    if type(profile.Story) ~= "table" then
        profile.Story={Zone=profile.Zone,QuestIndex=1,Active=false,Progress={}}
    end
    profile.Story.Zone=profile.Zone
    profile.Story.QuestIndex=math.max(1,math.floor(profile.Story.QuestIndex or 1))
    profile.Story.Active=profile.Story.Active==true
    if type(profile.Story.Progress)~="table" then profile.Story.Progress={} end
end

local function objectiveDone(profile,obj,index)
    return (profile.Story.Progress[index] or 0) >= (obj.Amount or 1)
end

local function questComplete(profile,quest)
    if not quest then return false end
    for i,obj in ipairs(quest.Objectives) do
        if not objectiveDone(profile,obj,i) then return false end
    end
    return true
end

local function firstIncomplete(profile,quest)
    if not quest then return nil end
    for i,obj in ipairs(quest.Objectives) do
        if not objectiveDone(profile,obj,i) then return i,obj end
    end
end

local function giverModel(zoneId)
    for _,npc in ipairs(npcs:GetChildren()) do
        if npc:GetAttribute("ZoneId")==zoneId and npc:GetAttribute("Role")=="Quest" then
            return npc
        end
    end
end

local function giverPosition(zoneId)
    local giver=giverModel(zoneId)
    return giver and giver.PrimaryPart and giver.PrimaryPart.Position or C.Zones[zoneId].Origin+C.NoraPosition
end

local function progressText(profile,quest)
    if not quest then return nil end
    local lines={}
    for i,obj in ipairs(quest.Objectives) do
        local amount=obj.Amount or 1
        local value=math.min(amount,profile.Story.Progress[i] or 0)
        table.insert(lines,(objectiveDone(profile,obj,i) and "✓ " or "• ") .. obj.Text .. "  " .. value .. "/" .. amount)
    end
    return table.concat(lines,"\n")
end

local function sendState(player)
    local profile=Data.Get(player)
    if not profile or not profile.Zone or not profile.Class then return end
    ensureStory(profile)
    local quest=currentQuest(profile)
    local zone=S.Zones[profile.Zone]

    if not quest then
        Remote:FireClient(player,"State",{
            Active=false,
            Title="Arc terminé — " .. C.Zones[profile.Zone].Short,
            ObjectiveText="L'Écho t'a conduit jusqu'au premier seuil. Le donjon t'attend.",
        })
        return
    end

    local ready=profile.Story.Active and questComplete(profile,quest)
    local goal,goalLabel

    if not profile.Story.Active or ready then
        goal=giverPosition(profile.Zone)
        goalLabel=zone.QuestGiver
    else
        local _,obj=firstIncomplete(profile,quest)
        if obj and obj.Point then
            goal,goalLabel=absolutePoint(profile.Zone,obj.Point)
        end
    end

    Remote:FireClient(player,"State",{
        Active=true,
        Title=quest.Name,
        ObjectiveText=not profile.Story.Active and ("Parler à "..zone.QuestGiver)
            or (ready and ("Retourner voir "..zone.QuestGiver) or "Objectifs"),
        ProgressText=profile.Story.Active and progressText(profile,quest) or nil,
        Goal=goal,
        GoalLabel=goalLabel,
        Ready=ready,
    })
end

local function dialogue(player,speaker,text)
    Remote:FireClient(player,"Dialogue",{Speaker=speaker,Text=text})
end

local function toast(player,text)
    Remote:FireClient(player,"Toast",text)
end

local function increment(player,kind,target,amount)
    local profile=Data.Get(player)
    if not profile or not profile.Zone or not profile.Class then return end
    ensureStory(profile)
    if not profile.Story.Active then return end
    local quest=currentQuest(profile)
    if not quest then return end

    local changed=false
    for i,obj in ipairs(quest.Objectives) do
        if obj.Type==kind and (not target or obj.Target==target or obj.Point==target) and not objectiveDone(profile,obj,i) then
            profile.Story.Progress[i]=math.min(obj.Amount or 1,(profile.Story.Progress[i] or 0)+(amount or 1))
            changed=true
            break
        end
    end

    if changed then
        if questComplete(profile,quest) then
            toast(player,"Objectifs terminés — retourne voir "..S.Zones[profile.Zone].QuestGiver..".")
        end
        sendState(player)
    end
end

local function acceptOrTurnIn(player)
    local profile=Data.Get(player)
    if not profile or not profile.Zone or not profile.Class then return end
    ensureStory(profile)
    local zone=S.Zones[profile.Zone]
    local quest=currentQuest(profile)
    if not quest then
        dialogue(player,zone.QuestGiver,"Tu as fait ce que nous pouvions demander. Maintenant, l'Écho nous conduit plus loin.")
        return
    end

    if not profile.Story.Active then
        profile.Story.Active=true
        profile.Story.Progress={}
        dialogue(player,zone.QuestGiver,quest.Accept)
        toast(player,"Quête acceptée : "..quest.Name)
        sendState(player)
        return
    end

    if not questComplete(profile,quest) then
        dialogue(player,zone.QuestGiver,"Ce n'est pas terminé. Observe le terrain, pas seulement ton arme.")
        sendState(player)
        return
    end

    dialogue(player,zone.QuestGiver,quest.Complete)
    local reward=quest.Rewards or {}
    local itemId
    if reward.Tier then
        itemId=profile.Class.."_Weapon_"..reward.Tier
    end
    Reward:Fire(player,reward.XP or 0,reward.Gold or 0,itemId)

    profile.Story.QuestIndex += 1
    profile.Story.Active=false
    profile.Story.Progress={}
    sessions[player]={Collected={}}
    sendState(player)
end

local function disableLegacyPrompt(prompt)
    if prompt:IsA("ProximityPrompt") and prompt.Name ~= "StoryPromptV23" then
        prompt.Enabled=false
    end
end

local function setupGiver(npc)
    if npc:GetAttribute("Role")~="Quest" then return end
    for _,d in ipairs(npc:GetDescendants()) do disableLegacyPrompt(d) end
    npc.DescendantAdded:Connect(function(d) task.defer(disableLegacyPrompt,d) end)

    local root=npc.PrimaryPart
    if not root or root:FindFirstChild("StoryPromptV23") then return end
    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="StoryPromptV23"
    prompt.ActionText="Parler"
    prompt.ObjectText=npc.Name:gsub("_[AH]2$","")
    prompt.MaxActivationDistance=13
    prompt.HoldDuration=0.12
    prompt.RequiresLineOfSight=false
    prompt.Parent=root
    prompt.Triggered:Connect(function(player)
        local profile=Data.Get(player)
        if profile and profile.Zone==npc:GetAttribute("ZoneId") then
            acceptOrTurnIn(player)
        end
    end)
end

local function setupCrystal(model)
    local zoneId=model:GetAttribute("ZoneId") or (model.Name:sub(1,2)=="A2" and "A2" or "H2")
    for _,d in ipairs(model:GetDescendants()) do disableLegacyPrompt(d) end
    local root=model.PrimaryPart
    if not root then return end
    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="StoryPromptV23"
    prompt.ActionText="Récolter"
    prompt.ObjectText=zoneId=="A2" and "Éclat de brume" or "Éclat ambré"
    prompt.MaxActivationDistance=12
    prompt.HoldDuration=0.15
    prompt.RequiresLineOfSight=false
    prompt.Parent=root
    prompt.Triggered:Connect(function(player)
        local profile=Data.Get(player)
        if not profile or profile.Zone~=zoneId then return end
        ensureStory(profile)
        local session=sessions[player] or {Collected={}}
        sessions[player]=session
        local key=tostring(profile.Story.QuestIndex)..":"..model.Name
        if session.Collected[key] then
            toast(player,"Cet éclat a déjà été étudié pour cette quête.")
            return
        end
        session.Collected[key]=true
        increment(player,"Collect",zoneId=="A2" and "A2Shard" or "H2Shard",1)
    end)
end


for _,npc in ipairs(npcs:GetChildren()) do setupGiver(npc) end
npcs.ChildAdded:Connect(function(npc) task.wait(0.3) setupGiver(npc) end)

for _,model in ipairs(collectibles:GetChildren()) do setupCrystal(model) end
collectibles.ChildAdded:Connect(function(model) task.wait(0.3) setupCrystal(model) end)

-- Story interactables créés par WorldPolishV23.
do
    local polish=world:FindFirstChild("V23Polish")
    if not polish then return end
    local poiFolder=polish:FindFirstChild("StoryPOIs")
    if not poiFolder then return end

    for _,obj in ipairs(poiFolder:GetChildren()) do
        local point=obj:GetAttribute("StoryPoint")
        local zoneId=obj:GetAttribute("ZoneId")
        if point=="MarauderCamp" or point=="BrokenWagon" then
            local prompt=Instance.new("ProximityPrompt")
            prompt.Name="StoryPromptV23"
            prompt.ActionText="Inspecter"
            prompt.ObjectText=point=="MarauderCamp" and "Camp abandonné" or "Chariot brisé"
            prompt.MaxActivationDistance=12
            prompt.HoldDuration=0.4
            prompt.RequiresLineOfSight=false
            prompt.Parent=obj
            prompt.Triggered:Connect(function(player)
                local profile=Data.Get(player)
                if profile and profile.Zone==zoneId then increment(player,"Interact",point,1) end
            end)
        end
    end
end

MobDied.Event:Connect(function(player,mobId,zoneId)
    local profile=Data.Get(player)
    if profile and profile.Zone==zoneId then increment(player,"Kill",mobId,1) end
end)

local function playerReady(player)
    task.spawn(function()
        for _=1,40 do
            local profile=Data.Get(player)
            if profile and profile.Class and profile.Zone then
                ensureStory(profile)
                profile.QuestActive=false -- désactive l'ancien arc V1 sans toucher au moteur.
                sessions[player]=sessions[player] or {Collected={}}
                sendState(player)
                return
            end
            task.wait(0.5)
        end
    end)
end

Players.PlayerAdded:Connect(playerReady)
Players.PlayerRemoving:Connect(function(player) sessions[player]=nil end)
for _,player in ipairs(Players:GetPlayers()) do playerReady(player) end

-- Explore objectives : vérification légère, 1.2 s.
task.spawn(function()
    while true do
        task.wait(1.2)
        for _,player in ipairs(Players:GetPlayers()) do
            local profile=Data.Get(player)
            local character=player.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            if profile and root and profile.Class and profile.Zone then
                ensureStory(profile)
                local quest=currentQuest(profile)
                if profile.Story.Active and quest then
                    for i,obj in ipairs(quest.Objectives) do
                        if obj.Type=="Explore" and not objectiveDone(profile,obj,i) then
                            local pos=absolutePoint(profile.Zone,obj.Point)
                            if pos and (root.Position-pos).Magnitude<=16 then
                                profile.Story.Progress[i]=1
                                local speaker=obj.Point=="Healer" and (profile.Zone=="A2" and "Solen" or "Tahla") or "L'Écho"
                                local text=obj.Point=="Healer"
                                    and (profile.Zone=="A2"
                                        and "La rivière est silencieuse. Même les oiseaux évitent les hauteurs. Quelque chose a changé."
                                        or "Les blessés parlent de vibrations sous la roche. Pas un séisme. Quelque chose de régulier.")
                                    or "Une vibration traverse la pierre, brève mais parfaitement régulière."
                                dialogue(player,speaker,text)
                                if questComplete(profile,quest) then
                                    toast(player,"Objectifs terminés — retourne voir "..S.Zones[profile.Zone].QuestGiver..".")
                                end
                                sendState(player)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

Remote.OnServerEvent:Connect(function(player,action)
    if action=="Sync" then sendState(player) end
end)

print("[Valbrume V2.3B] StoryQuestService actif.")

Generation.Complete(world, "Story")
