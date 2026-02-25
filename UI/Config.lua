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

    -- Warning: Buyer + Seller required for Production Engine
    local engineWarning = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    engineWarning:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)
    engineWarning:SetWidth(parent:GetWidth() - 40)
    engineWarning:SetJustifyH("LEFT")
    engineWarning:SetText("|cffff9900" ..
        (MCC.L["Note: Selecting both a Buyer and a Seller is required for the 'Production Engine' (/mcc process) to operate correctly."] or
            "Note: Selecting both a Buyer and a Seller is required for the 'Production Engine' (/mcc process) to operate correctly.") ..
        "|r")

    -- 1. Buyer Character Dropdown
    local buyerLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buyerLabel:SetPoint("TOPLEFT", engineWarning, "BOTTOMLEFT", 0, -20)
    buyerLabel:SetText(MCC.L["Buyer Character"] or "Personnage Acheteur")

    local buyerDesc = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    buyerDesc:SetPoint("TOPLEFT", buyerLabel, "BOTTOMLEFT", 0, -5)
    buyerDesc:SetText(MCC.L["Select which character is responsible for buying reagents."] or
        "Select which character is responsible for buying reagents.")

    local dropdown = CreateFrame("Frame", "MCC_InternalBuyerDropDown", container, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", buyerDesc, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(dropdown, 200)

    local function RefreshBuyerDropdownText()
        local current = MCC_Config.buyerCharacter or ""
        UIDropDownMenu_SetText(dropdown, current == "" and MCC.L["None"] or current)
    end

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.text = MCC.L["None"]
        info.func = function()
            MCC_Config.buyerCharacter = ""
            RefreshBuyerDropdownText()
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
                RefreshBuyerDropdownText()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    RefreshBuyerDropdownText()

    -- 2. Seller Character Dropdown
    local sellerLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sellerLabel:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 15, -20)
    sellerLabel:SetText(MCC.L["Seller Character"] or "Personnage Vendeur")

    local sellerDesc = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sellerDesc:SetPoint("TOPLEFT", sellerLabel, "BOTTOMLEFT", 0, -5)
    sellerDesc:SetText(MCC.L["Select which character is responsible for selling products."] or
        "Select which character is responsible for selling products.")

    local sellerDropdown = CreateFrame("Frame", "MCC_InternalSellerDropDown", container, "UIDropDownMenuTemplate")
    sellerDropdown:SetPoint("TOPLEFT", sellerDesc, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(sellerDropdown, 200)

    local function RefreshSellerDropdownText()
        local current = MCC_Config.sellerCharacter or ""
        UIDropDownMenu_SetText(sellerDropdown, current == "" and MCC.L["None"] or current)
    end

    UIDropDownMenu_Initialize(sellerDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.text = MCC.L["None"]
        info.func = function()
            MCC_Config.sellerCharacter = ""
            RefreshSellerDropdownText()
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
                MCC_Config.sellerCharacter = name
                RefreshSellerDropdownText()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    RefreshSellerDropdownText()

    -- 3. Auto-launch Checkbox
    local autoLaunch = CreateFrame("CheckButton", "MCC_AutoLaunchCheck", container, "InterfaceOptionsCheckButtonTemplate")
    autoLaunch:SetPoint("TOPLEFT", sellerDropdown, "BOTTOMLEFT", 20, -10)
    _G[autoLaunch:GetName() .. "Text"]:SetText(MCC.L["Auto-launch on login"] or "Auto-launch on login")

    autoLaunch:SetScript("OnClick", function(self)
        local player = MCC.player
        if not MCC_Config[player] then MCC_Config[player] = {} end
        MCC_Config[player].autoLaunch = self:GetChecked()
    end)

    autoLaunch:SetScript("OnShow", function(self)
        local player = MCC.player
        self:SetChecked(MCC_Config[player] and MCC_Config[player].autoLaunch or false)
    end)

    -- 4. Interactive Start Screen Checkbox
    local startScreen = CreateFrame("CheckButton", "MCC_ShowStartScreenCheck", container,
        "InterfaceOptionsCheckButtonTemplate")
    startScreen:SetPoint("TOPLEFT", autoLaunch, "BOTTOMLEFT", 0, -10)
    _G[startScreen:GetName() .. "Text"]:SetText(MCC.L["Show Start Screen"] or "Show Start Screen")
    startScreen.tooltipText = MCC.L["Display the 'Work, work !' screen at the start and wait for a click."]

    startScreen:SetScript("OnClick", function(self)
        MCC_Config.showStartScreen = self:GetChecked()
    end)

    startScreen:SetScript("OnShow", function(self)
        self:SetChecked(MCC_Config.showStartScreen or false)
    end)



    return container
end
