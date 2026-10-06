--========================================================--
--  Custom Party Glow  (WoW 12.x)
--  Glow effect over party / raid members on the world map.
--========================================================--

local addonName = ...

-- Localization: English is the fallback, add a block per client locale.
local L = setmetatable({}, { __index = function(_, k) return k end })
local locale = GetLocale()
if locale == "esES" or locale == "esMX" then
  L["Size"]                      = "Tamaño"
  L["Glow Scale"]                = "Escala del brillo"
  L["Opacity"]                   = "Opacidad"
  L["Show player"]               = "Mostrar jugador"
  L["Show minimap button"]       = "Mostrar botón en el minimapa"
  L["Click to open the options."] = "Click para abrir las opciones."
  L["Drag to move it."]          = "Arrastra para moverlo."
  L["loaded - /cpg opens the options."] = "cargado - /cpg abre las opciones."
elseif locale == "ptBR" then
  L["Size"]                      = "Tamanho"
  L["Glow Scale"]                = "Escala do brilho"
  L["Opacity"]                   = "Opacidade"
  L["Show player"]               = "Mostrar jogador"
  L["Show minimap button"]       = "Mostrar botão no minimapa"
  L["Click to open the options."] = "Clique para abrir as opções."
  L["Drag to move it."]          = "Arraste para movê-lo."
  L["loaded - /cpg opens the options."] = "carregado - /cpg abre as opções."
end

CustomPartyGlowDB = CustomPartyGlowDB or {}

local iconSize, glowScale, iconAlpha, showPlayer
local CreateMinimapButton, CreateMapButton -- defined below, run on ADDON_LOADED

local function ClassColor(unit)
  local _, cls = UnitClass(unit)
  local c = cls and RAID_CLASS_COLORS[cls]
  if c then return c.r, c.g, c.b end
  return 1, 1, 0
end

local function LoadSettings()
  local db = CustomPartyGlowDB
  db.iconSize   = db.iconSize   or 24
  db.glowScale  = db.glowScale  or 2
  db.iconAlpha  = db.iconAlpha  or 0.8
  db.showPlayer = db.showPlayer ~= false
  db.showMinimap = db.showMinimap ~= false

  iconSize   = db.iconSize
  glowScale  = db.glowScale
  iconAlpha  = db.iconAlpha
  showPlayer = db.showPlayer
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
-- Every option writes straight into CustomPartyGlowDB, which WoW saves on logout.
ev:SetScript("OnEvent", function(_, _, arg1)
  if arg1 == addonName then
    LoadSettings()
    CreateMinimapButton()
    CreateMapButton()
  end
end)

-----------------------------------------------------------------------------
-- World map blips
-----------------------------------------------------------------------------
local customBlips = {}

local function CreateBlip(unit)
  local blip = CreateFrame("Frame", nil, WorldMapFrame:GetCanvas())
  blip:SetFrameStrata("HIGH")
  blip:SetFrameLevel(2000)

  blip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(UnitName(unit) or "?", ClassColor(unit))
    GameTooltip:AddLine(UnitClass(unit) or "", 1, 1, 1)
    GameTooltip:Show()
  end)
  blip:SetScript("OnLeave", GameTooltip_Hide)

  blip.border = blip:CreateTexture(nil, "OVERLAY")
  blip.border:SetTexture("Interface\\GLUES\\Models\\UI_Draenei\\GenericGlow64")
  blip.border:SetBlendMode("ADD")
  blip.border:SetPoint("CENTER")

  local pulse = blip.border:CreateAnimationGroup()
  pulse:SetLooping("REPEAT")
  local pIn = pulse:CreateAnimation("Scale")
  pIn:SetScale(1.2, 1.2); pIn:SetDuration(0.5); pIn:SetSmoothing("IN")
  local pOut = pulse:CreateAnimation("Scale")
  pOut:SetScale(0.8333, 0.8333); pOut:SetDuration(0.5); pOut:SetSmoothing("OUT")
  pOut:SetStartDelay(0.5)
  pulse:Play()

  return blip
end

local function UpdatePartyIcons()
  if not WorldMapFrame or not WorldMapFrame:IsShown() then return end

  local canvas = WorldMapFrame:GetCanvas()
  local mapID  = WorldMapFrame:GetMapID()
  if not canvas or not mapID then
    for _, b in pairs(customBlips) do b:Hide() end
    return
  end

  local prefix   = IsInRaid() and "raid" or "party"
  local maxUnits = IsInRaid() and 40 or 4

  -- Build the set of units that should be shown right now.
  local active = {}
  if showPlayer then active.player = true end
  for i = 1, maxUnits do
    local u = prefix..i
    -- In a raid the player is also raidN; skip it so showPlayer is respected.
    if UnitExists(u) and not UnitIsUnit(u, "player") then active[u] = true end
  end

  -- Hide blips for units that are no longer in the group (kept for reuse:
  -- frames can't be destroyed, so dropping them would leak).
  for unit, blip in pairs(customBlips) do
    if not active[unit] then blip:Hide() end
  end

  local cw, ch = canvas:GetWidth(), canvas:GetHeight()
  for unit in pairs(active) do
    local pos = C_Map.GetPlayerMapPosition(mapID, unit)
    local x, y
    if pos then x, y = pos:GetXY() end

    if x and y and x > 0 and y > 0 then
      local blip = customBlips[unit]
      if not blip then
        blip = CreateBlip(unit)
        customBlips[unit] = blip
      end
      blip:SetSize(iconSize, iconSize)
      blip.border:SetSize(iconSize * glowScale, iconSize * glowScale)
      blip.border:SetAlpha(iconAlpha)
      blip.border:SetVertexColor(ClassColor(unit))
      blip:ClearAllPoints()
      blip:SetPoint("CENTER", canvas, "TOPLEFT", x * cw, -y * ch)
      blip:Show()
    elseif customBlips[unit] then
      customBlips[unit]:Hide()
    end
  end
end

-- Throttled updater while the map is open.
local updater = CreateFrame("Frame")
updater:SetScript("OnUpdate", function(self, dt)
  self.elapsed = (self.elapsed or 0) + dt
  if self.elapsed >= 0.1 then
    self.elapsed = 0
    UpdatePartyIcons()
  end
end)

-----------------------------------------------------------------------------
-- Options panel
-----------------------------------------------------------------------------
local function MakeSlider(parent, label, minVal, maxVal, step, getFunc, setFunc)
  local s = CreateFrame("Slider", nil, parent, "UISliderTemplate")
  s:SetSize(200, 17) -- the template has no size; without it nothing anchored below renders
  s:SetMinMaxValues(minVal, maxVal)
  s:SetValueStep(step)
  s:SetObeyStepOnDrag(true)

  s.Text = s:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  s.Text:SetPoint("BOTTOM", s, "TOP", 0, 2)
  s.Text:SetText(label)

  s.Val = s:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  s.Val:SetPoint("TOP", s, "BOTTOM", 0, -2)

  s:SetScript("OnValueChanged", function(_, v)
    if step == 1 then v = math.floor(v + 0.5) end
    s.Val:SetText(step == 1 and v or string.format("%.2f", v))
    setFunc(v)
    UpdatePartyIcons()
  end)

  C_Timer.After(0, function()
    local v = getFunc()
    s:SetValue(v)
    s.Val:SetText(step == 1 and v or string.format("%.2f", v))
  end)

  return s
end

local function ShowOptions()
  if CustomPartyGlowOpts then CustomPartyGlowOpts:SetShown(not CustomPartyGlowOpts:IsShown()); return end

  local f = CreateFrame("Frame", "CustomPartyGlowOpts", UIParent, "BackdropTemplate")
  f:SetSize(320, 320)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true); f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop",  f.StopMovingOrSizing)
  f:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  f:SetBackdropColor(0.1, 0.1, 0.1, 1)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  title:SetPoint("TOP", 0, -10)
  title:SetText("Custom Party Glow")

  local sizeSlider = MakeSlider(f, L["Size"], 16, 128, 1,
    function() return iconSize end,
    function(v) iconSize = v; CustomPartyGlowDB.iconSize = v end)
  sizeSlider:SetPoint("TOP", title, "BOTTOM", 0, -20)

  local scaleSlider = MakeSlider(f, L["Glow Scale"], 1, 5, 0.1,
    function() return glowScale end,
    function(v) glowScale = v; CustomPartyGlowDB.glowScale = v end)
  scaleSlider:SetPoint("TOP", sizeSlider, "BOTTOM", 0, -30)

  local alphaSlider = MakeSlider(f, L["Opacity"], 0.1, 1.0, 0.05,
    function() return iconAlpha end,
    function(v) iconAlpha = v; CustomPartyGlowDB.iconAlpha = v end)
  alphaSlider:SetPoint("TOP", scaleSlider, "BOTTOM", 0, -30)

  local playerCheck = CreateFrame("CheckButton", "CustomPartyGlowPlayerCheck", f, "UICheckButtonTemplate")
  playerCheck:SetPoint("TOP", alphaSlider, "BOTTOM", -60, -20)
  playerCheck.Text:SetText(L["Show player"])
  playerCheck:SetChecked(showPlayer)
  playerCheck:SetScript("OnClick", function(self)
    showPlayer = self:GetChecked() and true or false
    CustomPartyGlowDB.showPlayer = showPlayer
    UpdatePartyIcons()
  end)

  local minimapCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  minimapCheck:SetPoint("TOPLEFT", playerCheck, "BOTTOMLEFT", 0, -2)
  minimapCheck.Text:SetText(L["Show minimap button"])
  minimapCheck:SetChecked(CustomPartyGlowDB.showMinimap)
  minimapCheck:SetScript("OnClick", function(self)
    CustomPartyGlowDB.showMinimap = self:GetChecked() and true or false
    CustomPartyGlowMinimapButton:SetShown(CustomPartyGlowDB.showMinimap)
  end)

  local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  close:SetSize(80, 22)
  close:SetText(CLOSE) -- Blizzard global string, already localized
  close:SetPoint("BOTTOM", 0, 10)
  close:SetScript("OnClick", function() f:Hide() end)
end

-----------------------------------------------------------------------------
-- Slash command + map button
-----------------------------------------------------------------------------
SLASH_CUSTOMPARTYGLOW1 = "/cpg"
SLASH_CUSTOMPARTYGLOW2 = "/custompartyglow"
SlashCmdList["CUSTOMPARTYGLOW"] = ShowOptions

-- Addon compartment (the minimap dropdown that lists all addons), see .toc
CustomPartyGlow_OnAddonCompartmentClick = ShowOptions

-- World map button, stacked with Blizzard's/other addons' map buttons by
-- Krowi_WorldMapButtons (top-right corner of the map).
function CreateMapButton()
  local b = LibStub("Krowi_WorldMapButtons-1.4"):Add(nil, "BUTTON")
  b:SetSize(32, 32)
  b:SetFrameStrata("HIGH")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(25, 25)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetPoint("TOPLEFT", 2, -4)

  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetSize(20, 20)
  icon:SetTexture("Interface\\AddOns\\CustomPartyGlow\\icon")
  icon:SetPoint("TOPLEFT", 6, -6)

  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetSize(54, 54)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetPoint("TOPLEFT")

  b.Refresh = function() end -- called by the library on every map change

  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Custom Party Glow", 1, 1, 1)
    GameTooltip:AddLine(L["Click to open the options."], 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  b:SetScript("OnClick", ShowOptions)
end

-----------------------------------------------------------------------------
-- Minimap button (drag to move around the minimap edge)
-----------------------------------------------------------------------------
local function PlaceMinimapButton(b)
  local a = math.rad(CustomPartyGlowDB.minimapAngle or 225)
  local r = Minimap:GetWidth() / 2 + 5
  b:ClearAllPoints()
  b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

function CreateMinimapButton()
  local b = CreateFrame("Button", "CustomPartyGlowMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(24, 24)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetPoint("CENTER")

  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetSize(18, 18)
  icon:SetTexture("Interface\\AddOns\\CustomPartyGlow\\icon")
  icon:SetPoint("CENTER")

  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetSize(50, 50)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetPoint("TOPLEFT")

  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Custom Party Glow", 1, 1, 1)
    GameTooltip:AddLine(L["Click to open the options."], 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L["Drag to move it."], 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  b:SetScript("OnClick", ShowOptions)

  b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local s = Minimap:GetEffectiveScale()
      CustomPartyGlowDB.minimapAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
      PlaceMinimapButton(self)
    end)
  end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

  PlaceMinimapButton(b)
  b:SetShown(CustomPartyGlowDB.showMinimap)
end

print("|cff88ccff[CustomPartyGlow]|r " .. L["loaded - /cpg opens the options."])
