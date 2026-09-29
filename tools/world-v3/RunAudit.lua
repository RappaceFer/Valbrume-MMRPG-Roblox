-- COMMAND BAR during Play, context SERVER. Read-only; no module installation.
local run=game:GetService("RunService")
assert(run:IsStudio() and run:IsRunning() and run:IsServer(),"Lance Play puis selectionne Server.")
local server=game:GetService("ServerScriptService"):FindFirstChild("ValbrumeServer")
local modules=server and server:FindFirstChild("WorldV3")
assert(modules,"World V3.1 n'est pas installe")
local world=workspace:FindFirstChild("ValbrumeWorld")
assert(world and world:GetAttribute("GenerationReady")==true,"Attends GenerationReady avant le scan.")
require(modules.Audit).run(world,require(modules.Layout))
