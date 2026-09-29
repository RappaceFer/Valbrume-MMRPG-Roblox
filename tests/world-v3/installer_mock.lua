-- Real generated installer/rollback with a small in-memory Studio API mock.
-- This checks transaction logic, NOT the Roblox Script Editor or Undo implementation.
local savedPrint=print
local cases=0
local function setup()
    local all, services, nextGuid = {},{},0
    local functions,meta={},{ }
    function meta.__index(o,k) return functions[k] or o.p[k] end
    function meta.__newindex(o,k,v)
        if k=="Parent" then
            local old=o.p.Parent
            if old then for i,c in ipairs(old.c) do if c==o then table.remove(old.c,i);break end end end
            o.p.Parent=v
            if v then v.c[#v.c+1]=o end
        else o.p[k]=v end
    end
    local function make(class)
        local o=setmetatable({p={ClassName=class,Name=class,Source="",Disabled=false},a={},c={}},meta)
        all[#all+1]=o; return o
    end
    function functions:GetChildren() local c={} for i,v in ipairs(self.c) do c[i]=v end return c end
    function functions:IsA(class) return self.ClassName==class end
    function functions:GetFullName() return self.Parent and self.Parent:GetFullName().."."..self.Name or self.Name end
    function functions:SetAttribute(k,v) self.a[k]=v end
    function functions:GetAttribute(k) return self.a[k] end
    function functions:FindFirstChild(name) for _,c in ipairs(self.c) do if c.Name==name then return c end end end
    Instance={new=make}
    Enum={RunContext={Legacy={Name="Legacy"},Client={Name="Client"}},FinishRecordingOperation={Commit="Commit",Cancel="Cancel"}}
    game=make("DataModel");game.Name="VALBRUME_DEV"
    function functions:GetService(name)
        if not services[name] then local s=make(name);s.Name=name;s.Parent=game;services[name]=s end
        return services[name]
    end
    local run=game:GetService("RunService")
    run.IsStudio=function() return true end
    run.IsRunning=function() return run.running==true end
    local editor=game:GetService("ScriptEditorService")
    editor.writes=0
    editor.GetEditorSource=function(_,o) return o.buffer or o.Source end
    editor.FindScriptDocument=function(_,o) return o.open and {} or nil end
    editor.UpdateSourceAsync=function(_,o,fn)
        editor.writes=editor.writes+1
        if editor.failAt==editor.writes then error("Injected write failure") end
        local text=fn(o.Source); if text then o.Source=text end
    end
    local http=game:GetService("HttpService")
    http.GenerateGUID=function() nextGuid=nextGuid+1;return "mock-guid-"..nextGuid end
    local history=game:GetService("ChangeHistoryService")
    local snap
    history.TryBeginRecording=function()
        assert(not snap)
        snap={}
        for _,o in ipairs(all) do
            local p,a={},{}
            for k,v in pairs(o.p) do p[k]=v end
            for k,v in pairs(o.a) do a[k]=v end
            snap[o]={p=p,a=a}
        end
        return "recording"
    end
    history.FinishRecording=function(_,_,operation)
        assert(snap)
        if operation=="Cancel" then
            for _,o in ipairs(all) do
                o.c={}
                if snap[o] then o.p=snap[o].p;o.a=snap[o].a else o.p.Parent=nil end
            end
            for _,o in ipairs(all) do if o.Parent then o.Parent.c[#o.Parent.c+1]=o end end
        end
        snap=nil
    end
    local function ensure(path,class)
        local o=game:GetService(path[1])
        for i=2,#path do
            local c=o:FindFirstChild(path[i])
            if not c then c=make(i==#path and class or "Folder");c.Name=path[i];c.Parent=o end
            o=c
        end
        return o
    end
    for _,f in ipairs(SOURCE_FIXTURES) do
        local o=ensure(f.Path,f.Class);o.Source=f.Source;o.RunContext=Enum.RunContext.Legacy
    end
    local server=ensure({"ServerScriptService","ValbrumeServer"},"Folder")
    for _,name in ipairs({"DungeonSpawnRequest","DungeonMobDied","WorldMobDiedV23","StoryRewardV23"}) do
        ensure({"ServerScriptService","ValbrumeServer",name},"BindableEvent")
    end
    for _,name in ipairs({"Request","State","Effects","PartyRemote","StoryRemoteV23","ExpansionStoryRemoteV26","JournalSyncRemoteV27"}) do
        ensure({"ReplicatedStorage","Valbrume",name},"RemoteEvent")
    end
    return server,editor,run,ensure
end
local install=RELEASE.."/01_INSTALL_WORLD_V3_1.lua"
local rollback=RELEASE.."/03_ROLLBACK_WORLD_V3_1.lua"
print=function() end;warn=function() end
local server,editor,run,ensure=setup()
local target=server:FindFirstChild("OpenWorldContinentsV28")
local original=target.Source
assert(pcall(dofile,install));assert(editor.writes==6)
assert(server:FindFirstChild("WorldV3") and target.Source~=original);cases=cases+1
local written=editor.writes
assert(pcall(dofile,install));assert(editor.writes==written);cases=cases+1
assert(pcall(dofile,rollback));assert(target.Source==original and not server:FindFirstChild("WorldV3"));cases=cases+1
-- A modified existing gameplay script stops installation before any write.
server,editor,run,ensure=setup()
server:FindFirstChild("Main").Source=server:FindFirstChild("Main").Source.."\n-- local edit"
assert(not pcall(dofile,install));assert(editor.writes==0 and not server:FindFirstChild("WorldV3"));cases=cases+1
-- A failure in the third write cancels the transaction.
server,editor,run,ensure=setup();target=server:FindFirstChild("OpenWorldContinentsV28");original=target.Source
editor.failAt=3
assert(not pcall(dofile,install));assert(target.Source==original and not server:FindFirstChild("WorldV3"));cases=cases+1
-- A local modification after install blocks both reinstallation and rollback.
server,editor,run,ensure=setup()
assert(pcall(dofile,install));written=editor.writes
local layout=server:FindFirstChild("WorldV3"):FindFirstChild("Layout")
layout.Source=layout.Source.."\n-- changed by designer"
assert(not pcall(dofile,install) and editor.writes==written);cases=cases+1
assert(not pcall(dofile,rollback) and editor.writes==written and layout.Parent);cases=cases+1
-- Play context and unsaved buffers are both rejected.
server,editor,run,ensure=setup();run.running=true
assert(not pcall(dofile,install) and editor.writes==0);cases=cases+1
server,editor,run,ensure=setup();target=server:FindFirstChild("OpenWorldContinentsV28");target.buffer=target.Source.." draft"
assert(not pcall(dofile,install) and editor.writes==0);cases=cases+1
-- Even an unchanged open target tab must be closed before source replacement.
server,editor,run,ensure=setup();server:FindFirstChild("OpenWorldContinentsV28").open=true
assert(not pcall(dofile,install) and editor.writes==0);cases=cases+1
print=savedPrint
print("PASS: "..cases.." installer/rollback scenarios with Studio API mock")
