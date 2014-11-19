if GetSpellData(SUMMONER_1).name:lower() ~= "summonerexhaust" and GetSpellData(SUMMONER_2).name:lower() ~= "summonerexhaust"
then return end
local ts
local EXHAUST = nil

function AutoExhaust()
	if Menu.Exhaust then
		if ts.target ~= nil and ValidTarget(ts.target, 650) and (EXHAUST and myHero:CanUseSpell(EXHAUST) == READY or false) then
				CastSpell(EXHAUST, ts.target)							
		end
	end
end

function OnLoad()
	
	ts = TargetSelector(TARGET_PRIORITY,650)
	Menu = scriptConfig("Auto Exhaust", "AutoExhaust")
	Menu:addParam("Exhaust", "Exhaust Key", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('F'))
	Menu:addTS(ts)

	EXHAUST = ExhaustSlot()
end
function ExhaustSlot()
	if myHero:GetSpellData(SUMMONER_1).name:find("summonerexhaust") then
		return SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerexhaust") then
		return SUMMONER_2
	else
		return nil
	end
end
function OnTick()

ts:update()
AutoExhaust()

end

