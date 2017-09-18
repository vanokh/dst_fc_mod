Assets = {}

local function AddImageAsset(name)
    table.insert(Assets, Asset("IMAGE", "images/"..name..".tex"))
    table.insert(Assets, Asset("ATLAS", "images/"..name..".xml"))
end

--AddImageAsset("twitch_button")

local require = GLOBAL.require
local AddModRPCHandler = GLOBAL.AddModRPCHandler
local FileCommandsButton = require("widgets/filecommandsbutton")
local ShowDeathsButton = require("widgets/showdeathsbutton")
local FileCommands = require("filecommands/filecommands")("FileCommands", GetModConfigData("file_path", true))
local Commands = require("filecommands/commands")("Commands")
GLOBAL.FileCommands = FileCommands
FileCommands:SetCommands(Commands)
GLOBAL.COMMAND_SPEED_TIMER = GetModConfigData("speed_timer", true) or 60
GLOBAL.COMMAND_DAMAGE_TIMER = GetModConfigData("damage_timer", true) or 60
GLOBAL.COMMAND_CHARGE_TIMER = GetModConfigData("charge_timer", true) or 60
GLOBAL.COMMAND_GIVEALL_TIMER = GetModConfigData("giveall_timer", true) or 7
GLOBAL.COMMAND_NEAR_DISTANCE = GetModConfigData("near_distance", true) or 6

GLOBAL.FCAllDeaths = {}
FCAllDeaths = GLOBAL.FCAllDeaths

AddModRPCHandler("filecommands", "DoSafe",
    function(player, cmdstr)
        Commands:DoSafe(cmdstr)
    end)

    function OnUpdateDeaths(player, death)
      if death then print("Death of "..player.name) end
      require("consolecommands")
      if death then
        FCAllDeaths[player.userid] = {name=player.name, count=FCAllDeaths[player.userid] and FCAllDeaths[player.userid].count+1 or 1}
      end
      local ds = ""
      for _,v in pairs(GLOBAL.AllPlayers or {player}) do
        if FCAllDeaths[v.userid] then
          ds = ds..(ds ~= "" and ", " or "")..v.name.." ("..FCAllDeaths[v.userid].count..")"
        end
      end
      print("Deaths: "..ds)
      if ds ~= "" then GLOBAL.TheNet:Announce("Deaths: "..ds) end
    end

AddModRPCHandler("filecommands", "UpdateDeaths",
    function(from, player, death)
        OnUpdateDeaths(player, death)
    end)  
local function OnPlayerUpdate(player, death)
  --SendModRPCToServer(MOD_RPC.filecommands.UpdateDeaths, player, death)
  OnUpdateDeaths(player, death)
end

AddPrefabPostInit("world", function(inst)
  inst:ListenForEvent("ms_playerjoined", function(src, player)
    inst:ListenForEvent("death", function(inst, data) OnPlayerUpdate(inst, true) end, player)
    OnPlayerUpdate(player) 
  end , TheWorld)
  inst:ListenForEvent("ms_playerleft", function(src, player) OnPlayerUpdate(player) end, TheWorld)
end)                                             

AddClassPostConstruct("widgets/controls", function(self)
    local Image = require("widgets/image")
    --button
    self.fcbutton = self.bottomright_root:AddChild(FileCommandsButton())
    self.sdbutton = self.bottomright_root:AddChild(ShowDeathsButton())
    FileCommands:SetButton(self.fcbutton)
    self.mapcontrols.minimapBtn.OnHide = function()
        self.fcbutton:TweenToPosition(-140, 75, 0)
        self.sdbutton:TweenToPosition(-140, 25, 0)
    end
    self.mapcontrols.minimapBtn.OnShow = function()
        self.fcbutton:SnapToPosition(-140, 135, 0)
        self.sdbutton:SnapToPosition(-140, 80, 0)
    end
    if self.mapcontrols.minimapBtn.shown then
        self.mapcontrols.minimapBtn.OnShow()
    else
        self.mapcontrols.minimapBtn.OnHide()
    end
end)
