-- Modules/BLTracker/Core/BLTracker.lua

local BL_SPELLS = {
    [2825]   = { name = "Bloodlust",          icon = 136012,  debuff = 57724  },
    [32182]  = { name = "Heroism",             icon = 135413,  debuff = 57723  },
    [80353]  = { name = "Time Warp",           icon = 606545,  debuff = 80354  },
    [90355]  = { name = "Ancient Hysteria",    icon = 237589,  debuff = 95809  },
    [264667] = { name = "Primal Rage",         icon = 132276,  debuff = 264689 },
    [390386] = { name = "Fury of the Aspects", icon = 4622460, debuff = 390527 },
}

local BL_BUFFS = {
    [2825]   = true, -- Bloodlust
    [32182]  = true, -- Heroism
    [80353]  = true, -- Time Warp
    [90355]  = true, -- Ancient Hysteria
    [264667] = true, -- Primal Rage
    [390386] = true, -- Fury of the Aspects
}

local BL_DEBUFFS = {}
for _, data in pairs(BL_SPELLS) do
    BL_DEBUFFS[data.debuff] = data
end

local BL_CLASSES = {
    SHAMAN = true,
    MAGE   = true,
    EVOKER = true,
}
local BL_PET_CLASSES = {
    HUNTER = true,
}

local DEFAULT_CLASS_SPELLS = {
    SHAMAN = 2825,   -- Bloodlust
    MAGE   = 80353,  -- Time Warp
    EVOKER = 390386, -- Fury of the Aspects
    HUNTER = 264667, -- Primal Rage
}

local function GetDefaultClassIcon(class)
    local spellId = DEFAULT_CLASS_SPELLS[class]
    if not spellId then return nil end
    local spellInfo = C_Spell.GetSpellInfo(spellId)
    return spellInfo and spellInfo.iconID or nil
end

local playerHasBL  = false
local playerClass  = nil
local currentIcon  = nil
local hasDebuff    = false

-- ── TimerIcon ─────────────────────────────────────────────────────────────────

local blIcon = Unbunk_CreateTimerIcon({
    name    = "BLTrackerFrame",
    getCfg  = function(key) return BLTrackerCfg_Get(key) end,
    onDragStop = function(x, y)
        BLTrackerCfg_Set("posX", x)
        BLTrackerCfg_Set("posY", y)
        if BLTrackerPE then BLTrackerPE.Refresh() end
    end,
})

blIcon.onExpire = function() end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function IsActiveInCurrentInstance()
    local filter = BLTrackerCfg_Get("instanceFilter")
    if not filter then return true end
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return filter.outdoor ~= false
    elseif instanceType == "party" then
        return filter.dungeon ~= false
    elseif instanceType == "raid" then
        return filter.raid ~= false
    elseif instanceType == "pvp" or instanceType == "arena" then
        return filter.battleground ~= false
    end
    return false
end

local function CheckPlayerHasBL()
    local _, class = UnitClass("player")
    playerClass = class
    playerHasBL = BL_CLASSES[class] or BL_PET_CLASSES[class] or false
end

function ApplyVisuals_BL()
    if not BLTrackerCfg_Get("enabled") or not IsActiveInCurrentInstance() then
        blIcon.Hide()
        return
    end
    if not BLTrackerCfg_Get("showIcon") then
        blIcon.Hide()
    else
        local icon = currentIcon or (playerClass and GetDefaultClassIcon(playerClass))
        if icon then blIcon.SetIcon(icon) end
        blIcon.ApplySize()
        if hasDebuff or playerHasBL then
            blIcon.Show()
        else
            blIcon.Hide()
        end
    end
    -- Affiche le check seulement si pas de debuff
    if not hasDebuff and playerHasBL then
        blIcon.ShowCheck()
    else
        blIcon.HideCheck()
    end
end

-- ── Public API ────────────────────────────────────────────────────────────────

function BLTracker_ApplyFont()     blIcon.ApplyFont()     end
function BLTracker_ApplyPosition() blIcon.ApplyPosition() end
function BLTracker_ApplySize()     blIcon.ApplySize()     end
function BLTracker_SetUnlocked(v)  blIcon.SetUnlocked(v)  end
function BLTracker_IsUnlocked()    return blIcon.IsUnlocked() end
function BLTracker_GetFrame()      return blIcon.GetFrame() end

function BLTracker_PlaySound(key)
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local path = BLTrackerCfg_Get(key)
    if path then
        PlaySoundFile(path, "Master")
    elseif LSM then
        local soundKey = BLTrackerCfg_Get(key:gsub("Path", "Key"))
        local soundPath = soundKey and LSM:Fetch("sound", soundKey)
        if soundPath then PlaySoundFile(soundPath, "Master") end
    end
end

-- ── Events ────────────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellId = ...
        if not spellId then return end
        if not unit then return end
        if unit ~= "player" 
            and unit ~= "party1" and unit ~= "party2" and unit ~= "party3" and unit ~= "party4"
            and not (unit and #unit >= 5 and unit:sub(1,4) == "raid") then
            return
        end
        if BL_SPELLS[spellId] then
            local spellInfo = C_Spell.GetSpellInfo(spellId)
            currentIcon = spellInfo and spellInfo.iconID or BL_SPELLS[spellId].icon
            if BLTrackerCfg_Get("soundOnBL") then
                BLTracker_PlaySound("soundPathBL")
            end
            ApplyVisuals_BL()
        end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" or event == "SPELLS_CHANGED" then
        CheckPlayerHasBL()
        if not hasDebuff and playerClass then
            currentIcon = GetDefaultClassIcon(playerClass)
        end
        ApplyVisuals_BL()
        return
    end

    if event == "UNIT_AURA" then
        -- géré par le ticker
        return
    end
end)

local ALL_BL_IDS = {}
for debuffId in pairs(BL_DEBUFFS) do
    ALL_BL_IDS[debuffId] = true
end

local hasBuff = false

local function SyncDebuff()
    if not BLTrackerCfg_Get("enabled") then return end

    -- Check buff positif d'abord
    local foundBuff = false
    for i = 1, 40 do
        local success, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if success and aura then
            if BL_BUFFS[aura.spellId] then
                foundBuff = true
                currentIcon = aura.icon
                if not hasBuff then
                    hasBuff = true
                end
                blIcon.SetTimer(aura.expirationTime, aura.duration, { r=0, g=1, b=0 })
                break
            end
        end
    end

    if foundBuff then
        hasDebuff = false
        ApplyVisuals_BL()
        return
    end

    if hasBuff and not foundBuff then
        hasBuff = false
        -- Ne pas ClearTimer ici, on vérifie d'abord le debuff
    end

    -- Check debuff ensuite
    local foundDebuff = false
    for i = 1, 40 do
        local success, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HARMFUL")
        if success and aura then
            if ALL_BL_IDS[aura.spellId] then
                foundDebuff = true
                currentIcon = aura.icon
                if not hasDebuff then
                    hasDebuff = true
                end
                blIcon.SetTimer(aura.expirationTime, aura.duration)
                break
            end
        end
    end

    if not foundDebuff then
        if hasDebuff then
            hasDebuff = false
            currentIcon = GetDefaultClassIcon(playerClass)
            if BLTrackerCfg_Get("soundOnReady") then
                BLTracker_PlaySound("soundPathReady")
            end
            blIcon.ClearTimer()
        elseif not hasBuff then
            blIcon.ClearTimer()
        end
    end

    ApplyVisuals_BL()
end

C_Timer.NewTicker(0.5, function()
    SyncDebuff()
end)

local initBL = CreateFrame("Frame")
initBL:RegisterEvent("PLAYER_LOGIN")
initBL:SetScript("OnEvent", function(self)
    CheckPlayerHasBL()
    currentIcon = GetDefaultClassIcon(playerClass)
    BLTracker_ApplyPosition()
    BLTracker_ApplyFont()
    BLTracker_ApplySize()
    ApplyVisuals_BL()
    self:UnregisterEvent("PLAYER_LOGIN")
end)