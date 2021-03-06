require 'VPrediction'

lastCast = 0
function OnLoad()
	PrintChat("<font color=\"#FFFFFF\">Poro Thrower Helper Version Three Loaded ")
	poro = poroSlot()
	PoroMenu = scriptConfig("Poro Menu", "poro")
	PoroMenu:addParam("comboKey", "Shoot Poro", SCRIPT_PARAM_ONKEYDOWN, false, 32) 
	PoroMenu:addParam("range", "Cast Range", SCRIPT_PARAM_SLICE, 1400, 800, 2500, 0) 
	TargetSelector = TargetSelector(TARGET_CLOSEST, 2500, DAMAGE_PHYSICAL)
	PoroMenu:addTS(TargetSelector)
	vPred = VPrediction()
end

function OnTick()
--print(myHero:GetSpellData(SUMMONER_1).name)
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
	if hit() then
		DrawText3D("Poro Target Hit!", myHero.x +95, myHero.y + 305, myHero.z+33, 40, RGB(255, 69, 111), true)
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

function hit()
	if myHero:GetSpellData(SUMMONER_1).name:find("porothrowfollowupcast") then
		return true
	elseif myHero:GetSpellData(SUMMONER_2).name:find("porothrowfollowupcast") then
		return true
	else
		return false
	end
end

function shootPoro(unit)
	if lastCast > os.clock() - 10 then return end
	
	if  ValidTarget(unit, PoroMenu.range + 50) and poroRdy then
		local CastPosition, Hitchance, Position = vPred:GetLineCastPosition(Target, .25, 75, PoroMenu.range, 1200, myHero, true)
		if CastPosition and Hitchance >= 2 then
			local CastPosition = pPrediction(unit, 1200, 0.25)
			CastSpell(poro, CastPosition.x, CastPosition.z)
			lastCast = os.clock()
		end
	end
end
				
function pPrediction(unit, speed, delay) --PewPewPew Prediction
 if unit == nil then return end
 local pathPot = (unit.ms*(GetDistance(unit.pos)/speed))+ delay
 local pathSum = 0
 local pathHit = nil
 local pathPoints = unit.path
 for i=1, unit.pathCount do
  local pathEnd = unit:GetPath(i)
  if pathEnd then
   if unit:GetPath(i-1) then
    local iPathDist = GetDistance(unit:GetPath(i-1), pathEnd)
    pathSum = pathSum + iPathDist
    if pathSum > pathPot and pathHit == nil then
     pathHit = unit:GetPath(i)
     local l = (pathPot-(pathSum-iPathDist))
     local v = Vector(unit:GetPath(i-1)) + (Vector(unit:GetPath(i))-Vector(unit:GetPath(i-1))):normalized()*l
     --predDebug = v
     return v
    end
   end
  end
 end
 return unit.pos
end