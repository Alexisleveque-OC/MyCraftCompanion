local addonName, MCC = ...

local CreateFrame = CreateFrame
local GetMoney = GetMoney
local GetCoinTextureString = GetCoinTextureString
local tonumber = tonumber
local ipairs = ipairs
local pairs = pairs
local string = string
local type = type

MCC.isWorkActive = false
MCC.workStep = "IDLE"

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("UI_INFO_MESSAGE")
eventFrame:SetScript("OnEvent", function(self, event, msg, ...)
    if not MCC.isWorkActive then return end

    local text = msg
    if event == "UI_INFO_MESSAGE" then
        text = select(1, ...)
    end

    if not text then return end

    -- START DETECTION
    local isScanStart = text:find("Searching for") or text:find("Recherche de") or text:find("Scan en cours")
    if isScanStart and MCC.workStep == "BUYER_AH_SCAN" then
        MCC.workStatusText = MCC.L["AH Scan in progress... Please wait."] or
            "Scan de l'HV en cours... Veuillez patienter."
        if MCC.RefreshWorkProcess then MCC.RefreshWorkProcess() end
        return
    end

    -- END DETECTION
    local isAuctionator = text:find("Auctionator") or text:find("Shopping list") or text:find("Analyse de la liste")
    local isFinished = text:find("finished") or text:find("terminée") or text:find("terminé")

    if isAuctionator and isFinished then
        if MCC.workStep == "BUYER_AH_SCAN" then
            MCC.ValidateWorkStep()
        end
    end
end)

function MCC.StartWork()
    if MCC.isWorkActive then return end

    local buyer = MCC_Config.buyerCharacter
    if not buyer or buyer == "" then
        MCC.Log("|cffff0000MCC Error:|r " ..
            (MCC.L["Note: No buyer character selected means the 'Production Engine' (/mcc process) will not work correctly."] or "No buyer character selected."))
        return
    end

    -- Check if current character is an equipment crafter
    local pdata = MCC_Config[MCC.player]
    if pdata and pdata.profile == "equipment" then
        MCC.isWorkActive = true
        MCC.workStep = "EXCLUDED"
        MCC.workStatusText = (MCC.L["Equipment Crafters are excluded from the automated workflow."] or "Equipment Crafters are excluded from the automated workflow.")
        if MCC.RefreshWorkProcess then MCC.RefreshWorkProcess() end
        return
    end

    MCC.isWorkActive = true
    MCC.workStep = "INITIALIZING"

    -- If Interactive Start Screen is disabled, skip it
    if not MCC_Config.showStartScreen then
        local seller = (MCC_Config and MCC_Config.sellerCharacter)
        local currentTask = "IDLE"

        if MCC.player == buyer then
            currentTask = "BUYER_AH_SCAN"
        elseif MCC.player == seller then
            currentTask = "SELLER_POST_AUCTIONS"
        else
            currentTask = "CRAFTER_REAGENT_CHECK"
        end

        MCC.workStep = currentTask

        if currentTask == "BUYER_AH_SCAN" then
            MCC.RunBuyerWorkflow()
        elseif currentTask == "SELLER_POST_AUCTIONS" then
            MCC.RunSellerWorkflow()
        else
            MCC.RunCrafterWorkflow()
        end
    end

    if MCC.RefreshWorkProcess then
        MCC.RefreshWorkProcess()
    end
end

function MCC.RunBuyerWorkflow()
    -- Buyer Specific Logic: AH Scan step (just info now)
    MCC.workStatusText = (MCC.L["Please start an Auctionator search for the correct functioning of the addon and to listen to market prices."] or "Veuillez lancer une recherche Auctionator pour le bon fonctionnement de l'addon et écouter les prix du marché.")
end

function MCC.RunCrafterWorkflow()
    -- Crafter Specific Logic: Check reagents for local character
    local playerName = MCC.player
    local pdata = MCC_Config[playerName]
    if not pdata or not pdata.metiers then return end

    local readyToCraft = 0
    local missingReagents = 0
    local craftList = ""

    for _, metier in ipairs(pdata.metiers) do
        if metier.currentCraft then
            local qty = metier.craftQuantity or 0
            if qty > 0 then
                readyToCraft = readyToCraft + 1
                craftList = craftList .. string.format("\n- %s (%d)", metier.currentCraft, qty)
            else
                missingReagents = missingReagents + 1
            end
        end
    end

    MCC.workStatusText = ""
    if readyToCraft > 0 then
        MCC.workStatusText = string.format(MCC.L["Ready to craft: %d recipes."] or "Prêt à crafter : %d recettes.",
            readyToCraft) .. "\n" .. (MCC.L["To Craft:"] or "À Crafter :") .. craftList
    end
    if missingReagents > 0 then
        local missingText = string.format(
            MCC.L["Missing reagents for %d recipes."] or "Composants manquants pour %d recettes.", missingReagents)
        MCC.workStatusText = (MCC.workStatusText == "" and "" or (MCC.workStatusText .. "\n\n")) .. missingText
    end
end

function MCC.RunSellerWorkflow()
    -- Seller Specific Logic: Check inventory for sellable items
    MCC.workStatusText = (MCC.L["Analyzing inventory for products to sell..."] or "Analyse de l'inventaire pour les produits à vendre...")
    -- Logic to list auctions or notify user would go here
end

function MCC.StopWork()
    if not MCC.isWorkActive then return end

    MCC.isWorkActive = false
    MCC.workStep = "IDLE"
    -- MCC.workStatusText = "" -- Keep last status (Jobs Done)
    MCC.Log("|cff00ff00MCC:|r " .. (MCC.L["Jobs Done !"] or "Jobs Done !"))

    if MCC.RefreshWorkProcess then
        MCC.RefreshWorkProcess()
    end
end

function MCC.ClearCurrentCraft(playerName, metierIndex)
    local metier = MCC_Config[playerName]
        and MCC_Config[playerName].metiers
        and MCC_Config[playerName].metiers[metierIndex]

    if metier then
        metier.currentCraft = nil
        metier.craftRecipe = nil
        metier.craftQuantity = nil
        metier.activeRecipeID = nil
        MCC.Log((MCC.L["Craft deleted for"] or "Craft deleted for") .. " " .. playerName)
        -- Fix: Refresh workflow if active to update "Market analysis" text
        if MCC.isWorkActive and MCC.RefreshWorkProcess then
            MCC.RefreshWorkProcess()
        end
    end
end

-- ... (skipping to workflow steps)

function MCC.HasRequiredInBags()
    local pdata = MCC_Config[MCC.player]
    if not pdata or not pdata.inventory then return false end

    -- Collect all required items
    local requiredItems = {}
    for _, playerObj in pairs(MCC_Config) do
        if type(playerObj) == "table" and playerObj.isCharacter then
            for _, metier in ipairs(playerObj.metiers or {}) do
                if metier.currentCraft and metier.craftRecipe then
                    for _, slot in ipairs(metier.craftRecipe) do
                        if slot.selectedItemID then
                            requiredItems[slot.selectedItemID] = true
                        end
                    end
                end
            end
        end
    end

    for itemID, _ in pairs(requiredItems) do
        if (pdata.inventory[itemID] or 0) > 0 then
            return true
        end
    end
    return false
end

function MCC.ValidateWorkStep()
    if not MCC.isWorkActive or MCC.workStep == "IDLE" then return end

    if MCC.workStep == "INITIALIZING" then
        local buyer = (MCC_Config and MCC_Config.buyerCharacter)
        local seller = (MCC_Config and MCC_Config.sellerCharacter)
        local currentTask = "IDLE"

        if MCC.player == buyer then
            currentTask = "BUYER_AH_SCAN"
            MCC.workStep = currentTask
            MCC.RunBuyerWorkflow()
        elseif MCC.player == seller then
            currentTask = "SELLER_POST_AUCTIONS"
            MCC.workStep = currentTask
            MCC.RunSellerWorkflow()
        else
            currentTask = "CRAFTER_REAGENT_CHECK"
            MCC.workStep = currentTask
            MCC.RunCrafterWorkflow()
        end
        if MCC.RefreshWorkProcess then MCC.RefreshWorkProcess() end
        return
    end

    if MCC.workStep == "BUYER_AH_SCAN" then
        MCC.workStep = "BUYER_WARBANK_SYNC"
        MCC.workStatusText = MCC.L["Please open your Warbank to ensure data is synced."] or
            "Veuillez ouvrir votre banque de bataillon pour synchroniser les données."
    elseif MCC.workStep == "BUYER_WARBANK_SYNC" then
        MCC.workStep = "BUYER_READY"
        local missing = MCC.GetMissingIngredients(tonumber(MCC_Config.shoppingMargin) or 1.0)
        local totalDeficitItems = 0
        for _, data in ipairs(missing) do if data.deficit > 0 then totalDeficitItems = totalDeficitItems + 1 end end

        if totalDeficitItems > 0 then
            MCC.workStatusText = string.format(
                MCC.L["Deficit detected: %d items need to be purchased."] or "Déficit détecté : %d objets à acheter.",
                totalDeficitItems)
        else
            MCC.Log(MCC.L["No deficit detected. All reagents are available."] or
                "Aucun déficit détecté. Tous les composants sont disponibles.")
            MCC.workStep = "BUYER_READY"
            MCC.ValidateWorkStep()
            return
        end
    elseif MCC.workStep == "BUYER_READY" then
        MCC.workStep = "BUYER_GOLD_CHECK"
        local missing = MCC.GetMissingIngredients(tonumber(MCC_Config.shoppingMargin) or 1.0)
        local totalCost = 0
        for _, d in ipairs(missing) do
            if d.deficit > 0 then
                local price = MCC.GetItemPrice(d.itemID) or 0
                totalCost = totalCost + (price * d.deficit)
            end
        end
        local playerMoney = GetMoney()
        if playerMoney >= totalCost then
            MCC.Log(MCC.L["Funds sufficient. Skipping Gold Check."] or "Fonds suffisants. Saut de l'étape de retrait.")
            MCC.workStep = "BUYER_GOLD_CHECK"
            MCC.ValidateWorkStep()
            return
        else
            MCC.workStatusText = string.format(
                "|cffff0000" ..
                (MCC.L["Inadequate funds!"] or "Fonds insuffisants !") ..
                "|r\n" .. (MCC.L["You must withdraw at least:"] or "Vous devez retirer au minimum :") .. " %s",
                GetCoinTextureString(totalCost))
        end
    elseif MCC.workStep == "BUYER_GOLD_CHECK" then
        MCC.workStep = "BUYER_WARBANK_DEPOSIT"
        MCC.workStatusText = MCC.L["Please deposit all materials for your crafters into the Warbank."] or
            "Veuillez déposer tous les composants destinés aux crafteurs dans la Banque de bataillon."
    elseif MCC.workStep == "BUYER_WARBANK_DEPOSIT" then
        MCC.workStep = "BUYER_REAGENT_CHECK"
        local missing = MCC.GetMissingIngredients(tonumber(MCC_Config.shoppingMargin) or 1.0)
        local stillMissing = 0
        for _, d in ipairs(missing) do if d.deficit > 0 then stillMissing = stillMissing + 1 end end

        if stillMissing == 0 then
            -- Skip reagent check if all good, BUT DON'T RECURSE IMMEDIATELY to give UI a breath
            MCC.Log(MCC.L["Skipping Reagent Check (All stocks OK)."] or "Saut de la vérification (stocks OK).")
            MCC.workStep = "BUYER_CRAFTING"
            MCC.RunCrafterWorkflow()
            return
        else
            MCC.workStatusText = string.format(
                MCC.L["Missing Reagents Alert"] .. "\n" .. (MCC.L["Deficit: %d items."] or "Déficit : %d objets."),
                stillMissing)
        end
    elseif MCC.workStep == "BUYER_REAGENT_CHECK" then
        MCC.workStep = "BUYER_CRAFTING"
        MCC.RunCrafterWorkflow() -- Re-use Crafter logic for character crafts
    elseif MCC.workStep == "BUYER_CRAFTING" then
        MCC.workStep = "BUYER_MAIL_TO_SELLER"
        MCC.workStatusText = (MCC.L["Please mail your finished products to your Seller character."] or
                "Veuillez envoyer vos produits finis à votre personnage Vendeur.") ..
            "\n\n|cffffcc00" ..
            (MCC.L["Mail window must be open at the 'Send Mail' tab."] or "La fenêtre de courrier doit être ouverte sur l'onglet 'Envoi'.") ..
            "|r"
    elseif MCC.workStep == "BUYER_MAIL_TO_SELLER" then
        MCC.workStep = "BUYER_COMPLETE"
        MCC.workStatusText = MCC.L["Jobs Done !"] or "Jobs Done !"
    elseif MCC.workStep == "BUYER_COMPLETE" then
        -- No auto StopWork here, let the user enjoy the "Jobs Done!" screen or go back.
        -- Clicking 'X' or 'Previous' handles the state.
    elseif MCC.workStep == "CRAFTER_REAGENT_CHECK" then
        MCC.workStep = "BUYER_COMPLETE"
        MCC.workStatusText = MCC.L["Jobs Done !"] or "Jobs Done !"
    elseif MCC.workStep == "SELLER_POST_AUCTIONS" then
        MCC.workStep = "BUYER_COMPLETE"
        MCC.workStatusText = MCC.L["Jobs Done !"] or "Jobs Done !"
    end

    if MCC.RefreshWorkProcess then MCC.RefreshWorkProcess() end
end

function MCC.PreviousWorkStep()
    if not MCC.isWorkActive then return end

    if MCC.workStep == "BUYER_WARBANK_SYNC" then
        MCC.workStep = "BUYER_AH_SCAN"
        MCC.RunBuyerWorkflow()
    elseif MCC.workStep == "BUYER_READY" then
        MCC.workStep = "BUYER_WARBANK_SYNC"
        MCC.workStatusText = MCC.L["Please open your Warbank to ensure data is synced."]
    elseif MCC.workStep == "BUYER_GOLD_CHECK" then
        MCC.workStep = "BUYER_READY"
        -- Force update missing items text
        local missing = MCC.GetMissingIngredients(tonumber(MCC_Config.shoppingMargin) or 1.0)
        local totalDeficitItems = 0
        for _, data in ipairs(missing) do if data.deficit > 0 then totalDeficitItems = totalDeficitItems + 1 end end
        if totalDeficitItems > 0 then
            MCC.workStatusText = string.format(
                MCC.L["Deficit detected: %d items need to be purchased."] or "Déficit détecté : %d objets à acheter.",
                totalDeficitItems)
        else
            MCC.workStatusText = (MCC.L["No deficit detected. All reagents are available."] or "Aucun déficit détecté.") ..
                "\n\n" .. (MCC.L["Ready to proceed to next step."] or "Vous pouvez passer à l'étape suivante.")
        end
    elseif MCC.workStep == "BUYER_WARBANK_DEPOSIT" then
        MCC.workStep = "BUYER_GOLD_CHECK"
        MCC.workStatusText = MCC.L["Gold Check"] or "Retrait PO..."
    elseif MCC.workStep == "BUYER_REAGENT_CHECK" then
        MCC.workStep = "BUYER_WARBANK_DEPOSIT"
        MCC.workStatusText = MCC.L["Please deposit all materials for your crafters into the Warbank."]
    elseif MCC.workStep == "BUYER_CRAFTING" then
        MCC.workStep = "BUYER_REAGENT_CHECK"
        MCC.workStatusText = MCC.L["Reagent Check"] or "Vérification des composants..."
    elseif MCC.workStep == "BUYER_MAIL_TO_SELLER" then
        MCC.workStep = "BUYER_CRAFTING"
        MCC.RunCrafterWorkflow()
    elseif MCC.workStep == "BUYER_COMPLETE" then
        local seller = (MCC_Config and MCC_Config.sellerCharacter)
        local pdata = MCC_Config[MCC.player]
        if pdata and pdata.profile == "equipment" then
            MCC.workStep = "CRAFTER_REAGENT_CHECK"
            MCC.RunCrafterWorkflow()
        elseif MCC.player == seller then
            MCC.workStep = "SELLER_POST_AUCTIONS"
            MCC.RunSellerWorkflow()
        else
            MCC.workStep = "BUYER_MAIL_TO_SELLER"
            MCC.workStatusText = MCC.L["Please mail your finished products to your Seller character."]
        end
    else
        MCC.StopWork()
    end

    if MCC.RefreshWorkProcess then MCC.RefreshWorkProcess() end
end

function MCC.RefreshWorkProcess()
    -- This will be called to update UI or trigger next steps
    if MCC.UpdateWorkButton then
        MCC.UpdateWorkButton()
    end
    if MCC.UpdateProgressUI then
        MCC.UpdateProgressUI()
    end
end

local stepMap = {
    ["INITIALIZING"] = MCC.L["Initializing..."] or "Démarrage du workflow...",
    ["BUYER_AH_SCAN"] = MCC.L["AH Analysis..."] or "Analyse du marché...",
    ["BUYER_WARBANK_SYNC"] = MCC.L["Warbank Sync Check"] or "Vérification synchro Warbank...",
    ["BUYER_READY"] = MCC.L["Ready to Buy"] or "Prêt pour vos achats",
    ["BUYER_GOLD_CHECK"] = MCC.L["Gold Check"] or "Retrait PO si nécessaire...",
    ["BUYER_WARBANK_DEPOSIT"] = MCC.L["Warbank Deposit"] or "Dépôt en banque de bataillon...",
    ["BUYER_REAGENT_CHECK"] = MCC.L["Reagent Check"] or "Vérification des composants...",
    ["BUYER_CRAFTING"] = MCC.L["Crafting Session"] or "Session de craft en cours...",
    ["BUYER_MAIL_TO_SELLER"] = MCC.L["Mailing to Seller"] or "Envoi des produits au vendeur...",
    ["BUYER_COMPLETE"] = MCC.L["Jobs Done !"] or "Jobs Done !",
    ["SELLER_POST_AUCTIONS"] = MCC.L["Selling Items..."] or "Mise en vente des objets...",
    ["CRAFTER_REAGENT_CHECK"] = MCC.L["Checking Reagents..."] or "Vérification des composants...",
    ["EXCLUDED"] = MCC.L["Excluded"] or "Exclu du workflow",
}
