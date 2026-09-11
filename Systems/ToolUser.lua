const pcall = pcall

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