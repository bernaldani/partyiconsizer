-- Create configuration table if it doesn't exist
if not CustomPartyGlowDB then
    CustomPartyGlowDB = {}
end

-- Set default icon size if not configured
local iconSize = CustomPartyGlowDB.iconSize or 24
local sliderPos = CustomPartyGlowDB.sliderPos or {}

-- Global variables for the button, slider, and custom blips
local mapButton
local sizeSliderFrame
local customBlips = customBlips or {}

-- Class colors mapping
local classColors = {
    ["WARRIOR"] = {1, 0.78, 0.55},
    ["PALADIN"] = {0.96, 0.55, 0.73},
    ["HUNTER"] = {0.67, 0.83, 0.45},
    ["ROGUE"] = {1, 0.96, 0.41},
    ["PRIEST"] = {1, 1, 1},
    ["DEATHKNIGHT"] = {0.77, 0.12, 0.23},
    ["SHAMAN"] = {0, 0.44, 0.87},
    ["MAGE"] = {0.41, 0.8, 0.94},
    ["WARLOCK"] = {0.58, 0.51, 0.79},
    ["MONK"] = {0, 1, 0.59},
    ["DRUID"] = {1, 0.49, 0.04},
    ["DEMONHUNTER"] = {0.64, 0.19, 0.79},
    ["EVOKER"] = {0.2, 0.58, 0.5},
}

-- Function to update custom blips (glowing effects without icons)
local function UpdatePartyIcons()
    -- Ensure customBlips is a valid table
    if not customBlips or type(customBlips) ~= "table" then
        customBlips = {}
    end

    for _, blip in pairs(customBlips) do
        blip:Hide()
    end

    local uiMapID = WorldMapFrame:GetMapID()
    if not uiMapID then
        return
    end

    local numGroupMembers = GetNumGroupMembers()
    if numGroupMembers > 0 or not IsInInstance() then
        local unitPrefix = IsInRaid() and "raid" or "party"
        local numUnits = IsInRaid() and 40 or 4

        local units = {"player"}
        for i = 1, numUnits do
            local unit = unitPrefix .. i
            if UnitExists(unit) then
                table.insert(units, unit)
            end
        end

        for _, unit in ipairs(units) do
            local position = C_Map.GetPlayerMapPosition(uiMapID, unit)
            if position then
                local x, y = position:GetXY()
                if x and y and x > 0 and y > 0 then
                    local blip = customBlips[unit]
                    if not blip then
                        blip = CreateFrame("Frame", nil, WorldMapFrame:GetCanvas())
                        blip:SetSize(iconSize, iconSize)

                        -- Add glowing border effect
                        blip.border = blip:CreateTexture(nil, "OVERLAY")
                        blip.border:SetTexture("Interface\\GLUES\\Models\\UI_Draenei\\GenericGlow64")
                        blip.border:SetBlendMode("ADD")
                        blip.border:SetAlpha(0.8)

                        -- Get the class of the unit
                        local _, class = UnitClass(unit)
                        local color = classColors[class] or {1, 1, 0} -- Default to yellow if class not found
                        blip.border:SetVertexColor(unpack(color))

                        local glowSize = iconSize * 2
                        blip.border:SetSize(glowSize, glowSize)
                        blip.border:SetPoint("CENTER", blip, "CENTER", 0, 0)

                        local pulse = blip.border:CreateAnimationGroup()
                        local pulseIn = pulse:CreateAnimation("Scale")
                        pulseIn:SetScale(1.2, 1.2)
                        pulseIn:SetDuration(0.5)
                        pulseIn:SetSmoothing("IN")
                        local pulseOut = pulse:CreateAnimation("Scale")
                        pulseOut:SetScale(0.8333, 0.8333)
                        pulseOut:SetDuration(0.5)
                        pulseOut:SetSmoothing("OUT")
                        pulseOut:SetStartDelay(0.5)
                        pulse:SetLooping("REPEAT")
                        pulse:Play()

                        customBlips[unit] = blip
                    else
                        -- Update existing blip's color and size
                        local _, class = UnitClass(unit)
                        local color = classColors[class] or {1, 1, 0}
                        blip.border:SetVertexColor(unpack(color))

                        blip:SetSize(iconSize, iconSize)
                        local glowSize = iconSize * 2
                        blip.border:SetSize(glowSize, glowSize)
                        blip:Show()
                    end

                    blip:SetPoint("CENTER", WorldMapFrame:GetCanvas(), "TOPLEFT", x * WorldMapFrame:GetCanvas():GetWidth(), -y * WorldMapFrame:GetCanvas():GetHeight())
                    blip:SetFrameStrata("HIGH")
                    blip:SetFrameLevel(2000)
                end
            end
        end
    end
end

-- Frame for regularly updating blips
local updateFrame = CreateFrame("Frame")
local updateInterval = 0.1
local timeSinceLastUpdate = 0

updateFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= updateInterval then
        if WorldMapFrame:IsShown() then
            UpdatePartyIcons()
        end
        timeSinceLastUpdate = 0
    end
end)

-- Function to reposition the button based on map size (fullscreen or windowed)
function RepositionMapButton()
    if WorldMapFrame:IsMaximized() then
        mapButton:SetPoint("TOPRIGHT", WorldMapFrame.BorderFrame.MaximizeMinimizeFrame, "TOPLEFT", -185, -75)
    else
        mapButton:SetPoint("TOPRIGHT", WorldMapFrame.BorderFrame.MaximizeMinimizeFrame, "TOPLEFT", -485, -75)
    end
end

-- Function to create the button on the world map
function CreateMapButton()
    if mapButton then
        return
    end

    mapButton = CreateFrame("Button", "CustomPartyGlowMapButton", WorldMapFrame.BorderFrame, "UIPanelButtonTemplate")
    mapButton:SetSize(24, 24)
    RepositionMapButton()

    mapButton.icon = mapButton:CreateTexture(nil, "ARTWORK")
    mapButton.icon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    mapButton.icon:SetAllPoints()

    mapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Adjust Icon Size", 1, 1, 1)
        GameTooltip:Show()
    end)

    mapButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    hooksecurefunc(WorldMapFrame, "Maximize", RepositionMapButton)
    hooksecurefunc(WorldMapFrame, "Minimize", RepositionMapButton)

    mapButton:SetScript("OnClick", function()
        if sizeSliderFrame and sizeSliderFrame:IsShown() then
            sizeSliderFrame:Hide()
        else
            ShowSizeSlider()
        end
    end)
end

-- Function to display the size adjustment slider
function ShowSizeSlider()
    if not sizeSliderFrame then
        sizeSliderFrame = CreateFrame("Frame", "CustomPartyGlowSliderFrame", WorldMapFrame, "BasicFrameTemplateWithInset")
        sizeSliderFrame:SetSize(220, 100)
        if sliderPos.point then
            sizeSliderFrame:SetPoint(sliderPos.point, sliderPos.relativeTo, sliderPos.relativePoint, sliderPos.xOfs, sliderPos.yOfs)
        else
            sizeSliderFrame:SetPoint("CENTER", WorldMapFrame, "CENTER")
        end

        sizeSliderFrame:SetFrameStrata("DIALOG")
        sizeSliderFrame:SetFrameLevel(2000)

        sizeSliderFrame:SetMovable(true)
        sizeSliderFrame:EnableMouse(true)
        sizeSliderFrame:RegisterForDrag("LeftButton")
        sizeSliderFrame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        sizeSliderFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
            CustomPartyGlowDB.sliderPos = {
                point = point,
                relativeTo = relativeTo and relativeTo:GetName() or "WorldMapFrame",
                relativePoint = relativePoint,
                xOfs = xOfs,
                yOfs = yOfs,
            }
        end)

        sizeSliderFrame.title = sizeSliderFrame:CreateFontString(nil, "OVERLAY")
        sizeSliderFrame.title:SetFontObject("GameFontHighlight")
        sizeSliderFrame.title:SetPoint("TOPLEFT", sizeSliderFrame.TitleBg, "TOPLEFT", 5, -5)
        sizeSliderFrame.title:SetText("Adjust Icon Size")

        local slider = CreateFrame("Slider", "CustomPartyGlowSlider", sizeSliderFrame, "OptionsSliderTemplate")
        slider:SetWidth(180)
        slider:SetHeight(20)
        slider:SetPoint("CENTER", sizeSliderFrame, "CENTER", 0, -10)
        slider:SetMinMaxValues(16, 128)
        slider:SetValueStep(1)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(math.floor(iconSize))

        _G[slider:GetName() .. "Low"]:SetText("16")
        _G[slider:GetName() .. "High"]:SetText("128")
        _G[slider:GetName() .. "Text"]:SetText("Size: " .. math.floor(iconSize))

        slider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value)
            iconSize = value
            CustomPartyGlowDB.iconSize = value
            _G[self:GetName() .. "Text"]:SetText("Size: " .. value)
            if value > 16 then
                UpdatePartyIcons()
            else
                for _, blip in pairs(customBlips) do
                    blip:Hide()
                end
            end
        end)

        slider:HookScript("OnMouseUp", function(self)
            local value = math.floor(slider:GetValue())
            if value <= 16 then
                value = 16
                slider:SetValue(16)
                _G[slider:GetName() .. "Text"]:SetText("Size: 16")
                CustomPartyGlowDB.iconSize = 16
                for _, blip in pairs(customBlips) do
                    blip:Hide()
                end
            end
        end)

        local closeButton = CreateFrame("Button", nil, sizeSliderFrame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", sizeSliderFrame, "TOPRIGHT", -5, -5)
        closeButton:SetScript("OnClick", function()
            sizeSliderFrame:Hide()
        end)
    else
        sizeSliderFrame:Show()
        local slider = _G["CustomPartyGlowSlider"]
        if slider then
            slider:SetValue(math.floor(iconSize))
            _G[slider:GetName() .. "Text"]:SetText("Size: " .. math.floor(iconSize))
        end
    end
end

-- Automatically hide the slider when the map closes
WorldMapFrame:HookScript("OnHide", function()
    if sizeSliderFrame then
        sizeSliderFrame:Hide()
    end
end)

-- Frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "CustomPartyGlow" then
        iconSize = CustomPartyGlowDB.iconSize or 24
        sliderPos = CustomPartyGlowDB.sliderPos or {}
    elseif event == "PLAYER_ENTERING_WORLD" then
        CreateMapButton()
    end
end)

-- Chat command to open the slider
SLASH_CUSTOMPARTYGLOW1 = "/cpg"
SLASH_CUSTOMPARTYGLOW2 = "/custompartyglow"
SlashCmdList["CUSTOMPARTYGLOW"] = function(msg)
    ShowSizeSlider()
end
