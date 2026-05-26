-- Media/Media.lua
-- Registers all UnbunkUtility media into LibSharedMedia.

local initMedia = CreateFrame("Frame")
initMedia:RegisterEvent("ADDON_LOADED")
initMedia:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "UnbunkUtility" then return end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local ADDON_PATH = "Interface\\AddOns\\UnbunkUtility\\Media\\"
        local sounds = {
            ["UnbunkUtility: BL"]                 = ADDON_PATH .. "Sounds\\BL.mp3",
            ["UnbunkUtility: Bloodlust"]          = ADDON_PATH .. "Sounds\\Bloodlust.mp3",
            ["UnbunkUtility: BL Ready"]           = ADDON_PATH .. "Sounds\\BLReady.mp3",
            ["UnbunkUtility: Combat Potion"]      = ADDON_PATH .. "Sounds\\CombatPotion.mp3",
            ["UnbunkUtility: Combat Potion Ready"]= ADDON_PATH .. "Sounds\\CombatPotionReady.mp3",
            ["UnbunkUtility: Healer Died"]        = ADDON_PATH .. "Sounds\\HealerDied.mp3",
            ["UnbunkUtility: Health Potion"]      = ADDON_PATH .. "Sounds\\HealthPotion.mp3",
            ["UnbunkUtility: Health Potion Ready"]= ADDON_PATH .. "Sounds\\HealthPotionReady.mp3",
            ["UnbunkUtility: No Heal"]            = ADDON_PATH .. "Sounds\\NoHeal.mp3",
            ["UnbunkUtility: PI"]                 = ADDON_PATH .. "Sounds\\PI.mp3",
            ["UnbunkUtility: Potion Ready"]       = ADDON_PATH .. "Sounds\\PotionReady.mp3",
            ["UnbunkUtility: Tank Died"]          = ADDON_PATH .. "Sounds\\TankDied.mp3",
            ["UnbunkUtility: DPS Died"]           = ADDON_PATH .. "Sounds\\DPSDied.mp3",
            ["UnbunkUtility: Trinket"]            = ADDON_PATH .. "Sounds\\Trinket.mp3",
            ["UnbunkUtility: Trinket Ready"]      = ADDON_PATH .. "Sounds\\TrinketReady.mp3",
            ["UnbunkUtility: FAHH"]               = ADDON_PATH .. "Sounds\\FAHH.mp3",
        }
        for name, path in pairs(sounds) do
            LSM:Register("sound", name, path)
        end

        local ICON_PATH = "Interface\\AddOns\\UnbunkUtility\\Media\\Icons\\"
        UNBUNK_ICONS = {
            { label = "No Heal",     path = ICON_PATH .. "NoHeal.tga"     },
            { label = "Green Check", path = ICON_PATH .. "GreenCheck.tga" },
            { label = "Healer",      path = ICON_PATH .. "Healer.tga"     },
            { label = "Tank",        path = ICON_PATH .. "Tank.tga"       },
            { label = "DPS",         path = ICON_PATH .. "DPS.tga"        },
            { label = "Healer Died", path = ICON_PATH .. "HealerDied.tga" },
            { label = "Tank Died",   path = ICON_PATH .. "TankDied.tga"   },
            { label = "DPS Died",    path = ICON_PATH .. "DPSDied.tga"    },
        }
    end
    self:UnregisterEvent("ADDON_LOADED")
end)

-- Textures
local ICON_PATH = "Interface\\AddOns\\UnbunkUtility\\Media\\Icons\\"
UNBUNK_ICON_DROPDOWN_ARROW = "Interface\\Buttons\\Arrow-Down-Up"

-- Animations
UNBUNK_ANIMATIONS = {
    {
        label      = "Vinland Saga",
        path       = "Interface\\AddOns\\UnbunkUtility\\Media\\Animations\\Vinland Saga Animation\\Vinland Saga Animation GIF-",
        frameCount = 49,
    },
    {
        label      = "Dance Skeleton",
        path       = "Interface\\AddOns\\UnbunkUtility\\Media\\Animations\\Dance Skeleton Animation\\Dance Skeleton GIF-",
        frameCount = 10,
    },
}