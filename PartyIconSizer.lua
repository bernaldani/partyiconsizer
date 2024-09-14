-- Create configuration table if it doesn't exist
if not PartyIconSizerDB then
    PartyIconSizerDB = {}
end

-- Set default icon size if not configured
local iconSize = PartyIconSizerDB.iconSize or 24
local sliderPos = PartyIconSizerDB.sliderPos or {}

-- Global variables for the button, slider, and custom blips
local mapButton
local sizeSliderFrame
local customBlips = customBlips or {}

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
    if numGroupMembers > 0 then
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
                        blip.border:SetVertexColor(1, 1, 0)

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
        -- When the map is in fullscreen mode
        mapButton:SetPoint("TOPRIGHT", WorldMapFrame.BorderFrame.MaximizeMinimizeFrame, "TOPLEFT", -185, -75)
    else
        -- When the map is in windowed mode
        mapButton:SetPoint("TOPRIGHT", WorldMapFrame.BorderFrame.MaximizeMinimizeFrame, "TOPLEFT", -485, -75)
    end
end

-- Function to create the button on the world map
function CreateMapButton()
    if mapButton then
        return
    end

    -- Create button next to the World Map's filter button
    mapButton = CreateFrame("Button", "PartyIconSizerMapButton", WorldMapFrame.BorderFrame, "UIPanelButtonTemplate")
    mapButton:SetSize(24, 24)
    RepositionMapButton()

    -- Set the icon texture for the button
    mapButton.icon = mapButton:CreateTexture(nil, "ARTWORK")
    mapButton.icon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    mapButton.icon:SetAllPoints()

    -- Set tooltip when hovering over the button
    mapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Adjust Icon Size", 1, 1, 1)
        GameTooltip:Show()
    end)

    -- Hide tooltip when the cursor leaves the button
    mapButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Hook the maximize/minimize events to reposition the button when the map changes size
    hooksecurefunc(WorldMapFrame, "Maximize", RepositionMapButton)
    hooksecurefunc(WorldMapFrame, "Minimize", RepositionMapButton)

    -- OnClick behavior
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
        sizeSliderFrame = CreateFrame("Frame", "PartyIconSizerSliderFrame", WorldMapFrame, "BasicFrameTemplateWithInset")
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
            PartyIconSizerDB.sliderPos = {
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

        local slider = CreateFrame("Slider", "PartyIconSizerSlider", sizeSliderFrame, "OptionsSliderTemplate")
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
            PartyIconSizerDB.iconSize = value
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
                PartyIconSizerDB.iconSize = 16
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
        local slider = _G["PartyIconSizerSlider"]
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
    if event == "ADDON_LOADED" and arg1 == "PartyIconSizer" then
        iconSize = PartyIconSizerDB.iconSize or 24
        sliderPos = PartyIconSizerDB.sliderPos or {}
    elseif event == "PLAYER_ENTERING_WORLD" then
        CreateMapButton()
    end
end)

-- Chat command to open the slider
SLASH_PARTYICONSIZER1 = "/pis"
SLASH_PARTYICONSIZER2 = "/partyiconsizer"
SlashCmdList["PARTYICONSIZER"] = function(msg)
    ShowSizeSlider()
end
