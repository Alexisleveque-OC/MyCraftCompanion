local addonName, MCC = ...
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local type = type
local CreateFrame = CreateFrame
local C_Item = C_Item
local C_Timer = C_Timer
local C_TradeSkillUI = C_TradeSkillUI
local C_CurrencyInfo = C_CurrencyInfo
local UnitName = UnitName
local GetRealmName = GetRealmName
local C_Container = C_Container
local C_Bank = C_Bank
local SendMailNameEditBox = SendMailNameEditBox
local MailFrame = MailFrame
local ProfessionsFrame = ProfessionsFrame
local hooksecurefunc = hooksecurefunc
local select = select
local pcall = pcall
local print = print
local string = string
local Enum = Enum

function MCC.CaptureProfessionData()
    if not ProfessionsFrame or not ProfessionsFrame:IsShown() then return end

    local baseInfo = C_TradeSkillUI.GetBaseProfessionInfo()
    local childInfo = C_TradeSkillUI.GetChildProfessionInfo()

    if baseInfo and baseInfo.professionID then
        if childInfo then
        end

        local player = MCC.player
        if MCC_Config[player] and MCC_Config[player].metiers then
            for i, m in ipairs(MCC_Config[player].metiers) do
                -- Compare names to find the right slot (localized)
                if m.name == baseInfo.professionName or (childInfo and m.name == childInfo.professionName) then
                    -- Priority to ChildID (Extension specific like Khaz Algar)
                    local targetID = (childInfo and childInfo.professionID) or baseInfo.professionID
                    local currencyID = C_TradeSkillUI.GetConcentrationCurrencyID(targetID)

                    -- Fallback to BaseID if ChildID failed
                    if (not currencyID or currencyID == 0) and childInfo then
                        currencyID = C_TradeSkillUI.GetConcentrationCurrencyID(baseInfo.professionID)
                    end

                    if currencyID and currencyID > 0 then
                        if m.concentrationCurrencyID ~= currencyID then
                            m.concentrationCurrencyID = currencyID
                        end
                        -- Always refresh values when UI is open
                        MCC.UpdatePlayerConcentration()
                        if MCC.RenderMCCUI then MCC.RenderMCCUI() end
                    else
                    end
                end
            end
        end
    end
end

function MCC.InitProfessionUI()
    -- Data capture should happen every time Init is called (which is on TRADE_SKILL_SHOW)
    MCC.CaptureProfessionData()

    if not ProfessionsFrame or MCC_SetCraftButton then return end

    local parent = ProfessionsFrame.CraftingPage
    if not parent then return end -- Fallback

    local setCurrentCraftbutton = CreateFrame("Button", "MCC_SetCraftButton", parent, "UIPanelButtonTemplate")
    setCurrentCraftbutton:SetSize(160, 22)
    setCurrentCraftbutton:SetText(MCC.L["Set MCC Craft"] or "Set MCC Craft")
    -- Default anchor: top-right of CraftingPage. Will be dynamically repositioned below SchematicForm requirements on first show.
    setCurrentCraftbutton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -15, -25)
    setCurrentCraftbutton:SetFrameStrata("HIGH")

    local function GetCurrentRecipeContext()
        local schematicForm = ProfessionsFrame.CraftingPage.SchematicForm
        local recipeInfo = schematicForm and schematicForm:GetRecipeInfo()
        if not recipeInfo then return nil end

        local professionInfo = ProfessionsFrame:GetProfessionInfo()
        local displayName = professionInfo and professionInfo.displayName
        local player = MCC.player or (UnitName("player") .. "-" .. GetRealmName())

        local metierIndex = nil
        if MCC_Config[player] and MCC_Config[player].metiers then
            -- Loop through all métiers to find the matching name
            for i, metier in ipairs(MCC_Config[player].metiers) do
                if metier.name == displayName then
                    metierIndex = i
                    break
                end
            end
        end

        return recipeInfo, metierIndex, player
    end

    local favButton = CreateFrame("Button", "MCC_FavoriteButton", parent)
    favButton:SetSize(28, 28)
    favButton:SetPoint("RIGHT", setCurrentCraftbutton, "LEFT", -5, 0)
    favButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Star-Up")
    favButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    favButton:SetFrameStrata("HIGH")

    -- Delete craft button (red X, only visible when recipe is already saved in MCC)
    local deleteButton = CreateFrame("Button", "MCC_DeleteCraftButton", parent, "UIPanelButtonTemplate")
    deleteButton:SetSize(24, 22)
    deleteButton:SetText("|cffff4444\195\151|r") -- Red ✕
    deleteButton:SetPoint("LEFT", setCurrentCraftbutton, "RIGHT", 4, 0)
    deleteButton:SetFrameStrata("HIGH")
    deleteButton:Hide()

    deleteButton:SetScript("OnClick", function()
        local recipeInfo, metierIndex, player = GetCurrentRecipeContext()
        if not recipeInfo or not metierIndex then return end
        local metier = MCC_Config[player] and MCC_Config[player].metiers and MCC_Config[player].metiers[metierIndex]
        if metier then
            if metier.savedSchematics then
                metier.savedSchematics[recipeInfo.recipeID] = nil
            end
            if metier.activeRecipeID == recipeInfo.recipeID then
                MCC.ClearCurrentCraft(player, metierIndex)
            end
            if MCC.UpdateShoppingList then MCC.UpdateShoppingList() end
            if MCC.RenderMCCUI then MCC.RenderMCCUI() end
        end
    end)

    deleteButton:SetScript("OnUpdate", function(self)
        local recipeInfo, metierIndex, player = GetCurrentRecipeContext()
        if not recipeInfo or not metierIndex then
            self:Hide(); return
        end
        if not ProfessionsFrame.CraftingPage:IsVisible() then
            self:Hide(); return
        end
        local metier = MCC_Config[player] and MCC_Config[player].metiers and MCC_Config[player].metiers[metierIndex]
        if metier and metier.savedSchematics and metier.savedSchematics[recipeInfo.recipeID] then
            self:Show()
        else
            self:Hide()
        end
    end)

    favButton:SetScript("OnClick", function()
        local recipeInfo, metierIndex, player = GetCurrentRecipeContext()
        if not recipeInfo or not metierIndex then return end

        MCC.ToggleFavorite(recipeInfo.recipeID, recipeInfo.name, metierIndex)
    end)

    setCurrentCraftbutton:SetScript("OnClick", function()
        local recipeInfo, metierIndex, player = GetCurrentRecipeContext()
        if not recipeInfo or not metierIndex then
            return
        end

        -- DYNAMIC CAPTURE: Look for concentration cost in multiple possible UI locations
        local concCost = 0
        local schematicForm = ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
        if schematicForm then
            local opInfo = nil
            if schematicForm.GetRecipeOperationInfo then
                opInfo = schematicForm:GetRecipeOperationInfo()
            elseif schematicForm.GetCraftingOperationInfo then
                opInfo = schematicForm:GetCraftingOperationInfo()
            end

            if not opInfo and schematicForm.GetTransaction then
                local transaction = schematicForm:GetTransaction()
                if transaction then
                    if transaction.GetRecipeOperationInfo then
                        opInfo = transaction:GetRecipeOperationInfo()
                    elseif transaction.GetCraftingOperationInfo then
                        opInfo = transaction:GetCraftingOperationInfo()
                    end
                end
            end

            if opInfo then
                concCost = opInfo.concentrationCost or 0
            end
        end

        local recipeInfo = GetCurrentRecipeContext()
        if not recipeInfo then return end

        local player = MCC.player
        local metierIndex = nil

        -- Find matching metier index
        if MCC_Config[player] and MCC_Config[player].metiers then
            for i, m in ipairs(MCC_Config[player].metiers) do
                if m.name == C_TradeSkillUI.GetBaseProfessionInfo().professionName or
                    m.name == C_TradeSkillUI.GetChildProfessionInfo().professionName then
                    metierIndex = i
                    break
                end
            end
        end

        if not metierIndex then return end

        -- DYNAMIC CAPTURE: Look for concentration cost in multiple possible UI locations
        local concCost = 0
        local schematicForm = ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
        if schematicForm then
            local opInfo = nil
            if schematicForm.GetRecipeOperationInfo then
                opInfo = schematicForm:GetRecipeOperationInfo()
            elseif schematicForm.GetCraftingOperationInfo then
                opInfo = schematicForm:GetCraftingOperationInfo()
            end

            if not opInfo and schematicForm.GetTransaction then
                local transaction = schematicForm:GetTransaction()
                if transaction then
                    if transaction.GetRecipeOperationInfo then
                        opInfo = transaction:GetRecipeOperationInfo()
                    elseif transaction.GetCraftingOperationInfo then
                        opInfo = transaction:GetCraftingOperationInfo()
                    end
                end
            end

            if opInfo then
                concCost = opInfo.concentrationCost or 0
            end
        end

        MCC.SetCurrentCraft(player, metierIndex, recipeInfo, concCost)
    end)

    -- Visibility & Texture logic
    favButton:SetScript("OnUpdate", function(self)
        if not ProfessionsFrame or not ProfessionsFrame:IsShown() then
            self:Hide()
            return
        end
        local recipeInfo, metierIndex, player = GetCurrentRecipeContext()

        if recipeInfo and metierIndex then
            -- Only show favorite button if the CraftingPage is actually the one visible
            if ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage:IsVisible() then
                self:Show()
            else
                self:Hide()
                return
            end

            local metier = MCC_Config[player] and MCC_Config[player].metiers and MCC_Config[player].metiers[metierIndex]
            if not metier then return end

            if metier.favorites and metier.favorites[recipeInfo.recipeID] then
                self:GetNormalTexture():SetVertexColor(1, 1, 0)       -- Gold
            else
                self:GetNormalTexture():SetVertexColor(0.5, 0.5, 0.5) -- Gray
            end
        else
            self:Hide()
        end
    end)

    setCurrentCraftbutton:SetScript("OnUpdate", function(self)
        if not ProfessionsFrame or not ProfessionsFrame:IsShown() then
            self:Hide()
            return
        end

        -- Use IsVisible() which checks the entire hierarchy
        local page = ProfessionsFrame.CraftingPage
        if page and page:IsVisible() then
            self:Show()
        else
            self:Hide()
        end
    end)

    MCC_SetCraftButton = setCurrentCraftbutton
    MCC_FavoriteButton = favButton
    MCC_DeleteCraftButton = deleteButton

    -- Reanchor button below requirements, to the right of the OutputIcon
    -- OutputIcon TOPRIGHT = recipe name level, so offset -28 brings it to requirements level
    C_Timer.After(0.1, function()
        local sf = ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
        if sf then
            if sf.OutputIcon then
                setCurrentCraftbutton:ClearAllPoints()
                setCurrentCraftbutton:SetPoint("TOPLEFT", sf.OutputIcon, "TOPRIGHT", 8, -40)
                -- Realign fav and delete buttons
                if MCC_FavoriteButton then
                    MCC_FavoriteButton:ClearAllPoints()
                    MCC_FavoriteButton:SetPoint("RIGHT", setCurrentCraftbutton, "LEFT", -4, 0)
                end
                if MCC_DeleteCraftButton then
                    MCC_DeleteCraftButton:ClearAllPoints()
                    MCC_DeleteCraftButton:SetPoint("LEFT", setCurrentCraftbutton, "RIGHT", 4, 0)
                end
            elseif sf.Description then
                setCurrentCraftbutton:ClearAllPoints()
                setCurrentCraftbutton:SetPoint("BOTTOMLEFT", sf.Description, "TOPLEFT", 0, 4)
            end
        end
    end)
end

-- Events for Inventory
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
-- Warband bank: fires when any slot changes in an account-wide bank tab
eventFrame:RegisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")

-- SECURE HOOK: Capture concentration cost proactively when the user clicks "Craft"
local function OnCraftRecipeHook(recipeID, count)
    -- Identify métier
    local currentCraftMetierIndex = nil
    local player = MCC.player
    if MCC_Config[player] and MCC_Config[player].metiers then
        for i, m in ipairs(MCC_Config[player].metiers) do
            if m.activeRecipeID == recipeID then
                currentCraftMetierIndex = i
                break
            end
        end
    end

    -- Capture cost from UI right now
    local schematicForm = ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
    if schematicForm and currentCraftMetierIndex then
        local opInfo = schematicForm.GetRecipeOperationInfo and schematicForm:GetRecipeOperationInfo() or
            (schematicForm.GetCraftingOperationInfo and schematicForm:GetCraftingOperationInfo())

        if opInfo and opInfo.concentrationCost and opInfo.concentrationCost > 0 then
            MCC.UpdateCostFromRealCraft(player, currentCraftMetierIndex, opInfo.concentrationCost)
        end
    end
end

hooksecurefunc(C_TradeSkillUI, "CraftRecipe", OnCraftRecipeHook)
hooksecurefunc(C_TradeSkillUI, "CraftEnchant", OnCraftRecipeHook)

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
        local bagID = (event == "BAG_UPDATE") and select(1, ...) or nil

        -- Scan bags for any update
        MCC.ScanBags()

        if bagID then
            if bagID == -1 or bagID == -3 or (bagID >= 6 and bagID <= 12) then
                if MCC.ScanPersonalBank then MCC.ScanPersonalBank() end
            elseif bagID >= 13 then
                if MCC.ScanWarbank then MCC.ScanWarbank() end
            end
        else
            -- Delayed update or scan all
            if MCC.ScanPersonalBank then MCC.ScanPersonalBank() end
            if MCC.ScanWarbank then MCC.ScanWarbank() end
        end

        -- AUTO-ADVANCE logic for Warbank Deposit
        if MCC.isWorkActive and MCC.workStep == "BUYER_WARBANK_DEPOSIT" then
            -- We give it half a second for Blizzard's back-end to update inventory
            C_Timer.After(0.5, function()
                if MCC.isWorkActive and MCC.workStep == "BUYER_WARBANK_DEPOSIT" then
                    if MCC.HasRequiredInBags and not MCC.HasRequiredInBags() then
                        if MCC.ValidateWorkStep then
                            MCC.ValidateWorkStep()
                        end
                    end
                end
            end)
        end
    elseif event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED" then
        -- Account bank deposits are slow to sync. Wait 1s for the container data.
        C_Timer.After(1.0, function()
            if MCC.ScanWarbank then MCC.ScanWarbank() end
        end)
    elseif event == "BANKFRAME_OPENED" then
        MCC.ScanBags()
        if MCC.ScanPersonalBank then MCC.ScanPersonalBank() end
        if MCC.ScanWarbank then MCC.ScanWarbank() end

        -- AUTO-ADVANCE: Sync step
        if MCC.isWorkActive and MCC.workStep == "BUYER_WARBANK_SYNC" then
            if MCC.ValidateWorkStep then MCC.ValidateWorkStep() end
        end
    elseif event == "PLAYERBANKSLOTS_CHANGED" then
        MCC.ScanBags()
        if MCC.ScanPersonalBank then MCC.ScanPersonalBank() end
        if MCC.ScanWarbank then MCC.ScanWarbank() end
    end
end)

-- Mail Integration
local mailEventFrame = CreateFrame("Frame")
mailEventFrame:RegisterEvent("MAIL_SHOW")
mailEventFrame:RegisterEvent("MAIL_CLOSED")
mailEventFrame:RegisterEvent("MAIL_SEND_SUCCESS")

function MCC.DepositAllWarboundItems()
    if C_Bank and C_Bank.AutoDepositItemsIntoBank then
        C_Bank.AutoDepositItemsIntoBank(Enum.BankType.Account)
    elseif C_Bank and C_Bank.DepositAllWarboundItems then
        C_Bank.DepositAllWarboundItems()
    else
        MCC.Log("|cffff0000MCC Error:|r Aucune API de dépôt Warbank trouvée.")
    end
end

function MCC.ProcessMail()
    local seller = MCC_Config.sellerCharacter
    if not seller or seller == "" then
        print("MCC: Aucun vendeur configuré. Veuillez définir un personnage Vendeur dans les paramètres.")
        return
    end

    local player = MCC.player or (UnitName("player") .. "-" .. GetRealmName())
    local pdata = MCC_Config[player]
    if not pdata or not pdata.metiers then return end

    -- Identify items to send (Current Crafts)
    local itemsToSend = {}
    for _, metier in ipairs(pdata.metiers) do
        if metier.currentCraft and metier.activeRecipeID then
            -- Use the helper to get the real resulting item (Scroll for enchants, etc)
            local itemID = MCC.GetRecipeMaxRankItemID(metier.activeRecipeID)
            if itemID then
                local name = C_Item.GetItemInfo(itemID)
                if name then
                    itemsToSend[name] = true
                else
                    -- Fallback: wait for item info if nil
                    itemsToSend[metier.currentCraft] = true
                end
            else
                -- Fallback to craft name
                itemsToSend[metier.currentCraft] = true
            end
        end
    end

    -- Set Recipient
    SendMailNameEditBox:SetText(seller)

    -- Scan Bags for items matching the Craft Name
    local mailSlot = 1
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local name = C_Item.GetItemInfo(info.itemID)
                if name and itemsToSend[name] then
                    if mailSlot <= 12 then
                        C_Container.UseContainerItem(bag, slot)
                        mailSlot = mailSlot + 1
                    end
                end
            end
        end
    end
end

mailEventFrame:SetScript("OnEvent", function(self, event)
    if event == "MAIL_SHOW" then
        -- We no longer create a button in Blizzard's UI as per user request.
        -- It's now in the Progress UI.
    elseif event == "MAIL_CLOSED" or event == "MAIL_SEND_SUCCESS" then
        -- AUTO-ADVANCE: After mailing or closing mail, finish the workflow
        if MCC.isWorkActive and MCC.workStep == "BUYER_MAIL_TO_SELLER" then
            if MCC.ValidateWorkStep then MCC.ValidateWorkStep() end
        end
    end
end)

-------------------------------------------------------
-- Auctionator Integration
-------------------------------------------------------

-- GetItemPrice is defined in Utils.lua (loaded first)

function MCC.SyncReagentsToWoWUI(playerName, metierIndex)
    if playerName ~= MCC.player then return end -- Only for local player

    local pdata = MCC_Config[playerName]
    if not pdata or not pdata.metiers then return end

    local metier = pdata.metiers[metierIndex]
    if not metier or not metier.activeRecipeID or not metier.craftRecipe then return end

    local schematicForm = ProfessionsFrame.CraftingPage.SchematicForm
    if not schematicForm or not schematicForm:IsShown() then return end

    local recipeInfo = schematicForm:GetRecipeInfo()
    if not recipeInfo or recipeInfo.recipeID ~= metier.activeRecipeID then return end

    local transaction = schematicForm:GetTransaction()
    if not transaction then return end


    -- For basic reagents, we want to allocate based on what's in MCC
    -- We'll use the SchematicForm:AllocateItem which is the cleanest way
    for _, savedReagent in ipairs(metier.craftRecipe) do
        local itemID = savedReagent.itemID or savedReagent.selectedItemID
        if itemID then
            pcall(function()
                schematicForm:AllocateItem(itemID)
            end)
        end
    end

    -- Force UI refresh
    schematicForm:OnAllocationsChanged()
end

-- AUTO-LAUNCH LOGIC
local autoLaunchFrame = CreateFrame("Frame")
autoLaunchFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
autoLaunchFrame:SetScript("OnEvent", function(self, event)
    local pdata = MCC_Config[MCC.player]
    if pdata and pdata.autoLaunch then
        C_Timer.After(2.0, function()
            if not MCC.isWorkActive then
                MCC.StartWork()
            end
            if MCC.ToggleProgressUI then
                -- Open first, StartWork might already have toggled it if we refine StartWork
                -- but ToggleProgressUI is safe.
                if not MCC_ProgressFrame or not MCC_ProgressFrame:IsShown() then
                    MCC.ToggleProgressUI()
                end
            end
        end)
    end
end)
