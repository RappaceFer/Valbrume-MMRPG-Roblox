local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local package = ReplicatedStorage:WaitForChild("Valbrume")
local Remote = package:WaitForChild("ExpansionStoryRemoteV26")

local server = script.Parent
local MobDied = server:WaitForChild("WorldMobDiedV23")
local Reward = server:WaitForChild("StoryRewardV23")

local Generation = require(script.Parent.WorldGeneration)
local world = Generation.Await("Story")
local content, expansion = world.V26Content, world.ExpansionV25
local questObjects = content:WaitForChild("ExpansionQuestObjects")
local zonesFolder = expansion:WaitForChild("Zones")

local QUESTS = {
    S3 = {
        Giver = "Maelis",
        Intro = "La brume ne cache plus la forêt. Elle la réécrit.",
        Quests = {
            {
                Name = "Des pas dans la mousse",
                Accept = "Les Brumesangs tournent autour du camp. Écarte-les avant que nous suivions les traces plus profondes.",
                Complete = "Ils ne chassaient pas. Ils montaient la garde.",
                Objectives = {
                    {Type="Kill", Target="S3_Brumesang", Amount=5, Text="Vaincre des Brumesangs"},
                },
                Rewards = {XP=520, Gold=115},
            },
            {
                Name = "Les racines parlent",
                Accept = "Trois racines anciennes vibrent sous le même rythme. Approche-les et écoute.",
                Complete = "Même pulsation, même mémoire. Quelqu'un réveille le réseau par fragments.",
                Objectives = {
                    {Type="Interact", Point="MistRootA", Amount=1, Text="Écouter la première racine"},
                    {Type="Interact", Point="MistRootB", Amount=1, Text="Écouter la deuxième racine"},
                    {Type="Interact", Point="MistRootC", Amount=1, Text="Écouter la troisième racine"},
                },
                Rewards = {XP=620, Gold=138},
            },
            {
                Name = "Le bois se défend",
                Accept = "Les Racines vives ferment l'accès à la clairière. Brise leur cercle.",
                Complete = "Le chemin est ouvert. Le Veilleur nous attend.",
                Objectives = {
                    {Type="Kill", Target="S3_RacineVive", Amount=4, Text="Neutraliser les Racines vives"},
                    {Type="Explore", Point="BossGlade", Amount=1, Text="Atteindre la clairière"},
                },
                Rewards = {XP=760, Gold=164},
            },
            {
                Name = "Le Veilleur sylvestre",
                Accept = "Ce gardien protège un souvenir, pas un territoire. Libère-le de l'ordre qui le retient.",
                Complete = "Dans son silence, une route apparaît : les falaises de Nacre portent la même signature.",
                Objectives = {
                    {Type="Kill", Target="S3_VeilleurSylvestre", Amount=1, Text="Vaincre le Veilleur sylvestre"},
                },
                Rewards = {XP=1250, Gold=290},
            },
        },
    },

    N4 = {
        Giver = "Neris",
        Intro = "Le vent rapporte des voix qui n'appartiennent à personne de vivant.",
        Quests = {
            {
                Name = "Au bord du vide",
                Accept = "Les Rôdeurs ont pris les corniches. Nettoie les accès aux anciennes balises.",
                Complete = "Les balises sont accessibles. Mais elles pointent vers l'intérieur des terres.",
                Objectives = {
                    {Type="Kill", Target="N4_RodeurFalaise", Amount=5, Text="Vaincre des Rôdeurs des falaises"},
                },
                Rewards = {XP=610, Gold=136},
            },
            {
                Name = "Trois signaux",
                Accept = "Réactive les trois balises. Si elles répondent ensemble, nous saurons où mène le signal.",
                Complete = "Elles ne guident pas les navires. Elles tracent un réseau souterrain.",
                Objectives = {
                    {Type="Interact", Point="BeaconA", Amount=1, Text="Réactiver la balise I"},
                    {Type="Interact", Point="BeaconB", Amount=1, Text="Réactiver la balise II"},
                    {Type="Interact", Point="BeaconC", Amount=1, Text="Réactiver la balise III"},
                },
                Rewards = {XP=735, Gold=162},
            },
            {
                Name = "La lentille des vents",
                Accept = "Les Pilleurs de sel démontent la vieille lentille. Repousse-les et atteins l'instrument.",
                Complete = "La lentille montre Ormefer. Les anciennes forges étaient un relais de l'Écho.",
                Objectives = {
                    {Type="Kill", Target="N4_PilleurSel", Amount=4, Text="Repousser les Pilleurs de sel"},
                    {Type="Explore", Point="WindLens", Amount=1, Text="Atteindre la lentille"},
                },
                Rewards = {XP=860, Gold=190},
            },
            {
                Name = "Le Gardien de Nacre",
                Accept = "Le Gardien verrouille le promontoire. Tant qu'il tient, la route d'Ormefer reste muette.",
                Complete = "Le vent retombe. Un ancien chemin de forge répond désormais au signal.",
                Objectives = {
                    {Type="Kill", Target="N4_GardienNacre", Amount=1, Text="Vaincre le Gardien de Nacre"},
                },
                Rewards = {XP=1430, Gold=330},
            },
        },
    },

    O5 = {
        Giver = "Dorran",
        Intro = "Les forges sont froides depuis des siècles. Pourtant les marteaux recommencent à frapper.",
        Quests = {
            {
                Name = "Chiens de rouille",
                Accept = "Les Molosses patrouillent comme si les maîtres des forges vivaient encore. Ouvre la cour.",
                Complete = "Ils suivaient un ordre gravé dans leur noyau.",
                Objectives = {
                    {Type="Kill", Target="O5_MolosseRouille", Amount=5, Text="Détruire des Molosses de rouille"},
                },
                Rewards = {XP=720, Gold=160},
            },
            {
                Name = "Deux cœurs froids",
                Accept = "Active les deux cœurs secondaires. Je veux savoir si la forge répond encore à l'ancien réseau.",
                Complete = "Elle répond. Et quelque chose, plus bas, répond plus fort.",
                Objectives = {
                    {Type="Interact", Point="ForgeCoreA", Amount=1, Text="Réveiller le cœur I"},
                    {Type="Interact", Point="ForgeCoreB", Amount=1, Text="Réveiller le cœur II"},
                },
                Rewards = {XP=840, Gold=188},
            },
            {
                Name = "Le creuset oublié",
                Accept = "Les Forges éveillées convergent vers le vieux creuset. Dégage l'accès et observe-le.",
                Complete = "Le creuset ne fabriquait pas des armes. Il façonnait des réceptacles de mémoire.",
                Objectives = {
                    {Type="Kill", Target="O5_ForgeEveillee", Amount=4, Text="Neutraliser les Forges éveillées"},
                    {Type="Explore", Point="Smelter", Amount=1, Text="Atteindre l'ancien creuset"},
                },
                Rewards = {XP=980, Gold=218},
            },
            {
                Name = "Le Maître-Fourneau",
                Accept = "Le Maître-Fourneau alimente encore le relais. Coupe son cycle.",
                Complete = "Le relais s'éteint. Sous les forges, une veine cristalline continue pourtant de pulser.",
                Objectives = {
                    {Type="Kill", Target="O5_MaitreFourneau", Amount=1, Text="Vaincre le Maître-Fourneau"},
                },
                Rewards = {XP=1620, Gold=375},
            },
        },
    },

    V6 = {
        Giver = "Seyra",
        Intro = "Ici, l'Écho n'est plus un murmure. Il est partout.",
        Quests = {
            {
                Name = "Résonances",
                Accept = "Approche les trois cristaux. Nous devons déterminer s'ils stockent une mémoire ou s'ils l'émettent.",
                Complete = "Ils font les deux. Quelqu'un peut écrire dans l'Écho autant qu'il peut le lire.",
                Objectives = {
                    {Type="Interact", Point="CrystalA", Amount=1, Text="Accorder le cristal I"},
                    {Type="Interact", Point="CrystalB", Amount=1, Text="Accorder le cristal II"},
                    {Type="Interact", Point="CrystalC", Amount=1, Text="Accorder le cristal III"},
                },
                Rewards = {XP=910, Gold=205},
            },
            {
                Name = "Ceux qui n'ont plus de voix",
                Accept = "Les Spectres sont des souvenirs qui ont perdu leur nom. Dissipe-les avant qu'ils ne saturent la veine.",
                Complete = "Le signal devient plus net. Il vient de la faille.",
                Objectives = {
                    {Type="Kill", Target="V6_SpectreEcho", Amount=5, Text="Dissiper des Spectres de l'Écho"},
                },
                Rewards = {XP=1040, Gold=235},
            },
            {
                Name = "Sous la veine",
                Accept = "Les Sentinelles protègent la descente. Traverse leur ligne et atteins la faille profonde.",
                Complete = "Le réseau converge ici. Le Noyau n'est pas une source : c'est un relais central.",
                Objectives = {
                    {Type="Kill", Target="V6_SentinelleCristal", Amount=4, Text="Vaincre les Sentinelles cristallines"},
                    {Type="Explore", Point="DeepFissure", Amount=1, Text="Atteindre la faille profonde"},
                },
                Rewards = {XP=1210, Gold=270},
            },
            {
                Name = "Le Noyau Résonant",
                Accept = "Coupe le relais. S'il continue à diffuser cet ordre, les gardiens de toutes les régions finiront par se lever.",
                Complete = "Le réseau se tait enfin. Mais juste avant de s'éteindre, le Noyau a transmis une destination inconnue.",
                Objectives = {
                    {Type="Kill", Target="V6_NoyauResonant", Amount=1, Text="Vaincre le Noyau Résonant"},
                },
                Rewards = {XP=1950, Gold=450},
            },
        },
    },
}

local POINTS = {
    S3 = {
        MistRootA = Vector3.new(-72,0,26),
        MistRootB = Vector3.new(-18,0,-72),
        MistRootC = Vector3.new(78,0,-28),
        BossGlade = Vector3.new(-118,0,-118),
    },
    N4 = {
        BeaconA = Vector3.new(-80,0,18),
        BeaconB = Vector3.new(-12,0,-82),
        BeaconC = Vector3.new(86,0,-20),
        WindLens = Vector3.new(48,0,82),
        BossCliff = Vector3.new(-115,0,-120),
    },
    O5 = {
        ForgeCoreA = Vector3.new(-78,0,26),
        ForgeCoreB = Vector3.new(-20,0,-76),
        Smelter = Vector3.new(84,0,-28),
        BossForge = Vector3.new(112,0,86),
    },
    V6 = {
        CrystalA = Vector3.new(-76,0,22),
        CrystalB = Vector3.new(-18,0,-74),
        CrystalC = Vector3.new(80,0,-30),
        DeepFissure = Vector3.new(54,0,84),
        BossCore = Vector3.new(-104,0,96),
    },
}

local sessions = {}

local function stateFor(player, zoneId)
    sessions[player] = sessions[player] or {}
    sessions[player][zoneId] = sessions[player][zoneId] or {
        QuestIndex = 1,
        Active = false,
        Progress = {},
        Completed = false,
    }

    return sessions[player][zoneId]
end

local function currentZone(player)
    local zoneId = player:GetAttribute("VBExpansionZone")
    return QUESTS[zoneId] and zoneId or nil
end

local function questFor(zoneId, state)
    local z = QUESTS[zoneId]
    return z and z.Quests[state.QuestIndex]
end

local function objectiveDone(state, objective, index)
    return (state.Progress[index] or 0) >= (objective.Amount or 1)
end

local function complete(state, quest)
    if not quest then
        return false
    end

    for index, objective in ipairs(quest.Objectives) do
        if not objectiveDone(state, objective, index) then
            return false
        end
    end

    return true
end

local function progressText(state, quest)
    if not quest then
        return ""
    end

    local lines = {}

    for index, objective in ipairs(quest.Objectives) do
        local amount = objective.Amount or 1
        local value = math.min(amount, state.Progress[index] or 0)

        table.insert(
            lines,
            (objectiveDone(state, objective, index) and "✓ " or "• ")
                .. objective.Text
                .. "  "
                .. value
                .. "/"
                .. amount
        )
    end

    return table.concat(lines, "\n")
end

local function push(player)
    local zoneId = currentZone(player)

    if not zoneId then
        Remote:FireClient(player, "Hide")
        return
    end

    local state = stateFor(player, zoneId)
    local zone = QUESTS[zoneId]
    local quest = questFor(zoneId, state)

    Remote:FireClient(player, "State", {
        Zone = zoneId,
        Giver = zone.Giver,
        Intro = zone.Intro,
        QuestIndex = state.QuestIndex,
        Active = state.Active,
        Completed = state.Completed,
        QuestName = quest and quest.Name or "Arc terminé",
        Progress = quest and progressText(state, quest) or "Toutes les chroniques de cette région sont terminées.",
        CanTurnIn = quest and state.Active and complete(state, quest) or false,
    })
end

local function toast(player, text)
    Remote:FireClient(player, "Toast", text)
end

local function increment(player, kind, target, amount)
    local zoneId = currentZone(player)
    if not zoneId then
        return
    end

    local state = stateFor(player, zoneId)
    local quest = questFor(zoneId, state)

    if not state.Active or not quest then
        return
    end

    local changed = false

    for index, objective in ipairs(quest.Objectives) do
        local targetMatches = objective.Target == target or objective.Point == target

        if objective.Type == kind
            and targetMatches
            and not objectiveDone(state, objective, index) then

            state.Progress[index] = math.min(
                objective.Amount or 1,
                (state.Progress[index] or 0) + (amount or 1)
            )

            changed = true
            break
        end
    end

    if changed then
        push(player)

        if complete(state, quest) then
            toast(player, "Objectifs terminés — retourne voir " .. QUESTS[zoneId].Giver .. ".")
        end
    end
end

local function acceptOrTurnIn(player, zoneId)
    if currentZone(player) ~= zoneId then
        toast(player, "Tu dois être dans cette région pour poursuivre cette chronique.")
        return
    end

    local state = stateFor(player, zoneId)
    local zone = QUESTS[zoneId]
    local quest = questFor(zoneId, state)

    if state.Completed or not quest then
        toast(player, "Cette chronique est terminée.")
        return
    end

    if not state.Active then
        state.Active = true
        state.Progress = {}
        toast(player, quest.Accept)
        push(player)
        return
    end

    if not complete(state, quest) then
        toast(player, progressText(state, quest))
        return
    end

    local rewards = quest.Rewards or {}
    Reward:Fire(player, rewards.XP or 0, rewards.Gold or 0, nil)

    toast(
        player,
        quest.Complete
            .. "\n+"
            .. tostring(rewards.XP or 0)
            .. " XP   +"
            .. tostring(rewards.Gold or 0)
            .. " or"
    )

    state.QuestIndex += 1
    state.Active = false
    state.Progress = {}

    if state.QuestIndex > #zone.Quests then
        state.Completed = true
        toast(player, "Chronique de " .. zoneId .. " terminée.")
    end

    push(player)
end

-- Prompts donneurs de quêtes.
for _, object in ipairs(questObjects:GetChildren()) do
    if object:IsA("Model") and object:GetAttribute("VBExpansionQuestGiver") then
        local zoneId = object:GetAttribute("VBExpansionZone")
        local root = object.PrimaryPart

        if zoneId and root then
            local prompt = root:FindFirstChild("V26QuestPrompt")
            if prompt then
                prompt:Destroy()
            end

            prompt = Instance.new("ProximityPrompt")
            prompt.Name = "V26QuestPrompt"
            prompt.ActionText = "Chronique"
            prompt.ObjectText = QUESTS[zoneId] and QUESTS[zoneId].Giver or "Explorateur"
            prompt.MaxActivationDistance = 13
            prompt.HoldDuration = 0.12
            prompt.RequiresLineOfSight = false
            prompt.Parent = root

            prompt.Triggered:Connect(function(player)
                acceptOrTurnIn(player, zoneId)
            end)
        end
    end
end

-- Prompts interactables.
for _, object in ipairs(questObjects:GetChildren()) do
    if object:IsA("BasePart") and object:GetAttribute("VBExpansionPoint") then
        local zoneId = object:GetAttribute("VBExpansionZone")
        local pointId = object:GetAttribute("VBExpansionPoint")

        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "V26InteractPrompt"
        prompt.ActionText = "Examiner"
        prompt.ObjectText = tostring(pointId)
        prompt.MaxActivationDistance = 12
        prompt.HoldDuration = 0.25
        prompt.RequiresLineOfSight = false
        prompt.Parent = object

        prompt.Triggered:Connect(function(player)
            if currentZone(player) == zoneId then
                increment(player, "Interact", pointId, 1)
            end
        end)
    end
end

-- Kills expansion.
MobDied.Event:Connect(function(player, mobId, zoneId)
    if currentZone(player) == zoneId then
        increment(player, "Kill", mobId, 1)
    end
end)

-- Explore objectives.
local function pointWorldPosition(zoneId, pointId)
    local spawn = zonesFolder:FindFirstChild(zoneId .. "_ExpansionSpawn")
    local localPoint = POINTS[zoneId] and POINTS[zoneId][pointId]

    if not spawn or not localPoint then
        return nil
    end

    return Vector3.new(
        spawn.Position.X + localPoint.X,
        spawn.Position.Y,
        spawn.Position.Z + localPoint.Z
    )
end

task.spawn(function()
    while true do
        task.wait(1)

        for _, player in ipairs(Players:GetPlayers()) do
            local zoneId = currentZone(player)
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if zoneId and root then
                local state = stateFor(player, zoneId)
                local quest = questFor(zoneId, state)

                if state.Active and quest then
                    for index, objective in ipairs(quest.Objectives) do
                        if objective.Type == "Explore"
                            and objective.Point
                            and not objectiveDone(state, objective, index) then

                            local point = pointWorldPosition(zoneId, objective.Point)

                            if point then
                                local horizontal = Vector2.new(
                                    root.Position.X - point.X,
                                    root.Position.Z - point.Z
                                ).Magnitude

                                if horizontal <= 18 then
                                    state.Progress[index] = 1
                                    push(player)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

local function watchPlayer(player)
    player:GetAttributeChangedSignal("VBExpansionZone"):Connect(function()
        task.defer(push, player)
    end)

    player.CharacterAdded:Connect(function()
        task.wait(1)
        push(player)
    end)

    task.defer(push, player)
end

for _, player in ipairs(Players:GetPlayers()) do
    watchPlayer(player)
end

Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(player)
    sessions[player] = nil
end)

print("[Valbrume V2.6] ExpansionStoryService actif : 16 quêtes / 4 régions.")

Generation.Complete(world, "ExpansionStory")
