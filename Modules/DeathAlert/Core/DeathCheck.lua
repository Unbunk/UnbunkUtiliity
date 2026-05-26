-- Modules/DeathAlert/Core/DeathCheck.lua

local TANK_ROLES   = { TANK = true }
local HEALER_ROLES = { HEALER = true }
local DPS_ROLES    = { DAMAGER = true }

local function IsDeathAlertActiveInCurrentInstance(prefix)
    local filter = DeathAlertCfg_Get(prefix .. "InstanceFilter")
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

local function ShowAlert(frame, duration)
    frame:Show()
    C_Timer.After(duration, function()
        if not frame:IsMovable() then
            frame:Hide()
        end
    end)
end

local alertedGuids = {}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_FLAGS")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_REGEN_ENABLED" then
        alertedGuids = {}
        return
    end

    if event == "GROUP_ROSTER_UPDATE" then
        alertedGuids = {}
        return
    end

    if event == "UNIT_FLAGS" then
        if not unit then return end
        if not string.match(unit, "^party%d+$") and not string.match(unit, "^raid%d+$") then return end
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            local guid = UnitGUID(unit)
            if guid and type(guid) == "string" then
                alertedGuids[guid] = nil
            end
        end
        return
    end

    if not IsInGroup() and not IsInRaid() then return end

    local prefix = IsInRaid() and "raid" or "party"
    local count  = IsInRaid() and GetNumGroupMembers() or GetNumSubgroupMembers()

    for i = 1, count do
        local unit = prefix .. i
        if UnitExists(unit) then
            local role = UnitGroupRolesAssigned(unit)

            local guid = UnitGUID(unit)
            if guid and UnitIsDeadOrGhost(unit) and not alertedGuids[guid] then
                alertedGuids[guid] = true

                if TANK_ROLES[role] and DeathAlertCfg_Get("tankEnabled") and IsDeathAlertActiveInCurrentInstance("tank") then
                    if not DeathAlert_IsTankTesting() then
                        ShowAlert(DeathAlert_GetTankFrame(), DeathAlertCfg_Get("tankAlertDuration") or 5)
                        DeathAlertPlaySound("tank")
                    end
                elseif HEALER_ROLES[role] and DeathAlertCfg_Get("healerEnabled") and IsDeathAlertActiveInCurrentInstance("healer") then
                    if not DeathAlert_IsHealerTesting() then
                        ShowAlert(DeathAlert_GetHealerFrame(), DeathAlertCfg_Get("healerAlertDuration") or 5)
                        DeathAlertPlaySound("healer")
                    end
                elseif DPS_ROLES[role] and DeathAlertCfg_Get("dpsEnabled") and IsDeathAlertActiveInCurrentInstance("dps") then
                    if not DeathAlert_IsDpsTesting() then
                        ShowAlert(DeathAlert_GetDpsFrame(), DeathAlertCfg_Get("dpsAlertDuration") or 5)
                        DeathAlertPlaySound("dps")
                    end
                end
            end
        end
    end
end)