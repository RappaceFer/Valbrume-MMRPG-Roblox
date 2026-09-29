local C = {}

C.MaxLevel = 10
C.GroundY = 20
C.Spawn = Vector3.new(0, 25, 20)
C.NoraPosition = Vector3.new(0, 22, -20)

C.ClassOrder = {
    "Bastion",
    "Eclaireur",
    "Arcaniste",
    "Luminar",
}

C.Classes = {
    Bastion = {
        Name = "Bastion",
        Description = "Défenseur : attire les ennemis et réduit les dégâts.",
        Resource = "Vigueur",
        Health = 210,
        Armor = 8,
        Power = 10,
        Color = Color3.fromRGB(93, 160, 220),
        Skills = {
            {
                Name = "Frappe",
                Effect = "Damage",
                Base = 20,
                Scale = 1.0,
                Range = 11,
                Cost = 0,
                Cooldown = 0,
                Cast = 0,
            },
            {
                Name = "Onde",
                Effect = "Blast",
                Base = 26,
                Scale = 1.2,
                Radius = 13,
                Cost = 20,
                Cooldown = 6,
                Cast = 0,
            },
            {
                Name = "Défi",
                Effect = "Taunt",
                Radius = 20,
                Duration = 5,
                Cost = 10,
                Cooldown = 10,
                Cast = 0,
            },
            {
                Name = "Rempart",
                Effect = "Guard",
                Duration = 5,
                Cost = 25,
                Cooldown = 15,
                Cast = 0,
            },
        },
    },

    Eclaireur = {
        Name = "Éclaireur",
        Description = "Tireur : combat à distance, immobilise et se repositionne.",
        Resource = "Concentration",
        Health = 155,
        Armor = 3,
        Power = 13,
        Color = Color3.fromRGB(107, 199, 137),
        Skills = {
            {
                Name = "Tir",
                Effect = "Damage",
                Base = 18,
                Scale = 1.2,
                Range = 70,
                Cost = 0,
                Cooldown = 0,
                Cast = 0.25,
            },
            {
                Name = "Rafale",
                Effect = "Damage",
                Base = 45,
                Scale = 1.8,
                Range = 70,
                Cost = 20,
                Cooldown = 6,
                Cast = 0.5,
            },
            {
                Name = "Entrave",
                Effect = "Damage",
                Base = 16,
                Scale = 0.8,
                Range = 60,
                Stun = 2.5,
                Cost = 20,
                Cooldown = 10,
                Cast = 0,
            },
            {
                Name = "Élan",
                Effect = "Haste",
                Duration = 5,
                Cost = 15,
                Cooldown = 14,
                Cast = 0,
            },
        },
    },

    Arcaniste = {
        Name = "Arcaniste",
        Description = "Mage : incantations puissantes et dégâts de zone.",
        Resource = "Mana",
        Health = 135,
        Armor = 2,
        Power = 16,
        Color = Color3.fromRGB(178, 133, 236),
        Skills = {
            {
                Name = "Trait",
                Effect = "Damage",
                Base = 20,
                Scale = 1.2,
                Range = 65,
                Cost = 0,
                Cooldown = 0,
                Cast = 0.6,
            },
            {
                Name = "Nova",
                Effect = "Blast",
                Base = 35,
                Scale = 1.5,
                Radius = 17,
                Cost = 25,
                Cooldown = 7,
                Cast = 0.7,
            },
            {
                Name = "Foudre",
                Effect = "Damage",
                Base = 65,
                Scale = 2.1,
                Range = 65,
                Cost = 30,
                Cooldown = 9,
                Cast = 1.5,
            },
            {
                Name = "Égide",
                Effect = "Guard",
                Duration = 4,
                Cost = 20,
                Cooldown = 14,
                Cast = 0,
            },
        },
    },

    Luminar = {
        Name = "Luminar",
        Description = "Soutien : soigne les alliés proches et combat à distance.",
        Resource = "Foi",
        Health = 170,
        Armor = 4,
        Power = 12,
        Color = Color3.fromRGB(235, 202, 110),
        Skills = {
            {
                Name = "Rayon",
                Effect = "Damage",
                Base = 22,
                Scale = 1.1,
                Range = 60,
                Cost = 0,
                Cooldown = 0,
                Cast = 0.4,
            },
            {
                Name = "Soin",
                Effect = "Heal",
                Base = 35,
                Scale = 1.6,
                Radius = 35,
                Cost = 22,
                Cooldown = 6,
                Cast = 0.8,
            },
            {
                Name = "Sceau",
                Effect = "Blast",
                Base = 25,
                Scale = 1.2,
                Radius = 16,
                Cost = 20,
                Cooldown = 8,
                Cast = 0,
            },
            {
                Name = "Grâce",
                Effect = "Heal",
                Base = 75,
                Scale = 2.2,
                Radius = 40,
                Cost = 35,
                Cooldown = 14,
                Cast = 1.4,
            },
        },
    },
}

function C.RequiredXP(level)
    return 80 + 40 * (level - 1)
end

C.Items = {}

local weaponNames = {
    Bastion = "Lame",
    Eclaireur = "Arc",
    Arcaniste = "Bâton",
    Luminar = "Sceptre",
}

local tierNames = {
    "de l'escorte",
    "des sentiers",
    "du sanctuaire",
}

local tierLevels = {1, 4, 7}
local tierPower = {5, 12, 23}
local tierHealth = {25, 60, 100}
local tierArmor = {3, 7, 12}

for _, classId in ipairs(C.ClassOrder) do
    for tier = 1, 3 do
        local weaponId = classId .. "_Weapon_" .. tier
        local armorId = classId .. "_Armor_" .. tier

        C.Items[weaponId] = {
            Name = weaponNames[classId] .. " " .. tierNames[tier],
            Class = classId,
            Slot = "Weapon",
            Tier = tier,
            Level = tierLevels[tier],
            Power = tierPower[tier],
            Health = 0,
            Armor = 0,
        }

        C.Items[armorId] = {
            Name = "Tenue " .. tierNames[tier],
            Class = classId,
            Slot = "Armor",
            Tier = tier,
            Level = tierLevels[tier],
            Power = 0,
            Health = tierHealth[tier],
            Armor = tierArmor[tier],
        }
    end
end

C.Mobs = {
    Ronceux = {
        Name = "Ronceux des landes",
        Level = 1,
        Health = 90,
        Damage = 7,
        Armor = 0,
        XP = 32,
        Gold = 5,
        Speed = 12,
        Scale = 1,
        Respawn = 14,
        Color = Color3.fromRGB(108, 143, 81),
    },

    Pillard = {
        Name = "Pillard des chemins",
        Level = 2,
        Health = 135,
        Damage = 10,
        Armor = 4,
        XP = 45,
        Gold = 8,
        Speed = 14,
        Scale = 1,
        Respawn = 16,
        Color = Color3.fromRGB(156, 107, 83),
    },

    Sylvain = {
        Name = "Sylvain altéré",
        Level = 3,
        Health = 190,
        Damage = 13,
        Armor = 6,
        XP = 60,
        Gold = 10,
        Speed = 13,
        Scale = 1.15,
        Respawn = 18,
        Color = Color3.fromRGB(92, 159, 137),
    },

    Veilleur = {
        Name = "Veilleur des ruines",
        Level = 5,
        Health = 285,
        Damage = 18,
        Armor = 12,
        XP = 90,
        Gold = 15,
        Speed = 13,
        Scale = 1.15,
        Respawn = 20,
        Color = Color3.fromRGB(120, 126, 165),
    },

    Golem = {
        Name = "Golem fissuré",
        Level = 6,
        Health = 430,
        Damage = 23,
        Armor = 18,
        XP = 120,
        Gold = 20,
        Speed = 11,
        Scale = 1.35,
        Respawn = 25,
        Color = Color3.fromRGB(126, 132, 137),
    },

    Gardien = {
        Name = "Gardien du cœur brisé",
        Level = 8,
        Health = 1600,
        Damage = 29,
        Armor = 20,
        XP = 450,
        Gold = 90,
        Speed = 13,
        Scale = 1.7,
        Respawn = 65,
        Boss = true,
        Color = Color3.fromRGB(149, 98, 178),
    },
}

C.Spawns = {
    {"Ronceux", -25, 115},
    {"Ronceux", 0, 145},
    {"Ronceux", 30, 120},

    {"Pillard", 80, 110},
    {"Pillard", 105, 145},
    {"Pillard", 135, 105},

    {"Sylvain", 175, 90},
    {"Sylvain", 215, 100},
    {"Sylvain", 195, 140},

    {"Veilleur", 205, -45},
    {"Veilleur", 240, -65},
    {"Veilleur", 275, -45},

    {"Golem", 205, -100},
    {"Golem", 275, -100},

    {"Gardien", 240, -155},
}

C.Quests = {
    {
        Name = "La première patrouille",
        Description = "Élimine 3 Ronceux au sud du village.",
        Kind = "Kill",
        Target = "Ronceux",
        Count = 3,
        XP = 120,
        Gold = 25,
        Goal = Vector3.new(0, 23, 125),
    },
    {
        Name = "Les éclats de brume",
        Description = "Récolte 5 cristaux lumineux près du village.",
        Kind = "Collect",
        Target = "Shard",
        Count = 5,
        XP = 140,
        Gold = 30,
        Goal = Vector3.new(0, 23, 75),
    },
    {
        Name = "Une route moins sûre",
        Description = "Élimine 3 Pillards à l'est des landes.",
        Kind = "Kill",
        Target = "Pillard",
        Count = 3,
        XP = 180,
        Gold = 40,
        Goal = Vector3.new(105, 23, 120),
    },
    {
        Name = "La forêt altérée",
        Description = "Élimine 3 Sylvains dans la forêt.",
        Kind = "Kill",
        Target = "Sylvain",
        Count = 3,
        XP = 250,
        Gold = 55,
        Tier = 2,
        Goal = Vector3.new(195, 23, 110),
    },
    {
        Name = "Les portes du sanctuaire",
        Description = "Élimine 3 Veilleurs devant les ruines.",
        Kind = "Kill",
        Target = "Veilleur",
        Count = 3,
        XP = 350,
        Gold = 75,
        Goal = Vector3.new(240, 23, -55),
    },
    {
        Name = "Le cœur brisé",
        Description = "Vaincs le Gardien. Sors du cercle avant son explosion.",
        Kind = "Kill",
        Target = "Gardien",
        Count = 1,
        XP = 650,
        Gold = 150,
        Tier = 3,
        Goal = Vector3.new(240, 23, -155),
    },
}

C.Zones = {
    A2 = {
        Id = "A2",
        Name = "A2 — Val d'Astréa",
        Short = "Val d'Astréa",
        Origin = Vector3.new(-900, 0, 0),
        GroundY = 20,
        Boundary = 330,
        Color = Color3.fromRGB(102, 190, 145),
        FogColor = Color3.fromRGB(174, 207, 214),
        Ambient = Color3.fromRGB(103, 119, 126),
        OutdoorAmbient = Color3.fromRGB(143, 158, 149),
        ClockTime = 14.4,
    },

    H2 = {
        Id = "H2",
        Name = "H2 — Terres cendrées de Khar",
        Short = "Terres cendrées de Khar",
        Origin = Vector3.new(900, 0, 0),
        GroundY = 20,
        Boundary = 330,
        Color = Color3.fromRGB(218, 132, 89),
        FogColor = Color3.fromRGB(211, 164, 126),
        Ambient = Color3.fromRGB(126, 99, 89),
        OutdoorAmbient = Color3.fromRGB(166, 132, 104),
        ClockTime = 17.1,
    },
}

function C.WorldPosition(zoneId, relative)
    return C.Zones[zoneId].Origin + relative
end

C.Mobs.MistAcolyte = {
    Name = "Acolyte de l'Écho",
    Level = 5,
    Health = 240,
    Damage = 16,
    Armor = 7,
    XP = 75,
    Gold = 13,
    Speed = 14,
    Scale = 1,
    Respawn = 999,
    Color = Color3.fromRGB(102, 130, 171),
}

C.Mobs.StoneWarden = {
    Name = "Gardien runique",
    Level = 7,
    Health = 520,
    Damage = 23,
    Armor = 17,
    XP = 135,
    Gold = 24,
    Speed = 11,
    Scale = 1.3,
    Respawn = 999,
    Color = Color3.fromRGB(112, 119, 135),
}

C.Mobs.EchoLord = {
    Name = "Seigneur de l'Écho",
    Level = 10,
    Health = 2400,
    Damage = 34,
    Armor = 24,
    XP = 650,
    Gold = 140,
    Speed = 13,
    Scale = 1.8,
    Respawn = 999,
    Boss = true,
    Color = Color3.fromRGB(155, 95, 205),
}

-- V2.3B : bestiaire spécifique aux deux territoires.
C.Mobs.Brumelin = {
    Name="Brumelin", Level=1, Health=105, Damage=8, Armor=1,
    XP=36, Gold=6, Speed=12, Scale=0.95, Respawn=14,
    Color=Color3.fromRGB(86,151,111),
}
C.Mobs.MaraudeurA2 = {
    Name="Maraudeur des cols", Level=3, Health=175, Damage=13, Armor=5,
    XP=58, Gold=10, Speed=14, Scale=1, Respawn=17,
    Color=Color3.fromRGB(137,108,87),
}
C.Mobs.SylvainA2 = {
    Name="Sylvain des crêtes", Level=5, Health=270, Damage=18, Armor=9,
    XP=86, Gold=15, Speed=13, Scale=1.14, Respawn=20,
    Color=Color3.fromRGB(74,139,117),
}
C.Mobs.SentinelleA2 = {
    Name="Sentinelle d'Astréa", Level=7, Health=410, Damage=23, Armor=15,
    XP=125, Gold=22, Speed=12, Scale=1.24, Respawn=24,
    Color=Color3.fromRGB(106,129,165),
}
C.Mobs.GardienMousse = {
    Name="Gardien moussu", Level=8, Health=560, Damage=26, Armor=19,
    XP=150, Gold=28, Speed=11, Scale=1.34, Respawn=27,
    Color=Color3.fromRGB(94,118,101),
}
C.Mobs.ColosseA2 = {
    Name="Colosse d'Astréa", Level=10, Health=2100, Damage=35, Armor=25,
    XP=560, Gold=120, Speed=12, Scale=1.8, Respawn=72, Boss=true,
    Color=Color3.fromRGB(101,154,188),
}

C.Mobs.Fouisseur = {
    Name="Fouisseur des sables", Level=1, Health=110, Damage=9, Armor=2,
    XP=37, Gold=6, Speed=13, Scale=0.95, Respawn=14,
    Color=Color3.fromRGB(194,140,81),
}
C.Mobs.PillardH2 = {
    Name="Pillard de Khar", Level=3, Health=185, Damage=14, Armor=6,
    XP=60, Gold=11, Speed=14, Scale=1, Respawn=17,
    Color=Color3.fromRGB(155,91,67),
}
C.Mobs.ChacalCendre = {
    Name="Chacal de cendre", Level=5, Health=285, Damage=19, Armor=8,
    XP=88, Gold=16, Speed=16, Scale=1.08, Respawn=20,
    Color=Color3.fromRGB(91,82,77),
}
C.Mobs.GolemBasalte = {
    Name="Golem de basalte", Level=7, Health=465, Damage=24, Armor=19,
    XP=130, Gold=23, Speed=11, Scale=1.34, Respawn=25,
    Color=Color3.fromRGB(102,89,84),
}
C.Mobs.TitanH2 = {
    Name="Titan des Marches", Level=10, Health=2250, Damage=36, Armor=26,
    XP=575, Gold=125, Speed=12, Scale=1.82, Respawn=74, Boss=true,
    Color=Color3.fromRGB(179,98,68),
}


-- VALBRUME_V2_6_EXPANSION_MOBS

C.Mobs.S3_Brumesang = {
    Name="Brumesang", Level=9, Health=620, Damage=28, Armor=12,
    XP=175, Gold=31, Speed=15, Scale=1.08, Respawn=20,
    Color=Color3.fromRGB(82,143,112),
}
C.Mobs.S3_RacineVive = {
    Name="Racine vive", Level=10, Health=760, Damage=30, Armor=18,
    XP=205, Gold=37, Speed=11, Scale=1.22, Respawn=23,
    Color=Color3.fromRGB(92,116,76),
}
C.Mobs.S3_VeilleurSylvestre = {
    Name="Veilleur sylvestre", Level=12, Health=3400, Damage=43, Armor=30,
    XP=910, Gold=220, Speed=12, Scale=1.9, Respawn=95, Boss=true,
    Color=Color3.fromRGB(95,179,139),
}

C.Mobs.N4_RodeurFalaise = {
    Name="Rôdeur des falaises", Level=11, Health=790, Damage=32, Armor=15,
    XP=220, Gold=40, Speed=16, Scale=1.05, Respawn=21,
    Color=Color3.fromRGB(125,155,167),
}
C.Mobs.N4_PilleurSel = {
    Name="Pilleur de sel", Level=12, Health=930, Damage=35, Armor=20,
    XP=255, Gold=47, Speed=14, Scale=1.08, Respawn=24,
    Color=Color3.fromRGB(131,119,111),
}
C.Mobs.N4_GardienNacre = {
    Name="Gardien de Nacre", Level=14, Health=3900, Damage=48, Armor=34,
    XP=1040, Gold=255, Speed=12, Scale=1.95, Respawn=100, Boss=true,
    Color=Color3.fromRGB(155,198,216),
}

C.Mobs.O5_MolosseRouille = {
    Name="Molosse de rouille", Level=13, Health=1020, Damage=38, Armor=21,
    XP=275, Gold=52, Speed=15, Scale=1.13, Respawn=22,
    Color=Color3.fromRGB(148,94,64),
}
C.Mobs.O5_ForgeEveillee = {
    Name="Forge éveillée", Level=14, Health=1220, Damage=41, Armor=28,
    XP=315, Gold=59, Speed=11, Scale=1.30, Respawn=25,
    Color=Color3.fromRGB(116,104,96),
}
C.Mobs.O5_MaitreFourneau = {
    Name="Maître-Fourneau", Level=16, Health=4550, Damage=53, Armor=39,
    XP=1180, Gold=295, Speed=11, Scale=2.0, Respawn=105, Boss=true,
    Color=Color3.fromRGB(207,115,61),
}

C.Mobs.V6_SpectreEcho = {
    Name="Spectre de l'Écho", Level=15, Health=1280, Damage=44, Armor=23,
    XP=335, Gold=64, Speed=16, Scale=1.10, Respawn=22,
    Color=Color3.fromRGB(132,108,190),
}
C.Mobs.V6_SentinelleCristal = {
    Name="Sentinelle cristalline", Level=16, Health=1510, Damage=47, Armor=32,
    XP=380, Gold=72, Speed=12, Scale=1.35, Respawn=26,
    Color=Color3.fromRGB(114,188,211),
}
C.Mobs.V6_NoyauResonant = {
    Name="Noyau Résonant", Level=18, Health=5200, Damage=59, Armor=44,
    XP=1380, Gold=345, Speed=11, Scale=2.08, Respawn=110, Boss=true,
    Color=Color3.fromRGB(177,111,226),
}


return C
