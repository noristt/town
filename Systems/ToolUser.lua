const pcall = pcall

local function GetCharacter()
	local char = LocalPlayer.Character
	if not char then
		local ok, result = pcall(function()
			return LocalPlayer.CharacterAdded:Wait()
		end)
		if ok then return result end
	end
	return char
end

local function GetTool(toolName)
	local char = GetCharacter()
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

local function GetNearby(range)
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
	while task.wait(1/50) do
		const Character = GetCharacter()
		if not Character then continue end
		if AutoHealSelf then
			pcall(function()
				const _, UseRemote = GetTool("Medkit")
				if UseRemote then
					UseRemote:FireServer("heal", Character)
				end
			end)
		end
		if AutoHealNearby then
			pcall(function()
				const _, UseRemote = GetTool("Medkit")
				if UseRemote then
					for _, target in ipairs(GetNearby(50)) do
						UseRemote:FireServer("heal", target)
					end
				end
			end)
		end
		if AutoFixArmorSelf then
			pcall(function()
				const _, UseRemote = GetTool("Wrench")
				if UseRemote then
					UseRemote:FireServer("heal", Character)
				end
			end)
		end
		if AutoFixArmorNearby then
			pcall(function()
				const _, UseRemote = GetTool("Wrench")
				if UseRemote then
					for _, target in ipairs(GetNearby(50)) do
						UseRemote:FireServer("heal", target)
					end
				end
			end)
		end
	end
end)

return true