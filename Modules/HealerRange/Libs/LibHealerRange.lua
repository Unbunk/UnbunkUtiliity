-- LibHealerRange.lua
-- Range detection using UnitDistanceSquared (out of combat) and C_Spell.IsSpellInRange (in combat).
-- Compatible with WoW Midnight (12.0.5).

LibHealerRange = {}
local Lib = LibHealerRange

local SPEC_RANGES = {
    [105]  = 40,  -- Restoration Druid
    [270]  = 40,  -- Mistweaver Monk
    [65]   = 40,  -- Holy Paladin
    [256]  = 40,  -- Discipline Priest
    [257]  = 40,  -- Holy Priest
    [264]  = 40,  -- Restoration Shaman
    [1468] = 25,  -- Preservation Evoker
}

-- ─── Spell probes (used in combat, friendly target only) ─────────────────────

local SPELL_PROBES = {
    1459,   -- Arcane Intellect (Mage, 40y)
    475,    -- Remove Curse (Mage, 40y)
    130,    -- Slow Fall (Mage, 40y)
    366,    -- Resurrection (Priest, 40y)
    20484,  -- Rebirth (Druid, 40y)
    7328,   -- Redemption (Paladin, 40y)
    2008,   -- Ancestral Spirit (Shaman, 40y)
    61999,  -- Raise Ally (Death Knight, 40y)
    34477,  -- Misdirection (Hunter, 40y)
    115546, -- Provoke (Monk, 40y)
    361227, -- Return (Evoker, 40y)
    20707,  -- Soulstone (Warlock, 40y)
}

-- ─── Item probes ──────────────────────────────────────────────────────────────

local ITEM_PROBES_40Y = {
    3012,   -- Scroll of Strength
    1477,   -- Scroll of Agility
    1180,   -- Scroll of Stamina
    955,    -- Scroll of Intellect
    1711,   -- Scroll of Spirit
    2289,   -- Scroll of Protection
}

local ITEM_PROBES_25Y = {
    72985, 158381, 224442, 194049, 194050, 20066, 63391, 19068, 20237,
    19067, 20235, 224441, 20065, 20232, 20243, 20244, 19066, 20067,
    20234, 19307, 52014, 239711, 1251, 14530, 21991, 34721, 21990,
    34722, 194048, 53050, 53051, 133940, 72986, 3530, 6451, 14529,
    8544, 8545, 3531, 239713, 173191, 6450, 224440, 160433, 211943,
    2581, 158382, 173192, 53049, 111603,
}

local availableProbes    = {}
local availableItemProbe40y = nil
local availableItemProbe25y = nil

local function BuildAvailableProbes()
    availableProbes = {}
    for _, spellId in ipairs(SPELL_PROBES) do
        if C_Spell.GetSpellInfo(spellId) then
            table.insert(availableProbes, spellId)
        end
    end

    availableItemProbe40y = nil
    for _, itemId in ipairs(ITEM_PROBES_40Y) do
        if C_Item.GetItemCount(itemId) and C_Item.GetItemCount(itemId) > 0 then
            availableItemProbe40y = itemId
            break
        end
    end

    availableItemProbe25y = nil
    for _, itemId in ipairs(ITEM_PROBES_25Y) do
        if C_Item.GetItemCount(itemId) and C_Item.GetItemCount(itemId) > 0 then
            availableItemProbe25y = itemId
            break
        end
    end
    -- Expose pour le panel config
    Lib.availableSpellProbeCount = #availableProbes
    Lib.availableItemProbe40y    = availableItemProbe40y
    Lib.availableItemProbe25y    = availableItemProbe25y
end

-- ─── Spec cache ───────────────────────────────────────────────────────────────

local guidCache = {}
local CACHE_TTL = 30

local function GetHealerRange(unit)
    local guid = UnitGUID(unit)
    if not guid then return 40 end

    local now = GetTime()
    local cached = guidCache[guid]

    if cached and (now - cached.lastUpdate) < CACHE_TTL then
        return cached.range
    end

    local specID = GetInspectSpecialization(unit)
    if specID and specID > 0 then
        local range = SPEC_RANGES[specID] or 40
        guidCache[guid] = { specID = specID, range = range, lastUpdate = now }
        return range
    end

    NotifyInspect(unit)
    return 40
end

-- Nettoie le cache quand le groupe change
local cacheFrame = CreateFrame("Frame")
cacheFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
cacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
cacheFrame:SetScript("OnEvent", function()
    local activeGUIDs = {}
    local function scanGroup(prefix, count)
        for i = 1, count do
            local unit = prefix .. i
            if UnitExists(unit) then
                local guid = UnitGUID(unit)
                if guid and guidCache[guid] then
                    activeGUIDs[guid] = guidCache[guid]
                end
            end
        end
    end
    if IsInRaid() then
        scanGroup("raid", GetNumGroupMembers())
    elseif IsInGroup() then
        scanGroup("party", GetNumSubgroupMembers())
    end
    guidCache = activeGUIDs
end)

-- Met à jour le cache quand les données d'inspect arrivent
local inspectFrame = CreateFrame("Frame")
inspectFrame:RegisterEvent("INSPECT_READY")
inspectFrame:SetScript("OnEvent", function(self, event, guid)
    if not guid then return end
    local function findUnit(prefix, count)
        for i = 1, count do
            local unit = prefix .. i
            if UnitGUID(unit) == guid then return unit end
        end
    end
    local unit = nil
    if IsInRaid() then
        unit = findUnit("raid", GetNumGroupMembers())
    elseif IsInGroup() then
        unit = findUnit("party", GetNumSubgroupMembers())
    end
    if not unit then return end
    local specID = GetInspectSpecialization(unit)
    if specID and specID > 0 then
        local range = SPEC_RANGES[specID] or 40
        guidCache[guid] = { specID = specID, range = range, lastUpdate = GetTime() }
    end
end)

-- ─── Core range estimation ────────────────────────────────────────────────────

function Lib:GetRange(unit)
    if not UnitExists(unit) then return nil end

    local healerRange = GetHealerRange(unit)
    local inCombat    = InCombatLockdown()

    if inCombat then
        if healerRange <= 25 then
            -- Evoker : on utilise uniquement le bandage (25y)
            -- Les spell probes à 40y seraient faux pour un Evoker
            if availableItemProbe25y then
                local result = C_Item.IsItemInRange(availableItemProbe25y, unit)
                if result == true then return 0
                elseif result == false then return 999
                end
            end
            -- Pas de bandage disponible : fallback spell probes
            for _, spellId in ipairs(availableProbes) do
                local result = C_Spell.IsSpellInRange(spellId, unit)
                if result == true then return 0
                elseif result == false then return 999
                end
            end
        else
            -- Autres healers (40y) : spell probes d'abord
            for _, spellId in ipairs(availableProbes) do
                local result = C_Spell.IsSpellInRange(spellId, unit)
                if result == true then return 0
                elseif result == false then return 999
                end
            end
            -- Fallback scroll si aucun sort disponible
            if availableItemProbe40y then
                local result = C_Item.IsItemInRange(availableItemProbe40y, unit)
                if result == true then return 0
                elseif result == false then return 999
                end
            end
        end

        return 999
    end

    -- Hors combat : UnitDistanceSquared donne la distance précise en yards
    local distSquared, checkedDistance = UnitDistanceSquared(unit)
    if checkedDistance and distSquared then
        local dist = math.sqrt(distSquared)
        return dist <= healerRange and 0 or 999
    end

    -- Fallback si UnitDistanceSquared indisponible
    local inRange = UnitInRange(unit)
    return inRange and 0 or 999
end

-- ─── Initialization ───────────────────────────────────────────────────────────

local initLib = CreateFrame("Frame")
initLib:RegisterEvent("SPELLS_CHANGED")
initLib:RegisterEvent("PLAYER_LOGIN")
initLib:RegisterEvent("BAG_UPDATE")
initLib:SetScript("OnEvent", function()
    BuildAvailableProbes()
end)