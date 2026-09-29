-- COMMAND BAR / EDIT MODE only. Refuses to overwrite edits made after installation.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),"Arrete Play avant la restauration.")
local SES=game:GetService("ScriptEditorService")
local CHS=game:GetService("ChangeHistoryService")
local function child(parent,name)
    local found
    for _, value in ipairs(parent:GetChildren()) do
        if value.Name==name then assert(not found,"Nom duplique: "..name);found=value end
    end
    assert(found,"Objet absent: "..name)
    return found
end
local function read(object)
    local text=SES:GetEditorSource(object)
    assert(blobHash(text)==blobHash(object.Source),"Brouillon ouvert: "..object.Name)
    return text
end
local server=child(game:GetService("ServerScriptService"),"ValbrumeServer")
local folder=child(server,"WorldV3")
assert(folder:IsA("Folder") and folder:GetAttribute("Release")==VERSION,"Mauvaise version")
assert(#folder:GetChildren()==#INSTALLED-1,"Des fichiers ont ete ajoutes: restauration automatique refusee.")
local target=child(server,"OpenWorldContinentsV28")
for _, item in ipairs(INSTALLED) do
    local object=item.Kind=="bootstrap" and target or child(folder,item.Name)
    assert(object.ClassName==item.Class and blobHash(read(object))==item.Hash,"Code modifie depuis l'installation: "..item.Name)
    assert(not SES:FindScriptDocument(object),"Ferme l'onglet "..object.Name.." puis relance.")
end
local backup=child(child(game:GetService("ServerStorage"),"ValbrumeInstallBackups"),folder:GetAttribute("BackupName"))
assert(backup:GetAttribute("Complete")==true and backup:GetAttribute("Release")==VERSION,"Sauvegarde incomplete")
local original=child(backup,"OriginalSource").Value
assert(blobHash(original)==backup:GetAttribute("OriginalHash"),"Sauvegarde alteree")
local current=read(target)
local record=CHS:TryBeginRecording("ValbrumeWorldV31Restore","Restaurer la geographie precedente")
assert(record,"Historique Studio occupe")
local ok,err=xpcall(function()
    SES:UpdateSourceAsync(target,function(old)
        if blobHash(old)~=blobHash(current) then return nil end
        return original
    end)
    assert(blobHash(read(target))==blobHash(original),"Restauration de la source non confirmee")
    target.Disabled=backup:GetAttribute("OriginalDisabled")
    target.RunContext=Enum.RunContext[backup:GetAttribute("OriginalRunContext")]
    -- Detach, rather than destroy, to leave an undoable operation.
    folder.Parent=nil
    backup:SetAttribute("Restored",true)
end,debug.traceback)
if not ok then
    pcall(function() CHS:FinishRecording(record,Enum.FinishRecordingOperation.Cancel) end)
    error(err)
end
CHS:FinishRecording(record,Enum.FinishRecordingOperation.Commit)
print("[VALBRUME V3.1 ROLLBACK] OK — generateur precedent restaure. Terrain du mode Edit non modifie.")
