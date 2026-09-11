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
	local centerX = viewportSize.X * 0.5
	local centerY = viewportSize.Y * 0.5
	local center = Vector2_new(centerX, centerY)
	local camCFrame = Camera.CFrame
	local camPos = camCFrame.Position
	local localChar = LocalPlayer.Character
	local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")

	local showCrosshair = Toggles.Crosshair and Toggles.Crosshair.Value
	local showOnlyPassiveOff = Toggles.ShowOnlyPassiveOff and Toggles.ShowOnlyPassiveOff.Value
	local highlightESP = Toggles.HighlightESP and Toggles.HighlightESP.Value
	local wallcheckESP = Toggles.ChamsWallcheckESP and Toggles.ChamsWallcheckESP.Value
	local chamsESP = Toggles.ChamsESP and Toggles.ChamsESP.Value
	local isChamsActive = wallcheckESP or chamsESP
	local offscreenESP = Toggles.OffscreenESP and Toggles.OffscreenESP.Value
	local tracerESP = Toggles.TracerESP and Toggles.TracerESP.Value
	local boxESP = Toggles.BoxESP and Toggles.BoxESP.Value
	local healthBarESP = Toggles.HealthBarESP and Toggles.HealthBarESP.Value
	local nameESP = Toggles.NameESP and Toggles.NameESP.Value
	local passiveESP = Toggles.PassiveESP and Toggles.PassiveESP.Value
	local skeletonESP = Toggles.SkeletonESP and Toggles.SkeletonESP.Value
	local hideUsernames = Toggles.HideAllUsernames and Toggles.HideAllUsernames.Value

	local crosshairColor = (Options.CrosshairColor and Options.CrosshairColor.Value) or Color3_fromRGB(0, 255, 0)
	local fillTrans = (Options.ChamsFillTransparency and Options.ChamsFillTransparency.Value) or 0.2
	local outlineTrans = (Options.ChamsOutlineTransparency and Options.ChamsOutlineTransparency.Value) or 0.5
	local depthStyle = (Options.ChamsDepthMode and Enum.HighlightDepthMode[Options.ChamsDepthMode.Value]) or Enum.HighlightDepthMode.AlwaysOnTop
	local materialMode = (Options.ChamsMaterial and Options.ChamsMaterial.Value) or "Highlight"
	local chamsColor = (Options.ChamsColor and Options.ChamsColor.Value) or Color3_fromRGB(0, 255, 255)
	local visChamsColor = (Options.VisibleChamsColor and Options.VisibleChamsColor.Value) or Color3_fromRGB(0, 255, 0)
	local hidChamsColor = (Options.HiddenChamsColor and Options.HiddenChamsColor.Value) or Color3_fromRGB(255, 0, 0)
	local highlightColor = (Options.HighlightColor and Options.HighlightColor.Value) or Color3_fromRGB(255, 0, 0)
	local offscreenRadius = (Options.OffscreenRadius and Options.OffscreenRadius.Value) or 200
	local offscreenSize = (Options.OffscreenSize and Options.OffscreenSize.Value) or 15
	local offscreenColor = (Options.OffscreenColor and Options.OffscreenColor.Value) or Color3_fromRGB(255, 100, 100)
	local tracerOriginType = (Options.TracerOrigin and Options.TracerOrigin.Value) or "Bottom"
	local tracerColor = (Options.TracerColor and Options.TracerColor.Value) or Color3_fromRGB(255, 255, 255)
	local boxColor = (Options.BoxColor and Options.BoxColor.Value) or Color3_fromRGB(255, 255, 255)
	local nameColor = (Options.NameColor and Options.NameColor.Value) or Color3_fromRGB(255, 255, 255)
	local skeletonColor = (Options.SkeletonColor and Options.SkeletonColor.Value) or Color3_fromRGB(255, 255, 255)

	local useMaterialChams = isChamsActive and materialMode ~= "Highlight"
	local chosenMaterial = useMaterialChams and (Enum.Material[materialMode] or Enum.Material.ForceField)

	if showCrosshair then
		CrosshairH.From = Vector2_new(centerX - 8, centerY)
		CrosshairH.To = Vector2_new(centerX + 8, centerY)
		CrosshairH.Color = crosshairColor
		CrosshairH.Visible = true
		CrosshairV.From = Vector2_new(centerX, centerY - 8)
		CrosshairV.To = Vector2_new(centerX, centerY + 8)
		CrosshairV.Color = crosshairColor
		CrosshairV.Visible = true
	else
		CrosshairH.Visible = false
		CrosshairV.Visible = false
	end

	local frame = math.floor(os.clock() * 30)
	local doHeavy = (frame % 4) == 0

	for player, data in pairs(ESPCache) do
		local character = player.Character
		local hrp = data.HRP or (character and character:FindFirstChild("HumanoidRootPart"))
		local head = data.Head or (character and character:FindFirstChild("Head"))
		local humanoid = data.Humanoid or (character and character:FindFirstChildOfClass("Humanoid"))

		if not (character and hrp and humanoid and humanoid.Health > 0) then
			if data._active then
				ClearMaterialChams(character)
				ClearAllCharacterHighlights(character)
				data.ManagedHighlight = nil
				data._active = false
				data._chamsSet = false
				if data.Box then data.Box.Visible = false end
				if data.HealthBarBg then data.HealthBarBg.Visible = false end
				if data.HealthBar then data.HealthBar.Visible = false end
				if data.NameText then data.NameText.Visible = false end
				if data.PassiveText then data.PassiveText.Visible = false end
				if data.TracerLine then data.TracerLine.Visible = false end
				if data.OffscreenArrow then data.OffscreenArrow.Visible = false end
				for i = 1, #data.SkeletonLines do data.SkeletonLines[i].Visible = false end
			end
			continue
		end

		local hasForceField = character:FindFirstChildOfClass("ForceField") ~= nil

		if showOnlyPassiveOff and hasForceField then
			if data._active then
				ClearAllCharacterHighlights(character)
				data.ManagedHighlight = nil
				ClearMaterialChams(character)
				data._active = false
				data._chamsSet = false
				if data.Box then data.Box.Visible = false end
				if data.HealthBarBg then data.HealthBarBg.Visible = false end
				if data.HealthBar then data.HealthBar.Visible = false end
				if data.NameText then data.NameText.Visible = false end
				if data.PassiveText then data.PassiveText.Visible = false end
				if data.TracerLine then data.TracerLine.Visible = false end
				if data.OffscreenArrow then data.OffscreenArrow.Visible = false end
				for i = 1, #data.SkeletonLines do data.SkeletonLines[i].Visible = false end
			end
			continue
		end

		data._active = true
		local hrpPos = hrp.Position

		if isChamsActive or highlightESP then
			if doHeavy or not data._chamsSet then
				local isBlocked = data._lastBlocked or false
				if wallcheckESP then
					local targetPart = head or hrp
					sharedRaycastParams.FilterDescendantsInstances = {Camera, character, localChar}
					local result = workspace:Raycast(camPos, targetPart.Position - camPos, sharedRaycastParams)
					isBlocked = result and result.Instance and result.Instance.CanCollide and not result.Instance:IsDescendantOf(character)
					data._lastBlocked = isBlocked
				end

				local finalChamsColor = wallcheckESP and (isBlocked and hidChamsColor or visChamsColor) or chamsColor

				if useMaterialChams then
					if data._lastMatColor ~= finalChamsColor or data._lastMat ~= chosenMaterial then
						ApplyMaterialChams(character, chosenMaterial, finalChamsColor, fillTrans)
						data._lastMatColor = finalChamsColor
						data._lastMat = chosenMaterial
					end
				else
					if data._lastMat then
						ClearMaterialChams(character)
						data._lastMat = nil
						data._lastMatColor = nil
					end
				end

				local hl = data.ManagedHighlight
				if not (hl and hl.Parent == character) then
					hl = character:FindFirstChild("ManagedESPHighlight")
					if not hl then
						hl = Instance.new("Highlight")
						hl.Name = "ManagedESPHighlight"
						hl.Parent = character
					end
					data.ManagedHighlight = hl
				end

				local fillColor, outlineColor = finalChamsColor, finalChamsColor
				local calcFillTrans, calcOutlineTrans = fillTrans, outlineTrans

				if highlightESP then
					if not isChamsActive then
						fillColor = highlightColor
						outlineColor = highlightColor
						calcFillTrans = 0.5
						calcOutlineTrans = 0
					else
						outlineColor = highlightColor
						calcOutlineTrans = 0
					end
				end

				hl.FillColor = fillColor
				hl.OutlineColor = outlineColor
				hl.FillTransparency = useMaterialChams and math.clamp(fillTrans + 0.3, 0.3, 0.8) or calcFillTrans
				hl.OutlineTransparency = calcOutlineTrans
				hl.DepthMode = depthStyle
				hl.Enabled = true
				data._chamsSet = true
			end
		else
			if data._chamsSet then
				ClearMaterialChams(character)
				if data.ManagedHighlight then
					data.ManagedHighlight:Destroy()
					data.ManagedHighlight = nil
				end
				data._chamsSet = false
				data._lastMat = nil
				data._lastMatColor = nil
			end
		end

		local screenPos, onScreen = Camera:WorldToViewportPoint(hrpPos)
		local sx, sy, sz = screenPos.X, screenPos.Y, screenPos.Z
		local isOutOfBounds = sx < 0 or sx > viewportSize.X or sy < 0 or sy > viewportSize.Y or sz < 0

		if offscreenESP and (not onScreen or isOutOfBounds) then
			local relativePos = camCFrame:PointToObjectSpace(hrpPos)
			local dx, dy = relativePos.X, -relativePos.Y
			local mag = math.sqrt(dx * dx + dy * dy)
			local dirX, dirY = 0, -1
			if mag > 1e-4 then
				dirX, dirY = dx / mag, dy / mag
			end

			local ax = centerX + dirX * offscreenRadius
			local ay = centerY + dirY * offscreenRadius
			local tipX = ax + dirX * offscreenSize
			local tipY = ay + dirY * offscreenSize
			local perpX, perpY = -dirY, dirX
			local half = offscreenSize * 0.5

			data.OffscreenArrow.PointA = Vector2_new(tipX, tipY)
			data.OffscreenArrow.PointB = Vector2_new(ax + perpX * half, ay + perpY * half)
			data.OffscreenArrow.PointC = Vector2_new(ax - perpX * half, ay - perpY * half)
			data.OffscreenArrow.Color = offscreenColor
			data.OffscreenArrow.Visible = true
		elseif data.OffscreenArrow and data.OffscreenArrow.Visible then
			data.OffscreenArrow.Visible = false
		end

		if not Drawing then
			continue
		end

		if tracerESP and onScreen then
			local ox, oy
			if tracerOriginType == "Center" then
				ox, oy = centerX, centerY
			elseif tracerOriginType == "Mouse" then
				local m = UserInputService:GetMouseLocation()
				ox, oy = m.X, m.Y
			else
				ox, oy = centerX, viewportSize.Y
			end
			data.TracerLine.From = Vector2_new(ox, oy)
			data.TracerLine.To = Vector2_new(sx, sy)
			data.TracerLine.Color = tracerColor
			data.TracerLine.Visible = true
		elseif data.TracerLine and data.TracerLine.Visible then
			data.TracerLine.Visible = false
		end

		if onScreen then
			local headPos = head and head.Position or (hrpPos + Vector3_new(0, 2, 0))
			local topPoint = Camera:WorldToViewportPoint(headPos + Vector3_new(0, 0.8, 0))
			local botPoint = Camera:WorldToViewportPoint(hrpPos - Vector3_new(0, 3, 0))

			local boxHeight = math.abs(botPoint.Y - topPoint.Y)
			local boxWidth = boxHeight * 0.65
			local boxX = topPoint.X - boxWidth * 0.5
			local boxY = topPoint.Y

			if boxESP then
				data.Box.Color = boxColor
				data.Box.Size = Vector2_new(boxWidth, boxHeight)
				data.Box.Position = Vector2_new(boxX, boxY)
				data.Box.Visible = true
			else
				data.Box.Visible = false
			end

			if healthBarESP then
				local maxHealth = math.max(humanoid.MaxHealth, 1)
				local healthPercent = math.clamp(humanoid.Health / maxHealth, 0, 1)
				local barX = boxX - 4
				local currentHeight = boxHeight * healthPercent

				data.HealthBarBg.Size = Vector2_new(3, boxHeight + 2)
				data.HealthBarBg.Position = Vector2_new(barX - 1, boxY - 1)
				data.HealthBarBg.Visible = true

				data.HealthBar.Size = Vector2_new(1, currentHeight)
				data.HealthBar.Position = Vector2_new(barX, boxY + (boxHeight - currentHeight))
				data.HealthBar.Color = Color3_fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
				data.HealthBar.Visible = true
			else
				data.HealthBarBg.Visible = false
				data.HealthBar.Visible = false
			end

			if nameESP then
				local dist = localHRP and math.floor((localHRP.Position - hrpPos).Magnitude) or 0
				data.NameText.Color = nameColor
				data.NameText.Text = (hideUsernames and "[Hidden]" or player.Name) .. " [" .. dist .. "m]"
				data.NameText.Position = Vector2_new(boxX + boxWidth * 0.5, boxY - 18)
				data.NameText.Visible = true
			else
				data.NameText.Visible = false
			end

			if passiveESP then
				if hasForceField then
					data.PassiveText.Text = "Passive : On"
					data.PassiveText.Color = Color3_fromRGB(0, 150, 255)
				else
					data.PassiveText.Text = "Passive: Off"
					data.PassiveText.Color = nameColor
				end
				data.PassiveText.Position = Vector2_new(boxX + boxWidth * 0.5, boxY - 34)
				data.PassiveText.Visible = true
			else
				data.PassiveText.Visible = false
			end
		else
			if data.Box and data.Box.Visible then data.Box.Visible = false end
			if data.HealthBarBg and data.HealthBarBg.Visible then data.HealthBarBg.Visible = false end
			if data.HealthBar and data.HealthBar.Visible then data.HealthBar.Visible = false end
			if data.NameText and data.NameText.Visible then data.NameText.Visible = false end
			if data.PassiveText and data.PassiveText.Visible then data.PassiveText.Visible = false end
		end

		if skeletonESP then
			local bones = (humanoid.RigType == Enum.HumanoidRigType.R15) and R15_6Joint_Skeleton or R6_6Joint_Skeleton
			local lines = data.SkeletonLines
			local lineIdx = 1

			for i = 1, #bones do
				local connection = bones[i]
				local partA = character:FindFirstChild(connection[1])
				local partB = character:FindFirstChild(connection[2])
				if partA and partB then
					local posA, visA = Camera:WorldToViewportPoint(partA.Position)
					local posB, visB = Camera:WorldToViewportPoint(partB.Position)
					if visA and visB and lines[lineIdx] then
						local line = lines[lineIdx]
						line.Color = skeletonColor
						line.From = Vector2_new(posA.X, posA.Y)
						line.To = Vector2_new(posB.X, posB.Y)
						line.Visible = true
						lineIdx += 1
					end
				end
			end

			for i = lineIdx, #lines do
				lines[i].Visible = false
			end
		else
			for i = 1, #data.SkeletonLines do
				data.SkeletonLines[i].Visible = false
			end
		end
	end
end)

return true