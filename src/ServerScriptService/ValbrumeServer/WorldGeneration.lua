-- Runtime-only coordinator. Saved editor attributes are never accepted as readiness.
local G = {}
local changed = Instance.new("BindableEvent")
local current, generationId, failure
local completed = {}
local stages = {"Core", "Expansion", "Continents", "Biome", "Content", "Polish",
    "Grounding", "SafeSpawns", "Population", "Story", "ExpansionStory", "Dungeon", "Ready"}
local index = 0

function G.Begin(world)
    assert(not current, "World generation may only start once per server")
    assert(world.Parent == workspace and workspace:FindFirstChild("ValbrumeWorld") == world)
    current = world
    generationId = game:GetService("HttpService"):GenerateGUID(false)
    world:SetAttribute("GenerationId", generationId)
    world:SetAttribute("GenerationReady", false)
    world:SetAttribute("GenerationStage", "Building")
    world.Destroying:Connect(function()
        failure = "Final world was destroyed during this server session"
        changed:Fire()
    end)
    changed:Fire()
end

function G.Complete(world, stage)
    assert(world == current and world.Parent == workspace, "Obsolete world reference")
    assert(not failure, failure)
    assert(stages[index + 1] == stage, "Generation stage out of order: " .. stage)
    -- Terrain writes must reach the physics scene before downstream raycasts.
    if stage == "Core" or stage == "Expansion" or stage == "Continents" or stage == "Biome" then
        game:GetService("RunService").PostSimulation:Wait()
    end
    index += 1
    completed[stage] = true
    if stage ~= "Ready" then world:SetAttribute(stage .. "Ready", true) end
    world:SetAttribute("GenerationStage", stage)
    if stage == "Ready" then world:SetAttribute("GenerationReady", true) end
    print("[Valbrume Generation] " .. stage .. " / " .. generationId)
    changed:Fire()
end

function G.Await(stage, timeout)
    assert(table.find(stages, stage), "Unknown generation stage")
    local expired = false
    -- Deadline is a failure detector, never a readiness timer.
    local timer = task.delay(timeout or 120, function()
        expired = true
        changed:Fire()
    end)
    while not completed[stage] and not failure and not expired do changed.Event:Wait() end
    if not expired then task.cancel(timer) end
    if failure or expired then
        local message = failure or ("Timeout waiting for " .. stage .. "; last stage: " .. (stages[index] or "WorldBuilder"))
        if current then current:SetAttribute("GenerationError", message) end
        error("[Valbrume Generation] " .. message)
    end
    assert(current and current.Parent == workspace and workspace:FindFirstChild("ValbrumeWorld") == current,
        "Final world is no longer current")
    return current
end

return G
