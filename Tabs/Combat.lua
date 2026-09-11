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

const TweenService = game:GetService("TweenService")
const Debris = game:GetService("Debris")

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
	
	TweenService:Create(part, TweenInfo.new(Options.BulletTracer_Lifetime.Value, Enum.EasingStyle.Quart), {Transparency = , Size = Vector3.new(0, distance, 0)}):Play()
	
	task.spawn(function()
		local a = tick()
		while part do
			local a, b = pcall(function()
				task.wait()
				local b = tick()
				local dt = b - a
				a = b
				part.CFrame *= CFrame.Angles(0, math.rad(dt*45), 0)
			end)
			if not a then
				break
			end
		end
	end)
	
	-- Safely destroy after the configured lifetime
	--task.delay(Options.BulletTracer_Lifetime.Value, function()
		--pcall(function()
			--part:Destroy()
		--end)
	--end)
	Debris:AddItem(part, Options.BulletTracer_Lifetime.Value)
end

-- 3. Hook Namecall for FireEvent
local meta = getrawmetatable(game)
local oldNamecall = meta.__namecall
setreadonly(meta, false)

meta.__namecall = newcclosure(function(self, ...)
	if self.Name == "FireEvent" then
		local args = {...}
		-- Safely attempt to parse bullet data without breaking the game if table structures change
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
		-- Force global accMult to 0 on equip if silent aim is active
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

return true