local StateFile = nil
local StopFlag = false
local FileStatus, BuildStatus

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
		local ok, data = pcall(function()
			local raw = readfile(selected)
			if raw:match("%.%.%.%s*$") then
				error("JSON file is truncated (ends with '...')")
			end
			return HTTP:JSONDecode(raw)
		end)
		if not ok then
			Library:Notify('Load failed: ' .. tostring(data), 4)
			return
		end
		local genv = getgenv()
		genv.StarryStateFile = { Data = data, Name = selected }
		StateFile = genv.StarryStateFile

		-- Robust counter: works with both integer-keyed arrays and string-keyed tables
		-- (some executors / large JSONDecode results produce string keys, which break ipairs)
		local function countParts(items)
			local count = 0
			if type(items) ~= "table" then return 0 end
			for _, item in pairs(items) do
				if type(item) == "table" then
					if item.Position and item.Size then
						count = count + 1
					end
					if type(item.Children) == "table" then
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
	local ok, jsonData = pcall(function()
		if raw:match("%.%.%.%s*$") then
			error("JSON file is truncated")
		end
		return HTTP:JSONDecode(raw)
	end)

	if not ok then
		Library:Notify('Load failed: ' .. tostring(jsonData), 4)
		return
	end

	local partsList = {}
	-- Robust collector: works with both integer-keyed arrays and string-keyed tables
	-- (some executors / large JSONDecode results produce string keys, which break ipairs)
	local function collectParts(items)
		if type(items) ~= "table" then return end
		for _, item in pairs(items) do
			if type(item) == "table" then
				if item.Position and item.Size then
					table.insert(partsList, item)
				end
				if type(item.Children) == "table" then
					collectParts(item.Children)
				end
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
