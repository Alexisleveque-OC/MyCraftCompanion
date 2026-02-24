local addonName, MCC = ...

-- WoW Atlas names for crafting reagent quality stars
local QUALITY_ATLAS = {
    [1] = "Professions-ChatIcon-Quality-Tier1",
    [2] = "Professions-ChatIcon-Quality-Tier2",
    [3] = "Professions-ChatIcon-Quality-Tier3",
    [4] = "Professions-ChatIcon-Quality-Tier4",
    [5] = "Professions-ChatIcon-Quality-Tier5",
}

function MCC.GetRankIcon(rank)
    if not rank then return "" end

    if C_Texture and C_Texture.GetCraftingReagentQualityChatIcon then
        local icon = C_Texture.GetCraftingReagentQualityChatIcon(rank)
        if icon and icon ~= "" then
            return " " .. icon
        end
    end

    local atlas = QUALITY_ATLAS[rank]
    if atlas then
        return " |A:" .. atlas .. ":14:14:0:0|a"
    end

    return ""
end

function MCC.AttachItemTooltip(frame, itemID)
    if not frame or not itemID then return end

    local function OnEnter(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(itemID)
        GameTooltip:Show()
    end

    local function OnLeave()
        GameTooltip:Hide()
    end

    local function OnMouseDown(self, button)
        if button == "LeftButton" and IsShiftKeyDown() then
            local _, link = C_Item.GetItemInfo(itemID)
            if link then
                if not ChatEdit_InsertLink(link) then
                    if SELECTED_CHAT_FRAME then
                        SELECTED_CHAT_FRAME:AddMessage(link)
                    end
                end
            end
        end
    end

    frame:EnableMouse(true)
    frame:SetScript("OnEnter", OnEnter)
    frame:SetScript("OnLeave", OnLeave)
    frame:SetScript("OnMouseDown", OnMouseDown)

    local name = frame:GetName()
    local button = (name and _G[name .. "Button"]) or frame.Button
    if button then
        button:SetScript("OnEnter", OnEnter)
        button:SetScript("OnLeave", OnLeave)
        local oldClick = button:GetScript("OnClick")
        button:SetScript("OnClick", function(self, btn, down)
            if IsShiftKeyDown() then
                OnMouseDown(self, btn)
            elseif oldClick then
                oldClick(self, btn, down)
            end
        end)
    end
end
