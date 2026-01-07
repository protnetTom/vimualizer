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
    for i=1,60 do _G.prefPanel[i] = { type="rectangle", action="skip", frame={x=0,y=0,w=0,h=0} } end

    _G.prefPanel[1] = { type="rectangle", action="fill", fillColor=constants.panelColor, roundedRectRadii={xRadius=16, yRadius=16}, strokeColor=constants.hudStrokeColor, strokeWidth=1, shadow=constants.shadowSpec }
    _G.prefPanel[2] = { type="text", text="Vimualizer Config", textColor=constants.colorTitle, textSize=24, textAlignment="center", frame={x="0%",y="2%",w="100%",h="5%"} }

    -- SECTION: FEATURES (Index 3)
    _G.prefPanel[3] = { type="text", text="FEATURES", textColor=constants.colorHeader, textSize=12, textAlignment="center", frame={x="10%",y="8%",w="80%",h="3%"} }

    for i=0,7 do
        local yPos = 12 + (i * 5.5)
        _G.prefPanel[4 + (i*2)] = { type="rectangle", action="fill", frame={x="10%",y=yPos.."%",w="80%",h="4%"} }
        _G.prefPanel[5 + (i*2)] = { type="text", textAlignment="center", frame={x="10%",y=(yPos+1.2).."%",w="80%",h="4%"} }
    end

    -- SECTION: APPEARANCE (Index 20)
    local appY = 57
    _G.prefPanel[20] = { type="text", text="APPEARANCE", textColor=constants.colorHeader, textSize=12, textAlignment="center", frame={x="10%",y=appY.."%",w="80%",h="3%"} }

    -- Position & Alignment (Indices 21-24)
    local subY = 61
    _G.prefPanel[21] = { type="rectangle", action="fill", frame={x="10%",y=subY.."%",w="38%",h="4%"} }
    _G.prefPanel[22] = { type="text", textAlignment="center", frame={x="10%",y=(subY+1.2).."%",w="38%",h="4%"} }
    _G.prefPanel[23] = { type="rectangle", action="fill", frame={x="52%",y=subY.."%",w="38%",h="4%"} }
    _G.prefPanel[24] = { type="text", textAlignment="center", frame={x="52%",y=(subY+1.2).."%",w="38%",h="4%"} }

    -- Title Size
    local sizeY1 = 66.5
    _G.prefPanel[25] = { type="rectangle", action="fill", frame={x="10%",y=sizeY1.."%",w="15%",h="4%"} }
    _G.prefPanel[26] = { type="text", text="-", textColor={white=1}, textSize=20, textAlignment="center", frame={x="10%",y=(sizeY1+0.6).."%",w="15%",h="4%"} }
    _G.prefPanel[27] = { type="rectangle", action="fill", frame={x="75%",y=sizeY1.."%",w="15%",h="4%"} }
    _G.prefPanel[28] = { type="text", text="+", textColor={white=1}, textSize=20, textAlignment="center", frame={x="75%",y=(sizeY1+0.6).."%",w="15%",h="4%"} }
    _G.prefPanel[29] = { type="text", text="Title Size", textColor={white=1}, textSize=15, textAlignment="center", frame={x="25%",y=(sizeY1+0.9).."%",w="50%",h="4%"} }

    -- Text Size
    local sizeY2 = 72
    _G.prefPanel[30] = { type="rectangle", action="fill", frame={x="10%",y=sizeY2.."%",w="15%",h="4%"} }
    _G.prefPanel[31] = { type="text", text="-", textColor={white=1}, textSize=20, textAlignment="center", frame={x="10%",y=(sizeY2+0.6).."%",w="15%",h="4%"} }
    _G.prefPanel[32] = { type="rectangle", action="fill", frame={x="75%",y=sizeY2.."%",w="15%",h="4%"} }
    _G.prefPanel[33] = { type="text", text="+", textColor={white=1}, textSize=20, textAlignment="center", frame={x="75%",y=(sizeY2+0.6).."%",w="15%",h="4%"} }
    _G.prefPanel[34] = { type="text", text="Text Size", textColor={white=1}, textSize=15, textAlignment="center", frame={x="25%",y=(sizeY2+0.9).."%",w="50%",h="4%"} }

    -- SMART FEATURES
    local smartY = 77.5
    _G.prefPanel[35] = { type="rectangle", action="fill", frame={x="10%",y=smartY.."%",w="80%",h="4%"} }
    _G.prefPanel[36] = { type="text", textAlignment="center", frame={x="10%",y=(smartY+1.2).."%",w="80%",h="4%"} }

    -- FONTS
    local fontY = 83
    _G.prefPanel[39] = { type="rectangle", action="fill", frame={x="10%",y=fontY.."%",w="38%",h="4%"} }
    _G.prefPanel[40] = { type="text", textAlignment="center", frame={x="10%",y=(fontY+1.2).."%",w="38%",h="4%"} }
    _G.prefPanel[41] = { type="rectangle", action="fill", frame={x="52%",y=fontY.."%",w="38%",h="4%"} }
    _G.prefPanel[42] = { type="text", textAlignment="center", frame={x="52%",y=(fontY+1.2).."%",w="38%",h="4%"} }

    -- EXCLUSIONS
    local excY = 88.5
    _G.prefPanel[43] = { type="text", text="EXCLUSIONS", textColor=constants.colorHeader, textSize=12, textAlignment="center", frame={x="10%",y=excY.."%",w="80%",h="3%"} }

    -- App Row
    local appRowY = 92
    _G.prefPanel[44] = { type="rectangle", action="fill", frame={x="10%",y=appRowY.."%",w="55%",h="3%"} }
    _G.prefPanel[45] = { type="text", text="App Name", textColor={white=1}, textSize=11, textAlignment="center", frame={x="10%",y=(appRowY+0.3).."%",w="55%",h="3%"} }
    _G.prefPanel[46] = { type="rectangle", action="fill", frame={x="67%",y=appRowY.."%",w="23%",h="3%"} }
    _G.prefPanel[47] = { type="text", text="Toggle", textColor={white=1}, textSize=11, textAlignment="center", frame={x="67%",y=(appRowY+0.3).."%",w="23%",h="3%"} }

    -- Footer
    local footerY = 96
    _G.prefPanel[48] = { type="rectangle", action="fill", fillColor=constants.btnColorSave, frame={x="10%",y=footerY.."%",w="35%",h="2.2%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.prefPanel[49] = { type="text", text="Save", textColor={white=1}, textSize=14, textAlignment="center", frame={x="10%",y=(footerY+0.4).."%",w="35%",h="2.2%"} }
    _G.prefPanel[50] = { type="rectangle", action="fill", fillColor=constants.btnColorAction, frame={x="50%",y=footerY.."%",w="40%",h="2.2%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.prefPanel[51] = { type="text", text="Exclusions >>", textColor={white=1}, textSize=14, textAlignment="center", frame={x="50%",y=(footerY+0.4).."%",w="40%",h="2.2%"} }
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
    styleBtn(18, config.isTooltipsEnabled, "Show Tooltips: "..(config.isTooltipsEnabled and "ON" or "OFF"))

    local posNames = {"Left", "TopRight", "BotRight", "Center", "Custom"}
    styleActionBtn(21)
    _G.prefPanel[22].text = styledtext.new("Position: "..posNames[config.hudPosIndex], {font={name=config.fontUIBold, size=14}, color={white=1}, paragraphStyle={alignment="center"}})

    local alignLabel = "Align: " .. (config.hudTextAlignment:gsub("^%l", string.upper))
    styleActionBtn(23)
    _G.prefPanel[24].text = styledtext.new(alignLabel, {font={name=config.fontUIBold, size=14}, color={white=1}, paragraphStyle={alignment="center"}})

    styleActionBtn(25); styleActionBtn(27)
    _G.prefPanel[29].text = "Title Size: " .. config.fontTitleSize

    styleActionBtn(30); styleActionBtn(32)
    _G.prefPanel[34].text = "Text Size: " .. config.fontBodySize

    styleBtn(35, config.isReactiveOpacityEnabled, "Ghost Mode: "..(config.isReactiveOpacityEnabled and "ON" or "OFF"))

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

function panels.updateExclusionPanel()
    while #_G.exclPanel > 0 do _G.exclPanel[#_G.exclPanel] = nil end

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
    -- SECTION: FEATURES (Start 12%, Stride 5.5%, Height 4%)
    if relY > 0.120 and relY < 0.160 then return "toggle_master"
    elseif relY > 0.175 and relY < 0.215 then return "toggle_hud"
    elseif relY > 0.230 and relY < 0.270 then return "toggle_buffer"
    elseif relY > 0.285 and relY < 0.325 then return "toggle_action"
    elseif relY > 0.340 and relY < 0.380 then return "toggle_entry"
    elseif relY > 0.395 and relY < 0.435 then return "toggle_macro"
    elseif relY > 0.450 and relY < 0.490 then return "toggle_aerospace"
    elseif relY > 0.505 and relY < 0.545 then return "toggle_tooltips"
    
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
            if relX < 0.45 then return "btn_save"
            elseif relX > 0.50 then return "btn_exclusions" end
        end
    end
    return nil
end

return panels
