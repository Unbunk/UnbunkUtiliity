-- Modules/HealerRange/UI/ConfigWindow.lua

local function CreateHealerRangePanel(parent)
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints(parent)

    local GAP = 12
    local totalHeight = 0
    local lastFrame = nil

    local function AddModule(moduleFrame, moduleHeight)
        moduleFrame:SetWidth(518)
        if lastFrame then
            moduleFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -GAP)
        else
            moduleFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        end
        totalHeight = totalHeight + moduleHeight + GAP
        lastFrame = moduleFrame
    end

    -- ── Enable checkbox ───────────────────────────────────────────────────────

    local enableFrame = CreateFrame("Frame", nil, content)
    enableFrame:SetHeight(24)

    local enableCheckbox = Unbunk_CreateCheckbox({
        parent  = enableFrame,
        label   = "Enable Healer Range",
        checked = HealerRangeCfg_Get("enabled") ~= false,
        onClick = function(val)
            HealerRangeCfg_Set("enabled", val)
        end,
    })
    enableCheckbox.frame:SetPoint("TOPLEFT", enableFrame, "TOPLEFT", 0, 0)
    AddModule(enableFrame, 24)

    -- ── Probe status ──────────────────────────────────────────────────────────

    local probeFrame = CreateFrame("Frame", nil, content)
    probeFrame:SetHeight(30)

    local probeMsg = probeFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    probeMsg:SetPoint("TOPLEFT", probeFrame, "TOPLEFT", 0, 0)
    probeMsg:SetWidth(500)
    probeMsg:SetJustifyH("LEFT")
    probeMsg:SetWordWrap(true)
    AddModule(probeFrame, 30)

    -- ── Test Alert ────────────────────────────────────────────────────────────

    local testFrame = CreateFrame("Frame", nil, content)
    testFrame:SetHeight(30)
    local testAlertBtn = Unbunk_CreateButton({
        parent  = testFrame,
        label   = "Test Alert",
        width   = 100,
        height  = 22,
        onClick = function()
            if SlashCmdList["UNBUNKUTILITY"] then
                SlashCmdList["UNBUNKUTILITY"]("test")
            end
        end,
    })
    testAlertBtn.frame:SetPoint("TOPLEFT", testFrame, "TOPLEFT", 0, -4)
    AddModule(testFrame, 30)

    -- ── Instance filter ───────────────────────────────────────────────────────

    local iF = Unbunk_CreateInstanceFilter({
        parent    = content,
        getConfig = function() return HealerRangeCfg_Get("instanceFilter") end,
        setConfig = function(key, val)
            local filter = HealerRangeCfg_Get("instanceFilter")
            filter[key] = val
            HealerRangeCfg_Set("instanceFilter", filter)
        end,
    })
    AddModule(iF.frame, iF.height)

    -- ── Icon picker ───────────────────────────────────────────────────────────

    local ip = Unbunk_CreateIconPicker({
        parent    = content,
        getConfig = function() return HealerRangeCfg_Get("icon") end,
        setConfig = function(key, val)
            local cfg = HealerRangeCfg_Get("icon")
            cfg[key] = val
            HealerRangeCfg_Set("icon", cfg)
            HealerRangeAlert_ApplyIcon()
        end,
        icons = UNBUNK_ICONS or {},
    })
    AddModule(ip.frame, ip.height)

    -- ── Sound picker ──────────────────────────────────────────────────────────

    local soundResult = HealerRange_CreateSoundPicker(content, LSM)
    AddModule(soundResult.frame, soundResult.height)

    -- ── Text editor ───────────────────────────────────────────────────────────

    local te = HealerRange_CreateTextEditor(content, {
        LSM             = LSM,
        label           = "Alert text",
        getText         = function() return HealerRangeCfg_Get("alertMessage") end,
        getFontKey      = function() return HealerRangeCfg_Get("fontKey") end,
        getFontPath     = function() return HealerRangeCfg_Get("fontPath") end,
        getFontSize     = function() return HealerRangeCfg_Get("fontSize") end,
        getColor        = function() return HealerRangeCfg_Get("color") end,
        getOutline      = function() return HealerRangeCfg_Get("outline") end,
        onTextChange    = function(txt)
            HealerRangeCfg_Set("alertMessage", txt)
            if HealerRangeAlert_ApplyMessage then HealerRangeAlert_ApplyMessage() end
        end,
        onFontChange    = function(key, path)
            HealerRangeCfg_Set("fontKey", key)
            HealerRangeCfg_Set("fontPath", path)
            if HealerRangeAlert_ApplyFont then HealerRangeAlert_ApplyFont() end
        end,
        onSizeChange    = function(size)
            HealerRangeCfg_Set("fontSize", size)
            if HealerRangeAlert_ApplyFont then HealerRangeAlert_ApplyFont() end
        end,
        onColorChange   = function(r, g, b, a)
            HealerRangeCfg_Set("color", { r=r, g=g, b=b, a=a })
            if HealerRangeAlert_ApplyColor then HealerRangeAlert_ApplyColor() end
        end,
        onOutlineChange = function(outline)
            HealerRangeCfg_Set("outline", outline)
            if HealerRangeAlert_ApplyFont then HealerRangeAlert_ApplyFont() end
        end,
    })
    AddModule(te.frame, te.height)

    -- ── Duration editor ───────────────────────────────────────────────────────

    local de = Unbunk_CreateDurationEditor({
        parent           = content,
        getDuration      = function() return HealerRangeCfg_Get("alertDuration") end,
        onDurationChange = function(val) HealerRangeCfg_Set("alertDuration", val) end,
    })
    AddModule(de.frame, de.height)

    -- ── Position editor ───────────────────────────────────────────────────────

    HealerRangePE = HealerRange_CreatePositionEditor(content, {
        label       = "Alert position (offset from screen center)",
        getX        = function() return HealerRangeCfg_Get("posX") end,
        getY        = function() return HealerRangeCfg_Get("posY") end,
        onApply     = function(x, yv)
            if x  then HealerRangeCfg_Set("posX", x)  end
            if yv then HealerRangeCfg_Set("posY", yv) end
            if HealerRangeAlert_ApplyPosition then HealerRangeAlert_ApplyPosition() end
        end,
        onUnlock    = function()
            if HealerRangeAlert_SetUnlocked then HealerRangeAlert_SetUnlocked(true) end
            print("|cffff4444[UnbunkUtility]|r Alert unlocked — drag to reposition, then /ubu lock to save.")
        end,
        onLock      = function()
            if HealerRangeAlert_SetUnlocked then HealerRangeAlert_SetUnlocked(false) end
        end,
        isUnlocked  = function()
            return HealerRangeAlert_IsUnlocked and HealerRangeAlert_IsUnlocked() or false
        end,
    })
    AddModule(HealerRangePE.frame, HealerRangePE.height)

    local function RefreshProbeStatus()
        if not HealerRange_HasCombatProbe() then
            probeMsg:SetText("|cffff4444Combat range detection unavailable — your class has no friendly spell probe usable in combat. The alert will not trigger.|r")
        else
            probeMsg:SetText("|cff00ff00Combat range detection available. Note: Evoker healers are ignored unless other healers are present in the group.|r")
        end
    end

    parent:HookScript("OnShow", function()
        enableCheckbox.SetChecked(HealerRangeCfg_Get("enabled") ~= false)
        soundResult.Refresh()
        te.Refresh()
        de.Refresh()
        if HealerRangePE then HealerRangePE.Refresh() end
        iF.Refresh()
        ip.Refresh()
        RefreshProbeStatus()
    end)
end

-- ── Enregistrement ────────────────────────────────────────────────────────────
local initHR = CreateFrame("Frame")
initHR:RegisterEvent("ADDON_LOADED")
initHR:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "UnbunkUtility" then return end

    local blizzPanel = CreateFrame("Frame")
    blizzPanel.name = "UnbunkUtility"
    local blizzTitle = blizzPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    blizzTitle:SetPoint("TOPLEFT", 16, -16)
    blizzTitle:SetText("UnbunkUtility")
    local openBtn = CreateFrame("Button", nil, blizzPanel, "UIPanelButtonTemplate")
    openBtn:SetSize(160, 22)
    openBtn:SetPoint("TOPLEFT", 16, -80)
    openBtn:SetText("Open UnbunkUtility")
    openBtn:SetScript("OnClick", function()
        UnbunkUtility.OpenWindow()
        HideUIPanel(SettingsPanel)
    end)
    local cat = Settings.RegisterCanvasLayoutCategory(blizzPanel, blizzPanel.name)
    Settings.RegisterAddOnCategory(cat)

    UnbunkUtility.RegisterModule("Healer Range", nil, CreateHealerRangePanel)

    self:UnregisterEvent("ADDON_LOADED")
end)