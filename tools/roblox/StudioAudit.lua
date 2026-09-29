--[[
Valbrume Studio Audit v1
NON-DESTRUCTIVE / READ-ONLY.

Run this from Roblox Studio's Command Bar while the place is open in EDIT mode.
It only reads the DataModel and prints an export to Output.
It does NOT create, delete, move, rename, reparent, modify, save, or call DataStores.

Recommended:
1) View > Output
2) View > Command Bar
3) Paste this entire script in Command Bar and run it.
4) Wait for === VALBRUME_AUDIT_END ===
5) Copy everything from === VALBRUME_AUDIT_BEGIN === to === VALBRUME_AUDIT_END ===
6) Send that text back for analysis.

Important:
- Script.Source reading is attempted with pcall. Studio/security settings may deny it.
- Full script source is included when readable because architecture cannot be audited reliably from names alone.
- The output can be large on a mature map. It is chunked to keep individual prints manageable.
]]

local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local CONFIG = {
	VERSION = "1.0.0",
	CHUNK_SIZE = 45000,
	MAX_SOURCE_CHARS_PER_SCRIPT = 500000,
	INCLUDE_SCRIPT_SOURCE = true,
	INCLUDE_ALL_BASEPART_TRANSFORMS = true,
	INCLUDE_GUI_LAYOUT = true,
	INCLUDE_ATTRIBUTES = true,
	INCLUDE_COLLECTION_TAGS = true,
}

local ROOT_SERVICE_NAMES = {
	"Workspace",
	"ServerScriptService",
	"ReplicatedStorage",
	"ServerStorage",
	"StarterPlayer",
	"StarterGui",
	"StarterPack",
	"Teams",
	"Lighting",
	"SoundService",
}

local INTERESTING_CLASSES = {
	RemoteEvent = true,
	RemoteFunction = true,
	UnreliableRemoteEvent = true,
	BindableEvent = true,
	BindableFunction = true,
	Script = true,
	LocalScript = true,
	ModuleScript = true,
	Tool = true,
	Humanoid = true,
	SpawnLocation = true,
	ProximityPrompt = true,
	ClickDetector = true,
	Animation = true,
	Sound = true,
	ScreenGui = true,
	SurfaceGui = true,
	BillboardGui = true,
	Frame = true,
	TextLabel = true,
	TextButton = true,
	ImageLabel = true,
	ImageButton = true,
	ScrollingFrame = true,
	UIListLayout = true,
	UIGridLayout = true,
	Folder = true,
	Configuration = true,
	ObjectValue = true,
	StringValue = true,
	IntValue = true,
	NumberValue = true,
	BoolValue = true,
	CFrameValue = true,
	Vector3Value = true,
	Color3Value = true,
}

local SYSTEM_KEYWORDS = {
	"quest", "mission", "objective",
	"inventory", "item", "equipment", "equip", "weapon", "armor",
	"combat", "damage", "attack", "skill", "ability", "spell", "cooldown",
	"npc", "mob", "enemy", "boss", "spawn",
	"datastore", "profile", "save", "load", "currency", "gold", "xp", "level",
	"remoteevent", "remotefunction",
}

local DATASTORE_PATTERNS = {
	"GetDataStore",
	"GetOrderedDataStore",
	"GetGlobalDataStore",
	"UpdateAsync",
	"SetAsync",
	"GetAsync",
	"RemoveAsync",
	"IncrementAsync",
	"OnUpdate",
	"DataStoreService",
	"ProfileService",
	"ProfileStore",
	"DataStore2",
}

local REMOTE_PATTERNS = {
	"FireServer",
	"InvokeServer",
	"FireClient",
	"FireAllClients",
	"InvokeClient",
	"OnServerEvent",
	"OnServerInvoke",
	"OnClientEvent",
	"OnClientInvoke",
}

local counters = {
	instances = 0,
	scripts = 0,
	sourceReadable = 0,
	sourceUnreadable = 0,
	remotes = 0,
	baseParts = 0,
	npcsHumanoids = 0,
	spawns = 0,
	tools = 0,
	guiObjects = 0,
	taggedInstances = 0,
	errors = 0,
}

local outputBuffer = ""

local function emitRaw(line)
	outputBuffer ..= line .. "\n"
	if #outputBuffer >= CONFIG.CHUNK_SIZE then
		print(outputBuffer)
		outputBuffer = ""
	end
end

local function flush()
	if #outputBuffer > 0 then
		print(outputBuffer)
		outputBuffer = ""
	end
end

local function emit(recordType, payload)
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode({
			type = recordType,
			data = payload,
		})
	end)
	if ok then
		emitRaw(encoded)
	else
		counters.errors += 1
		emitRaw(HttpService:JSONEncode({
			type = "ENCODE_ERROR",
			data = {
				recordType = recordType,
				error = tostring(encoded),
			},
		}))
	end
end

local function safeGet(instance, propertyName)
	local ok, value = pcall(function()
		return instance[propertyName]
	end)
	if ok then
		return value
	end
	return nil
end

local function enumName(value)
	if typeof(value) == "EnumItem" then
		return tostring(value)
	end
	return value
end

local function vector3(v)
	return {x = v.X, y = v.Y, z = v.Z}
end

local function vector2(v)
	return {x = v.X, y = v.Y}
end

local function color3(v)
	return {r = v.R, g = v.G, b = v.B}
end

local function cframe(cf)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	local rx, ry, rz = cf:ToOrientation()
	return {
		position = {x = x, y = y, z = z},
		rotationRadians = {x = rx, y = ry, z = rz},
		rotationDegrees = {x = math.deg(rx), y = math.deg(ry), z = math.deg(rz)},
		matrix = {r00, r01, r02, r10, r11, r12, r20, r21, r22},
	}
end

local function serializeValue(value)
	local t = typeof(value)
	if t == "nil" then
		return nil
	elseif t == "string" or t == "number" or t == "boolean" then
		return value
	elseif t == "Vector3" then
		return vector3(value)
	elseif t == "Vector2" then
		return vector2(value)
	elseif t == "Color3" then
		return color3(value)
	elseif t == "CFrame" then
		return cframe(value)
	elseif t == "UDim" then
		return {scale = value.Scale, offset = value.Offset}
	elseif t == "UDim2" then
		return {
			x = {scale = value.X.Scale, offset = value.X.Offset},
			y = {scale = value.Y.Scale, offset = value.Y.Offset},
		}
	elseif t == "BrickColor" then
		return {name = value.Name, number = value.Number}
	elseif t == "EnumItem" then
		return tostring(value)
	elseif t == "Instance" then
		return value:GetFullName()
	else
		return tostring(value)
	end
end

local function getAttributes(instance)
	if not CONFIG.INCLUDE_ATTRIBUTES then
		return nil
	end
	local ok, attrs = pcall(function()
		return instance:GetAttributes()
	end)
	if not ok or next(attrs) == nil then
		return nil
	end
	local result = {}
	for key, value in pairs(attrs) do
		result[key] = serializeValue(value)
	end
	return result
end

local function getTags(instance)
	if not CONFIG.INCLUDE_COLLECTION_TAGS then
		return nil
	end
	local ok, tags = pcall(function()
		return CollectionService:GetTags(instance)
	end)
	if not ok or #tags == 0 then
		return nil
	end
	table.sort(tags)
	counters.taggedInstances += 1
	return tags
end

local function keywordHits(text, keywords)
	local lower = string.lower(text)
	local hits = {}
	for _, keyword in ipairs(keywords) do
		if string.find(lower, string.lower(keyword), 1, true) then
			table.insert(hits, keyword)
		end
	end
	return hits
end

local function patternHits(text, patterns)
	local hits = {}
	for _, pattern in ipairs(patterns) do
		if string.find(text, pattern, 1, true) then
			table.insert(hits, pattern)
		end
	end
	return hits
end

local function getScriptSource(instance)
	if not CONFIG.INCLUDE_SCRIPT_SOURCE then
		return nil, "disabled"
	end

	local ok, sourceOrError = pcall(function()
		return instance.Source
	end)

	if not ok then
		counters.sourceUnreadable += 1
		return nil, tostring(sourceOrError)
	end

	counters.sourceReadable += 1
	local source = sourceOrError
	if #source > CONFIG.MAX_SOURCE_CHARS_PER_SCRIPT then
		return string.sub(source, 1, CONFIG.MAX_SOURCE_CHARS_PER_SCRIPT), "truncated:" .. tostring(#source)
	end
	return source, nil
end

local function instanceRecord(instance, rootName)
	local record = {
		name = instance.Name,
		className = instance.ClassName,
		fullName = instance:GetFullName(),
		parent = instance.Parent and instance.Parent:GetFullName() or nil,
		root = rootName,
		archivable = safeGet(instance, "Archivable"),
		attributes = getAttributes(instance),
		tags = getTags(instance),
	}

	if instance:IsA("BasePart") and CONFIG.INCLUDE_ALL_BASEPART_TRANSFORMS then
		counters.baseParts += 1
		record.basePart = {
			cframe = cframe(instance.CFrame),
			size = vector3(instance.Size),
			anchored = instance.Anchored,
			canCollide = instance.CanCollide,
			canTouch = instance.CanTouch,
			canQuery = instance.CanQuery,
			transparency = instance.Transparency,
			material = tostring(instance.Material),
			color = color3(instance.Color),
			collisionGroup = safeGet(instance, "CollisionGroup"),
			massless = safeGet(instance, "Massless"),
		}
	end

	if instance:IsA("Model") then
		local ok, pivot = pcall(function()
			return instance:GetPivot()
		end)
		if ok then
			record.model = {
				pivot = cframe(pivot),
				primaryPart = instance.PrimaryPart and instance.PrimaryPart:GetFullName() or nil,
			}
		end
	end

	if instance:IsA("Humanoid") then
		counters.npcsHumanoids += 1
		record.humanoid = {
			health = instance.Health,
			maxHealth = instance.MaxHealth,
			walkSpeed = instance.WalkSpeed,
			jumpPower = instance.JumpPower,
			rigType = tostring(instance.RigType),
			displayName = instance.DisplayName,
		}
	end

	if instance:IsA("SpawnLocation") then
		counters.spawns += 1
		record.spawn = {
			enabled = instance.Enabled,
			neutral = instance.Neutral,
			duration = instance.Duration,
			teamColor = tostring(instance.TeamColor),
			allowTeamChangeOnTouch = instance.AllowTeamChangeOnTouch,
		}
	end

	if instance:IsA("Tool") then
		counters.tools += 1
		record.tool = {
			requiresHandle = instance.RequiresHandle,
			canBeDropped = instance.CanBeDropped,
			toolTip = instance.ToolTip,
			manualActivationOnly = instance.ManualActivationOnly,
			enabled = instance.Enabled,
		}
	end

	if instance:IsA("RemoteEvent") or instance:IsA("RemoteFunction") or instance.ClassName == "UnreliableRemoteEvent" then
		counters.remotes += 1
		record.remote = true
	end

	if instance:IsA("ValueBase") then
		record.value = serializeValue(safeGet(instance, "Value"))
	end

	if instance:IsA("ProximityPrompt") then
		record.proximityPrompt = {
			actionText = instance.ActionText,
			objectText = instance.ObjectText,
			holdDuration = instance.HoldDuration,
			maxActivationDistance = instance.MaxActivationDistance,
			requiresLineOfSight = instance.RequiresLineOfSight,
			enabled = instance.Enabled,
		}
	end

	if instance:IsA("Animation") then
		record.animation = {
			animationId = instance.AnimationId,
		}
	end

	if instance:IsA("Sound") then
		record.sound = {
			soundId = instance.SoundId,
			volume = instance.Volume,
			looped = instance.Looped,
			playbackSpeed = instance.PlaybackSpeed,
		}
	end

	if CONFIG.INCLUDE_GUI_LAYOUT and instance:IsA("GuiObject") then
		counters.guiObjects += 1
		record.gui = {
			visible = instance.Visible,
			position = serializeValue(instance.Position),
			size = serializeValue(instance.Size),
			anchorPoint = vector2(instance.AnchorPoint),
			layoutOrder = instance.LayoutOrder,
			zIndex = instance.ZIndex,
			automaticSize = tostring(instance.AutomaticSize),
		}
		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			record.gui.text = instance.Text
			record.gui.textSize = instance.TextSize
			record.gui.textScaled = instance.TextScaled
		end
	end

	if instance:IsA("ScreenGui") then
		record.screenGui = {
			enabled = instance.Enabled,
			displayOrder = instance.DisplayOrder,
			ignoreGuiInset = instance.IgnoreGuiInset,
			resetOnSpawn = instance.ResetOnSpawn,
			zIndexBehavior = tostring(instance.ZIndexBehavior),
		}
	end

	return record
end

local function auditScript(instance, rootName)
	counters.scripts += 1

	local source, sourceNote = getScriptSource(instance)
	local scriptRecord = {
		name = instance.Name,
		className = instance.ClassName,
		fullName = instance:GetFullName(),
		parent = instance.Parent and instance.Parent:GetFullName() or nil,
		root = rootName,
		disabled = safeGet(instance, "Disabled"),
		runContext = enumName(safeGet(instance, "RunContext")),
		sourceReadable = source ~= nil,
		sourceNote = sourceNote,
	}

	if source then
		scriptRecord.sourceLength = #source
		scriptRecord.systemKeywordHits = keywordHits(source, SYSTEM_KEYWORDS)
		scriptRecord.dataStoreHits = patternHits(source, DATASTORE_PATTERNS)
		scriptRecord.remoteApiHits = patternHits(source, REMOTE_PATTERNS)
		scriptRecord.source = source
	end

	emit("SCRIPT", scriptRecord)
end

local function auditRoot(root)
	emit("ROOT", {
		name = root.Name,
		className = root.ClassName,
		fullName = root:GetFullName(),
		childCount = #root:GetChildren(),
		descendantCount = #root:GetDescendants(),
		attributes = getAttributes(root),
		tags = getTags(root),
	})

	local descendants = root:GetDescendants()
	for _, instance in ipairs(descendants) do
		counters.instances += 1
		local ok, err = pcall(function()
			emit("INSTANCE", instanceRecord(instance, root.Name))
			if instance:IsA("LuaSourceContainer") then
				auditScript(instance, root.Name)
			end
		end)
		if not ok then
			counters.errors += 1
			emit("INSTANCE_ERROR", {
				fullName = instance:GetFullName(),
				className = instance.ClassName,
				error = tostring(err),
			})
		end
	end
end

print("=== VALBRUME_AUDIT_BEGIN ===")

emit("META", {
	auditVersion = CONFIG.VERSION,
	generatedAtUnix = os.time(),
	placeId = game.PlaceId,
	placeVersion = game.PlaceVersion,
	gameId = game.GameId,
	jobId = game.JobId,
	studio = true,
	config = CONFIG,
	note = "Read-only Studio inventory. No mutations and no DataStore calls.",
})

for _, serviceName in ipairs(ROOT_SERVICE_NAMES) do
	local ok, serviceOrError = pcall(function()
		return game:GetService(serviceName)
	end)
	if ok and serviceOrError then
		local rootOk, rootErr = pcall(function()
			auditRoot(serviceOrError)
		end)
		if not rootOk then
			counters.errors += 1
			emit("ROOT_ERROR", {
				service = serviceName,
				error = tostring(rootErr),
			})
		end
	else
		counters.errors += 1
		emit("SERVICE_ERROR", {
			service = serviceName,
			error = tostring(serviceOrError),
		})
	end
end

emit("SUMMARY", counters)
flush()

print("=== VALBRUME_AUDIT_END ===")
print("Valbrume audit complete. Copy the full block from BEGIN through END and send it back for analysis.")
