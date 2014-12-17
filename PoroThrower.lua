require 'VPrediction'

lastCast = 0
function OnLoad()
	PrintChat("<font color=\"#FFFFFF\">Poro Thrower Helper Version One Loaded ")
	poro = poroSlot()
	PoroMenu = scriptConfig("Poro Menu", "poro")
	PoroMenu:addParam("comboKey", "Shoot Poro", SCRIPT_PARAM_ONKEYDOWN, false, 32) 
	PoroMenu:addParam("range", "Cast Range", SCRIPT_PARAM_SLICE, 1400, 800, 2500, 0) 
	TargetSelector = TargetSelector(TARGET_CLOSEST, 2500, DAMAGE_PHYSICAL)
	PoroMenu:addTS(TargetSelector)
	vPred = VPrediction()
end

function OnTick()
	Target = getTarget()
	if (poro ~= nil) and (myHero:CanUseSpell(poro) == READY) then 
		poroRdy = true
	else
		poroRdy = false
	end
	if PoroMenu.comboKey then
		shootPoro(Target)
	end
end

function OnDraw()
	if not myHero.dead then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, PoroMenu.range, 2, ARGB(255, 0, 0, 255))
	end
end
function getTarget()
	TargetSelector:update()	
	if TargetSelector.target and not TargetSelector.target.dead and TargetSelector.target.type == myHero.type then
		return TargetSelector.target
	else
		return nil
	end
end

function poroSlot()
	if myHero:GetSpellData(SUMMONER_1).name:find("porothrow") then
		return SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("porothrow") then
		return SUMMONER_2
	else
		return nil
	end
end

function shootPoro(unit)
	if lastCast > os.clock() - 8 then return end
	
	if  ValidTarget(unit, PoroMenu.range + 50) and poroRdy then
		local CastPosition, Hitchance, Position = vPred:GetLineCastPosition(Target, .25, 75, PoroMenu.range, 1600, myHero, true)
		if CastPosition and Hitchance >= 2 then
			CastSpell(poro, CastPosition.x, CastPosition.z)
			lastCast = os.clock()
		end
	end
end
				