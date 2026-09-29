local Players=game:GetService("Players")
local SSS=game:GetService("ServerScriptService")
require(script.Parent.WorldGeneration).Await("Ready")

local failures={}
local infos={}
local function fail(m) table.insert(failures,m) end
local function info(m) table.insert(infos,m) end

local server=SSS:FindFirstChild("ValbrumeServer")
if not server then
    fail("ValbrumeServer absent")
else
    for _,name in ipairs({"WeaponToolServiceV27","JournalSyncServiceV27","ValbrumeQAV26"}) do
        if not server:FindFirstChild(name) then fail("Service absent : "..name) end
    end
    if server:FindFirstChild("WeaponVisualService") then fail("Ancien WeaponVisualService encore actif") end
end

if SSS:FindFirstChild("VBWeaponCalibrationLab") then fail("Ancien Weapon Calibration Lab encore actif") end

for _,player in ipairs(Players:GetPlayers()) do
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if root and root.Anchored and root.Position.Y<250 then
        fail(player.Name.." : HumanoidRootPart ancré en gameplay")
    end

    local tool=character and character:FindFirstChild("VB_EquippedWeaponV27")
    if tool then
        local handle=tool:FindFirstChild("Handle")
        if not handle or not handle:IsA("BasePart") then
            fail(player.Name.." : Handle arme absent")
        else
            if handle.Anchored then fail(player.Name.." : Handle arme ancré") end
            if handle.CanCollide then fail(player.Name.." : Handle arme collision active") end
            if not handle.Massless then fail(player.Name.." : Handle arme non Massless") end
            if tool:GetAttribute("VBValidated")~=true then fail(player.Name.." : arme équipée non validée") end
        end

        for _,d in ipairs(tool:GetDescendants()) do
            if d:IsA("BasePart") and (d.Anchored or d.CanCollide or not d.Massless) then
                fail(player.Name.." : physique arme invalide -> "..d.Name)
                break
            end
        end
    else
        info(player.Name.." : aucune arme Tool V2.7 équipée au moment du QA")
    end
end

if #failures==0 then
    print("[VALBRUME QA V2.7] PASS structure — parcours UI et arme après sélection à tester.")
else
    warn("[VALBRUME QA V2.7] FAIL — "..#failures.." erreur(s).")
    for _,m in ipairs(failures) do warn("[VALBRUME QA V2.7][CRITIQUE] "..m) end
end
for _,m in ipairs(infos) do warn("[VALBRUME QA V2.7][INFO] "..m) end
