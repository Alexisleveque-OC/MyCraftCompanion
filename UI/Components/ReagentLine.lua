local addonName, MCC = ...

function MCC.CreateIngredientLine(parent, yOffset, slotData, playerName, metierIndex)
    local line = CreateFrame("Frame", nil, parent)
    line:SetSize(MCC.COLUMN_WIDTH - 10, MCC.ROW_HEIGHT)
    line:SetPoint("TOPLEFT", 5, yOffset)

    local text = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT")
    text:SetText("x" .. slotData.quantity)

    local dropdown = CreateFrame("Frame", nil, line, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", text, "RIGHT", -15, 0)
    dropdown:SetScale(0.9)

    UIDropDownMenu_SetWidth(dropdown, 140)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.text = MCC.L["None"]
        info.func = function()
            UIDropDownMenu_SetText(dropdown, MCC.L["None"])
            slotData.selectedItemID = nil
            slotData.selectedRank = nil
            MCC.RefreshConcentrationCost(playerName, metierIndex)
            MCC.UpdateShoppingList()
            MCC.RenderMCCUI()
        end
        UIDropDownMenu_AddButton(info)

        for _, opt in ipairs(slotData.options) do
            local itemID, rank
            if type(opt) == "table" then
                itemID = opt.itemID
                rank = opt.rank
            else
                itemID = opt
                rank = nil
            end

            local itemName = MCC.GetItemNameSafe(itemID)
            local rankText = MCC.GetRankIcon(rank)

            local _, _, quality = C_Item.GetItemInfo(itemID)
            local itemColorPrefix = "|cffffffff"
            if quality then
                local _, _, _, hex = C_Item.GetItemQualityColor(quality)
                if hex then itemColorPrefix = "|c" .. hex end
            end

            local info = UIDropDownMenu_CreateInfo()
            info.text = itemColorPrefix .. itemName .. "|r" .. rankText
            info.onEnter = function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(itemID)
                GameTooltip:Show()
            end
            info.onLeave = function()
                GameTooltip:Hide()
            end
            info.func = function()
                if IsShiftKeyDown() then
                    local _, link = C_Item.GetItemInfo(itemID)
                    if link and not ChatEdit_InsertLink(link) then
                        if SELECTED_CHAT_FRAME then SELECTED_CHAT_FRAME:AddMessage(link) end
                    end
                    return
                end

                UIDropDownMenu_SetText(dropdown, info.text)
                slotData.selectedItemID = itemID
                slotData.selectedRank = rank
                MCC.RefreshConcentrationCost(playerName, metierIndex)
                MCC.UpdateShoppingList()
                MCC.RenderMCCUI()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    if slotData.selectedItemID then
        local found = false
        for _, opt in ipairs(slotData.options) do
            local oID = type(opt) == "table" and opt.itemID or opt
            if oID == slotData.selectedItemID then
                local oRank = type(opt) == "table" and opt.rank or nil
                local itemName = MCC.GetItemNameSafe(oID)
                local rankText = MCC.GetRankIcon(oRank)

                local _, _, quality = C_Item.GetItemInfo(oID)
                local itemColorPrefix = "|cffffffff"
                if quality then
                    local _, _, _, hex = C_Item.GetItemQualityColor(quality)
                    if hex then itemColorPrefix = "|c" .. hex end
                end

                UIDropDownMenu_SetText(dropdown, itemColorPrefix .. itemName .. "|r" .. rankText)
                MCC.AttachItemTooltip(dropdown, oID)
                found = true
                break
            end
        end
        if not found then
            UIDropDownMenu_SetText(dropdown, MCC.L["None"])
        end
    else
        UIDropDownMenu_SetText(dropdown, MCC.L["None"])
    end

    return line
end
