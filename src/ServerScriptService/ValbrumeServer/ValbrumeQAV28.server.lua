require(script.Parent.WorldGeneration).Await("Ready"); local failures={}; local function fail(x) table.insert(failures,x) end; local server=script.Parent; local world=workspace:FindFirstChild("ValbrumeWorld"); local exp=world and world:FindFirstChild("ExpansionV25")
for _,name in ipairs({"OpenWorldContinentsV28","OpenWorldBiomeV28","SafeSpawnDirectorV26","ExpansionStoryServiceV26"}) do if not server:FindFirstChild(name) then fail("Service absent : "..name) end end
if not world or not world:FindFirstChild("OpenWorldV28") then fail("OpenWorldV28 absent") end; if exp and exp:FindFirstChild("Travel") then fail("Anciens portails ExpansionV25 encore présents") end
local zones=exp and exp:FindFirstChild("Zones"); local expected={S3=Vector3.new(-1520,0,-560),N4=Vector3.new(-1520,0,560),O5=Vector3.new(1520,0,-560),V6=Vector3.new(1520,0,560)}
if zones then for id,pos in pairs(expected) do local s=zones:FindFirstChild(id.."_ExpansionSpawn"); if not s then fail("Spawn absent : "..id) elseif Vector2.new(s.Position.X-pos.X,s.Position.Z-pos.Z).Magnitude>90 then fail(id.." mal positionnée") end end else fail("Zones expansion absentes") end
if world and world:FindFirstChild("OpenWorldV28") then local r=world.OpenWorldV28; if not r:FindFirstChild("SeaTravel") then fail("SeaTravel absent") end; if not r:FindFirstChild("Roads") then fail("Roads absentes") end; if not r:FindFirstChild("Hazards") then fail("Hazards absents") end end
if world then
    local root=world:FindFirstChild("OpenWorldV28")
    local sea=root and root:FindFirstChild("SeaTravel")
    local hazards=root and root:FindFirstChild("Hazards")
    if not sea or not sea:FindFirstChild("Ferry_Obsidienne") then fail("Ferry absent") end
    if not hazards or #hazards:GetChildren()<3 then fail("Hazards incomplets") end
    local cross,story=0,0
    for _,d in world:GetDescendants() do
        if d:IsA("ProximityPrompt") and d.Name=="CrossSea" then cross+=1 end
        if d:IsA("ProximityPrompt") and d.Name=="StoryPromptV23" then story+=1 end
    end
    if cross~=2 then fail("Traversées ferry incomplètes") end
    if story<16 then fail("Prompts narratifs incomplets") end
    for _,zone in {"A2","H2"} do
        local gate=world.Decor:FindFirstChild("DungeonGate_"..zone)
        if not gate or not gate:FindFirstChild("Start",true) or not gate:FindFirstChild("Join",true) then fail("Porte donjon absente : "..zone) end
    end
    local counts={A2=0,H2=0,S3=0,N4=0,O5=0,V6=0}
    for _,enemy in world.Enemies:GetChildren() do
        if not enemy:GetAttribute("DungeonId") then
            local zone=enemy:GetAttribute("ZoneId")
            if counts[zone] then counts[zone]+=1 else fail("Zone ennemi inconnue") end
            if table.find({"Ronceux","Pillard","Sylvain","Veilleur","Golem","Gardien"},enemy:GetAttribute("MobId")) then fail("Ancien bestiaire encore présent") end
        end
    end
    for zone,count in counts do if count~=((zone=="A2" or zone=="H2") and 15 or 9) then fail("Effectif incorrect : "..zone.."="..count) end end
end
if #failures==0 then print("[VALBRUME QA V2.8] PASS structure — contenus, bestiaire et effectifs présents ; parcours joueur à tester.") else warn("[VALBRUME QA V2.8] FAIL — "..#failures.." erreur(s)."); for _,m in ipairs(failures) do warn("[VALBRUME QA V2.8][CRITIQUE] "..m) end end
