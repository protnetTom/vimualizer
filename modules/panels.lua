local panels = {}

local canvas = require("hs.canvas")
local styledtext = require("hs.styledtext")
local application = require("hs.application")
local window = require("hs.window")

local constants = require("modules.constants")
local config = require("modules.config")

panels.sortedExclusions = {}

function panels.getCurrentAppInfo()
    local win = window.focusedWindow()
    if not win then return "Unknown", "Unknown" end
    local app = win:application()
    if not app then return "Unknown", "Unknown" end
    return app:name(), app:bundleID()
end

function panels.initPrefs()
    -- Safeguard: Ensure all sequential indices are initialized
    for i=1,100 do _G.prefPanel[i] = { type="rectangle", action="skip", frame={x=0,y=0,w=0,h=0} } end

    _G.prefPanel[1] = { type="rectangle", action="fill", fillColor=constants.panelColor, roundedRectRadii={xRadius=16, yRadius=16}, strokeColor=constants.hudStrokeColor, strokeWidth=1, shadow=constants.shadowSpec }
    _G.prefPanel[2] = { type="text", text="Vimualizer Config", textColor=constants.colorTitle, textSize=24, textAlignment="center", frame={x="0%",y="2%",w="100%",h="5%"} }

    -- SECTION: FEATURES (Index 3)
    _G.prefPanel[3] = { type="text", text="FEATURES", textColor=constants.colorHeader, textSize=12, textAlignment="center", frame={x="10%",y="8%",w="80%",h="3%"} }

    for i=0,8 do
        local yPos = 12 + (i * 5.0)
        _G.prefPanel[4 + (i*2)] = { type="rectangle", action="fill", frame={x="10%",y=yPos.."%",w="80%",h="4%"} }
        _G.prefPanel[5 + (i*2)] = { type="text", textAlignment="center", frame={x="10%",y=(yPos+1.2).."%",w="80%",h="4%"} }
    end

    -- SECTION: APPEARANCE (Index 22)
    local appY = 57
    _G.prefPanel[22] = { type="text", text="APPEARANCE", textColor=constants.colorHeader, textSize=12, textAlignment="center", frame={x="10%",y=appY.."%",w="80%",h="3%"} }

    -- Position & Alignment (Indices 23-26)
    local subY = 61
    _G.prefPanel[23] = { type="rectangle", action="fill", frame={x="10%",y=subY.."%",w="38%",h="4%"} }
    _G.prefPanel[24] = { type="text", textAlignment="center", frame={x="10%",y=(subY+1.2).."%",w="38%",h="4%"} }
    _G.prefPanel[25] = { type="rectangle", action="fill", frame={x="52%",y=subY.."%",w="38%",h="4%"} }
    _G.prefPanel[26] = { type="text", textAlignment="center", frame={x="52%",y=(subY+1.2).."%",w="38%",h="4%"} }

    -- Title Size (Indices 27-31)
    local sizeY1 = 66.5
    _G.prefPanel[27] = { type="rectangle", action="fill", frame={x="10%",y=sizeY1.."%",w="15%",h="4%"} }
    _G.prefPanel[28] = { type="text", text="-", textColor={white=1}, textSize=20, textAlignment="center", frame={x="10%",y=(sizeY1+0.6).."%",w="15%",h="4%"} }
    _G.prefPanel[29] = { type="rectangle", action="fill", frame={x="75%",y=sizeY1.."%",w="15%",h="4%"} }
    _G.prefPanel[30] = { type="text", text="+", textColor={white=1}, textSize=20, textAlignment="center", frame={x="75%",y=(sizeY1+0.6).."%",w="15%",h="4%"} }
    _G.prefPanel[31] = { type="text", text="Title Size", textColor={white=1}, textSize=15, textAlignment="center", frame={x="25%",y=(sizeY1+0.9).."%",w="50%",h="4%"} }

    -- Text Size (Indices 32-36)
    local sizeY2 = 72
    _G.prefPanel[32] = { type="rectangle", action="fill", frame={x="10%",y=sizeY2.."%",w="15%",h="4%"} }
    _G.prefPanel[33] = { type="text", text="-", textColor={white=1}, textSize=20, textAlignment="center", frame={x="10%",y=(sizeY2+0.6).."%",w="15%",h="4%"} }
    _G.prefPanel[34] = { type="rectangle", action="fill", frame={x="75%",y=sizeY2.."%",w="15%",h="4%"} }
    _G.prefPanel[35] = { type="text", text="+", textColor={white=1}, textSize=20, textAlignment="center", frame={x="75%",y=(sizeY2+0.6).."%",w="15%",h="4%"} }
    _G.prefPanel[36] = { type="text", text="Text Size", textColor={white=1}, textSize=15, textAlignment="center", frame={x="25%",y=(sizeY2+0.9).."%",w="50%",h="4%"} }

    -- SMART FEATURES (Indices 37-38)
    local smartY = 77.5
    _G.prefPanel[37] = { type="rectangle", action="fill", frame={x="10%",y=smartY.."%",w="80%",h="4%"} }
    _G.prefPanel[38] = { type="text", textAlignment="center", frame={x="10%",y=(smartY+1.2).."%",w="80%",h="4%"} }

    -- FONTS (Indices 39-42)
    local fontY = 83
    _G.prefPanel[39] = { type="rectangle", action="fill", frame={x="10%",y=fontY.."%",w="38%",h="4%"} }
    _G.prefPanel[40] = { type="text", textAlignment="center", frame={x="10%",y=(fontY+1.2).."%",w="38%",h="4%"} }
    _G.prefPanel[41] = { type="rectangle", action="fill", frame={x="52%",y=fontY.."%",w="38%",h="4%"} }
    _G.prefPanel[42] = { type="text", textAlignment="center", frame={x="52%",y=(fontY+1.2).."%",w="38%",h="4%"} }

    -- EXCLUSIONS (Index 43)
    local excY = 88.5
    _G.prefPanel[43] = { type="text", text="EXCLUSIONS", textColor=constants.colorHeader, textSize=12, textAlignment="center", frame={x="10%",y=excY.."%",w="80%",h="3%"} }

    -- App Row (Indices 44-47)
    local appRowY = 92
    _G.prefPanel[44] = { type="rectangle", action="fill", frame={x="10%",y=appRowY.."%",w="55%",h="3%"} }
    _G.prefPanel[45] = { type="text", text="App Name", textColor={white=1}, textSize=11, textAlignment="center", frame={x="10%",y=(appRowY+0.3).."%",w="55%",h="3%"} }
    _G.prefPanel[46] = { type="rectangle", action="fill", frame={x="67%",y=appRowY.."%",w="23%",h="3%"} }
    _G.prefPanel[47] = { type="text", text="Toggle", textColor={white=1}, textSize=11, textAlignment="center", frame={x="67%",y=(appRowY+0.3).."%",w="23%",h="3%"} }

    -- Footer (Indices 48-53)
    local footerY = 96
    _G.prefPanel[48] = { type="rectangle", action="fill", fillColor=constants.btnColorSave, frame={x="10%",y=footerY.."%",w="25%",h="2.2%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.prefPanel[49] = { type="text", text="Save", textColor={white=1}, textSize=14, textAlignment="center", frame={x="10%",y=(footerY+0.4).."%",w="25%",h="2.2%"} }
    
    _G.prefPanel[50] = { type="rectangle", action="fill", fillColor=constants.btnColorAction, frame={x="37.5%",y=footerY.."%",w="25%",h="2.2%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.prefPanel[51] = { type="text", text="Analytics", textColor={white=1}, textSize=14, textAlignment="center", frame={x="37.5%",y=(footerY+0.4).."%",w="25%",h="2.2%"} }

    _G.prefPanel[52] = { type="rectangle", action="fill", fillColor={hex="#5856D6"}, frame={x="65%",y=footerY.."%",w="25%",h="2.2%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.prefPanel[53] = { type="text", text="Exclusions", textColor={white=1}, textSize=14, textAlignment="center", frame={x="65%",y=(footerY+0.4).."%",w="25%",h="2.2%"} }
end

function panels.updatePrefsVisuals()
    local function styleBtn(idx, enabled, txt)
        _G.prefPanel[idx].fillColor = (enabled and constants.btnColorOn or constants.btnColorOff)
        _G.prefPanel[idx].roundedRectRadii = {xRadius=6, yRadius=6}
        _G.prefPanel[idx+1].text = styledtext.new(txt, {font={name=config.fontUIBold, size=15}, color={white=1}, paragraphStyle={alignment="center"}})
    end
    local function styleActionBtn(idx)
        _G.prefPanel[idx].fillColor = constants.btnColorAction
        _G.prefPanel[idx].roundedRectRadii = {xRadius=6, yRadius=6}
    end

    styleBtn(4, config.isMasterEnabled, "Enable Vimualizer: "..(config.isMasterEnabled and "ON" or "OFF"))
    styleBtn(6, config.isHudEnabled, "Show Key Hints: "..(config.isHudEnabled and "ON" or "OFF"))
    styleBtn(8, config.isBufferEnabled, "Show Keystrokes: "..(config.isBufferEnabled and "ON" or "OFF"))
    styleBtn(10, config.isActionInfoEnabled, "Explain Actions: "..(config.isActionInfoEnabled and "ON" or "OFF"))
    styleBtn(12, config.isEscapeMenuEnabled, "Show Help Menu: "..(config.isEscapeMenuEnabled and "ON" or "OFF"))
    styleBtn(14, config.isMacroEnabled, "Macro Recording: "..(config.isMacroEnabled and "ON" or "OFF"))
    styleBtn(16, config.isAerospaceEnabled, "Aerospace Mode: "..(config.isAerospaceEnabled and "ON" or "OFF"))
    styleBtn(18, config.isTooltipsEnabled, "Tooltips: "..(config.isTooltipsEnabled and "ON" or "OFF"))
    
    local trainer = require("modules.trainer")
    styleBtn(20, trainer.isActive, "Trainer Mode: "..(trainer.isActive and "ON" or "OFF"))

    -- APPEARANCE
    local posNames = {"Left", "TopRight", "BotRight", "Center", "Custom"}
    styleActionBtn(23)
    _G.prefPanel[24].text = styledtext.new("Position: "..posNames[config.hudPosIndex], {font={name=config.fontUIBold, size=14}, color={white=1}, paragraphStyle={alignment="center"}})

    local alignLabel = "Align: " .. (config.hudTextAlignment:gsub("^%l", string.upper))
    styleActionBtn(25)
    _G.prefPanel[26].text = styledtext.new(alignLabel, {font={name=config.fontUIBold, size=14}, color={white=1}, paragraphStyle={alignment="center"}})

    styleActionBtn(27); styleActionBtn(29)
    _G.prefPanel[31].text = "Title Size: " .. config.fontTitleSize

    styleActionBtn(32); styleActionBtn(34)
    _G.prefPanel[36].text = "Text Size: " .. config.fontBodySize

    styleBtn(37, config.isReactiveOpacityEnabled, "Ghost Mode: "..(config.isReactiveOpacityEnabled and "ON" or "OFF"))

    styleActionBtn(39)
    _G.prefPanel[40].text = styledtext.new("Main Font", {font={name=config.fontUIBold, size=11}, color={white=1}, paragraphStyle={alignment="center"}})
    styleActionBtn(41)
    _G.prefPanel[42].text = styledtext.new("Code Font", {font={name=config.fontUIBold, size=11}, color={white=1}, paragraphStyle={alignment="center"}})

    local appName, appID = panels.getCurrentAppInfo()
    local isExcluded = config.excludedApps[appID] == true
    _G.prefPanel[44].fillColor = {red=0.15, green=0.15, blue=0.15, alpha=1}
    _G.prefPanel[44].roundedRectRadii = {xRadius=6,yRadius=6}
    _G.prefPanel[45].text = styledtext.new("App: "..appName, {font={name=config.fontUI, size=11}, color={white=0.9}, paragraphStyle={alignment="center"}})
    _G.prefPanel[46].fillColor = isExcluded and constants.btnColorOff or constants.btnColorOn
    _G.prefPanel[46].roundedRectRadii = {xRadius=6,yRadius=6}
    _G.prefPanel[47].text = styledtext.new(isExcluded and "Include" or "Exclude", {font={name=config.fontUIBold, size=11}, color={white=1}, paragraphStyle={alignment="center"}})
end

function panels.updateStatsPanel()
    local stats = require("modules.stats")
    
    -- Thoroughly clear the canvas
    local currentLen = #_G.statsPanel
    for i = currentLen, 1, -1 do _G.statsPanel[i] = nil end

    -- Background & Title
    _G.statsPanel[1] = { type="rectangle", action="fill", fillColor=constants.panelColor, roundedRectRadii={xRadius=16, yRadius=16}, strokeColor=constants.hudStrokeColor, strokeWidth=1, shadow=constants.shadowSpec }
    _G.statsPanel[2] = { type="text", text="Efficiency Analytics", textColor=constants.colorTitle, textSize=24, textAlignment="center", frame={x="0%",y="2%",w="100%",h="8%"} }

    -- Summary Section
    local summaryY = 60
    _G.statsPanel[3] = { type="text", text="LIFETIME STATS", textColor=constants.colorHeader, textSize=12, textAlignment="center", frame={x="0%",y=summaryY,w="100%",h=20} }
    
    local keysTyped = tonumber(stats.data.totalKeysTyped) or 0
    local keysSaved = tonumber(stats.data.keysSaved) or 0
    local totalUsed = keysTyped + keysSaved
    local efficiency = (totalUsed > 0) and math.floor((keysSaved / totalUsed) * 100) or 0

    local statsTxt = string.format("Keystrokes Typed: %d\nKeystrokes Saved: %d\nVim Efficiency: %d%%", keysTyped, keysSaved, efficiency)
    _G.statsPanel[4] = { type="text", text=statsTxt, textColor={white=0.9}, textSize=18, textAlignment="center", frame={x="10%", y=summaryY + 30, w="80%", h=80} }

    _G.statsPanel[5] = { type="text", text="TOP COMMANDS", textColor=constants.colorHeader, textSize=12, textAlignment="center", frame={x="0%", y=summaryY + 120, w="100%", h=20} }
    
    -- Graph Section
    local top = stats.getTopCommands(12)
    local maxFreq = 1
    if top and top[1] and top[1].freq then maxFreq = top[1].freq end
    
    local idx = 6
    for i, item in ipairs(top) do
        local rowY = summaryY + 150 + ((i-1) * 35)
        local barW = math.floor((item.freq / maxFreq) * 300)
        local barX = 150
        
        _G.statsPanel[idx] = { type="text", text=tostring(item.cmd), textColor=constants.colorKey, textSize=15, textAlignment="right", frame={x=10, y=rowY, w=130, h=30}, textFont=config.fontCode }
        idx = idx + 1
        _G.statsPanel[idx] = { type="rectangle", action="fill", fillColor={hex="#0A84FF", alpha=0.3}, frame={x=barX, y=rowY+5, w=barW, h=20}, roundedRectRadii={xRadius=4,yRadius=4} }
        idx = idx + 1
        _G.statsPanel[idx] = { type="text", text=tostring(item.freq), textColor={white=0.7}, textSize=12, textAlignment="left", frame={x=barX + barW + 10, y=rowY+5, w=60, h=20} }
        idx = idx + 1
    end

    -- Footer
    _G.statsPanel[idx] = { type="rectangle", action="fill", fillColor=constants.btnColorAction, frame={x="30%", y="90%", w="40%", h="5%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    idx = idx + 1
    _G.statsPanel[idx] = { type="text", text="Close Results", textColor={white=1}, textSize=16, textAlignment="center", frame={x="30%", y="91.2%", w="40%", h="5%"} }
    
    _G.statsPanel:show()
end

function panels.updateExclusionPanel()
    while #_G.exclPanel > 0 do _G.exclPanel[1] = nil end

    _G.exclPanel[1] = { type="rectangle", action="fill", fillColor=constants.panelColor, roundedRectRadii={xRadius=16, yRadius=16}, strokeColor=constants.hudStrokeColor, strokeWidth=1, shadow=constants.shadowSpec }
    _G.exclPanel[2] = { type="text", text="Excluded Apps", textColor=constants.colorTitle, textSize=24, textAlignment="center", frame={x="0%",y="2%",w="100%",h="8%"} }

    panels.sortedExclusions = {}
    for id, _ in pairs(config.excludedApps) do table.insert(panels.sortedExclusions, id) end
    table.sort(panels.sortedExclusions)

    local rowH = 35
    local startY = 60

    for i, bundleId in ipairs(panels.sortedExclusions) do
        local yVal = startY + ((i-1) * (rowH + 5))
        _G.exclPanel[#_G.exclPanel+1] = { type="rectangle", action="fill", fillColor={red=0.2,green=0.2,blue=0.2,alpha=1}, frame={x="5%", y=yVal, w="80%", h=rowH}, roundedRectRadii={xRadius=4,yRadius=4} }
        _G.exclPanel[#_G.exclPanel+1] = { type="text", text=bundleId, textColor={white=0.9}, textSize=13, textAlignment="center", frame={x="7%", y=yVal+11, w="75%", h=rowH} }
        _G.exclPanel[#_G.exclPanel+1] = { type="rectangle", action="fill", fillColor=constants.btnColorExclude, frame={x="87%", y=yVal, w="8%", h=rowH}, roundedRectRadii={xRadius=4,yRadius=4} }
        _G.exclPanel[#_G.exclPanel+1] = { type="text", text="X", textColor={white=1}, textSize=14, textAlignment="center", frame={x="87%", y=yVal+10, w="8%", h=rowH} }
    end

    _G.exclPanel[#_G.exclPanel+1] = { type="rectangle", action="fill", fillColor=constants.btnColorAction, frame={x="30%", y="89%", w="40%", h="5%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.exclPanel[#_G.exclPanel+1] = { type="text", text="Close List", textColor={white=1}, textSize=16, textAlignment="center", frame={x="30%", y="90.2%", w="40%", h="5%"} }
end

function panels.getSettingsTarget(relX, relY)
    -- SECTION: FEATURES (Start 12%, Stride 5.0%, Height 4%)
    -- Original: relY > 0.120 and relY < 0.160 then return "toggle_master"
    -- New logic for features (0.12 to 0.56, 9 rows, 5% height each)
    if relY > 0.11 and relY < 0.56 then
        local row = math.floor((relY - 0.11) / 0.05)
        if row == 0 then return "toggle_master"
        elseif row == 1 then return "toggle_hud"
        elseif row == 2 then return "toggle_buffer"
        elseif row == 3 then return "toggle_action"
        elseif row == 4 then return "toggle_entry"
        elseif row == 5 then return "toggle_macro"
        elseif row == 6 then return "toggle_aerospace"
        elseif row == 7 then return "toggle_tooltips"
        elseif row == 8 then return "toggle_trainer" end
    
    -- SECTION: APPEARANCE (Header 59%)
    elseif relY > 0.60 then
        -- Pos (61 - 65)
        if relY > 0.61 and relY < 0.65 then
            if relX < 0.5 then return "btn_pos" else return "btn_align" end
        
        -- Title (66.5 - 70.5)
        elseif relY > 0.665 and relY < 0.705 then
            if relX < 0.25 then return "btn_title_minus"
            elseif relX > 0.75 then return "btn_title_plus" end
        
        -- Text (72 - 76)
        elseif relY > 0.72 and relY < 0.76 then
            if relX < 0.25 then return "btn_text_minus"
            elseif relX > 0.75 then return "btn_text_plus" end
        
        -- SECTION: SMART (77.5 - 81.5)
        elseif relY > 0.775 and relY < 0.815 then
            return "toggle_ghost"
        
        -- SECTION: FONTS (83 - 87)
        elseif relY > 0.83 and relY < 0.87 then
            if relX < 0.5 then return "btn_font_ui" else return "btn_font_code" end

        elseif relY > 0.92 and relY < 0.95 then return "toggle_app"
        
        -- FOOTER (96 - 99%)
        elseif relY > 0.96 then
            if relX < 0.35 then return "btn_save"
            elseif relX > 0.38 and relX < 0.63 then return "btn_analytics"
            elseif relX > 0.65 then return "btn_exclusions" end
        end
    end
    return nil
end

return panels
