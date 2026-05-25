-- UI/FontPicker.lua
-- Font picker widget.

function HealerRange_CreateFontPicker(panel, y, LSM)
    local result = {}

    if LSM then
        local anchorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        anchorLabel:SetPoint("TOPLEFT", 16, y)
        anchorLabel:SetText("")

        local dd = HealerRange_CreateDropdown({
            parent        = panel,
            anchorFrame   = anchorLabel,
            width         = 200,
            itemHeight    = 20,
            visibleItems  = 10,
            getList       = function() return LSM:List("font") end,
            getCurrentKey = function() return HealerRangeCfg_Get("fontKey") end,
            onSelect      = function(name)
                local path = LSM:Fetch("font", name)
                HealerRangeCfg_Set("fontKey",  name)
                HealerRangeCfg_Set("fontPath", path)
                if HealerRangeAlert_ApplyFont then HealerRangeAlert_ApplyFont() end
            end,
        })

        dd.selectedText:SetText(HealerRangeCfg_Get("fontKey") or "(select a font)")
        result.fontSelectedText = dd.selectedText

        local sizeLbl = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        sizeLbl:SetPoint("LEFT", dd.toggleBtn, "RIGHT", 10, 4)
        sizeLbl:SetText("Size")

        local sizeBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        sizeBox:SetSize(46, 20)
        sizeBox:SetPoint("LEFT", sizeLbl, "RIGHT", 4, -2)
        sizeBox:SetAutoFocus(false)
        sizeBox:SetNumeric(true)
        sizeBox:SetMaxLetters(3)
        result.sizeBox = sizeBox

        sizeBox:SetScript("OnEnterPressed", function(self)
            local v = tonumber(self:GetText())
            if v and v > 0 then
                HealerRangeCfg_Set("fontSize", v)
                if HealerRangeAlert_ApplyFont then HealerRangeAlert_ApplyFont() end
            end
            self:ClearFocus()
        end)

        local colorSwatch = CreateFrame("Button", nil, panel)
        colorSwatch:SetSize(16, 16)
        colorSwatch:SetPoint("LEFT", sizeBox, "RIGHT", 10, 0)

        local swatchTex = colorSwatch:CreateTexture(nil, "BACKGROUND")
        swatchTex:SetAllPoints()

        local colorLbl = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        colorLbl:SetPoint("LEFT", colorSwatch, "RIGHT", 4, 0)
        colorLbl:SetText("Color")

        local function RefreshSwatch()
            local c = HealerRangeCfg_Get("color")
            swatchTex:SetColorTexture(c.r, c.g, c.b, 1)
        end
        result.RefreshSwatch = RefreshSwatch

        colorSwatch:SetScript("OnClick", function()
            local c = HealerRangeCfg_Get("color")
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    local a = ColorPickerFrame:GetColorAlpha()
                    HealerRangeCfg_Set("color", { r = r, g = g, b = b, a = a })
                    RefreshSwatch()
                    if HealerRangeAlert_ApplyColor then HealerRangeAlert_ApplyColor() end
                end,
                opacityFunc = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    local a = ColorPickerFrame:GetColorAlpha()
                    HealerRangeCfg_Set("color", { r = r, g = g, b = b, a = a })
                    RefreshSwatch()
                    if HealerRangeAlert_ApplyColor then HealerRangeAlert_ApplyColor() end
                end,
                cancelFunc = function(prev)
                    local a = prev.a or (prev.opacity and (1 - prev.opacity)) or 1
                    HealerRangeCfg_Set("color", { r = prev.r, g = prev.g, b = prev.b, a = a })
                    RefreshSwatch()
                    if HealerRangeAlert_ApplyColor then HealerRangeAlert_ApplyColor() end
                end,
                r = c.r, g = c.g, b = c.b, opacity = c.a,
                hasOpacity = true,
            })
        end)

    else
        local sizeLbl = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        sizeLbl:SetPoint("TOPLEFT", 16, y)
        sizeLbl:SetText("Font size")

        local sizeBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        sizeBox:SetSize(46, 20)
        sizeBox:SetPoint("LEFT", sizeLbl, "RIGHT", 6, 0)
        sizeBox:SetAutoFocus(false)
        sizeBox:SetNumeric(true)
        sizeBox:SetMaxLetters(3)
        result.sizeBox = sizeBox

        sizeBox:SetScript("OnEnterPressed", function(self)
            local v = tonumber(self:GetText())
            if v and v > 0 then
                HealerRangeCfg_Set("fontSize", v)
                if HealerRangeAlert_ApplyFont then HealerRangeAlert_ApplyFont() end
            end
            self:ClearFocus()
        end)

        panel:HookScript("OnShow", function()
            sizeBox:SetText(tostring(HealerRangeCfg_Get("fontSize") or 22))
        end)
    end

    result.bottomY = y - 40
    return result
end