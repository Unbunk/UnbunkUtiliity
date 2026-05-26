-- Modules/BLTracker/UI/ConfigWindow.lua

local function CreateBLTrackerPanel(parent)
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
        label   = "Enable BL Tracker",
        checked = BLTrackerCfg_Get("enabled") ~= false,
        onClick = function(val) BLTrackerCfg_Set("enabled", val) end,
    })
    enableCb.frame:SetPoint("TOPLEFT", enableFrame, "TOPLEFT", 0, 0)
    AddModule(enableFrame, 24)

    -- ── Instance filter ───────────────────────────────────────────────────────

    local iF = Unbunk_CreateInstanceFilter({
        parent    = content,
        getConfig = function() return BLTrackerCfg_Get("instanceFilter") end,
        setConfig = function(key, val)
            local filter = BLTrackerCfg_Get("instanceFilter")
            filter[key] = val
            BLTrackerCfg_Set("instanceFilter", filter)
        end,
    })
    AddModule(iF.frame, iF.height)

    local soundBLResult = HealerRange_CreateSoundPicker(content, LSM, {
        label          = "Sound on Bloodlust",
        getSoundKey    = function() return BLTrackerCfg_Get("soundKeyBL") end,
        getSoundEnable = function() return BLTrackerCfg_Get("soundOnBL") end,
        onSoundSelect  = function(key, path)
            BLTrackerCfg_Set("soundKeyBL", key)
            BLTrackerCfg_Set("soundPathBL", path)
        end,
        onEnableToggle = function(val) BLTrackerCfg_Set("soundOnBL", val) end,
        onTest         = function() BLTracker_PlaySound("soundPathBL") end,
    })
    AddModule(soundBLResult.frame, soundBLResult.height)

    local soundReadyResult = HealerRange_CreateSoundPicker(content, LSM, {
        label          = "Sound when Bloodlust ready",
        getSoundKey    = function() return BLTrackerCfg_Get("soundKeyReady") end,
        getSoundEnable = function() return BLTrackerCfg_Get("soundOnReady") end,
        onSoundSelect  = function(key, path)
            BLTrackerCfg_Set("soundKeyReady", key)
            BLTrackerCfg_Set("soundPathReady", path)
        end,
        onEnableToggle = function(val) BLTrackerCfg_Set("soundOnReady", val) end,
        onTest         = function() BLTracker_PlaySound("soundPathReady") end,
    })
    AddModule(soundReadyResult.frame, soundReadyResult.height)

    -- ── Show icon checkbox ────────────────────────────────────────────────────

    local showIconFrame = CreateFrame("Frame", nil, content)
    showIconFrame:SetHeight(24)
    local showIconCb = Unbunk_CreateCheckbox({
        parent  = showIconFrame,
        label   = "Show icon",
        checked = BLTrackerCfg_Get("showIcon") ~= false,
        onClick = function(val)
            BLTrackerCfg_Set("showIcon", val)
            ApplyVisuals_BL()
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
        text       = tostring(BLTrackerCfg_Get("iconWidth") or 64),
        onEnter    = function(val)
            if val and val > 0 then
                BLTrackerCfg_Set("iconWidth", val)
                BLTracker_ApplySize()
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
        text       = tostring(BLTrackerCfg_Get("iconHeight") or 64),
        onEnter    = function(val)
            if val and val > 0 then
                BLTrackerCfg_Set("iconHeight", val)
                BLTracker_ApplySize()
            end
        end,
    })
    hInput.frame:SetPoint("LEFT", hLbl, "RIGHT", 4, 0)

    AddModule(sizeFrame, 46)

    -- ── Position editor ───────────────────────────────────────────────────────

    BLTrackerPE = HealerRange_CreatePositionEditor(content, {
        label      = "Icon position (offset from screen center)",
        getX       = function() return BLTrackerCfg_Get("posX") end,
        getY       = function() return BLTrackerCfg_Get("posY") end,
        onApply    = function(x, yv)
            if x  then BLTrackerCfg_Set("posX", x)  end
            if yv then BLTrackerCfg_Set("posY", yv) end
            BLTracker_ApplyPosition()
        end,
        onUnlock   = function() BLTracker_SetUnlocked(true) end,
        onLock     = function()
            BLTracker_SetUnlocked(false)
            if BLTrackerPE then BLTrackerPE.Refresh() end
        end,
        isUnlocked = function() return BLTracker_IsUnlocked() end,
    })
    AddModule(BLTrackerPE.frame, BLTrackerPE.height)

    -- ── Timer text style ──────────────────────────────────────────────────────

    local te = HealerRange_CreateTextEditor(content, {
        LSM          = LSM,
        label        = "Timer text",
        showText     = false,
        showFont     = true,
        showSize     = true,
        showColor    = true,
        showOutline  = true,
        getFontKey   = function() return BLTrackerCfg_Get("timerFontKey") end,
        getFontPath  = function() return BLTrackerCfg_Get("timerFontPath") end,
        getFontSize  = function() return BLTrackerCfg_Get("timerFontSize") end,
        getColor     = function() return BLTrackerCfg_Get("timerColor") end,
        getOutline   = function() return BLTrackerCfg_Get("timerOutline") end,
        onFontChange = function(key, path)
            BLTrackerCfg_Set("timerFontKey", key)
            BLTrackerCfg_Set("timerFontPath", path)
            BLTracker_ApplyFont()
        end,
        onSizeChange = function(size)
            BLTrackerCfg_Set("timerFontSize", size)
            BLTracker_ApplyFont()
        end,
        onColorChange = function(r, g, b, a)
            BLTrackerCfg_Set("timerColor", { r=r, g=g, b=b, a=a })
            BLTracker_ApplyFont()
        end,
        onOutlineChange = function(outline)
            BLTrackerCfg_Set("timerOutline", outline)
            BLTracker_ApplyFont()
        end,
    })
    AddModule(te.frame, te.height)

    -- ── OnShow refresh ────────────────────────────────────────────────────────

    parent:HookScript("OnShow", function()
        enableCb.SetChecked(BLTrackerCfg_Get("enabled") ~= false)
        iF.Refresh()
        soundBLResult.Refresh()
        soundReadyResult.Refresh()
        te.Refresh()
        wInput.SetText(tostring(BLTrackerCfg_Get("iconWidth") or 64))
        hInput.SetText(tostring(BLTrackerCfg_Get("iconHeight") or 64))
        BLTrackerPE.Refresh()
    end)
end

-- ── Enregistrement ────────────────────────────────────────────────────────────

local initBLUI = CreateFrame("Frame")
initBLUI:RegisterEvent("ADDON_LOADED")
initBLUI:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "UnbunkUtility" then return end
    UnbunkUtility.RegisterModule("BL Tracker", nil, CreateBLTrackerPanel)
    self:UnregisterEvent("ADDON_LOADED")
end)