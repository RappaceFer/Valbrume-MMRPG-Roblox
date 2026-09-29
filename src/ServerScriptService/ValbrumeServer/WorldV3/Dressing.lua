-- Small, original wayfinding props. No downloaded assets, scripts or mesh IDs.
-- Only recognisable WorldBuilder vegetation may be repositioned, at runtime.
local G = require(script.Parent.Geometry)
local D = {}
local function terrainHit(x,z)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {workspace.Terrain}
    params.IgnoreWater = false
    return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-320,0),params)
end
local function part(parent,name,size,cf,material,color)
    local p = Instance.new("Part")
    p.Name, p.Size, p.CFrame = name, size, cf
    p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
    p.Material, p.Color, p.CastShadow = material, color, false
    p.Parent = parent
    return p
end
local function originalVegetation(model)
    if not model:IsA("Model") or (model.Name ~= "Tree" and model.Name ~= "Cactus") then return nil end
    local trunk = model:FindFirstChild("Trunk")
    if not trunk or not trunk:IsA("BasePart") then return nil end
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("LuaSourceContainer") or item:IsA("Humanoid") then return nil end
        if item:IsA("BasePart") and not item.Anchored then return nil end
    end
    return trunk
end
function D.build(world,root,layout)
    local moved = 0
    for _, model in ipairs(world.Decor:GetChildren()) do
        local trunk = originalVegetation(model)
        if trunk then
            local p = trunk.Position
            local s = G.field(layout.Routes,p.X,p.Z)
            if s then
                local x,z = p.X,p.Z
                if s.Distance < s.Route.Core+4 then
                    local nx,nz = -s.DZ,s.DX
                    local side = (x-s.X)*nx+(z-s.Z)*nz >= 0 and 1 or -1
                    local offset = s.Route.Core+14+math.max(trunk.Size.X,trunk.Size.Z)
                    x,z = s.X+nx*side*offset,s.Z+nz*side*offset
                end
                local hit = terrainHit(x,z)
                if hit and hit.Material ~= Enum.Material.Water and hit.Material ~= Enum.Material.CrackedLava then
                    local oldBottom = p.Y-trunk.Size.Y/2
                    model:PivotTo(model:GetPivot()+Vector3.new(x-p.X,hit.Position.Y-oldBottom,z-p.Z))
                    moved = moved+1
                end
            end
        end
    end
    for _, route in ipairs(layout.Routes) do
        local folder = Instance.new("Folder")
        folder.Name, folder.Parent = route.Id, root.Roads
        folder:SetAttribute("FromRegion",route.From)
        folder:SetAttribute("ToRegion",route.To)
        folder:SetAttribute("WorldV3Route",true)
        -- Two roadside markers, never a row of collidable props across the lane.
        for _, index in ipairs({2,#route.Points-1}) do
            local p,q = route.Points[index],route.Points[index+1]
            local dx,dz = q[1]-p[1],q[3]-p[3]
            local length = math.sqrt(dx*dx+dz*dz)
            local x,z = p[1]-dz/length*(route.Core+10),p[3]+dx/length*(route.Core+10)
            local hit = terrainHit(x,z)
            if hit then
                local model = Instance.new("Model")
                model.Name,model.Parent = "Waystone_"..index,folder
                local cf = CFrame.lookAt(hit.Position,hit.Position+Vector3.new(dx,0,dz))
                local color = Color3.fromRGB(route.Color[1],route.Color[2],route.Color[3])
                local base = part(model,"Base",Vector3.new(3.5,1,3.5),cf*CFrame.new(0,.5,0),Enum.Material.Slate,Color3.fromRGB(83,83,79))
                part(model,"Pillar",Vector3.new(1.4,8,1.4),cf*CFrame.new(0,5,0),Enum.Material.Slate,Color3.fromRGB(123,119,107))
                local lens = part(model,"Rune",Vector3.new(1.7,1.7,1.7),cf*CFrame.new(0,9,0),Enum.Material.Neon,color)
                part(model,"Banner",Vector3.new(.18,3.8,2.2),cf*CFrame.new(0,6.2,1.8),Enum.Material.Fabric,color)
                model.PrimaryPart = base
                local gui = Instance.new("BillboardGui")
                gui.Name,gui.Adornee,gui.Size = "RouteLabel",lens,UDim2.fromOffset(240,38)
                gui.StudsOffsetWorldSpace,gui.MaxDistance,gui.AlwaysOnTop = Vector3.new(0,2,0),70,false
                gui.Parent = model
                local text = Instance.new("TextLabel")
                text.Size,text.BackgroundTransparency = UDim2.fromScale(1,1),1
                text.Text,text.TextSize,text.Font = route.Title,15,Enum.Font.GothamSemibold
                text.TextColor3,text.TextStrokeTransparency,text.Parent = color,.4,gui
            end
        end
    end
    return moved
end
return D
