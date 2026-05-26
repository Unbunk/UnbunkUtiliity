-- Modules/PlayerDeathAnimation/UI/ConfigWindow.lua

local function CreatePlayerDeathPanel(parent)
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
        label   = "Enable Player Death Animation",
        checked = PlayerDeathCfg_Get("enabled") ~= false,
        onClick = function(val) PlayerDeathCfg_Set("enabled", val) end,
    })
    enableCb.frame:SetPoint("TOPLEFT", enableFrame, "TOPLEFT", 0, 0)
    AddModule(enableFrame, 24)

    -- ── Test button ───────────────────────────────────────────────────────────

    local testFrame = CreateFrame("Frame", nil, content)
    testFrame:SetHeight(26)
    local testBtn = Unbunk_CreateButton({
        parent  = testFrame,
        label   = "Test",
        width   = 80,
        height  = 22,
        onClick = function()
            if PlayerDeathCfg_Get("soundEnabled") then
                PlayerDeath_PlaySound()
            end
            PlayerDeathAnim_Play()
        end,
    })
    testBtn.frame:SetPoint("TOPLEFT", testFrame, "TOPLEFT", 0, -2)
    AddModule(testFrame, 26)

    -- ── Sound ─────────────────────────────────────────────────────────────────

    local soundResult = HealerRange_CreateSoundPicker(content, LSM, {
        label          = "Sound on death",
        getSoundKey    = function() return PlayerDeathCfg_Get("soundKey") end,
        getSoundEnable = function() return PlayerDeathCfg_Get("soundEnabled") end,
        onSoundSelect  = function(key, path)
            PlayerDeathCfg_Set("soundKey", key)
            PlayerDeathCfg_Set("soundPath", path)
        end,
        onEnableToggle = function(val) PlayerDeathCfg_Set("soundEnabled", val) end,
        onTest         = function() PlayerDeath_PlaySound() end,
    })
    AddModule(soundResult.frame, soundResult.height)

    -- ── Animation checkbox ────────────────────────────────────────────────────

    local animCbFrame = CreateFrame("Frame", nil, content)
    animCbFrame:SetHeight(24)
    local animCb = Unbunk_CreateCheckbox({
        parent  = animCbFrame,
        label   = "Show animation on death",
        checked = PlayerDeathCfg_Get("animEnabled") ~= false,
        onClick = function(val) PlayerDeathCfg_Set("animEnabled", val) end,
    })
    animCb.frame:SetPoint("TOPLEFT", animCbFrame, "TOPLEFT", 0, 0)
    AddModule(animCbFrame, 24)

    -- ── Animation picker ──────────────────────────────────────────────────────

    local animPickerFrame = CreateFrame("Frame", nil, content)
    animPickerFrame:SetHeight(50)

    local animPickerLbl = animPickerFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    animPickerLbl:SetPoint("TOPLEFT", animPickerFrame, "TOPLEFT", 0, 0)
    animPickerLbl:SetText("Animation")

    local animAnchor = animPickerFrame:CreateFontString(nil, "ARTWORK")
    animAnchor:SetPoint("TOPLEFT", animPickerFrame, "TOPLEFT", 0, -20)

    local animDD = HealerRange_CreateDropdown({
        parent        = animPickerFrame,
        anchorFrame   = animAnchor,
        width         = 200,
        itemHeight    = 20,
        visibleItems  = 6,
        getList       = function()
            local list = {}
            if UNBUNK_ANIMATIONS then
                for _, anim in ipairs(UNBUNK_ANIMATIONS) do
                    table.insert(list, anim.label)
                end
            end
            return list
        end,
        getCurrentKey = function()
            local idx = PlayerDeathCfg_Get("animIndex") or 1
            if UNBUNK_ANIMATIONS and UNBUNK_ANIMATIONS[idx] then
                return UNBUNK_ANIMATIONS[idx].label
            end
            return ""
        end,
        onSelect      = function(label)
            if UNBUNK_ANIMATIONS then
                for i, anim in ipairs(UNBUNK_ANIMATIONS) do
                    if anim.label == label then
                        PlayerDeathCfg_Set("animIndex", i)
                        break
                    end
                end
            end
        end,
    })

    AddModule(animPickerFrame, 50)

    -- ── FPS ───────────────────────────────────────────────────────────────────

    local fpsFrame = CreateFrame("Frame", nil, content)
    fpsFrame:SetHeight(46)

    local fpsLbl = fpsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fpsLbl:SetPoint("TOPLEFT", fpsFrame, "TOPLEFT", 0, 0)
    fpsLbl:SetText("Frames per second")

    local fpsMinusBtn = Unbunk_CreateButton({
        parent = fpsFrame,
        label  = "-",
        width  = 22,
        height = 22,
    })
    fpsMinusBtn.frame:SetPoint("TOPLEFT", fpsFrame, "TOPLEFT", 0, -20)

    local fpsInput = Unbunk_CreateTextInput({
        parent     = fpsFrame,
        width      = 46,
        height     = 22,
        numeric    = true,
        maxLetters = 2,
        text       = tostring(PlayerDeathCfg_Get("animFPS") or 24),
        onEnter    = function(val)
            if val and val > 0 then
                PlayerDeathCfg_Set("animFPS", val)
            end
        end,
    })
    fpsInput.frame:SetPoint("LEFT", fpsMinusBtn.frame, "RIGHT", 4, 0)

    local fpsPlusBtn = Unbunk_CreateButton({
        parent = fpsFrame,
        label  = "+",
        width  = 22,
        height = 22,
    })
    fpsPlusBtn.frame:SetPoint("LEFT", fpsInput.frame, "RIGHT", 4, 0)

    local fpsSecLbl = fpsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fpsSecLbl:SetPoint("LEFT", fpsPlusBtn.frame, "RIGHT", 6, 0)
    fpsSecLbl:SetText("fps")

    fpsMinusBtn.frame:SetScript("OnClick", function()
        local v = tonumber(fpsInput.GetText()) or 24
        v = math.max(1, v - 1)
        fpsInput.SetText(tostring(v))
        PlayerDeathCfg_Set("animFPS", v)
    end)

    fpsPlusBtn.frame:SetScript("OnClick", function()
        local v = tonumber(fpsInput.GetText()) or 24
        v = math.min(60, v + 1)
        fpsInput.SetText(tostring(v))
        PlayerDeathCfg_Set("animFPS", v)
    end)

    AddModule(fpsFrame, 46)

    -- ── Duration editor ───────────────────────────────────────────────────────

    local de = Unbunk_CreateDurationEditor({
        parent           = content,
        getDuration      = function() return PlayerDeathCfg_Get("animDuration") end,
        onDurationChange = function(val) PlayerDeathCfg_Set("animDuration", val) end,
    })
    AddModule(de.frame, de.height)

    -- ── Loop checkbox ─────────────────────────────────────────────────────────

    local loopFrame = CreateFrame("Frame", nil, content)
    loopFrame:SetHeight(24)
    local loopCb = Unbunk_CreateCheckbox({
        parent  = loopFrame,
        label   = "Loop animation until duration ends",
        checked = PlayerDeathCfg_Get("animLoop") or false,
        onClick = function(val) PlayerDeathCfg_Set("animLoop", val) end,
    })
    loopCb.frame:SetPoint("TOPLEFT", loopFrame, "TOPLEFT", 0, 0)
    AddModule(loopFrame, 24)

    -- ── Animation size ────────────────────────────────────────────────────────

    local sizeFrame = CreateFrame("Frame", nil, content)
    sizeFrame:SetHeight(46)

    local sizeLbl = sizeFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sizeLbl:SetPoint("TOPLEFT", sizeFrame, "TOPLEFT", 0, 0)
    sizeLbl:SetText("Animation size")

    local wLbl = sizeFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    wLbl:SetPoint("TOPLEFT", sizeFrame, "TOPLEFT", 0, -20)
    wLbl:SetText("W")

    local wInput = Unbunk_CreateTextInput({
        parent     = sizeFrame,
        width      = 60,
        height     = 22,
        numeric    = true,
        maxLetters = 4,
        text       = tostring(PlayerDeathCfg_Get("animWidth") or 300),
        onEnter    = function(val)
            if val and val > 0 then
                PlayerDeathCfg_Set("animWidth", val)
                PlayerDeathAnim_ApplySize()
            end
        end,
    })
    wInput.frame:SetPoint("LEFT", wLbl, "RIGHT", 4, 0)

    local hLbl = sizeFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hLbl:SetPoint("LEFT", wInput.frame, "RIGHT", 12, 0)
    hLbl:SetText("H")

    local hInput = Unbunk_CreateTextInput({
        parent     = sizeFrame,
        width      = 60,
        height     = 22,
        numeric    = true,
        maxLetters = 4,
        text       = tostring(PlayerDeathCfg_Get("animHeight") or 300),
        onEnter    = function(val)
            if val and val > 0 then
                PlayerDeathCfg_Set("animHeight", val)
                PlayerDeathAnim_ApplySize()
            end
        end,
    })
    hInput.frame:SetPoint("LEFT", hLbl, "RIGHT", 4, 0)

    AddModule(sizeFrame, 46)

    -- ── Position editor ───────────────────────────────────────────────────────

    PlayerDeathPE = HealerRange_CreatePositionEditor(content, {
        label      = "Animation position (offset from screen center)",
        getX       = function() return PlayerDeathCfg_Get("posX") end,
        getY       = function() return PlayerDeathCfg_Get("posY") end,
        onApply    = function(x, yv)
            if x  then PlayerDeathCfg_Set("posX", x)  end
            if yv then PlayerDeathCfg_Set("posY", yv) end
            PlayerDeathAnim_ApplyPosition()
        end,
        onUnlock   = function() PlayerDeathAnim_SetUnlocked(true) end,
        onLock     = function()
            PlayerDeathAnim_SetUnlocked(false)
            if PlayerDeathPE then PlayerDeathPE.Refresh() end
        end,
        isUnlocked = function() return PlayerDeathAnim_IsUnlocked() end,
    })
    AddModule(PlayerDeathPE.frame, PlayerDeathPE.height)

    -- ── OnShow refresh ────────────────────────────────────────────────────────

    parent:HookScript("OnShow", function()
        enableCb.SetChecked(PlayerDeathCfg_Get("enabled") ~= false)
        animCb.SetChecked(PlayerDeathCfg_Get("animEnabled") ~= false)
        soundResult.Refresh()
        de.Refresh()
        wInput.SetText(tostring(PlayerDeathCfg_Get("animWidth") or 300))
        hInput.SetText(tostring(PlayerDeathCfg_Get("animHeight") or 300))
        PlayerDeathPE.Refresh()
        local idx = PlayerDeathCfg_Get("animIndex") or 1
        if UNBUNK_ANIMATIONS and UNBUNK_ANIMATIONS[idx] then
            animDD.selectedText:SetText(UNBUNK_ANIMATIONS[idx].label)
        end
        fpsInput.SetText(tostring(PlayerDeathCfg_Get("animFPS") or 24))
        loopCb.SetChecked(PlayerDeathCfg_Get("animLoop") or false)
    end)
end

-- ── Enregistrement ────────────────────────────────────────────────────────────

local initPDA = CreateFrame("Frame")
initPDA:RegisterEvent("ADDON_LOADED")
initPDA:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "UnbunkUtility" then return end
    UnbunkUtility.RegisterModule("Death Anim", nil, CreatePlayerDeathPanel)
    self:UnregisterEvent("ADDON_LOADED")
end)