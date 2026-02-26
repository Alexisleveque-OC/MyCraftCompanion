local addonName, MCC = ...

function MCC.CreatePlayerHeader(parent, playerName, pdata, columnIndex)
    local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    header:SetSize(MCC.COLUMN_WIDTH, 80)
    header:SetPoint("TOPLEFT", (columnIndex - 1) * MCC.COLUMN_WIDTH, 0)

    if columnIndex % 2 == 0 then
        header:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16 })
        header:SetBackdropColor(1, 1, 1, 0.05)
    else
        header:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16 })
        header:SetBackdropColor(0, 0, 0, 0.2)
    end

    local separator = header:CreateTexture(nil, "ARTWORK")
    separator:SetWidth(1)
    separator:SetPoint("TOPRIGHT", 0, 0)
    separator:SetPoint("BOTTOMRIGHT", 0, 0)
    if MCC.Styles then
        separator:SetColorTexture(unpack(MCC.Styles.Colors.Separator))
    end

    local y = -10
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    title:SetPoint("TOP", 0, y)
    title:SetText(playerName)

    local classColor = pdata.class and C_ClassColor.GetClassColor(pdata.class)
    if classColor then
        title:SetTextColor(classColor.r, classColor.g, classColor.b)
    elseif MCC.Styles then
        title:SetTextColor(unpack(MCC.Styles.Colors.Gold))
    end

    local profileDropdown = CreateFrame("Frame", "MCC_ProfileDropDown_" .. playerName, header, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("TOP", 0, y - 22)
    UIDropDownMenu_SetWidth(profileDropdown, 160)

    UIDropDownMenu_Initialize(profileDropdown, function(self, level)
        local options = {
            { text = MCC.L["None"],              value = nil },
            { text = MCC.L["Equipment Crafter"], value = "equipment" },
            { text = MCC.L["Resource Producer"], value = "resource" },
        }
        for _, opt in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.text
            info.func = function()
                pdata.profile = opt.value
                UIDropDownMenu_SetText(profileDropdown, opt.text)
                MCC.RenderMCCUI()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local currentProfile = pdata.profile
    local profileLabel = MCC.L["None"]
    if currentProfile == "equipment" then
        profileLabel = MCC.L["Equipment Crafter"]
    elseif currentProfile == "resource" then
        profileLabel = MCC.L["Resource Producer"]
    end
    UIDropDownMenu_SetText(profileDropdown, profileLabel)

    return header
end

function MCC.CreatePlayerContent(parent, playerName, pdata, columnIndex)
    local column = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    column:SetSize(MCC.COLUMN_WIDTH, 1000)
    column:SetPoint("TOPLEFT", (columnIndex - 1) * MCC.COLUMN_WIDTH, 0)

    if columnIndex % 2 == 0 then
        column:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16 })
        column:SetBackdropColor(1, 1, 1, 0.03)
    else
        column:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16 })
        column:SetBackdropColor(0, 0, 0, 0.15)
    end

    local separator = column:CreateTexture(nil, "ARTWORK")
    separator:SetWidth(1)
    separator:SetPoint("TOPRIGHT", 0, 0)
    separator:SetPoint("BOTTOMRIGHT", 0, 0)
    if MCC.Styles then
        separator:SetColorTexture(unpack(MCC.Styles.Colors.Separator))
    end

    local y = -10

    for metierIndex, metier in ipairs(pdata.metiers or {}) do
        local m = column:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        m:SetPoint("TOPLEFT", 10, y)
        m:SetText(metier.name)

        local currentConc = MCC.GetEstimatedConcentration(metier)
        if currentConc and metier.concentrationMax then
            local conc = column:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            conc:SetPoint("TOPRIGHT", -15, y)
            local percent = currentConc / metier.concentrationMax
            local color = "00ff00" -- Green
            if percent >= 0.9 then
                color = "ff4444"   -- Red (Alert Cap)
            elseif percent >= 0.7 then
                color = "ffff00"   -- Yellow
            end
            conc:SetText("|cff" .. color .. currentConc .. "|r/" .. metier.concentrationMax)
        end

        y = y - 16

        local craftDropdown = CreateFrame("Frame", "MCC_CraftDropDown_" .. playerName .. "_" .. metierIndex, column,
            "UIDropDownMenuTemplate")
        craftDropdown:SetPoint("TOPLEFT", -15, y + 5)
        UIDropDownMenu_SetWidth(craftDropdown, 120) -- Slightly smaller to fit delete button

        -- Delete Button next to dropdown
        local delBtn = CreateFrame("Button", nil, column, "UIPanelButtonTemplate")
        delBtn:SetSize(20, 20)
        delBtn:SetText("|cffff4444\195\151|r")
        delBtn:SetPoint("LEFT", craftDropdown, "RIGHT", -15, 3)
        delBtn:SetScript("OnClick", function()
            local currentRecipeID = metier.activeRecipeID
            if currentRecipeID then
                if metier.savedSchematics then
                    metier.savedSchematics[currentRecipeID] = nil
                end
                MCC.ClearCurrentCraft(playerName, metierIndex)

                -- Force immediate UI feedback
                UIDropDownMenu_SetText(craftDropdown, "|cffffffff" .. MCC.L["None"] .. "|r")
                MCC.RenderMCCUI()

                MCC.Log("|cffff4444MCC:|r Recette supprimée: " .. (metier.currentCraft or ""))
            end
        end)
        delBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(MCC.L["Delete current recipe from MCC"] or "Delete current recipe from MCC")
            GameTooltip:Show()
        end)
        delBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        UIDropDownMenu_Initialize(craftDropdown, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.text = MCC.L["None"]
            info.func = function()
                MCC.ClearCurrentCraft(playerName, metierIndex)
                MCC.RenderMCCUI()
            end
            UIDropDownMenu_AddButton(info)

            if metier.savedSchematics then
                for recipeID, data in pairs(metier.savedSchematics) do
                    local recipeName = data.recipeName
                    local isFavorite = metier.favorites and metier.favorites[recipeID]
                    local bestItemID = MCC.GetRecipeMaxRankItemID(recipeID) or data.outputItemID

                    local itemColorPrefix = "|cffffffff"
                    if bestItemID then
                        local _, _, quality = C_Item.GetItemInfo(bestItemID)
                        if quality then
                            local _, _, _, hex = C_Item.GetItemQualityColor(quality)
                            if hex then itemColorPrefix = "|c" .. hex end
                        end
                    end

                    local fInfo = UIDropDownMenu_CreateInfo()
                    local displayName = recipeName
                    if bestItemID then
                        local itemName = C_Item.GetItemNameByID(bestItemID)
                        if itemName then
                            displayName = itemName
                        else
                            local link = C_TradeSkillUI.GetRecipeItemLink(recipeID)
                            if link then
                                local nameFromLink = link:match("%[(.-)%]")
                                if nameFromLink then displayName = nameFromLink end
                            end
                        end
                    end

                    fInfo.text = (isFavorite and "|TInterface\\Buttons\\UI-GroupLoot-Star-Up:0|t " or "") ..
                        itemColorPrefix .. displayName .. "|r"
                    if bestItemID then
                        fInfo.onEnter = function(self)
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:SetItemByID(bestItemID)
                            GameTooltip:Show()
                        end
                        fInfo.onLeave = function() GameTooltip:Hide() end
                    end

                    fInfo.func = function()
                        if IsShiftKeyDown() and bestItemID then
                            local _, link = C_Item.GetItemInfo(bestItemID)
                            if link and not ChatEdit_InsertLink(link) then
                                if SELECTED_CHAT_FRAME then SELECTED_CHAT_FRAME:AddMessage(link) end
                            end
                            return
                        end
                        MCC.SetCurrentCraft(playerName, metierIndex, { recipeID = recipeID, recipeName = recipeName })
                        MCC.RenderMCCUI()
                    end
                    UIDropDownMenu_AddButton(fInfo)
                end
            end
        end)

        local bestItemID = metier.outputItemID
        if metier.activeRecipeID then
            bestItemID = MCC.GetRecipeMaxRankItemID(metier.activeRecipeID) or bestItemID
        end

        local itemColorPrefix = "|cffffffff"
        if bestItemID then
            local _, _, quality = C_Item.GetItemInfo(bestItemID)
            if quality then
                local _, _, _, hex = C_Item.GetItemQualityColor(quality)
                if hex then itemColorPrefix = "|c" .. hex end
            end
        end

        local displayLabel = metier.currentCraft or MCC.L["None"]
        if bestItemID then
            local itemName = C_Item.GetItemNameByID(bestItemID)
            if itemName then
                displayLabel = itemName
            else
                local link = metier.activeRecipeID and C_TradeSkillUI.GetRecipeItemLink(metier.activeRecipeID)
                if link then
                    local nameFromLink = link:match("%[(.-)%]")
                    if nameFromLink then displayLabel = nameFromLink end
                end
            end
        end

        UIDropDownMenu_SetText(craftDropdown, itemColorPrefix .. displayLabel .. "|r")
        if metier.currentCraft and bestItemID then
            MCC.AttachItemTooltip(craftDropdown, bestItemID)
        end
        y = y - 30

        if metier.currentCraft then
            local qBox = CreateFrame("EditBox", nil, column, "InputBoxTemplate")
            qBox:SetSize(30, 20)
            qBox:SetPoint("TOPLEFT", 15, y)
            qBox:SetAutoFocus(false)
            qBox:SetNumeric(true)
            qBox:SetMaxLetters(3)
            qBox:SetText(tostring(metier.craftQuantity or "1"))

            local capacity = MCC.GetCraftCapacity(metier)
            local capText = column:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            capText:SetPoint("TOPLEFT", qBox, "BOTTOMLEFT", 0, -2)
            metier.capText = capText

            local saleText = column:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            saleText:SetPoint("TOPLEFT", capText, "BOTTOMLEFT", 0, -2)
            metier.saleText = saleText

            function MCC.RefreshLocalProfit(metier, playerName)
                if not metier or not metier.saleText then return end
                local craftQty = tonumber(metier.craftQuantity) or 1
                local outputQty = metier.outputQty or 1
                local bestItemID = metier.outputItemID

                local capMax = MCC.GetCraftCapacity(metier)
                local capAvailable = MCC.GetAvailableCraftCapacity(metier)

                local concCostStr = ""
                if metier.concentrationCost and metier.concentrationCost > 0 then
                    concCostStr = " | |cffaaafffC: " .. metier.concentrationCost .. "|r"
                end

                local capText = ""
                if capMax then
                    capText = MCC.L["Cap Max:"] .. " " .. capMax
                end
                if capAvailable then
                    local colorPrefix = (capAvailable > 0) and "|cff00ff00" or "|cffff0000"
                    capText = capText .. " | |cffaaaaaaDispo:|r " .. colorPrefix .. capAvailable .. "|r"
                end
                metier.capText:SetText(capText .. concCostStr)

                if metier.activeRecipeID then
                    bestItemID = MCC.GetRecipeMaxRankItemID(metier.activeRecipeID) or bestItemID
                end

                if bestItemID then
                    local price = MCC.GetItemPrice(bestItemID)
                    local totalSale = price * craftQty * outputQty
                    local reagentsCost = MCC.GetCraftReagentsCost(metier) * craftQty
                    local profit = totalSale - reagentsCost

                    if totalSale > 0 then
                        local profitColor = (profit >= 0) and "|cff00ff00" or "|cffff4444"
                        local saleStr = GetMoneyString(totalSale, true)
                        local profitStr = (profit >= 0 and "+" or "-") .. GetMoneyString(math.abs(profit), true)

                        metier.saleText:SetText("|cffffcc00V:|r " ..
                            saleStr .. " | " .. profitColor .. "P: " .. profitStr .. "|r")
                    else
                        metier.saleText:SetText("")
                    end
                else
                    metier.saleText:SetText("")
                end
            end

            MCC.RefreshLocalProfit(metier, playerName)

            qBox:SetScript("OnTextChanged", function(self)
                local val = tonumber(self:GetText()) or 1
                metier.craftQuantity = val
                MCC.UpdateShoppingList()
                MCC.RefreshLocalProfit(metier, playerName)
            end)

            local delButton = CreateFrame("Button", nil, column, "UIPanelCloseButton")
            delButton:SetSize(20, 20)
            delButton:SetPoint("LEFT", qBox, "RIGHT", 5, 0)
            delButton:SetScript("OnClick", function()
                MCC.ClearCurrentCraft(playerName, metierIndex)
                MCC.RenderMCCUI()
            end)

            y = y - 55
            for _, slot in ipairs(metier.craftRecipe or {}) do
                MCC.CreateIngredientLine(column, y, slot, playerName, metierIndex)
                y = y - MCC.ROW_HEIGHT
            end
            y = y - 15
        else
            y = y - 5
        end
    end

    local frames = MCC.GetUIFrames()
    local totalY = math.abs(y)
    local scrollChild = frames.HScrollFrame:GetScrollChild()
    local currentHeight = scrollChild:GetHeight()
    if totalY > currentHeight then
        scrollChild:SetHeight(totalY + 50)
    end
end

function MCC.RenderMCCUI()
    local frames = MCC.GetUIFrames()
    local contentFrame = frames.HScrollFrame:GetScrollChild()
    if not contentFrame or not frames.HeaderScrollingFrame then return end

    -- Cleanup
    for _, child in ipairs({ contentFrame:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, child in ipairs({ frames.HeaderScrollingFrame:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local col = 1

    local playerNames = {}
    for playerName, data in pairs(MCC_Config) do
        if type(data) == "table" and data.metiers then
            table.insert(playerNames, playerName)
        end
    end

    table.sort(playerNames, function(a, b)
        if a == MCC.player then return true end
        if b == MCC.player then return false end
        return a < b
    end)

    for _, playerName in ipairs(playerNames) do
        local pdata = MCC_Config[playerName]
        local hasRecipe = false
        for _, metier in ipairs(pdata.metiers or {}) do
            if metier.currentCraft or (metier.savedSchematics and next(metier.savedSchematics)) then
                hasRecipe = true
                break
            end
        end

        if hasRecipe or playerName == MCC.player then
            MCC.CreatePlayerHeader(frames.HeaderScrollingFrame, playerName, pdata, col)
            MCC.CreatePlayerContent(contentFrame, playerName, pdata, col)
            col = col + 1
        end
    end

    local totalWidth = (col - 1) * MCC.COLUMN_WIDTH
    contentFrame:SetSize(totalWidth, 1000)
    frames.HeaderScrollingFrame:SetSize(totalWidth, 80)

    local frameWidth = frames.HeaderClip:GetWidth()
    if totalWidth > frameWidth then
        frames.HSlider:SetMinMaxValues(0, totalWidth - frameWidth)
        frames.HSlider:Show()
    else
        frames.HSlider:Hide()
        frames.HScrollFrame:SetHorizontalScroll(0)
        frames.HeaderScrollingFrame:SetPoint("TOPLEFT", 0, 0)
    end

    if frames.MultBox and MCC_Config.shoppingMargin then
        frames.MultBox:SetText(MCC_Config.shoppingMargin)
    end
    if frames.VendorBox and MCC_Config.vendorName then
        frames.VendorBox:SetText(MCC_Config.vendorName)
    end

    MCC.UpdateShoppingList()
end
