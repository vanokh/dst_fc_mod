local randomSpawn = require("filecommands/randomSpawn")
local startApoEvents = require("filecommands/startApo")

local Commands = Class(function(self, name)
    self.name = name or ""
    self.filepath = "C:\\temp\\cmd.txt"
    self.enable_log = nil
    self.lastline = -1

    self:EnableLog(true)
end)

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
  for _,v in pairs(AllPlayers) do
    SpawnPrefab("spawn_fx_medium").Transform:SetPosition(v.Transform:GetWorldPosition())
    v:ScreenFade(false, 2)
    v:Hide()
    v:DoTaskInTime(1, teleportPlayer)
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
    SpawnPrefab("spawn_fx_medium").Transform:SetPosition(pos.x, pos.y, pos.z)
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

function spawnNearPlayer(f, c)
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
              spawnFabNearPosition(fv, Vector3(v.Transform:GetWorldPosition()), COMMAND_NEAR_DISTANCE, math.random()*2*PI)
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