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

    local vendorLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    vendorLabel:SetPoint("LEFT", exportButton, "RIGHT", 20, 0)
    vendorLabel:SetText(MCC.L["Vendor:"])

    local vendorBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    vendorBox:SetSize(100, 20)
    vendorBox:SetPoint("LEFT", vendorLabel, "RIGHT", 10, 0)
    vendorBox:SetAutoFocus(false)
    vendorBox:SetText("")
    vendorBox:SetScript("OnTextChanged", function(self)
        MCC_Config.vendorName = self:GetText()
    end)

    local shoppingContent = CreateFrame("ScrollFrame", "MCC_ShoppingScroll", parent, "UIPanelScrollFrameTemplate")
    shoppingContent:SetPoint("TOPLEFT", 10, -35)
    shoppingContent:SetPoint("BOTTOMRIGHT", -30, 10)

    local container = CreateFrame("Frame", nil, shoppingContent)
    container:SetSize(1, 1)
    shoppingContent:SetScrollChild(container)

    -- Update the internal references in Main.lua via a setter or just store them in MCC
    MCC.MultBox = multBox
    MCC.VendorBox = vendorBox
    MCC.ShoppingScroll = shoppingContent
    MCC.ShoppingContainer = container
end

-- Remove the SetupShoppingSection function as it's now redundancy

function MCC.UpdateShoppingList()
    local shoppingContainer = MCC.ShoppingContainer
    if not shoppingContainer or not MCC.MultBox then return end

    for _, child in ipairs({ shoppingContainer:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local multiplier = tonumber(MCC.MultBox:GetText()) or 1.0
    local totals = {}

    for playerName, pdata in pairs(MCC_Config) do
        if type(pdata) == "table" then
            for _, metier in ipairs(pdata.metiers or {}) do
                if metier.currentCraft and metier.craftRecipe then
                    local craftQty = tonumber(metier.craftQuantity) or 1
                    for _, slot in ipairs(metier.craftRecipe) do
                        if slot.selectedItemID then
                            local itemID = slot.selectedItemID
                            local rank = slot.selectedRank or 0
                            local key = itemID .. "-" .. rank
                            local totalQty = (slot.quantity or 0) * craftQty

                            if not totals[key] then
                                totals[key] = { itemID = itemID, rank = slot.selectedRank, quantity = 0, owned = 0 }
                            end
                            totals[key].quantity = totals[key].quantity + totalQty
                        end
                    end
                end
            end
        end
    end

    for key, data in pairs(totals) do
        local itemID = data.itemID
        local owned = 0
        for playerName, pdata in pairs(MCC_Config) do
            if type(pdata) == "table" and pdata.inventory and pdata.inventory[itemID] then
                owned = owned + pdata.inventory[itemID]
            end
        end
        if MCC_Config.Warbank and MCC_Config.Warbank[itemID] then
            owned = owned + MCC_Config.Warbank[itemID]
        end
        data.owned = owned
    end

    local sortedList = {}
    for _, data in pairs(totals) do table.insert(sortedList, data) end
    table.sort(sortedList, function(a, b) return MCC.GetItemNameSafe(a.itemID) < MCC.GetItemNameSafe(b.itemID) end)

    local profit, revenue, deficitCost, totalRequiredCost = 0, 0, 0, 0
    if MCC.GetSessionProfit then
        profit, revenue, deficitCost, totalRequiredCost = MCC.GetSessionProfit(multiplier)
    end

    local y = 0
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

    for _, data in ipairs(sortedList) do
        local line = CreateFrame("Frame", nil, shoppingContainer)
        line:SetSize(400, 20)
        line:SetPoint("TOPLEFT", 0, y)
        local text = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("LEFT")

        local requiredWithMargin = math.ceil(data.quantity * multiplier)
        local deficit = math.max(0, requiredWithMargin - data.owned)
        local lineCost = deficit * MCC.GetItemPrice(data.itemID)

        local _, _, quality = C_Item.GetItemInfo(data.itemID)
        local itemColorPrefix = "|cffffffff"
        if quality then
            local _, _, _, hex = C_Item.GetItemQualityColor(quality)
            if hex then itemColorPrefix = "|c" .. hex end
        end

        local color = "|1cffffffff"
        if deficit == 0 then
            color = "|cff00ff00"
        elseif deficit < requiredWithMargin then
            color = "|cffffff00"
        else
            color = "|cffff0000"
        end

        local priceStr = (lineCost > 0) and (" |cffffd700(" .. GetMoneyString(lineCost, true) .. ")|r") or ""
        text:SetText(color ..
            deficit ..
            "x|r " ..
            itemColorPrefix ..
            MCC.GetItemNameSafe(data.itemID) ..
            "|r" ..
            MCC.GetRankIcon(data.rank) ..
            priceStr .. " |cffaaaaaa(" .. (MCC.L["Owned:"] or "Poss:") .. " " .. data.owned .. ")|r")

        MCC.AttachItemTooltip(line, data.itemID)
        y = y - 20
    end
    shoppingContainer:SetSize(400, math.abs(y))
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
    local totals = {}

    for playerName, pdata in pairs(MCC_Config) do
        for _, metier in ipairs(pdata.metiers or {}) do
            if metier.currentCraft and metier.craftRecipe then
                local craftQty = tonumber(metier.craftQuantity) or 1
                for _, slot in ipairs(metier.craftRecipe) do
                    if slot.selectedItemID then
                        local itemID = slot.selectedItemID
                        local rank = slot.selectedRank or 0
                        local key = itemID .. "-" .. rank
                        local totalQty = (slot.quantity or 0) * craftQty
                        if not totals[key] then totals[key] = { itemID = itemID, rank = slot.selectedRank, quantity = 0, owned = 0 } end
                        totals[key].quantity = totals[key].quantity + totalQty
                    end
                end
            end
        end
    end

    for key, data in pairs(totals) do
        local itemID = data.itemID
        local owned = 0
        for playerName, pdata in pairs(MCC_Config) do
            if pdata.inventory and pdata.inventory[itemID] then owned = owned + pdata.inventory[itemID] end
        end
        if MCC_Config.Warbank and MCC_Config.Warbank[itemID] then owned = owned + MCC_Config.Warbank[itemID] end
        data.owned = owned
    end

    for key, data in pairs(totals) do
        local required = math.ceil(data.quantity * multiplier)
        local missing = math.max(0, required - data.owned)
        if missing > 0 then
            local name = MCC.GetItemNameSafe(data.itemID)
            local rankText = (data.rank and data.rank > 0) and tostring(data.rank) or ""
            exportText = exportText .. "^\"" .. name .. "\";;;;;;;;;;;" .. rankText .. ";;" .. missing
        end
    end

    MCC_ExportFrame.editBox:SetText(exportText)
    MCC_ExportFrame.editBox:HighlightText()
    MCC_ExportFrame:Show()
end
