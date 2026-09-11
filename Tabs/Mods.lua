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
						-- Optional tracking tag if needed, or rely on toggle state cleanup
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

return true