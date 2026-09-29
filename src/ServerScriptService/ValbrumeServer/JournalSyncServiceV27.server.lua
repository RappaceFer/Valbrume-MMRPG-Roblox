local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local package=RS:WaitForChild("Valbrume")
local C=require(package:WaitForChild("Config"))
local S=require(package:WaitForChild("StoryConfigV23"))
local Remote=package:WaitForChild("JournalSyncRemoteV27")
local Data=require(script.Parent:WaitForChild("PlayerDataService"))

local function shallow(source)
    local r={}
    if type(source)=="table" then
        for k,v in pairs(source) do
            if type(v)~="table" then r[k]=v end
        end
    end
    return r
end

local function inventory(source)
    local r={}
    if type(source)=="table" then
        for id,owned in pairs(source) do
            if owned==true then r[id]=true end
        end
    end
    return r
end

local function homeArc(profile)
    local zoneId=profile.Zone
    local zoneStory=zoneId and S.Zones[zoneId]
    if not zoneStory then return nil end

    local story=type(profile.Story)=="table" and profile.Story or {}
    local current=math.max(1,math.floor(story.QuestIndex or 1))
    local progress=type(story.Progress)=="table" and story.Progress or {}
    local quests={}

    for index,quest in ipairs(zoneStory.Quests) do
        local status=index<current and "Completed"
            or (index==current and (story.Active==true and "Active" or "Available"))
            or "Locked"

        local objectives={}
        for i,obj in ipairs(quest.Objectives or {}) do
            local amount=obj.Amount or 1
            table.insert(objectives,{
                Text=obj.Text or obj.Type or "Objectif",
                Amount=amount,
                Progress=index==current and math.min(amount,progress[i] or 0)
                    or (status=="Completed" and amount or 0),
            })
        end

        table.insert(quests,{
            Id=quest.Id,Name=quest.Name,Status=status,Objectives=objectives,
            Rewards={
                XP=quest.Rewards and quest.Rewards.XP or 0,
                Gold=quest.Rewards and quest.Rewards.Gold or 0,
                Tier=quest.Rewards and quest.Rewards.Tier or nil,
            },
        })
    end

    return {
        Zone=zoneId,
        ZoneName=C.Zones[zoneId] and C.Zones[zoneId].Short or zoneId,
        Giver=zoneStory.QuestGiver,
        Intro=zoneStory.Intro,
        QuestIndex=current,
        Active=story.Active==true,
        Quests=quests,
    }
end

local function send(player)
    local p=Data.Get(player)
    if not p then return end
    Remote:FireClient(player,"State",{
        Player={
            Class=p.Class,Zone=p.Zone,Level=p.Level or 1,XP=p.XP or 0,Gold=p.Gold or 0,
            Inventory=inventory(p.Inventory),Equipment=shallow(p.Equipment),
        },
        HomeArc=homeArc(p),
        ExpansionZone=player:GetAttribute("VBExpansionZone"),
        DungeonId=player:GetAttribute("VBDungeonId"),
    })
end

Remote.OnServerEvent:Connect(function(player,action)
    if action=="Sync" then send(player) end
end)

local function watch(player)
    player.CharacterAdded:Connect(function() task.wait(1); send(player) end)
    player:GetAttributeChangedSignal("VBExpansionZone"):Connect(function() send(player) end)
    player:GetAttributeChangedSignal("VBDungeonId"):Connect(function() send(player) end)
    task.spawn(function()
        for _=1,30 do
            if Data.Get(player) then send(player); return end
            task.wait(0.5)
        end
    end)
end

for _,player in ipairs(Players:GetPlayers()) do watch(player) end
Players.PlayerAdded:Connect(watch)
print("[Valbrume V2.7] JournalSyncService actif.")
