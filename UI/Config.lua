local _, MCC = ...

-- NEW: Function to build the settings UI inside the main addon window
function MCC.CreateSettingsUI(parent)
    if not parent then return end

    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints()

    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText(MCC.L["General Settings"] or "Paramètres Généraux")

    -- About / Description
    local desc = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(parent:GetWidth() - 40)
    desc:SetJustifyH("LEFT")
    desc:SetText(MCC.L["Help_1_Text"] or "Open your profession windows once to register your characters in the addon.")

    -- 1. Buyer Character Dropdown
    local buyerLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buyerLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -30)
    buyerLabel:SetText(MCC.L["Buyer Character"] or "Personnage Acheteur")

    local dropdown = CreateFrame("Frame", "MCC_InternalBuyerDropDown", container, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", buyerLabel, "BOTTOMLEFT", -15, -10)
    UIDropDownMenu_SetWidth(dropdown, 200)

    local function RefreshDropdownText()
        local current = MCC_Config.buyerCharacter or ""
        UIDropDownMenu_SetText(dropdown, current == "" and MCC.L["None"] or current)
    end

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.text = MCC.L["None"]
        info.func = function()
            MCC_Config.buyerCharacter = ""
            RefreshDropdownText()
        end
        UIDropDownMenu_AddButton(info)

        local sortedNames = {}
        for name, data in pairs(MCC_Config) do
            if type(data) == "table" and data.metiers then
                table.insert(sortedNames, name)
            end
        end
        table.sort(sortedNames)

        for _, name in ipairs(sortedNames) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.func = function()
                MCC_Config.buyerCharacter = name
                RefreshDropdownText()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    RefreshDropdownText()

    -- 2. Warning Note (Just below the option)
    local warning = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    warning:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 20, -10)
    warning:SetWidth(parent:GetWidth() - 60)
    warning:SetJustifyH("LEFT")
    warning:SetText("|cffff0000" ..
    (MCC.L["Note: No buyer character selected means the 'Production Engine' (/mcc process) will not work correctly."] or "Note: Si aucun perso acheteur n'est défini, le 'Moteur de Production' ne pourra pas fonctionner correctement.") ..
    "|r")

    return container
end
