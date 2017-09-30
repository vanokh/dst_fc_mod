local randomSpawn = require("filecommands/randomSpawn")
local startApoEvents = require("filecommands/startApo")

local Commands = Class(function(self, name)
    self.name = name or ""
    self.filepath = "C:\\temp\\cmd.txt"
    self.enable_log = nil
    self.lastline = -1

    self:EnableLog(true)
end)

local function getunknownposition(radius)
    local ground = TheWorld
    local centers = {}
    local maxx, maxy = 0, 0
    for i, node in ipairs(ground.topology.nodes) do
      if node.x > maxx then maxx = node.x end
      if node.y > maxy then maxy = node.y end
    end
    local corners = {{x=-maxx,y=-maxy},{x=-maxx,y=maxy},{x=maxx,y=-maxy},{x=maxx,y=maxy}}
    for _,c in pairs(corners) do
      if not ground.Map:IsPassableAtPoint(c.x, 0, c.y) and #TheSim:FindEntities(c.x, 0, c.y, radius or 20) <= 0 then
        return Point(c.x, 0, c.y)
      end
    end
    print("Place for arena not found")
end

--from purple staff in prefabs/staff.lua
local function getrandomposition(caster)
    local ground = TheWorld
    local centers = {}
    for i, node in ipairs(ground.topology.nodes) do
        if ground.Map:IsPassableAtPoint(node.x, 0, node.y) then
            table.insert(centers, {x = node.x, z = node.y})
        end
    end
    if #centers > 0 then
        local pos = centers[math.random(#centers)]
        return Point(pos.x, 0, pos.z)
    else
        return caster:GetPosition()
    end
end

local function teleportPlayer(player, loc)
	local t_loc = loc or getrandomposition(player)
  if player.Physics ~= nil then
      player.Physics:Teleport(t_loc.x, 0, t_loc.z)
  else
      player.Transform:SetPosition(t_loc.x, 0, t_loc.z)
  end
	player:SnapCamera()
	SpawnPrefab("spawn_fx_medium").Transform:SetPosition(t_loc:Get())
	player:DoTaskInTime(0.5, function()
		player:Show()
	end)
	player:ScreenFade(true, 1)
end

function teleportRandom()
  if isArenaActive() then
    teleportToArena()
  else
    for _,v in pairs(AllPlayers) do
      SpawnPrefab("spawn_fx_medium").Transform:SetPosition(v.Transform:GetWorldPosition())
      v:ScreenFade(false, 2)
      v:Hide()
      v:DoTaskInTime(1, teleportPlayer)
    end
  end
end

function worldEvent(event, param)
  local alias = {season="ms_setseason", rain="ms_forceprecipitation"}
  local seasons = {"spring","summer","autumn","winter"}
  local newseasons = {}
  for _,s in pairs(seasons) do
    if s ~= TheWorld.state.season then
      table.insert(newseasons, s)
    end
  end
  if param == "random" and (event == "season" or event == alias["season"]) then
    param = newseasons[math.random(#newseasons)] or param
  end
    
  if alias[event] then
    event = alias[event]
  end
  if event == "longnight" then
    local delay = 0
    if TheWorld.state.isnight then
      TheWorld:PushEvent("ms_nextphase")
      delay = 1
    end
    TheWorld:DoTaskInTime(delay, function()
      TheWorld:PushEvent("ms_setclocksegs", {day = 0, dusk = 0, night = 16})
    end)
  elseif event == "sinkholespawner" then
    if TheWorld.components.sinkholespawner == nil then
      TheWorld:AddComponent("sinkholespawner")
    end
    TheWorld.components.sinkholespawner:StartSinkholes()
  else
    TheWorld:PushEvent(event, param)
  end
end

function playerEvent(event, param)
  for _,v in pairs(AllPlayers) do
    if event == "lightningstrike" then
      local counter = 0
      for i = 1, param or 1 do
        if v and v:IsValid() then
          v:DoTaskInTime(counter, function()
              TheWorld:PushEvent("ms_sendlightningstrike", v:GetPosition())
            end)
          counter = counter + 0.25 + math.random()/4
        end
      end
    elseif event == "sleep" then
      v:PushEvent("yawn", { grogginess = 4, knockoutduration = TUNING.BEARGER_YAWN_SLEEPTIME })
    else
      v:PushEvent(event)
    end
  end
end

function playerCommand(command, param)
  local alias = {dropEverything="components.inventory:DropEverything", giveAllRecipes="components.builder:GiveAllRecipes"}
  if alias[command] then
    command = alias[command]
  end
  for i,v in ipairs(AllPlayers) do
    if command == "speed" then
      v.components.locomotor:SetExternalSpeedMultiplier(v, "c_speedmult", param or 1)
      v:DoTaskInTime(COMMAND_SPEED_TIMER, 
        function() v.components.locomotor:SetExternalSpeedMultiplier(v, "c_speedmult", 1) end)
    
    elseif command == "damage" then
      v.components.combat.damagemultiplier = param or 1
      v:DoTaskInTime(COMMAND_DAMAGE_TIMER, 
        function() v.components.combat.damagemultiplier = 1 end)
      
    elseif command == "charge" then
      v.Light:Enable(true)
      v.Light:SetRadius(3)
      v.Light:SetFalloff(0.75)
      v.Light:SetIntensity(.75)
      v.Light:SetColour(235 / 255, 121 / 255, 12 / 255)
      v:DoTaskInTime(COMMAND_CHARGE_TIMER, 
        function() v.Light:Enable(false) end)
      
    elseif command == "freeze" then
      if v.components.freezable ~= nil then
          v.components.freezable:Freeze(5)
          --v.components.freezable:AddColdness(5)
          v.components.freezable:SpawnShatterFX()
      end
    else
      local f = loadstring("AllPlayers["..i.."]."..command.."()")
      if f then
        f()
        if command == alias.giveAllRecipes then
          v:DoTaskInTime(COMMAND_GIVEALL_TIMER, f)
        end
      end
    end
  end
end

function givePlayer(f, c)
  for k,v in pairs(AllPlayers) do
    for i = 1, c or 1 do
      local sfab = SpawnPrefab(f)
      if sfab ~= nil then
        if sfab.components.stackable ~= nil then
          sfab.components.stackable:SetStackSize(c or 1)
          v.components.inventory:GiveItem(sfab)
          break
        end
        v.components.inventory:GiveItem(sfab)
      end
    end
  end
end

local books = {sleep=1,	gardening=1, brimstone=1, birds=1, tentacles=1}

local function readBookPlayer(player, bookname)
  if not books[bookname] then
    return
  end
  
	-- Make a fake "reader" to pass to the book's onread function
	local reader = {}
	reader.Transform = {}
	reader.Transform.GetWorldPosition = function() return player.Transform:GetWorldPosition() end
	reader.GetPosition = function() return player:GetPosition() end
	reader.Get = function() return player.Transform:GetWorldPosition() end
	reader.components = {}
	reader.components.sanity = {}
	reader.components.sanity.DoDelta = function() end
	reader.StartThread = function(inst, fn) player:StartThread(fn) end
	reader.prefab = ""
	reader.components.talker = {}
	reader.components.talker.Say = function() end
	reader.IsValid = function() return true end
	reader.HasTag = function() return false end
	
	-- having it on this command would be weird if it wasn't on all of them...
	-- player.components.talker:Say("What sorcery is this?!")
	
	local book = SpawnPrefab("book_"..bookname)
  if book then
    print(bookname)
    book.Transform:SetPosition(player.Transform:GetWorldPosition())
    book:Hide()
    book.components.book:OnRead(reader)
    book:DoTaskInTime(5, book.Remove)
  end
end

function readBook(bookName)
  for _,v in pairs(AllPlayers) do
    readBookPlayer(v, bookName)
  end
end

local function spawnFabNearPosition(fab, ppos, dist, angle)
  if fab:match("randomBoss") then
    local bosses = {}
    if fab == "randomBossLight" then
      bosses = {"spat","rook","warg","krampus","rocky"}
    elseif fab == "randomBossHard" then
      bosses = {"minotaur","dragonfly","klaus","beequeen"}
    else
      bosses = {"leif","bearger","moose","spiderqueen","deerclops"}
    end
    print("Choosing from "..table.concat(bosses,","))
    
    fab = bosses[math.random(#bosses)] or fab
  end
	local sfab = SpawnPrefab(fab)
  if sfab then
    local pos = ToVector3(ppos)
    print("Spawn "..fab.." at "..pos.x..":"..pos.z)
    if dist and dist ~= 0 and angle and angle ~= 0 then
      --dist = dist/2 + math.random() * dist/2
      pos.x = pos.x + dist*math.cos(angle)
      pos.z = pos.z + dist*math.sin(angle)
    end
    sfab.Transform:SetPosition(pos.x, pos.y, pos.z)
    if fab == "klaus" then
      sfab:SpawnDeer()
    end
    if fab == "snowball" then
      SpawnPrefab("splash_snow_fx").Transform:SetPosition(pos.x, pos.y, pos.z)
      sfab.components.wateryprotection:SpreadProtection(sfab)
      sfab:Remove()
    elseif fab == "waterballoon" then
      SpawnPrefab("waterballoon_splash").Transform:SetPosition(pos.x, pos.y, pos.z)
      sfab.components.wateryprotection:SpreadProtection(sfab)
      sfab:Remove()
    else    
      SpawnPrefab("spawn_fx_medium").Transform:SetPosition(pos.x, pos.y, pos.z)
    end
  end
	return sfab;
end

local function fillFabs(f, c)
  local fabs = {}
  if randomSpawn[f] and type(randomSpawn[f]) == "table" then
    -- select random combination from tier
    local comb = randomSpawn[f][math.random(#randomSpawn[f])]
    if type(comb) == "table" then
      for combi,combv in pairs(comb) do
        if type(combv) == "table" then
          for fi, fv in pairs(combv) do
            if type(fv) == "number" then
              for i = 1, fv do
                table.insert(fabs, fi)
              end
            else
              table.insert(fabs, fv)
            end
          end
        else
          -- only one fab in combination array, e.g. tier1
          if type(combv) == "number" then
            for i = 1, combv do
              table.insert(fabs, combi)
            end
          else
            table.insert(fabs, combv)
          end
        end
      end
    else
      -- only one fab in combination, e.g. boss
      table.insert(fabs, comb)
    end
  else
    for i = 1, c or 1 do
      table.insert(fabs, f)
    end
  end
  return fabs;
end

function spawnNearPlayer(f, c, makeFollower, equipFab)
  c = c or 1
  local fabs = fillFabs(f, c)
  if f == "randomBossHard" then
    local loc = getrandomposition(AllPlayers[1])
    for _,v in pairs(AllPlayers) do
      SpawnPrefab("spawn_fx_medium").Transform:SetPosition(v.Transform:GetWorldPosition())
      v:ScreenFade(false, 2)
      v:Hide()
      loc.x = loc.x + 1
      v:DoTaskInTime(1, function() teleportPlayer(v, loc) end)
    end
    local counter = 0
    for _,fv in pairs(fabs) do
      AllPlayers[1]:DoTaskInTime(counter, function()
          spawnFabNearPosition(fv, loc, COMMAND_NEAR_DISTANCE, math.random()*2*PI)
        end)
      counter = counter + 0.25 + math.random()/4
    end
  else
    for _,v in pairs(AllPlayers) do
      fabs = fillFabs(f, c)
      local counter = 0
      for _,fv in pairs(fabs) do
        if v and v:IsValid() then
          v:DoTaskInTime(counter, function()
              local res = spawnFabNearPosition(fv, Vector3(v.Transform:GetWorldPosition()), COMMAND_NEAR_DISTANCE, math.random()*2*PI)
              if makeFollower and res.components.follower ~= nil then
                --res.components.follower:SetLeader(v)
                v:PushEvent("makefriend")
                v.components.leader:AddFollower(res)
                res.components.follower:AddLoyaltyTime(TUNING.TOTAL_DAY_TIME)
                res.components.follower.maxfollowtime = TUNING.TOTAL_DAY_TIME * 3
              end
              if equipFab and res.components and res.components.inventory then
                local efab = SpawnPrefab(equipFab)
                res.components.inventory:Equip(efab)
              end
            end)
          counter = counter + 0.25 + math.random()/4
        end
      end
    end
  end
end

function spawnAtPlayer(f, c)
  for k,v in pairs(AllPlayers) do
    local counter = 0
    for i = 1, c or 1 do
      if v and v:IsValid() then
        v:DoTaskInTime(counter, function()
            spawnFabNearPosition(f, Vector3(v.Transform:GetWorldPosition()))
          end)
        counter = counter + 0.1 + math.random()/4
      end
    end
  end
end

function startApo()
  for _,e in pairs(startApoEvents) do
    TheWorld:DoTaskInTime(e.delay or 0, function()
      if e.cmd then
        Commands:DoSafe(e.cmd)
      elseif e.fn ~= nil then
        e.fn(e.param)
      end
    end)
  end
end

local function spawnAt(prefab, x, y, z)
	local f = SpawnPrefab(prefab)
  f.Transform:SetPosition(x, y, z)
  return f
end

local function canSpawnTurf(pt)
    local ground = TheWorld
    if ground then
		local tile = ground.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
		return tile ~= GROUND.IMPASSIBLE and tile < GROUND.UNDERGROUND --and not ground.Map:IsWater(tile)
	end
	return false
end
local function spawnTurf(turf, pt)	
	local ground = TheWorld
	if ground and canSpawnTurf(pt) then
		local original_tile_type = ground.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
		local x, y = ground.Map:GetTileCoordsAtPoint(pt.x, pt.y, pt.z)
		if x and y then
			ground.Map:SetTile(x,y, turf)
			ground.Map:RebuildLayer( original_tile_type, x, y )
			ground.Map:RebuildLayer( turf, x, y )
		end
		local minimap = TheSim:FindFirstEntityWithTag("minimap")
		if minimap then
			minimap.MiniMap:RebuildLayer( original_tile_type, x, y )
			minimap.MiniMap:RebuildLayer( turf, x, y )
		end
	end
end

function isArenaActive()
  --check if arena exists
  local ent = TheSim:FindFirstEntityWithTag("rodbase")
  if not ent then
    return false
  end
  local pos = Point(ent.Transform:GetWorldPosition())
  --check if boss still alive
  local ents = TheSim:FindEntities(pos.x, 0, pos.z, 30, {"arenaBoss"})
  if #ents >= 1 then
    return true
  else
    return false
  end
end

function teleportToArena()
  local ent = TheSim:FindFirstEntityWithTag("rodbase")
  if not ent then
    return
  end
  local pos = Point(ent.Transform:GetWorldPosition())
  for _,v in pairs(AllPlayers) do
    SpawnPrefab("spawn_fx_medium").Transform:SetPosition(v.Transform:GetWorldPosition())
    v:ScreenFade(false, 2)
    v:Hide()
    local finaloffset = FindValidPositionByFan(math.random() * 2 * PI, 8, 8, function(offset) return true end)
    if finaloffset ~= nil then
        finaloffset.x = finaloffset.x + pos.x
        finaloffset.z = finaloffset.z + pos.z
    end
    v:DoTaskInTime(1, function() teleportPlayer(v, finaloffset or pos) end)
  end
end

function startArena(bossfab)
  --find arena
  local ents = TheSim:FindEntities(0, 0, 0, 1000, {"arena"})
  local ent = TheSim:FindFirstEntityWithTag("rodbase")
  local pos = getunknownposition(30) or Point(AllPlayers[1].Transform:GetWorldPosition())
  --if #ents <= 0 then
  if not ent then
    if pos then
      print("Arena not found, spawn at ", pos.x, pos.z)
      spawnArena(4, 3, pos.x, pos.y, pos.z)
    end
  else
    --pos = Point(ents[1].Transform:GetWorldPosition())
    pos = Point(ent.Transform:GetWorldPosition())
    print("Arena found at ", pos.x, pos.z)
    ents = TheSim:FindEntities(pos.x, 0, pos.z, 30, {"monster"})
    print("Remove "..#ents.." monsters")
    for _,e in ipairs(ents) do
      e:Remove()
    end
    ents = TheSim:FindEntities(pos.x, 0, pos.z, 30, {"arenaBoss"})
    for _,e in ipairs(ents) do
      e:Remove()
    end
    spawnArena(4, 3, pos.x, pos.y, pos.z, true)
  end
  
  --teleport players
  print("Teleport all players")
  teleportToArena()
  
  --spawn boss
  print("Spawn boss ", bossfab)
  local fabs = fillFabs(bossfab)
  for c=10,0,-1 do    
    TheWorld:DoTaskInTime(11-c, function() c_announce("Boss arriving in "..c) end)
  end
  if #fabs == 1 then
    TheWorld:DoTaskInTime(11.5, function() 
        local res = spawnFabNearPosition(fabs[1], pos)
        res:AddTag("arenaBoss")
        res:ListenForEvent("death", function() 
              for _,v in pairs(AllPlayers) do
                givePrize(v, 10)
              end
            end)
      end)
  else
    local counter = 11.5
    for _,fv in pairs(fabs) do
      v:DoTaskInTime(counter, function()
          local res = spawnFabNearPosition(fv, pos, 4, math.random()*2*PI)
          res:AddTag("arenaBoss")
        end)
      counter = counter + 0.25 + math.random()/4
    end
  end
end

function spawnArena(w,h,x,y,z,refreshOnly)
  refreshOnly = refreshOnly or false
  local player = AllPlayers[1]
	if not x and player ~= nil and player.Network:IsServerAdmin() then
		x, y, z = player.Transform:GetWorldPosition()
  end
  if x then
		x = math.floor(x/4)*4
		y = 0
		z = math.floor(z/4)*4
    w = w or 4
    h = h or 3
    local t = 4 --size of turf
    local b = 2 --size of basalt
    local tb = 2 --how many basalt in turf
    if not refreshOnly then
      spawnAt("diviningrodbase",x+2,y,z+2):AddTag("arena")
      for j=-w-1,w+1,1 do 
        for i=-h-1,h+1,1 do spawnTurf(GROUND.CHECKER, Vector3(x+j*t, y, z+i*t)) end
      end
      for j=-w-1,w+1,1 do spawnTurf(GROUND.IMPASSABLE, Vector3(x+j*t, y, z+(h+2)*t)) end
      for j=-w-1,w+1,1 do spawnTurf(GROUND.IMPASSABLE, Vector3(x+j*t, y, z+(-h-2)*t)) end
      for i=-h-2,h+2,1 do spawnTurf(GROUND.IMPASSABLE, Vector3(x+(-w-2)*t, y, z+i*t)) end
      for i=-h-2,h+2,1 do spawnTurf(GROUND.IMPASSABLE, Vector3(x+(w+2)*t, y, z+i*t)) end
    else
      local ents = TheSim:FindEntities(x, y, z, 30)
      for _,e in pairs(ents) do
        if e.prefab == "firepit" or e.prefab == "glommerfuel" or e.prefab == "lightning_rod" then
          e:Remove()
        end
      end
    end
    for i=-w-1,w+1,w+1 do
      --spawnTurf(GROUND.CHECKER, Vector3(x+i*t, y, z+(h+1)*t))
      --spawnTurf(GROUND.CHECKER, Vector3(x+i*t, y, z-(h+1)*t))
      spawnAt("firepit",x+i*t+2,y,z+(h+1)*t+2).components.fueled:InitializeFuelLevel(TUNING.FIREPIT_FUEL_MAX)
      spawnAt("firepit",x+i*t+2,y,z-(h+1)*t+2).components.fueled:InitializeFuelLevel(TUNING.FIREPIT_FUEL_MAX)
      
      spawnAt("lightning_rod",x+i*t+2,y,z+(h+2)*t+2)
      spawnAt("lightning_rod",x+i*t+2,y,z-(h+2)*t+2)
      
      spawnAt("glommerfuel",x+i*t,  y,z+(h+1)*t+4)
      spawnAt("glommerfuel",x+i*t+4,y,z+(h+1)*t+4) 
      for j=1,3,1 do
        spawnAt("spear_wathgrithr",x+i*t+j,y,z+(h+1)*t+4) 
      end
      spawnAt("amulet",     x+i*t,  y,z+(h+1)*t) 
      spawnAt("amulet",     x+i*t+4,y,z+(h+1)*t) 
      spawnAt("armorruins", x+i*t,  y,z+(h+1)*t+1) 
      spawnAt("slurtlehat", x+i*t,  y,z+(h+1)*t+2) 
      spawnAt("armorruins", x+i*t+4,y,z+(h+1)*t+1) 
      spawnAt("slurtlehat", x+i*t+4,y,z+(h+1)*t+2) 
      spawnAt("fishsticks", x+i*t,  y,z+(h+1)*t+3).components.stackable:SetStackSize(10) 
      spawnAt("fishsticks", x+i*t+4,y,z+(h+1)*t+3).components.stackable:SetStackSize(10)  
      
      spawnAt("glommerfuel",x+i*t,  y,z-(h+1)*t) 
      spawnAt("glommerfuel",x+i*t+4,y,z-(h+1)*t) 
      for j=1,3,1 do
        spawnAt("spear_wathgrithr",x+i*t+j,y,z-(h+1)*t) 
      end
      spawnAt("amulet",     x+i*t,  y,z-(h+1)*t+4) 
      spawnAt("amulet",     x+i*t+4,y,z-(h+1)*t+4) 
      spawnAt("armorruins", x+i*t,  y,z-(h+1)*t+2) 
      spawnAt("slurtlehat", x+i*t,  y,z-(h+1)*t+3) 
      spawnAt("armorruins", x+i*t+4,y,z-(h+1)*t+2) 
      spawnAt("slurtlehat", x+i*t+4,y,z-(h+1)*t+3) 
      spawnAt("fishsticks", x+i*t,  y,z-(h+1)*t+1).components.stackable:SetStackSize(10) 
      spawnAt("fishsticks", x+i*t+4,y,z-(h+1)*t+1).components.stackable:SetStackSize(10)  
    end
    
		for i=-h*tb,(h+1)*tb,1 do spawnAt("basalt_pillar", x-w*tb*b, y, z+i*b) end
		for i=-h*tb,(h+1)*tb,1 do spawnAt("basalt_pillar", x+(w+1)*tb*b, y, z+i*b) end
		for i=-w*tb+2,(w+1)*tb-2,1 do if i ~= 1 then spawnAt("basalt_pillar", x+i*b, y, z-h*tb*b) end end
		for i=-w*tb+2,(w+1)*tb-2,1 do if i ~= 1 then spawnAt("basalt_pillar", x+i*b, y, z+(h+1)*tb*b) end end
	end
end

local function launchitem(item, angle)
    local speed = math.random() * 4 + 2
    angle = (angle + math.random() * 60 - 30) * DEGREES
    item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
end

function givePrize(giver,count)
    local prizes = {"goldnugget","gears","goldnugget","gears","purplegem","yellowgem","redgem","bluegem","greengem","orangegem"}
    local inst = TheSim:FindFirstEntityWithTag("rodbase")
    inst.SoundEmitter:PlaySound("dontstarve/pig/PigKingThrowGold")

    local x, y, z = inst.Transform:GetWorldPosition()
    y = 4.5

    local angle
    if giver ~= nil and giver:IsValid() then
      angle = 180 - giver:GetAngleToPoint(x, 0, z)
    else
      local down = TheCamera:GetDownVec()
      angle = math.atan2(down.z, down.x) / DEGREES
    end

    for k = 1, count or 10 do
      local nug = SpawnPrefab(prizes[math.random(#prizes)])
      nug.Transform:SetPosition(x, y, z)
      launchitem(nug, angle)
    end
end

function Commands:DoSafe(cmdstr)
  local f = loadstring(cmdstr)
  if f and f ~= "" then
    local success, err = pcall(f)
    if not success then 
      self:Log("command error "..tostring(err))
    end
  end
end

function Commands:Do(cmdstr)
  self:Log(self.lastline..": "..cmdstr)
  --Run via RPC
  --self:Do(cmdstr)
  SendModRPCToServer(MOD_RPC.filecommands.DoSafe, cmdstr)
end

function Commands:Process()
  local lines = {}
  local i = 0
  for line in io.lines(self.filename) do
    if i > self.lastline then
      table.insert(lines, line)
    end
    i = i + 1
  end
  for i, l in ipairs(lines) do 
    l = l:gsub("^%s+", ""):gsub("%s+$", "")
    if l ~= "" then
      l = l:gsub("/","("):gsub("\\",")")
      
      for m in string.gmatch(l, "[^;]+") do
        local t = {}
        local lc
        if string.match(m, "random{.*}") then
          self:Log("random found")
        end
        if string.match(m, "random{[^}]+}") then
          local res
          local rla = {}
          local rl = string.match(m, "random{([^}]+)}")
          for rli in string.gmatch(rl, "[^,]+") do
            rla[#rla+1] = rli:gsub("^%s+", ""):gsub("%s+$", "")
          end
          res = rla[math.random(#rla)]
          self:Log("Select random from "..#rla.." -> "..res)
          if res and res ~= "" then
            m = m:gsub("random{[^}]+}", res)
          end
        end
                
        for k in string.gmatch(m, "%S+") do
          t[#t+1] = (#t == 0 or tonumber(k) or k == "true" or k == "false") and k or "\""..k.."\"" 
        end
        if t[1] == "c_announce" then
          lc = t[1].."(\""..m:gsub("c_announce","").."\")"
        elseif #t > 1 then
          lc = t[1].."("..table.concat(t, ",", 2)..")"
        elseif not string.match(l, "%(%)$") and not string.match(l,"=%S+") then
          lc = t[1].."()"
        else
          lc = l
        end
        self:Do(lc)
      end
    end
    self.lastline = self.lastline + 1
  end
  return true
end

function Commands:Init(filename)
  self.filename = filename or self.filename
  self.lastline = -1
  for line in io.lines(self.filename) do
    self.lastline = self.lastline + 1
  end
  self:Log("Commands init: skipped "..self.lastline)
end

function Commands:EnableLog(enable)
    if not enable then
        self:Log("Logging is disabled")
        self.enable_log = false
    elseif not self.enable_log then
        self.enable_log = true
        self:Log("Logging is enabled")
    end
end

function Commands:Log(message)
    if self.enable_log then
        print("["..self.name.."] "..message)
    end
end

return Commands