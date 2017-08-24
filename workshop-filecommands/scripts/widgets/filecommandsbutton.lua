local TextButton = require("widgets/textbutton")
local ImageButton = require("widgets/imagebutton")
local TEMPLATES = require("widgets/templates")

local function OnClick()
    local platform = PLATFORM:sub(1, 3):upper()
    if platform ~= "WIN" and platform ~= "OSX" then
        if ThePlayer ~= nil and ThePlayer.HUD ~= nil then
            ThePlayer.HUD.eventannouncer:ShowNewAnnouncement("FileCommands is currently supported on Windows and OSX only!")
        end
    elseif FileCommands:IsActive() then
	FileCommands:Stop()
    else
        FileCommands:Start()
    end
end

local FileCommandsButton = Class(ImageButton, function(self)
--    TextButton._ctor(self, "images/ui.xml", "blank.tex")--"images/twitch_button.xml", "twitch_button.tex")
  ImageButton._ctor(self, "images/frontend.xml", "button_square.tex", "button_square_halfshadow.tex", "button_square_disabled.tex", "button_square_halfshadow.tex", "button_square_disabled.tex", {1,1}, {0,0})
  self.image:SetScale(.7)
  self.icon = self:AddChild(Image("images/frontend.xml", "button_square_highlight.tex"))
  self.icon:SetPosition(-5,4)
  self.icon:SetScale(.16)
  self.icon:SetClickable(false)

  self.highlight = self:AddChild(Image("images/frontend.xml", "button_square_highlight.tex"))
  self.highlight:SetScale(.7)
  self.highlight:SetClickable(false)
  self.highlight:Hide()

  self:SetOnGainFocus(function()
      if self:IsEnabled() and not self:IsSelected() and TheFrontEnd:GetFadeLevel() <= 0 then
          self.highlight:Show()
      end
  end)
  self:SetOnLoseFocus(function()
      self.highlight:Hide()
  end)

    self.x = 0
    self.y = 0
    self.z = 0

  self.icon:Hide()
  self.text:SetPosition(-3, 5)
  --self.image:SetTint(.5, 1, .5, 1)

    --self:SetScale(.5, .5, .5)
    --self:SetFont(BUTTONFONT)
    self:SetTextSize(30)
    self:SetOnClick(OnClick)
    self:SetTooltip("File Commands disabled")
    self:SetText("FC")
end)

function FileCommandsButton:SnapToPosition(x, y, z)
    self:StopUpdating()
    self:SetPosition(x, y, z)
    self.x = x
    self.y = y
    self.z = z
end

function FileCommandsButton:TweenToPosition(x, y, z)
    self.x = x
    self.y = y
    self.z = z
    self:StartUpdating()
end

function FileCommandsButton:OnUpdate(dt)
    local x, y, z = self:GetPosition():Get()
    if math.abs(x - self.x) < .1 and math.abs(y - self.y) < .1 and math.abs(z - self.z) < .1 then
        self:SnapToPosition(self.x, self.y, self.z)
    else
        self:SetPosition(Lerp(x, self.x, .3), Lerp(y, self.y, .3), Lerp(z, self.z, .3))
    end
end

return FileCommandsButton