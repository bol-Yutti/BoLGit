function OnLoad()
	print("<font color=\"#A51842\">Ralphlol's Utility Suite:  </font><font color=\"#FFFFFF\"> Version 1.0 Loaded")
	MainMenu = scriptConfig("UtilitySuite", "UtilitySuite")
	turrets = GetTurrets()
	missCS()
	jungle()
	Secret()
	wardBush()
end
	 
class 'missCS'

function missCS:__init()
	self.additionalRange = 300			-- Default scans minions that die in your attack range. You can add range here.
	self.minionsMissed = 0
	self.checkedMinions = {}
	self.lastGold = 0
	self.weKilledIt = false
	self.minionArray = { team_ally ="##", team_ennemy ="##" }
	self.minionArray.jungleCreeps = {}
	self.minionArray.ennemyMinion = {}
	self.minionArray.allyMinion = {}
	self.minionArray.team_ally = "Minion_T"..player.team
	self.minionArray.team_ennemy = "Minion_T"..(player.team == TEAM_BLUE and TEAM_RED or TEAM_BLUE)
	self.csM = self:Menu()
	
	AddCreateObjCallback(function(obj) self:OnCreateObj(obj) end)
	AddDeleteObjCallback(function(obj) self:OnDeleteObj(obj) end)
	AddRecvPacketCallback(function(p) self:RecvPacket(p) end)
	AddDrawCallback(function() self:Draw() end)
	AddTickCallback(function() self:Tick() end)
end
function missCS:Menu()
	MainMenu:addSubMenu('Missed CS Counter', 'cs')
	local csM = MainMenu.cs
	csM:addParam("enable", "Enable",SCRIPT_PARAM_ONOFF, true)
	csM:addParam("drawX", "X Position", SCRIPT_PARAM_SLICE, 2, 1, 2000, 0)
	csM:addParam("drawY", "Y Position", SCRIPT_PARAM_SLICE, 100, 1, 2000, 0)	

	return csM
end

function missCS:getDeadMinion()
	for name, objectTableObject in pairs(self.minionArray["ennemyMinion"]) do
		if objectTableObject ~= nil and objectTableObject.dead and objectTableObject.visible and GetDistance(objectTableObject) <= self.getAttackRange() + self.additionalRange and not self.checkedMinions[objectTableObject] then
			return objectTableObject
		end
	end
	return nil
end

function missCS:Draw()
	if self.csM.enable then
		DrawText("Failed last hits: "..self.minionsMissed, 30, self.csM.drawX, self.csM.drawY, 0xFFFFFF00)
	end
end
function missCS:Tick()
	local deadMinion = self:getDeadMinion()
	if deadMinion then
		if not self:isGoldFromMinion(deadMinion) then
			self.minionsMissed = self.minionsMissed + 1
		end
		self.checkedMinions[deadMinion] = true
	end
end
function missCS:OnCreateObj(object)
	if object ~= nil and object.type == "obj_AI_Minion" and not object.dead then
		if self.minionArray.allyMinion[object.name] ~= nil or self.minionArray.ennemyMinion[object.name] ~= nil or self.minionArray.allyMinion[object.name] ~= nil then return end
		if string.find(object.name,self.minionArray.team_ally) then 
			self.minionArray.allyMinion[object.name] = object
		elseif string.find(object.name,self.minionArray.team_ennemy) then 
			self.minionArray.ennemyMinion[object.name] = object
		else 
			self.minionArray.jungleCreeps[object.name] = object
		end
	end
end
function missCS:OnDeleteObj(object)
	if object ~= nil and object.type == "obj_AI_Minion" and object.name ~= nil then
		if self.minionArray.jungleCreeps[object.name] ~= nil then 
			self.minionArray.jungleCreeps[object.name] = nil
		elseif self.minionArray.ennemyMinion[object.name] ~= nil then 
			self.minionArray.ennemyMinion[object.name] = nil
		elseif self.minionArray.allyMinion[object.name] ~= nil then 
			self.minionArray.allyMinion[object.name] = nil
		end
	if self.checkedMinions[object] then self.checkedMinions[object] = nil end
	end
end
function missCS:getAttackRange()
	return myHero.range + GetDistance(myHero, myHero.minBBox) 
end
function missCS:RecvPacket(p)
	if p.header == 281 then
		self.lastGold = os.clock()
	end
end

function missCS:isGoldFromMinion(minion)
	if minion ~= nil then
		if self.lastGold > os.clock() - 0.2 then
			return true
		else
			return false
		end
	end
end


class 'jungle'

function jungle:__init()
	require "MapPosition"
	require "VPrediction"
	
	self.sEnemies = GetEnemyHeroes()
	self.sAllies = GetAllyHeroes()
	self.vPred = VPrediction()
	self.MapPosition = MapPosition()
	self.EnemyJungler = nil
	self.lasttime = 0
	self.autoDisableTime = 1500  -- time in seconds until automatic disable (when lane phase ends)
	self.JungleGank = 0
	self.TimeMissing = {}
	self.SurprizeTime = {}
	self.DistanceToEnemy = {}
	self.EnemyVisible = {}
	self.Drawed = {}
	self.LastDraw = {}
	self.EnemyDead = {}
	self.Appeared = {}
	self.Dissapeared = {}
	for i, Enemy in pairs(self.sEnemies) do
		self.EnemyVisible[i] = Enemy.visible
		self.DistanceToEnemy[i] = myHero:GetDistance(Enemy)
		self.TimeMissing[i] = 0
		self.SurprizeTime[i] = 0
		self.Appeared[i] = false
		self.Drawed[i] = false
		self.LastDraw[i] = 0
		self.EnemyDead[i] = false
		self.Dissapeared[i] = false
	end    
	self.jM = self:Menu()
	for i = 1, heroManager.iCount do
		local hero = heroManager:getHero(i)
		if hero ~= nil and hero.team ~= player.team then
			if hero:GetSpellData(SUMMONER_1).name:lower():find("smite") or hero:GetSpellData(SUMMONER_2).name:lower():find("smite") then
				self.EnemyJungler = hero
			end
		end
	end
	
	AddDrawCallback(function() self:Draw() end)
	if GetRegion() ~= "unk" then
		AddNewPathCallback(function(unit, startPos, endPos, isDash ,dashSpeed,dashGravity, dashDistance) self:OnNewPath(unit, startPos, endPos, isDash, dashSpeed, dashGravity, dashDistance) end)
		AddIssueOrderCallback(function(unit,iAction,targetPos,targetUnit) self:OnIssueOrder(unit,iAction,targetPos,targetUnit) end)
	end
	AddTickCallback(function() self:Tick() end)
end

function jungle:Tick()
    if not self.jM.enable then return end
	for i, Enemy in pairs(self.sEnemies) do
		if self.EnemyVisible[i] then
			if not self.Appeared[i] then
				self.SurprizeTime[i] = os.clock() + 8
				self.Appeared[i] = true
			end
			self. Dissapeared[i] = false
		end
		if self.EnemyVisible[i] == false then
			if not self.Dissapeared[i] then
				self.TimeMissing[i] = os.clock() + 15
				self.Dissapeared[i] = true
			end
			self.Drawed[i] = false
			self. Appeared[i] = false
		end
	end
end
function jungle:Menu()
	MainMenu:addSubMenu('Jungler', 'Jungler')
	local jM = MainMenu.Jungler
	
	self.sEnemies = GetEnemyHeroes()
	jM:addParam("enable", "Enable",SCRIPT_PARAM_ONOFF, true)
	jM:addParam("wp", "Draw Waypoints",SCRIPT_PARAM_ONOFF,true)
	jM:addParam("jungleT", "Text Size", SCRIPT_PARAM_SLICE, 24, 1, 200, 0)
	jM:addParam("jungleX", "X Position", SCRIPT_PARAM_SLICE, 2, 1, 2000, 0)
	jM:addParam("jungleY", "Y Position", SCRIPT_PARAM_SLICE, 2, 1, 2000, 0)	

	return jM
end
function jungle:OnIssueOrder(unit,iAction,targetPos,targetUnit)
	if unit == self.EnemyJungler then
		if targetUnit == myHero then
			print("Jungler has targeted you")
		end
	end
end
function jungle:OnNewPath(unit, startPos, endPos, isDash, dashSpeed ,dashGravity, dashDistance)
	if unit == self.EnemyJungler and self.JungleGank - 10 < os.clock() then
		if GetDistance(myHero, endPos) < 500 or (GetDistance(myHero, endPos) < 1300  and GetDistance(unit) > 1600) then
			self.JungleGank = os.clock()
			--self:RecPing(myHero.x,myHero.z,0x02)
			--self:RecPing(myHero.x,myHero.z,0x01)
			--self:RecPing(myHero.x,myHero.z,0x03)
			--self:RecPing(myHero.x,myHero.z,0x05)
		end
	end
end

function jungle:RecPing(x,z,pingtype)
  packet = CLoLPacket(0x60)
  packet.dwArg1 = 1
  packet.dwArg2 = 0
  for i=1, 8 do
    packet:Encode1(0) 
  end
  packet:Encode1(pingtype) -- <== Ping Type
  packet:EncodeF(myHero.networkID) 
  packet:EncodeF(x) 
  packet:EncodeF(z) 
  packet:Encode1(0xB) 
  packet:EncodeF(GetGameTimer()) 
  RecvPacket(packet) 
end

function jungle:Draw()	
	for name, tower in pairs(turrets) do
        if tower.object and tower.object.team ~= myHero.team and GetDistance(tower.object) < 1500 then
			DrawCircle3D(tower.object.x, tower.object.y, tower.object.z, 875, 4, ARGB(80, 32,178,100), 52)
        end
    end
	if not self.jM.enable then return end
	for i, Enemy in pairs(self.sEnemies) do
		if Enemy ~= self.EnemyJungler and ValidTarget(Enemy, 3000) and os.clock() > self.TimeMissing[i] and os.clock() < self.SurprizeTime[i] then
			if self.Drawed[i] then
				if os.clock() < self.LastDraw[i] then
					local width =((os.clock() - math.floor(os.clock()))*4)+4
					local distance = GetDistance(Enemy) / 3000
					DrawLine3D(myHero.x, myHero.y, myHero.z, Enemy.pos.x, Enemy.pos.y, Enemy.pos.z, width,ARGB(255,255 - 255*distance,255*distance,0))
				end
			else
				self.LastDraw[i] = os.clock() + 5
				self.Drawed[i] = true
			end
		end		
	end
	if self.jM.wp then
		for _, enemy in pairs(self.sEnemies) do
			if ValidTarget(enemy) then
				self.vPred:DrawSavedWaypoints(enemy, 0, ARGB(255, 255, 0, 0))
			end
		end
		for _, ally in pairs(self.sAllies) do
			if ValidTarget(ally) then
				self.vPred:DrawSavedWaypoints(ally, 0, ARGB(255, 0, 255, 0))
			end
		end
	end
	local color = ARGB(255, 255, 6, 0)
	--DrawText("Top Lane",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY, color)

	--PrintChat("Enemy Jungler : ".. tostring(EnemyJungler))
	
	
	if  self.EnemyJungler and self.EnemyJungler.visible and not self.EnemyJungler.dead then
		if GetDistance(self.EnemyJungler) < 3000 then
			local width =((os.clock() - math.floor(os.clock()))*4)+4
			local distance = GetDistance(self.EnemyJungler) / 3000
			DrawLine3D(myHero.x, myHero.y, myHero.z, self.EnemyJungler.x, self.EnemyJungler.y, self.EnemyJungler.z, width,ARGB(255,255 - 255*distance,255*distance,0))
		end
		if self.JungleGank > os.clock() - 10 then
			DrawText("GANK ALERT",self.jM.jungleT+5,self.jM.jungleX,self.jM.jungleY,ARGB(255, 255, 0, 0))
			if GetTickCount() >= self.lasttime then
				DrawText("____________",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY + 20,color)
				self.lasttime = GetTickCount() + 15
			end
			return true
		end
		local color
		if GetDistance(self.EnemyJungler) > 6200 then
			color = ARGB(255, 5, 185, 9)
		elseif GetDistance(self.EnemyJungler) > 2500 then
			color = ARGB(255, 255, 222, 0)
		else
			color = ARGB(255, 255, 50, 0)
		end
		if self.MapPosition:onTopLane(self.EnemyJungler) then
			DrawText("Top Lane",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY,color )
		elseif self.MapPosition:onMidLane(self.EnemyJungler) then
			 DrawText("Mid Lane",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY,color)
		elseif self.MapPosition:onBotLane(self.EnemyJungler) then
			 DrawText("Bot Lane",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY,color)
		elseif self.MapPosition:inTopRiver(self.EnemyJungler) then
			 DrawText("Top River",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY,color)
		elseif self.MapPosition:inBottomRiver(self.EnemyJungler) then
			 DrawText("Bot River",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY,color)
		elseif self.MapPosition:inLeftBase(self.EnemyJungler) then
			 DrawText("Bot Left Base",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY,color)
		elseif self.MapPosition:inRightBase(self.EnemyJungler) then
			 DrawText("Top Right Base",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY,color)
		elseif self.MapPosition:inTopLeftJungle(self.EnemyJungler) then
			 DrawText("Bot Blue Buff Jungle",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY,color)
		elseif self.MapPosition:inTopRightJungle(self.EnemyJungler) then
			DrawText("Top Red Buff Jungle",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY,color)
		elseif self.MapPosition:inBottomRightJungle(self.EnemyJungler) then
			DrawText("Top Blue Buff Jungle",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY,color)
		elseif self.MapPosition:inBottomLeftJungle(self.EnemyJungler) then
			DrawText("Bottom Red Buff Jungle",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY,color)
		end
		if GetTickCount() >= self.lasttime then
			DrawText("__________",self.jM.jungleT,self.jM.jungleX,self.jM.jungleY + 20,color)
			lasttime = GetTickCount() + 15
		end
	end
end

class 'wardBush'

function wardBush:__init()
	self.sEnemies = GetEnemyHeroes()
	self.lastpos={}
	self.lasttime={}
	self.next_wardtime=0	--NEXT TIME TO CAST WARD
	self.wM = self:Menu()
	for _,c in pairs(self.sEnemies) do
		self.lastpos[ c.networkID ] = Vector(c)
	end
	self.BuffNames = {"rengarr", "monkeykingdecoystealth", "talonshadowassaultbuff", "vaynetumblefade", "twitchhideinshadows", "khazixrstealth", "akaliwstealth"}

	--[[Callbacks]]--
	if GetRegion() ~= "unk" then
		AddNewPathCallback(function(unit, startPos, endPos, isDash ,dashSpeed,dashGravity, dashDistance) self:OnNewPath(unit, startPos, endPos, isDash, dashSpeed, dashGravity, dashDistance) end)
	end
	AddTickCallback(function() self:Tick() end)
	AddProcessSpellCallback(function(unit, spell) self:ProcessSpell(unit, spell) end)
	--AddCreateObjCallback(function(obj) self:CreateObj(obj) end)
	AddApplyBuffCallback(function(unit, buff) self:ApplyBuff(unit, buff) end)
end
function wardBush:Menu()
	MainMenu:addSubMenu('Ward Bush', 'wardbush')
	wM = MainMenu.wardbush
	wM:addParam("enable", "Enable",SCRIPT_PARAM_ONOFF, true)
	wM:addParam("active","Key Activation",SCRIPT_PARAM_ONKEYDOWN, false, 32)
	wM:addParam("always","Always On",SCRIPT_PARAM_ONOFF,false)
	wM:addParam("maxT","Max Time to check missing Enemy",SCRIPT_PARAM_SLICE, 2, 1, 10)
	return wM
end
function wardBush:ApplyBuff(unit, buff)
	if not unit or not buff then return end
	if unit.team ~= myHero.team then
		if wM.always or wM.active then 
			for _, buffN in pairs(self.BuffNames) do		
				if buff.name:lower():find(buffN) then
					self:Check(unit, false)
				end
			end
		end
	end
end
function wardBush:ProcessSpell(unit, spell)
	if unit.team ~= myHero.team then
		if spell.name:lower():find("deceive") then
			self:Check(unit, false, spell.endPos)
		end
	end
end
function wardBush:Tick()
	if not self.wM.enable then return end
	for _,c in pairs(self.sEnemies) do		
		if c.visible then
			self.lastpos [ c.networkID ] = Vector(c) 
			self.lasttime[ c.networkID ] = os.clock() 
		elseif not c.dead and not c.visible then
			if wM.always or wM.active then 
				self:Check(c, true)
			end
		end
	end
end
function wardBush:Check(c, bush, cPos)
	local time=self.lasttime[ c.networkID ]  --last seen time
	local pos = cPos and cPos or self.lastpos [ c.networkID ]   --last seen pos
	local clock=os.clock()
	if time and pos and clock-time <wM.maxT and clock>self.next_wardtime and GetDistanceSqr(pos)<1000*1000 then
		local castPos, WardSlot
		if bush then
			castPos = self:FindBush(pos.x,pos.y,pos.z,100)
			if castPos and GetDistanceSqr(castPos)<600*600 then
				WardSlot = self:Item(bush)
			end
		else
			castPos = pos
			if GetDistanceSqr(castPos) < 600*600 then
				WardSlot = self:Item(bush)
			elseif GetDistanceSqr(castPos) < 900*900 then
				castPos = Vector(myHero) +  Vector(Vector(castPos) - Vector(myHero)):normalized()* 575
				WardSlot = self:Item(bush)
			end
		end
		if WardSlot then
			CastSpell(WardSlot,castPos.x,castPos.z)
			self.next_wardtime=clock+35
			return
		end
	end
end
function wardBush:Item(bush)
	local WardSlot = nil
	if bush then
		if GetInventorySlotItem(2045) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(2045)) == READY then
			WardSlot = GetInventorySlotItem(2045)
		elseif GetInventorySlotItem(2049) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(2049)) == READY then
			WardSlot = GetInventorySlotItem(2049)
		elseif myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3340 or myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3350 or myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3361 or myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3362 then
			WardSlot = ITEM_7
		elseif GetInventorySlotItem(2044) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(2044)) == READY then
			WardSlot = GetInventorySlotItem(2044)
		elseif GetInventorySlotItem(2043) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(2043)) == READY then
			WardSlot = GetInventorySlotItem(2043)
		end
	else
		if myHero:CanUseSpell(ITEM_7) == READY and (myHero:getItem(ITEM_7).id == 3364 or myHero:getItem(ITEM_7).id == 3362) then
			WardSlot = ITEM_7
		elseif GetInventorySlotItem(2043) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(2043)) == READY then
			WardSlot = GetInventorySlotItem(2043)
		end
	end
	return WardSlot
end
function wardBush:OnNewPath(unit, startPos, endPos, isDash, dashSpeed, dashGravity, dashDistance)
	if unit.team ~= myHero.team and isDash then
		self.lastpos[unit.networkID]= Vector(endPos)
	end
end
function wardBush:FindBush(x0, y0, z0, maxRadius, precision) --returns the nearest non-wall-position of the given position(Credits to gReY)
    
    --Convert to vector
    local vec = D3DXVECTOR3(x0, y0, z0)
    
    --If the given position it a non-wall-position return it
	--if IsWallOfGrass(vec) then
	--	print("#1")
	--	return vec 
	--end
    
    --Optional arguments
    precision = precision or 50
    maxRadius = maxRadius and math.floor(maxRadius / precision) or math.huge
    
    --Round x, z
    x0, z0 = math.round(x0 / precision) * precision, math.round(z0 / precision) * precision

    --Init vars
    local radius = 2
    
    --Check if the given position is a non-wall position
    local function checkP(x, y) 
        vec.x, vec.z = x0 + x * precision, z0 + y * precision 
        return IsWallOfGrass(vec) 
    end
    
    --Loop through incremented radius until a non-wall-position is found or maxRadius is reached
    while radius <= maxRadius do
        --A lot of crazy math (ask gReY if you don't understand it. I don't)
        if checkP(0, radius) or checkP(radius, 0) or checkP(0, -radius) or checkP(-radius, 0) then 
			--print("#2:"..radius)
            return vec 
        end
        local f, x, y = 1 - radius, 0, radius
        while x < y - 1 do
            x = x + 1
            if f < 0 then 
                f = f + 1 + 2 * x
            else 
                y, f = y - 1, f + 1 + 2 * (x - y)
            end
            if checkP(x, y) or checkP(-x, y) or checkP(x, -y) or checkP(-x, -y) or 
               checkP(y, x) or checkP(-y, x) or checkP(y, -x) or checkP(-y, -x) then 
			--	print("#3:"..radius)
                return vec 
            end
        end
        --Increment radius every iteration
        radius = radius + 1
    end
end

assert(load(Base64Decode("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AAAAAAAQAAAAQG9iZnVzY2F0ZWQubHVhANoAAAAWAAAAFgAAABYAAAAWAAAAFgAAABYAAAAXAAAAFwAAABcAAAAXAAAAFwAAABcAAAAXAAAAFwAAABsAAAAbAAAAGwAAABsAAAAbAAAAGwAAABsAAAAbAAAAGwAAABsAAAAbAAAAGwAAABsAAAAbAAAAGwAAABsAAAAbAAAAGwAAABsAAAAbAAAAGwAAABsAAAAbAAAAGwAAABsAAAAbAAAAHAAAABwAAAAcAAAAHAAAABwAAAAcAAAAHAAAABwAAAAcAAAAHQAAAB4AAAAfAAAAHwAAAB8AAAAfAAAAHwAAAB8AAAAfAAAAHwAAAB8AAAAfAAAAHwAAAB8AAAAfAAAAHwAAAB8AAAAfAAAAHwAAAB8AAAAfAAAAHwAAAB0AAAAfAAAAHwAAACEAAAAhAAAAIQAAACEAAAAhAAAAIQAAACEAAAAhAAAAIQAAACEAAAAhAAAAIgAAACIAAAAjAAAAIwAAACMAAAAjAAAAIgAAACMAAAAjAAAAIwAAACMAAAAiAAAAIwAAACMAAAAjAAAAJAAAACQAAAAkAAAAJAAAACQAAAAkAAAAJAAAACQAAAAkAAAAJAAAACQAAAAkAAAAJAAAACQAAAAkAAAAJAAAACQAAAAkAAAAJAAAACUAAAAlAAAAJQAAACUAAAAnAAAAJwAAACcAAAAnAAAAJwAAACcAAAAnAAAAJwAAACcAAAAnAAAAKAAAACgAAAApAAAAKQAAACkAAAAoAAAAKQAAACkAAAApAAAAKQAAACgAAAApAAAAKQAAACkAAAAqAAAAKgAAACoAAAAqAAAAKgAAACoAAAAqAAAAKgAAACoAAAAqAAAAKwAAACsAAAArAAAAKwAAACsAAAArAAAAKwAAACsAAAAqAAAAJQAAACUAAAAsAAAALAAAACwAAAAsAAAALgAAAC4AAAAuAAAALgAAAC4AAAAuAAAALgAAAC4AAAAuAAAALgAAAC8AAAAvAAAAMAAAADAAAAAwAAAALwAAADAAAAAwAAAAMAAAADAAAAAvAAAAMAAAADAAAAAwAAAAMQAAADEAAAAxAAAAMQAAADEAAAAxAAAAMQAAADEAAAAxAAAAMQAAADEAAAAxAAAAMgAAADIAAAAyAAAAMgAAADIAAAAyAAAAMQAAACwAAAAsAAAAMgAAAA4AAAAFAAAAc2VsZgAAAAAA2gAAAAIAAABhAGQAAADZAAAAEAAAAChmb3IgZ2VuZXJhdG9yKQB6AAAAqAAAAAwAAAAoZm9yIHN0YXRlKQB6AAAAqAAAAA4AAAAoZm9yIGNvbnRyb2wpAHoAAACoAAAAAgAAAGIAewAAAKYAAAACAAAAYwB7AAAApgAAAAIAAABkAJMAAACmAAAAEAAAAChmb3IgZ2VuZXJhdG9yKQCrAAAA2QAAAAwAAAAoZm9yIHN0YXRlKQCrAAAA2QAAAA4AAAAoZm9yIGNvbnRyb2wpAKsAAADZAAAAAgAAAGIArAAAANcAAAACAAAAYwCsAAAA1wAAAAIAAABkAMQAAADXAAAAAQAAAAUAAABfRU5WAAEAAAABABAAAABAb2JmdXNjYXRlZC5sdWEAEwAAAAEAAAABAAAAAQAAAAIAAAAKAAAAAgAAAAsAAAAOAAAACwAAAA8AAAAPAAAADwAAABAAAAAVAAAAEAAAABYAAAAyAAAAFgAAADIAAAAAAAAAAQAAAAUAAABfRU5WAA=="), nil, "bt", _ENV))()