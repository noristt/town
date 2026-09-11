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

local CoreGui = game:GetService("CoreGui")

local function CreateSeatGUI(seat: Seat)
	if not seat or not seat:IsA('BasePart') then return end
	if ActiveSeatGUIs[seat] then return end

	local bg = Instance.new('BillboardGui')
	bg.Name = 'SeatTPGui'
	bg.AlwaysOnTop = true
	bg.Adornee = seat
	bg.Size = UDim2.new(0, 30, 0, 30)
	bg.StudsOffset = Vector3.new(0, 2.5, 0)
	bg.Active = true
	bg.Parent = CoreGui

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
			--hrp.CFrame = seat.CFrame + Vector3.new(0, 3, 0)
			seat:Sit(char.Humanoid)
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

setscriptable(workspace.Terrain, "Decoration", true)

WorldGroup:AddToggle("No Grass", {
	Text = 'No Grass',
	Default = false,
	Callback = function(Value)
		workspace.Terrain.Decoration = not Value
	end,
})

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

return true