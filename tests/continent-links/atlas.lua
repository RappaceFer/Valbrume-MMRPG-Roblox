-- Valbrume: authored region atlas for the TWO-CONTINENT CANDIDATE, not a gameplay rewrite.
-- Coordinates are world studs. Original gameplay centres and home profiles stay unchanged.
local Atlas = {
    Version = "continents-candidate-0.1",
    SeaLevel = 8,
    Bounds = {-4352, -3072, 4608, 3584}, -- minX,minZ,maxX,maxZ; includes surrounding ocean
    Order = {"A2","S3","N4","P6","P9","H2","O5","V6","P8","P7"},
    Regions = {
        A2={Name="Val d'Astrea",Continent="Elyndra",Center={-900,0},Radius=650,Legacy=true},
        S3={Name="Sylvebrume",Continent="Elyndra",Center={-1520,-560},Radius=700,Legacy=true},
        N4={Name="Caps de Nacre",Continent="Elyndra",Center={-1520,560},Radius=700,Legacy=true},
        P6={Name="Marches de Brumepin",Continent="Elyndra",Center={-2560,-1664},Radius=1250},
        P9={Name="Val de Bellecorce",Continent="Elyndra",Center={-2560,1664},Radius=1250},
        H2={Name="Terres de Khar",Continent="Varkhun",Center={900,0},Radius=650,Legacy=true},
        O5={Name="Forges d'Ormefer",Continent="Varkhun",Center={1520,-560},Radius=700,Legacy=true},
        V6={Name="Profondeurs de l'Echo",Continent="Varkhun",Center={1520,560},Radius=700,Legacy=true},
        P8={Name="Citadelle de Noctefort",Continent="Varkhun",Center={2560,-1664},Radius=1250},
        P7={Name="Presqu'ile de Cendremer",Continent="Varkhun",Center={2944,2048},Radius=1600},
    },
    Imported = {
        P6={Source="Place6.rbxl",Translation={-2560,0,-1664},Parts=1753},
        P9={Source="Place9.rbxl",Translation={-2560,0,1664},Parts=4447},
        P8={Source="Place8.rbxl",Translation={2560,0,-1664},Parts=9168},
        P7={Source="Place7.rbxl",Translation={2944,0,2048},Parts=15362},
    },
    -- Prospecting lines, not certified roads. The audit must report blocked/wet sections.
    Probes = {
        {Id="S3_P6",Points={{-1520,-560},{-1900,-1000},{-2160,-1350},{-2225,-1483}}},
        {Id="N4_P9",Points={{-1520,560},{-1900,1000},{-2160,1380},{-2410,1664}}},
        {Id="O5_P8",Points={{1520,-560},{1850,-980},{2190,-1350},{2614,-1608}}},
        {Id="V6_P7",Points={{1520,560},{1910,1020},{2160,1460},{2300,1588},{2900,1588},{3026,1823}}},
        {Id="S3_N4_BORDER",Points={{-1750,-340},{-1750,0},{-1750,340}}},
        {Id="O5_V6_BORDER",Points={{1750,-340},{1750,0},{1750,340}}},
    },
}
function Atlas.resolve(x,z)
    local b=Atlas.Bounds
    if x<b[1] or z<b[2] or x>b[3] or z>b[4] or math.abs(x)<400 then
        return "SEA",math.huge,nil
    end
    local continent=x<0 and "Elyndra" or "Varkhun"
    -- Preserve existing quest/combat region identification close to its established centre.
    for _,id in ipairs(Atlas.Order) do
        local r=Atlas.Regions[id]
        local dx,dz=x-r.Center[1],z-r.Center[2]
        if r.Legacy and r.Continent==continent and dx*dx+dz*dz<=330*330 then
            return id,math.sqrt(dx*dx+dz*dz),continent
        end
    end
    local selected,distance,best=nil,math.huge,math.huge
    for _,id in ipairs(Atlas.Order) do
        local r=Atlas.Regions[id]
        if r.Continent==continent then
            local dx,dz=x-r.Center[1],z-r.Center[2]
            local d=math.sqrt(dx*dx+dz*dz)
            local score=d/r.Radius
            if score<best then selected,distance,best=id,d,score end
        end
    end
    return selected,distance,continent
end
-- The atlas is a territorial partition, not a detector of water under a character.
return Atlas
