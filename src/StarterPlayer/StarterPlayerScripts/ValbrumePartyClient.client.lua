local Players = game:GetService("Players")
local player = Players.LocalPlayer
local remote = game.ReplicatedStorage:WaitForChild("Valbrume"):WaitForChild("PartyRemote")

local gui = Instance.new("ScreenGui")
gui.Name = "ValbrumePartyUI"
gui.ResetOnSpawn = false
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Position = UDim2.fromOffset(14, 140)
frame.Size = UDim2.fromOffset(220, 150)
frame.BackgroundColor3 = Color3.fromRGB(18,24,34)
frame.BackgroundTransparency = 0.08
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0,16)
c.Parent = frame
local s = Instance.new("UIStroke")
s.Color = Color3.fromRGB(87,104,126)
s.Transparency = 0.58
s.Parent = frame

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(12,8)
title.Size = UDim2.new(1,-92,0,26)
title.BackgroundTransparency = 1
title.Text = "EXPÉDITION"
title.TextColor3 = Color3.fromRGB(238,202,117)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame

local leave = Instance.new("TextButton")
leave.Position = UDim2.new(1,-75,0,7)
leave.Size = UDim2.fromOffset(63,28)
leave.Text = "Quitter"
leave.TextColor3 = Color3.fromRGB(241,244,247)
leave.BackgroundColor3 = Color3.fromRGB(83,52,59)
leave.BorderSizePixel = 0
leave.Font = Enum.Font.GothamBold
leave.TextSize = 11
leave.Parent = frame
local lc = Instance.new("UICorner")
lc.CornerRadius = UDim.new(0,12)
lc.Parent = leave

local members = Instance.new("TextLabel")
members.Position = UDim2.fromOffset(12,42)
members.Size = UDim2.new(1,-24,1,-52)
members.BackgroundTransparency = 1
members.TextColor3 = Color3.fromRGB(224,229,235)
members.TextXAlignment = Enum.TextXAlignment.Left
members.TextYAlignment = Enum.TextYAlignment.Top
members.Font = Enum.Font.Gotham
members.TextSize = 12
members.TextWrapped = true
members.Parent = frame

leave.Activated:Connect(function() remote:FireServer("Leave") end)

remote.OnClientEvent:Connect(function(kind,state)
    if kind ~= "State" then return end
    if not state then frame.Visible=false return end
    frame.Visible=true
    local lines = {state.Started and "Donjon en cours" or "Préparation", ""}
    for _,entry in ipairs(state.Members or {}) do
        table.insert(lines,(entry.Leader and "★  " or "•  ") .. entry.Name)
    end
    members.Text = table.concat(lines,"\n")
end)
