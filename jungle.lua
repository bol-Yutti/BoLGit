-- Dependencies ----------------------------------------------------------------


require "MapPosition"
if (GetGame().map.index ~= 1) then return end
-- Code ------------------------------------------------------------------------
local EnemyJungler = nil
local lasttime = 0
local autoDisableTime = 1500  -- time in seconds until automatic disable (when lane phase ends)

function OnLoad()
	mapPosition = MapPosition()
	PrintChat(" >> Tell me enemy's jungler position loaded")
	Menu = scriptConfig("jungle", "jungle")
	Menu:addParam("jungleT", "Text Size", SCRIPT_PARAM_SLICE, 24, 1, 200, 0)
	Menu:addParam("jungleX", "X Position", SCRIPT_PARAM_SLICE, 2, 1, 2000, 0)
	Menu:addParam("jungleY", "Y Position", SCRIPT_PARAM_SLICE, 2, 1, 2000, 0)
	
for i = 1, heroManager.iCount do
 local hero = heroManager:getHero(i)
 if hero ~= nil and hero.team ~= player.team then
   if hero:GetSpellData(SUMMONER_1).name:find("smite") or hero:GetSpellData(SUMMONER_2).name:find("smite") then
      EnemyJungler = hero
   
    end
   end
 end
end


function OnDraw()	
	--DrawText("Top Lane",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 255, 222, 0))
--PrintChat("Enemy Jungler : ".. tostring(EnemyJungler))
 if GetInGameTimer() < autoDisableTime and EnemyJungler ~= nil and EnemyJungler.visible and EnemyJungler.dead == false then
  
	if MapPosition:onTopLane(EnemyJungler) then
	DrawText("Top Lane",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 255, 222, 0))
	
  if GetTickCount() >= lasttime then
		DrawText("________",Menu.jungleT,Menu.jungleX,Menu.jungleY + 20,ARGB(255, 255, 222, 0))
		lasttime = GetTickCount() + 15
	end

		 
	elseif MapPosition:onMidLane(EnemyJungler) then
		 DrawText("Mid Lane",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 255, 222, 0))
		 
		   if GetTickCount() >= lasttime then
		DrawText("________",Menu.jungleT,Menu.jungleX,Menu.jungleY + 20,ARGB(255, 255, 222, 0))
		lasttime = GetTickCount() + 15
	end
	
	elseif MapPosition:onBotLane(EnemyJungler) then
		 DrawText("Bot Lane",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 255, 222, 0))
		 
		   if GetTickCount() >= lasttime then
		DrawText("________",Menu.jungleT,Menu.jungleX,Menu.jungleY + 20,ARGB(255, 255, 222, 0))
		lasttime = GetTickCount() + 15
	end
	
	elseif MapPosition:inTopRiver(EnemyJungler) then
		 DrawText("Top River",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 255, 222, 0))
		 
		   if GetTickCount() >= lasttime then
		DrawText("________",Menu.jungleT,Menu.jungleX,Menu.jungleY + 20,ARGB(255, 255, 222, 0))
		lasttime = GetTickCount() + 15
	end
	
	elseif MapPosition:inBottomRiver(EnemyJungler) then
		 DrawText("Bot River",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 255, 222, 0))
		 
		   if GetTickCount() >= lasttime then
		DrawText("________",Menu.jungleT,Menu.jungleX,Menu.jungleY + 20,ARGB(255, 255, 222, 0))
		lasttime = GetTickCount() + 15
	end
	
	elseif MapPosition:inLeftBase(EnemyJungler) then
		 DrawText("Bot Left Base",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 255, 222, 0))
		 
		   if GetTickCount() >= lasttime then
		DrawText("____________",Menu.jungleT,Menu.jungleX,Menu.jungleY + 20,ARGB(255, 255, 222, 0))
		lasttime = GetTickCount() + 15
	end
	
	elseif MapPosition:inRightBase(EnemyJungler) then
		 DrawText("Top Right Base",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 255, 222, 0))
		 
		   if GetTickCount() >= lasttime then
		DrawText("_____________",Menu.jungleT,Menu.jungleX,Menu.jungleY + 20,ARGB(255, 255, 222, 0))
		lasttime = GetTickCount() + 15
	end
	
	elseif MapPosition:inTopLeftJungle(EnemyJungler) then
		 DrawText("Bot Blue Buff Jungle",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 5, 135, 9))
		 
		   if GetTickCount() >= lasttime then
		DrawText("_____________________",Menu.jungleT,Menu.jungleX,Menu.jungleY + 20,ARGB(255, 5, 135, 9))
		lasttime = GetTickCount() + 15
	end
	
	elseif MapPosition:inTopRightJungle(EnemyJungler) then
		DrawText("Top Red Buff Jungle",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 5, 135, 9))
		
		  if GetTickCount() >= lasttime then
		DrawText("_____________________",Menu.jungleT,Menu.jungleX,Menu.jungleY + 20,ARGB(255, 5, 135, 9))
		lasttime = GetTickCount() + 15
	end
	
	elseif MapPosition:inBottomRightJungle(EnemyJungler) then
		DrawText("Top Blue Buff Jungle",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 5, 135, 9))
		
		  if GetTickCount() >= lasttime then
		DrawText("__________________",Menu.jungleT,Menu.jungleX,Menu.jungleY + 20,ARGB(255, 5, 135, 9))
		lasttime = GetTickCount() + 15
	end
	
	elseif MapPosition:inBottomLeftJungle(EnemyJungler) then
		DrawText("Bottom Red Buff Jungle",Menu.jungleT,Menu.jungleX,Menu.jungleY,ARGB(255, 5, 135, 9))
		
		  if GetTickCount() >= lasttime then
		DrawText("_____________________",Menu.jungleT,Menu.jungleX,Menu.jungleY + 20,ARGB(255, 5, 135, 9))
		lasttime = GetTickCount() + 15
	end
		
	end
 end
end
