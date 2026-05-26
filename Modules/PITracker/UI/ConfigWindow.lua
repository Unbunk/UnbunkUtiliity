-- Modules/PITracker/UI/ConfigWindow.lua

local function CreatePITrackerPanel(parent)
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints(parent)

    local GAP = 12
    local lastFrame = nil

    local function AddModule(moduleFrame, moduleHeight)
        moduleFrame:SetWidth(518)
        if lastFrame then
            moduleFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -GAP)
        else
            moduleFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        end
        lastFrame = moduleFrame
    end

    -- ── Enable checkbox ───────────────────────────────────────────────────────

    local enableFrame = CreateFrame("Frame", nil, content)
    enableFrame:SetHeight(24)
    local enableCb = Unbunk_CreateCheckbox({
        parent  = enableFrame,
        label   = "Enable PI Tracker",
        checked = PITrackerCfg_Get("enabled") ~= false,
        onClick = function(val)
            PITrackerCfg_Set("enabled", val)
            ApplyVisuals_PI()
        end,
    })
    enableCb.frame:SetPoint("TOPLEFT", enableFrame, "TOPLEFT", 0, 0)
    AddModule(enableFrame, 24)

    -- ── Instance filter ───────────────────────────────────────────────────────

    local iF = Unbunk_CreateInstanceFilter({
        parent    = content,
        getConfig = function() return PITrackerCfg_Get("instanceFilter") end,
        setConfig = function(key, val)
            local filter = PITrackerCfg_Get("instanceFilter")
            filter[key] = val
            PITrackerCfg_Set("instanceFilter", filter)
        end,
    })
    AddModule(iF.frame, iF.height)

    -- ── Sound PI ──────────────────────────────────────────────────────────────

    local soundResult = HealerRange_CreateSoundPicker(content, LSM, {
        label          = "Sound on PI",
        getSoundKey    = function() return PITrackerCfg_Get("soundKeyPI") end,
        getSoundEnable = function() return PITrackerCfg_Get("soundOnPI") end,
        onSoundSelect  = function(key, path)
            PITrackerCfg_Set("soundKeyPI", key)
            PITrackerCfg_Set("soundPathPI", path)
        end,
        onEnableToggle = function(val) PITrackerCfg_Set("soundOnPI", val) end,
        onTest         = function() PITracker_PlaySound() end,
    })
    AddModule(soundResult.frame, soundResult.height)

    -- ── Show icon checkbox ────────────────────────────────────────────────────

    local showIconFrame = CreateFrame("Frame", nil, content)
    showIconFrame:SetHeight(24)
    local showIconCb = Unbunk_CreateCheckbox({
        parent  = showIconFrame,
        label   = "Show icon",
        checked = PITrackerCfg_Get("showIcon") ~= false,
        onClick = function(val)
            PITrackerCfg_Set("showIcon", val)
            ApplyVisuals_PI()
        end,
    })
    showIconCb.frame:SetPoint("TOPLEFT", showIconFrame, "TOPLEFT", 0, 0)
    AddModule(showIconFrame, 24)

    -- ── Icon size ─────────────────────────────────────────────────────────────

    local sizeFrame = CreateFrame("Frame", nil, content)
    sizeFrame:SetHeight(46)

    local sizeLbl = sizeFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sizeLbl:SetPoint("TOPLEFT", sizeFrame, "TOPLEFT", 0, 0)
    sizeLbl:SetText("Icon size")

    local wLbl = sizeFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    wLbl:SetPoint("TOPLEFT", sizeFrame, "TOPLEFT", 0, -20)
    wLbl:SetText("W")

    local wInput = Unbunk_CreateTextInput({
        parent     = sizeFrame,
        width      = 46,
        height     = 22,
        numeric    = true,
        maxLetters = 3,
        text       = tostring(PITrackerCfg_Get("iconWidth") or 64),
        onEnter    = function(val)
            if val and val > 0 then
                PITrackerCfg_Set("iconWidth", val)
                PITracker_ApplySize()
            end
        end,
    })
    wInput.frame:SetPoint("LEFT", wLbl, "RIGHT", 4, 0)

    local hLbl = sizeFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hLbl:SetPoint("LEFT", wInput.frame, "RIGHT", 12, 0)
    hLbl:SetText("H")

    local hInput = Unbunk_CreateTextInput({
        parent     = sizeFrame,
        width      = 46,
        height     = 22,
        numeric    = true,
        maxLetters = 3,
        text       = tostring(PITrackerCfg_Get("iconHeight") or 64),
        onEnter    = function(val)
            if val and val > 0 then
                PITrackerCfg_Set("iconHeight", val)
                PITracker_ApplySize()
            end
        end,
    })
    hInput.frame:SetPoint("LEFT", hLbl, "RIGHT", 4, 0)

    AddModule(sizeFrame, 46)

    -- ── Position editor ───────────────────────────────────────────────────────

    PITrackerPE = HealerRange_CreatePositionEditor(content, {
        label      = "Icon position (offset from screen center)",
        getX       = function() return PITrackerCfg_Get("posX") end,
        getY       = function() return PITrackerCfg_Get("posY") end,
        onApply    = function(x, yv)
            if x  then PITrackerCfg_Set("posX", x)  end
            if yv then PITrackerCfg_Set("posY", yv) end
            PITracker_ApplyPosition()
        end,
        onUnlock   = function() PITracker_SetUnlocked(true) end,
        onLock     = function()
            PITracker_SetUnlocked(false)
            if PITrackerPE then PITrackerPE.Refresh() end
        end,
        isUnlocked = function() return PITracker_IsUnlocked() end,
    })
    AddModule(PITrackerPE.frame, PITrackerPE.height)

    -- ── Timer text ────────────────────────────────────────────────────────────

    local te = HealerRange_CreateTextEditor(content, {
        LSM          = LSM,
        label        = "Timer text",
        showText     = false,
        showFont     = true,
        showSize     = true,
        showColor    = true,
        showOutline  = true,
        getFontKey   = function() return PITrackerCfg_Get("timerFontKey") end,
        getFontPath  = function() return PITrackerCfg_Get("timerFontPath") end,
        getFontSize  = function() return PITrackerCfg_Get("timerFontSize") end,
        getColor     = function() return PITrackerCfg_Get("timerColor") end,
        getOutline   = function() return PITrackerCfg_Get("timerOutline") end,
        onFontChange = function(key, path)
            PITrackerCfg_Set("timerFontKey", key)
            PITrackerCfg_Set("timerFontPath", path)
            PITracker_ApplyFont()
        end,
        onSizeChange = function(size)
            PITrackerCfg_Set("timerFontSize", size)
            PITracker_ApplyFont()
        end,
        onColorChange = function(r, g, b, a)
            PITrackerCfg_Set("timerColor", { r=r, g=g, b=b, a=a })
            PITracker_ApplyFont()
        end,
        onOutlineChange = function(outline)
            PITrackerCfg_Set("timerOutline", outline)
            PITracker_ApplyFont()
        end,
    })
    AddModule(te.frame, te.height)

    -- ── OnShow refresh ────────────────────────────────────────────────────────

    parent:HookScript("OnShow", function()
        enableCb.SetChecked(PITrackerCfg_Get("enabled") ~= false)
        showIconCb.SetChecked(PITrackerCfg_Get("showIcon") ~= false)
        iF.Refresh()
        soundResult.Refresh()
        wInput.SetText(tostring(PITrackerCfg_Get("iconWidth") or 64))
        hInput.SetText(tostring(PITrackerCfg_Get("iconHeight") or 64))
        PITrackerPE.Refresh()
        te.Refresh()
    end)
end

-- ── Enregistrement ────────────────────────────────────────────────────────────

local initPIUI = CreateFrame("Frame")
initPIUI:RegisterEvent("ADDON_LOADED")
initPIUI:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "UnbunkUtility" then return end
    UnbunkUtility.RegisterModule("PI Tracker", nil, CreatePITrackerPanel)
    self:UnregisterEvent("ADDON_LOADED")
end)