local addonName, MCC = ...
local GetRealmName = GetRealmName
local UnitName = UnitName
local Enum = Enum
local C_Container = C_Container

-- CONSISTENT PLAYER KEY: Used across the addon to group data
-- Initialized in Data.lua for load order safety.
MCC.player = UnitName("player") .. "-" .. (GetRealmName() or ""):gsub(" ", "")

function MCC.GetMissingIngredients(multiplier)
    local totals = {}
    multiplier = multiplier or 1.0

    local aggregateDemand = {}

    for playerName, pdata in pairs(MCC_Config) do
        if type(pdata) == "table" and pdata.isCharacter then
            -- CRITICAL FIX: Only count hyphenated names to avoid doubling with stale "ShortName" entries
            if playerName:find("-") then
                for _, metier in ipairs(pdata.metiers or {}) do
                    if metier.currentCraft and metier.craftRecipe then
                        local craftQty = tonumber(metier.craftQuantity) or 1
                        for _, slot in ipairs(metier.craftRecipe) do
                            if slot.selectedItemID then
                                local itemID = slot.selectedItemID
                                local rank = slot.selectedRank or 0
                                local key = itemID .. "-" .. rank
                                local totalQty = (slot.quantity or 0) * craftQty

                                if not aggregateDemand[key] then
                                    aggregateDemand[key] = { itemID = itemID, rank = slot.selectedRank, quantity = 0 }
                                end
                                aggregateDemand[key].quantity = aggregateDemand[key].quantity + totalQty
                            end
                        end
                    end
                end
            end
        end
    end

    for key, data in pairs(aggregateDemand) do
        local itemID = data.itemID
        local bagsOwned = 0
        local bankOwned = 0
        local warbankOwned = 0

        for playerName, pdata in pairs(MCC_Config) do
            if type(pdata) == "table" and pdata.isCharacter then
                -- CRITICAL FIX: Only count hyphenated names
                if playerName:find("-") then
                    if pdata.inventory and pdata.inventory[itemID] then
                        bagsOwned = bagsOwned + pdata.inventory[itemID]
                    end
                    if pdata.personalBank and pdata.personalBank[itemID] then
                        bankOwned = bankOwned + pdata.personalBank[itemID]
                    end
                end
            end
        end
        if MCC_Config.Warbank and MCC_Config.Warbank[itemID] then
            warbankOwned = warbankOwned + MCC_Config.Warbank[itemID]
        end

        data.bagsOwned = bagsOwned
        data.bankOwned = bankOwned
        data.charOwned = bagsOwned + bankOwned
        data.warbankOwned = warbankOwned
        data.owned = data.charOwned + warbankOwned
        data.requiredWithMargin = math.ceil(data.quantity * multiplier)
        data.deficit = math.max(0, data.requiredWithMargin - data.owned)
        table.insert(totals, data)
    end

    local sortedList = {}
    for _, data in pairs(totals) do table.insert(sortedList, data) end
    table.sort(sortedList, function(a, b) return MCC.GetItemNameSafe(a.itemID) < MCC.GetItemNameSafe(b.itemID) end)

    return sortedList
end

-- Enregistrer un perso et ses métiers
function MCC.RegisterPlayerCraft(playerName, professions)
    MCC_Config[playerName] = MCC_Config[playerName] or {}
    MCC_Config[playerName].isCharacter = true
    MCC_Config[playerName].metiers = MCC_Config[playerName].metiers or {}

    for i, prof in ipairs(professions) do
        if prof then
            local _, classFile = UnitClass("player")
            MCC_Config[playerName].class = classFile
            local name, _, rank, maxRank = GetProfessionInfo(prof)
            MCC_Config[playerName].metiers[i] = MCC_Config[playerName].metiers[i] or {}
            MCC_Config[playerName].metiers[i].name = name
            -- Tracked per métier
            MCC_Config[playerName].metiers[i].favorites = MCC_Config[playerName].metiers[i].favorites or {}
            MCC_Config[playerName].metiers[i].savedSchematics = MCC_Config[playerName].metiers[i].savedSchematics or {}

            -- Concentration Trackers
            MCC_Config[playerName].metiers[i].concentration = MCC_Config[playerName].metiers[i].concentration or 0
            MCC_Config[playerName].metiers[i].concentrationMax = MCC_Config[playerName].metiers[i].concentrationMax or
                1000
            MCC_Config[playerName].metiers[i].lastUpdate = MCC_Config[playerName].metiers[i].lastUpdate or time()
            MCC_Config[playerName].metiers[i].concentrationCurrencyID = MCC_Config[playerName].metiers[i]
                .concentrationCurrencyID or nil
        end
    end

    MCC.Log((MCC.L["Character registered: "] or "Character registered: ") .. playerName)
end

function MCC.SetCurrentCraft(playerName, metierIndex, recipe, concCost, uiReagents)
    MCC.Log("SetCurrentCraft called for " ..
        tostring(playerName) .. " | Recipe: " .. (recipe and (recipe.recipeName or recipe.recipeID) or "nil"))

    if not recipe then
        MCC.Log("MCC Error: SetCurrentCraft received nil recipe")
        return
    end
    if not recipe.recipeID then
        MCC.Log(MCC.L["Invalid Recipe"])
        return
    end

    local metier = MCC_Config[playerName]
        and MCC_Config[playerName].metiers
        and MCC_Config[playerName].metiers[metierIndex]

    -- 1. Initialize metadata
    metier.activeRecipeID = recipe.recipeID
    metier.currentCraft = recipe.recipeName or recipe.name

    -- 2. RESTORE or INITIALIZE
    metier.savedSchematics = metier.savedSchematics or {}
    if metier.savedSchematics[recipe.recipeID] and not uiReagents then
        -- Only restore from cache if we DON'T have fresh UI selections
        local saved = metier.savedSchematics[recipe.recipeID]
        metier.craftRecipe = saved.craftRecipe
        metier.craftQuantity = saved.craftQuantity
        MCC.Log("MCC: " .. (MCC.L["Craft restored for"] or "Craft restored for") .. " " .. metier.currentCraft)
    elseif metier.savedSchematics[recipe.recipeID] and uiReagents then
        -- Saved craft exists but player clicked with fresh selections → reinit with overrides
        MCC.Log("MCC: Mise à jour des ingrédients pour " .. metier.currentCraft)
        metier.savedSchematics[recipe.recipeID] = nil -- force re-init with uiReagents
    else
        -- INITIALIZE NEW
        local schematic = C_TradeSkillUI.GetRecipeSchematic(recipe.recipeID, false)
        if not schematic or not schematic.reagentSlotSchematics then
            MCC.Log("MCC Error: Schematic not found for " .. recipe.recipeID)
            return
        end

        metier.craftRecipe = {}
        metier.craftQuantity = 1

        -- Save output item for profit estimation
        if schematic.outputItemID then
            metier.outputItemID = schematic.outputItemID
            metier.outputQty = schematic.quantityMax or schematic.quantityMin or 1
        end

        for slotIndex, slot in ipairs(schematic.reagentSlotSchematics) do
            if slot.reagents and slot.quantityRequired and slot.quantityRequired > 0 then
                local options = {}
                local numReagents = #slot.reagents
                for reagentIndex, reagent in ipairs(slot.reagents) do
                    if reagent.itemID then
                        local rank = nil
                        if C_TradeSkillUI.GetItemReagentQualityInfo then
                            local success, qInfo = pcall(C_TradeSkillUI.GetItemReagentQualityInfo, reagent.itemID)
                            if success and qInfo then rank = qInfo.quality end
                        end
                        -- Fallback for different counts (Midnight = 2, TWW = 3)
                        if not rank then
                            if numReagents == 3 then
                                rank = reagentIndex
                            elseif numReagents == 2 then
                                rank = reagentIndex
                            end
                        end

                        table.insert(options, {
                            itemID = reagent.itemID,
                            rank = rank,
                        })
                    end
                end

                if #options > 0 then
                    -- SMART PRE-FILLING: Take the highest rank available by default
                    -- But if uiReagents override was provided, use that instead
                    local bestOption = options[#options]
                    local overrideItemID = uiReagents and uiReagents[slotIndex]
                    if overrideItemID then
                        -- Find the matching option by itemID
                        for _, opt in ipairs(options) do
                            if opt.itemID == overrideItemID then
                                bestOption = opt
                                break
                            end
                        end
                    end
                    metier.craftRecipe[slotIndex] = {
                        quantity = slot.quantityRequired,
                        dataSlotIndex = slot.dataSlotIndex,
                        options = options,
                        selectedItemID = bestOption.itemID,
                        selectedRank = bestOption.rank
                    }
                end
            end
        end
    end

    -- 3. UPDATE CONCENTRATION & CAPACITY (Always run this, even for restored crafts)
    -- Use captured cost from UI if provided, otherwise fallback to existing or recalculate
    metier.concentrationCost = concCost or metier.concentrationCost or 0

    -- User choice priority: Do NOT auto-fill quantity with capacity anymore
    -- local capacity = MCC.GetCraftCapacity(metier)
    -- if capacity and capacity > 0 then
    --     metier.craftQuantity = capacity
    -- end

    MCC.Log("MCC: " .. (MCC.L["Craft defined/updated:"] or "Craft defined/updated:") .. " " ..
        metier.currentCraft .. " (Cost: " .. (metier.concentrationCost or 0) .. ")")

    -- 3. SAVE IMMEDIATELY
    metier.savedSchematics[metier.activeRecipeID] = {
        recipeName = metier.currentCraft,
        craftRecipe = metier.craftRecipe,
        craftQuantity = metier.craftQuantity or 1,
        concentrationCost = metier.concentrationCost,
        concentrationCurrencyID = metier.concentrationCurrencyID,
        outputItemID = metier.outputItemID,
        outputQty = metier.outputQty
    }

    if MCC.UpdateShoppingList then MCC.UpdateShoppingList() end
    if MCC.RenderMCCUI then MCC.RenderMCCUI() end
end

-- Calculation Helpers
function MCC.GetEstimatedConcentration(metier)
    -- Simplified: Assume 1000 max as requested
    return 1000
end

-- Internal mapping for Enchants that don't return an ItemID via Blizzard APIs
-- Mapping: craftingDataID -> Max Rank Scroll ItemID (or Base ID for upcoming expansions)
-- This list is dynamically mapped via C_TradeSkillUI.GetCraftingOperationInfo
MCC.CraftingDataMap = {
    [1576] = 223650,
    [1577] = 223653,
    [1578] = 223656,
    [1579] = 223659,
    [1580] = 223662,
    [1581] = 223665,
    [1582] = 223674,
    [1583] = 223668,
    [1584] = 223677,
    [1585] = 223671,
    [1586] = 223680,
    [1587] = 223775,
    [1588] = 223778,
    [1589] = 223781,
    [1627] = 223683,
    [1628] = 223686,
    [1629] = 223692,
    [1630] = 223689,
    [1631] = 223695,
    [1632] = 223698,
    [1633] = 223701,
    [1634] = 223704,
    [1635] = 223707,
    [1636] = 223772,
    [1637] = 223759,
    [1638] = 223762,
    [1639] = 223765,
    [1640] = 223768,
    [1641] = 223747,
    [1642] = 223750,
    [1643] = 223753,
    [1644] = 223756,
    [1645] = 223710,
    [1646] = 223713,
    [1647] = 223716,
    [1648] = 223719,
    [1649] = 223722,
    [1650] = 223725,
    [1651] = 223800,
    [1652] = 223740,
    [1653] = 223737,
    [1654] = 223734,
    [1655] = 223731,
    [1656] = 223728,
    [1657] = 223787,
    [1658] = 223790,
    [1659] = 223793,
    [1660] = 223796,
    [1661] = 223784,
    [2447] = 223665,
}

function MCC.GetRecipeMaxRankItemID(recipeID)
    if not recipeID then return nil end
    local bestID = nil

    -- 0. Check internal CraftingDataMap using GetCraftingOperationInfo
    if C_TradeSkillUI.GetCraftingOperationInfo then
        local operationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, {}, nil, false)
        if operationInfo and operationInfo.craftingDataID and MCC.CraftingDataMap[operationInfo.craftingDataID] then
            local mappedID = MCC.CraftingDataMap[operationInfo.craftingDataID]
            return mappedID
        end
    end

    -- 1. Try Quality Item IDs (Most reliable for Dragonflight/TWW quality items)
    if C_TradeSkillUI.GetRecipeQualityItemIDs then
        local qualityItemIDs = C_TradeSkillUI.GetRecipeQualityItemIDs(recipeID)
        if qualityItemIDs and #qualityItemIDs > 0 then
            bestID = qualityItemIDs[#qualityItemIDs]
        end
    end

    -- 2. Try Schematic Output
    if not bestID then
        local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
        if schematic and schematic.outputItemID then
            bestID = schematic.outputItemID
        end
    end

    -- 3. Try Recipe Info Output (Newer API for some recipes)
    if not bestID then
        local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
        if recipeInfo and recipeInfo.unparsedRecipeLink then
            bestID = tonumber(recipeInfo.unparsedRecipeLink:match("item:(%d+)"))
        end
    end

    -- 4. Try Recipe Item Link extraction
    if not bestID then
        local link = C_TradeSkillUI.GetRecipeItemLink(recipeID)
        if link then
            bestID = tonumber(link:match("item:(%d+)"))
        end
    end

    -- 5. SPECIFIC HACK FOR ENCHANTMENTS (If still nil)
    -- Some enchantments return an 'enchant:' link but have a corresponding scroll item.
    if not bestID then
        local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
        -- If it's an enchantment, sometimes we can find the scroll by name or through the schematic's outputItemData
        if recipeInfo and recipeInfo.isEnchanting then
            -- Try to get the output item data (complex API)
            local outputData = C_TradeSkillUI.GetRecipeOutputItemData(recipeID)
            if outputData and outputData.itemID then
                bestID = outputData.itemID
            end
        end
    end


    return bestID
end

function MCC.GetCraftCapacity(metier)
    local current = MCC.GetEstimatedConcentration(metier)
    local cost = metier.concentrationCost or 0
    if cost <= 0 then return nil end

    return math.floor(current / cost)
end

function MCC.GetSessionEconomics(multiplier)
    multiplier = multiplier or (MCC_Config and MCC_Config.shoppingMargin) or 1.0

    -- 1. Calculate Aggregate Demand (Sum of all character requirements)
    local aggregateDemand = {}
    local totalRequiredCost = 0

    for playerName, pdata in pairs(MCC_Config) do
        if type(pdata) == "table" and pdata.isCharacter then
            for _, metier in ipairs(pdata.metiers or {}) do
                if metier.currentCraft and metier.craftRecipe then
                    local craftQty = tonumber(metier.craftQuantity) or 1
                    for _, slot in ipairs(metier.craftRecipe) do
                        if slot.selectedItemID then
                            local qtyPerCraft = slot.quantity or 0
                            local totalQtyNeeded = math.ceil(qtyPerCraft * craftQty * multiplier)
                            local unitPrice = MCC.GetItemPrice(slot.selectedItemID)

                            local key = slot.selectedItemID .. "-" .. (slot.selectedRank or 0)
                            if not aggregateDemand[key] then
                                aggregateDemand[key] = { itemID = slot.selectedItemID, quantity = 0, price = unitPrice }
                            end
                            aggregateDemand[key].quantity = aggregateDemand[key].quantity + totalQtyNeeded
                            totalRequiredCost = totalRequiredCost + (totalQtyNeeded * unitPrice)
                        end
                    end
                end
            end
        end
    end

    -- 2. Calculate Deficit Cost based on Aggregate Supply
    local deficitCost = 0
    for key, data in pairs(aggregateDemand) do
        local itemID = data.itemID
        local owned = 0
        for pName, pObj in pairs(MCC_Config) do
            if type(pObj) == "table" and pObj.isCharacter then
                if pObj.inventory and pObj.inventory[itemID] then
                    owned = owned + pObj.inventory[itemID]
                end
                if pObj.bank and pObj.bank[itemID] then
                    owned = owned + pObj.bank[itemID]
                end
            end
        end
        if MCC_Config.Warbank and MCC_Config.Warbank[itemID] then
            owned = owned + MCC_Config.Warbank[itemID]
        end

        local deficit = math.max(0, data.quantity - owned)
        deficitCost = deficitCost + (deficit * data.price)
    end

    return deficitCost, totalRequiredCost
end

function MCC.GetCraftReagentsCost(metier)
    if not metier or not metier.craftRecipe then return 0 end
    local totalCost = 0
    for _, slot in ipairs(metier.craftRecipe) do
        if slot.selectedItemID then
            local qty = slot.quantity or 0
            local unitPrice = MCC.GetItemPrice(slot.selectedItemID)
            totalCost = totalCost + (qty * unitPrice)
        end
    end
    return totalCost
end

function MCC.GetSessionProfit(multiplier)
    local totalRevenue = 0
    local deficitCost, totalRequiredCost = MCC.GetSessionEconomics(multiplier)

    for playerName, pdata in pairs(MCC_Config) do
        if type(pdata) == "table" then
            for _, metier in ipairs(pdata.metiers or {}) do
                if metier.currentCraft then
                    local craftQty = (tonumber(metier.craftQuantity) or 1) * (multiplier or 1)
                    local outputQty = metier.outputQty or 1
                    local bestItemID = metier.outputItemID

                    -- Try to find the highest rank item for the recipe
                    if metier.activeRecipeID and C_TradeSkillUI.GetRecipeQualityItemIDs then
                        local qualityItemIDs = C_TradeSkillUI.GetRecipeQualityItemIDs(metier.activeRecipeID)
                        if qualityItemIDs and #qualityItemIDs > 0 then
                            bestItemID = qualityItemIDs[#qualityItemIDs]
                        end
                    end

                    if bestItemID then
                        local price = MCC.GetItemPrice(bestItemID)
                        totalRevenue = totalRevenue + (price * craftQty * outputQty)
                    end
                end
            end
        end
    end

    local profit = totalRevenue - totalRequiredCost
    return profit, totalRevenue, deficitCost, totalRequiredCost
end

function MCC.RefreshConcentrationCost(playerName, metierIndex)
    local pdata = MCC_Config[playerName]
    local metier = pdata and pdata.metiers and pdata.metiers[metierIndex]
    if not metier or not metier.activeRecipeID or not metier.craftRecipe then return end

    -- Backward compatibility: recover dataSlotIndex if missing
    local needsSchematic = false
    for _, slot in pairs(metier.craftRecipe) do
        if not slot.dataSlotIndex then
            needsSchematic = true
            break
        end
    end

    if needsSchematic then
        local schematic = C_TradeSkillUI.GetRecipeSchematic(metier.activeRecipeID, false)
        if schematic and schematic.reagentSlotSchematics then
            for slotIndex, slot in ipairs(schematic.reagentSlotSchematics) do
                if metier.craftRecipe[slotIndex] then
                    metier.craftRecipe[slotIndex].dataSlotIndex = slot.dataSlotIndex
                end
            end
        end
    end

    local reagents = {}
    for _, slot in pairs(metier.craftRecipe) do
        if slot.selectedItemID and slot.dataSlotIndex then
            table.insert(reagents, {
                reagent = { itemID = slot.selectedItemID },
                dataSlotIndex = slot.dataSlotIndex,
                quantity = slot.quantity
            })
        end
    end

    -- SAFE API CALL
    -- Some testing shows that applyConcentration=false might return the cost more reliably in some contexts
    local success, opInfo = pcall(C_TradeSkillUI.GetCraftingOperationInfo, metier.activeRecipeID, reagents, nil, false)
    if not success or not opInfo or not opInfo.concentrationCost then
        success, opInfo = pcall(C_TradeSkillUI.GetCraftingOperationInfo, metier.activeRecipeID, reagents, nil, true)
    end

    if success and opInfo then
        metier.concentrationCost = opInfo.concentrationCost
        -- Update saved schematic too
        if metier.savedSchematics[metier.activeRecipeID] then
            metier.savedSchematics[metier.activeRecipeID].concentrationCost = opInfo.concentrationCost
        end
    else
        -- Fallback: try without reagents just to have a base cost if it fails with reagents
        local s2, op2 = pcall(C_TradeSkillUI.GetCraftingOperationInfo, metier.activeRecipeID, {}, nil, true)
        if s2 and op2 then
            metier.concentrationCost = op2.concentrationCost
        end
    end
end

function MCC.UpdateCostFromRealCraft(playerName, metierIndex, realCost)
    local pdata = MCC_Config[playerName]
    local metier = pdata and pdata.metiers and pdata.metiers[metierIndex]
    if not metier or not metier.activeRecipeID then return end

    if realCost and realCost > 0 then
        metier.concentrationCost = realCost
        -- Save it
        if metier.savedSchematics[metier.activeRecipeID] then
            metier.savedSchematics[metier.activeRecipeID].concentrationCost = realCost
        end

        -- NEW: User choice priority: Do NOT auto-fill quantity with capacity anymore
        -- local capacity = MCC.GetCraftCapacity(metier)
        -- if capacity and capacity > 0 then
        --     metier.craftQuantity = capacity
        --     if metier.savedSchematics[metier.activeRecipeID] then
        --         metier.savedSchematics[metier.activeRecipeID].craftQuantity = capacity
        --     end
        -- end

        MCC.Log("|cff00ff00MCC:|r Concentration updated (" .. realCost .. ")")
        if MCC.UpdateShoppingList then MCC.UpdateShoppingList() end
        if MCC.RenderMCCUI then MCC.RenderMCCUI() end
    end
end

function MCC.ToggleFavorite(recipeID, recipeName, metierIndex)
    local player = MCC.player
    local metier = MCC_Config[player] and MCC_Config[player].metiers and MCC_Config[player].metiers[metierIndex]
    if not metier then return end

    metier.favorites = metier.favorites or {}
    if metier.favorites[recipeID] then
        metier.favorites[recipeID] = nil
        MCC.Log((MCC.L["Removed from favorites:"] or "Removed from favorites:") .. " " .. recipeName)
    else
        metier.favorites[recipeID] = recipeName
        MCC.Log((MCC.L["Added to favorites:"] or "Added to favorites:") .. " " .. recipeName)
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
    end
end

-- Inventory Tracking
-- MCC_Config.Warbank initialization moved to core.lua (ADDON_LOADED)

function MCC.ScanBags()
    local player = MCC.player -- Consistently use full name with realm
    if not MCC_Config[player] then MCC_Config[player] = {} end
    MCC_Config[player].isCharacter = true
    MCC_Config[player].inventory = {}

    -- Bags 0 to 5 (Backpack + Bags + Reagent Bag)
    for bag = 0, 5 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                -- Use ItemID as definitive key. Rank is cosmetic/implicit in ID.
                MCC_Config[player].inventory[info.itemID] = (MCC_Config[player].inventory[info.itemID] or 0) +
                    info.stackCount
            end
        end
    end
    -- MCC.Log("Sacs personnages (0-5) scannés.")
    if MCC.UpdateShoppingList then
        MCC.UpdateShoppingList()
    end
end

function MCC.ScanPersonalBank()
    local player = MCC.player
    if not MCC_Config[player] then MCC_Config[player] = {} end
    MCC_Config[player].isCharacter = true
    -- Always reset to get a clean snapshot
    MCC_Config[player].personalBank = {}

    -- Personal bank bags ONLY: main bank slot (-1), reagent bank (-3), and physical bank bags (6-12)
    -- Warbank tabs start at 13+ and are handled separately by ScanWarbank()
    local bankBags = { -1, -3 }
    for bag = 6, 12 do
        -- Only add if it's a legit personal bank bag (not a warbank tab)
        local numSlots = C_Container.GetContainerNumSlots(bag)
        if numSlots > 0 and bag < (Enum.BagIndex.AccountBankTab_1 or 13) then
            table.insert(bankBags, bag)
        end
    end

    for _, bag in ipairs(bankBags) do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        if numSlots > 0 then
            for slot = 1, numSlots do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.itemID then
                    local itemID = info.itemID
                    MCC_Config[player].personalBank[itemID] = (MCC_Config[player].personalBank[itemID] or 0) +
                        info.stackCount
                end
            end
        end
    end

    if MCC.UpdateShoppingList then MCC.UpdateShoppingList() end
end

function MCC.ScanWarbank()
    -- ONLY scans Account-wide Warbank tabs (13+)
    -- Personal bank bags (6-12) are handled separately by ScanPersonalBank()
    local tempWarbank = {}

    local startBank = Enum.BagIndex.AccountBankTab_1 or 13
    local endBank = Enum.BagIndex.AccountBankTab_5 or 17

    local hasData = false
    for bag = startBank, endBank do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        if numSlots > 0 then
            hasData = true
            for slot = 1, numSlots do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.itemID then
                    tempWarbank[info.itemID] = (tempWarbank[info.itemID] or 0) + info.stackCount
                end
            end
        end
    end

    -- PROTECT PERSISTENCE: Only overwrite if we actually scanned something.
    -- If hasData is false, it usually means the bank is not open or data isn't cached yet.
    -- We don't want to wipe the global Warband data on every character login!
    if hasData then
        MCC_Config.Warbank = tempWarbank
    end

    if MCC.UpdateShoppingList then MCC.UpdateShoppingList() end
end
