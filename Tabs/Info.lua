local InfoGroup = InfoTab:AddLeftGroupbox('Credits & Socials')
local SessionGroup = InfoTab:AddRightGroupbox('Session Status')

InfoGroup:AddLabel('Made by noritery', true)
InfoGroup:AddLabel('Optimized/Modularized by lua_u', true)
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

return true