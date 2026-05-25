-- Core/SlashCommands.lua

local function OpenConfig()
    if Unbunk and Unbunk.OpenWindow then
        Unbunk.OpenWindow()
    else
        print("|cffff4444[Unbunk]|r Config panel not ready yet.")
    end
end

local function PrintHelp()
    print("|cffff4444[Unbunk]|r Commands:")
    print("  |cffffd700/ub|r or |cffffd700/ub config|r — open settings")
    print("  |cffffd700/ub help|r — show this help")
    print("  |cffffd700/ub test|r — test healer range alert")
    print("  |cffffd700/ub lock|r — lock alert position")
    print("  |cffffd700/ub reset|r — reset alert position")
end

SLASH_UNBUNK1 = "/ub"
SlashCmdList["UNBUNK"] = function(msg)
    local cmd = strtrim(msg):lower()

    if cmd == "" or cmd == "config" or cmd == "options" then
        OpenConfig()
    elseif cmd == "help" then
        PrintHelp()
    elseif cmd == "test" then
        HealerRangeAlert_SetTesting(true)
        HealerRangeAlert_GetFrame():Show()
        HealerRangePlaySound()
        print("|cffff4444[Unbunk]|r Alert test — disappears in 5 seconds.")
        C_Timer.After(5, function()
            HealerRangeAlert_SetTesting(false)
            if not HealerRangeAlert_IsUnlocked() then
                HealerRangeAlert_GetFrame():Hide()
            end
        end)
    elseif cmd == "lock" then
        if HealerRangeAlert_SetUnlocked then HealerRangeAlert_SetUnlocked(false) end
        print("|cffff4444[Unbunk]|r Alert locked and position saved.")
    elseif cmd == "reset" then
        HealerRangeCfg_Set("posX", 0)
        HealerRangeCfg_Set("posY", 100)
        HealerRangeAlert_ApplyPosition()
        print("|cffff4444[Unbunk]|r Position reset.")
    else
        print("|cffff4444[Unbunk]|r Unknown command. Type |cffffd700/ub help|r for the list.")
    end
end

print("|cffff4444[Unbunk]|r Loaded. Type /ub for help.")