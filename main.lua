-- mostly AI im embarrassed of ts

task.spawn(function()
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
end);

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
local UISettingsTab = Window:AddTab('UI Settings')
local InfoTab = Window:AddTab('Info')

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local Lighting = game:GetService('Lighting')
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local DrawingRegistry = {}
local ESPCache = {}
local OriginalPartState = {}

local function RegisterDrawing(drawingObj)
    table.insert(DrawingRegistry, drawingObj)
    return drawingObj
end

local function HeadPositionEstimate(char)
    local head = char and char:FindFirstChild('Head')
    return head and head.Position or (char and char.PrimaryPart and char.PrimaryPart.Position) or Vector3.new(0,0,0)
end

local MovementGroup = MainTab:AddLeftGroupbox('Movement & Camera')
local CharacterGroup = MainTab:AddRightGroupbox('Character Modifiers')
local WorldGroup = MainTab:AddRightGroupbox('World & Atmosphere')
local SpawnsGroup = MainTab:AddLeftGroupbox('Spawns')

SpawnsGroup:AddLabel('Wear Mask from inventory (Press ") to hide your username and get votekicked slower.', true)

SpawnsGroup:AddButton({
    Text = 'Hide Player | !s Mask',
    Func = function()
        local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
        Event:InvokeServer("!s mask")
    end,
    Tooltip = 'Wear this to hide username'
})

SpawnsGroup:AddButton({
    Text = 'Wear Armour | GRU',
    Func = function()
        local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
        Event:InvokeServer("!sa GRU")
    end,
    Tooltip = 'GRU Armour'
})

SpawnsGroup:AddButton({
    Text = 'Spawn MG',
    Func = function()
        local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
        Event:InvokeServer("!s mg")
    end,
    Tooltip = 'Invokes command: !s mg'
})

SpawnsGroup:AddButton({
    Text = 'Spawn M4',
    Func = function()
        local Event = game:GetService("Players").LocalPlayer.PlayerGui.ChatConsoleGui.CommandFunction
        Event:InvokeServer("!s m4")
    end,
    Tooltip = 'Invokes command: !s m4'
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
    end,
    Tooltip = 'Deletes workspace.[LocalPlayer].Helmet.Omniscence'
})

MovementGroup:AddToggle('Fly', {
    Text = 'Fly',
    Default = false,
    Tooltip = 'Toggle fly on/off',
    Callback = function(Value)
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local HRP = Character and Character:WaitForChild('HumanoidRootPart', 2)
        local Humanoid = Character and Character:FindFirstChildOfClass('Humanoid')

        if not HRP or not Humanoid then return end

        if Value then
            Humanoid.PlatformStand = true

            local BG = Instance.new('BodyGyro')
            BG.P = 9e4
            BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            BG.CFrame = HRP.CFrame
            BG.Parent = HRP

            local BV = Instance.new('BodyVelocity')
            BV.Velocity = Vector3.new(0, 0, 0)
            BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            BV.Parent = HRP

            _G.FlyObjects = { BG = BG, BV = BV }

            _G.FlyLoop = RunService.Heartbeat:Connect(function()
                local moveDir = Vector3.new(0, 0, 0)
                local SPEED = Options.FlySpeed and Options.FlySpeed.Value or 60

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                BG.CFrame = Camera.CFrame
                BV.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * SPEED or Vector3.new(0, 0, 0)
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
local freecamPos = Vector3.new(0, 0, 0)
local freecamRotX, freecamRotY = 0, 0
local lastMousePos = Vector2.new(0, 0)
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
                    freecamRotX = math.clamp(freecamRotX - (mouseDelta.Y * 0.003), -math.pi / 2, math.pi / 2)
                end

                local camCFrame = CFrame.new(freecamPos) * CFrame.Angles(0, freecamRotY, 0) * CFrame.Angles(freecamRotX, 0, 0)
                local moveDir = Vector3.new(0, 0, 0)
                local speed = Options.FreecamSpeed and Options.FreecamSpeed.Value or 50

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                freecamPos = freecamPos + (moveDir * speed * dt)
                Camera.CFrame = CFrame.new(freecamPos) * CFrame.Angles(0, freecamRotY, 0) * CFrame.Angles(freecamRotX, 0, 0)
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

CharacterGroup:AddToggle('Spinbot', {
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
                    local isAiming = (Options.AimbotKeybind and Options.AimbotKeybind:GetState()) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                    local isFirstPerson = (Camera.CFrame.Position - HeadPositionEstimate(char)).Magnitude < 1.5

                    if not (isAiming and isFirstPerson) then
                        local speed = Options.SpinSpeed and Options.SpinSpeed.Value or 50
                        local currentAngles = hrp.CFrame - hrp.CFrame.Position
                        local spinAngle = CFrame.Angles(0, math.rad(speed), 0)
                        
                        hrp.CFrame = CFrame.new(hrp.CFrame.Position) * currentAngles * spinAngle
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
CharacterGroup:AddSlider('SpinSpeed', { Text = 'Spin Speed', Default = 50, Min = 10, Max = 200, Rounding = 0 })

CharacterGroup:AddDivider()

CharacterGroup:AddToggle('HideFirstPersonBody', {
    Text = 'Hide Body in First Person',
    Default = false,
    Tooltip = 'Hides your local body parts and hair in first person',
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
    Default = false,
    Tooltip = 'Hides your character arms/hands even in first person'
})

CharacterGroup:AddToggle('HideFirstPersonTool', {
    Text = 'Also Hide Equipped Tool',
    Default = false,
    Tooltip = 'Hides your equipped weapon/tool model in first person'
})

local FirstPersonBodyLoop = RunService.RenderStepped:Connect(function()
    if not (Toggles.HideFirstPersonBody and Toggles.HideFirstPersonBody.Value) then return end
    local char = LocalPlayer.Character
    if not char then return end
    
    local head = char:FindFirstChild('Head')
    if not head then return end

    local isFirstPerson = (Camera.CFrame.Position - head.Position).Magnitude < 1.5
    local hideArms = Toggles.HideFirstPersonArms and Toggles.HideFirstPersonArms.Value
    local hideTool = Toggles.HideFirstPersonTool and Toggles.HideFirstPersonTool.Value

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA('BasePart') and part.Name ~= 'HumanoidRootPart' then
            local isArm = part.Name:lower():find('arm') or 
                          part.Name:lower():find('hand') or 
                          part.Name:lower():find('upperarm') or 
                          part.Name:lower():find('lowerarm') or 
                          part.Name:lower():find('rightlowerarm') or 
                          part.Name:lower():find('leftlowerarm') or
                          part.Name:lower():find('rightupperarm') or 
                          part.Name:lower():find('leftupperarm')

            local isToolPart = part.Parent:IsA('Tool') or part:FindFirstAncestorOfClass('Tool') ~= nil
            local isHair = part.Name:lower():find('hair') or 
                           (part.Parent and part.Parent:IsA('Accessory') and part.Parent.AccessoryType == Enum.AccessoryType.Hair) or
                           (part.Parent and part.Parent.Name:lower():find('hair'))

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

            if shouldHide then
                part.LocalTransparencyModifier = 1
            else
                part.LocalTransparencyModifier = 0
            end
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
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
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

_G.SelectedSkyboxPreset = 'Default'

WorldGroup:AddDropdown('SkyboxPreset', {
    Values = { 'Default', 'Purple Nebula', 'Vaporwave', 'Space' },
    Default = 1,
    Multi = false,
    Text = 'Skybox Preset',
    Callback = function(Value)
        _G.SelectedSkyboxPreset = Value
        local data = SkyboxData[Value]
        if data and data.Type == 'Default' then
            local atm = Lighting:FindFirstChildOfClass('Atmosphere')
            if atm and atm:FindFirstChild('IsCustomAtmosphere') then atm:Destroy() end
        end
    end
})

local SkyboxLoop = RunService.RenderStepped:Connect(function()
    local data = SkyboxData[_G.SelectedSkyboxPreset]
    if data and data.Type == 'Procedural' then
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
end)

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

local AimToggle = AimbotGroup:AddToggle('AimbotEnabled', { Text = 'Enable Aimbot', Default = false })
AimToggle:AddKeyPicker('AimbotKeybind', { Default = 'MB2', Mode = 'Hold', Text = 'Aimbot Key' })

AimbotGroup:AddDropdown('AimbotTargetPart', { Values = { 'Head', 'HumanoidRootPart', 'Torso' }, Default = 1, Multi = false, Text = 'Target Part' })

AimFilterGroup:AddToggle('AimbotEnableBots', { Text = 'Target Bots', Default = false, Tooltip = 'Aims at models inside workspace.BotStorage' })
AimFilterGroup:AddToggle('AimbotWallCheck', { Text = 'Wall Check', Default = true })
AimFilterGroup:AddToggle('AimbotPassiveCheck', { Text = 'Ignore Passive / ForceField', Default = false, Tooltip = 'Prevents aimbot from targeting shielded entities' })

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

local LockedTarget = nil

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
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local ignoreList = { Camera }
        if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
        rayParams.FilterDescendantsInstances = ignoreList

        local result = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position), rayParams)
        if not (result and result.Instance:IsDescendantOf(character)) then return false end
    end

    return true
end

local function GetClosestTarget()
    local closestPart = nil
    local maxRadius = Options.AimbotFOV and Options.AimbotFOV.Value or 150
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local partName = Options.AimbotTargetPart and Options.AimbotTargetPart.Value or 'Head'

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local targetPart = character:FindFirstChild(partName) or character:FindFirstChild('Head')

            if targetPart and IsValidTarget(targetPart, character) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                    if dist <= maxRadius then
                        maxRadius = dist
                        closestPart = targetPart
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
                    local targetPart = botModel:FindFirstChild(partName) or botModel:FindFirstChild('Head') or botModel.PrimaryPart
                    if targetPart and IsValidTarget(targetPart, botModel) then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                            if dist <= maxRadius then
                                maxRadius = dist
                                closestPart = targetPart
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPart
end

local lastTriggerClick = 0

local CombatConnection = RunService.RenderStepped:Connect(function()
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if Toggles.DrawFOV and Toggles.DrawFOV.Value then
        FOVCircle.Position = centerScreen
        FOVCircle.Radius = Options.AimbotFOV and Options.AimbotFOV.Value or 150
        FOVCircle.Color = Options.FOVColor and Options.FOVColor.Value or Color3.fromRGB(255, 255, 255)
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    local isKeyDown = Options.AimbotKeybind and Options.AimbotKeybind:GetState()
    if Toggles.AimbotEnabled and Toggles.AimbotEnabled.Value and isKeyDown then
        LockedTarget = GetClosestTarget()
        if LockedTarget then Camera.CFrame = CFrame.new(Camera.CFrame.Position, LockedTarget.Position) end
    else
        LockedTarget = nil
    end

    if Toggles.TriggerbotEnabled and Toggles.TriggerbotEnabled.Value and Options.TriggerKeybind and Options.TriggerKeybind:GetState() then
        local delayVal = Options.TriggerbotDelay and Options.TriggerbotDelay.Value or 0.05
        if (tick() - lastTriggerClick >= delayVal) then
            local unitRay = Camera:ViewportPointToRay(centerScreen.X, centerScreen.Y)
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local ignoreList = { Camera }
            if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
            rayParams.FilterDescendantsInstances = ignoreList

            local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rayParams)
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
                        if mouse1click then mouse1click() end
                    end
                end
            end
        end
    end
end)

local WeaponGroup = ModsTab:AddLeftGroupbox('Equipped Weapon Modifications')
local SoundModGroup = ModsTab:AddRightGroupbox('Gun Sound Modder')

local originalValues = {}
local currentModifiedTool = nil

local function GetEquippedWeaponSettings()
    local character = LocalPlayer.Character
    if not character then return nil, nil end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA('Tool') then
            local settingsModule = child:FindFirstChild('Settings')
            if settingsModule and settingsModule:IsA('ModuleScript') then
                local success, settingsTable = pcall(require, settingsModule)
                if success and type(settingsTable) == 'table' then
                    return settingsTable, child
                end
            end
        end
    end
    return nil, nil
end

local function RestoreWeaponStats(tool)
    if not tool or not originalValues[tool] then return end
    local settingsModule = tool:FindFirstChild('Settings')
    if settingsModule and settingsModule:IsA('ModuleScript') then
        local success, settingsTable = pcall(require, settingsModule)
        if success and type(settingsTable) == 'table' then
            local orig = originalValues[tool]
            settingsTable.ReloadSpeed = orig.ReloadSpeed
            settingsTable.ReloadSpeed2 = orig.ReloadSpeed2
            settingsTable.waittime = orig.waittime
            settingsTable.GunRecoil = orig.GunRecoil
            settingsTable.GunRecoilX = orig.GunRecoilX
            settingsTable.AimSpeed = orig.AimSpeed
            settingsTable.cooldown = orig.cooldown
            settingsTable.guardTime = orig.guardTime
            if orig.hitbox and settingsTable.hitbox then
                settingsTable.hitbox = orig.hitbox
            end
        end
    end
    originalValues[tool] = nil
end

local WeaponModConnection = RunService.Stepped:Connect(function()
    if not Toggles.EnableWeaponMods or not Toggles.EnableWeaponMods.Value then return end

    local settings, equippedTool = GetEquippedWeaponSettings()
    if not settings or not equippedTool then
        currentModifiedTool = nil
        return
    end

    if currentModifiedTool ~= equippedTool then currentModifiedTool = equippedTool end

    if not originalValues[equippedTool] then
        originalValues[equippedTool] = {
            ReloadSpeed = settings.ReloadSpeed,
            ReloadSpeed2 = settings.ReloadSpeed2,
            waittime = settings.waittime,
            GunRecoil = settings.GunRecoil,
            GunRecoilX = settings.GunRecoilX,
            AimSpeed = settings.AimSpeed,
            cooldown = settings.cooldown,
            guardTime = settings.guardTime,
            hitbox = settings.hitbox and Vector3.new(settings.hitbox.X, settings.hitbox.Y, settings.hitbox.Z) or nil
        }
    end

    settings.ReloadSpeed = Options.ModReloadSpeed.Value
    settings.ReloadSpeed2 = Options.ModReloadSpeed.Value
    settings.waittime = Options.ModFireRate.Value
    settings.GunRecoil = Options.ModRecoil.Value
    settings.GunRecoilX = Options.ModRecoilX.Value
    settings.AimSpeed = Options.ModAimSpeed.Value

    if settings.cooldown ~= nil then
        settings.cooldown = Options.ModCooldown.Value
    end
    if settings.guardTime ~= nil then
        settings.guardTime = Options.ModGuardTime.Value
    end
    if settings.hitbox ~= nil and originalValues[equippedTool].hitbox then
        local baseHitbox = originalValues[equippedTool].hitbox
        local rangeMultiplier = Options.ModRange.Value
        settings.hitbox = Vector3.new(baseHitbox.X, baseHitbox.Y, baseHitbox.Z * rangeMultiplier)
    end
end)

WeaponGroup:AddToggle('EnableWeaponMods', {
    Text = 'Enable Custom Stats (Equipped)',
    Default = false,
    Callback = function(Value)
        if not Value and currentModifiedTool then
            RestoreWeaponStats(currentModifiedTool)
            currentModifiedTool = nil
            Library:Notify('Weapon stats restored!', 3)
        elseif Value then
            Library:Notify('Modifications active for equipped weapon.', 3)
        end
    end
})

WeaponGroup:AddDivider()

WeaponGroup:AddSlider('ModReloadSpeed', { Text = 'Reload Speed (s)', Default = 0.5, Min = 0.05, Max = 3.0, Rounding = 2 })
WeaponGroup:AddSlider('ModFireRate', { Text = 'Fire Delay / Wait Time (s)', Default = 0.04, Min = 0.01, Max = 0.20, Rounding = 3 })
WeaponGroup:AddSlider('ModRecoil', { Text = 'Gun Recoil (Vertical)', Default = 0.3, Min = 0, Max = 2.0, Rounding = 2 })
WeaponGroup:AddSlider('ModRecoilX', { Text = 'Gun Recoil X (Horizontal)', Default = 0.3, Min = 0, Max = 2.0, Rounding = 2 })
WeaponGroup:AddSlider('ModAimSpeed', { Text = 'Aim Speed (ADS Duration)', Default = 0.25, Min = 0.01, Max = 1.0, Rounding = 2 })

WeaponGroup:AddDivider()

WeaponGroup:AddSlider('ModCooldown', { Text = 'Attack Cooldown (s)', Default = 0.54, Min = 0.01, Max = 3.0, Rounding = 2, Tooltip = 'Edits weapon settings cooldown' })
WeaponGroup:AddSlider('ModGuardTime', { Text = 'Guard Time (s)', Default = 1.5, Min = 0.1, Max = 5.0, Rounding = 2, Tooltip = 'Edits weapon settings guardTime' })
WeaponGroup:AddSlider('ModRange', { Text = 'Range Multiplier', Default = 1.0, Min = 0.5, Max = 5.0, Rounding = 1, Tooltip = 'Scales weapon hitbox range' })

SoundModGroup:AddInput('SoundIdInput', {
    Default = 'rbxassetid://0',
    Numeric = false,
    Finished = false,
    Text = 'New Sound ID Input',
    Tooltip = 'Enter the Sound ID (e.g. rbxassetid://your_id)',
    Placeholder = 'rbxassetid://...'
})

local SoundModLoop = RunService.Stepped:Connect(function()
    if not Toggles.AutoUpdateSounds or not Toggles.AutoUpdateSounds.Value then return end
    
    local inputVal = Options.SoundIdInput and Options.SoundIdInput.Value
    if not inputVal or inputVal == '' or inputVal == 'rbxassetid://0' then return end

    local formattedInput = inputVal
    if not string.match(inputVal, "rbxassetid://") then
        local numericId = string.match(inputVal, "%d+")
        if numericId then
            formattedInput = "rbxassetid://" .. numericId
        end
    end

    local character = LocalPlayer.Character
    if not character then return end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA('Tool') then
            for _, obj in ipairs(child:GetDescendants()) do
                if obj:IsA('Sound') then
                    if obj.SoundId ~= formattedInput then
                        obj.SoundId = formattedInput
                    end
                end
            end
        end
    end
end)

SoundModGroup:AddToggle('AutoUpdateSounds', {
    Text = 'Auto-Update Equipped Sound Loop',
    Default = false,
    Tooltip = 'Continuously updates all sounds inside your equipped tool in real-time',
    Callback = function(Value)
        if Value then
            Library:Notify('Continuous sound loop activated!', 3)
        else
            Library:Notify('Continuous sound loop deactivated.', 3)
        end
    end
})

SoundModGroup:AddButton({
    Text = 'Apply Once to Tool Sounds',
    Func = function()
        local inputVal = Options.SoundIdInput and Options.SoundIdInput.Value
        if not inputVal or inputVal == '' or inputVal == 'rbxassetid://0' then
            Library:Notify('Please enter a valid Sound ID first!', 3)
            return
        end

        local formattedInput = inputVal
        if not string.match(inputVal, "rbxassetid://") then
            local numericId = string.match(inputVal, "%d+")
            if numericId then
                formattedInput = "rbxassetid://" .. numericId
            end
        end

        local character = LocalPlayer.Character
        if not character then 
            Library:Notify('Character not found!', 3)
            return 
        end

        local foundTool = false
        local updatedCount = 0

        for _, child in ipairs(character:GetChildren()) do
            if child:IsA('Tool') then
                foundTool = true
                for _, obj in ipairs(child:GetDescendants()) do
                    if obj:IsA('Sound') then
                        obj.SoundId = formattedInput
                        updatedCount = updatedCount + 1
                    end
                end
            end
        end

        if foundTool then
            Library:Notify(string.format('Successfully updated %d sounds in tool!', updatedCount), 4)
        else
            Library:Notify('No equipped tool found!', 4)
        end
    end,
    Tooltip = 'Loops through all sounds inside your equipped tool and applies input ID once'
})

local PlayerESPGroup = VisualsTab:AddLeftGroupbox('ESP Elements')
local OffscreenGroup = VisualsTab:AddLeftGroupbox('Off-Screen Indicators')
local ChamsGroup = VisualsTab:AddRightGroupbox('Chams & Highlights')
local ScreenGroup = VisualsTab:AddRightGroupbox('Screen & Crosshair')

local BoxToggle = PlayerESPGroup:AddToggle('BoxESP', { Text = 'Box ESP', Default = false })
BoxToggle:AddColorPicker('BoxColor', { Default = Color3.fromRGB(255, 255, 255) })

local NameToggle = PlayerESPGroup:AddToggle('NameESP', { Text = 'Name / Distance ESP', Default = false })
NameToggle:AddColorPicker('NameColor', { Default = Color3.fromRGB(255, 255, 255) })

local HealthBarToggle = PlayerESPGroup:AddToggle('HealthBarESP', { Text = 'Health Bar', Default = false })

local SkelToggle = PlayerESPGroup:AddToggle('SkeletonESP', { Text = 'Skeleton ESP', Default = false })
SkelToggle:AddColorPicker('SkeletonColor', { Default = Color3.fromRGB(255, 255, 255) })

local TracerToggle = PlayerESPGroup:AddToggle('TracerESP', { Text = 'Tracer Lines', Default = false })
TracerToggle:AddColorPicker('TracerColor', { Default = Color3.fromRGB(255, 255, 255) })
PlayerESPGroup:AddDropdown('TracerOrigin', { Values = { 'Bottom', 'Center', 'Mouse' }, Default = 1, Multi = false, Text = 'Tracer Origin' })

PlayerESPGroup:AddDivider()

local PassiveToggle = PlayerESPGroup:AddToggle('PassiveESP', { Text = 'Passive / ForceField Text', Default = false })
PlayerESPGroup:AddToggle('ShowOnlyPassiveOff', {
    Text = 'Show Only Passive Off',
    Default = false,
    Tooltip = 'Hides ESP entirely for players with active shields'
})

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
        part.Material = OriginalPartState[part].Material
        part.Color = OriginalPartState[part].Color
        part.Transparency = OriginalPartState[part].Transparency
        OriginalPartState[part] = nil
    end
end

local function ApplyMaterialChams(character, materialEnum, color)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            StorePartState(part)
            part.Material = materialEnum
            part.Color = color
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

ChamsGroup:AddSlider('ChamsFillTransparency', {
    Text = 'Fill Transparency',
    Default = 0.2, Min = 0, Max = 1, Rounding = 2
})

ChamsGroup:AddSlider('ChamsOutlineTransparency', {
    Text = 'Outline Transparency',
    Default = 0.5, Min = 0, Max = 1, Rounding = 2
})

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
        if child:IsA('Highlight') then
            child:Destroy()
        end
    end
end

local function CreateESP(player)
    if player == LocalPlayer or ESPCache[player] then return end

    local data = { 
        ManagedHighlight = nil, Box = nil, HealthBarBg = nil, 
        HealthBar = nil, NameText = nil, PassiveText = nil, TracerLine = nil, 
        OffscreenArrow = nil, SkeletonLines = {} 
    }

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
    player.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        if ESPCache[player] then
            ESPCache[player].ManagedHighlight = nil
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do SetupPlayerConnection(player) end

local PlayerAddedConn = Players.PlayerAdded:Connect(SetupPlayerConnection)
local PlayerRemovingConn = Players.PlayerRemoving:Connect(RemoveESP)

local VisualsConnection = RunService.RenderStepped:Connect(function()
    if Toggles.Crosshair and Toggles.Crosshair.Value then
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local color = Options.CrosshairColor and Options.CrosshairColor.Value or Color3.fromRGB(0, 255, 0)

        CrosshairH.From = Vector2.new(center.X - 8, center.Y)
        CrosshairH.To = Vector2.new(center.X + 8, center.Y)
        CrosshairH.Color = color
        CrosshairH.Visible = true

        CrosshairV.From = Vector2.new(center.X, center.Y - 8)
        CrosshairV.To = Vector2.new(center.X, center.Y + 8)
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
        local hrp = character and character:FindFirstChild('HumanoidRootPart')
        local head = character and character:FindFirstChild('Head')
        local humanoid = character and character:FindFirstChildOfClass('Humanoid')

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
                        local chosenColor = Options.ChamsColor and Options.ChamsColor.Value or Color3.fromRGB(0, 255, 255)

                        if isWallcheckActive then
                            local visColor = Options.VisibleChamsColor and Options.VisibleChamsColor.Value or Color3.fromRGB(0, 255, 0)
                            local hidColor = Options.HiddenChamsColor and Options.HiddenChamsColor.Value or Color3.fromRGB(255, 0, 0)
                            local targetPart = head or hrp
                            local rayParams = RaycastParams.new()
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            rayParams.FilterDescendantsInstances = { Camera, character, LocalPlayer.Character }

                            local result = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), rayParams)
                            chosenColor = (not result) and visColor or hidColor
                        end

                        ApplyMaterialChams(character, chosenMaterial, chosenColor)
                    else
                        ClearMaterialChams(character)
                    end

                    local hl = character:FindFirstChild('ManagedESPHighlight')
                    if not hl or not hl:IsA('Highlight') then
                        hl = Instance.new('Highlight')
                        hl.Name = 'ManagedESPHighlight'
                        hl.Parent = character
                    end
                    data.ManagedHighlight = hl

                    local fillColor = Color3.fromRGB(255, 0, 0)
                    local outlineColor = Color3.fromRGB(255, 0, 0)
                    local calculatedFillTrans = fillTrans
                    local calculatedOutlineTrans = outlineTrans

                    if isChamsActive then
                        local chamColor = Options.ChamsColor and Options.ChamsColor.Value or Color3.fromRGB(0, 255, 255)
                        if isWallcheckActive then
                            local visColor = Options.VisibleChamsColor and Options.VisibleChamsColor.Value or Color3.fromRGB(0, 255, 0)
                            local hidColor = Options.HiddenChamsColor and Options.HiddenChamsColor.Value or Color3.fromRGB(255, 0, 0)
                            local targetPart = head or hrp
                            local rayParams = RaycastParams.new()
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            rayParams.FilterDescendantsInstances = { Camera, character, LocalPlayer.Character }

                            local result = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), rayParams)
                            chamColor = (not result) and visColor or hidColor
                        end
                        fillColor = chamColor
                        outlineColor = chamColor
                    end

                    if isHighlightActive then
                        local hlColor = Options.HighlightColor and Options.HighlightColor.Value or Color3.fromRGB(255, 0, 0)
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
                    hl.FillTransparency = (materialMode ~= 'Highlight') and math.clamp(fillTrans + 0.3, 0.3, 0.8) or calculatedFillTrans
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
                local viewportSize = Camera.ViewportSize
                local isOutOfBounds = screenPos.X < 0 or screenPos.X > viewportSize.X or screenPos.Y < 0 or screenPos.Y > viewportSize.Y or screenPos.Z < 0

                if Toggles.OffscreenESP and Toggles.OffscreenESP.Value and (not onScreen or isOutOfBounds) then
                    local relativePos = Camera.CFrame:PointToObjectSpace(hrp.Position)
                    local dir = Vector2.new(relativePos.X, -relativePos.Y).Unit

                    if dir.X ~= dir.X or dir.Y ~= dir.Y then dir = Vector2.new(0, -1) end

                    local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
                    local radius = Options.OffscreenRadius and Options.OffscreenRadius.Value or 200
                    local arrowSize = Options.OffscreenSize and Options.OffscreenSize.Value or 15

                    local arrowCenter = center + (dir * radius)
                    local tip = arrowCenter + (dir * arrowSize)
                    local perp = Vector2.new(-dir.Y, dir.X)
                    local left = arrowCenter + (perp * (arrowSize * 0.5))
                    local right = arrowCenter - (perp * (arrowSize * 0.5))

                    data.OffscreenArrow.PointA = tip
                    data.OffscreenArrow.PointB = left
                    data.OffscreenArrow.PointC = right
                    data.OffscreenArrow.Color = Options.OffscreenColor and Options.OffscreenColor.Value or Color3.fromRGB(255, 100, 100)
                    data.OffscreenArrow.Visible = true
                else
                    if data.OffscreenArrow then data.OffscreenArrow.Visible = false end
                end

                local cframe, size = character:GetBoundingBox()
                local halfSize = size * 0.5

                local corners = {
                    cframe * Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z),
                    cframe * Vector3.new(-halfSize.X, -halfSize.Y, halfSize.Z),
                    cframe * Vector3.new(-halfSize.X, halfSize.Y, -halfSize.Z),
                    cframe * Vector3.new(-halfSize.X, halfSize.Y, halfSize.Z),
                    cframe * Vector3.new(halfSize.X, -halfSize.Y, -halfSize.Z),
                    cframe * Vector3.new(halfSize.X, -halfSize.Y, halfSize.Z),
                    cframe * Vector3.new(halfSize.X, halfSize.Y, -halfSize.Z),
                    cframe * Vector3.new(halfSize.X, halfSize.Y, halfSize.Z)
                }

                local minX, minY = math.huge, math.huge
                local maxX, maxY = -math.huge, -math.huge
                local onScreenCount = 0

                for i = 1, 8 do
                    local cornerPos, cornerOnScreen = Camera:WorldToViewportPoint(corners[i])
                    if cornerOnScreen then onScreenCount = onScreenCount + 1 end
                    if cornerPos.X < minX then minX = cornerPos.X end
                    if cornerPos.X > maxX then maxX = cornerPos.X end
                    if cornerPos.Y < minY then minY = cornerPos.Y end
                    if cornerPos.Y > maxY then maxY = cornerPos.Y end
                end

                if Drawing then
                    if Toggles.TracerESP and Toggles.TracerESP.Value then
                        local hrpPos, hrpOnScreen = Camera:WorldToViewportPoint(hrp.Position)
                        if hrpOnScreen then
                            local originPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            local originType = Options.TracerOrigin and Options.TracerOrigin.Value or 'Bottom'

                            if originType == 'Center' then originPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                            elseif originType == 'Mouse' then originPos = UserInputService:GetMouseLocation() end

                            data.TracerLine.From = originPos
                            data.TracerLine.To = Vector2.new(hrpPos.X, hrpPos.Y)
                            data.TracerLine.Color = Options.TracerColor and Options.TracerColor.Value or Color3.fromRGB(255, 255, 255)
                            data.TracerLine.Visible = true
                        else
                            data.TracerLine.Visible = false
                        end
                    else
                        if data.TracerLine then data.TracerLine.Visible = false end
                    end

                    if onScreenCount > 0 then
                        local padding = 2
                        minX = minX - padding
                        maxX = maxX + padding
                        minY = minY - padding
                        maxY = maxY + padding

                        local boxWidth = maxX - minX
                        local boxHeight = maxY - minY
                        local boxPos = Vector2.new(minX, minY)

                        if Toggles.BoxESP and Toggles.BoxESP.Value then
                            data.Box.Color = Options.BoxColor and Options.BoxColor.Value or Color3.fromRGB(255, 255, 255)
                            data.Box.Size = Vector2.new(boxWidth, boxHeight)
                            data.Box.Position = boxPos
                            data.Box.Visible = true
                        else
                            data.Box.Visible = false
                        end

                        if Toggles.HealthBarESP and Toggles.HealthBarESP.Value then
                            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                            local barHeight = boxHeight
                            local barWidth = 1
                            local barX = minX - 4
                            local barY = minY

                            data.HealthBarBg.Size = Vector2.new(barWidth + 2, barHeight + 2)
                            data.HealthBarBg.Position = Vector2.new(barX - 1, barY - 1)
                            data.HealthBarBg.Visible = true

                            local currentHeight = barHeight * healthPercent
                            data.HealthBar.Size = Vector2.new(barWidth, currentHeight)
                            data.HealthBar.Position = Vector2.new(barX, barY + (barHeight - currentHeight))
                            data.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                            data.HealthBar.Visible = true
                        else
                            data.HealthBarBg.Visible = false
                            data.HealthBar.Visible = false
                        end

                        if Toggles.NameESP and Toggles.NameESP.Value then
                            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                            local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
                            data.NameText.Color = Options.NameColor and Options.NameColor.Value or Color3.fromRGB(255, 255, 255)
                            data.NameText.Text = string.format('%s [%dm]', player.Name, dist)
                            data.NameText.Position = Vector2.new(minX + (boxWidth / 2), minY - 18)
                            data.NameText.Visible = true
                        else
                            data.NameText.Visible = false
                        end

                        if Toggles.PassiveESP and Toggles.PassiveESP.Value then
                            local baseColor = Options.NameColor and Options.NameColor.Value or Color3.fromRGB(255, 255, 255)

                            if hasForceField then
                                data.PassiveText.Text = "Passive : On"
                                data.PassiveText.Color = Color3.fromRGB(0, 150, 255)
                            else
                                data.PassiveText.Text = "Passive: Off"
                                data.PassiveText.Color = baseColor
                            end

                            data.PassiveText.Position = Vector2.new(minX + (boxWidth / 2), minY - 34)
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
                                    line.Color = Options.SkeletonColor and Options.SkeletonColor.Value or Color3.fromRGB(255, 255, 255)
                                    line.From = Vector2.new(posA.X, posA.Y)
                                    line.To = Vector2.new(posB.X, posB.Y)
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
    end,
    Tooltip = 'Copies the Discord link to your clipboard',
})

local TimeLabel = SessionGroup:AddLabel('Session Time: 00:00:00', true)
local StartTime = tick()

local SessionConnection = RunService.Heartbeat:Connect(function()
    local elapsed = math.floor(tick() - StartTime)
    TimeLabel:SetText(('Session Time: %02d:%02d:%02d'):format(math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), elapsed % 60))
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
    SessionConnection:Disconnect()
    CombatConnection:Disconnect()
    VisualsConnection:Disconnect()
    if FOVConnection then FOVConnection:Disconnect() end
    WeaponModConnection:Disconnect()
    SoundModLoop:Disconnect()
    PlayerAddedConn:Disconnect()
    PlayerRemovingConn:Disconnect()
    InputBeganConn:Disconnect()
    InputEndedConn:Disconnect()
    if SkyboxLoop then SkyboxLoop:Disconnect() end
    if FirstPersonBodyLoop then FirstPersonBodyLoop:Disconnect() end

    if currentModifiedTool then RestoreWeaponStats(currentModifiedTool) end

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
