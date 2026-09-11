local MenuGroup = UISettingsTab:AddLeftGroupbox('Menu Settings')
MenuGroup:AddButton({
	Text = 'Unload',
	Func = function() Library:Unload() end
})

local MenuPicker = MenuGroup:AddLabel('Menu bind')
MenuPicker:AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind