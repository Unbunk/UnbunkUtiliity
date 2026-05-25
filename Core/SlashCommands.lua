-- Core/SlashCommands.lua

local function OpenConfig()
    if UnbunkUtility and UnbunkUtility.OpenWindow then
        UnbunkUtility.OpenWindow()
    else
        print("|cffff4444[UnbunkUtility]|r Config panel not ready yet.")
    end
end

local function PrintHelp()
    print("|cffff4444[UnbunkUtility]|r Commands:")
    print("  |cffffd700/ubu|r or |cffffd700/ubu config|r — open settings")
    print("  |cffffd700/ubu help|r — show this help")
    print("  |cffffd700/ubu test|r — test healer range alert")
    print("  |cffffd700/ubu lock|r — lock alert position")
    print("  |cffffd700/ubu reset|r — reset alert position")
end

SLASH_UNBUNKUTILITY1 = "/ubu"
SlashCmdList["UNBUNKUTILITY"] = function(msg)
    local cmd = strtrim(msg):lower()

    if cmd == "" or cmd == "config" or cmd == "options" then
        OpenConfig()
    elseif cmd == "help" then
        PrintHelp()
    elseif cmd == "test" then
        HealerRangeAlert_SetTesting(true)
        HealerRangeAlert_GetFrame():Show()
        HealerRangePlaySound()
        print("|cffff4444[UnbunkUtility]|r Alert test — disappears in 5 seconds.")
        C_Timer.After(5, function()
            HealerRangeAlert_SetTesting(false)
            if not HealerRangeAlert_IsUnlocked() then
                HealerRangeAlert_GetFrame():Hide()
            end
        end)
    elseif cmd == "lock" then
        if HealerRangeAlert_SetUnlocked then HealerRangeAlert_SetUnlocked(false) end
        print("|cffff4444[UnbunkUtility]|r Alert locked and position saved.")
    elseif cmd == "reset" then
        HealerRangeCfg_Set("posX", 0)
        HealerRangeCfg_Set("posY", 100)
        HealerRangeAlert_ApplyPosition()
        print("|cffff4444[UnbunkUtility]|r Position reset.")
    else
        print("|cffff4444[UnbunkUtility]|r Unknown command. Type |cffffd700/ubu help|r for the list.")
    end
end

print("|cffff4444[UnbunkUtility]|r Loaded. Type /ubu for help.")