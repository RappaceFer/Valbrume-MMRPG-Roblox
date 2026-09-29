-- Six links only. Native terrain is retained; no V3 route, map or sea redesign.
-- Points: {X, fallback ground Y, Z}. Y is used ONLY for genuinely empty columns
-- outside native-map bounds, never to flatten an existing hill/cave/river.
local P = {
    Version = "six-links-0.2.5",
    Resolution = 4, TileSize = 64, MinY = -256, MaxY = 384,
    CoreRadius = 32, OuterRadius = 48, FoundationY = -96, FillFootprint = 16,
    MaxTiles = 640, MaxSeconds = 85, CheckStep = 12, PhysicsSettleSeconds = 1.0, RefreshTileSize = 32, MaxRefreshTiles = 96,
    CheckOffsets = {-16, 0, 16}, MaxDetails = 12,
    -- Native chunk envelopes. Do not synthesize missing source-map content.
    -- Refreshing a column with existing native voxels does not change its geometry.
    SourceBounds = {
        {-3072,-2304,-2048,-1152}, -- P6
        {-3200,1024,-1920,2304},   -- P9
        {2048,-2304,3200,-1024},   -- P8
        {1920,1024,3968,3072},     -- P7 (includes its native water)
    },
    Links = {
        {Id="S3_P6", Material="Ground", Points={
            {-1520,27,-560},{-1900,28,-1000},{-2160,10,-1350},{-2225,7,-1483}}},
        {Id="N4_P9", Material="Ground", Points={
            {-1520,33,560},{-1900,29,1000},{-2160,20,1380},{-2410,12,1664}}},
        {Id="O5_P8", Material="Slate", Points={
            {1520,29,-560},{1850,30,-980},{2190,25,-1350},{2614,15,-1608}}},
        {Id="V6_P7", Material="Basalt", Points={
            {1520,30,560},{1910,27,1020},{2160,20,1460},{2300,16,1588},
            {2900,21,1588},{3026,15,1823}}},
        {Id="S3_N4_BORDER", Material="Ground", Points={
            {-1750,27,-340},{-1750,30,0},{-1750,33,340}}},
        {Id="O5_V6_BORDER", Material="Slate", Points={
            {1750,29,-340},{1750,30,0},{1750,30,340}}},
    },
}
return P
