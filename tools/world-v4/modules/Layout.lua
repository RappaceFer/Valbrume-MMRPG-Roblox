-- Valbrume World V4: authoring coordinates, NOT current gameplay coordinates.
-- Read docs before moving NPCs/quests. The current MMO is not patched by this file.
local L = {
    Version = "4.0.0-authoring",
    Bounds = {-6144, -4096, 6144, 4096}, -- Xmin,Zmin,Xmax,Zmax; includes surrounding sea
    SeaY = 0, BottomY = -128, TopY = 384, Tile = 128, Resolution = 4,
    ShoreBlend = 180, MaxTiles = 6500,
    Continents = {
        {Id="Elyndra", X=-3200, Z=0, RX=2600, RZ=3300},
        {Id="Varkhun", X=3200, Z=0, RX=2600, RZ=3300},
    },
    Regions = {
        {Id="A2", Name="Val d'Astrea", Continent="Elyndra", X=-2000, Z=0, Theme="Meadow"},
        {Id="S3", Name="Sylvebrume", Continent="Elyndra", X=-2304, Z=-960, Theme="Forest"},
        {Id="N4", Name="Caps de Nacre", Continent="Elyndra", X=-2304, Z=1600, Theme="Mountain"},
        {Id="P6", Name="Marches de Brumepin", Continent="Elyndra", X=-3904, Z=-1792, Theme="Forest", Source="Place6.rbxl"},
        {Id="P9", Name="Val de Bellecorce", Continent="Elyndra", X=-3904, Z=896, Theme="Meadow", Source="Place9.rbxl"},
        {Id="H2", Name="Terres cendrees de Khar", Continent="Varkhun", X=2000, Z=0, Theme="Desert"},
        {Id="O5", Name="Forges d'Ormefer", Continent="Varkhun", X=2304, Z=-960, Theme="Volcanic"},
        {Id="V6", Name="Profondeurs de l'Echo", Continent="Varkhun", X=2304, Z=1600, Theme="Crystal"},
        {Id="P7", Name="Cendremer", Continent="Varkhun", X=3904, Z=-1792, Theme="Volcanic", Source="Place7.rbxl"},
        {Id="P8", Name="Citadelle de Noctefort", Continent="Varkhun", X=3904, Z=1152, Theme="Mountain", Source="Place8.rbxl"},
    },
    -- Traversal checks, not invisible teleport links. Gate design follows native-map review.
    Links = {{"A2","S3"},{"S3","P6"},{"A2","N4"},{"N4","P9"},{"P6","P9"},
             {"H2","O5"},{"O5","P7"},{"H2","V6"},{"V6","P8"},{"P7","P8"}},
}
return L
