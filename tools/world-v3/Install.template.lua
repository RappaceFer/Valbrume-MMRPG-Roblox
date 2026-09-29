-- Valbrume World V3.1 installer. COMMAND BAR, EDIT MODE, VALBRUME_DEV ONLY.
-- Writes scripts, NOT Terrain. Generated terrain changes only on the next Play.
-- Offline payload; no HttpGet, loadstring, numeric require or DataStore access.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Arrete Play. Installation uniquement en mode Edit.")
assert(not string.find(string.upper(game.Name),"BASELINE",1,true), "Ne pas installer dans la baseline.")
local SES = game:GetService("ScriptEditorService")
local CHS = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")
local function normalized(text) return (text:gsub("\r\n","\n")) end
local function child(parent,name,optional)
    local found
    for _, item in ipairs(parent:GetChildren()) do
        if item.Name == name then assert(not found,"Nom duplique: "..name); found=item end
    end
    assert(optional or found,"Objet absent: "..name)
    return found
end
local function resolve(path)
    local object=game:GetService(path[1])
    for i=2,#path do object=child(object,path[i]) end
    return object
end
local function source(object)
    local text=SES:GetEditorSource(object)
    assert(normalized(text)==normalized(object.Source),"Brouillon non enregistre: "..object:GetFullName())
    return text
end
local function write(object,before,after)
    SES:UpdateSourceAsync(object,function(old)
        if normalized(old)~=normalized(before) then return nil end
        return after
    end)
    assert(normalized(source(object))==normalized(after),"Ecriture annulee ou concurrente: "..object.Name)
end
-- All gates are evaluated before creating even the backup folder.
for _, item in ipairs(DEPENDENCIES) do
    local object=resolve(item.Path)
    assert(object.ClassName==item.Class,"Classe inattendue: "..object:GetFullName())
    local digest=blobHash(source(object))
    local allowed=false
    for _, known in ipairs(item.Hashes) do if digest==known then allowed=true end end
    assert(allowed,"Source Studio differente du depot: "..object:GetFullName().." ["..digest.."]. Aucun ecrasement.")
end
local server=resolve({"ServerScriptService","ValbrumeServer"})
for _, name in ipairs({"DungeonSpawnRequest","DungeonMobDied","WorldMobDiedV23","StoryRewardV23"}) do
    assert(child(server,name):IsA("BindableEvent"),"Contrat serveur absent: "..name)
end
local packageRoot=resolve({"ReplicatedStorage","Valbrume"})
for _, name in ipairs({"Request","State","Effects","PartyRemote","StoryRemoteV23","ExpansionStoryRemoteV26","JournalSyncRemoteV27"}) do
    assert(child(packageRoot,name):IsA("RemoteEvent"),"Remote absent: "..name)
end
for _, item in ipairs(PAYLOAD) do
    assert(blobHash(item.Source)==item.Hash,"Payload incomplet: "..item.Name)
end
local target=child(server,"OpenWorldContinentsV28")
assert(target:IsA("Script") and not target.Disabled,"Generateur absent ou desactive")
assert(target.RunContext~=Enum.RunContext.Client,"Generateur configure cote Client")
assert(not SES:FindScriptDocument(target),"Ferme l'onglet OpenWorldContinentsV28 avant l'installation.")
local installed=child(server,"WorldV3",true)
if installed then
    assert(installed:IsA("Folder") and installed:GetAttribute("Release")==VERSION,"WorldV3 existe deja: aucun remplacement automatique.")
    assert(#installed:GetChildren()==#PAYLOAD-1,"WorldV3 contient des fichiers supplementaires")
    for _, item in ipairs(PAYLOAD) do
        local object=item.Kind=="bootstrap" and target or child(installed,item.Name)
        assert(object.ClassName==item.Class and blobHash(source(object))==item.Hash,"Installation modifiee: "..item.Name)
    end
    print("[VALBRUME V3.1 INSTALL] DEJA INSTALLE — aucune modification.")
    return
end
local storage=game:GetService("ServerStorage")
local backups=child(storage,"ValbrumeInstallBackups",true)
assert(not backups or backups:IsA("Folder"),"ValbrumeInstallBackups n'est pas un Folder")
local before=source(target)
local beforeDisabled=target.Disabled
local beforeContext=target.RunContext.Name
local backupName="WorldV3_3_1_0_"..HttpService:GenerateGUID(false)
local function beginRecordingWithRetry()
    local attempts=8
    for attempt=1,attempts do
        local record=CHS:TryBeginRecording("ValbrumeWorldV31Install","Installer Valbrume World V3.1")
        if record then return record end
        if attempt<attempts then
            warn(string.format("[VALBRUME V3.1 INSTALL] Historique Studio occupe — nouvelle tentative %d/%d dans 0.75 s.",attempt+1,attempts))
            task.wait(0.75)
        end
    end
    error("Historique Studio toujours occupe apres plusieurs tentatives. Ferme les outils/plugins qui modifient la scene, attends quelques secondes puis relance l'installateur complet.")
end
local record=beginRecordingWithRetry()
local created,backup,createdBackups
local ok,err=xpcall(function()
    if not backups then
        backups=Instance.new("Folder"); backups.Name="ValbrumeInstallBackups"; backups.Parent=storage
        createdBackups=backups
    end
    backup=Instance.new("Folder"); backup.Name=backupName; backup.Parent=backups
    backup:SetAttribute("Release",VERSION)
    backup:SetAttribute("OriginalHash",blobHash(before))
    backup:SetAttribute("OriginalDisabled",beforeDisabled)
    backup:SetAttribute("OriginalRunContext",beforeContext)
    backup:SetAttribute("CreatedAt",os.time())
    local snapshot=Instance.new("StringValue")
    snapshot.Name="OriginalSource"; snapshot.Value=before; snapshot.Parent=backup
    assert(blobHash(snapshot.Value)==blobHash(before),"Sauvegarde du script incomplete")
    created=Instance.new("Folder"); created.Name="WorldV3"
    created:SetAttribute("Release",VERSION); created:SetAttribute("BackupName",backupName); created.Parent=server
    for _, item in ipairs(PAYLOAD) do
        if item.Kind=="module" then
            local object=Instance.new(item.Class)
            object.Name=item.Name; object.Parent=created
            write(object,source(object),item.Source)
        end
    end
    -- Switch the entry point only after every module is installed and verified.
    for _, item in ipairs(PAYLOAD) do
        if item.Kind=="bootstrap" then write(target,before,item.Source) end
    end
    for _, item in ipairs(PAYLOAD) do
        local object=item.Kind=="bootstrap" and target or child(created,item.Name)
        assert(blobHash(source(object))==item.Hash,"Verification finale: "..item.Name)
    end
    assert(target.Disabled==beforeDisabled and target.RunContext.Name==beforeContext,"Metadonnees du generateur modifiees")
    backup:SetAttribute("Complete",true)
end,debug.traceback)
if not ok then
    local cancelOK,cancelError=pcall(function() CHS:FinishRecording(record,Enum.FinishRecordingOperation.Cancel) end)
    local restored=pcall(function()
        assert(normalized(source(target))==normalized(before))
        assert(not child(server,"WorldV3",true))
    end)
    if not cancelOK or not restored then
        warn("RESTAURATION A VERIFIER. Ne sauvegarde pas le DEV; recharge ta copie intacte. "..tostring(cancelError))
    end
    error("Installation annulee: "..tostring(err))
end
CHS:FinishRecording(record,Enum.FinishRecordingOperation.Commit)
print("[VALBRUME V3.1 INSTALL] OK — "..#PAYLOAD.." fichiers verifies. Sauvegarde: ServerStorage.ValbrumeInstallBackups."..backupName)
print("Enregistre VALBRUME_DEV, puis lance Play. Attends VALBRUME_WORLD_V3_AUDIT_END dans l'Output serveur.")
