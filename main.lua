local http_request = (psm and psm.request) or (syn and syn.request) or (fluxus and fluxus.request) or request or http_request or (http and http.request);
if not http_request then 
	warn("Executor does not support HTTP requests.")
	return; 
end;
local cloneref = cloneref or function(i: Instance) return i; end;
local HTTP = cloneref(game:GetService("HttpService"));
local discord_link = "ckbr3wqcms"
discord_link = discord_link:gsub("https://discord.gg", ""):gsub("discord.gg/", ""):gsub("https://discord.com", "")
for i = 6463, 6472, 1 do
	local s, r = pcall(http_request, {
		Url = "http://127.0.0.1:" .. tostring(i) .. "/rpc?v=1",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["Origin"] = "https://discord.com"
		},
		Body = HTTP:JSONEncode({
			["cmd"] = "INVITE_BROWSER",
			["args"] = {
				["code"] = discord_link
			},
			["nonce"] = HTTP:GenerateGUID(true)
		})
	});
	if s and r and r.StatusCode == 200 then 
		break; 
	end;
end;

local getinfo = getinfo or debug.getinfo
local DEBUG = false
local Hooked = {}

setthreadidentity(2)

for i, v in getgc(true) do
    if typeof(v) == "table" then
        local DetectFunc = rawget(v, "Detected")
        local KillFunc = rawget(v, "Kill")
    
        if typeof(DetectFunc) == "function" and not Detected then
            Detected = DetectFunc
            
            local Old; Old = hookfunction(Detected, function(Action, Info, NoCrash)
                if Action ~= "_" then
                    if DEBUG then
                        warn(`Adonis AntiCheat flagged\nMethod: {Action}\nInfo: {Info}`)
                    end
                end
                
                return true
            end)

            table.insert(Hooked, Detected)
        end

        if rawget(v, "Variables") and rawget(v, "Process") and typeof(KillFunc) == "function" and not Kill then
            Kill = KillFunc
            local Old; Old = hookfunction(Kill, function(Info)
                if DEBUG then
                    warn(`Adonis AntiCheat tried to kill (fallback): {Info}`)
                end
            end)

            table.insert(Hooked, Kill)
        end
    end
end

local Old; Old = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local LevelOrFunc, Info = ...

    if Detected and LevelOrFunc == Detected then
        if DEBUG then
            warn(`zins | adonis bypassed`)
        end

        return coroutine.yield(coroutine.running())
    end
    
    return Old(...)
end))
setthreadidentity(7)

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'SkidWare - noritery',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local MainTab = Window:AddTab('Main')
local CombatTab = Window:AddTab('Combat')
local ModsTab = Window:AddTab('Mods')
local VisualsTab = Window:AddTab('Visuals')
local BuilderTab = Window:AddTab('Builder')
local UISettingsTab = Window:AddTab('UI Settings')
local InfoTab = Window:AddTab('Info')

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local Lighting = game:GetService('Lighting')
local Stats = game:GetService('Stats')
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Vector2_new = Vector2.new
local Vector3_new = Vector3.new
local CFrame_new = CFrame.new
local CFrame_Angles = CFrame.Angles
local Color3_fromRGB = Color3.fromRGB
local math_clamp = math.clamp
local math_floor = math.floor
local math_rad = math.rad
local math_abs = math.abs
local math_max = math.max
local tick = tick

local DrawingRegistry = {}
local ESPCache = {}
local OriginalPartState = {}

Library:SetWatermarkVisibility(true)

local frameCount = 0
local lastFpsTime = tick()
local currentFps = 60

local WatermarkConnection = RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastFpsTime >= 1 then
        currentFps = frameCount
        frameCount = 0
        lastFpsTime = now
        
        local ping = 0
        pcall(function()
            ping = math_floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        Library:SetWatermark(string.format("SkidWare - noritery | %d FPS | %d ms", currentFps, ping))
    end
end)

local sharedRaycastParams = RaycastParams.new()
sharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function RegisterDrawing(drawingObj)
    table.insert(DrawingRegistry, drawingObj)
    return drawingObj
end

local AutoHealSelf = false
local AutoHealNearby = false
local AutoFixArmorSelf = false
local AutoFixArmorNearby = false

local function getChar()
    local char = LocalPlayer.Character
    if not char then
        local ok, result = pcall(function()
            return LocalPlayer.CharacterAdded:Wait()
        end)
        if ok then return result end
    end
    return char
end

local function getTool(toolName)
    local char = getChar()
    if not char then return nil, nil end
    local tool = char:FindFirstChild(toolName) or LocalPlayer.Backpack:FindFirstChild(toolName)
    if tool then
        local ok, action = pcall(function()
            return tool:WaitForChild("ActionMain", 5)
        end)
        if ok then return tool, action end
    end
    return nil, nil
end

local function getNearbyPlayers(range)
    local char = LocalPlayer.Character
    if not char then return {} end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return {} end
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                if (hrp.Position - myRoot.Position).Magnitude <= range then
                    table.insert(list, plr.Character)
                end
            end
        end
    end
    return list
end

task.spawn(function()
    while true do
        task.wait(0.01)
        if AutoHealSelf then
            pcall(function()
                local char = getChar()
                if not char then return end
                local tool, event = getTool("Medkit")
                if tool and event then
                    event:FireServer("heal", char)
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.01)
        if AutoHealNearby then
            pcall(function()
                local tool, event = getTool("Medkit")
                if tool and event then
                    for _, target in ipairs(getNearbyPlayers(50)) do
                        event:FireServer("heal", target)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.01)
        if AutoFixArmorSelf then
            pcall(function()
                local char = getChar()
                if not char then return end
                local tool, event = getTool("Wrench")
                if tool and event then
                    event:FireServer("heal", char)
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.01)
        if AutoFixArmorNearby then
            pcall(function()
                local tool, event = getTool("Wrench")
                if tool and event then
                    for _, target in ipairs(getNearbyPlayers(50)) do
                        event:FireServer("heal", target)
                    end
                end
            end)
        end
    end
end)

local MovementGroup = MainTab:AddLeftGroupbox('Movement & Camera')
local CharacterGroup = MainTab:AddRightGroupbox('Character Modifiers')
local WorldGroup = MainTab:AddRightGroupbox('World & Atmosphere')
local SpawnsGroup = MainTab:AddLeftGroupbox('Spawns')
local Raiding = MainTab:AddRightGroupbox('Raiding')

SpawnsGroup:AddLabel('Mask hides username and shows user id', true)
SpawnsGroup:AddLabel('Reset once after choosing/clearing kit', true)

SpawnsGroup:AddButton({
    Text = 'Hide Player | !s Mask',
    Func = function()
        pcall(function()
            local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
            Event:InvokeServer("!s mask")
        end)
    end
})

SpawnsGroup:AddButton({
    Text = 'Delete Effects From Mask',
    Func = function()
        pcall(function()
            local helmet = workspace:FindFirstChild(LocalPlayer.Name) and workspace[LocalPlayer.Name]:FindFirstChild("Helmet")
            if helmet then
                local omniscence = helmet:FindFirstChild("Omniscence")
                if omniscence then
                    omniscence:Destroy()
                    Library:Notify('Deleted Helmet.Omniscence successfully!', 3)
                    return
                end
            end
            Library:Notify('Helmet.Omniscence not found.', 3)
        end)
    end
})

SpawnsGroup:AddButton({
    Text = 'Kit #1 - RGF',
    Func = function()
        pcall(function()
            local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
            Event:InvokeServer("!sts HK+Ang+J+SLR+NG AK+MOE+SLR+J+NG SR+Coy+SLR+NG SR+Coy+SLR+NG Saiga+SLR+Coy kat JNG+SLR+Pro+Ang+NG med")
            Event:InvokeServer("!sta RGF")
        end)
    end
})

SpawnsGroup:AddButton({
    Text = 'Kit #2 - GRU',
    Func = function()
        pcall(function()
            local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
            Event:InvokeServer("!sts MP7+Heavy+Ergo+Exten+EO+NG M870+Ergo+EO+Muzzle+NG AG-19+EO+Muzzle+NG Med")
            Event:InvokeServer("!sta GRU")
        end)
    end
})

SpawnsGroup:AddButton({
    Text = 'Kit #3 - SAS',
    Func = function()
        pcall(function()
            local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
            Event:InvokeServer("!sts AK-15+NG+Muzzle+Ergo+EO PP+Com+NG+Coyote WA200+Ergo+Muzzle+NG+Acog Desert+Ergo+Muzzle+NG+Coyote")
            Event:InvokeServer("!sta SAS")
        end)
    end
})

SpawnsGroup:AddButton({
    Text = 'Kit #4 - Riot',
    Func = function()
        pcall(function()
            local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
            Event:InvokeServer("!sts m4+sup+red+fold+refle inter+hunt+heavy m9+sup+red ar+hunt lap med def wrench")
            Event:InvokeServer("!sta riot")
        end)
    end
})


SpawnsGroup:AddButton({
    Text = 'Clear Gun Kit',
    Func = function()
        pcall(function()
            local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
            Event:InvokeServer("!sts")
        end)
    end
})

SpawnsGroup:AddButton({
    Text = 'Clear Armour Kit',
    Func = function()
        pcall(function()
            local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
            Event:InvokeServer("!sta")
        end)
    end
})

SpawnsGroup:AddButton({
    Text = 'Drop All Tools',
    Func = function()
        task.spawn(function()
            local interactFunction = ReplicatedStorage:FindFirstChild("InteractFunction") or ReplicatedStorage:WaitForChild("InteractFunction", 2)
            if not interactFunction then
                Library:Notify('InteractFunction not found in ReplicatedStorage!', 3)
                return
            end

            local function dropTool(tool)
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local humanoid = character:FindFirstChildOfClass("Humanoid")

                if tool.Parent ~= character then
                    if humanoid then
                        humanoid:EquipTool(tool)
                    else
                        tool.Parent = character
                    end
                    task.wait(0.1)
                end

                local args = {
                    tool,
                    "CanCollide",
                    false,
                    "par1",
                    vector.create(100, -100, 100)
                }

                interactFunction:InvokeServer(unpack(args))
                task.wait(0.1)
            end

            local character = LocalPlayer.Character
            if character then
                local currentTool = character:FindFirstChildOfClass("Tool")
                if currentTool then
                    dropTool(currentTool)
                end
            end

            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
            if backpack then
                for _, item in ipairs(backpack:GetChildren()) do
                    if item:IsA("Tool") then
                        dropTool(item)
                    end
                end
            end

            Library:Notify('Dropped all tools!', 3)
        end)
    end
})

local ActiveSeatGUIs = {}

local function RemoveSeatGUI(seat)
    if ActiveSeatGUIs[seat] then
        pcall(function() ActiveSeatGUIs[seat]:Destroy() end)
        ActiveSeatGUIs[seat] = nil
    end
end

local function CreateSeatGUI(seat)
    if not seat or not seat:IsA('BasePart') then return end
    if ActiveSeatGUIs[seat] then return end

    local bg = Instance.new('BillboardGui')
    bg.Name = 'SeatTPGui'
    bg.AlwaysOnTop = true
    bg.Adornee = seat
    bg.Size = UDim2.new(0, 30, 0, 30)
    bg.StudsOffset = Vector3.new(0, 2.5, 0)
    bg.Active = true
    bg.Parent = PlayerGui

    local btn = Instance.new('TextButton')
    btn.Name = 'TPButton'
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
    btn.BackgroundTransparency = 0.4
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = 'TP'
    btn.Active = true
    btn.Parent = bg

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild('HumanoidRootPart')
        if hrp then
            hrp.CFrame = seat.CFrame + Vector3.new(0, 3, 0)
            Library:Notify('Teleported to seat!', 2)
        end
    end)

    ActiveSeatGUIs[seat] = bg
end

Raiding:AddToggle('SeatTPEnabled', {
    Text = 'Enable Seat TP',
    Default = false,
    Callback = function(Value)
        if Value then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA('Seat') or obj:IsA('VehicleSeat') then
                    CreateSeatGUI(obj)
                end
            end
            Library:Notify('Seat teleporters enabled across the world.', 3)
        else
            for seat, _ in pairs(ActiveSeatGUIs) do
                RemoveSeatGUI(seat)
            end
            Library:Notify('Seat teleporters disabled.', 3)
        end
    end
})

Raiding:AddDivider()
Raiding:AddLabel('Player Bases & Part Counts', true)

local BaseInfoLabels = {}

local function UpdatePlayerBases()
    local privateAreas = workspace:FindFirstChild("PrivateBuilding Areas") or workspace:FindFirstChild("Private Building Areas")
    if not privateAreas then return end

    for _, child in ipairs(privateAreas:GetChildren()) do
        if child.Name:sub(-9) == "BuildArea" then
            local playerName = child.Name:sub(1, #child.Name - 9)
            local partCount = #child:GetDescendants()

            if not BaseInfoLabels[playerName] then
                BaseInfoLabels[playerName] = Raiding:AddLabel(string.format("%s's Base: %d parts", playerName, partCount), false)
            else
                BaseInfoLabels[playerName]:SetText(string.format("%s's Base: %d parts", playerName, partCount))
            end
        end
    end
end

task.spawn(function()
    while true do
        pcall(UpdatePlayerBases)
        task.wait(2)
    end
end)

workspace.DescendantAdded:Connect(function(obj)
    if Toggles.SeatTPEnabled and Toggles.SeatTPEnabled.Value then
        if obj:IsA('Seat') or obj:IsA('VehicleSeat') then
            CreateSeatGUI(obj)
        end
    end
end)

workspace.DescendantRemoving:Connect(function(obj)
    if obj:IsA('Seat') or obj:IsA('VehicleSeat') then
        RemoveSeatGUI(obj)
    end
end)

MovementGroup:AddToggle('Fly', {
    Text = 'Fly',
    Default = false,
    Callback = function(Value)
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local HRP = Character and Character:WaitForChild('HumanoidRootPart', 2)
        local Humanoid = Character and Character:FindFirstChildOfClass('Humanoid')

        if not HRP or not Humanoid then return end

        if Value then
            Humanoid.PlatformStand = true

            local BG = Instance.new('BodyGyro')
            BG.P = 9e4
            BG.MaxTorque = Vector3_new(9e9, 9e9, 9e9)
            BG.CFrame = HRP.CFrame
            BG.Parent = HRP

            local BV = Instance.new('BodyVelocity')
            BV.Velocity = Vector3_new(0, 0, 0)
            BV.MaxForce = Vector3_new(9e9, 9e9, 9e9)
            BV.Parent = HRP

            _G.FlyObjects = { BG = BG, BV = BV }

            _G.FlyLoop = RunService.Heartbeat:Connect(function()
                local moveDir = Vector3_new(0, 0, 0)
                local SPEED = Options.FlySpeed and Options.FlySpeed.Value or 60

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3_new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3_new(0, 1, 0) end

                BG.CFrame = Camera.CFrame
                BV.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * SPEED or Vector3_new(0, 0, 0)
            end)
        else
            if _G.FlyLoop then _G.FlyLoop:Disconnect() _G.FlyLoop = nil end
            if _G.FlyObjects then
                pcall(function() _G.FlyObjects.BG:Destroy() end)
                pcall(function() _G.FlyObjects.BV:Destroy() end)
                _G.FlyObjects = nil
            end
            if Humanoid then Humanoid.PlatformStand = false end
        end
    end
})
MovementGroup:AddSlider('FlySpeed', { Text = 'Fly Speed', Default = 60, Min = 10, Max = 300, Rounding = 0 })

MovementGroup:AddDivider()

MovementGroup:AddToggle('Speed', {
    Text = 'Speed Hack',
    Default = false,
    Callback = function(Value)
        if Value then
            _G.SpeedLoop = RunService.RenderStepped:Connect(function(deltaTime)
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild('HumanoidRootPart')
                local humanoid = char and char:FindFirstChildOfClass('Humanoid')

                if hrp and humanoid and humanoid.MoveDirection.Magnitude > 0 then
                    local speedMultiplier = (Options.SpeedAmount and Options.SpeedAmount.Value or 50) / 16
                    local targetCFrame = hrp.CFrame + (humanoid.MoveDirection * (humanoid.WalkSpeed * (speedMultiplier - 1) * deltaTime))
                    
                    local tweenInfo = TweenInfo.new(deltaTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCFrame })
                    tween:Play()
                end
            end)
        else
            if _G.SpeedLoop then _G.SpeedLoop:Disconnect() _G.SpeedLoop = nil end
        end
    end
})
MovementGroup:AddSlider('SpeedAmount', { Text = 'Walk Speed', Default = 50, Min = 16, Max = 500, Rounding = 0 })

MovementGroup:AddDivider()

local _G_FreecamConn = nil
local freecamPos = Vector3_new(0, 0, 0)
local freecamRotX, freecamRotY = 0, 0
local lastMousePos = Vector2_new(0, 0)
local isPanning = false

local InputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not (Toggles.Freecam and Toggles.Freecam.Value) then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isPanning = true
        lastMousePos = UserInputService:GetMouseLocation()
    end
end)

local InputEndedConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isPanning = false
    end
end)

MovementGroup:AddToggle('Freecam', {
    Text = 'Freecam',
    Default = false,
    Callback = function(Value)
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild('HumanoidRootPart')
        local humanoid = character and character:FindFirstChildOfClass('Humanoid')

        if Value then
            freecamPos = Camera.CFrame.Position
            local rx, ry, _ = Camera.CFrame:ToOrientation()
            freecamRotX = rx
            freecamRotY = ry

            Camera.CameraType = Enum.CameraType.Scriptable
            if hrp then hrp.Anchored = true end
            if humanoid then humanoid.PlatformStand = true end

            _G_FreecamConn = RunService.RenderStepped:Connect(function(dt)
                if isPanning then
                    local currentMousePos = UserInputService:GetMouseLocation()
                    local mouseDelta = currentMousePos - lastMousePos
                    lastMousePos = currentMousePos

                    freecamRotY = freecamRotY - (mouseDelta.X * 0.003)
                    freecamRotX = math_clamp(freecamRotX - (mouseDelta.Y * 0.003), -math.pi / 2, math.pi / 2)
                end

                local camCFrame = CFrame_new(freecamPos) * CFrame_Angles(0, freecamRotY, 0) * CFrame_Angles(freecamRotX, 0, 0)
                local moveDir = Vector3_new(0, 0, 0)
                local speed = Options.FreecamSpeed and Options.FreecamSpeed.Value or 50

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3_new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3_new(0, 1, 0) end

                freecamPos = freecamPos + (moveDir * speed * dt)
                Camera.CFrame = CFrame_new(freecamPos) * CFrame_Angles(0, freecamRotY, 0) * CFrame_Angles(freecamRotX, 0, 0)
            end)
        else
            if _G_FreecamConn then _G_FreecamConn:Disconnect() _G_FreecamConn = nil end
            isPanning = false
            Camera.CameraType = Enum.CameraType.Custom

            if hrp then hrp.Anchored = false end
            if humanoid then humanoid.PlatformStand = false end
        end
    end
})
MovementGroup:AddSlider('FreecamSpeed', { Text = 'Freecam Speed', Default = 50, Min = 10, Max = 200, Rounding = 0 })

MovementGroup:AddDivider()

MovementGroup:AddToggle('Spinbot', {
    Text = 'Spinbot',
    Default = false,
    Callback = function(Value)
        if Value then
            _G.SpinbotLoop = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild('HumanoidRootPart')
                local humanoid = char and char:FindFirstChildOfClass('Humanoid')
                
                if hrp and humanoid then
                    humanoid.AutoRotate = false
                    local head = char:FindFirstChild('Head')
                    local isAiming = (Options.AimbotKeybind and Options.AimbotKeybind:GetState()) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                    local isFirstPerson = head and (Camera.CFrame.Position - head.Position).Magnitude < 1.5

                    if not (isAiming and isFirstPerson) then
                        local speed = Options.SpinSpeed and Options.SpinSpeed.Value or 50
                        local currentAngles = hrp.CFrame - hrp.CFrame.Position
                        local spinAngle = CFrame_Angles(0, math_rad(speed), 0)
                        
                        hrp.CFrame = CFrame_new(hrp.CFrame.Position) * currentAngles * spinAngle
                    end
                end
            end)
        else
            if _G.SpinbotLoop then _G.SpinbotLoop:Disconnect() _G.SpinbotLoop = nil end
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass('Humanoid')
            if humanoid then humanoid.AutoRotate = true end
        end
    end
})
MovementGroup:AddSlider('SpinSpeed', { Text = 'Spin Speed', Default = 50, Min = 10, Max = 200, Rounding = 0 })

CharacterGroup:AddToggle('HideFirstPersonBody', {
    Text = 'Hide Body in First Person',
    Default = false,
    Callback = function(Value)
        if not Value then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA('BasePart') and part.Name ~= 'HumanoidRootPart' then
                        part.LocalTransparencyModifier = 0
                    end
                end
            end
        end
    end
})

CharacterGroup:AddToggle('HideFirstPersonArms', {
    Text = 'Also Hide Hands/Arms',
    Default = false
})

CharacterGroup:AddToggle('HideFirstPersonTool', {
    Text = 'Also Hide Equipped Tool',
    Default = false
})

local CachedLocalParts = {}
local function CacheLocalCharacterParts(char)
    table.clear(CachedLocalParts)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA('BasePart') and part.Name ~= 'HumanoidRootPart' then
            table.insert(CachedLocalParts, part)
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    CacheLocalCharacterParts(char)
end)
if LocalPlayer.Character then CacheLocalCharacterParts(LocalPlayer.Character) end

local FirstPersonBodyLoop = RunService.RenderStepped:Connect(function()
    if not (Toggles.HideFirstPersonBody and Toggles.HideFirstPersonBody.Value) then return end
    local char = LocalPlayer.Character
    if not char then return end
    
    local head = char:FindFirstChild('Head')
    if not head then return end

    local isFirstPerson = (Camera.CFrame.Position - head.Position).Magnitude < 1.5
    local hideArms = Toggles.HideFirstPersonArms and Toggles.HideFirstPersonArms.Value
    local hideTool = Toggles.HideFirstPersonTool and Toggles.HideFirstPersonTool.Value

    for i = 1, #CachedLocalParts do
        local part = CachedLocalParts[i]
        if part and part.Parent then
            local nameLower = part.Name:lower()
            local isArm = nameLower:find('arm') or nameLower:find('hand')
            local isToolPart = part.Parent:IsA('Tool') or part:FindFirstAncestorOfClass('Tool') ~= nil
            local isHair = nameLower:find('hair') or (part.Parent and part.Parent:IsA('Accessory') and part.Parent.AccessoryType == Enum.AccessoryType.Hair)

            local shouldHide = false
            if isFirstPerson then
                if isHair then
                    shouldHide = true
                elseif isToolPart then
                    shouldHide = hideTool
                elseif isArm then
                    shouldHide = hideArms
                else
                    shouldHide = true
                end
            end

            part.LocalTransparencyModifier = shouldHide and 1 or 0
        end
    end
end)

local DisabledLightingEffects = {}

WorldGroup:AddToggle('Fullbright', {
    Text = 'Fullbright',
    Default = false,
    Callback = function(Value)
        if Value then
            _G.OldBrightness = Lighting.Brightness
            _G.OldClockTime = Lighting.ClockTime
            _G.OldGlobalShadows = Lighting.GlobalShadows
            _G.OldAmbient = Lighting.Ambient
            _G.OldOutdoorAmbient = Lighting.OutdoorAmbient
            _G.OldFogEnd = Lighting.FogEnd

            for _, effect in ipairs(Lighting:GetChildren()) do
                if (effect:IsA('PostEffect') or effect:IsA('Atmosphere')) and effect.Enabled then
                    table.insert(DisabledLightingEffects, effect)
                    effect.Enabled = false
                end
            end

            _G.FullbrightLoop = RunService.RenderStepped:Connect(function()
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3_fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3_fromRGB(255, 255, 255)
                Lighting.FogEnd = 100000
            end)
        else
            if _G.FullbrightLoop then _G.FullbrightLoop:Disconnect() _G.FullbrightLoop = nil end

            for _, effect in ipairs(DisabledLightingEffects) do
                if effect and effect.Parent then effect.Enabled = true end
            end
            table.clear(DisabledLightingEffects)

            if _G.OldBrightness then
                Lighting.Brightness = _G.OldBrightness
                Lighting.ClockTime = _G.OldClockTime
                Lighting.GlobalShadows = _G.OldGlobalShadows
                Lighting.Ambient = _G.OldAmbient
                Lighting.OutdoorAmbient = _G.OldOutdoorAmbient
                Lighting.FogEnd = _G.OldFogEnd
            end
        end
    end
})

WorldGroup:AddSlider('TimeOfDay', {
    Text = 'Time of Day',
    Default = 12,
    Min = 0,
    Max = 24,
    Rounding = 1,
    Callback = function(Value)
        if not (Toggles.FreezeTime and Toggles.FreezeTime.Value) and not (Toggles.Fullbright and Toggles.Fullbright.Value) then
            Lighting.ClockTime = Value
        end
    end
})

WorldGroup:AddToggle('FreezeTime', {
    Text = 'Freeze Time',
    Default = false,
    Callback = function(Value)
        if Value then
            _G.FreezeTimeLoop = RunService.RenderStepped:Connect(function()
                if not (Toggles.Fullbright and Toggles.Fullbright.Value) then
                    Lighting.ClockTime = Options.TimeOfDay and Options.TimeOfDay.Value or 12
                end
            end)
        else
            if _G.FreezeTimeLoop then _G.FreezeTimeLoop:Disconnect() _G.FreezeTimeLoop = nil end
        end
    end
})

local SkyboxData = {
    ['Default'] = { Type = 'Default' },
    ['Purple Nebula'] = {
        Type = 'Procedural', Density = 2.0, Offset = -0.5,
        Color = Color3.fromRGB(45, 10, 70), Decay = Color3.fromRGB(10, 2, 20),
        Glare = 150, Haze = 100
    },
    ['Vaporwave'] = {
        Type = 'Procedural', Density = 0.4, Offset = 0.5,
        Color = Color3.fromRGB(255, 105, 180), Decay = Color3.fromRGB(75, 0, 130),
        Glare = 100, Haze = 25
    },
    ['Space'] = {
        Type = 'Procedural', Density = 0.6, Offset = -0.5,
        Color = Color3.fromRGB(10, 10, 30), Decay = Color3.fromRGB(5, 5, 15),
        Glare = 0, Haze = 0
    }
}

local function ApplySkyboxPreset(presetName)
    local data = SkyboxData[presetName]
    if not data then return end

    if data.Type == 'Default' then
        local atm = Lighting:FindFirstChildOfClass('Atmosphere')
        if atm and atm:FindFirstChild('IsCustomAtmosphere') then atm:Destroy() end
    elseif data.Type == 'Procedural' then
        local atm = Lighting:FindFirstChildOfClass('Atmosphere')
        if not atm then
            atm = Instance.new('Atmosphere')
            atm.Name = 'CustomAtmosphere'
            atm.Parent = Lighting
        end

        local marker = atm:FindFirstChild('IsCustomAtmosphere') or Instance.new('BoolValue')
        marker.Name = 'IsCustomAtmosphere'
        marker.Parent = atm

        atm.Density = data.Density
        atm.Offset = data.Offset
        atm.Color = data.Color
        atm.Decay = data.Decay
        atm.Glare = data.Glare
        atm.Haze = data.Haze
        
        Lighting.Ambient = data.Color
        Lighting.OutdoorAmbient = data.Decay
    end
end

WorldGroup:AddDropdown('SkyboxPreset', {
    Values = { 'Default', 'Purple Nebula', 'Vaporwave', 'Space' },
    Default = 1,
    Multi = false,
    Text = 'Skybox Preset',
    Callback = function(Value)
        ApplySkyboxPreset(Value)
    end
})

WorldGroup:AddDivider()

WorldGroup:AddButton({
    Text = 'Load Anti-AFK Script',
    Func = function()
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/imisury/antiafk/refs/heads/main/antiafk"))()
        end)
        if success then Library:Notify('Anti-AFK Loaded Successfully!', 5)
        else Library:Notify('Failed to load Anti-AFK: ' .. tostring(err), 5) end
    end
})

local AimbotGroup = CombatTab:AddLeftGroupbox('Aimbot Settings')
local AimFilterGroup = CombatTab:AddLeftGroupbox('Target Filtering')
local TriggerGroup = CombatTab:AddRightGroupbox('Triggerbot Settings')
local FOVGroup = CombatTab:AddRightGroupbox('FOV Visuals')
local MedkitGroup = CombatTab:AddRightGroupbox('Auto-Heal Controls')
local WrenchGroup = CombatTab:AddRightGroupbox('Auto-Fix Armor Controls')

MedkitGroup:AddLabel('You MUST have Medkit selected in hotbar!', true)
MedkitGroup:AddToggle('AutoHealSelfToggle', {
    Text = 'Auto-Heal Self',
    Default = false,
    Callback = function(v) AutoHealSelf = v end
})
MedkitGroup:AddToggle('AutoHealNearbyToggle', {
    Text = 'Auto-Heal Nearby Players',
    Default = false,
    Callback = function(v) AutoHealNearby = v end
})

MedkitGroup:AddButton({
    Text = 'Spawn Medkit',
    Func = function()
        pcall(function()
            local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
            Event:InvokeServer("!s medkit")
        end)
    end
})

WrenchGroup:AddLabel('You MUST have Wrench selected in hotbar!', true)
WrenchGroup:AddToggle('AutoFixArmorSelfToggle', {
    Text = 'Auto-Fix Armor Self',
    Default = false,
    Callback = function(v) AutoFixArmorSelf = v end
})
WrenchGroup:AddToggle('AutoFixArmorNearbyToggle', {
    Text = 'Auto-Fix Armor Nearby Players',
    Default = false,
    Callback = function(v) AutoFixArmorNearby = v end
})

WrenchGroup:AddButton({
    Text = 'Spawn Wrench',
    Func = function()
        pcall(function()
            local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
            Event:InvokeServer("!s wrench")
        end)
    end
})

local AimToggle = AimbotGroup:AddToggle('AimbotEnabled', { Text = 'Enable Aimbot', Default = false })
AimToggle:AddKeyPicker('AimbotKeybind', { Default = 'MB2', Mode = 'Hold', Text = 'Aimbot Key' })

AimbotGroup:AddDropdown('AimbotTargetPart', { Values = { 'Head', 'HumanoidRootPart', 'Torso', 'Closest To Cursor', 'Multi-Hitbox' }, Default = 1, Multi = false, Text = 'Target Part' })
AimbotGroup:AddSlider('AimbotSmoothness', { Text = 'Smoothing', Default = 5, Min = 1, Max = 20, Rounding = 1 })
AimbotGroup:AddToggle('AimbotStickyTarget', { Text = 'Sticky Target Lock', Default = true })

local SilentAimGroup = CombatTab:AddLeftGroupbox('Silent Aim Settings')
SilentAimGroup:AddToggle('SilentAimEnabled', { Text = 'Enable Silent Aim', Default = false })
SilentAimGroup:AddDropdown('SilentAimTargetMode', { Values = { 'Closest Head', 'Closest Torso', 'Closest HRP' }, Default = 1, Multi = false, Text = 'Silent Target Part' })

AimFilterGroup:AddToggle('AimbotEnableBots', { Text = 'Target Bots', Default = false })
AimFilterGroup:AddToggle('AimbotWallCheck', { Text = 'Wall Check', Default = true })
AimFilterGroup:AddToggle('AimbotPassiveCheck', { Text = 'Ignore Passive / ForceField', Default = false })

-- tracers

local BulletTracerGroup = CombatTab:AddRightGroupbox('Bullet Tracers')

local BulletTracerToggle = BulletTracerGroup:AddToggle('BulletTracer_Enabled', {
    Text = 'Enable Bullet Tracers',
    Default = false
})

BulletTracerGroup:AddLabel('Tracer Color'):AddColorPicker('BulletTracer_Color', {
    Default = Color3.fromRGB(255, 0, 255),
    Title = 'Bullet Tracer Color'
})

BulletTracerGroup:AddSlider('BulletTracer_Thickness', {
    Text = 'Thickness',
    Default = 0.2,
    Min = 0.05,
    Max = 1,
    Rounding = 2
})

BulletTracerGroup:AddSlider('BulletTracer_Transparency', {
    Text = 'Transparency',
    Default = 0.9,
    Min = 0,
    Max = 1,
    Rounding = 2
})

BulletTracerGroup:AddSlider('BulletTracer_Lifetime', {
    Text = 'Lifetime (Seconds)',
    Default = 3,
    Min = 0.1,
    Max = 10,
    Rounding = 1
})

local function spawnBulletTracer(from, hit)
    if not BulletTracerToggle.Value then return end

    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Color = Options.BulletTracer_Color.Value
    part.Transparency = Options.BulletTracer_Transparency.Value
    part.Material = Enum.Material.Neon

    local distance = (hit - from).Magnitude
    local midpoint = (from + hit) / 2

    local thickness = Options.BulletTracer_Thickness.Value
    part.Size = Vector3.new(thickness, distance, thickness)
    part.CFrame = CFrame.new(midpoint, hit) * CFrame.Angles(math.rad(90), 0, 0)
    part.Parent = workspace

    task.delay(Options.BulletTracer_Lifetime.Value, function()
        pcall(function()
            part:Destroy()
        end)
    end)
end

local meta = getrawmetatable(game)
local oldNamecall = meta.__namecall
setreadonly(meta, false)

meta.__namecall = newcclosure(function(self, ...)
    if self.Name == "FireEvent" then
        local args = {...}
        pcall(function()
            local shot = args[1][1][1]
            local hit = shot[2]
            local from = shot[5]
            if hit and from then
                task.spawn(spawnBulletTracer, from, hit)
            end
        end)
    end
    return oldNamecall(self, ...)
end)

setreadonly(meta, true)

local TrigToggle = TriggerGroup:AddToggle('TriggerbotEnabled', { Text = 'Enable Triggerbot', Default = false })
TrigToggle:AddKeyPicker('TriggerKeybind', { Default = 'MB2', Mode = 'Hold', Text = 'Trigger Key' })
TriggerGroup:AddSlider('TriggerbotDelay', { Text = 'Click Delay (s)', Default = 0.05, Min = 0, Max = 0.5, Rounding = 2 })

local FOVToggle = FOVGroup:AddToggle('DrawFOV', { Text = 'Draw FOV Circle', Default = false })
FOVToggle:AddColorPicker('FOVColor', { Default = Color3.fromRGB(255, 255, 255) })
FOVGroup:AddSlider('AimbotFOV', { Text = 'FOV Radius', Default = 150, Min = 30, Max = 500, Rounding = 0 })

local FOVCircle = RegisterDrawing(Drawing.new('Circle'))
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Filled = false
FOVCircle.Visible = false

local function getClosestTargetPartForSilent()
    local closestPart = nil
    local shortestDistance = math.huge
    local targetMode = Options.SilentAimTargetMode and Options.SilentAimTargetMode.Value or 'Closest Head'
    local targetPartName = "Head"
    if targetMode == 'Closest Torso' then targetPartName = "Torso"
    elseif targetMode == 'Closest HRP' then targetPartName = "HumanoidRootPart" end

    local maxRadius = Options.AimbotFOV and Options.AimbotFOV.Value or 150
    local centerScreen = Vector2_new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local targetPart = player.Character:FindFirstChild(targetPartName) or player.Character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distToScreen = (Vector2_new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                    if distToScreen <= maxRadius then
                        local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPart = targetPart
                        end
                    end
                end
            end
        end
    end

    return closestPart and closestPart.CFrame or nil
end

local function setupTool(tool)
    if not tool:IsA("Tool") then return end

    tool.Equipped:Connect(function()
        local settingsModule = tool:FindFirstChild('Settings')
        if settingsModule and settingsModule:IsA('ModuleScript') then
            pcall(function()
                local mod = require(settingsModule)
                if type(mod) == 'table' then
                    if Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value then
                        mod.accMult = 0
                    end
                end
            end)
        end

        if not (Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value) then return end
        
        local success, connections = pcall(function()
            return getconnections(tool.Equipped)
        end)
        
        if success and connections then
            for _, conn in ipairs(connections) do
                if conn.Function then
                    local old
                    old = hookfunction(conn.Function, function(mouse)
                        if not (Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value) then
                            return old(mouse)
                        end

                        local new = setmetatable({}, {
                            __index = function(a, b)
                                if b == "Hit" then
                                    local targetCFrame = getClosestTargetPartForSilent()
                                    if targetCFrame then
                                        return targetCFrame
                                    end
                                    return CFrame.new(0, 0, 0)
                                end
                                return mouse[b]
                            end,
                            __newindex = function(a, b, c)
                                mouse[b] = c
                            end
                        })
                        return old(new)
                    end)
                end
            end
        end
    end)
end

local function scanInventory()
    if LocalPlayer.Backpack then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            setupTool(item)
        end
    end
    if LocalPlayer.Character then
        for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
            setupTool(item)
        end
    end
end

scanInventory()

if LocalPlayer.Backpack then
    LocalPlayer.Backpack.ChildAdded:Connect(function(item)
        task.wait(0.1)
        setupTool(item)
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(item)
        task.wait(0.1)
        setupTool(item)
    end)
    task.wait(0.5)
    scanInventory()
end)

local LockedTargetPart = nil
local CurrentTargetPlayer = nil

local function IsValidTarget(part, character)
    if not part or not part.Parent or not character then return false end
    local humanoid = character:FindFirstChildOfClass('Humanoid')
    local player = Players:GetPlayerFromCharacter(character)

    if not humanoid or humanoid.Health <= 0 then return false end
    if player == LocalPlayer then return false end

    if Toggles.AimbotPassiveCheck and Toggles.AimbotPassiveCheck.Value then
        if character:FindFirstChildOfClass('ForceField') then return false end
    end

    if Toggles.AimbotWallCheck and Toggles.AimbotWallCheck.Value then
        local ignoreList = { Camera }
        if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
        sharedRaycastParams.FilterDescendantsInstances = ignoreList

        local rayOrigin = Camera.CFrame.Position
        local rayDirection = (part.Position - rayOrigin)
        local raycastResult = workspace:Raycast(rayOrigin, rayDirection, sharedRaycastParams)

        if raycastResult and raycastResult.Instance then
            local hitPart = raycastResult.Instance
            if hitPart.CanCollide then
                if not hitPart:IsDescendantOf(character) then
                    return false
                end
            end
        end
    end

    return true
end

local function GetBestTargetPart(character)
    if not character then return nil end
    local selected = Options.AimbotTargetPart and Options.AimbotTargetPart.Value or 'Head'
    
    if selected == 'Multi-Hitbox' then
        local parts = { 'Head', 'Torso', 'HumanoidRootPart' }
        for _, pName in ipairs(parts) do
            local part = character:FindFirstChild(pName)
            if part and IsValidTarget(part, character) then
                return part
            end
        end
        return character:FindFirstChild('Head')
    elseif selected == 'Closest To Cursor' then
        local centerScreen = Vector2_new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local bestPart = nil
        local minDist = math.huge
        for _, pName in ipairs({ 'Head', 'Torso', 'HumanoidRootPart', 'LeftUpperArm', 'RightUpperArm' }) do
            local part = character:FindFirstChild(pName)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2_new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                    if dist < minDist then
                        minDist = dist
                        bestPart = part
                    end
                end
            end
        end
        return bestPart or character:FindFirstChild('Head')
    else
        return character:FindFirstChild(selected) or character:FindFirstChild('Head')
    end
end

local function GetClosestTarget()
    if Toggles.AimbotStickyTarget and Toggles.AimbotStickyTarget.Value and CurrentTargetPlayer and CurrentTargetPlayer.Character then
        local targetPart = GetBestTargetPart(CurrentTargetPlayer.Character)
        if targetPart and IsValidTarget(targetPart, CurrentTargetPlayer.Character) then
            return targetPart, CurrentTargetPlayer
        else
            CurrentTargetPlayer = nil
        end
    end

    local closestPart = nil
    local closestPlayer = nil
    local maxRadius = Options.AimbotFOV and Options.AimbotFOV.Value or 150
    local centerScreen = Vector2_new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = GetBestTargetPart(player.Character)
            if targetPart and IsValidTarget(targetPart, player.Character) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2_new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                    if dist <= maxRadius then
                        maxRadius = dist
                        closestPart = targetPart
                        closestPlayer = player
                    end
                end
            end
        end
    end

    if Toggles.AimbotEnableBots and Toggles.AimbotEnableBots.Value then
        local botStorage = workspace:FindFirstChild('BotStorage')
        if botStorage then
            for _, botModel in ipairs(botStorage:GetChildren()) do
                if botModel:IsA('Model') then
                    local targetPart = GetBestTargetPart(botModel)
                    if targetPart and IsValidTarget(targetPart, botModel) then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local dist = (Vector2_new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                            if dist <= maxRadius then
                                maxRadius = dist
                                closestPart = targetPart
                                closestPlayer = nil
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPart, closestPlayer
end

local lastTriggerClick = 0

local CombatConnection = RunService.RenderStepped:Connect(function(deltaTime)
    local centerScreen = Vector2_new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if Toggles.DrawFOV and Toggles.DrawFOV.Value then
        FOVCircle.Position = centerScreen
        FOVCircle.Radius = Options.AimbotFOV and Options.AimbotFOV.Value or 150
        FOVCircle.Color = Options.FOVColor and Options.FOVColor.Value or Color3_fromRGB(255, 255, 255)
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    local isKeyDown = Options.AimbotKeybind and Options.AimbotKeybind:GetState()
    if Toggles.AimbotEnabled and Toggles.AimbotEnabled.Value and isKeyDown then
        LockedTargetPart, CurrentTargetPlayer = GetClosestTarget()

        if LockedTargetPart then
            local targetPos = LockedTargetPart.Position
            local targetCFrame = CFrame_new(Camera.CFrame.Position, targetPos)

            local smoothValue = Options.AimbotSmoothness and Options.AimbotSmoothness.Value or 5
            local alpha = math_clamp(1 / math_max(smoothValue, 1), 0, 1)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
        end
    else
        LockedTargetPart = nil
        CurrentTargetPlayer = nil
    end

    if Toggles.TriggerbotEnabled and Toggles.TriggerbotEnabled.Value and Options.TriggerKeybind and Options.TriggerKeybind.GetState and Options.TriggerKeybind:GetState() then
        local delayVal = Options.TriggerbotDelay and Options.TriggerbotDelay.Value or 0.05
        if (tick() - lastTriggerClick >= delayVal) then
            local unitRay = Camera:ViewportPointToRay(centerScreen.X, centerScreen.Y)
            local ignoreList = { Camera }
            if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
            sharedRaycastParams.FilterDescendantsInstances = ignoreList

            local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, sharedRaycastParams)
            if result and result.Instance then
                local hitCharacter = result.Instance:FindFirstAncestorOfClass('Model')
                if hitCharacter then
                    local player = Players:GetPlayerFromCharacter(hitCharacter)
                    local humanoid = hitCharacter:FindFirstChildOfClass('Humanoid')
                    local isBotModel = (Toggles.AimbotEnableBots and Toggles.AimbotEnableBots.Value) and workspace:FindFirstChild('BotStorage') and hitCharacter:IsDescendantOf(workspace.BotStorage)

                    local hasFF = hitCharacter:FindFirstChildOfClass('ForceField') ~= nil
                    local ignorePassiveActive = Toggles.AimbotPassiveCheck and Toggles.AimbotPassiveCheck.Value

                    if (player and player ~= LocalPlayer or isBotModel) and humanoid and humanoid.Health > 0 and not (ignorePassiveActive and hasFF) then
                        lastTriggerClick = tick()
                        pcall(function()
                            if mouse1click then mouse1click() end
                        end)
                    end
                end
            end
        end
    end
end)

local WeaponGroup = ModsTab:AddLeftGroupbox('Equipped Weapon Modifications')
local SoundModGroup = ModsTab:AddRightGroupbox('Gun Sound Modder')
local SniperGroup = ModsTab:AddRightGroupbox('Sway Mods')

local originalSettingsCache = {}

local function GetOriginalSettings(tool)
    if originalSettingsCache[tool] then
        return originalSettingsCache[tool]
    end
    
    local settingsModule = tool:FindFirstChild('Settings')
    if settingsModule and settingsModule:IsA('ModuleScript') then
        local success, settingsTable = pcall(require, settingsModule)
        if success and type(settingsTable) == 'table' then
            local copy = {}
            for k, v in pairs(settingsTable) do
                copy[k] = v
            end
            originalSettingsCache[tool] = copy
            return copy
        end
    end
    return {}
end

local function ApplyWeaponMod()
    local character = LocalPlayer.Character
    if not character then error("Character not found") end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then error("You need to hold a tool") end

    local settingsModule = tool:FindFirstChild('Settings')
    if not settingsModule or not settingsModule:IsA('ModuleScript') then error("Tool has no Settings module") end

    local success, mod = pcall(require, settingsModule)
    if not success or type(mod) ~= 'table' then error("Failed to require Settings module") end

    local old = GetOriginalSettings(tool)

    local cfg = {
        ReloadSpeed = Options.ModReloadSpeed and Options.ModReloadSpeed.Value or mod.ReloadSpeed,
        ReloadSpeed2 = Options.ModReloadSpeed and Options.ModReloadSpeed.Value or mod.ReloadSpeed2,
        waittime = Options.ModFireRate and Options.ModFireRate.Value or mod.waittime,
        GunRecoil = Options.ModRecoil and Options.ModRecoil.Value or mod.GunRecoil,
        GunRecoilX = Options.ModRecoilX and Options.ModRecoilX.Value or mod.GunRecoilX,
        AimSpeed = Options.ModAimSpeed and Options.ModAimSpeed.Value or mod.AimSpeed,
        cooldown = Options.ModCooldown and Options.ModCooldown.Value or mod.cooldown,
        guardTime = Options.ModGuardTime and Options.ModGuardTime.Value or mod.guardTime,
        BoltAction = Toggles.ModBoltAction and not Toggles.ModBoltAction.Value or mod.BoltAction,
        auto = Toggles.MakeGunAutoAction and Toggles.MakeGunAutoAction.Value or mod.auto,
        scatter = (Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value) and nil or mod.scatter,
        AimScatterMultiplyer = nil,
        accMult = (Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value) and 0 or mod.accMult,
    }

    for index, v in pairs(cfg) do
        if v ~= old[index] then
            mod[index] = v
        end
    end

    Library:Notify('Applied modifications to equipped weapon!', 3)
end

WeaponGroup:AddButton({
    Text = 'Apply Weapon Mods',
    Func = function()
        xpcall(ApplyWeaponMod, function(err)
            Library:Notify('Error: ' .. tostring(err), 3)
        end)
    end
})

WeaponGroup:AddDivider()

WeaponGroup:AddToggle('ModBoltAction', {
    Text = 'Disable Bolt Action',
    Default = false
})

WeaponGroup:AddToggle('MakeGunAutoAction', {
    Text = 'MakeGunAuto',
    Default = false
})

WeaponGroup:AddDivider()

WeaponGroup:AddSlider('ModReloadSpeed', { Text = 'Reload Speed (s)', Default = 0.5, Min = 0.05, Max = 3.0, Rounding = 2 })
WeaponGroup:AddSlider('ModFireRate', { Text = 'Fire Delay / Wait Time (s)', Default = 0.04, Min = 0.01, Max = 0.20, Rounding = 3 })
WeaponGroup:AddSlider('ModRecoil', { Text = 'Gun Recoil (Vertical)', Default = 0.3, Min = 0, Max = 2.0, Rounding = 2 })
WeaponGroup:AddSlider('ModRecoilX', { Text = 'Gun Recoil X (Horizontal)', Default = 0.3, Min = 0, Max = 2.0, Rounding = 2 })
WeaponGroup:AddSlider('ModAimSpeed', { Text = 'Aim Speed (ADS Duration)', Default = 0.25, Min = 0.01, Max = 1.0, Rounding = 2 })

WeaponGroup:AddDivider()

WeaponGroup:AddSlider('ModCooldown', { Text = 'Attack Cooldown (s)', Default = 0.54, Min = 0.01, Max = 3.0, Rounding = 2 })
WeaponGroup:AddSlider('ModGuardTime', { Text = 'Guard Time (s)', Default = 1.5, Min = 0.1, Max = 5.0, Rounding = 2 })
WeaponGroup:AddSlider('ModRange', { Text = 'Range Multiplier', Default = 1.0, Min = 0.5, Max = 5.0, Rounding = 1 })

SoundModGroup:AddInput('SoundIdInput', {
    Default = 'rbxassetid://0',
    Numeric = false,
    Finished = false,
    Text = 'New Sound ID Input',
    Placeholder = 'rbxassetid://...'
})

local function UpdateToolSounds()
    local inputVal = Options.SoundIdInput and Options.SoundIdInput.Value
    if not inputVal or inputVal == '' or inputVal == 'rbxassetid://0' then return end

    local formattedInput = inputVal
    if not string.match(inputVal, "rbxassetid://") then
        local numericId = string.match(inputVal, "%d+")
        if numericId then formattedInput = "rbxassetid://" .. numericId end
    end

    local character = LocalPlayer.Character
    if not character then return end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA('Tool') then
            for _, obj in ipairs(child:GetDescendants()) do
                if obj:IsA('Sound') and obj.SoundId ~= formattedInput then
                    obj.SoundId = formattedInput
                end
            end
        end
    end
end

local ToolSoundConnection = nil
SoundModGroup:AddToggle('AutoUpdateSounds', {
    Text = 'Auto-Update Equipped Sound Loop',
    Default = false,
    Callback = function(Value)
        if Value then
            UpdateToolSounds()
            if LocalPlayer.Character and not ToolSoundConnection then
                ToolSoundConnection = LocalPlayer.Character.ChildAdded:Connect(function(child)
                    if child:IsA("Tool") then
                        task.wait(0.1)
                        UpdateToolSounds()
                    end
                end)
            end
            Library:Notify('Sound auto-updater activated!', 3)
        else
            if ToolSoundConnection then ToolSoundConnection:Disconnect() ToolSoundConnection = nil end
            Library:Notify('Sound auto-updater deactivated.', 3)
        end
    end
})

SoundModGroup:AddButton({
    Text = 'Apply Once to Tool Sounds',
    Func = function()
        UpdateToolSounds()
        Library:Notify('Updated sounds in current tool!', 3)
    end
})

local LaptopMainGroup = ModsTab:AddLeftGroupbox('Laptop Modifications')
local LaptopVisualsGroup = ModsTab:AddRightGroupbox('Laptop Effects')
local function ApplyLaptopMod()
    local character = LocalPlayer.Character
    if not character then error("Character not found") end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool or not tool:FindFirstChild('Settings') then
        tool = character:FindFirstChild("Laptop") or LocalPlayer.Backpack:FindFirstChild("Laptop")
    end

    if not tool then error("You need to hold or own the Laptop tool") end

    local settingsModule = tool:FindFirstChild('Settings')
    if not settingsModule or not settingsModule:IsA('ModuleScript') then error("Tool has no Settings module") end

    local success, mod = pcall(require, settingsModule)
    if not success or type(mod) ~= 'table' then error("Failed to require Settings module") end

    local old = GetOriginalSettings(tool)

    local cfg = {
        -- Duration
        droneCloakDuration = Options.LaptopCloakDuration and Options.LaptopCloakDuration.Value or mod.droneCloakDuration,

        -- Cooldowns
        droneCloakCooldown = Options.LaptopCloakCooldown and Options.LaptopCloakCooldown.Value or mod.droneCloakCooldown,
        droneDefibCooldown = Options.LaptopDefibCooldown and Options.LaptopDefibCooldown.Value or mod.droneDefibCooldown,
        droneGunRecharge = Options.LaptopGunRecharge and Options.LaptopGunRecharge.Value or mod.droneGunRecharge,

        -- Distance & Range
        droneCraneDistance = Options.LaptopCraneDistance and Options.LaptopCraneDistance.Value or mod.droneCraneDistance,
        droneGunRange = Options.LaptopGunRange and Options.LaptopGunRange.Value or mod.droneGunRange,
        droneDefibRange = Options.LaptopDefibRange and Options.LaptopDefibRange.Value or mod.droneDefibRange,

        -- Burst & Spread
        droneGunBurst = Options.LaptopGunBurst and Options.LaptopGunBurst.Value or mod.droneGunBurst,
        droneGunBurstTime = Options.LaptopGunBurstTime and Options.LaptopGunBurstTime.Value or mod.droneGunBurstTime,
        droneGunSpread = Options.LaptopGunSpread and Options.LaptopGunSpread.Value or mod.droneGunSpread,

        -- Additional Drone Stats
        droneGunDamage = Options.LaptopGunDamage and Options.LaptopGunDamage.Value or mod.droneGunDamage,
        flightSpeed = Options.LaptopFlightSpeed and Options.LaptopFlightSpeed.Value or mod.flightSpeed,
        turnSpeed = Options.LaptopTurnSpeed and Options.LaptopTurnSpeed.Value or mod.turnSpeed,
        droneHealth = Options.LaptopDroneHealth and Options.LaptopDroneHealth.Value or mod.droneHealth,
        canOpenDoors = Toggles.LaptopCanOpenDoors and Toggles.LaptopCanOpenDoors.Value or mod.canOpenDoors,
        droneCloakTransparency = Options.LaptopCloakTransparency and Options.LaptopCloakTransparency.Value or mod.droneCloakTransparency,
    }

    for index, v in pairs(cfg) do
        if v ~= old[index] then
            mod[index] = v
        end
    end

    Library:Notify('Applied modifications to Laptop!', 3)
end

LaptopMainGroup:AddButton({
    Text = 'Apply Laptop Mods',
    Func = function()
        xpcall(ApplyLaptopMod, function(err)
            Library:Notify('Error: ' .. tostring(err), 3)
        end)
    end
})

LaptopMainGroup:AddDivider()

LaptopMainGroup:AddSlider('LaptopFlightSpeed', { Text = 'Flight Speed', Default = 32, Min = 10, Max = 500, Rounding = 0 })
LaptopMainGroup:AddSlider('LaptopTurnSpeed', { Text = 'Turn Speed', Default = 90, Min = 10, Max = 500, Rounding = 0 })

local RemoveLaptopEffectsLoop = nil

LaptopVisualsGroup:AddToggle('RemoveLaptopEffects', {
    Text = 'Remove Overlay',
    Default = false,
    Callback = function(Value)
        if Value then
            RemoveLaptopEffectsLoop = RunService.RenderStepped:Connect(function()
                local charWorld = workspace:FindFirstChild(LocalPlayer.Name)
                if charWorld then
                    local laptop = charWorld:FindFirstChild("Laptop")
                    if laptop then
                        local droneClient = laptop:FindFirstChild("DroneClient")
                        if droneClient then
                            local droneBlur = droneClient:FindFirstChild("DroneBlur")
                            if droneBlur then droneBlur:Destroy() end

                            local droneColor = droneClient:FindFirstChild("DroneColor")
                            if droneColor then droneColor:Destroy() end
                        end
                    end
                end

                local vhs = PlayerGui:FindFirstChild("VHS")
                if vhs then vhs:Destroy() end
            end)
        else
            if RemoveLaptopEffectsLoop then
                RemoveLaptopEffectsLoop:Disconnect()
                RemoveLaptopEffectsLoop = nil
            end
        end
    end
})

local swayConnection = nil
local characterConnection = nil

local function toggleAimSwayRemoval(enabled)
    if enabled then
        local function checkValue(item)
            if item.Name == "AimSway" or item.Name == "SwayTime" then
                if item:IsA("NumberValue") then
                    item.Value = 0
                    if not item:FindFirstChild("SwayLockConn") then
                        local conn = item:GetPropertyChangedSignal("Value"):Connect(function()
                            if item.Value ~= 0 then
                                item.Value = 0
                            end
                        end)
                    end
                end
            end
        end

        local function setupCharacter(char)
            if swayConnection then swayConnection:Disconnect() end
            
            for _, descendant in ipairs(char:GetDescendants()) do
                checkValue(descendant)
            end
            
            swayConnection = char.DescendantAdded:Connect(checkValue)
        end

        if LocalPlayer.Character then
            setupCharacter(LocalPlayer.Character)
        end

        characterConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
            setupCharacter(newChar)
        end)
        
        Library:Notify('Aim Sway removal enabled!', 3)
    else
        if swayConnection then swayConnection:Disconnect() swayConnection = nil end
        if characterConnection then characterConnection:Disconnect() characterConnection = nil end
        Library:Notify('Aim Sway removal disabled.', 3)
    end
end

SniperGroup:AddToggle('RemoveAimSwayToggle', {
    Text = 'Remove Scope Sway',
    Default = false,
    Callback = function(Value)
        pcall(function()
            toggleAimSwayRemoval(Value)
        end)
    end
})

local PlayerESPGroup = VisualsTab:AddLeftGroupbox('ESP Elements')
local OffscreenGroup = VisualsTab:AddLeftGroupbox('Off-Screen Indicators')
local ChamsGroup = VisualsTab:AddRightGroupbox('Chams & Highlights')
local ScreenGroup = VisualsTab:AddRightGroupbox('Screen & Crosshair')

local BoxToggle = PlayerESPGroup:AddToggle('BoxESP', { Text = 'Box ESP', Default = false })
BoxToggle:AddColorPicker('BoxColor', { Default = Color3.fromRGB(255, 255, 255) })

local NameToggle = PlayerESPGroup:AddToggle('NameESP', { Text = 'Name / Distance ESP', Default = false })
NameToggle:AddColorPicker('NameColor', { Default = Color3.fromRGB(255, 255, 255) })

local GlobalNameConnections = {}

local function obfuscateText(text)
    if not (Toggles.HideAllUsernames and Toggles.HideAllUsernames.Value) then return text end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Name and #player.Name > 0 then
                text = text:gsub(player.Name, "[Hidden]")
            end
            if player.DisplayName and #player.DisplayName > 0 then
                text = text:gsub(player.DisplayName, "[Hidden]")
            end
        end
    end
    return text
end

local function initGlobalHiding()
    pcall(function()
        for _, gui in ipairs(game:GetService("CoreGui"):GetDescendants()) do
            hookTextLabel(gui)
        end
        table.insert(GlobalNameConnections, game:GetService("CoreGui").DescendantAdded:Connect(hookTextLabel))
    end)

    pcall(function()
        if LocalPlayer:FindFirstChild("PlayerGui") then
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                hookTextLabel(gui)
            end
            table.insert(GlobalNameConnections, LocalPlayer.PlayerGui.DescendantAdded:Connect(hookTextLabel))
        end
    end)
end

local function cleanupGlobalHiding()
    for _, conn in ipairs(GlobalNameConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(GlobalNameConnections)
end

PlayerESPGroup:AddToggle('HideAllUsernames', { 
    Text = 'Hide All Usernames', 
    Default = false,
    Callback = function(Value)
        if Value then
            initGlobalHiding()
            Library:Notify('username hiding enabled!', 3)
        else
            cleanupGlobalHiding()
            Library:Notify('username hiding disabled.', 3)
        end
    end
})

local HealthBarToggle = PlayerESPGroup:AddToggle('HealthBarESP', { Text = 'Health Bar', Default = false })

local SkelToggle = PlayerESPGroup:AddToggle('SkeletonESP', { Text = 'Skeleton ESP', Default = false })
SkelToggle:AddColorPicker('SkeletonColor', { Default = Color3.fromRGB(255, 255, 255) })

local TracerToggle = PlayerESPGroup:AddToggle('TracerESP', { Text = 'Tracer Lines', Default = false })
TracerToggle:AddColorPicker('TracerColor', { Default = Color3.fromRGB(255, 255, 255) })
local PassiveToggle = PlayerESPGroup:AddToggle('PassiveESP', { Text = 'Passive Check', Default = false })

PlayerESPGroup:AddDivider()
PlayerESPGroup:AddToggle('ShowOnlyPassiveOff', {
    Text = 'Show Only Passive Off',
    Default = false
})
PlayerESPGroup:AddDropdown('TracerOrigin', { Values = { 'Bottom', 'Center', 'Mouse' }, Default = 1, Multi = false, Text = 'Tracer Origin' })

local OffscreenToggle = OffscreenGroup:AddToggle('OffscreenESP', { Text = 'Off-Screen Indicators', Default = false })
OffscreenToggle:AddColorPicker('OffscreenColor', { Default = Color3.fromRGB(255, 100, 100) })
OffscreenGroup:AddSlider('OffscreenRadius', { Text = 'Indicator Radius', Default = 200, Min = 50, Max = 500, Rounding = 0 })
OffscreenGroup:AddSlider('OffscreenSize', { Text = 'Indicator Size', Default = 15, Min = 5, Max = 35, Rounding = 0 })

local NormalChamsToggle = ChamsGroup:AddToggle('ChamsESP', { Text = 'Chams ESP', Default = false })
NormalChamsToggle:AddColorPicker('ChamsColor', { Default = Color3.fromRGB(0, 255, 255) })

local WallcheckChamsToggle = ChamsGroup:AddToggle('ChamsWallcheckESP', { Text = 'Wallcheck Chams ESP', Default = false })
WallcheckChamsToggle:AddColorPicker('VisibleChamsColor', { Default = Color3.fromRGB(0, 255, 0) })
WallcheckChamsToggle:AddColorPicker('HiddenChamsColor', { Default = Color3.fromRGB(255, 0, 0) })

local HighlightToggle = ChamsGroup:AddToggle('HighlightESP', { Text = 'Highlight ESP', Default = false })
HighlightToggle:AddColorPicker('HighlightColor', { Default = Color3.fromRGB(255, 0, 0) })

ChamsGroup:AddDivider()

local function StorePartState(part)
    if not OriginalPartState[part] then
        OriginalPartState[part] = { Material = part.Material, Color = part.Color, Transparency = part.Transparency }
    end
end

local function RestorePartState(part)
    if OriginalPartState[part] then
        pcall(function()
            part.Material = OriginalPartState[part].Material
            part.Color = OriginalPartState[part].Color
            part.Transparency = OriginalPartState[part].Transparency
        end)
        OriginalPartState[part] = nil
    end
end

local function ApplyMaterialChams(character, materialEnum, color, fillTrans)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            StorePartState(part)
            pcall(function()
                part.Material = materialEnum
                part.Color = color
                part.Transparency = fillTrans
            end)
        end
    end
end

local function ClearMaterialChams(character)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then RestorePartState(part) end
    end
end

ChamsGroup:AddDropdown('ChamsMaterial', {
    Values = { 'Highlight', 'ForceField', 'Neon', 'Glass', 'Plastic' },
    Default = 1,
    Multi = false,
    Text = 'Chams Material Mode',
    Callback = function(Value)
        if Value == 'Highlight' then
            for player, _ in pairs(ESPCache) do
                if player.Character then ClearMaterialChams(player.Character) end
            end
        end
    end
})

ChamsGroup:AddSlider('ChamsFillTransparency', { Text = 'Fill Transparency', Default = 0.2, Min = 0, Max = 1, Rounding = 2 })
ChamsGroup:AddSlider('ChamsOutlineTransparency', { Text = 'Outline Transparency', Default = 0.5, Min = 0, Max = 1, Rounding = 2 })

ChamsGroup:AddDropdown('ChamsDepthMode', {
    Values = { 'AlwaysOnTop', 'Occluded' },
    Default = 1, Multi = false,
    Text = 'Chams Depth Style'
})

ScreenGroup:AddToggle('CustomFOVEnabled', {
    Text = 'Custom Field of View',
    Default = false,
    Callback = function(Value)
        if not Value then Camera.FieldOfView = 70 end
    end
})
ScreenGroup:AddSlider('CustomFOVAmount', { Text = 'FOV Value', Default = 70, Min = 10, Max = 120, Rounding = 0 })

local FOVConnection = RunService.RenderStepped:Connect(function()
    if Toggles.CustomFOVEnabled and Toggles.CustomFOVEnabled.Value then
        local targetFOV = Options.CustomFOVAmount and Options.CustomFOVAmount.Value or 70
        if Camera.FieldOfView ~= targetFOV then
            Camera.FieldOfView = targetFOV
        end
    end
end)

local CrossToggle = ScreenGroup:AddToggle('Crosshair', { Text = 'Screen Crosshair', Default = false })
CrossToggle:AddColorPicker('CrosshairColor', { Default = Color3.fromRGB(0, 255, 0) })

local CrosshairH = RegisterDrawing(Drawing.new('Line'))
local CrosshairV = RegisterDrawing(Drawing.new('Line'))

local R15_6Joint_Skeleton = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftHand"}, {"UpperTorso", "RightHand"},
    {"LowerTorso", "LeftFoot"}, {"LowerTorso", "RightFoot"}
}

local R6_6Joint_Skeleton = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function ClearAllCharacterHighlights(character)
    if not character then return end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA('Highlight') then child:Destroy() end
    end
end

local function CachePlayerComponents(data, character)
    if not character then return end
    data.HRP = character:FindFirstChild('HumanoidRootPart')
    data.Head = character:FindFirstChild('Head')
    data.Humanoid = character:FindFirstChildOfClass('Humanoid')
end

local function CreateESP(player)
    if player == LocalPlayer or ESPCache[player] then return end

    local data = { 
        ManagedHighlight = nil, Box = nil, HealthBarBg = nil, 
        HealthBar = nil, NameText = nil, PassiveText = nil, TracerLine = nil, 
        OffscreenArrow = nil, SkeletonLines = {},
        HRP = nil, Head = nil, Humanoid = nil
    }

    if player.Character then CachePlayerComponents(data, player.Character) end

    if Drawing then
        data.Box = RegisterDrawing(Drawing.new('Square'))
        data.Box.Thickness = 1.5
        data.Box.Filled = false
        data.Box.Visible = false

        data.HealthBarBg = RegisterDrawing(Drawing.new('Square'))
        data.HealthBarBg.Thickness = 1
        data.HealthBarBg.Filled = true
        data.HealthBarBg.Color = Color3.fromRGB(0, 0, 0)
        data.HealthBarBg.Visible = false

        data.HealthBar = RegisterDrawing(Drawing.new('Square'))
        data.HealthBar.Thickness = 1
        data.HealthBar.Filled = true
        data.HealthBar.Color = Color3.fromRGB(0, 255, 0)
        data.HealthBar.Visible = false

        data.NameText = RegisterDrawing(Drawing.new('Text'))
        data.NameText.Size = 16
        data.NameText.Center = true
        data.NameText.Outline = true
        data.NameText.Visible = false

        data.PassiveText = RegisterDrawing(Drawing.new('Text'))
        data.PassiveText.Size = 15
        data.PassiveText.Center = true
        data.PassiveText.Outline = true
        data.PassiveText.Visible = false

        data.TracerLine = RegisterDrawing(Drawing.new('Line'))
        data.TracerLine.Thickness = 1.5
        data.TracerLine.Visible = false

        data.OffscreenArrow = RegisterDrawing(Drawing.new('Triangle'))
        data.OffscreenArrow.Filled = true
        data.OffscreenArrow.Thickness = 1
        data.OffscreenArrow.Visible = false

        for i = 1, 6 do
            local line = RegisterDrawing(Drawing.new('Line'))
            line.Thickness = 1.5
            line.Visible = false
            table.insert(data.SkeletonLines, line)
        end
    end
    ESPCache[player] = data
end

local function RemoveESP(player)
    local data = ESPCache[player]
    if data then
        if player.Character then 
            ClearMaterialChams(player.Character)
            ClearAllCharacterHighlights(player.Character)
        end
        if data.Box then pcall(function() data.Box:Remove() end) end
        if data.HealthBarBg then pcall(function() data.HealthBarBg:Remove() end) end
        if data.HealthBar then pcall(function() data.HealthBar:Remove() end) end
        if data.NameText then pcall(function() data.NameText:Remove() end) end
        if data.PassiveText then pcall(function() data.PassiveText:Remove() end) end
        if data.TracerLine then pcall(function() data.TracerLine:Remove() end) end
        if data.OffscreenArrow then pcall(function() data.OffscreenArrow:Remove() end) end
        for _, line in ipairs(data.SkeletonLines) do pcall(function() line:Remove() end) end
        ESPCache[player] = nil
    end
end

local function SetupPlayerConnection(player)
    CreateESP(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.2)
        if ESPCache[player] then 
            ESPCache[player].ManagedHighlight = nil 
            CachePlayerComponents(ESPCache[player], character)
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do SetupPlayerConnection(player) end

local PlayerAddedConn = Players.PlayerAdded:Connect(SetupPlayerConnection)
local PlayerRemovingConn = Players.PlayerRemoving:Connect(RemoveESP)

local VisualsConnection = RunService.RenderStepped:Connect(function()
    local viewportSize = Camera.ViewportSize
    local center = Vector2_new(viewportSize.X / 2, viewportSize.Y / 2)

    if Toggles.Crosshair and Toggles.Crosshair.Value then
        local color = Options.CrosshairColor and Options.CrosshairColor.Value or Color3_fromRGB(0, 255, 0)
        CrosshairH.From = Vector2_new(center.X - 8, center.Y)
        CrosshairH.To = Vector2_new(center.X + 8, center.Y)
        CrosshairH.Color = color
        CrosshairH.Visible = true

        CrosshairV.From = Vector2_new(center.X, center.Y - 8)
        CrosshairV.To = Vector2_new(center.X, center.Y + 8)
        CrosshairV.Color = color
        CrosshairV.Visible = true
    else
        CrosshairH.Visible = false
        CrosshairV.Visible = false
    end

    local fillTrans = Options.ChamsFillTransparency and Options.ChamsFillTransparency.Value or 0.2
    local outlineTrans = Options.ChamsOutlineTransparency and Options.ChamsOutlineTransparency.Value or 0.5
    local depthStyle = Options.ChamsDepthMode and Enum.HighlightDepthMode[Options.ChamsDepthMode.Value] or Enum.HighlightDepthMode.AlwaysOnTop
    local materialMode = Options.ChamsMaterial and Options.ChamsMaterial.Value or 'Highlight'

    for player, data in pairs(ESPCache) do
        local character = player.Character
        local hrp = data.HRP or (character and character:FindFirstChild('HumanoidRootPart'))
        local head = data.Head or (character and character:FindFirstChild('Head'))
        local humanoid = data.Humanoid or (character and character:FindFirstChildOfClass('Humanoid'))

        if character and hrp and humanoid and humanoid.Health > 0 then
            local hasForceField = character:FindFirstChildOfClass('ForceField') ~= nil
            local shouldSkip = (Toggles.ShowOnlyPassiveOff and Toggles.ShowOnlyPassiveOff.Value and hasForceField)

            if shouldSkip then
                ClearAllCharacterHighlights(character)
                data.ManagedHighlight = nil
                ClearMaterialChams(character)
                if data.Box then data.Box.Visible = false end
                if data.HealthBarBg then data.HealthBarBg.Visible = false end
                if data.HealthBar then data.HealthBar.Visible = false end
                if data.NameText then data.NameText.Visible = false end
                if data.PassiveText then data.PassiveText.Visible = false end
                if data.TracerLine then data.TracerLine.Visible = false end
                if data.OffscreenArrow then data.OffscreenArrow.Visible = false end
                for _, line in ipairs(data.SkeletonLines) do line.Visible = false end
            else
                local isHighlightActive = Toggles.HighlightESP and Toggles.HighlightESP.Value
                local isWallcheckActive = Toggles.ChamsWallcheckESP and Toggles.ChamsWallcheckESP.Value
                local isNormalActive = Toggles.ChamsESP and Toggles.ChamsESP.Value
                local isChamsActive = isWallcheckActive or isNormalActive

                if isChamsActive or isHighlightActive then
                    if isChamsActive and materialMode ~= 'Highlight' then
                        local chosenMaterial = Enum.Material[materialMode] or Enum.Material.ForceField
                        local chosenColor = Options.ChamsColor and Options.ChamsColor.Value or Color3_fromRGB(0, 255, 255)

                        if isWallcheckActive then
                            local visColor = Options.VisibleChamsColor and Options.VisibleChamsColor.Value or Color3_fromRGB(0, 255, 0)
                            local hidColor = Options.HiddenChamsColor and Options.HiddenChamsColor.Value or Color3_fromRGB(255, 0, 0)
                            local targetPart = head or hrp
                            sharedRaycastParams.FilterDescendantsInstances = { Camera, character, LocalPlayer.Character }

                            local result = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), sharedRaycastParams)
                            local isBlocked = false
                            if result and result.Instance then
                                if result.Instance.CanCollide and not result.Instance:IsDescendantOf(character) then
                                    isBlocked = true
                                end
                            end
                            chosenColor = (not isBlocked) and visColor or hidColor
                        end

                        ApplyMaterialChams(character, chosenMaterial, chosenColor, fillTrans)
                    elseif materialMode == 'Highlight' then
                        ClearMaterialChams(character)
                    end

                    local hl = character:FindFirstChild('ManagedESPHighlight')
                    if not hl or not hl:IsA('Highlight') then
                        hl = Instance.new('Highlight')
                        hl.Name = 'ManagedESPHighlight'
                        hl.Parent = character
                    end
                    data.ManagedHighlight = hl

                    local fillColor = Color3_fromRGB(255, 0, 0)
                    local outlineColor = Color3_fromRGB(255, 0, 0)
                    local calculatedFillTrans = fillTrans
                    local calculatedOutlineTrans = outlineTrans

                    if isChamsActive then
                        local chamColor = Options.ChamsColor and Options.ChamsColor.Value or Color3_fromRGB(0, 255, 255)
                        if isWallcheckActive then
                            local visColor = Options.VisibleChamsColor and Options.VisibleChamsColor.Value or Color3_fromRGB(0, 255, 0)
                            local hidColor = Options.HiddenChamsColor and Options.HiddenChamsColor.Value or Color3_fromRGB(255, 0, 0)
                            local targetPart = head or hrp
                            sharedRaycastParams.FilterDescendantsInstances = { Camera, character, LocalPlayer.Character }

                            local result = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), sharedRaycastParams)
                            local isBlocked = false
                            if result and result.Instance then
                                if result.Instance.CanCollide and not result.Instance:IsDescendantOf(character) then
                                    isBlocked = true
                                end
                            end
                            chamColor = (not isBlocked) and visColor or hidColor
                        end
                        fillColor = chamColor
                        outlineColor = chamColor
                    end

                    if isHighlightActive then
                        local hlColor = Options.HighlightColor and Options.HighlightColor.Value or Color3_fromRGB(255, 0, 0)
                        if not isChamsActive then
                            fillColor = hlColor
                            outlineColor = hlColor
                            calculatedFillTrans = 0.5
                            calculatedOutlineTrans = 0
                        else
                            outlineColor = hlColor
                            calculatedOutlineTrans = 0
                        end
                    end

                    hl.FillColor = fillColor
                    hl.OutlineColor = outlineColor
                    hl.FillTransparency = (materialMode ~= 'Highlight') and math_clamp(fillTrans + 0.3, 0.3, 0.8) or calculatedFillTrans
                    hl.OutlineTransparency = calculatedOutlineTrans
                    hl.DepthMode = depthStyle
                    hl.Enabled = true
                else
                    ClearMaterialChams(character)
                    if character:FindFirstChild('ManagedESPHighlight') then
                        character.ManagedESPHighlight:Destroy()
                    end
                    data.ManagedHighlight = nil
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local isOutOfBounds = screenPos.X < 0 or screenPos.X > viewportSize.X or screenPos.Y < 0 or screenPos.Y > viewportSize.Y or screenPos.Z < 0

                if Toggles.OffscreenESP and Toggles.OffscreenESP.Value and (not onScreen or isOutOfBounds) then
                    local relativePos = Camera.CFrame:PointToObjectSpace(hrp.Position)
                    local dir = Vector2_new(relativePos.X, -relativePos.Y).Unit
                    if dir.X ~= dir.X or dir.Y ~= dir.Y then dir = Vector2_new(0, -1) end

                    local radius = Options.OffscreenRadius and Options.OffscreenRadius.Value or 200
                    local arrowSize = Options.OffscreenSize and Options.OffscreenSize.Value or 15

                    local arrowCenter = center + (dir * radius)
                    local tip = arrowCenter + (dir * arrowSize)
                    local perp = Vector2_new(-dir.Y, dir.X)
                    local left = arrowCenter + (perp * (arrowSize * 0.5))
                    local right = arrowCenter - (perp * (arrowSize * 0.5))

                    data.OffscreenArrow.PointA = tip
                    data.OffscreenArrow.PointB = left
                    data.OffscreenArrow.PointC = right
                    data.OffscreenArrow.Color = Options.OffscreenColor and Options.OffscreenColor.Value or Color3_fromRGB(255, 100, 100)
                    data.OffscreenArrow.Visible = true
                else
                    if data.OffscreenArrow then data.OffscreenArrow.Visible = false end
                end

                if Drawing then
                    if Toggles.TracerESP and Toggles.TracerESP.Value then
                        if onScreen then
                            local originPos = Vector2_new(viewportSize.X / 2, viewportSize.Y)
                            local originType = Options.TracerOrigin and Options.TracerOrigin.Value or 'Bottom'

                            if originType == 'Center' then originPos = center
                            elseif originType == 'Mouse' then originPos = UserInputService:GetMouseLocation() end

                            data.TracerLine.From = originPos
                            data.TracerLine.To = Vector2_new(screenPos.X, screenPos.Y)
                            data.TracerLine.Color = Options.TracerColor and Options.TracerColor.Value or Color3_fromRGB(255, 255, 255)
                            data.TracerLine.Visible = true
                        else
                            data.TracerLine.Visible = false
                        end
                    else
                        if data.TracerLine then data.TracerLine.Visible = false end
                    end

                    if onScreen then
                        local headPos = head and head.Position or (hrp.Position + Vector3_new(0, 2, 0))
                        local topPoint = Camera:WorldToViewportPoint(headPos + Vector3_new(0, 0.8, 0))
                        local botPoint = Camera:WorldToViewportPoint(hrp.Position - Vector3_new(0, 3, 0))

                        local boxHeight = math_abs(botPoint.Y - topPoint.Y)
                        local boxWidth = boxHeight * 0.65
                        local boxPos = Vector2_new(topPoint.X - (boxWidth / 2), topPoint.Y)

                        if Toggles.BoxESP and Toggles.BoxESP.Value then
                            data.Box.Color = Options.BoxColor and Options.BoxColor.Value or Color3_fromRGB(255, 255, 255)
                            data.Box.Size = Vector2_new(boxWidth, boxHeight)
                            data.Box.Position = boxPos
                            data.Box.Visible = true
                        else
                            data.Box.Visible = false
                        end

                        if Toggles.HealthBarESP and Toggles.HealthBarESP.Value then
                             local maxHealth = math.max(humanoid.MaxHealth, 1)
                             local healthPercent = math_clamp(humanoid.Health / maxHealth, 0, 1)
                             local barHeight = boxHeight
                             local barWidth = 1
                             local barX = boxPos.X - 4
                             local barY = boxPos.Y

                             data.HealthBarBg.Size = Vector2_new(barWidth + 2, barHeight + 2)
                             data.HealthBarBg.Position = Vector2_new(barX - 1, barY - 1)
                             data.HealthBarBg.Visible = true

                             local currentHeight = barHeight * healthPercent
                             data.HealthBar.Size = Vector2_new(barWidth, currentHeight)
                             data.HealthBar.Position = Vector2_new(barX, barY + (barHeight - currentHeight))
                             data.HealthBar.Color = Color3_fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                             data.HealthBar.Visible = true
                        else
                             data.HealthBarBg.Visible = false
                             data.HealthBar.Visible = false
                        end

                        if Toggles.NameESP and Toggles.NameESP.Value then
                            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                            local dist = myHRP and math_floor((myHRP.Position - hrp.Position).Magnitude) or 0
                            data.NameText.Color = Options.NameColor and Options.NameColor.Value or Color3_fromRGB(255, 255, 255)
                            
                            local displayName = player.Name
                            if Toggles.HideAllUsernames and Toggles.HideAllUsernames.Value then
                                displayName = "[Hidden]"
                            end

                            data.NameText.Text = string.format('%s [%dm]', displayName, dist)
                            data.NameText.Position = Vector2_new(boxPos.X + (boxWidth / 2), boxPos.Y - 18)
                            data.NameText.Visible = true
                        else
                            data.NameText.Visible = false
                        end

                        if Toggles.PassiveESP and Toggles.PassiveESP.Value then
                            local baseColor = Options.NameColor and Options.NameColor.Value or Color3_fromRGB(255, 255, 255)

                            if hasForceField then
                                data.PassiveText.Text = "Passive : On"
                                data.PassiveText.Color = Color3_fromRGB(0, 150, 255)
                            else
                                data.PassiveText.Text = "Passive: Off"
                                data.PassiveText.Color = baseColor
                            end

                            data.PassiveText.Position = Vector2_new(boxPos.X + (boxWidth / 2), boxPos.Y - 34)
                            data.PassiveText.Visible = true
                        else
                            data.PassiveText.Visible = false
                        end
                    else
                        if data.Box then data.Box.Visible = false end
                        if data.HealthBarBg then data.HealthBarBg.Visible = false end
                        if data.HealthBar then data.HealthBar.Visible = false end
                        if data.NameText then data.NameText.Visible = false end
                        if data.PassiveText then data.PassiveText.Visible = false end
                    end

                    if Toggles.SkeletonESP and Toggles.SkeletonESP.Value then
                        local bones = (humanoid.RigType == Enum.HumanoidRigType.R15) and R15_6Joint_Skeleton or R6_6Joint_Skeleton
                        local lineIdx = 1

                        for _, connection in ipairs(bones) do
                            local partA = character:FindFirstChild(connection[1])
                            local partB = character:FindFirstChild(connection[2])

                            if partA and partB then
                                local posA, visA = Camera:WorldToViewportPoint(partA.Position)
                                local posB, visB = Camera:WorldToViewportPoint(partB.Position)

                                if visA and visB and data.SkeletonLines[lineIdx] then
                                    local line = data.SkeletonLines[lineIdx]
                                    line.Color = Options.SkeletonColor and Options.SkeletonColor.Value or Color3_fromRGB(255, 255, 255)
                                    line.From = Vector2_new(posA.X, posA.Y)
                                    line.To = Vector2_new(posB.X, posB.Y)
                                    line.Visible = true
                                    lineIdx = lineIdx + 1
                                end
                            end
                        end

                        for i = lineIdx, #data.SkeletonLines do data.SkeletonLines[i].Visible = false end
                    else
                        for _, line in ipairs(data.SkeletonLines) do line.Visible = false end
                    end
                end
            end
        else
            ClearMaterialChams(character)
            ClearAllCharacterHighlights(character)
            data.ManagedHighlight = nil

            if data.Box then data.Box.Visible = false end
            if data.HealthBarBg then data.HealthBarBg.Visible = false end
            if data.HealthBar then data.HealthBar.Visible = false end
            if data.NameText then data.NameText.Visible = false end
            if data.PassiveText then data.PassiveText.Visible = false end
            if data.TracerLine then data.TracerLine.Visible = false end
            if data.OffscreenArrow then data.OffscreenArrow.Visible = false end
            for _, line in ipairs(data.SkeletonLines) do line.Visible = false end
        end
    end
end)

local StateFile = nil
local StopFlag = false
local FileStatus, BuildStatus

local function SafeJSONDecode(raw)
	if type(raw) ~= "string" or raw == "" then
		return false, "Raw data is empty or not a string"
	end

	if raw:match("%.%.%.%s*$") then
		return false, "JSON file is truncated (ends with '...')"
	end

	if type(json) == "table" then
		if type(json.tryDecode) == "function" then
			local success, result = pcall(function()
				return json.tryDecode(raw)
			end)
			if success and result ~= nil then
				return true, result
			end
		end
		if type(json.decode) == "function" then
			local success, result = pcall(function()
				return json.decode(raw)
			end)
			if success and result ~= nil then
				return true, result
			end
		end
	end

	
	local httpService = game:GetService("HttpService")
	local success, result = pcall(function()
		return httpService:JSONDecode(raw)
	end)
	if success then
		return true, result
	end

	if HTTP and type(HTTP.JSONDecode) == "function" then
		local success, result = pcall(function()
			return HTTP:JSONDecode(raw)
		end)
		if success then
			return true, result
		end
	end

	return false, result or "All JSON decode methods failed"
end

local BuilderGroupSrc = BuilderTab:AddLeftGroupbox('Source file')

BuilderGroupSrc:AddButton({
	Text = "Refresh file list",
	Func = function()
		local files = {}
		local success, fileList = pcall(function()
			return listfiles("")
		end)
		
		if not success or type(fileList) ~= "table" then
			success, fileList = pcall(function()
				return listfiles("/")
			end)
		end

		if success and type(fileList) == "table" then
			for _, f in ipairs(fileList) do
				local ext = f:lower():match("%.([^.]+)$")
				if ext == "json" then
					table.insert(files, f)
				end
			end
		end

		if #files == 0 then
			table.insert(files, "(none found) - put .json in workspace")
		end
		
		Options.FileDropdown:SetValues(files)
		Options.FileDropdown:SetValue(files[1])
		Library:Notify('Found ' .. tostring(#files == 1 and files[1] == "(none found) - put .json in workspace" and 0 or #files) .. ' .json file(s)', 3)
	end,
	Tooltip = "Scans your workspace folder for .json files",
})

BuilderGroupSrc:AddDropdown("FileDropdown", {
	Values = { "(press refresh)" },
	Default = 1,
	Searchable = true,
	Text = "File",
	Tooltip = "The .json build file to load",
})

BuilderGroupSrc:AddButton({
	Text = "Load file",
	Func = function()
		local selected = Options.FileDropdown.Value
		if not selected or not isfile(selected) then
			Library:Notify('Pick a valid file first (refresh the list)', 3)
			return
		end
		
		local raw = readfile(selected)
		local ok, data = SafeJSONDecode(raw)
		
		if not ok then
			Library:Notify('Load failed: ' .. tostring(data), 4)
			return
		end
		
		local genv = getgenv()
		genv.StarryStateFile = { Data = data, Name = selected }
		StateFile = genv.StarryStateFile

		local function countParts(items)
			local count = 0
			if type(items) == "table" then
				for _, item in ipairs(items) do
					if item.Position and item.Size then
						count = count + 1
					elseif item.Children then
						count = count + countParts(item.Children)
					end
				end
			end
			return count
		end

		local count = countParts(data)
		FileStatus:SetText(("Loaded: %s\n%d Part(s) in JSON"):format(selected, count))
		Library:Notify(('Loaded %s (%d parts)'):format(selected, count), 3)
	end,
	Tooltip = "readfile + JSONDecode",
})

FileStatus = BuilderGroupSrc:AddLabel("No file loaded yet", true)

local BuilderGroupExport = BuilderTab:AddRightGroupbox('Export Player Build')
local ExportStatus

BuilderGroupExport:AddButton({
	Text = "Refresh Players List",
	Func = function()
		local privateAreas = workspace:FindFirstChild("Private Building Areas") or workspace:FindFirstChild("PrivateBuilding Areas")
		local playersList = {}
		if privateAreas then
			for _, child in ipairs(privateAreas:GetChildren()) do
				if child.Name:sub(-9) == "BuildArea" then
					local playerName = child.Name:sub(1, #child.Name - 9)
					table.insert(playersList, playerName)
				elseif child:FindFirstChild("Build") then
					table.insert(playersList, child.Name)
				end
			end
		end
		
		if #playersList == 0 then
			table.insert(playersList, "(no building areas found)")
		end
		
		Options.ExportPlayerDropdown:SetValues(playersList)
		Options.ExportPlayerDropdown:SetValue(playersList[1])
		Library:Notify('Found ' .. tostring(#playersList) .. ' player building area(s)', 3)
	end,
	Tooltip = "Scans Private Building Areas for player builds",
})

BuilderGroupExport:AddDropdown("ExportPlayerDropdown", {
	Values = { "(press refresh)" },
	Default = 1,
	Searchable = true,
	Text = "Target Player",
	Tooltip = "Select player whose build to export",
})

BuilderGroupExport:AddButton({
	Text = "Export Build to JSON",
	Func = function()
		local playerName = Options.ExportPlayerDropdown.Value
		if not playerName or playerName == "(no building areas found)" or playerName == "(press refresh)" then
			Library:Notify("Please select a valid player first", 3)
			return
		end
		
		local privateAreas = workspace:FindFirstChild("Private Building Areas") or workspace:FindFirstChild("PrivateBuilding Areas")
		if not privateAreas then
			Library:Notify("Private Building Areas folder not found", 3)
			return
		end
		
		local playerFolder = privateAreas:FindFirstChild(playerName .. "BuildArea") or privateAreas:FindFirstChild(playerName)
		if not playerFolder then
			for _, child in ipairs(privateAreas:GetChildren()) do
				if child.Name == playerName or child.Name:sub(1, #child.Name - 9) == playerName then
					playerFolder = child
					break
				end
			end
		end
		
		if not playerFolder then
			Library:Notify("Player folder not found for: " .. playerName, 3)
			return
		end
		
		local buildModel = playerFolder:FindFirstChild("Build")
		if not buildModel then
			Library:Notify("Build folder not found under player's area", 3)
			return
		end

        local function serializeModel(model)
	            local data = {}
	            for _, child in ipairs(model:GetChildren()) do
		            if child:IsA("BasePart") then
			            local partData = {
				            Name = child.Name,
				            ClassName = child.ClassName,
				            Position = {child.Position.X, child.Position.Y, child.Position.Z},
				            CFrame = {child.CFrame:GetComponents()},
				            Size = {child.Size.X, child.Size.Y, child.Size.Z},
				            Color = {child.Color.R, child.Color.G, child.Color.B},
				            Material = tostring(child.Material),
				            Transparency = child.Transparency,
				            Reflectance = child.Reflectance,
				            CastShadow = child.CastShadow,
				            CanCollide = child.CanCollide,
				            Anchored = child.Anchored,
				            Children = {}
			            }
			            
	            for _, subChild in ipairs(child:GetChildren()) do
					            if subChild.ClassName == "Texture" then
						            table.insert(partData.Children, {
							            ClassName = subChild.ClassName,
							            Name = subChild.Name,
							            Texture = subChild.Texture,
							            Face = tostring(subChild.Face),
							            Transparency = subChild.Transparency,
							            StudsPerTileU = subChild.StudsPerTileU,
							            StudsPerTileV = subChild.StudsPerTileV
						            })
					            elseif subChild.ClassName == "Decal" then
						            table.insert(partData.Children, {
							            ClassName = subChild.ClassName,
							            Name = subChild.Name,
							            Texture = subChild.Texture,
							            Face = tostring(subChild.Face),
							            Transparency = subChild.Transparency
						            })
					            elseif subChild.ClassName == "SurfaceAppearance" then
						            table.insert(partData.Children, {
							            ClassName = subChild.ClassName,
							            ColorMap = subChild.ColorMap,
							            MetalnessMap = subChild.MetalnessMap,
							            NormalMap = subChild.NormalMap,
							            RoughnessMap = subChild.RoughnessMap
						            })
					            end
				            end
				            table.insert(data, partData)

			            elseif child:IsA("Model") or child:IsA("Folder") then
				            local nestedData = serializeModel(child)
				            for _, nestedItem in ipairs(nestedData) do
					            table.insert(data, nestedItem)
				            end
			            end
		        end
		        return data
	    end
		
		local success, result = pcall(function()
			local buildData = serializeModel(buildModel)
			local encoded = game:GetService("HttpService"):JSONEncode(buildData)
			local safeName = playerName:gsub("[^%w]", "_")
			local fileName = safeName .. "_Build.json"
			writefile(fileName, encoded)
			return fileName
		end)
		
		if success then
			ExportStatus:SetText("Successfully exported: " .. result)
			Library:Notify("Exported build to " .. result, 4)
		else
			ExportStatus:SetText("Export failed")
			Library:Notify("Export failed: " .. tostring(result), 4)
		end
	end,
	Tooltip = "Export player build to a custom JSON format compatible with executors",
})

ExportStatus = BuilderGroupExport:AddLabel("Idle", true)

local BuilderGroupBuild = BuilderTab:AddLeftGroupbox('Build')

BuilderGroupBuild:AddToggle("CenterOnPlot", {
	Text = "Center build on my plot",
	Default = true,
})

BuilderGroupBuild:AddToggle("ClearFirst", {
	Text = "Clear existing plot first",
	Default = true,
})

BuilderGroupBuild:AddSlider("Raise", {
	Text = "Raise above plot",
	Default = 1,
	Min = -10,
	Max = 50,
	Rounding = 1,
	Suffix = " studs",
})

BuilderGroupBuild:AddSlider("PaceMs", {
	Text = "Delay between parts",
	Default = 500,
	Min = 100,
	Max = 3000,
	Rounding = 0,
	Suffix = " ms",
})

local function GetBuildContext()
	local bt = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Building Tools")
		or LocalPlayer.Backpack:FindFirstChild("Building Tools")
	if not bt then return nil, "Building Tools not on character/backpack" end
	local api = bt:FindFirstChild("SyncAPI")
	if not api then return nil, "SyncAPI missing" end
	local tgt = require(bt.Core:WaitForChild("Targeting"))
	local scope = tgt.Scope
	if not scope or not scope:IsA("Folder") then return nil, "No build scope (stand on your plot?)" end
	return api, scope
end

local function EnsureCreated(api, scope, kind, targetCF, retries)
	for i = 1, retries do
		local p = api:Invoke("CreatePart", kind, CFrame.new(targetCF.Position), scope)
		if p then return p end
		task.wait(0.8)
	end
    if not targetCF then
         warn("Centering failed: Invalid target CFrame generated.")
         return
    end
	return nil
end

local function parseEnum(enumRegistry, enumString)
	if type(enumString) ~= "string" then return nil end
	local enumName = enumString:match("%.([^%.]+)$") or enumString
	local success, result = pcall(function()
		return enumRegistry[enumName]
	end)
	return success and result or nil
end

local function BuildSelected(selected, targetPlotCFrame, api, scope)
    if not selected or type(selected) ~= "string" or selected == "" then
        Library:Notify('Please select a valid JSON file from the dropdown first!', 4)
        return
    end
    
    local raw = readfile(selected)
    local ok, jsonData = SafeJSONDecode(raw)
    
    if not ok then
        Library:Notify('Load failed: ' .. tostring(jsonData), 4)
        return
    end

    local partsList = {}
    local function collectParts(items)
        if type(items) ~= "table" then return end
        for _, item in ipairs(items) do
            if item.Position and item.Size then
                table.insert(partsList, item)
            end
            if item.Children and type(item.Children) == "table" then
                collectParts(item.Children)
            end
        end
    end
    collectParts(jsonData)

    if #partsList == 0 then
        Library:Notify('JSON has no valid parts!', 4)
        return
    end
    local minY, maxY = math.huge, -math.huge
    local centerSum = Vector3.new(0, 0, 0)
    local partCount = #partsList

    for _, partData in ipairs(partsList) do
        local px, py, pz = partData.Position[1], partData.Position[2], partData.Position[3]
        local sizeY = partData.Size[2]
        
        minY = math.min(minY, py - (sizeY / 2))
        maxY = math.max(maxY, py + (sizeY / 2))
        centerSum = centerSum + Vector3.new(px, py, pz)
    end

    local modelCenter = partCount > 0 and (centerSum / partCount) or Vector3.new(0, 0, 0)
    local plot = scope and scope.Parent or nil
    local plotPos, plotTop = Vector3.new(0, 0, 0), 0
    
    if plot and plot:IsA("BasePart") then
        plotPos = plot.Position
        plotTop = plot.Position.Y + plot.Size.Y / 2
    elseif plot and plot:IsA("Model") then
        local cf, size = plot:GetBoundingBox()
        plotPos = cf.Position
        plotTop = cf.Position.Y + size.Y / 2
    else
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            plotPos = hrp.Position
            plotTop = hrp.Position.Y - 3
        elseif targetPlotCFrame then
            plotPos = targetPlotCFrame.Position
            plotTop = targetPlotCFrame.Position.Y
        end
    end

    local targetCenter
    if Toggles.CenterOnPlot and Toggles.CenterOnPlot.Value then
        targetCenter = Vector3.new(plotPos.X, plotTop + (Options.Raise and Options.Raise.Value or 0) + (maxY - minY) / 2, plotPos.Z)
    else
        targetCenter = Vector3.new(modelCenter.X, plotTop + (Options.Raise and Options.Raise.Value or 0) + (maxY - minY) / 2, modelCenter.Z)
    end
    local delta = targetCenter - modelCenter

    local placed, failed = 0, 0
    StopFlag = false
    
    for idx, src in ipairs(partsList) do
        if StopFlag then
            BuildStatus:SetText(("Stopped. %d placed, %d failed"):format(placed, failed))
            break
        end
        local kind = (src.ClassName == "Seat") and "Seat" or "Normal"
        
        local pos = src.Position
        local baseTargetPos = Vector3.new(pos[1], pos[2], pos[3])
        local targetCF
        if src.CFrame and type(src.CFrame) == "table" and #src.CFrame >= 12 then
            local rawCF = CFrame.new(unpack(src.CFrame))
            local rotationOnly = rawCF - rawCF.Position
            local shiftedPos = baseTargetPos + delta
            targetCF = CFrame.new(shiftedPos) * rotationOnly
        else
            local targetPos = baseTargetPos + delta
            targetCF = CFrame.new(targetPos)
        end

        local created = EnsureCreated(api, scope, kind, targetCF, 6)
        if not created then
            failed = failed + 1
            BuildStatus:SetText(("Fail %d/%d: %s"):format(idx, #partsList, src.Name or "Part"))
            task.wait(1)
        else
            local success, err = pcall(function()
                created.Size = Vector3.new(src.Size[1], src.Size[2], src.Size[3])
                created.CFrame = targetCF
                if src.Color then
                    created.Color = Color3.new(src.Color[1], src.Color[2], src.Color[3])
                end
                if src.Material then
                    pcall(function() 
                        created.Material = parseEnum(Enum.Material, src.Material) or Enum.Material.Plastic 
                    end)
                end
                created.Transparency = src.Transparency or 0
                created.Reflectance = src.Reflectance or 0
                created.CastShadow = src.CastShadow ~= false
                created.CanCollide = src.CanCollide ~= false
                created.Anchored = src.Anchored ~= false
                created.Name = src.Name or "Part"

                if src.Children and type(src.Children) == "table" then
                    for _, subData in ipairs(src.Children) do
                        if subData.ClassName == "Texture" then
                            local tex = Instance.new("Texture")
                            tex.Name = subData.Name or "Texture"
                            tex.Texture = subData.Texture or ""
                            tex.Face = parseEnum(Enum.NormalId, subData.Face) or Enum.NormalId.Front
                            tex.Transparency = subData.Transparency or 0
                            tex.StudsPerTileU = subData.StudsPerTileU or 1
                            tex.StudsPerTileV = subData.StudsPerTileV or 1
                            tex.Parent = created
                        elseif subData.ClassName == "Decal" then
                            local decal = Instance.new("Decal")
                            decal.Name = subData.Name or "Decal"
                            decal.Texture = subData.Texture or ""
                            decal.Face = parseEnum(Enum.NormalId, subData.Face) or Enum.NormalId.Front
                            decal.Transparency = subData.Transparency or 0
                            decal.Parent = created
                        elseif subData.ClassName == "SurfaceAppearance" then
                            local sa = Instance.new("SurfaceAppearance")
                            sa.ColorMap = subData.ColorMap or ""
                            sa.MetalnessMap = subData.MetalnessMap or ""
                            sa.NormalMap = subData.NormalMap or ""
                            sa.RoughnessMap = subData.RoughnessMap or ""
                            sa.Parent = created
                        end
                    end
                end
            end)
            
            if not success then
                failed = failed + 1
            else
                placed = placed + 1
            end
            BuildStatus:SetText(("Placing %d/%d (%d placed)"):format(idx, #partsList, placed))
            task.wait(Options.PaceMs and (Options.PaceMs.Value / 1000) or 0.01)
        end
    end
    BuildStatus:SetText(("Done. %d placed, %d failed out of %d"):format(placed, failed, #partsList))
    Library:Notify(("Build finished: %d placed, %d failed"):format(placed, failed), 4)
end

BuilderGroupBuild:AddButton({
	Text = "Build!",
	Func = function()
		task.spawn(function()
			local selectedFile = Options.FileDropdown and Options.FileDropdown.Value
			local api, scope = GetBuildContext()
			
			if not api or not scope then
				BuildStatus:SetText("Error: Building Tools or plot scope not found")
				Library:Notify("Building Tools or plot scope not found", 4)
				return
			end
			
			if Toggles.ClearFirst and Toggles.ClearFirst.Value then
				BuildStatus:SetText("Clearing existing plot...")
				local partsToRemove = {}
				for _, child in ipairs(scope:GetChildren()) do
					if child:IsA("BasePart") then
						table.insert(partsToRemove, child)
					end
				end
				if #partsToRemove > 0 then
					pcall(function()
						api:Invoke("Remove", partsToRemove)
					end)
				end
				task.wait(0.3)
			end
			
			local raiseOffset = Vector3.new(0, Options.Raise and Options.Raise.Value or 1, 0)
			local targetCFrame = CFrame.new(0, 5, 0)
			local plotFolder = scope.Parent
			local basePart = plotFolder and (plotFolder:FindFirstChild("Base") or plotFolder:FindFirstChild("Baseplate"))
				or scope:FindFirstChild("Base") or scope:FindFirstChild("Baseplate")
			
			if Toggles.CenterOnPlot and Toggles.CenterOnPlot.Value then
				if basePart then
					targetCFrame = basePart.CFrame + raiseOffset
				else
					targetCFrame = CFrame.new(0, raiseOffset.Y, 0)
				end
			else
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					targetCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + raiseOffset
				elseif basePart then
					targetCFrame = basePart.CFrame + raiseOffset
				end
			end
			
			BuildStatus:SetText("Building model...")
			local ok, err = pcall(function()
				BuildSelected(selectedFile, targetCFrame, api, scope)
			end)
			
			if ok then
				BuildStatus:SetText("Build complete!")
				Library:Notify("Model built successfully!", 3)
			else
				BuildStatus:SetText("Error during build")
				Library:Notify("Error: " .. tostring(err), 4)
			end
		end)
	end,
	Tooltip = "Rebuilds the loaded JSON model using your toggle settings",
})

BuilderGroupBuild:AddButton({
	Text = "Stop",
	Func = function()
		StopFlag = true
	end,
	Tooltip = "Stop the current build",
})

BuildStatus = BuilderGroupBuild:AddLabel("Idle", true)

local InfoGroup = InfoTab:AddLeftGroupbox('Credits & Socials')
local SessionGroup = InfoTab:AddRightGroupbox('Session Status')

InfoGroup:AddLabel('Made by noritery', true)
InfoGroup:AddDivider()
InfoGroup:AddLabel('UI Library by violin-suzutsuki', true)
InfoGroup:AddLabel('github.com/violin-suzutsuki/LinoriaLib', true)
InfoGroup:AddDivider()
InfoGroup:AddButton({
    Text = 'Copy Discord Link',
    Func = function()
        Library:Notify('Discord copied to clipboard!', 5)
        if setclipboard then setclipboard('https://discord.gg/NJub84fsb') end
    end
})

local TimeLabel = SessionGroup:AddLabel('Session Time: 00:00:00', true)
local StartTime = tick()

local SessionConnection = RunService.Heartbeat:Connect(function()
    local elapsed = math_floor(tick() - StartTime)
    TimeLabel:SetText(('Session Time: %02d:%02d:%02d'):format(math_floor(elapsed / 3600), math_floor((elapsed % 3600) / 60), elapsed % 60))
end)

local MenuGroup = UISettingsTab:AddLeftGroupbox('Menu Settings')
MenuGroup:AddButton({
    Text = 'Unload',
    Func = function() Library:Unload() end
})

local MenuPicker = MenuGroup:AddLabel('Menu bind')
MenuPicker:AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    SessionConnection:Disconnect()
    CombatConnection:Disconnect()
    VisualsConnection:Disconnect()
    if FOVConnection then FOVConnection:Disconnect() end
    if ToolSoundConnection then ToolSoundConnection:Disconnect() end
    PlayerAddedConn:Disconnect()
    PlayerRemovingConn:Disconnect()
    InputBeganConn:Disconnect()
    InputEndedConn:Disconnect()
    if FirstPersonBodyLoop then FirstPersonBodyLoop:Disconnect() end

    cleanupGlobalHiding()

    for seat, _ in pairs(ActiveSeatGUIs) do
        RemoveSeatGUI(seat)
    end

    if _G.FlyLoop then _G.FlyLoop:Disconnect() _G.FlyLoop = nil end
    if _G.SpeedLoop then _G.SpeedLoop:Disconnect() _G.SpeedLoop = nil end
    if _G.SpinbotLoop then _G.SpinbotLoop:Disconnect() _G.SpinbotLoop = nil end
    if _G_FreecamConn then _G_FreecamConn:Disconnect() _G_FreecamConn = nil end
    if _G.FullbrightLoop then _G.FullbrightLoop:Disconnect() _G.FullbrightLoop = nil end
    if _G.FreezeTimeLoop then _G.FreezeTimeLoop:Disconnect() _G.FreezeTimeLoop = nil end

    if _G.FlyObjects then
        pcall(function() _G.FlyObjects.BG:Destroy() end)
        pcall(function() _G.FlyObjects.BV:Destroy() end)
        _G.FlyObjects = nil
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild('HumanoidRootPart')
    local humanoid = char and char:FindFirstChildOfClass('Humanoid')
    if hrp then hrp.Anchored = false end
    if humanoid then humanoid.PlatformStand = false end
    
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA('BasePart') then
                part.LocalTransparencyModifier = 0
            end
        end
    end

    Camera.CameraType = Enum.CameraType.Custom
    Camera.FieldOfView = 70
    LocalPlayer.CameraMaxZoomDistance = 12.5

    local atm = Lighting:FindFirstChildOfClass('Atmosphere')
    if atm and atm:FindFirstChild('IsCustomAtmosphere') then atm:Destroy() end

    for player, _ in pairs(ESPCache) do RemoveESP(player) end
    table.clear(ESPCache)

    for _, drawObj in ipairs(DrawingRegistry) do
        pcall(function()
            drawObj.Visible = false
            drawObj:Remove()
        end)
    end
    table.clear(DrawingRegistry)

    Library:Notify('Unloaded successfully!', 3)
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind', 'AimbotKeybind', 'TriggerKeybind' })

ThemeManager:SetFolder('SkidWare Town')
SaveManager:SetFolder('SkidWare/configs')

SaveManager:BuildConfigSection(UISettingsTab)
ThemeManager:ApplyToTab(UISettingsTab)

SaveManager:LoadAutoloadConfig()
