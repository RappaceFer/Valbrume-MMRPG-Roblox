-- First LANDSCAPE worksite. Not a full-world rework; no new gameplay.
return {
    Version = "s3-p6-landscape-0.3.0",
    BaseCandidate = "continents-candidate-0.2.5",
    Resolution = 4, TileSize = 32, MinY = -128, MaxY = 192,
    MaxTiles = 240, MaxSeconds = 65, MaxColumns = 18000,
    -- X/Z only: the two endpoint heights are measured in the running engine.
    Points = {{-1700,-760},{-1772,-842},{-1868,-950},{-1940,-1054},{-2028,-1140}},
    CoreRadius = 32, OuterRadius = 108, EndFade = 88,
    Crest = 3, MaxCut = 32, MaxFill = 128, CoverDepth = 12,
    SourceMoat = 48, SourceFeather = 56,
    ProtectedSources = {
        {-3072,-2304,-2048,-1152}, {-3200,1024,-1920,2304},
        {2048,-2304,3200,-1024}, {1920,1024,3968,3072},
    },
    ObjectMoat = 6, ObjectFeather = 20, MaxObjects = 2000,
    EndpointProbe = 24, AuditStep = 6, AuditOffsets = {-24,-12,0,12,24},
    MaxSlope = 30, MaxGrade = 25, Headroom = 6, AvatarWidth = 4,
    MaxDetails = 16,
}
