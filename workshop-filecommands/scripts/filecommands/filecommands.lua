local InputDialogScreen = require "screens/inputdialog"

local FileCommands = Class(function(self, name, filepath_config)
    self.name = name or ""
    self.filepath = (filepath_config == 1) and "C:\\temp\\cmd.txt" or 
      (filepath_config == 2) and "..\\cmd.txt" or 
      (filepath_config == 3) and "D:\\cmd.txt" or ""
    self.enable_log = nil
    self.isActive = false
    self.inEvent = false

    self.commands = nil

    self:EnableLog(true)
end)

--------------------------------------------------------------------------
--[[Public]]
function FileCommands:SetCommands(commands)
  self.commands = commands
end

function FileCommands:SetButton(button)
    self.button = button
end

local function file_exists(name)
   return pcall(function() io.lines(name) end)
end

function FileCommands:GetPath(startfn)
  local report_dialog = InputDialogScreen("Enter path to the file with commands:", 
    {
      {
        text = "OK", 
        cb = function()
            local fn = InputDialogScreen:GetText()
            self:Log("Text entered (ok) "..fn)
            if file_exists(fn) then
              self:Log("File "..fn.." exists")
              self.filepath = fn
              startfn()
            end
            TheFrontEnd:PopScreen()
        end
      },
      {
        text = "Cancel", 
        cb = function()
            self:Log("Text cancelled")
            TheFrontEnd:PopScreen()
        end
      },
    },
    true)
    report_dialog.edit_text.OnTextEntered = function()
        local fn = InputDialogScreen:GetText()
        self:Log("Text entered "..fn)
        if file_exists(fn) then
          self:Log("File "..fn.." exists")
          self.filepath = fn
          startfn()
        end
        TheFrontEnd:PopScreen()
    end
    report_dialog:SetValidChars([[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:.\ ]]) --'
    TheFrontEnd:PushScreen(report_dialog)  
    report_dialog.edit_text:OnControl(CONTROL_ACCEPT, false)
end

--Start processing commands from file in game
function FileCommands:Start()
  if not self.filepath or self.filepath == "" then
    self:GetPath(function() self:Start() end)
  end
  if self.filepath ~= "" then
    self:Log("Started")
    self.isActive = true
    if self.button then
        self:RefreshButton(self.button)
    end
    self.commands:Init(self.filepath)
    self:Run(self,{time=0})
  end
end

--Stop processing commands from file in game
function FileCommands:Stop()
    self:Log("Stopping")
    self.isActive = false
    if self.button then
        self:RefreshButton(self.button)
    end
end

--Toggle logging to log.txt
function FileCommands:EnableLog(enable)
    if not enable then
        self:Log("Logging is disabled")
        self.enable_log = false
    elseif not self.enable_log then
        self.enable_log = true
        self:Log("Logging is enabled")
    end
end

--Returns whether the processing is active or not
function FileCommands:IsActive()
    return self.isActive
end

--Returns whether a command is currently running
function FileCommands:IsBusy()
    return self.inEvent
end

--Returns whether we are ready to process commands or not
function FileCommands:IsReady()
    return self:IsActive() and not self:IsBusy()
end

--------------------------------------------------------------------------
--[[Internal]]

function FileCommands:Log(message)
    if self.enable_log then
        print("["..self.name.."] "..message)
    end
end

function FileCommands:RefreshButton(button)
    if button ~= nil then
        button.image:SetTint(self:IsActive() and .5 or 1, self:IsActive() and 1 or .5, .5, 1)
        button:SetTooltip("File commands " ..(self:IsActive() and "enabled" or "disabled"))
    end
end

function FileCommands:SendCommand(commandstr)
    if self:IsReady() and commandstr ~= "" then
        self:Log("Sending command "..commandstr)
        SendModRPCToServer(MOD_RPC.filecommands.RunCommand, commandstr)
    end
end

function FileCommands:RunCommand(player, cmdstr)
    if player ~= nil and player:IsValid() then
        local fn = loadstring(cmdstr)
        if cmdstr ~= nil and fn ~= nil then
            self:Log("Running command "..cmdstr.." for "..player.name)
            fn(player)
        end
    end
end

function FileCommands:Run(inst, data)
  if not self.isActive then
    self:Log("Stopped")
    return true
  end
  self.commands:Process()
  TheWorld:DoTaskInTime(0.3, function() self:Run(inst,{time=data.time+0.001}) end)
  --self:Log("tick "..data.time)
  return true
end
return FileCommands