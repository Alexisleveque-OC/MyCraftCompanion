local addonName, MCC = ...

function MCC.InitProfessionUI()
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
            MCC.Log("|cffff4444MCC:|r Recette supprimée: " .. recipeInfo.name)
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
            MCC.Log("Métier ou recette non prêt(e)")
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
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
-- As of 11.0, Warbank likely triggers BANKFRAME_OPENED or similar when visiting the bank.

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
    if event == "BAG_UPDATE" then
        local bagID = ...
        if bagID and bagID <= 5 then
            MCC.ScanBags()
        elseif bagID and bagID >= 13 then
            MCC.ScanWarbank()
        end
    elseif event == "BANKFRAME_OPENED" or event == "PLAYERBANKSLOTS_CHANGED" then
        MCC.ScanBags()
        MCC.ScanWarbank()
    end
end)

-- Mail Integration
local mailEventFrame = CreateFrame("Frame")
mailEventFrame:RegisterEvent("MAIL_SHOW")

local function ProcessMail()
    if not MCC_Config.vendorName or MCC_Config.vendorName == "" then
        print("MCC: Aucun vendeur configuré. Remplissez le champ 'Vendeur' dans l'interface principale.")
        return
    end

    local player = MCC.player or (UnitName("player") .. "-" .. GetRealmName())
    local pdata = MCC_Config[player]
    if not pdata or not pdata.metiers then return end

    -- Identify items to send (Current Crafts)
    local itemsToSend = {}
    for _, metier in ipairs(pdata.metiers) do
        if metier.currentCraft and metier.craftRecipe then
            -- We assume the 'currentCraft' Name is what we want, but better:
            -- The user said "send crafts registered". usually this means the RESULT of the craft.
            -- My addon tracks INGREDIENTS.
            -- Wait, if I track ingredients, I don't know the Output Item ID easily unless I stored it.
            -- The `recipeInfo` in Data.lua has `recipeID`. I might need to get the "Output Item" from the recipe.
            -- BUT, for now, let's assume the user wants to send the CURRENT CRAFT's OUTPUT.
            -- Since I don't store the Output Item ID in `metier.currentCraft` (it's just a name),
            -- I might have to rely on name matching or scanning bags for the name.
            -- Scanning by name is risky but acceptable for "Send to Vendor".

            -- PLAN B: The user might mean "Send the ingredients I just bought to my crafter".
            -- "Mon vendeur" implies selling results.
            -- Let's assume matches by NAME of the current craft.

            if metier.currentCraft then
                itemsToSend[metier.currentCraft] = true
            end
        end
    end

    -- Set Recipient
    SendMailNameEditBox:SetText(MCC_Config.vendorName)

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
        if not MCC_MailButton then
            local btn = CreateFrame("Button", "MCC_MailButton", MailFrame, "UIPanelButtonTemplate")
            btn:SetSize(120, 22)
            btn:SetPoint("TOPLEFT", MailFrame, "TOPLEFT", 60, -20)
            btn:SetText("Envoyer Crafts")
            btn:SetScript("OnClick", function()
                ProcessMail()
            end)
        end
    end
end)

-------------------------------------------------------
-- Auctionator Integration
-------------------------------------------------------

function MCC.GetItemPrice(itemID)
    if not itemID then return 0 end

    -- Try Auctionator API
    if Auctionator and Auctionator.API and Auctionator.API.v1 then
        local price = Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID)
        if price and price > 0 then
            return price
        end
    end

    -- Fallback to vendor price
    local _, _, _, _, _, _, _, _, _, _, vendorPrice = C_Item.GetItemInfo(itemID)
    return vendorPrice or 0
end

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

    MCC.Log("MCC: Application des composants vers WoW (" .. metier.currentCraft .. ")")

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
