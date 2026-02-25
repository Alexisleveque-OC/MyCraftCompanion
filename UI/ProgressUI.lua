local addonName, MCC = ...

local CreateFrame = CreateFrame
local UIParent = UIParent
local Minimap = Minimap
local unpack = unpack
local table = table
local _G = _G

local progressFrame = nil

function MCC.CreateProgressUI()
    if progressFrame then return end

    progressFrame = CreateFrame("Frame", "MCC_ProgressFrame", UIParent, "BackdropTemplate")
    local f = progressFrame
    f:SetSize(250, 220)
    -- Anchor near Minimap (TopRight of screen, offset to the left of the minimap area)
    f:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -20, -50)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    if MCC.Styles then
        f:SetBackdrop(MCC.Styles.Backdrop)
        f:SetBackdropColor(unpack(MCC.Styles.Colors.BgDark))
        f:SetBackdropBorderColor(unpack(MCC.Styles.Colors.Gold))
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText(MCC.L["Work Progress"] or "Work Progress")
    if MCC.Styles then title:SetTextColor(unpack(MCC.Styles.Colors.Gold)) end
    f.title = title

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() f:Hide() end)

    local stepLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stepLabel:SetPoint("TOPLEFT", 20, -50)
    stepLabel:SetText(MCC.L["Step:"] or "Step:")

    local stepValue = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    stepValue:SetPoint("LEFT", stepLabel, "RIGHT", 10, 0)
    f.stepLabel = stepLabel
    f.stepValue = stepValue

    local statusLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusLabel:SetPoint("TOPLEFT", 20, -80)
    statusLabel:SetText(MCC.L["Status:"] or "Status:")
    f.statusLabel = statusLabel

    local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", 20, -100)
    statusText:SetWidth(210)
    statusText:SetJustifyH("LEFT")
    statusText:SetJustifyV("TOP")
    -- Height is dynamic or large enough for the frame
    statusText:SetHeight(100)
    f.statusText = statusText

    -- GIANT Finish Text
    local finishText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    finishText:SetPoint("CENTER", 0, 10)
    finishText:SetScale(2.2)         -- Adjusted scale to fit the window (250x220)
    finishText:SetJustifyH("CENTER") -- Center multi-line text
    finishText:SetText(MCC.L["Jobs Done !"] or "Jobs Done !")
    if MCC.Styles then finishText:SetTextColor(unpack(MCC.Styles.Colors.Gold)) end
    finishText:Hide()
    f.finishText = finishText

    -- Button container or just positioning
    local backBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    backBtn:SetSize(100, 22)
    backBtn:SetPoint("BOTTOMLEFT", 20, 15)
    backBtn:SetText(MCC.L["Previous Step"] or "Précédent")
    backBtn:SetScript("OnClick", function()
        if MCC.PreviousWorkStep then
            MCC.PreviousWorkStep()
        end
    end)
    f.backBtn = backBtn

    local validateBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    validateBtn:SetSize(100, 22)
    validateBtn:SetPoint("BOTTOMRIGHT", -20, 15)
    validateBtn:SetText(MCC.L["Next Step"] or "Suivant")
    validateBtn:SetScript("OnClick", function()
        if MCC.ValidateWorkStep then
            MCC.ValidateWorkStep()
        end
    end)
    f.validateBtn = validateBtn

    local exportBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    exportBtn:SetSize(120, 22)
    exportBtn:SetPoint("BOTTOM", 0, 45) -- Centered above the other buttons
    exportBtn:SetText(MCC.L["Export Auctionator"] or "Export Auctionator")
    exportBtn:SetScript("OnClick", function()
        if MCC.ShowExportPopup then
            MCC.ShowExportPopup()
        end
    end)
    f.exportBtn = exportBtn

    local depositBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    depositBtn:SetSize(140, 22)
    depositBtn:SetPoint("BOTTOM", 0, 45) -- Same position as export, they never show at the same time
    depositBtn:SetText(MCC.L["Deposit Warbound"] or "Dépôt Bataillon")
    depositBtn:SetScript("OnClick", function()
        if MCC.DepositAllWarboundItems then
            MCC.DepositAllWarboundItems()
        end
    end)
    f.depositBtn = depositBtn

    local mailBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    mailBtn:SetSize(140, 22)
    mailBtn:SetPoint("BOTTOM", 0, 45) -- Same position
    mailBtn:SetText(MCC.L["Send Crafts"] or "Envoyer Crafts")
    mailBtn:SetScript("OnClick", function()
        if MCC.ProcessMail then
            MCC.ProcessMail()
        end
    end)
    f.mailBtn = mailBtn

    f:Hide()

    -- Removed from UISpecialFrames as per user request (no ESC to close)
    -- _G["UISpecialFrames"] = _G["UISpecialFrames"] or {}
    -- table.insert(_G["UISpecialFrames"], "MCC_ProgressFrame")
end

local stepMap = {
    ["INITIALIZING"] = MCC.L["Initializing..."] or "Démarrage du workflow...",
    ["BUYER_AH_SCAN"] = MCC.L["AH Analysis..."] or "Analyse du marché...",
    ["BUYER_READY"] = MCC.L["Ready to Buy"] or "Prêt pour vos achats",
    ["BUYER_GOLD_CHECK"] = MCC.L["Gold Check"] or "Retrait PO si nécessaire...",
    ["BUYER_WARBANK_SYNC"] = MCC.L["Warbank Sync Check"] or "Vérification synchro Warbank...",
    ["BUYER_WARBANK_DEPOSIT"] = MCC.L["Warbank Deposit"] or "Dépôt en banque de bataillon...",
    ["BUYER_REAGENT_CHECK"] = MCC.L["Reagent Check"] or "Vérification des composants...",
    ["BUYER_CRAFTING"] = MCC.L["Crafting Session"] or "Session de craft en cours...",
    ["BUYER_MAIL_TO_SELLER"] = MCC.L["Mailing to Seller"] or "Envoi des produits au vendeur...",
    ["BUYER_COMPLETE"] = MCC.L["Workflow Complete"] or "Workflow terminé !",
    ["SELLER_POST_AUCTIONS"] = MCC.L["Selling Items..."] or "Mise en vente des objets...",
    ["CRAFTER_REAGENT_CHECK"] = MCC.L["Checking Reagents..."] or "Vérification des composants...",
    ["EXCLUDED"] = MCC.L["Excluded"] or "Exclu du workflow",
}

function MCC.UpdateProgressUI()
    if not progressFrame then return end

    local step = MCC.workStep or "IDLE"
    progressFrame.stepValue:SetText(stepMap[step] or step)
    progressFrame.statusText:SetText(MCC.workStatusText or "")

    -- Show/Hide buttons based on work state
    if MCC.isWorkActive and step ~= "IDLE" and step ~= "EXCLUDED" then
        -- FINISH & START Special Logic
        if step == "BUYER_COMPLETE" or step == "INITIALIZING" then
            progressFrame.finishText:Show()
            progressFrame.finishText:SetText(step == "INITIALIZING" and MCC.L["Work, work !"]
                or MCC.L["Jobs Done !"])
            progressFrame.title:Hide()
            progressFrame.stepLabel:Hide()
            progressFrame.stepValue:Hide()
            progressFrame.statusLabel:Hide()
            progressFrame.statusText:Hide()
            progressFrame.validateBtn:Hide()
            if step == "INITIALIZING" then
                progressFrame.validateBtn:Show()
                progressFrame.validateBtn:SetText(MCC.L["Next Step"] or "Suivant")
            end
            progressFrame.backBtn:Hide()     -- Hide back during start too
            if step == "BUYER_COMPLETE" then
                progressFrame.backBtn:Show() -- Keep back allowed for finish
            end
            progressFrame.exportBtn:Hide()
            progressFrame.depositBtn:Hide()
            progressFrame.mailBtn:Hide()
            return -- Exit early for clean state
        else
            progressFrame.finishText:Hide()
            progressFrame.title:Show()
            progressFrame.stepLabel:Show()
            progressFrame.stepValue:Show()
            progressFrame.statusLabel:Show()
            progressFrame.statusText:Show()
        end

        -- Hide Back if at the very first steps
        if step == "INITIALIZING" or step == "BUYER_AH_SCAN" or step == "SELLER_POST_AUCTIONS" or step == "CRAFTER_REAGENT_CHECK" then
            progressFrame.backBtn:Hide()
        else
            progressFrame.backBtn:Show()
        end

        local isReadyToBuy = (step == "BUYER_READY")
        if isReadyToBuy then
            progressFrame.exportBtn:Show()
        else
            progressFrame.exportBtn:Hide()
        end

        local isDeposit = (step == "BUYER_WARBANK_DEPOSIT")
        if isDeposit then
            progressFrame.depositBtn:Show()
        else
            progressFrame.depositBtn:Hide()
        end

        local isMail = (step == "BUYER_MAIL_TO_SELLER")
        if isMail then
            progressFrame.mailBtn:Show()
        else
            progressFrame.mailBtn:Hide()
        end

        -- Hide Next if at the very last steps (BUYER_COMPLETE handled above, but safety)
        if step == "BUYER_COMPLETE" then
            progressFrame.validateBtn:Hide()
        else
            progressFrame.validateBtn:Show()
        end
    else
        progressFrame.finishText:Hide()
        progressFrame.title:Show()
        progressFrame.stepLabel:Show()
        progressFrame.stepValue:Show()
        progressFrame.statusLabel:Show()
        progressFrame.statusText:Show()
        progressFrame.validateBtn:Hide()
        progressFrame.backBtn:Hide()
        progressFrame.exportBtn:Hide()
        progressFrame.depositBtn:Hide()
        progressFrame.mailBtn:Hide()
    end
end

function MCC.ToggleProgressUI()
    if not progressFrame then
        MCC.CreateProgressUI()
    end

    if progressFrame and progressFrame:IsShown() then
        progressFrame:Hide()
    elseif progressFrame then
        MCC.UpdateProgressUI()
        progressFrame:Show()
    end
end
