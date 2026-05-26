-- UI/Shared/InstanceFilter.lua
-- Reusable instance type filter widget.
--
-- Usage:
--   local iF = Unbunk_CreateInstanceFilter({
--       parent   = panel,
--       getConfig = function() return MyCfg_Get("instanceFilter") end,
--       setConfig = function(key, val) MyCfg_Set("instanceFilter."..key, val) end,
--   })
--   iF.frame
--   iF.height
--   iF.Refresh()

function Unbunk_CreateInstanceFilter(config)
    local parent    = config.parent
    local getConfig = config.getConfig
    local setConfig = config.setConfig

    local result = {}
    local height = 0

    local container = CreateFrame("Frame", nil, parent)
    container:SetWidth(518)

    local sectionLabel = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sectionLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -height)
    sectionLabel:SetText("Active in")
    height = height + 20

    local filters = {
        { key = "dungeon",     label = "Dungeon"     },
        { key = "raid",        label = "Raid"        },
        { key = "battleground",label = "Battleground"},
        { key = "outdoor",     label = "Outdoor"     },
    }

    local checkboxes = {}
    local x = 0
    local rowHeight = 24

    for i, filter in ipairs(filters) do
        local cfg = getConfig()
        local cb = Unbunk_CreateCheckbox({
            parent  = container,
            label   = filter.label,
            checked = cfg[filter.key] ~= false,
            onClick = function(val)
                setConfig(filter.key, val)
            end,
        })
        cb.frame:SetPoint("TOPLEFT", container, "TOPLEFT", x, -height)
        cb.frame:SetWidth(120)
        checkboxes[filter.key] = cb

        x = x + 130
        if i % 4 == 0 then
            x = 0
            height = height + rowHeight
        end
    end

    height = height + rowHeight

    container:SetHeight(height)
    result.frame  = container
    result.height = height

    function result.Refresh()
        local cfg = getConfig()
        for key, cb in pairs(checkboxes) do
            cb.SetChecked(cfg[key] ~= false)
        end
    end

    return result
end