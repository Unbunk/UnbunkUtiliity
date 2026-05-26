-- Core/Profiles.lua

local ALL_DBS = {
    HealerRange    = function() return HealerRangeDB    end,
    DeathAlert     = function() return DeathAlertDB     end,
    BLTracker      = function() return BLTrackerDB      end,
    PotionTracker  = function() return PotionTrackerDB  end,
    TrinketTracker = function() return TrinketTrackerDB end,
    PITracker = function() return PITrackerDB end,
    PlayerDeath = function() return PlayerDeathDB end,
}

local ALL_SETTERS = {
    HealerRange    = function(t) HealerRangeDB    = t end,
    DeathAlert     = function(t) DeathAlertDB     = t end,
    BLTracker      = function(t) BLTrackerDB      = t end,
    PotionTracker  = function(t) PotionTrackerDB  = t end,
    TrinketTracker = function(t) TrinketTrackerDB = t end,
    PITracker = function(t) PITrackerDB = t end,
    PlayerDeath = function(t) PlayerDeathDB = t end,
}

local function InitDB()
    UnbunkUtilityDB = UnbunkUtilityDB or {}
    UnbunkUtilityDB.currentProfile = UnbunkUtilityDB.currentProfile or "Default"
    UnbunkUtilityDB.profiles       = UnbunkUtilityDB.profiles or {}
    if not UnbunkUtilityDB.profiles["Default"] then
        UnbunkUtilityDB.profiles["Default"] = {}
    end
end

-- Sérialise une table en string
local function Serialize(t, indent)
    indent = indent or ""
    if type(t) ~= "table" then
        if type(t) == "string" then
            return string.format("%q", t)
        else
            return tostring(t)
        end
    end
    local result = "{"
    for k, v in pairs(t) do
        local key
        if type(k) == "string" then
            key = '["' .. k .. '"]'
        else
            key = "[" .. tostring(k) .. "]"
        end
        result = result .. key .. "=" .. Serialize(v) .. ","
    end
    return result .. "}"
end

-- Désérialise une string en table
local function Deserialize(str)
    local fn, err = loadstring("return " .. str)
    if not fn then return nil, err end
    local ok, result = pcall(fn)
    if not ok then return nil, result end
    return result
end

-- Encode en base64
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function Base64Encode(data)
    return ((data:gsub(".", function(x)
        local r, b = "", x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i-1) > 0 and "1" or "0") end
        return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x < 6 then return "" end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2^(6-i) or 0) end
        return b64chars:sub(c+1, c+1)
    end) .. ({ "", "==", "=" })[#data % 3 + 1])
end

local function Base64Decode(data)
    data = data:gsub("[^" .. b64chars .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (b64chars:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d%d%d%d%d%d", function(x)
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- ── API publique ──────────────────────────────────────────────────────────────

function UnbunkProfiles_GetCurrent()
    return UnbunkUtilityDB.currentProfile or "Default"
end

function UnbunkProfiles_GetList()
    local list = {}
    for name in pairs(UnbunkUtilityDB.profiles) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

function UnbunkProfiles_SaveCurrent()
    local name = UnbunkProfiles_GetCurrent()
    local snapshot = {}
    for dbName, getter in pairs(ALL_DBS) do
        snapshot[dbName] = DeepCopy(getter())
    end
    UnbunkUtilityDB.profiles[name] = snapshot
end

function UnbunkProfiles_Load(name)
    if not UnbunkUtilityDB.profiles[name] then return false end
    local snapshot = UnbunkUtilityDB.profiles[name]
    for dbName, setter in pairs(ALL_SETTERS) do
        if snapshot[dbName] then
            setter(DeepCopy(snapshot[dbName]))
        end
    end
    UnbunkUtilityDB.currentProfile = name
    UnbunkProfiles_ReloadAll()
    return true
end

function UnbunkProfiles_Create(name)
    if not name or name == "" then return false end
    if UnbunkUtilityDB.profiles[name] then return false end
    -- Sauvegarde d'abord le profil actuel
    UnbunkProfiles_SaveCurrent()
    -- Crée le nouveau profil comme copie du profil actuel
    local currentName = UnbunkProfiles_GetCurrent()
    UnbunkUtilityDB.profiles[name] = DeepCopy(UnbunkUtilityDB.profiles[currentName])
    UnbunkUtilityDB.currentProfile = name
    return true
end

function UnbunkProfiles_Delete(name)
    if name == "Default" then return false end
    if not UnbunkUtilityDB.profiles[name] then return false end
    UnbunkUtilityDB.profiles[name] = nil
    if UnbunkProfiles_GetCurrent() == name then
        UnbunkProfiles_Load("Default")
    end
    return true
end

function UnbunkProfiles_Export()
    UnbunkProfiles_SaveCurrent()
    local name = UnbunkProfiles_GetCurrent()
    local data = Serialize(UnbunkUtilityDB.profiles[name])
    return Base64Encode(data)
end

function UnbunkProfiles_Import(str)
    local data = Base64Decode(str)
    local t, err = Deserialize(data)
    if not t then return false, err end
    local name = UnbunkProfiles_GetCurrent()
    UnbunkUtilityDB.profiles[name] = t
    UnbunkProfiles_Load(name)
    return true
end

function UnbunkProfiles_ReloadAll()
    -- HealerRange
    if HealerRangeAlert_ApplyFont then HealerRangeAlert_ApplyFont() end
    if HealerRangeAlert_ApplyColor then HealerRangeAlert_ApplyColor() end
    if HealerRangeAlert_ApplyMessage then HealerRangeAlert_ApplyMessage() end
    if HealerRangeAlert_ApplyPosition then HealerRangeAlert_ApplyPosition() end
    if HealerRangeAlert_ApplyIcon then HealerRangeAlert_ApplyIcon() end
    -- DeathAlert
    if DeathAlert_ApplyTankFont then DeathAlert_ApplyTankFont() end
    if DeathAlert_ApplyTankColor then DeathAlert_ApplyTankColor() end
    if DeathAlert_ApplyTankMessage then DeathAlert_ApplyTankMessage() end
    if DeathAlert_ApplyTankPosition then DeathAlert_ApplyTankPosition() end
    if DeathAlert_ApplyTankIcon then DeathAlert_ApplyTankIcon() end
    if DeathAlert_ApplyHealerFont then DeathAlert_ApplyHealerFont() end
    if DeathAlert_ApplyHealerColor then DeathAlert_ApplyHealerColor() end
    if DeathAlert_ApplyHealerMessage then DeathAlert_ApplyHealerMessage() end
    if DeathAlert_ApplyHealerPosition then DeathAlert_ApplyHealerPosition() end
    if DeathAlert_ApplyHealerIcon then DeathAlert_ApplyHealerIcon() end
    if DeathAlert_ApplyDpsFont then DeathAlert_ApplyDpsFont() end
    if DeathAlert_ApplyDpsColor then DeathAlert_ApplyDpsColor() end
    if DeathAlert_ApplyDpsMessage then DeathAlert_ApplyDpsMessage() end
    if DeathAlert_ApplyDpsPosition then DeathAlert_ApplyDpsPosition() end
    if DeathAlert_ApplyDpsIcon then DeathAlert_ApplyDpsIcon() end
    -- BLTracker
    if BLTracker_ApplyFont then BLTracker_ApplyFont() end
    if BLTracker_ApplyPosition then BLTracker_ApplyPosition() end
    if BLTracker_ApplySize then BLTracker_ApplySize() end
    -- PotionTracker
    if PotionTracker_ApplyAll then PotionTracker_ApplyAll() end
    -- TrinketTracker
    if TrinketTracker_ApplyAll then TrinketTracker_ApplyAll() end
    -- Refresh le panel actif si ouvert
    if UnbunkUtility and UnbunkUtility.registeredModules then
        for _, mod in ipairs(UnbunkUtility.registeredModules) do
            if mod.frame then
                -- Force recréation du frame pour tout refresher
                mod.frame:Hide()
                mod.frame = nil
            end
        end
        -- Réaffiche le module actif
        if UnbunkUtility.ShowActiveModule then
            UnbunkUtility.ShowActiveModule();
        end
    end
    -- PITracker
    if PITracker_ApplyFont then PITracker_ApplyFont() end
    if PITracker_ApplyPosition then PITracker_ApplyPosition() end
    if PITracker_ApplySize then PITracker_ApplySize() end
    -- PlayerDeathAnimation
    if PlayerDeathAnim_ApplyPosition then PlayerDeathAnim_ApplyPosition() end
    if PlayerDeathAnim_ApplySize then PlayerDeathAnim_ApplySize() end
end

local initProfiles = CreateFrame("Frame")
initProfiles:RegisterEvent("ADDON_LOADED")
initProfiles:RegisterEvent("PLAYER_LOGOUT")
initProfiles:SetScript("OnEvent", function(self, event, addonName)
    if event == "PLAYER_LOGOUT" then
        UnbunkProfiles_SaveCurrent()
        return
    end
    if addonName ~= "UnbunkUtility" then return end
    InitDB()
    self:UnregisterEvent("ADDON_LOADED")
end)