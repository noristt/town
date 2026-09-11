const AutoUpdate = true -- change this to false if you only want it to use the locally saved code

const function HGet(url: string)
	local ret = request({
		Url = url,
		Method = "GET",
		Headers = {
			["Cache-Control"] = "no-cache"
		}
	})

	return ret.Body
end

if not isfolder("SkidWare") then
	makefolder("SkidWare")
end

BaseURL = "https://raw.githubusercontent.com/ToesOfTexasHoldem/Code/refs/heads/main/"
const Url = BaseURL .. "main.lua"
const Path = "SkidWare/main.lua"
local Code = ""

if AutoUpdate then
	Code = HGet(Url)
	writefile(Path, Code)
else
	Code = readfile(Path)
end

loadstring(Code, "Skidware-Main")(AutoUpdate)