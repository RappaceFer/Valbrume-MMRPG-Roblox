--[[
    Valbrume open-world geography / V3 world pass.

    Compatibility contract:
    - keeps the existing Generation stage name "Continents";
    - keeps workspace.ValbrumeWorld.OpenWorldV28 for V2.8 clients/QA;
    - keeps Roads / POI / SeaTravel / Hazards folders;
    - keeps the six existing region centers and existing gameplay services untouched.

    V3 goal:
    Build continuous, readable and traversable geography instead of relying on
    isolated terrain balls. Routes are graded ribbons with carved headroom,
    wide terrain shoulders and continuous visual roads.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace.Terrain

local package = ReplicatedStorage:WaitForChild("Valbrume")
local C = require(package:WaitForChild("Config"))
local server = script.Parent
local Data = require(server:WaitForChild("PlayerDataService"))
local Generation = require(script.Parent.WorldGeneration)

local world = Generation.Await("Expansion")
local expansion = world:WaitForChild("ExpansionV25")
local zones = expansion:WaitForChild("Zones")

local oldTravel = expansion:FindFirstChild("Travel")
if oldTravel then
    oldTravel:Destroy()
end

local oldRoot = world:FindFirstChild("OpenWorldV28")
if oldRoot then
    oldRoot:Destroy()
end

local root = Instance.new("Folder")
root.Name = "OpenWorldV28"
root:SetAttribute("WorldRevision", "V3")
root:SetAttribute("GeographyRevision", "3.0")
root.Parent = world

local roads = Instance.new("Folder")
roads.Name = "Roads"
roads.Parent = root

local poi = Instance.new("Folder")
poi.Name = "POI"
poi.Parent = root

local sea = Instance.new("Folder")
sea.Name = "SeaTravel"
sea.Parent = root

local hazards = Instance.new("Folder")
hazards.Name = "Hazards"
hazards.Parent = root

local geography = Instance.new("Folder")
geography.Name = "GeographyV3"
geography.Parent = root

local function part(parent, name, size, cf, color, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.CanCollide = true
    p.CanTouch = false
    p.CanQuery = true
    p.Color = color
    p.Material = material or Enum.Material.Slate
    p.Transparency = transparency or 0
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function label(adornee, title, subtitle, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "WorldLabel"
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(280, 76)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 130
    gui.Parent = adornee

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = title .. "\n" .. subtitle
    text.TextColor3 = color
    text.TextStrokeTransparency = 0.25
    text.Font = Enum.Font.GothamBold
    text.TextSize = 15
    text.TextWrapped = true
    text.Parent = gui
end

local function terrainHit(x, z)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {Terrain}
    params.IgnoreWater = true

    return workspace:Raycast(
        Vector3.new(x, 360, z),
        Vector3.new(0, -760, 0),
        params
    )
end

local function groundY(x, z, fallback)
    local hit = terrainHit(x, z)
    return hit and hit.Position.Y or fallback
end

local function spawnOf(id)
    if C.Zones[id] then
        return world:FindFirstChild(id .. "Spawn")
    end

    return zones:FindFirstChild(id .. "_ExpansionSpawn")
end

local function center(id)
    if C.Zones[id] then
        return C.Zones[id].Origin
    end

    local spawn = spawnOf(id)
    return spawn and Vector3.new(spawn.Position.X, 0, spawn.Position.Z)
end

local names = {
    A2 = "Val d'Astréa",
    S3 = "Sylvebrume",
    N4 = "Caps de Nacre",
    H2 = "Terres cendrées de Khar",
    O5 = "Forges d'Ormefer",
    V6 = "Profondeurs de l'Écho",
}

-- The sea remains the narrative divide between the two home continents.
-- Shores intentionally overlap the landmasses so there is never a void seam.
Terrain:FillBlock(
    CFrame.new(0, -17, 0),
    Vector3.new(900, 50, 2300),
    Enum.Material.Water
)

Terrain:FillBlock(
    CFrame.new(-505, 7, 0),
    Vector3.new(190, 24, 2100),
    Enum.Material.Sand
)

Terrain:FillBlock(
    CFrame.new(505, 7, 0),
    Vector3.new(190, 24, 2100),
    Enum.Material.Sand
)

local function smoothstep(t)
    return t * t * (3 - 2 * t)
end

local function routeProfile(a, b, sampleCount)
    local raw = table.create(sampleCount + 1)
    local positions = table.create(sampleCount + 1)

    local a2 = Vector2.new(a.X, a.Z)
    local b2 = Vector2.new(b.X, b.Z)

    for i = 0, sampleCount do
        local t = i / sampleCount
        local p = a2:Lerp(b2, t)
        positions[i + 1] = p
        raw[i + 1] = groundY(p.X, p.Y, 24)
    end

    -- Moving average removes spikes generated by overlapping terrain balls.
    local smoothed = table.create(sampleCount + 1)
    for i = 1, sampleCount + 1 do
        local total = 0
        local count = 0

        for j = math.max(1, i - 2), math.min(sampleCount + 1, i + 2) do
            total += raw[j]
            count += 1
        end

        smoothed[i] = total / count
    end

    -- A route is gameplay space: limit the vertical change between samples.
    local maxDelta = 4.5

    for i = 2, sampleCount + 1 do
        smoothed[i] = math.clamp(
            smoothed[i],
            smoothed[i - 1] - maxDelta,
            smoothed[i - 1] + maxDelta
        )
    end

    for i = sampleCount, 1, -1 do
        smoothed[i] = math.clamp(
            smoothed[i],
            smoothed[i + 1] - maxDelta,
            smoothed[i + 1] + maxDelta
        )
    end

    return positions, smoothed
end

local function fillRamp(a, b, width, depth, material)
    local direction = b - a
    local length = direction.Magnitude

    if length < 0.1 then
        return
    end

    local mid = (a + b) * 0.5
    local cf = CFrame.lookAt(mid, b)

    Terrain:FillBlock(
        cf * CFrame.new(0, -depth * 0.48, 0),
        Vector3.new(width, depth, length + 8),
        material
    )
end

local function carveHeadroom(a, b, width)
    local direction = b - a
    local length = direction.Magnitude

    if length < 0.1 then
        return
    end

    local mid = (a + b) * 0.5
    local cf = CFrame.lookAt(mid, b)

    -- Bottom of the cut stays well above the walking surface.
    Terrain:FillBlock(
        cf * CFrame.new(0, 34, 0),
        Vector3.new(width, 54, length + 8),
        Enum.Material.Air
    )
end

local ROUTES = {
    {
        Id = "A2_S3",
        From = "A2",
        To = "S3",
        Title = "Passage des Racines",
        Material = Enum.Material.Ground,
        Color = Color3.fromRGB(91, 119, 89),
        Width = 86,
    },
    {
        Id = "A2_N4",
        From = "A2",
        To = "N4",
        Title = "Col des Embruns",
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(111, 132, 141),
        Width = 84,
    },
    {
        Id = "H2_O5",
        From = "H2",
        To = "O5",
        Title = "Défilé des Scories",
        Material = Enum.Material.Basalt,
        Color = Color3.fromRGB(116, 82, 66),
        Width = 86,
    },
    {
        Id = "H2_V6",
        From = "H2",
        To = "V6",
        Title = "Faille des Murmures",
        Material = Enum.Material.Rock,
        Color = Color3.fromRGB(104, 87, 125),
        Width = 84,
    },
}

local function buildRoute(definition)
    local a = center(definition.From)
    local b = center(definition.To)

    if not a or not b then
        warn("[Valbrume V3] Route impossible, centre absent: " .. definition.Id)
        return
    end

    local routeFolder = Instance.new("Folder")
    routeFolder.Name = definition.Id
    routeFolder:SetAttribute("FromRegion", definition.From)
    routeFolder:SetAttribute("ToRegion", definition.To)
    routeFolder:SetAttribute("V3Route", true)
    routeFolder.Parent = roads

    local distance = (Vector2.new(b.X, b.Z) - Vector2.new(a.X, a.Z)).Magnitude
    local sampleCount = math.max(16, math.ceil(distance / 22))
    local positions, heights = routeProfile(a, b, sampleCount)

    for i = 1, sampleCount do
        local p0 = positions[i]
        local p1 = positions[i + 1]
        local y0 = heights[i]
        local y1 = heights[i + 1]

        local a3 = Vector3.new(p0.X, y0, p0.Y)
        local b3 = Vector3.new(p1.X, y1, p1.Y)

        -- Solid broad core + softer rock shoulders.
        fillRamp(a3, b3, definition.Width + 34, 34, Enum.Material.Rock)
        fillRamp(a3 + Vector3.new(0, 2, 0), b3 + Vector3.new(0, 2, 0), definition.Width, 22, definition.Material)
        carveHeadroom(a3, b3, definition.Width * 0.72)

        local visualDirection = b3 - a3
        local visualLength = visualDirection.Magnitude
        local visualMid = (a3 + b3) * 0.5 + Vector3.new(0, 1.15, 0)
        local roadPart = part(
            routeFolder,
            string.format("Path_%02d", i),
            Vector3.new(17, 0.45, visualLength + 2),
            CFrame.lookAt(visualMid, b3 + Vector3.new(0, 1.15, 0)),
            definition.Color,
            definition.Material,
            0.08
        )
        roadPart.CanCollide = false
        roadPart.CanTouch = false
        roadPart.CanQuery = false
    end

    -- Wide arrival plazas prevent the route from pinching at region seams.
    for _, endpoint in ipairs({
        {Region = definition.From, Point = positions[1], Y = heights[1]},
        {Region = definition.To, Point = positions[#positions], Y = heights[#heights]},
    }) do
        Terrain:FillBall(
            Vector3.new(endpoint.Point.X, endpoint.Y - 20, endpoint.Point.Y),
            definition.Width * 0.72,
            definition.Material
        )
    end

    local midIndex = math.floor(#positions * 0.5)
    local mid2 = positions[midIndex]
    local midY = heights[midIndex]

    local marker = part(
        poi,
        definition.Id .. "_Marker",
        Vector3.new(5, 10, 5),
        CFrame.new(mid2.X, midY + 5, mid2.Y),
        definition.Color,
        Enum.Material.Slate
    )

    marker.CanCollide = false
    marker.CanQuery = false

    label(
        marker,
        definition.Title,
        names[definition.From] .. " ↔ " .. names[definition.To],
        definition.Color
    )
end

for _, routeDefinition in ipairs(ROUTES) do
    buildRoute(routeDefinition)
end

local function buildCoastCauseway(name, startPos, endPos, material, color)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = geography

    local segments = 8

    for i = 0, segments - 1 do
        local t0 = i / segments
        local t1 = (i + 1) / segments
        local eased0 = smoothstep(t0)
        local eased1 = smoothstep(t1)

        local p0 = startPos:Lerp(endPos, t0)
        local p1 = startPos:Lerp(endPos, t1)

        -- Gently descend toward the dock.
        p0 = Vector3.new(p0.X, startPos.Y + (endPos.Y - startPos.Y) * eased0, p0.Z)
        p1 = Vector3.new(p1.X, startPos.Y + (endPos.Y - startPos.Y) * eased1, p1.Z)

        fillRamp(p0, p1, 64, 26, material)
        carveHeadroom(p0, p1, 48)

        local d = p1 - p0
        local road = part(
            folder,
            string.format("Causeway_%02d", i + 1),
            Vector3.new(20, 0.5, d.Magnitude + 2),
            CFrame.lookAt((p0 + p1) * 0.5 + Vector3.new(0, 1, 0), p1 + Vector3.new(0, 1, 0)),
            color,
            material,
            0.05
        )
        road.CanCollide = false
        road.CanQuery = false
    end
end

buildCoastCauseway(
    "ElyndraCauseway",
    Vector3.new(-625, 24, 0),
    Vector3.new(-500, 16, 0),
    Enum.Material.Ground,
    Color3.fromRGB(121, 118, 92)
)

buildCoastCauseway(
    "VarkhunCauseway",
    Vector3.new(625, 24, 0),
    Vector3.new(500, 16, 0),
    Enum.Material.Sandstone,
    Color3.fromRGB(151, 111, 80)
)

-- Maritime silhouettes keep the central sea from reading as an empty rectangle.
for i, island in ipairs({
    {Position = Vector3.new(-155, 5, -430), Radius = 68, Cap = Enum.Material.Grass},
    {Position = Vector3.new(140, 6, 360), Radius = 61, Cap = Enum.Material.Rock},
    {Position = Vector3.new(-60, 4, 780), Radius = 47, Cap = Enum.Material.Grass},
}) do
    Terrain:FillBall(island.Position, island.Radius, Enum.Material.Rock)
    Terrain:FillBall(
        island.Position + Vector3.new(0, 15, 0),
        island.Radius * 0.64,
        island.Cap
    )

    local beacon = part(
        geography,
        "SeaLandmark_" .. i,
        Vector3.new(4, 14, 4),
        CFrame.new(island.Position + Vector3.new(0, island.Radius * 0.55, 0)),
        Color3.fromRGB(176, 160, 128),
        Enum.Material.Slate
    )
    beacon.CanCollide = false
end

print("[Valbrume V3] Géographie maîtresse : routes continues, raccords et littoraux reconstruits.")

Generation.Complete(world, "Continents")
