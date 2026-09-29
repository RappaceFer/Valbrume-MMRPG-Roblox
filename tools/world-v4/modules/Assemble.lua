-- Studio authoring only. Builds the future map in an EMPTY construction place.
-- Does not install/replace Valbrume gameplay. Native inputs are never moved/deleted.
local A = {}
local function inside(r,x,z) return x>=r.x0 and x<r.x1 and z>=r.z0 and z<r.z1 end
local function intersect(r,x0,z0,x1,z1) return x0<r.x1 and x1>r.x0 and z0<r.z1 and z1>r.z0 end
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function smoothing(t) t=clamp(t,0,1);return t*t*(3-2*t) end
local function abortIfRequested(root)
    assert(root.Parent==workspace and root:GetAttribute("CancelBuild")~=true,
        "Construction interrompue : recharge la copie de chantier vide, sans enregistrer ce resultat partiel")
end
function A.build(layout,field)
    local run=game:GetService("RunService")
    assert(run:IsStudio() and not run:IsRunning(),"Construction uniquement dans Studio, Play ARRETE")
    local ss=game:GetService("ServerStorage")
    assert(not game:GetService("ServerScriptService"):FindFirstChild("ValbrumeServer"),
        "Pas dans DEV : utiliser une place de chantier vide. Le gameplay doit etre migre APRES validation.")
    assert(not workspace:FindFirstChild("ValbrumeContinentsV4"),"Construction deja presente; pas d'ecrasement")
    local terrain=workspace.Terrain
    assert(terrain:CountCells()==0,"Le Terrain doit etre vide; aucun effacement automatique")
    local baseplate
    for _,o in ipairs(workspace:GetChildren()) do
        if o.Name=="Baseplate" and o:IsA("BasePart") then baseplate=o
        else assert(o:IsA("Camera") or o:IsA("Terrain"),"Workspace non vide: "..o.Name) end
    end
    field.validate(layout)
    local sourceRoot=ss:FindFirstChild("WorldV4Sources")
    assert(sourceRoot,"Placer les exports natifs dans ServerStorage.WorldV4Sources")
    local found={}
    for _,o in ipairs(sourceRoot:GetDescendants()) do
        if o:GetAttribute("Format")=="ValbrumeNativeMap/1" then
            local id=o:GetAttribute("SourceId")
            assert(not found[id],"Source dupliquee: "..id); found[id]=o
        end
    end
    local records={}
    for _,r in ipairs(layout.Regions) do
        local p=assert(found[r.Id],"Source native manquante: "..r.Id)
        local native=assert(p:FindFirstChild("NativeTerrain"),"Terrain manquant: "..r.Id)
        local decor=assert(p:FindFirstChild("Decor"),"Decor manquant: "..r.Id)
        assert(native:IsA("TerrainRegion") and decor:IsA("Model"),"Types natifs invalides")
        local min,size,anchor=p:GetAttribute("MinCell"),native.SizeInCells,p:GetAttribute("SourceAnchor")
        assert(typeof(min)=="Vector3" and typeof(anchor)=="Vector3" and size.X>0,"Metadonnees manquantes")
        local d=Vector3.new(r.X,0,r.Z)-anchor
        assert(d.X%4==0 and d.Y%4==0 and d.Z%4==0,"Translation hors grille Terrain")
        local low=min*4+d; local high=low+size*4
        assert(low.Y>=layout.BottomY and high.Y<=layout.TopY,"Capture verticale hors budget")
        assert(low.X>=layout.Bounds[1] and high.X<=layout.Bounds[3] and low.Z>=layout.Bounds[2]
            and high.Z<=layout.Bounds[4],"Carte hors cadre: "..r.Id)
        for _,o in ipairs(p:GetDescendants()) do
            assert(not o:IsA("LuaSourceContainer") and not o:IsA("RemoteEvent") and not o:IsA("RemoteFunction")
                and not o:IsA("Tool") and not o:IsA("Humanoid") and not o:IsA("SpawnLocation"),
                "Objet actif dans export: "..o:GetFullName())
            if o:IsA("BasePart") then assert(o.Anchored,"Part non ancree: "..o.Name) end
        end
        local rec={id=r.Id,source=p,native=native,decor=decor,delta=d,low=low,high=high,
            x0=low.X,x1=high.X,z0=low.Z,z1=high.Z}
        for _,other in ipairs(records) do
            assert(not intersect(other,rec.x0,rec.z0,rec.x1,rec.z1),"Captures superposees: "..r.Id.." / "..other.id)
        end
        records[#records+1]=rec
    end
    local tile=layout.Tile;local b=layout.Bounds
    local total=(b[3]-b[1])/tile*(b[4]-b[2])/tile
    assert(total%1==0 and total<=layout.MaxTiles,"Budget de tuiles depasse")
    -- All validation above happens before the first change.
    if baseplate then baseplate.Parent=ss end
    local root=Instance.new("Folder"); root.Name="ValbrumeContinentsV4"
    root:SetAttribute("Status","BUILDING");root:SetAttribute("Version",layout.Version);root.Parent=workspace
    local started=os.clock()
    local ok,err=xpcall(function()
        for _,r in ipairs(records) do
            abortIfRequested(root)
            local v=r.low/4
            terrain:PasteRegion(r.native,Vector3int16.new(v.X,v.Y,v.Z),true)
            local decor=r.decor:Clone(); decor.Name=r.id
            decor:PivotTo(decor:GetPivot()+r.delta);decor.Parent=root
        end
        -- Snapshot perimeter heights BEFORE generating surrounding terrain.
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances={terrain};params.IgnoreWater=false
        local function top(x,z)
            local h=workspace:Raycast(Vector3.new(x,layout.TopY+32,z),Vector3.new(0,-640,0),params)
            return h and h.Position.Y
        end
        local grid=32
        for _,r in ipairs(records) do
            r.nz=math.floor((r.z1-r.z0-4)/grid);r.nx=math.floor((r.x1-r.x0-4)/grid)
            r.tops={}
            for ix=0,r.nx do
                r.tops[ix]={}
                for iz=0,r.nz do r.tops[ix][iz]=top(r.x0+2+ix*grid,r.z0+2+iz*grid) end
                if ix%8==0 then task.wait() end
            end
        end
        local function nearestNative(r,x,z)
            if x<r.x0-layout.ShoreBlend or x>r.x1+layout.ShoreBlend
                or z<r.z0-layout.ShoreBlend or z>r.z1+layout.ShoreBlend then return nil end
            local gx=math.floor((x-r.x0-2)/grid+.5);local gz=math.floor((z-r.z0-2)/grid+.5)
            local best,hy=layout.ShoreBlend^2,nil
            local steps=math.ceil(layout.ShoreBlend/grid)
            for ix=math.max(0,gx-steps),math.min(r.nx,gx+steps) do
                for iz=math.max(0,gz-steps),math.min(r.nz,gz+steps) do
                    local y=r.tops[ix][iz]
                    if y then
                        local d=(x-r.x0-2-ix*grid)^2+(z-r.z0-2-iz*grid)^2
                        if d<best then best,hy=d,y end
                    end
                end
            end
            return hy,math.sqrt(best)
        end
        local function height(x,z)
            local y,mat=field.sample(layout,x,z)
            local weighted,total=y,1
            for _,r in ipairs(records) do
                local h,d=nearestNative(r,x,z)
                if h then
                    local t=d/layout.ShoreBlend
                    local w=(1-t)^4/(t*t+.000001)
                    weighted,total=weighted+h*w,total+w
                end
            end
            return clamp(weighted/total,layout.BottomY+8,layout.TopY-8),Enum.Material[mat]
        end
        local done=0
        for x0=b[1],b[3]-tile,tile do for z0=b[2],b[4]-tile,tile do
            abortIfRequested(root)
            local touching={}
            for _,r in ipairs(records) do if intersect(r,x0,z0,x0+tile,z0+tile) then touching[#touching+1]=r end end
            do
                local n=tile/4; local hs,ms={},{};local minH,maxH=math.huge,-math.huge
                for ix=1,n do hs[ix]={};ms[ix]={};for iz=1,n do
                    local h,m=height(x0+(ix-.5)*4,z0+(iz-.5)*4)
                    hs[ix][iz],ms[ix][iz]=h,m;minH=math.min(minH,h);maxH=math.max(maxH,h)
                end end
                local lowY=layout.BottomY;local highY=layout.TopY
                if #touching==0 then
                    lowY=math.max(layout.BottomY,math.floor((minH-8)/4)*4)
                    highY=math.ceil((math.max(maxH,layout.SeaY)+8)/4)*4
                    if lowY>layout.BottomY then
                        terrain:FillBlock(CFrame.new(x0+tile/2,(layout.BottomY+lowY)/2,z0+tile/2),
                            Vector3.new(tile,lowY-layout.BottomY,tile),Enum.Material.Rock)
                    end
                end
                local region=Region3.new(Vector3.new(x0,lowY,z0),Vector3.new(x0+tile,highY,z0+tile))
                local data
                if #touching>0 then data=terrain:ReadVoxelChannels(region,4,{"SolidMaterial","SolidOccupancy","LiquidOccupancy"})
                else data={SolidMaterial={},SolidOccupancy={},LiquidOccupancy={}} end
                local ny=(highY-lowY)/4
                for ix=1,n do
                    if #touching==0 then data.SolidMaterial[ix]={};data.SolidOccupancy[ix]={};data.LiquidOccupancy[ix]={} end
                    local protected={}
                    for iz=1,n do
                        local inSource=false
                        for _,r in ipairs(touching) do
                            if inside(r,x0+(ix-.5)*4,z0+(iz-.5)*4) then inSource=true;break end
                        end
                        if inSource then
                            -- Preserve native caves, water and relief, but not empty padding around a map.
                            for iy=1,ny do
                                if data.SolidOccupancy[ix][iy][iz]>0 or data.LiquidOccupancy[ix][iy][iz]>0 then
                                    protected[iz]=true;break
                                end
                            end
                        end
                    end
                    for iy=1,ny do
                        if #touching==0 then data.SolidMaterial[ix][iy]={};data.SolidOccupancy[ix][iy]={};data.LiquidOccupancy[ix][iy]={} end
                        local bottom=lowY+(iy-1)*4
                        for iz=1,n do if not protected[iz] then
                            local h=hs[ix][iz];local so=clamp((h-bottom)/4,0,1)
                            local lo=clamp((layout.SeaY-bottom)/4,0,1)
                            data.SolidMaterial[ix][iy][iz]=so>0 and (bottom<h-8 and Enum.Material.Rock or ms[ix][iz]) or Enum.Material.Air
                            data.SolidOccupancy[ix][iy][iz]=so
                            data.LiquidOccupancy[ix][iy][iz]=so>=1 and 0 or lo
                        end end
                    end
                end
                terrain:WriteVoxelChannels(region,4,data)
            end
            done=done+1
            if done%16==0 then root:SetAttribute("Progress",done/total);task.wait() end
            if done%256==0 then print("[VALBRUME V4] "..done.." / "..total.." tuiles") end
        end end
        root:SetAttribute("Status","BUILT_UNVALIDATED");root:SetAttribute("Progress",1)
        root:SetAttribute("BuildSeconds",os.clock()-started)
        print("[VALBRUME V4] ASSEMBLAGE TERMINE. Pas une validation des collisions, routes ou du gameplay.")
    end,debug.traceback)
    if not ok then
        root:SetAttribute("Status","FAILED_PARTIAL");root:SetAttribute("Error",tostring(err))
        error("Echec de construction. Ne pas utiliser le resultat partiel. Recharge la place de chantier vide.\n"..tostring(err))
    end
    return root
end
return A
