-- UI/Dropdown.lua
-- Generic reusable dropdown widget.
--
-- Usage:
--   local dd = HealerRange_CreateDropdown({
--       parent       = panel,
--       anchorFrame  = someFrame,    -- frame sous lequel le dropdown apparaît
--       width        = 240,
--       itemHeight   = 20,
--       visibleItems = 10,
--       getList      = function() return { "Item1", "Item2" } end,
--       getCurrentKey = function() return HealerRangeCfg_Get("myKey") end,
--       onSelect     = function(name) ... end,
--   })
--   dd.selectedText  -- FontString du bouton toggle
--   dd.bottomY       -- Y après le widget (anchorFrame:GetBottom() - 40)

function HealerRange_CreateDropdown(config)
    local parent       = config.parent
    local anchorFrame  = config.anchorFrame
    local width        = config.width        or 240
    local itemHeight   = config.itemHeight   or 20
    local visibleItems = config.visibleItems or 10
    local getList      = config.getList
    local getCurrentKey = config.getCurrentKey
    local onSelect     = config.onSelect

    local result = {}

    -- ── Toggle button ─────────────────────────────────────────────────────────

    local toggleBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    toggleBtn:SetSize(width, 22)
    toggleBtn:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -4)
    toggleBtn:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    toggleBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    toggleBtn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    toggleBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    end)
    toggleBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end)

    local selectedText = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    selectedText:SetPoint("LEFT", 6, 0)
    selectedText:SetPoint("RIGHT", -6, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetText("(select...)")
    result.selectedText = selectedText
    result.toggleBtn    = toggleBtn

    -- ── Drop frame ────────────────────────────────────────────────────────────

    local dropFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dropFrame:SetSize(width, itemHeight * visibleItems)
    dropFrame:SetFrameStrata("TOOLTIP")
    dropFrame:SetClipsChildren(true)
    dropFrame:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    dropFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    dropFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    dropFrame:Hide()
    dropFrame:EnableMouse(false)

    -- ── Scroll frame ──────────────────────────────────────────────────────────

    local scrollFrame = CreateFrame("ScrollFrame", nil, dropFrame)
    scrollFrame:SetPoint("TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -18, 4)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(width - 22)
    scrollFrame:SetScrollChild(scrollChild)

    -- ── Scrollbar ─────────────────────────────────────────────────────────────

    local scrollTrack = CreateFrame("Frame", nil, dropFrame, "BackdropTemplate")
    scrollTrack:SetPoint("TOPRIGHT", dropFrame, "TOPRIGHT", -4, -4)
    scrollTrack:SetPoint("BOTTOMRIGHT", dropFrame, "BOTTOMRIGHT", -4, 4)
    scrollTrack:SetWidth(8)
    scrollTrack:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    scrollTrack:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    scrollTrack:Hide()

    local scrollThumb
    local UpdateScrollBar

    UpdateScrollBar = function()
        local list = getList()
        local max = scrollFrame:GetVerticalScrollRange()
        if not dropFrame:IsShown() or max <= 0 then
            scrollTrack:Hide()
            return
        end
        scrollTrack:Show()
        local ratio     = scrollFrame:GetVerticalScroll() / max
        local trackH    = scrollTrack:GetHeight()
        local thumbH    = math.max(12, trackH * (itemHeight * visibleItems / (itemHeight * #list)))
        local maxOffset = trackH - thumbH
        scrollThumb:SetHeight(thumbH)
        scrollThumb:ClearAllPoints()
        scrollThumb:SetPoint("TOP", scrollTrack, "TOP", 0, -(ratio * maxOffset))
    end

    scrollThumb = CreateFrame("Button", nil, scrollTrack)
    scrollThumb:SetWidth(8)
    scrollThumb:SetHeight(12)
    local scrollThumbTex = scrollThumb:CreateTexture(nil, "OVERLAY")
    scrollThumbTex:SetAllPoints()
    scrollThumbTex:SetColorTexture(0.6, 0.6, 0.6, 0.8)

    scrollTrack:EnableMouse(true)
    scrollTrack:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local _, trackY = scrollTrack:GetCenter()
        local _, cursorY = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        cursorY = cursorY / scale
        local trackH = scrollTrack:GetHeight()
        local thumbH = scrollThumb:GetHeight()
        local maxOffset = trackH - thumbH
        local ratio = math.max(0, math.min(1, (trackY + trackH/2 - cursorY) / maxOffset))
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        scrollFrame:SetVerticalScroll(ratio * maxScroll)
        UpdateScrollBar()
    end)

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        self:SetVerticalScroll(offset)
        UpdateScrollBar()
    end)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local max     = self:GetVerticalScrollRange()
        local new     = math.max(0, math.min(max, current - delta * itemHeight * 2))
        self:SetVerticalScroll(new)
        UpdateScrollBar()
    end)

    dropFrame:EnableMouseWheel(true)
    dropFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollFrame:GetVerticalScroll()
        local max     = scrollFrame:GetVerticalScrollRange()
        local new     = math.max(0, math.min(max, current - delta * itemHeight * 2))
        scrollFrame:SetVerticalScroll(new)
        UpdateScrollBar()
    end)

    -- ── List items ────────────────────────────────────────────────────────────

    local buttons = {}

    local function RefreshList()
        local list       = getList()
        local currentKey = getCurrentKey()
        local level      = dropFrame:GetFrameLevel()

        scrollChild:SetHeight(itemHeight * #list)

        for i, name in ipairs(list) do
            local btn = buttons[i]
            if not btn then
                btn = CreateFrame("Button", nil, scrollChild)
                btn:SetHeight(itemHeight)
                btn:SetPoint("TOPLEFT", 0, -(i - 1) * itemHeight)
                btn:SetWidth(width - 22)

                local hl = btn:CreateTexture(nil, "HIGHLIGHT")
                hl:SetAllPoints()
                hl:SetColorTexture(1, 1, 1, 0.1)
                btn:SetHighlightTexture(hl)

                local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                lbl:SetPoint("LEFT", 4, 0)
                lbl:SetPoint("RIGHT", -4, 0)
                lbl:SetJustifyH("LEFT")
                btn.label = lbl

                buttons[i] = btn
            end

            btn:SetFrameLevel(level + 2)
            btn.label:SetText(name)

            if name == currentKey then
                btn.label:SetTextColor(1, 0.82, 0, 1)
            else
                btn.label:SetTextColor(1, 1, 1, 1)
            end

            btn:SetScript("OnClick", function()
                onSelect(name)
                selectedText:SetText(name)
                dropFrame:Hide()
                RefreshList()
            end)
        end

        -- Cache les boutons en surplus
        for i = #list + 1, #buttons do
            buttons[i]:Hide()
        end

        UpdateScrollBar()
    end

    -- ── Toggle logic ──────────────────────────────────────────────────────────

    toggleBtn:SetScript("OnClick", function()
        if dropFrame:IsShown() then
            dropFrame:Hide()
        else
            local left   = toggleBtn:GetLeft()
            local bottom = toggleBtn:GetBottom()
            dropFrame:ClearAllPoints()
            dropFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                left,
                bottom - 2 - UIParent:GetBottom()
            )
            dropFrame:SetFrameLevel(1)
            scrollTrack:SetFrameLevel(2)
            scrollThumb:SetFrameLevel(3)
            RefreshList()
            dropFrame:Show()
            dropFrame:EnableMouse(true)
            scrollFrame:EnableMouse(true)
            scrollChild:EnableMouse(true)

            local list       = getList()
            local currentKey = getCurrentKey()
            for i, name in ipairs(list) do
                if name == currentKey then
                    local maxScroll = scrollFrame:GetVerticalScrollRange()
                    local target    = math.max(0, math.min(maxScroll, (i - 1) * itemHeight))
                    scrollFrame:SetVerticalScroll(target)
                    UpdateScrollBar()
                    break
                end
            end
        end
    end)

    dropFrame:SetScript("OnHide", function()
        scrollTrack:Hide()
        dropFrame:EnableMouse(false)
        scrollFrame:EnableMouse(false)
        scrollChild:EnableMouse(false)
    end)

    parent:HookScript("OnHide", function()
        dropFrame:Hide()
    end)

    result.RefreshList = RefreshList
    return result
end