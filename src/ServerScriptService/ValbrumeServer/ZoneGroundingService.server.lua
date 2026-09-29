local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace.Terrain

local C = require(ReplicatedStorage:WaitForChild("Valbrume"):WaitForChild("Config"))
local Generation = require(script.Parent.WorldGeneration)
local world = Generation.Await("Polish")

local decor = world:WaitForChild("Decor")
local npcs = world:WaitForChild("NPCs")
local collectibles = world:WaitForChild("Collectibles")
local spawns = world:WaitForChild("Spawns")
local enemies = world:WaitForChild("Enemies")

local function terrainHit(x, z, ignore)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {Terrain}
    params.IgnoreWater = false

    local result = workspace:Raycast(
        Vector3.new(x, 260, z),
        Vector3.new(0, -520, 0),
        params
    )

    return result
end

local function zoneForPosition(position)
    local bestId
    local bestDistance = math.huge

    for zoneId, zone in pairs(C.Zones) do
        local delta = Vector2.new(
            position.X - zone.Origin.X,
            position.Z - zone.Origin.Z
        )
        local distance = delta.Magnitude

        if distance < bestDistance then
            bestDistance = distance
            bestId = zoneId
        end
    end

    return bestId
end

local function snapPart(part, clearance)
    if not part or not part:IsA("BasePart") then
        return false
    end

    local hit = terrainHit(part.Position.X, part.Position.Z)
    if not hit then
        return false
    end

    local wantedY = hit.Position.Y + (clearance or part.Size.Y * 0.5)

    if math.abs(part.Position.Y - wantedY) > 0.25 then
        part.Position = Vector3.new(part.Position.X, wantedY, part.Position.Z)
    end

    return true
end

local function snapModel(model, clearance)
    if not model or not model:IsA("Model") then
        return false
    end

    local root = model.PrimaryPart
        or model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChildWhichIsA("BasePart")

    if not root then
        return false
    end

    local hit = terrainHit(root.Position.X, root.Position.Z)
    if not hit then
        return false
    end

    local extents = model:GetExtentsSize()
    local bottomClearance = clearance or math.max(1, extents.Y * 0.5)
    local wantedY = hit.Position.Y + bottomClearance
    local deltaY = wantedY - root.Position.Y

    if math.abs(deltaY) > 0.25 then
        model:PivotTo(model:GetPivot() + Vector3.new(0, deltaY, 0))
    end

    return true
end

local function makeCampPad(zoneId, relative, size, material)
    local zone = C.Zones[zoneId]
    if not zone then
        return
    end

    local worldPos = zone.Origin + relative
    local hit = terrainHit(worldPos.X, worldPos.Z)
    if not hit then
        return
    end

    -- Petite plateforme visuelle/collision au-dessus du terrain.
    -- On ne remodèle pas tout le Smooth Terrain pour éviter de casser le relief.
    local name = "V22_CampPad_" .. zoneId .. "_" .. tostring(relative.X) .. "_" .. tostring(relative.Z)

    local existing = decor:FindFirstChild(name)
    if existing then
        existing:Destroy()
    end

    local pad = Instance.new("Part")
    pad.Name = name
    pad.Size = size
    pad.Position = Vector3.new(worldPos.X, hit.Position.Y + 0.35, worldPos.Z)
    pad.Anchored = true
    pad.CanCollide = true
    pad.CanQuery = true
    pad.CanTouch = false
    pad.Material = material
    pad.Color = zoneId == "A2"
        and Color3.fromRGB(137, 132, 113)
        or Color3.fromRGB(151, 111, 80)
    pad.TopSurface = Enum.SurfaceType.Smooth
    pad.BottomSurface = Enum.SurfaceType.Smooth
    pad.Parent = decor
end

local function correctStaticWorld()
    -- Existing houses used fixed floor heights (26/24), below the final terrain.
    -- Align their base only; preserve their geometry and refuse large relocations.
    for _,house in decor:GetChildren() do
        if house:IsA("Model") and house.Name == "House" then
            local cf, size = house:GetBoundingBox()
            local highest = -math.huge
            for _,offset in {Vector2.zero, Vector2.new(-.45,-.45), Vector2.new(.45,-.45),
                Vector2.new(-.45,.45), Vector2.new(.45,.45)} do
                local hit = terrainHit(cf.X+offset.X*size.X, cf.Z+offset.Y*size.Z)
                if hit then highest = math.max(highest, hit.Position.Y) end
            end
            local rise = highest + .1 - (cf.Y-size.Y/2)
            if rise > .1 and rise <= 8 then house:PivotTo(house:GetPivot()+Vector3.new(0,rise,0)) end
        end
    end

    -- PNJ : le body est le PrimaryPart créé par WorldBuilder.
    for _, npc in ipairs(npcs:GetChildren()) do
        snapModel(npc, 2.1)
    end

    -- Cristaux.
    for _, crystal in ipairs(collectibles:GetChildren()) do
        snapModel(crystal, 2.15)
    end

    -- Marqueurs de spawn : on les place légèrement au-dessus du sol.
    for _, marker in ipairs(spawns:GetChildren()) do
        if marker:IsA("BasePart") then
            snapPart(marker, 3.2)
        end
    end
end

local function correctEnemy(model)
    if not model:IsA("Model") then
        return
    end

    if model:GetAttribute("DungeonId") then
        -- Le donjon a son propre sol et ne doit jamais être groundé sur le Terrain.
        return
    end

    task.defer(function()
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")

        if not humanoid or not root then
            return
        end

        -- Les rigs V1 sont centrés autour du HumanoidRootPart.
        -- 3 studs donnent assez de marge pour les jambes sur une pente.
        snapModel(model, 3.0 * (model:GetScale() or 1))

        pcall(function()
            root:SetNetworkOwner(nil)
        end)
    end)
end

-- Camps plus lisibles et réellement plats au niveau gameplay.
makeCampPad("A2", Vector3.new(-35, 0, 15), Vector3.new(118, 1, 110), Enum.Material.Cobblestone)
makeCampPad("H2", Vector3.new(-35, 0, 15), Vector3.new(118, 1, 110), Enum.Material.Sandstone)

-- Petites plateformes pour donneurs de quête + soigneurs.
makeCampPad("A2", Vector3.new(0, 0, -20), Vector3.new(34, 1, 22), Enum.Material.Cobblestone)
makeCampPad("H2", Vector3.new(0, 0, -20), Vector3.new(34, 1, 22), Enum.Material.Sandstone)

correctStaticWorld()

enemies.ChildAdded:Connect(function(child)
    correctEnemy(child)
end)

npcs.ChildAdded:Connect(function(child)
    snapModel(child, 2.1)
end)

collectibles.ChildAdded:Connect(function(child)
    snapModel(child, 2.15)
end)

-- Garde-fou : si un mob du monde ouvert tombe/s'enfonce anormalement,
-- on le remet sur la surface locale. Les mobs de donjon sont exclus.
task.spawn(function()
    while true do
        task.wait(2)

        for _, enemy in ipairs(enemies:GetChildren()) do
            if not enemy:GetAttribute("DungeonId") then
                local root = enemy:FindFirstChild("HumanoidRootPart")
                local humanoid = enemy:FindFirstChildOfClass("Humanoid")

                if root and humanoid and humanoid.Health > 0 then
                    local hit = terrainHit(root.Position.X, root.Position.Z)

                    if hit and root.Position.Y < hit.Position.Y + 0.5 then
                        snapModel(enemy, 3.0 * (enemy:GetScale() or 1))
                    end
                end
            end
        end
    end
end)

print("[Valbrume V2.2] Grounding A2/H2 actif.")

Generation.Complete(world, "Grounding")
