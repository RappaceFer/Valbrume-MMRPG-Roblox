--[[
Valbrume Terrain Continuity Audit v1.0
READ-ONLY / NON-DESTRUCTIVE.

Purpose:
- run in Play mode after Valbrume world generation;
- detect terrain gaps, water/lava crossings, steep terrain and abrupt height steps;
- check the four land connectors and both ferry-side dock approaches;
- print compact machine-readable JSONL plus readable summaries.

This script DOES NOT:
- write Terrain;
- move/create/delete gameplay instances;
- modify Attributes;
- modify DataStores.

Recommended:
1) Open VALBRUME_DEV.
2) Start Play.
3) Wait until the world is visibly loaded.
4) View > Output and View > Command Bar.
5) Paste this entire script into the Command Bar while Play is running.
6) Copy everything between VALBRUME_TERRAIN_AUDIT_BEGIN/END and send it back.
]]

local HttpService = game:GetService("HttpService")
local Terrain = workspace.Terrain

local CONFIG = {
	VERSION = "1.0.0",
	SAMPLE_STEP = 12,
	RAY_START_Y = 420,
	RAY_LENGTH = 900,
	MAX_STEP_HEIGHT = 7,
	MAX_SLOPE_DEGREES = 32,
	ROUTE_SIDE_OFFSETS = {0},
	SEAM_SIDE_OFFSETS = {-48, -32, -16, 0, 16, 32, 48},
	DOCK_Z_OFFSETS = {-24, -12, 0, 12, 24},
}

local function emit(kind, data)
	print(HttpService:JSONEncode({
		type = kind,
		data = data,
	}))
end

local function v2(x, z)
	return Vector2.new(x, z)
end

local function vec3(v)
	return {x = v.X, y = v.Y, z = v.Z}
end

local function waitForWorld()
	local world = workspace:WaitForChild("ValbrumeWorld", 30)
	assert(world, "ValbrumeWorld introuvable")

	local deadline = os.clock() + 90
	while world:GetAttribute("GenerationReady") ~= true and os.clock() < deadline do
		task.wait(0.25)
	end

	assert(
		world:GetAttribute("GenerationReady") == true,
		"GenerationReady n'est pas devenu true avant le timeout"
	)

	return world
end

local function terrainHit(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {Terrain}
	params.IgnoreWater = false

	return workspace:Raycast(
		Vector3.new(x, CONFIG.RAY_START_Y, z),
		Vector3.new(0, -CONFIG.RAY_LENGTH, 0),
		params
	)
end

local function slopeDegrees(normal)
	local y = math.clamp(normal.Y, -1, 1)
	return math.deg(math.acos(y))
end

local function classifyHit(hit)
	if not hit then
		return "MISSING"
	end

	if hit.Material == Enum.Material.Water then
		return "WATER"
	end

	if hit.Material == Enum.Material.CrackedLava then
		return "LAVA"
	end

	local slope = slopeDegrees(hit.Normal)
	if slope > CONFIG.MAX_SLOPE_DEGREES then
		return "STEEP"
	end

	return "OK"
end

local function getCenters(world)
	local centers = {}

	local function fromSpawn(name)
		local spawn = world:FindFirstChild(name)
		if spawn and spawn:IsA("BasePart") then
			return Vector3.new(spawn.Position.X, 0, spawn.Position.Z)
		end
		return nil
	end

	centers.A2 = fromSpawn("A2Spawn")
	centers.H2 = fromSpawn("H2Spawn")

	local expansion = world:FindFirstChild("ExpansionV25")
	local zones = expansion and expansion:FindFirstChild("Zones")

	for _, id in ipairs({"S3", "N4", "O5", "V6"}) do
		local spawn = zones and zones:FindFirstChild(id .. "_ExpansionSpawn")
		if spawn and spawn:IsA("BasePart") then
			centers[id] = Vector3.new(spawn.Position.X, 0, spawn.Position.Z)
		end
	end

	return centers
end

local function sampleLine(name, startPos, endPos, lateralOffset, category)
	local a = v2(startPos.X, startPos.Z)
	local b = v2(endPos.X, endPos.Z)
	local delta = b - a
	local distance = delta.Magnitude

	assert(distance > 0.1, "Segment nul: " .. name)

	local direction = delta.Unit
	local perpendicular = Vector2.new(-direction.Y, direction.X)
	local count = math.max(1, math.ceil(distance / CONFIG.SAMPLE_STEP))

	local stats = {
		name = name,
		category = category,
		offset = lateralOffset,
		distance = distance,
		samples = count + 1,
		ok = 0,
		missing = 0,
		water = 0,
		lava = 0,
		steep = 0,
		steps = 0,
		maxStep = 0,
		maxSlope = 0,
		anomalies = {},
	}

	local previousY = nil
	local activeMissingStart = nil

	for i = 0, count do
		local t = i / count
		local point = a:Lerp(b, t) + perpendicular * lateralOffset
		local hit = terrainHit(point.X, point.Y)
		local status = classifyHit(hit)

		local item = {
			index = i,
			t = t,
			x = point.X,
			z = point.Y,
			status = status,
		}

		if hit then
			local slope = slopeDegrees(hit.Normal)
			item.y = hit.Position.Y
			item.material = tostring(hit.Material)
			item.slope = slope
			stats.maxSlope = math.max(stats.maxSlope, slope)

			if previousY ~= nil then
				local stepHeight = math.abs(hit.Position.Y - previousY)
				item.stepFromPrevious = stepHeight
				stats.maxStep = math.max(stats.maxStep, stepHeight)

				if stepHeight > CONFIG.MAX_STEP_HEIGHT then
					stats.steps += 1
					table.insert(stats.anomalies, {
						kind = "HEIGHT_STEP",
						x = point.X,
						y = hit.Position.Y,
						z = point.Y,
						step = stepHeight,
						material = tostring(hit.Material),
					})
				end
			end

			previousY = hit.Position.Y
		else
			previousY = nil
		end

		if status == "OK" then
			stats.ok += 1
		elseif status == "MISSING" then
			stats.missing += 1
		elseif status == "WATER" then
			stats.water += 1
		elseif status == "LAVA" then
			stats.lava += 1
		elseif status == "STEEP" then
			stats.steep += 1
		end

		if status ~= "OK" and #stats.anomalies < 120 then
			table.insert(stats.anomalies, item)
		end

		if status == "MISSING" then
			if not activeMissingStart then
				activeMissingStart = {
					index = i,
					x = point.X,
					z = point.Y,
					t = t,
				}
			end
		elseif activeMissingStart then
			activeMissingStart.endIndex = i - 1
			activeMissingStart.endT = (i - 1) / count
			activeMissingStart.endX = a:Lerp(b, activeMissingStart.endT).X
				+ perpendicular.X * lateralOffset
			activeMissingStart.endZ = a:Lerp(b, activeMissingStart.endT).Y
				+ perpendicular.Y * lateralOffset

			table.insert(stats.anomalies, {
				kind = "MISSING_RUN",
				start = activeMissingStart,
			})
			activeMissingStart = nil
		end
	end

	if activeMissingStart then
		activeMissingStart.endIndex = count
		activeMissingStart.endT = 1
		activeMissingStart.endX = b.X + perpendicular.X * lateralOffset
		activeMissingStart.endZ = b.Y + perpendicular.Y * lateralOffset
		table.insert(stats.anomalies, {
			kind = "MISSING_RUN",
			start = activeMissingStart,
		})
	end

	return stats
end

local function printSummary(stats)
	local severity = "OK"

	if stats.missing > 0 then
		severity = "HOLE"
	elseif stats.lava > 0 then
		severity = "LAVA"
	elseif stats.water > 0 then
		severity = "WATER"
	elseif stats.steps > 0 or stats.steep > 0 then
		severity = "ROUGH"
	end

	print(string.format(
		"[TERRAIN %s] %s offset=%+.1f | samples=%d ok=%d missing=%d water=%d lava=%d steep=%d heightSteps=%d maxStep=%.2f maxSlope=%.1f°",
		severity,
		stats.name,
		stats.offset,
		stats.samples,
		stats.ok,
		stats.missing,
		stats.water,
		stats.lava,
		stats.steep,
		stats.steps,
		stats.maxStep,
		stats.maxSlope
	))
end

local function scanConnector(results, name, a, b)
	for _, offset in ipairs(CONFIG.ROUTE_SIDE_OFFSETS) do
		local stats = sampleLine(name, a, b, offset, "ROUTE_CENTER")
		table.insert(results, stats)
		printSummary(stats)
		emit("SEGMENT", stats)
	end

	-- A narrower seam scan near the theoretical midpoint.
	local av = v2(a.X, a.Z)
	local bv = v2(b.X, b.Z)
	local dir = (bv - av).Unit
	local mid = av:Lerp(bv, 0.5)
	local halfLength = 115
	local seamA = mid - dir * halfLength
	local seamB = mid + dir * halfLength

	for _, offset in ipairs(CONFIG.SEAM_SIDE_OFFSETS) do
		local stats = sampleLine(
			name .. "_SEAM",
			Vector3.new(seamA.X, 0, seamA.Y),
			Vector3.new(seamB.X, 0, seamB.Y),
			offset,
			"SEAM_BAND"
		)
		table.insert(results, stats)
		printSummary(stats)
		emit("SEGMENT", stats)
	end
end

local function scanDockApproaches(results)
	-- These ranges deliberately cover the expected edge of A2/H2
	-- and the shore/dock strip created by OpenWorldContinentsV28.
	local dockSegments = {
		{
			name = "A2_TO_ELYNDRA_DOCK",
			a = Vector3.new(-620, 0, 0),
			b = Vector3.new(-485, 0, 0),
		},
		{
			name = "H2_TO_VARKHUN_DOCK",
			a = Vector3.new(620, 0, 0),
			b = Vector3.new(485, 0, 0),
		},
	}

	for _, seg in ipairs(dockSegments) do
		for _, zOffset in ipairs(CONFIG.DOCK_Z_OFFSETS) do
			local a = seg.a + Vector3.new(0, 0, zOffset)
			local b = seg.b + Vector3.new(0, 0, zOffset)
			local stats = sampleLine(
				seg.name,
				a,
				b,
				0,
				"DOCK_APPROACH"
			)
			stats.zOffset = zOffset
			table.insert(results, stats)
			printSummary(stats)
			emit("SEGMENT", stats)
		end
	end
end

local function scanZoneEdges(results, centers)
	for _, id in ipairs({"A2", "H2", "S3", "N4", "O5", "V6"}) do
		local c = centers[id]
		if c then
			local radius = (id == "A2" or id == "H2") and 300 or 295
			local samples = 48
			local missing = 0
			local water = 0
			local lava = 0
			local steep = 0
			local points = {}

			for i = 0, samples - 1 do
				local angle = i / samples * math.pi * 2
				local x = c.X + math.cos(angle) * radius
				local z = c.Z + math.sin(angle) * radius
				local hit = terrainHit(x, z)
				local status = classifyHit(hit)

				if status == "MISSING" then missing += 1 end
				if status == "WATER" then water += 1 end
				if status == "LAVA" then lava += 1 end
				if status == "STEEP" then steep += 1 end

				if status ~= "OK" then
					table.insert(points, {
						x = x,
						z = z,
						y = hit and hit.Position.Y or nil,
						material = hit and tostring(hit.Material) or nil,
						slope = hit and slopeDegrees(hit.Normal) or nil,
						status = status,
					})
				end
			end

			local record = {
				name = id,
				category = "ZONE_EDGE_RING",
				radius = radius,
				samples = samples,
				missing = missing,
				water = water,
				lava = lava,
				steep = steep,
				anomalies = points,
			}

			table.insert(results, record)

			print(string.format(
				"[EDGE %s] samples=%d missing=%d water=%d lava=%d steep=%d",
				id, samples, missing, water, lava, steep
			))
			emit("ZONE_EDGE", record)
		end
	end
end

print("=== VALBRUME_TERRAIN_AUDIT_BEGIN ===")

local world = waitForWorld()
local centers = getCenters(world)

emit("META", {
	version = CONFIG.VERSION,
	generationId = world:GetAttribute("GenerationId"),
	generationStage = world:GetAttribute("GenerationStage"),
	generationReady = world:GetAttribute("GenerationReady"),
	config = CONFIG,
	centers = {
		A2 = centers.A2 and vec3(centers.A2) or nil,
		H2 = centers.H2 and vec3(centers.H2) or nil,
		S3 = centers.S3 and vec3(centers.S3) or nil,
		N4 = centers.N4 and vec3(centers.N4) or nil,
		O5 = centers.O5 and vec3(centers.O5) or nil,
		V6 = centers.V6 and vec3(centers.V6) or nil,
	},
})

local required = {"A2", "H2", "S3", "N4", "O5", "V6"}
for _, id in ipairs(required) do
	assert(centers[id], "Centre/spawn introuvable pour " .. id)
end

local results = {}

scanConnector(results, "A2_S3", centers.A2, centers.S3)
scanConnector(results, "A2_N4", centers.A2, centers.N4)
scanConnector(results, "H2_O5", centers.H2, centers.O5)
scanConnector(results, "H2_V6", centers.H2, centers.V6)

scanDockApproaches(results)
scanZoneEdges(results, centers)

local totals = {
	segments = 0,
	missingSamples = 0,
	waterSamples = 0,
	lavaSamples = 0,
	steepSamples = 0,
	heightSteps = 0,
}

for _, r in ipairs(results) do
	if r.category ~= "ZONE_EDGE_RING" then
		totals.segments += 1
		totals.missingSamples += r.missing or 0
		totals.waterSamples += r.water or 0
		totals.lavaSamples += r.lava or 0
		totals.steepSamples += r.steep or 0
		totals.heightSteps += r.steps or 0
	end
end

emit("SUMMARY", totals)

print(string.format(
	"[TERRAIN SUMMARY] segments=%d missing=%d water=%d lava=%d steep=%d heightSteps=%d",
	totals.segments,
	totals.missingSamples,
	totals.waterSamples,
	totals.lavaSamples,
	totals.steepSamples,
	totals.heightSteps
))

print("=== VALBRUME_TERRAIN_AUDIT_END ===")
