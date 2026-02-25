local addonName, MCC = ...

function MCC.InitShoppingUI(parent)
    local shoppingTitle = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    shoppingTitle:SetPoint("TOPLEFT", 15, -10)
    shoppingTitle:SetText(MCC.L["Shopping List (Total Ingredients)"])
    if MCC.Styles then
        shoppingTitle:SetTextColor(unpack(MCC.Styles.Colors.Gold))
    end

    local multLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    multLabel:SetPoint("LEFT", shoppingTitle, "RIGHT", 20, 0)
    multLabel:SetText(MCC.L["Margin (x):"])

    local multBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    multBox:SetSize(40, 20)
    multBox:SetPoint("LEFT", multLabel, "RIGHT", 10, 0)
    multBox:SetAutoFocus(false)
    multBox:SetText("1.0")
    multBox:SetScript("OnTextChanged", function(self)
        MCC_Config.shoppingMargin = self:GetText()
        MCC.UpdateShoppingList()
    end)

    local exportButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    exportButton:SetSize(140, 22)
    exportButton:SetPoint("LEFT", multBox, "RIGHT", 20, 0)
    exportButton:SetText(MCC.L["Export Auctionator"] or "Export Auctionator")
    exportButton:SetScript("OnClick", function() MCC.ShowExportPopup() end)

    local shoppingContent = CreateFrame("ScrollFrame", "MCC_ShoppingScroll", parent, "UIPanelScrollFrameTemplate")
    shoppingContent:SetPoint("TOPLEFT", 10, -35)
    shoppingContent:SetPoint("BOTTOMRIGHT", -30, 10)

    local container = CreateFrame("Frame", nil, shoppingContent)
    container:SetSize(1, 1)
    shoppingContent:SetScrollChild(container)

    -- Collapse Toggle Button
    local collapseBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    collapseBtn:SetSize(120, 18)
    collapseBtn:SetPoint("TOPRIGHT", -10, -10)
    if MCC.Styles then
        collapseBtn:SetBackdrop(MCC.Styles.Backdrop)
        collapseBtn:SetBackdropColor(unpack(MCC.Styles.Colors.BgSubtle))
        collapseBtn:SetBackdropBorderColor(unpack(MCC.Styles.Colors.Gold))
    end
    local collapseText = collapseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    collapseText:SetPoint("CENTER")
    collapseBtn:SetFontString(collapseText)

    collapseBtn:SetScript("OnClick", function()
        MCC_Config.collapseIngredients = not MCC_Config.collapseIngredients
        MCC.UpdateShoppingList()
    end)

    -- Update the internal references in Main.lua via a setter or just store them in MCC
    MCC.MultBox = multBox
    MCC.ShoppingScroll = shoppingContent
    MCC.ShoppingContainer = container
    MCC.CollapseBtn = collapseBtn
end

function MCC.UpdateShoppingList()
    local shoppingContainer = MCC.ShoppingContainer
    if not shoppingContainer or not MCC.MultBox then return end

    -- Handle Button Text
    if MCC.CollapseBtn then
        local label = MCC_Config.collapseIngredients and (MCC.L["Expand Ingredients"] or "Expand Ingredients")
            or (MCC.L["Collapse Ingredients"] or "Collapse Ingredients")
        MCC.CollapseBtn:SetText(label)
    end

    for _, child in ipairs({ shoppingContainer:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local multiplier = tonumber(MCC.MultBox:GetText()) or 1.0
    local sortedList = MCC.GetMissingIngredients(multiplier)

    local profit, revenue, deficitCost, totalRequiredCost = 0, 0, 0, 0
    if MCC.GetSessionProfit then
        profit, revenue, deficitCost, totalRequiredCost = MCC.GetSessionProfit(multiplier)
    end

    local y = 0
    -- ALWAYS SHOW HEADER if there's data
    if totalRequiredCost > 0 then
        local header = CreateFrame("Frame", nil, shoppingContainer)
        header:SetSize(400, 80)
        header:SetPoint("TOPLEFT", 0, 0)
        local bg = header:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.3)

        local function GetProfitString(amount)
            local color = amount >= 0 and "|cff00ff00+" or "|cffff4444-"
            return color .. GetMoneyString(math.abs(amount), true) .. "|r"
        end

        local costText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        costText:SetPoint("TOPLEFT", 8, -6)
        costText:SetText("|cffff4444" ..
            (MCC.L["Purchases to Make"] or "Achats à effectuer :") .. ":|r  " .. GetMoneyString(deficitCost, true))

        local totalReqText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        totalReqText:SetPoint("TOPLEFT", 8, -22)
        totalReqText:SetAlpha(0.8)
        totalReqText:SetText("|cffaaaaaa" ..
            (MCC.L["Total Purchases"] or "Total des achats :") .. ":|r  " .. GetMoneyString(totalRequiredCost, true))

        local revenueText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        revenueText:SetPoint("TOPLEFT", 8, -38)
        revenueText:SetText("|cff88ff88" ..
            (MCC.L["Total Sales"] or "Total des ventes :") .. ":|r  " .. GetMoneyString(revenue, true))

        local profitLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        profitLabel:SetPoint("TOPLEFT", 8, -56)
        profitLabel:SetText("|cffffd700Profit:|r  " .. GetProfitString(profit))

        y = -80
    end

    -- ONLY SHOW INGREDIENTS IF NOT COLLAPSED
    if not MCC_Config.collapseIngredients then
        for _, data in ipairs(sortedList) do
            local line = CreateFrame("Frame", nil, shoppingContainer)
            line:SetSize(400, 25)
            line:SetPoint("TOPLEFT", 0, y)

            local icon = line:CreateTexture(nil, "OVERLAY")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT", 5, 0)
            local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(data.itemID)
            icon:SetTexture(itemTexture or 134400)

            local nameText = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            local itemName = MCC.GetItemNameSafe(data.itemID)
            if data.rank and data.rank > 0 then
                itemName = itemName .. " |cff00ccff(R" .. data.rank .. ")|r"
            end
            nameText:SetText(itemName)

            local countText = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            countText:SetPoint("RIGHT", -10, 0)

            local status = ""
            if data.deficit > 0 then
                status = "|cffff4444" .. data.deficit .. " " .. (MCC.L["missing"] or "manquants") .. "|r"
            else
                status = "|cff00ff00" .. (MCC.L["OK"] or "OK") .. "|r"
            end

            countText:SetText(string.format("%d/%d  (%s)", data.owned, data.requiredWithMargin, status))

            -- Tooltip
            line:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(data.itemID)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(MCC.L["Owned:"] or "Possédé :")
                GameTooltip:AddDoubleLine("- Sak / Bags:", data.bagsOwned or 0, 1, 1, 1, 1, 1, 1)
                GameTooltip:AddDoubleLine("- Bank:", data.bankOwned or 0, 1, 1, 1, 1, 1, 1)
                GameTooltip:AddDoubleLine("- Warbank:", data.warbankOwned or 0, 1, 1, 1, 1, 1, 1)
                GameTooltip:Show()
            end)
            line:SetScript("OnLeave", function() GameTooltip:Hide() end)

            y = y - 25
        end
    end

    shoppingContainer:SetHeight(math.abs(y))
end

function MCC.ShowExportPopup()
    local frames = MCC.GetUIFrames()
    if not MCC_ExportFrame then
        local f = CreateFrame("Frame", "MCC_ExportFrame", UIParent, "BackdropTemplate")
        f:SetSize(400, 500)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        if MCC.Styles then
            f:SetBackdrop(MCC.Styles.Backdrop)
            f:SetBackdropColor(unpack(MCC.Styles.Colors.BgDark))
            f:SetBackdropBorderColor(unpack(MCC.Styles.Colors.Gold))
        end
        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -5, -5)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", 0, -10)
        title:SetText("Export Auctionator")
        if MCC.Styles then title:SetTextColor(unpack(MCC.Styles.Colors.Gold)) end

        local desc = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
        desc:SetText(MCC.L["Copy this text (Ctrl+C) and import it into Auctionator."])

        local copyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        copyBtn:SetSize(140, 22)
        copyBtn:SetPoint("TOP", desc, "BOTTOM", 0, -10)
        copyBtn:SetText(MCC.L["Select All"])
        copyBtn:SetScript("OnClick", function()
            f.editBox:HighlightText(); f.editBox:SetFocus()
        end)

        local scroll = CreateFrame("ScrollFrame", "MCC_ExportScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -60)
        scroll:SetPoint("BOTTOMRIGHT", -30, 20)

        local editBox = CreateFrame("EditBox", nil, scroll)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetWidth(340)
        editBox:SetAutoFocus(true)
        scroll:SetScrollChild(editBox)

        f.editBox = editBox
        MCC_ExportFrame = f
        _G["UISpecialFrames"] = _G["UISpecialFrames"] or {}
        table.insert(_G["UISpecialFrames"], "MCC_ExportFrame")
    end

    local multiplier = tonumber(frames.MultBox:GetText()) or 1.0
    local exportText = "MCC Export"
    local missing = MCC.GetMissingIngredients(multiplier)

    for _, data in ipairs(missing) do
        if data.deficit > 0 then
            local name = MCC.GetItemNameSafe(data.itemID)
            local rankText = (data.rank and data.rank > 0) and tostring(data.rank) or ""
            -- Auctionator Shopping List Import format
            exportText = exportText .. "^\"" .. name .. "\";;;;;;;;;;;" .. rankText .. ";;" .. data.deficit
        end
    end

    MCC_ExportFrame.editBox:SetText(exportText)
    MCC_ExportFrame.editBox:HighlightText()
    MCC_ExportFrame:Show()
end
