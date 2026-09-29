-- C1 art-only ground finish. No gameplay or global terrain/lighting changes.
local world=require(script.Parent.WorldGeneration).Await("Ready")
local root=workspace:FindFirstChild("ValbrumeArtPassC1")
if not root then return end
assert(world==workspace:FindFirstChild("ValbrumeWorld") and world:GetAttribute("GenerationReady"))
local function apply()
-- C1 local material-only patch; occupancy and terrain elevations remain unchanged.
local terrain=workspace.Terrain
local region=Region3.new(Vector3.new(-908,24,-92),Vector3.new(-880,36,-28))
local materials,occupancy=terrain:ReadVoxels(region,4)
local changed={}
local function nearSegment(x,z,ax,az,bx,bz)
 local dx,dz=bx-ax,bz-az;local t=math.clamp(((x-ax)*dx+(z-az)*dz)/(dx*dx+dz*dz),0,1)
 return (x-ax-t*dx)^2+(z-az-t*dz)^2<=9
end
for i,column in ipairs(materials)do for j,row in ipairs(column)do for k,material in ipairs(row)do
 local x,y,z=-908+(i-.5)*4,24+(j-.5)*4,-92+(k-.5)*4
 local inside=x>=-908 and x<=-882 and z>=-90 and z<=-54
 inside=inside or nearSegment(x,z,-895,-54,-889,-45)or nearSegment(x,z,-889,-45,-889,-30)
 if inside and material==Enum.Material.Grass and occupancy[i][j][k]>0 then
  table.insert(changed,{x=x,y=y,z=z,before='Grass',after='Ground',occupancy=occupancy[i][j][k]})
  materials[i][j][k]=Enum.Material.Ground
 end
end end end
terrain:WriteVoxels(region,4,materials,occupancy)
return {changed=changed,count=#changed,occupancyModified=false,bounds={-908,24,-92,-880,36,-28}}
end
local result=apply()
root:SetAttribute("C1GroundReady",true)
root:SetAttribute("C1GroundChangedVoxels",result.count)
root:SetAttribute("C1GenerationId",world:GetAttribute("GenerationId"))
