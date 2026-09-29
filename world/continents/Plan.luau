-- DESIGN DATA ONLY: not an installer, no writes to the DataModel or Terrain.
-- The four native SmoothGrid payloads still require measurement in Studio.
-- Keep outside src until the full current DEV place and integration are validated.
local Plan = {
    SchemaVersion = 1,
    Status = "DesignOnly_NotInstalled",
    BaseCommit = "0f9f190077a3174a0a418eac0aae7c551871b7df",
    SamePlace = true,
    SeaLevel = 8, -- proposed: preserves the original maritime datum
    CentralSeaX = {-400, 400}, -- proposed no-land strip; not a Terrain measurement
    LegacyCenters = {
        A2 = {-900, 0, 0}, S3 = {-1520, 0, -560}, N4 = {-1520, 0, 560},
        H2 = {900, 0, 0}, O5 = {1520, 0, -560}, V6 = {1520, 0, 560},
    },
    Continents = {
        Elyndra = {Regions = {"A2", "S3", "N4", "P6", "P9"}},
        Varkhun = {Regions = {"H2", "O5", "V6", "P8", "P7"}},
    },
    -- A connected graph is a design gate, NOT a proof of connected terrain.
    LandAdjacencies = {
        {"A2", "S3"}, {"A2", "N4"}, {"S3", "N4"},
        {"S3", "P6"}, {"A2", "P9"}, {"N4", "P9"},
        {"H2", "O5"}, {"H2", "V6"}, {"O5", "V6"},
        {"O5", "P8"}, {"V6", "P7"}, {"H2", "P7"},
    },
    Sources = {
        P6 = {
            File = "Place6.rbxl", Continent = "Elyndra",
            ProposedName = "Marches de Brumepin",
            SHA256 = "a97963be7751e6c8f17cc1e187ee9c5d5c7515ee011fef6fb59e7f16374de6d0",
            Translation = {-2368, 0, -1408}, Yaw = 0, Scale = 1,
            FileInstances = 2536, WorkspaceParts = 1767, LuaSources = 30,
            PartsSize = {1001.600006, 147.483250, 988},
            TerrainBoundsKnown = false, LicenseVerified = false,
        },
        P9 = {
            File = "Place9.rbxl", Continent = "Elyndra",
            ProposedName = "Val de Bellecorce",
            SHA256 = "acb896a8728dcaedd9d92995dcd2b2ebf28c850b0e56bd38bb281aeb35b75646",
            Translation = {-2368, 0, 1408}, Yaw = 0, Scale = 1,
            FileInstances = 21618, WorkspaceParts = 4491, LuaSources = 30,
            PartsSize = {974.399608, 177.990207, 967.100610},
            TerrainBoundsKnown = false, LicenseVerified = false,
        },
        P8 = {
            File = "Place8.rbxl", Continent = "Varkhun",
            ProposedName = "Citadelle de Noctefort",
            SHA256 = "d2fcfd955d98da0081c583421b7d72bc8ad551907233063438652cdd2b811394",
            Translation = {2368, 0, -1408}, Yaw = 0, Scale = 1,
            FileInstances = 40190, WorkspaceParts = 9209, LuaSources = 14,
            PartsSize = {922.100579, 129.937923, 966.050844},
            TerrainBoundsKnown = false, LicenseVerified = false,
        },
        P7 = {
            File = "Place7.rbxl", Continent = "Varkhun",
            ProposedName = "Presqu'ile de Cendremer",
            Translation = {2560, 0, 1344}, Yaw = 0, Scale = 1,
            SHA256 = "c6be992a206ea27de8e97c2e3f6e6e0120f939713332157a2975b3ab3d5193f7",
            FileInstances = 17107, WorkspaceParts = 15363, LuaSources = 49,
            PartsSize = {1466.101675, 183.776446, 1724.702013},
            TerrainBoundsKnown = false, LicenseVerified = false,
        },
    },
    Gates = {
        CurrentDevPlaceReceived = false,
        SourceTerrainMeasured = false,
        TerrainConnectedInRoblox = false,
        GameplayRegressionPassed = false,
        MobileProfilePassed = false,
    },
}
return Plan
