local addonName, MCC = ...

-- Constants
MCC.COLUMN_WIDTH = 200
MCC.COLUMN_GAP = 0
MCC.COLUMN_START_Y = -15
MCC.ROW_HEIGHT = 20

-- Expose internal frames to MCC for other modules
function MCC.GetUIFrames()
    return {
        MainFrame = MCC.MainFrame,
        MultBox = MCC.MultBox,
        VendorBox = MCC.VendorBox,
        HScrollFrame = MCC.HScrollFrame,
        ShoppingScroll = MCC.ShoppingScroll,
        ShoppingContainer = MCC.ShoppingContainer,
        HSlider = MCC.HSlider,
        ConfigFrame = MCC.ConfigFrame,
        FactoryScroll = MCC.FactoryScroll,
        HeaderClip = MCC.HeaderClip,
        HeaderScrollingFrame = MCC.HeaderScrollingFrame
    }
end

function MCC.InitUI()
    if MCC.MainFrame then return end
    MCC.MainFrame = CreateFrame("Frame", "MCC_MainFrame", UIParent, "BackdropTemplate")
    local MCC_UI = MCC.MainFrame
    if not MCC_UI then return end

    MCC_UI:SetSize(
        (MCC_Config and MCC_Config.uiWidth) or 1200,
        (MCC_Config and MCC_Config.uiHeight) or 850
    )

    MCC_UI:SetPoint("CENTER")
    MCC_UI:SetFrameStrata("HIGH")
    MCC_UI:SetMovable(true)
    MCC_UI:SetResizable(true)

    if MCC_UI.SetResizeBounds then
        MCC_UI:SetResizeBounds(800, 500, 1600, 1200)
    else
        pcall(function()
            MCC_UI:SetMinResize(800, 500)
            MCC_UI:SetMaxResize(1600, 1200)
        end)
    end

    MCC_UI:EnableMouse(true)
    MCC_UI:RegisterForDrag("LeftButton")
    MCC_UI:SetScript("OnDragStart", MCC_UI.StartMoving)
    MCC_UI:SetScript("OnDragStop", MCC_UI.StopMovingOrSizing)
    MCC_UI:Hide()

    local close = CreateFrame("Button", nil, MCC_UI, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() MCC_UI:Hide() end)

    local resizeButton = CreateFrame("Button", nil, MCC_UI)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT", -2, 2)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeButton:SetScript("OnMouseDown", function()
        MCC_UI:StartSizing("BOTTOMRIGHT")
    end)
    resizeButton:SetScript("OnMouseUp", function(self)
        MCC_UI:StopMovingOrSizing()
        MCC_Config.uiWidth = MCC_UI:GetWidth()
        MCC_Config.uiHeight = MCC_UI:GetHeight()
    end)

    if MCC.Styles then
        MCC_UI:SetBackdrop(MCC.Styles.Backdrop)
        MCC_UI:SetBackdropColor(unpack(MCC.Styles.Colors.BgDark))
        MCC_UI:SetBackdropBorderColor(unpack(MCC.Styles.Colors.Gold))
    end

    local headerGroup = CreateFrame("Frame", nil, MCC_UI)
    headerGroup:SetHeight(64)
    headerGroup:SetPoint("TOP", 0, -5)

    local logo = headerGroup:CreateTexture(nil, "OVERLAY")
    logo:SetSize(64, 64)
    logo:SetPoint("LEFT", headerGroup, "LEFT")
    logo:SetTexture("Interface\\AddOns\\MyCraftCompanion\\Media\\Logo_Mcc.png")

    local title = headerGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetText("MyCraftCompanion")
    title:SetPoint("LEFT", logo, "RIGHT", 10, 0)
    if MCC.Styles then
        title:SetTextColor(unpack(MCC.Styles.Colors.Gold))
    end
    headerGroup:SetWidth(64 + 10 + title:GetStringWidth())

    local helpButton = CreateFrame("Button", nil, MCC_UI, "BackdropTemplate")
    helpButton:SetSize(60, 20)
    helpButton:SetPoint("TOPRIGHT", -15, -10)
    helpButton:SetFrameLevel(MCC_UI:GetFrameLevel() + 100)

    if MCC.Styles then
        helpButton:SetBackdrop(MCC.Styles.Backdrop)
        helpButton:SetBackdropColor(unpack(MCC.Styles.Colors.BgSubtle))
        helpButton:SetBackdropBorderColor(unpack(MCC.Styles.Colors.Gold))
    end

    local btnText = helpButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btnText:SetPoint("CENTER")
    btnText:SetText(MCC.L["Help"] or "Aide")
    if MCC.Styles then
        btnText:SetTextColor(unpack(MCC.Styles.Colors.Gold))
    end
    helpButton:SetScript("OnClick", function() MCC.ShowHelp() end)

    local configButton = CreateFrame("Button", nil, MCC_UI, "BackdropTemplate")
    configButton:SetSize(80, 20)
    configButton:SetPoint("RIGHT", helpButton, "LEFT", -10, 0)
    configButton:SetFrameLevel(MCC_UI:GetFrameLevel() + 100)

    if MCC.Styles then
        configButton:SetBackdrop(MCC.Styles.Backdrop)
        configButton:SetBackdropColor(unpack(MCC.Styles.Colors.BgSubtle))
        configButton:SetBackdropBorderColor(unpack(MCC.Styles.Colors.Gold))
    end

    local cfgText = configButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cfgText:SetPoint("CENTER")
    cfgText:SetText(MCC.L["Config"] or "Config")
    if MCC.Styles then
        cfgText:SetTextColor(unpack(MCC.Styles.Colors.Gold))
    end

    configButton:SetScript("OnClick", function()
        if MCC.ConfigFrame:IsShown() then
            MCC.ConfigFrame:Hide()
            MCC.FactoryScroll:Show()
            if MCC.ShoppingFrame then MCC.ShoppingFrame:Show() end
            cfgText:SetText(MCC.L["Config"] or "Config")
        else
            MCC.ConfigFrame:Show()
            MCC.FactoryScroll:Hide()
            if MCC.ShoppingFrame then MCC.ShoppingFrame:Show() end -- We'll hide it specifically
            cfgText:SetText(MCC.L["Back"] or "Retour")

            -- New logic: hide shopping list during config
            if MCC.ShoppingFrame then MCC.ShoppingFrame:Hide() end
        end
    end)

    local workButton = CreateFrame("Button", nil, MCC_UI, "BackdropTemplate")
    workButton:SetSize(120, 20)
    workButton:SetPoint("RIGHT", configButton, "LEFT", -10, 0)
    workButton:SetFrameLevel(MCC_UI:GetFrameLevel() + 100)

    if MCC.Styles then
        workButton:SetBackdrop(MCC.Styles.Backdrop)
        workButton:SetBackdropColor(unpack(MCC.Styles.Colors.BgSubtle))
        workButton:SetBackdropBorderColor(unpack(MCC.Styles.Colors.Gold))
    end

    local workText = workButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    workText:SetPoint("CENTER")
    if MCC.Styles then
        workText:SetTextColor(unpack(MCC.Styles.Colors.Gold))
    end

    function MCC.UpdateWorkButton()
        if MCC.isWorkActive then
            if MCC.workStep == "BUYER_COMPLETE" then
                workText:SetText(MCC.L["Jobs Done !"] or "Jobs Done !")
                workButton:SetBackdropColor(0.2, 0.8, 0.2, 0.8) -- Green when finished
            else
                workText:SetText(MCC.L["Work in progress"] or "Travail en cours")
                workButton:SetBackdropColor(0.8, 0.8, 0.2, 0.8) -- Yellow during work
            end
        else
            workText:SetText(MCC.L["Work, work !"] or "Work, work !")
            if MCC.Styles then
                workButton:SetBackdropColor(unpack(MCC.Styles.Colors.BgSubtle))
            end
        end
    end

    workButton:SetScript("OnClick", function()
        if MCC.isWorkActive then
            MCC.StopWork()
        else
            MCC.StartWork()
        end
    end)

    MCC.UpdateWorkButton()
    helpButton:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
        self:SetBackdropBorderColor(1, 1, 1, 1)
    end)
    helpButton:SetScript("OnLeave", function(self)
        if MCC.Styles then
            self:SetBackdropColor(unpack(MCC.Styles.Colors.BgSubtle))
            self:SetBackdropBorderColor(unpack(MCC.Styles.Colors.Gold))
        end
    end)

    _G["UISpecialFrames"] = _G["UISpecialFrames"] or {}
    table.insert(_G["UISpecialFrames"], "MCC_MainFrame")

    local scrollFrame = CreateFrame("ScrollFrame", "MCC_HScrollFrame", MCC_UI, "UIPanelScrollFrameTemplate")
    if not scrollFrame then return end
    scrollFrame:SetPoint("TOPLEFT", 10, -120)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 280)
    scrollFrame:EnableMouseWheel(true)
    MCC.HScrollFrame = scrollFrame
    MCC.FactoryScroll = scrollFrame

    MCC.HeaderClip = CreateFrame("Frame", nil, MCC_UI)
    MCC.HeaderClip:SetSize(MCC_UI:GetWidth() - 40, 80)
    MCC.HeaderClip:SetPoint("TOPLEFT", 10, -40)
    MCC.HeaderClip:SetClipsChildren(true)

    MCC.HeaderScrollingFrame = CreateFrame("Frame", nil, MCC.HeaderClip)
    MCC.HeaderScrollingFrame:SetSize(MCC.COLUMN_WIDTH * 5, 80)
    MCC.HeaderScrollingFrame:SetPoint("TOPLEFT", 0, 0)

    MCC.ConfigFrame = CreateFrame("Frame", nil, MCC_UI, "BackdropTemplate")
    MCC.ConfigFrame:SetPoint("TOPLEFT", 10, -80)
    MCC.ConfigFrame:SetPoint("BOTTOMRIGHT", -10, 280)
    MCC.ConfigFrame:Hide()

    if MCC.CreateSettingsUI then
        MCC.CreateSettingsUI(MCC.ConfigFrame)
    end

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(MCC.COLUMN_WIDTH * 5, 1000)
    scrollFrame:SetScrollChild(content)

    local hSlider = CreateFrame("Slider", nil, MCC_UI, "OptionsSliderTemplate")
    if not hSlider then return end
    hSlider:SetPoint("BOTTOMLEFT", 20, 260)
    hSlider:SetPoint("BOTTOMRIGHT", -30, 260)
    hSlider:SetMinMaxValues(0, 0)
    hSlider:SetValueStep(10)
    hSlider:SetObeyStepOnDrag(true)
    MCC.HSlider = hSlider

    hSlider:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetHorizontalScroll(value)
        MCC.HeaderScrollingFrame:SetPoint("TOPLEFT", -value, 0)
    end)

    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        if IsShiftKeyDown() and hSlider:IsShown() then
            local value = hSlider:GetValue() - delta * 40
            hSlider:SetValue(value)
        else
            local current = self:GetVerticalScroll()
            self:SetVerticalScroll(math.max(0, current - delta * 20))
        end
    end)

    local shoppingFrame = CreateFrame("Frame", "MCC_ShoppingListFrame", MCC_UI, "BackdropTemplate")
    if not shoppingFrame then return end
    shoppingFrame:SetHeight(250)
    shoppingFrame:SetPoint("BOTTOMLEFT", 10, 10)
    shoppingFrame:SetPoint("BOTTOMRIGHT", -10, 10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 275)

    if MCC.Styles then
        shoppingFrame:SetBackdrop(MCC.Styles.Backdrop)
        shoppingFrame:SetBackdropColor(unpack(MCC.Styles.Colors.BgSubtle))
        shoppingFrame:SetBackdropBorderColor(unpack(MCC.Styles.Colors.Gold))
    end

    MCC.ShoppingFrame = shoppingFrame
    MCC.InitShoppingUI(shoppingFrame) -- Delegate to ShoppingList.lua

    MCC_UI:SetScript("OnSizeChanged", function(self, width, height)
        if not MCC.HSlider then return end
        local contentFrame = MCC.HScrollFrame:GetScrollChild()
        local totalWidth = contentFrame:GetWidth()
        local frameWidth = MCC.HScrollFrame:GetWidth()

        if totalWidth > frameWidth then
            MCC.HSlider:SetMinMaxValues(0, totalWidth - frameWidth)
            MCC.HSlider:Show()
        else
            MCC.HSlider:Hide()
            MCC.HScrollFrame:SetHorizontalScroll(0)
        end
    end)
end

function MCC.RestoreUISettings()
    local frames = MCC.GetUIFrames()
    if MCC_Config and MCC_Config.uiWidth and MCC_Config.uiHeight then
        frames.MainFrame:SetSize(MCC_Config.uiWidth, MCC_Config.uiHeight)
    end
end

function MCC.ToggleUI()
    local frames = MCC.GetUIFrames()
    if frames.MainFrame:IsShown() then
        frames.MainFrame:Hide()
    else
        MCC.RenderMCCUI()
        frames.MainFrame:Show()
    end
end
