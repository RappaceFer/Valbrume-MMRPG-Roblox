local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace.Terrain

local C = require(ReplicatedStorage:WaitForChild("Valbrume"):WaitForChild("Config"))
local server = script.Parent
local spawnRequest = server:WaitForChild("DungeonSpawnRequest")
local Generation = require(script.Parent.WorldGeneration)
local world = Generation.Await("Content")
local decor = world:WaitForChild("Decor")
local enemies = world:WaitForChild("Enemies")
local spawns = world:WaitForChild("Spawns")



local old = world:FindFirstChild("V23Polish")
if old then old:Destroy() end
local folder = Instance.new("Folder")
folder.Name = "V23Polish"
folder.Parent = world

local poiFolder = Instance.new("Folder")
poiFolder.Name = "StoryPOIs"
poiFolder.Parent = folder

local function ground(zoneId, relative)
    local zone = C.Zones[zoneId]
    local x = zone.Origin.X + relative.X
    local z = zone.Origin.Z + relative.Z
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {Terrain}
    local hit = workspace:Raycast(Vector3.new(x,260,z),Vector3.new(0,-520,0),params)
    return Vector3.new(x, hit and hit.Position.Y or zone.GroundY, z)
end

local function part(parent,name,size,pos,color,material)
    local p=Instance.new("Part")
    p.Name=name
    p.Size=size
    p.Position=pos
    p.Anchored=true
    p.Color=color
    p.Material=material or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end

local function post(zoneId, relative, height, color)
    local g=ground(zoneId,relative)
    return part(folder,"Post",Vector3.new(1.2,height,1.2),g+Vector3.new(0,height/2,0),color,Enum.Material.Wood)
end

local function fence(zoneId, center, length, alongX, color)
    local count=math.max(2,math.floor(length/9))
    for i=0,count do
        local t=i/count-0.5
        local rel=center + (alongX and Vector3.new(t*length,0,0) or Vector3.new(0,0,t*length))
        post(zoneId,rel,5,color)
    end
    local g=ground(zoneId,center)
    local rail=part(
        folder,"FenceRail",
        alongX and Vector3.new(length,0.65,0.65) or Vector3.new(0.65,0.65,length),
        g+Vector3.new(0,3.5,0),color,Enum.Material.Wood
    )
end

local function banner(zoneId, relative, color)
    local g=ground(zoneId,relative)
    local pole=part(folder,"BannerPole",Vector3.new(0.7,10,0.7),g+Vector3.new(0,5,0),Color3.fromRGB(78,61,47),Enum.Material.Wood)
    local flag=part(folder,"Banner",Vector3.new(0.3,4.5,3.6),g+Vector3.new(0.3,7,1.7),color,Enum.Material.Fabric)
    flag.CanCollide=false
end

local function crate(zoneId, relative, color)
    local g=ground(zoneId,relative)
    return part(folder,"Crate",Vector3.new(4,4,4),g+Vector3.new(0,2,0),color,Enum.Material.WoodPlanks)
end

local function fireBowl(zoneId, relative)
    local g=ground(zoneId,relative)
    part(folder,"Brazier",Vector3.new(3.8,1.1,3.8),g+Vector3.new(0,0.55,0),Color3.fromRGB(67,61,58),Enum.Material.Metal)
    local glow=part(folder,"Ember",Vector3.new(2.2,1.1,2.2),g+Vector3.new(0,1.45,0),Color3.fromRGB(255,123,48),Enum.Material.Neon)
    glow.CanCollide=false
end

local function stoneRing(zoneId, relative, color)
    local center=ground(zoneId,relative)
    for i=1,6 do
        local a=i/6*math.pi*2
        local pos=center+Vector3.new(math.cos(a)*7,2.4,math.sin(a)*7)
        local s=part(folder,"StandingStone",Vector3.new(2.8,6,2.8),pos,color,Enum.Material.Slate)
        s.CFrame*=CFrame.Angles(0,a,math.rad((i%2)*5))
    end
end

-- A2 : camp vivant et repères visuels.
fence("A2",Vector3.new(-74,0,52),72,true,Color3.fromRGB(95,72,50))
fence("A2",Vector3.new(-110,0,15),74,false,Color3.fromRGB(95,72,50))
banner("A2",Vector3.new(-5,0,34),C.Zones.A2.Color)
banner("A2",Vector3.new(-48,0,55),C.Zones.A2.Color)
crate("A2",Vector3.new(-42,0,-5),Color3.fromRGB(126,91,60))
crate("A2",Vector3.new(-37,0,-8),Color3.fromRGB(126,91,60))
fireBowl("A2",Vector3.new(-3,0,-3))
stoneRing("A2",Vector3.new(-145,0,-105),Color3.fromRGB(113,132,143))
stoneRing("A2",Vector3.new(240,0,-155),Color3.fromRGB(112,145,166))

-- H2 : avant-poste frontalier.
fence("H2",Vector3.new(-74,0,52),72,true,Color3.fromRGB(91,60,43))
fence("H2",Vector3.new(-110,0,15),74,false,Color3.fromRGB(91,60,43))
banner("H2",Vector3.new(-5,0,34),C.Zones.H2.Color)
banner("H2",Vector3.new(-48,0,55),C.Zones.H2.Color)
crate("H2",Vector3.new(-42,0,-5),Color3.fromRGB(113,72,49))
crate("H2",Vector3.new(-37,0,-8),Color3.fromRGB(113,72,49))
fireBowl("H2",Vector3.new(-4,0,-2))
fireBowl("H2",Vector3.new(-58,0,42))
stoneRing("H2",Vector3.new(210,0,-150),Color3.fromRGB(92,73,70))

-- Chariot brisé H2 / camp de fouilles A2 : interactables story.
local wagonPos=ground("H2",Vector3.new(105,0,45))
local wagon=part(poiFolder,"H2_BrokenWagon",Vector3.new(10,2,5),wagonPos+Vector3.new(0,1.2,0),Color3.fromRGB(95,62,43),Enum.Material.WoodPlanks)
wagon:SetAttribute("StoryPoint","BrokenWagon")
wagon:SetAttribute("ZoneId","H2")

local campPos=ground("A2",Vector3.new(105,0,45))
local camp=part(poiFolder,"A2_MarauderCamp",Vector3.new(9,1,7),campPos+Vector3.new(0,0.6,0),Color3.fromRGB(90,72,57),Enum.Material.WoodPlanks)
camp:SetAttribute("StoryPoint","MarauderCamp")
camp:SetAttribute("ZoneId","A2")

-- Stèles / porte : points d'intérêt visibles.
for _,info in ipairs({
    {"A2","RuinA",Vector3.new(-135,0,-65),Color3.fromRGB(112,132,145)},
    {"A2","RuinB",Vector3.new(-172,0,-105),Color3.fromRGB(112,132,145)},
    {"A2","RuinC",Vector3.new(-110,0,-145),Color3.fromRGB(112,132,145)},
    {"H2","SealedGate",Vector3.new(210,0,-150),Color3.fromRGB(92,73,70)},
}) do
    local g=ground(info[1],info[3])
    local p=part(poiFolder,info[1].."_"..info[2],Vector3.new(5,13,3),g+Vector3.new(0,6.5,0),info[4],Enum.Material.Slate)
    p:SetAttribute("StoryPoint",info[2])
    p:SetAttribute("ZoneId",info[1])
end

-- Remplace les mobs clonés A2/H2 par des familles distinctes.
local mapping = {
    A2={"Brumelin","Brumelin","Brumelin","MaraudeurA2","MaraudeurA2","MaraudeurA2","SylvainA2","SylvainA2","SylvainA2","SentinelleA2","SentinelleA2","SentinelleA2","GardienMousse","GardienMousse","ColosseA2"},
    H2={"Fouisseur","Fouisseur","Fouisseur","PillardH2","PillardH2","PillardH2","ChacalCendre","ChacalCendre","ChacalCendre","GolemBasalte","GolemBasalte","GolemBasalte","GolemBasalte","GolemBasalte","TitanH2"},
}

for _,marker in ipairs(spawns:GetChildren()) do
    local zoneId=marker:GetAttribute("ZoneId")
    if mapping[zoneId] then
        local index=tonumber(marker.Name:match("(%d+)$"))
        if index and mapping[zoneId][index] then
            marker:SetAttribute("MobId",mapping[zoneId][index])
        end
    end
end


Generation.Complete(world, "Polish")
