Assets = {}

local function AddImageAsset(name)
    table.insert(Assets, Asset("IMAGE", "images/"..name..".tex"))
    table.insert(Assets, Asset("ATLAS", "images/"..name..".xml"))
end

--AddImageAsset("twitch_button")

local require = GLOBAL.require
local AddModRPCHandler = GLOBAL.AddModRPCHandler
local FileCommandsButton = require("widgets/filecommandsbutton")
local FileCommands = require("filecommands/filecommands")("FileCommands", GetModConfigData("file_path", true))
local Commands = require("filecommands/commands")("Commands")
GLOBAL.FileCommands = FileCommands
FileCommands:SetCommands(Commands)
GLOBAL.COMMAND_SPEED_TIMER = GetModConfigData("speed_timer", true) or 60
GLOBAL.COMMAND_DAMAGE_TIMER = GetModConfigData("damage_timer", true) or 60
GLOBAL.COMMAND_CHARGE_TIMER = GetModConfigData("charge_timer", true) or 60
GLOBAL.COMMAND_NEAR_DISTANCE = GetModConfigData("near_distance", true) or 6

AddModRPCHandler("filecommands", "DoSafe",
    function(player, cmdstr)
        Commands:DoSafe(cmdstr)
    end)

AddClassPostConstruct("widgets/controls", function(self)
    local Image = require("widgets/image")
    --button
    self.fcbutton = self.bottomright_root:AddChild(FileCommandsButton())
    FileCommands:SetButton(self.fcbutton)
    self.mapcontrols.minimapBtn.OnHide = function()
        self.fcbutton:TweenToPosition(-140, 75, 0)
    end
    self.mapcontrols.minimapBtn.OnShow = function()
        self.fcbutton:SnapToPosition(-140, 135, 0)
    end
    if self.mapcontrols.minimapBtn.shown then
        self.mapcontrols.minimapBtn.OnShow()
    else
        self.mapcontrols.minimapBtn.OnHide()
    end
end)
