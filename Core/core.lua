local addonName, MCC = ...

-- Expose MCC globally for /run commands and debugging
_G["MCC"] = MCC

-- Cache global functions for performance
local GetRealmName = GetRealmName
local UnitName = UnitName

-- Frame principal pour les events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("TRADE_SKILL_SHOW")
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
    -- MCC.Log(event) -- Optional debug log

    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            MCC.version = "0.4"
            MCC_Config = MCC_Config or {}
            MCC_Config.Warbank = MCC_Config.Warbank or {}

            -- CLEANUP: Delete stale entries without realm suffixes
            local currentName = UnitName("player")
            local currentRealm = GetRealmName():gsub(" ", "")
            local canonicalKey = currentName .. "-" .. currentRealm

            for key, data in pairs(MCC_Config) do
                if type(data) == "table" and data.metiers then
                    if not key:find("-") then
                        -- If a hyphenated version exists or it's the current player, delete the stale non-hyphenated one
                        if MCC_Config[key .. "-" .. currentRealm] or key == currentName then
                            MCC_Config[key] = nil
                        else
                            -- No hyphenated version exists yet, but it's a character entry.
                            -- We'll wait for the next scan to populate the proper key.
                            data.isCharacter = true
                        end
                    else
                        data.isCharacter = true
                    end
                end
            end

            local prof1, prof2 = GetProfessions()
            MCC.RegisterPlayerCraft(MCC.player, { prof1, prof2 })
            MCC.InitUI()

            -- LibDBIcon Integration
            local ldb = LibStub("LibDataBroker-1.1")
            local icon = LibStub("LibDBIcon-1.0")

            local MCC_LDB = ldb:NewDataObject("MyCraftCompanion", {
                type = "launcher",
                text = "MyCraftCompanion",
                icon = "Interface\\AddOns\\MyCraftCompanion\\Media\\Logo_Mcc.png",
                OnClick = function(self, button)
                    if button == "LeftButton" then
                        if IsShiftKeyDown() then
                            if MCC.ToggleProgressUI then MCC.ToggleProgressUI() end
                        else
                            MCC.ToggleUI()
                        end
                    end
                end,
                OnTooltipShow = function(tooltip)
                    tooltip:AddLine("MyCraftCompanion", 1, 0.85, 0) -- Gold Title
                    tooltip:AddLine(MCC.L["Left Click: Open/Close Interface"], 0.7, 0.7, 0.7)
                    tooltip:AddLine(
                        MCC.L["Shift + Left Click: Open Progress Window"] or "Shift + Left Click: Open Progress Window",
                        0.7,
                        0.7, 0.7)
                    tooltip:AddLine(MCC.L["Drag: Move Button"], 0.7, 0.7, 0.7)

                    -- Session economics
                    if MCC.GetSessionProfit then
                        local multiplier = (MCC_Config and MCC_Config.shoppingMargin) or 1.0
                        local profit, revenue, deficit, total = MCC.GetSessionProfit(multiplier)
                        if total and total > 0 then
                            tooltip:AddLine(" ")
                            tooltip:AddLine("|cffffcc00" .. (MCC.L["Shopping List"] or "Liste d'achats") .. "|r")
                            tooltip:AddDoubleLine(
                                "|cffff4444" .. (MCC.L["Purchases to Make"] or "Achats à effectuer") .. ":|r",
                                GetMoneyString(deficit, true),
                                1, 1, 1, 1, 1, 1
                            )
                            tooltip:AddDoubleLine(
                                "|cffaaaaaa" .. (MCC.L["Total Purchases"] or "Total des achats") .. ":|r",
                                GetMoneyString(total, true),
                                1, 1, 1, 1, 1, 1
                            )
                            if revenue > 0 then
                                tooltip:AddDoubleLine(
                                    "|cff88ff88" .. (MCC.L["Total Sales"] or "Total des ventes") .. ":|r",
                                    GetMoneyString(revenue, true),
                                    1, 1, 1, 1, 1, 1
                                )
                                local pr, pg = profit >= 0 and 0 or 1, profit >= 0 and 1 or 0.27
                                tooltip:AddDoubleLine(
                                    "|cffffd700Profit:|r",
                                    (profit >= 0 and "+" or "-") .. GetMoneyString(math.abs(profit), true),
                                    1, 1, 1, pr, pg, 0
                                )
                            end
                        end
                    end

                    -- CRAFTS GLOBAL section (Refined: Only current character)
                    local pdata = MCC_Config[MCC.player]
                    if pdata and pdata.metiers then
                        local activeCrafts = {}
                        for _, metier in ipairs(pdata.metiers) do
                            if metier.currentCraft and (tonumber(metier.craftQuantity) or 0) > 0 then
                                table.insert(activeCrafts, metier)
                            end
                        end

                        if #activeCrafts > 0 then
                            tooltip:AddLine(" ")
                            tooltip:AddLine("|cffffcc00" .. (MCC.L["FACTORY VIEW"] or "VUE FACTORY") .. "|r")

                            -- Class color the player name
                            local nameOnly = UnitName("player")
                            local _, class = UnitClass("player")
                            local displayPlayer = "|cff00ffcc" .. nameOnly .. "|r"
                            if class then
                                local color = (C_ClassColor and C_ClassColor.GetClassColor) and
                                    C_ClassColor.GetClassColor(class) or RAID_CLASS_COLORS[class]
                                if color then
                                    if color.WrapTextInColorCode then
                                        displayPlayer = color:WrapTextInColorCode(nameOnly)
                                    else
                                        displayPlayer = string.format("|cff%02x%02x%02x%s|r", color.r * 255,
                                            color.g * 255, color.b * 255, nameOnly)
                                    end
                                end
                            end

                            for _, metier in ipairs(activeCrafts) do
                                tooltip:AddDoubleLine(
                                    "  " .. displayPlayer,
                                    "|cffffffff" ..
                                    (metier.currentCraft or "Unknown") .. " x" .. (metier.craftQuantity or 1) .. "|r"
                                )
                            end
                        end

                        -- CONCENTRATION ALERTS
                        local concAlerts = MCC.GetCappingCharacters and MCC.GetCappingCharacters()
                        if concAlerts and #concAlerts > 0 then
                            tooltip:AddLine(" ")
                            tooltip:AddLine("|cff00ff00" ..
                                (MCC.L["PRÊT À CRAFTER (CAP MAX)"] or "PRÊT À CRAFTER (CAP MAX)") .. "|r")
                            for _, alert in ipairs(concAlerts) do
                                local colorStr = "|cffffffff"
                                if alert.class then
                                    local c = (C_ClassColor and C_ClassColor.GetClassColor) and
                                        C_ClassColor.GetClassColor(alert.class) or RAID_CLASS_COLORS[alert.class]
                                    if c then
                                        if c.WrapTextInColorCode then
                                            colorStr = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
                                        else
                                            colorStr = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
                                        end
                                    end
                                end
                                tooltip:AddDoubleLine(
                                    colorStr .. alert.player .. "|r",
                                    "|cffff4444" ..
                                    (alert.metier or "Unknown") ..
                                    " (" .. alert.concentration .. "/" .. alert.max .. ")|r"
                                )
                            end
                        end
                    end
                end,
            })

            MCC_Config.minimap = MCC_Config.minimap or { hide = false, minimapPos = 200 }
            icon:Register("MyCraftCompanion", MCC_LDB, MCC_Config.minimap)

            if MCC.RestoreUISettings then MCC.RestoreUISettings() end
            MCC.CheckVersion()

            -- Auto-launch check
            if MCC_Config[MCC.player] and MCC_Config[MCC.player].autoLaunch then
                C_Timer.After(2, function() -- Slight delay after login
                    if MCC.StartWork then MCC.StartWork() end
                end)
            end

            print("|c" .. (MCC.Styles and MCC.Styles.Colors.GoldChat or "ffffcc00") .. "MyCraftCompanion|r " ..
                MCC.version .. " (WoW 12.0.1) " .. (MCC.L["Loaded!"] or "loaded!"))
        end
    elseif event == "TRADE_SKILL_SHOW" then
        C_Timer.After(0, function()
            local prof1, prof2 = GetProfessions()
            MCC.RegisterPlayerCraft(MCC.player, { prof1, prof2 })
            MCC.UpdatePlayerConcentration()
            MCC.InitProfessionUI()
        end)
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        MCC.UpdatePlayerConcentration()
        if MCC.RenderMCCUI then MCC.RenderMCCUI() end
    end
end)

SLASH_MCC1 = "/mcc"
SlashCmdList["MCC"] = function()
    MCC.ToggleUI()
end
