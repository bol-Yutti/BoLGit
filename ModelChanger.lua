_G.Model_Version = 1.1
_G.Model_Autoupdate = true
timeran = os.clock()
local script_downloadName = "Model Changer"
local script_downloadHost = "raw.github.com"
local script_downloadPath = "/Ralphlol/BoLGit/master/ModelChanger.lua" .. "?rand=" .. math.random(1, 10000)
local script_downloadUrl = "https://" .. script_downloadHost .. script_downloadPath
local script_filePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME

function script_Messager(message) print("<font color=\"#0000E5\">" .. script_downloadName .. ":</font> <font color=\"#FFFFFF\">" .. message) end

if _G.Model_Autoupdate then
	local script_webResult = GetWebResult(script_downloadHost, script_downloadPath)
	if script_webResult then
		local script_serverVersion = string.match(script_webResult, "%s*_G.Model_Version%s+=%s+%d+%.%d+")

		if script_serverVersion then
			script_serverVersion = tonumber(string.match(script_serverVersion or "", "%d+%.?%d*"))

			if not script_serverVersion then
				script_Messager("Please contact the developer of the script \"" .. script_downloadName .. "\", since the auto updater returned an invalid version.")
				return
			end

			if _G.Model_Version < script_serverVersion then
				script_Messager("New version available: " .. script_serverVersion)
				script_Messager("Updating, please don't press F9")
				DelayAction(function () DownloadFile(script_downloadUrl, script_filePath, function() script_Messager("Successfully updated the script, please reload and check the changelog!") end) end, 2)
			else
				script_Messager("You've got the latest version: " .. script_serverVersion)
			end
		else
			script_Messager("Something went wrong, update the script manually!")
		end
	else
		script_Messager("Error downloading server version!")
	end
end

ModelNames = {
	"      OFF",
	"Cupcake",
	"New Dragon",
	"Poro", 
	"Urf", 
	"Yonkey", 
	"Azir", 
	"Vision Ward", 
	"New Red", 
	"New Blue", 
	"Gromp", 
	"New Nexus", 
	"New Baron", 
	"New Turret", 
	"New Turret 2",
	"Shop",
	"Monacle Guy",
	"Shark",
	"Vilemaw",
	"Pumpkin Guy",
	"Kitty",
	"Baby Dragon",
	"Snowman",
	"Crystal Platform",
	"Some Dude 1", 
	"Some Dude 2" 
	
 }
Models = {
	"OFF",
	"LuluCupcake",
	"SRU_Dragon",
	"HA_AP_Poro",
	"Urf",
	"Yonkey",
	"Azir",
	"VisionWard",
	"SRU_Red",
	"SRU_Blue",
	"SRU_Gromp",
	"SRUAP_ChaosNexus",
	"SRU_Baron",
	"SRUAP_Turret_Order3",
	"SRUAP_Turret_Chaos2",
	"sru_storekeepersouth",
	"sru_storekeepernorth",
	"FizzShark",
	"TT_Spiderboss",
	"TT_Shopkeeper",
	"LuluKitty",
	"LuluDragon",
	"LuluSnowman",
	"crystal_platform",
	"Summoner_Rider_Order",
	"Summoner_Rider_Chaos"
}
function OnLoad()
	Menu()
	ModelChosen = 0
	Menu.skins = false
	Menu.flames = false
	Menu.model = 1
	check = 1
end

function skinsfun()
	if check == 1 then
		if timeran ~= nil then
			if timeran < os.clock() - 5 then
				if Menu.model ~= 1 then
					MakeModel(ModelChosen)	
					Menu.model = 1
				end
				
				if Menu.skins then
					MakeModel(myHero.charName)
					Menu.skins = false
				end
				if Menu.flames then
					MakeModel("TT_Brazier")
					Menu.flames = false
					DelayAction(function()
						MakeModel(myHero.charName)
					end, 1)
				end
			end
		end
	end
end

function Menu()
	Menu = scriptConfig("Model Changer", "ModelChanger")
		Menu:addParam("skins", "Change Me Back", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("flames", "Give My Hero Flames", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("model", "Change Model", SCRIPT_PARAM_LIST, 1, ModelNames)
		
		Menu:addParam("info4","", SCRIPT_PARAM_INFO, "")
		Menu:addParam("use", "Use Spells", SCRIPT_PARAM_ONOFF, true)  
		Menu:addParam("CastQ", "Cast Q", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('Q')) 
		Menu:addParam("CastW", "Cast W", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('W')) 
		Menu:addParam("CastE", "Cast E", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('E')) 
		Menu:addParam("CastR", "Cast R", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('R')) 
end

function OnTick()
	if check == 1 then
		if Menu.model ~= 0 then
			if Menu.model ~= 1 then
				ModelChosen = Models[Menu.model]
			end
		end
	end
	
	skinsfun()
	if Menu.use then
		if Menu.CastQ then
			Packet("S_CAST", { spellId = _Q}):send()
		end
		if Menu.CastW then
			Packet("S_CAST", { spellId = _W}):send()
		end
		if Menu.CastE then
			Packet("S_CAST", { spellId = _E}):send()
		end
		if Menu.CastR then
			Packet("S_CAST", { spellId = _R}):send()
		end
	end
end

function MakeModel(champ) --credits to shalzuth
	p = CLoLPacket(0x97)
	p:EncodeF(myHero.networkID)
	p.pos = 1
	t1 = p:Decode1()
	t2 = p:Decode1()
	t3 = p:Decode1()
	t4 = p:Decode1()
	p:Encode1(t1)
	p:Encode1(t2)
	p:Encode1(t3)
	p:Encode1(bit32.band(t4,0xB))
	p:Encode1(1)
	p:Encode4(0)
	for i = 1, #champ do
		p:Encode1(string.byte(champ:sub(i,i)))
	end
	for i = #champ + 1, 64 do
		p:Encode1(0)
	end
	p:Hide()
	RecvPacket(p)
end
