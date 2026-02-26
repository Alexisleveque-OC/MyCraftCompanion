local addonName, MCC = ...

local MCC_UpdateNotesFrame, MCC_HelpFrame

-- Global Styles (Initialized early for other files)
MCC.Styles = {
    Colors = {
        Gold = { 1, 0.85, 0 }, -- Renamed from Green
        GoldChat = "ffffcc00", -- WoW Yellow
        BgSubtle = { 0.1, 0.1, 0.1, 0.8 },
        BgDark = { 0, 0, 0, 0.95 },
        TextGold = { 1, 0.82, 0 },
        Separator = { 1, 1, 1, 0.1 }
    },
    Backdrop = {
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    }
}

MCC.UpdateNotes = {
    ["0.2"] = {
        "Note_02_1",
        "Note_02_2",
        "Note_02_3",
        "Note_02_4",
    },
    ["0.3"] = {
        "Note_03_1",
        "Note_03_2",
        "Note_03_3",
    },
    ["0.4"] = {
        "Note_04_1",
        "Note_04_2",
        "Note_04_3",
        "Note_04_4",
    },
    ["0.4.1"] = {
        "Note_041_1",
        "Note_041_2",
    }
}

function MCC.CheckVersion()
    MCC_Config = MCC_Config or {}
    MCC_Config.lastVersion = MCC_Config.lastVersion or "0.1"

    if MCC_Config.lastVersion ~= MCC.version then
        local notes = MCC.UpdateNotes[MCC.version]
        if notes then
            -- Delay appearance to ensure UIParent is ready
            C_Timer.After(1, function()
                MCC.ShowUpdateNotes(MCC.version, notes)
            end)
        end
        MCC_Config.lastVersion = MCC.version
    end
end

function MCC.ShowUpdateNotes(version, notes)
    -- Suppression de l'ancienne frame si elle existe
    if MCC_UpdateNotesFrame then
        MCC_UpdateNotesFrame:Hide()
    end

    -- Creation d'une frame simple avec Backdrop
    local f = CreateFrame("Frame", "MCC_UpdateNotesFrame", UIParent, "BackdropTemplate")
    f:SetSize(450, 400)
    f:SetPoint("CENTER", 0, 100)
    f:SetFrameStrata("TOOLTIP") -- Top absolute level
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop(MCC.Styles.Backdrop)
    f:SetBackdropColor(unpack(MCC.Styles.Colors.BgDark))
    f:SetBackdropBorderColor(unpack(MCC.Styles.Colors.Gold))

    -- Standard Close Button (The "X")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Header / Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("MyCraftCompanion - v" .. version)
    title:SetTextColor(unpack(MCC.Styles.Colors.Gold))

    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(unpack(MCC.Styles.Colors.Separator))
    sep:SetSize(400, 1)
    sep:SetPoint("TOP", title, "BOTTOM", 0, -10)

    -- ScrollFrame
    local scroll = CreateFrame("ScrollFrame", "MCC_UpdateNotesScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 15, -60)
    scroll:SetPoint("BOTTOMRIGHT", -35, 50)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(380, 1)
    scroll:SetScrollChild(content)

    -- Fill Notes
    local y = -5
    for _, noteKey in ipairs(notes) do
        local noteText = MCC.L[noteKey] or noteKey
        local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 5, y)
        text:SetWidth(370)
        text:SetJustifyH("LEFT")
        text:SetText("- " .. noteText)
        -- Back to white/highlight for body text
        text:SetTextColor(1, 1, 1)

        local h = text:GetStringHeight()
        if h == 0 then h = 20 end
        y = y - (h + 8)
    end
    content:SetHeight(math.abs(y) + 20)

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetSize(120, 25)
    closeBtn:SetPoint("BOTTOM", 0, 15)
    closeBtn:SetText(MCC.L["Close"] or "Fermer")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    _G["UISpecialFrames"] = _G["UISpecialFrames"] or {}
    table.insert(_G["UISpecialFrames"], "MCC_UpdateNotesFrame")

    f:Show()
end

-------------------------------------------------------
-- Help / Tutorial UI
-------------------------------------------------------

function MCC.ShowHelp()
    if MCC_HelpFrame and MCC_HelpFrame:IsShown() then
        MCC_HelpFrame:Hide()
        return
    end

    if MCC_HelpFrame then
        MCC_HelpFrame:Show()
        return
    end

    MCC_HelpFrame = CreateFrame("Frame", "MCC_HelpFrame", UIParent, "BackdropTemplate")
    local f = MCC_HelpFrame
    f:SetSize(600, 500)
    f:SetPoint("CENTER")
    f:SetFrameStrata("TOOLTIP") -- Higher than main UI
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop(MCC.Styles.Backdrop)
    f:SetBackdropColor(unpack(MCC.Styles.Colors.BgDark))
    f:SetBackdropBorderColor(unpack(MCC.Styles.Colors.Gold))

    -- Standard Close Button (The "X")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Header
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("MyCraftCompanion - " .. (MCC.L["Help"] or "Aide"))
    title:SetTextColor(unpack(MCC.Styles.Colors.Gold))

    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(unpack(MCC.Styles.Colors.Separator))
    sep:SetSize(550, 1)
    sep:SetPoint("TOP", title, "BOTTOM", 0, -10)

    -- ScrollArea for tutorial
    local scroll = CreateFrame("ScrollFrame", "MCC_HelpScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 15, -60)
    scroll:SetPoint("BOTTOMRIGHT", -35, 50)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(530, 800)
    scroll:SetScrollChild(content)

    local helpText = {
        { title = MCC.L["Help_1_Title"],       text = MCC.L["Help_1_Text"] },
        { title = MCC.L["Help_2_Title"],       text = MCC.L["Help_2_Text"] },
        { title = MCC.L["Help_3_Title"],       text = MCC.L["Help_3_Text"] },
        { title = MCC.L["Help_4_Title"],       text = MCC.L["Help_4_Text"] },
        { title = MCC.L["Work, work !"],       text = "|cffff4444" .. MCC.L["Help: Important!"] .. "|r\n" .. MCC.L["Make sure to define your Buyer and Seller characters in the settings tab for the workflow to operate correctly."] },
        { title = MCC.L["Help_Minimap_Title"], text = MCC.L["Help_Minimap_Text"] },
    }

    local y = -10
    for _, item in ipairs(helpText) do
        local hTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        hTitle:SetPoint("TOPLEFT", 10, y)
        hTitle:SetText(item.title)
        hTitle:SetTextColor(unpack(MCC.Styles.Colors.Gold))
        y = y - 25

        local hText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        hText:SetPoint("TOPLEFT", 20, y)
        hText:SetWidth(490)
        hText:SetJustifyH("LEFT")
        hText:SetText(item.text)
        hText:SetTextColor(0.9, 0.9, 0.9) -- Clean light grey/white for body
        y = y - (hText:GetStringHeight() + 20)
    end
    content:SetHeight(math.abs(y) + 20)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetSize(120, 25)
    closeBtn:SetPoint("BOTTOM", 0, 15)
    closeBtn:SetText(MCC.L["Close"] or "Fermer")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    _G["UISpecialFrames"] = _G["UISpecialFrames"] or {}
    table.insert(_G["UISpecialFrames"], "MCC_HelpFrame")
    f:Show()
end
