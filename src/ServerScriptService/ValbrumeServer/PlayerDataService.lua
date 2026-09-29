local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local C = require(game.ReplicatedStorage.Valbrume.Config)

local D = {
    Sessions = {},
    Enabled = false,
}

local token = game.JobId .. ":" .. HttpService:GenerateGUID(false)
local store
local LOCK_SECONDS = 180

local function clone(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for key, item in pairs(value) do
        result[key] = clone(item)
    end
    return result
end

local function integer(value, fallback, minimum, maximum)
    if type(value) ~= "number"
        or value ~= value
        or math.abs(value) == math.huge then
        return fallback
    end

    return math.clamp(math.floor(value), minimum, maximum)
end

local function fresh()
    return {
        Zone = false,
        Class = false,
        Level = 1,
        XP = 0,
        Gold = 0,
        Inventory = {},
        Equipment = {},
        QuestIndex = 1,
        QuestActive = false,
        QuestProgress = 0,
        Story = {
            Zone = false,
            QuestIndex = 1,
            Active = false,
            Progress = {},
        },
    }
end

local function sanitize(raw)
    local p = fresh()

    if type(raw) ~= "table" then
        return p
    end

    p.Zone = C.Zones[raw.Zone] and raw.Zone or false
    p.Class = C.Classes[raw.Class] and raw.Class or false

    -- Les anciens profils V1 n'avaient pas de territoire.
    -- On redemande donc zone + classe au prochain chargement.
    if p.Class and not p.Zone then
        p.Class = false
    end

    p.Level = integer(raw.Level, 1, 1, C.MaxLevel)
    p.XP = integer(raw.XP, 0, 0, C.RequiredXP(p.Level) - 1)
    p.Gold = integer(raw.Gold, 0, 0, 10000000)
    p.QuestIndex = integer(raw.QuestIndex, 1, 1, #C.Quests + 1)
    p.QuestActive = raw.QuestActive == true and C.Quests[p.QuestIndex] ~= nil

    local quest = C.Quests[p.QuestIndex]
    p.QuestProgress = integer(
        raw.QuestProgress,
        0,
        0,
        quest and quest.Count or 0
    )

    p.Story = {
        Zone = p.Zone,
        QuestIndex = 1,
        Active = false,
        Progress = {},
    }

    if type(raw.Story) == "table" then
        p.Story.Zone = C.Zones[raw.Story.Zone] and raw.Story.Zone or p.Zone
        p.Story.QuestIndex = integer(raw.Story.QuestIndex, 1, 1, 99)
        p.Story.Active = raw.Story.Active == true

        if type(raw.Story.Progress) == "table" then
            for key, value in pairs(raw.Story.Progress) do
                if type(key) == "number" and type(value) == "number" then
                    p.Story.Progress[key] = math.clamp(math.floor(value), 0, 999)
                end
            end
        end
    end

    if p.Level == C.MaxLevel then
        p.XP = 0
    end

    if type(raw.Inventory) == "table" then
        for id, owned in pairs(raw.Inventory) do
            if owned == true and C.Items[id] then
                p.Inventory[id] = true
            end
        end
    end

    if type(raw.Equipment) == "table" then
        for slot, id in pairs(raw.Equipment) do
            local item = C.Items[id]
            if item
                and item.Slot == slot
                and item.Class == p.Class
                and item.Level <= p.Level
                and p.Inventory[id] then
                p.Equipment[slot] = id
            end
        end
    end

    if p.Class then
        for _, slot in ipairs({"Weapon", "Armor"}) do
            local id = p.Class .. "_" .. slot .. "_1"
            p.Inventory[id] = true
            p.Equipment[slot] = p.Equipment[slot] or id
        end
    end

    return p
end

function D.Configure(enabled)
    D.Enabled = enabled == true

    if not D.Enabled then
        return
    end

    assert(
        game.GameId ~= 0,
        "Publie d'abord une place de test avant d'activer la sauvegarde."
    )

    local name = RunService:IsStudio()
        and "Valbrume_v01_Studio"
        or "Valbrume_v01_Live"

    store = DataStoreService:GetDataStore(name)
end

function D.Open(player)
    if not D.Enabled then
        local profile = fresh()
        D.Sessions[player] = {
            Profile = profile,
            Busy = false,
            Closing = false,
            Lost = false,
            LastSuccessfulSave = os.time(),
        }
        return profile
    end

    local key = "u_" .. player.UserId
    local result
    local lastError = "Profil occupé ou indisponible."

    for attempt = 1, 3 do
        local ok, value = pcall(function()
            return store:UpdateAsync(key, function(old)
                if old ~= nil
                    and (
                        type(old) ~= "table"
                        or old.Schema ~= 1
                        or type(old.Profile) ~= "table"
                    ) then
                    lastError = "Format de profil non reconnu : aucune écriture effectuée."
                    return nil
                end

                local lock = old and old.Lock

                if lock ~= nil and type(lock) ~= "table" then
                    lastError = "Verrou de profil invalide."
                    return nil
                end

                if lock and lock.Token ~= token then
                    if type(lock.Expires) ~= "number" then
                        lastError = "Verrou de profil invalide."
                        return nil
                    end

                    if lock.Expires > os.time() then
                        lastError = "Ce profil est encore ouvert sur un autre serveur."
                        return nil
                    end
                end

                return {
                    Schema = 1,
                    Profile = old and old.Profile or fresh(),
                    Lock = {
                        Token = token,
                        Expires = os.time() + LOCK_SECONDS,
                    },
                }
            end)
        end)

        if ok and type(value) == "table"
            and value.Lock
            and value.Lock.Token == token then
            result = value
            break
        end

        if not ok then
            lastError = tostring(value)
        end

        task.wait(attempt)
    end

    if not result then
        return nil, lastError
    end

    local profile = sanitize(result.Profile)

    D.Sessions[player] = {
        Profile = profile,
        Busy = false,
        Closing = false,
        Lost = false,
        LastSuccessfulSave = os.time(),
    }

    return profile
end

function D.Get(player)
    local entry = D.Sessions[player]

    if not entry or entry.Closing or entry.Lost then
        return nil
    end

    return entry.Profile
end

function D.Save(player, release)
    local entry = D.Sessions[player]

    if not entry or entry.Busy or entry.Lost then
        return false
    end

    if not D.Enabled then
        return true
    end

    entry.Busy = true

    local snapshot = clone(entry.Profile)
    local success = false
    local lostLock = false

    for attempt = 1, 3 do
        local ok, result = pcall(function()
            return store:UpdateAsync("u_" .. player.UserId, function(old)
                if type(old) ~= "table"
                    or type(old.Lock) ~= "table"
                    or old.Lock.Token ~= token then
                    return nil
                end

                return {
                    Schema = 1,
                    Profile = snapshot,
                    Lock = not release and {
                        Token = token,
                        Expires = os.time() + LOCK_SECONDS,
                    } or nil,
                }
            end)
        end)

        if ok and type(result) == "table" then
            success = true
            entry.LastSuccessfulSave = os.time()
            break
        elseif ok then
            lostLock = true
            break
        end

        task.wait(attempt)
    end

    entry.Busy = false

    if not success then
        warn("[Valbrume] Échec de sauvegarde pour un profil.")

        if lostLock
            or (not release and os.time() - entry.LastSuccessfulSave > 90) then
            entry.Lost = true

            task.defer(function()
                if player.Parent then
                    player:Kick(
                        "La session de sauvegarde est indisponible. "
                        .. "Reconnecte-toi pour protéger ta progression."
                    )
                end
            end)
        end
    end

    return success
end

function D.Close(player)
    local entry = D.Sessions[player]

    if not entry or entry.Closing then
        return
    end

    entry.Closing = true

    local deadline = os.clock() + 20
    while entry.Busy and os.clock() < deadline do
        task.wait(0.1)
    end

    if not entry.Busy then
        D.Save(player, true)
    end

    D.Sessions[player] = nil
end

return D
