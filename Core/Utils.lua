local addonName, MCC = ...

MCC.LogsBuffer = {}

function MCC.DumpTable(t, indent)
    indent = indent or 0
    local buffer = ""
    for k, v in pairs(t) do
        local prefix = string.rep("  ", indent) .. tostring(k) .. " = "
        if type(v) == "table" then
            buffer = buffer .. prefix .. "{\n"
            buffer = buffer .. MCC.DumpTable(v, indent + 1)
            buffer = buffer .. string.rep("  ", indent) .. "}\n"
        else
            buffer = buffer .. prefix .. tostring(v) .. "\n"
        end
    end
    return buffer
end

function MCC.Log(msg)
    local timestamp = date("%H:%M:%S")
    local logMsg = ""
    if type(msg) == "table" then
        logMsg = "[" .. timestamp .. "] table:\n" .. MCC.DumpTable(msg)
    else
        logMsg = "[" .. timestamp .. "] " .. tostring(msg)
    end

    table.insert(MCC.LogsBuffer, logMsg)
    if #MCC.LogsBuffer > 200 then table.remove(MCC.LogsBuffer, 1) end

    -- Print to chat as well
    print("|cff33ff99MCC|r", logMsg)

    -- Update debug frame if visible
    if MCC.DebugFrame and MCC.DebugFrame:IsShown() then
        MCC.UpdateDebugFrame()
    end
end

function MCC.GetItemNameSafe(itemID)
    return C_Item.GetItemNameByID(itemID) or ("Item " .. itemID)
end

-- SIMPLE DEBUG FRAME
function MCC.ToggleDebugFrame()
    if not MCC.DebugFrame then
        local f = CreateFrame("Frame", "MCC_DebugFrame", UIParent, "BasicFrameTemplateWithInset")
        f:SetSize(500, 400)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f.TitleText:SetText("MCC Debug Console")

        local s = CreateFrame("ScrollFrame", "MCC_DebugScroll", f, "UIPanelScrollFrameTemplate")
        s:SetPoint("TOPLEFT", 10, -35)
        s:SetPoint("BOTTOMRIGHT", -30, 40)

        local edit = CreateFrame("EditBox", nil, s)
        edit:SetMultiLine(true)
        edit:SetMaxLetters(99999)
        edit:SetFontObject("ChatFontNormal")
        edit:SetWidth(450)
        edit:SetAutoFocus(false)
        edit:SetScript("OnEscapePressed", function() f:Hide() end)
        s:SetScrollChild(edit)

        local clear = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        clear:SetSize(80, 22)
        clear:SetPoint("BOTTOMLEFT", 10, 10)
        clear:SetText("Clear")
        clear:SetScript("OnClick", function()
            MCC.LogsBuffer = {}
            MCC.UpdateDebugFrame()
        end)

        local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetSize(80, 22)
        close:SetPoint("BOTTOMRIGHT", -10, 10)
        close:SetText("Close")
        close:SetScript("OnClick", function() f:Hide() end)

        f.scroll = s
        f.edit = edit
        MCC.DebugFrame = f
    end

    if MCC.DebugFrame:IsShown() then
        MCC.DebugFrame:Hide()
    else
        MCC.DebugFrame:Show()
        MCC.UpdateDebugFrame()
    end
end

function MCC.UpdateDebugFrame()
    if MCC.DebugFrame and MCC.DebugFrame.edit then
        local text = table.concat(MCC.LogsBuffer, "\n")
        MCC.DebugFrame.edit:SetText(text)
        C_Timer.After(0.1, function()
            MCC_DebugScroll:SetVerticalScroll(MCC_DebugScroll:GetVerticalScrollRange())
        end)
    end
end

SLASH_MCCDEBUG1 = "/mccdebug"
SLASH_MCCDEBUG2 = "/mcc"
SlashCmdList["MCCDEBUG"] = function(msg)
    if msg == "debug" or msg == "" then
        MCC.ToggleDebugFrame()
    end
end
