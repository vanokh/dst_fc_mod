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

local function teleportPlayer(player)
	local t_loc = getrandomposition(player)
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
    elseif command == "damage" then
      v.components.combat.damagemultiplier = param or 1
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

local function spawnFabNearPlayer(fab, player, dist, angle)
	local sfab = SpawnPrefab(fab)
  local pos = Vector3(player.Transform:GetWorldPosition() )
  if dist and dist ~= 0 and angle and angle ~= 0 then
    --dist = dist/2 + math.random() * dist/2
    pos.x = pos.x + dist*math.cos(angle)
    pos.z = pos.z + dist*math.sin(angle)
  end
	sfab.Transform:SetPosition(pos.x, pos.y, pos.z)
	SpawnPrefab("spawn_fx_medium").Transform:SetPosition(pos.x, pos.y, pos.z)
	return sfab;
end

function spawnNearPlayer(f, c)
  c = c or 1
  for k,v in pairs(AllPlayers) do
    local counter = 0
    for i = 1, c do
      if v and v:IsValid() then
        v:DoTaskInTime(counter, function()
            spawnFabNearPlayer(f, v, 6, math.random()*2*PI)
          end)
        counter = counter + 0.25 + math.random()/4
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
            spawnFabNearPlayer(f, v)
          end)
        counter = counter + 0.1 + math.random()/4
      end
    end
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
        for k in string.gmatch(m, "%S+") do
          t[#t+1] = (#t == 0 or tonumber(k) or k == "true" or k == "false") and k or "\""..k.."\"" 
        end
        if #t > 1 then
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