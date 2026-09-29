-- Pure numeric landmass field: one height function, not per-region terrain islands.
local H = {}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function smooth(v) v=clamp(v,0,1); return v*v*(3-2*v) end
function H.sample(layout,x,z)
    local best,continent = math.huge,nil
    for _, c in ipairs(layout.Continents) do
        local d=math.sqrt(((x-c.X)/c.RX)^2+((z-c.Z)/c.RZ)^2)
        if d<best then best,continent=d,c.Id end
    end
    if best>=1 then return -48,"Sand",nil end
    local coast=smooth((1-best)/.16)
    local selected,nearest=nil,math.huge
    local sum,weight=0,0
    for _,r in ipairs(layout.Regions) do
        if r.Continent==continent then
            local d2=(x-r.X)^2+(z-r.Z)^2
            if d2<nearest then selected,nearest=r,d2 end
            local w=1/(1+d2/(700*700))^2
            local hills=math.sin(x/390+z/640)*math.cos(z/310-x/750)
            local y=34+12*hills
            if r.Theme=="Mountain" then
                y=y+125*(.5+.5*math.sin(x/640-z/530))^3
            elseif r.Theme=="Desert" then y=y+16*math.sin(x/1100+z/125)^2
            elseif r.Theme=="Volcanic" then y=y+60*(.5+.5*math.cos(x/450+z/380))^2
            elseif r.Theme=="Crystal" then y=y+45*(.5+.5*math.sin(x/360-z/280))^2
            elseif r.Theme=="Forest" then y=y+18*(.5+.5*math.sin(x/270+z/290)) end
            sum,weight=sum+y*w,weight+w
        end
    end
    local y=-48*(1-coast)+(sum/weight)*coast
    local material="Grass"
    if y<7 then material="Sand"
    elseif selected.Theme=="Desert" then material="Sand"
    elseif selected.Theme=="Volcanic" then material="Basalt"
    elseif selected.Theme=="Crystal" then material="Slate"
    elseif selected.Theme=="Mountain" then material=y>128 and "Snow" or "Rock" end
    return y,material,selected.Id
end
function H.validate(layout)
    local ids={}
    assert(#layout.Continents==2 and #layout.Regions==10,"Expected 2 continents and 10 regions")
    for _,r in ipairs(layout.Regions) do
        assert(not ids[r.Id],"Duplicate region"); ids[r.Id]=r
        assert(r.X%4==0 and r.Z%4==0,"Coordinates must align to Terrain cells")
        local y=H.sample(layout,r.X,r.Z)
        assert(y>layout.SeaY+8,"Region anchor is at sea: "..r.Id)
    end
    for _,pair in ipairs(layout.Links) do
        local a,b=assert(ids[pair[1]]),assert(ids[pair[2]])
        assert(a.Continent==b.Continent,"A land route crosses the sea")
    end
    return ids
end
return H
