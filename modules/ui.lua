local ui = {}

local canvas = require("hs.canvas")
local styledtext = require("hs.styledtext")
local drawing = require("hs.drawing")
local timer = require("hs.timer")

local constants = require("modules.constants")
local config = require("modules.config")
local menus = require("modules.menus")

-- CANVASES
_G.hud = canvas.new({x=0,y=0,w=100,h=100})
_G.keyBuffer = canvas.new({x=0, y=0, w=constants.bufferW, h=constants.bufferH})
_G.prefPanel = canvas.new({x=constants.prefX, y=constants.prefY, w=constants.prefW, h=constants.prefH}):level(hs.canvas.windowLevels.floating)
_G.exclPanel = canvas.new({x=constants.exclX, y=constants.exclY, w=constants.exclW, h=constants.exclH}):level(hs.canvas.windowLevels.floating)
_G.snipPanel = canvas.new({x=constants.snipX, y=constants.snipY, w=constants.snipW, h=constants.snipH}):level(hs.canvas.windowLevels.floating + 5)
_G.statsPanel = canvas.new({x=constants.statsX, y=constants.statsY, w=constants.statsW, h=constants.statsH}):level(hs.canvas.windowLevels.floating + 5)
_G.trainerCanvas = canvas.new({x=(constants.screen.w-450)/2, y=constants.screen.h * 0.2, w=450, h=180}):level(hs.canvas.windowLevels.overlay)
_G.tooltipCanvas = canvas.new({x=0,y=0,w=200,h=60}):level(hs.canvas.windowLevels.floating + 10)

ui.opacityTimer = nil
ui.hudTimer = nil

function ui.initCanvases()
    -- Initialize HUD
    _G.hud[1] = { type="rectangle", action="fill", fillColor=constants.hudBgColor, roundedRectRadii={xRadius=16,yRadius=16}, strokeColor=constants.hudStrokeColor, strokeWidth=1, shadow=constants.shadowSpec }
    _G.hud[2] = { type="text", text="", frame={x=0,y=0,w=0,h=0} }
    _G.hud[3] = { type="text", text="", frame={x=0,y=0,w=0,h=0} }
    _G.hud[4] = { type="rectangle", action="skip", fillColor=constants.colorDrag, roundedRectRadii={xRadius=12,yRadius=12}, frame={x=0,y=0,w="100%",h=30} }
    _G.hud[5] = { type="text", action="skip", text="DRAG ME", textSize=11, textColor={white=1}, textAlignment="center", frame={x=0,y=9,w="100%",h=12} }

    -- Initialize KeyBuffer
    _G.keyBuffer[1] = { type="rectangle", action="fill", fillColor=constants.bufferBgColor, roundedRectRadii={xRadius=12,yRadius=12}, strokeColor=constants.hudStrokeColor, strokeWidth=1, shadow=constants.shadowSpec }
    _G.keyBuffer[2] = { type="text", text="NORMAL", textColor=constants.colorTitle, textSize=22, textAlignment="center", frame={x="0%",y="30%",w="25%",h="100%"}, textFont=config.fontUIBold }
    _G.keyBuffer[3] = { type="text", text="", textColor=constants.bufferTxtColor, textSize=34, textAlignment="right", frame={x="25%",y="5%",w="70%",h="60%"}, textFont=config.fontCode }
    _G.keyBuffer[4] = { type="text", text="", textColor=constants.colorInfo, textSize=15, textAlignment="right", frame={x="25%",y="60%",w="70%",h="30%"}, textFont=config.fontUI }
    _G.keyBuffer[5] = { type="rectangle", action="skip", fillColor=constants.colorDrag, roundedRectRadii={xRadius=8,yRadius=8}, frame={x=0,y=0,w="100%",h=20} }
    _G.keyBuffer[6] = { type="text", action="skip", text="DRAG ME", textSize=10, textColor={white=1}, textAlignment="center", frame={x=0,y=5,w="100%",h=10} }

    -- Initialize Tooltips
    _G.tooltipCanvas[1] = { type="rectangle", action="fill", fillColor={hex="#1c1c1e", alpha=0.95}, roundedRectRadii={xRadius=8,yRadius=8}, strokeColor={white=1,alpha=0.2}, strokeWidth=1, shadow={ blurRadius=8, color={alpha=0.5, white=0}, offset={h=4, w=0} } }
    _G.tooltipCanvas[2] = { type="text", text="", frame={x="8px",y="8px",w="184px",h="44px"} }

    -- Initialize Trainer
    _G.trainerCanvas[1] = { type="rectangle", action="fill", fillColor={hex="#1e1e1e", alpha=0.98}, roundedRectRadii={xRadius=16,yRadius=16}, strokeColor={hex="#FFD60A", alpha=1}, strokeWidth=3, shadow=constants.shadowSpec }
    _G.trainerCanvas[2] = { type="text", text="", textColor={white=0.6}, textSize=12, textAlignment="center", frame={x="5%",y="5%",w="90%",h="10%"}, textFont=config.fontUIBold }
    _G.trainerCanvas[3] = { type="text", text="", textColor={white=1}, textSize=17, textAlignment="center", frame={x="5%",y="15%",w="90%",h="35%"}, textFont=config.fontUIBold }
    _G.trainerCanvas[4] = { type="text", text="", textColor={hex="#FF453A"}, textSize=16, textAlignment="center", frame={x="5%",y="50%",w="90%",h="15%"}, textFont=config.fontCode }
    _G.trainerCanvas[5] = { type="text", text="", textColor={hex="#FFD60A"}, textSize=20, textAlignment="center", frame={x="5%",y="65%",w="90%",h="20%"}, textFont=config.fontCode }
    _G.trainerCanvas[6] = { type="text", text="", textColor={white=0.4}, textSize=10, textAlignment="center", frame={x="5%",y="85%",w="90%",h="12%"}, textFont=config.fontUI }
end

function ui.resetOpacity()
    if not config.isReactiveOpacityEnabled then return end
    if _G.keyBuffer then _G.keyBuffer:alpha(1.0) end
    if _G.hud then _G.hud:alpha(1.0) end
    if ui.opacityTimer then ui.opacityTimer:stop() end
    ui.opacityTimer = timer.doAfter(config.idleTimeout, function()
        if not config.isEditMode and config.isReactiveOpacityEnabled then
            if _G.keyBuffer then _G.keyBuffer:alpha(config.idleOpacity) end
            if _G.hud then _G.hud:alpha(config.idleOpacity) end
        end
    end)
end

function ui.updateDragHandles()
    local action = config.isEditMode and "fill" or "skip"
    _G.hud[4].action = action; _G.hud[5].action = action; _G.hud[1].strokeColor = config.isEditMode and constants.colorDrag or constants.hudStrokeColor
    _G.keyBuffer[5].action = action; _G.keyBuffer[6].action = action; _G.keyBuffer[1].strokeColor = config.isEditMode and constants.colorDrag or {white=1,alpha=0.2}
    local level = config.isEditMode and hs.canvas.windowLevels.floating or hs.canvas.windowLevels.overlay
    _G.hud:level(level); _G.keyBuffer:level(level)
    ui.updateBufferGeometry()
end

function ui.updateBufferGeometry()
    if config.isActionInfoEnabled then
        _G.keyBuffer[3].frame = {x="25%", y="2%", w="70%", h="58%"}
        _G.keyBuffer[4].action = "stroke"; _G.keyBuffer[4].frame = {x="25%", y="62%", w="70%", h="30%"}
    else
        _G.keyBuffer[3].frame = {x="25%", y="15%", w="70%", h="70%"}
        _G.keyBuffer[4].action = "skip"
    end
end

function ui.formatHudBody(rawText)
    local finalStyled = styledtext.new("")
    local baseStyle = { font={name=config.fontUI, size=config.fontBodySize}, color=constants.colorDesc, paragraphStyle={lineSpacing=6, alignment=config.hudTextAlignment} }
    local keyStyle =  { font={name=config.fontCode, size=config.fontBodySize}, color=constants.colorKey, paragraphStyle={lineSpacing=6, alignment=config.hudTextAlignment} }
    local headerStyle = { font={name=config.fontUIBold, size=config.fontBodySize-2}, color=constants.colorHeader, paragraphStyle={lineSpacing=6, alignment=config.hudTextAlignment} }

    if not rawText or rawText == "" then return finalStyled end
    for line in rawText:gmatch("[^\r\n]+") do
        if line:match("^%-%-.*%-%-$") then
            finalStyled = finalStyled .. styledtext.new("\n" .. line .. "\n", headerStyle)
        elseif line:match(":") then
            local keyPart, descPart = line:match("^(.-)%s*:%s*(.*)$")
            finalStyled = finalStyled .. styledtext.new(keyPart, keyStyle) .. styledtext.new(" : ", baseStyle) .. styledtext.new(descPart .. "\n", baseStyle)
        else
            finalStyled = finalStyled .. styledtext.new(line .. "\n", baseStyle)
        end
    end
    return finalStyled
end

function ui.presentHud(title, rawBodyText, titleOverrideColor)
    local styledTitle = styledtext.new(title, { font={name=config.fontUIBold, size=config.fontTitleSize}, color=titleOverrideColor or constants.colorTitle, paragraphStyle={alignment=config.hudTextAlignment} })
    local styledBody = ui.formatHudBody(rawBodyText)

    local innerMaxW = constants.maxHudWidth - (constants.hudPadding * 2)
    local titleSize = drawing.getTextDrawingSize(styledTitle, {w=innerMaxW})
    local bodySize = {w=0, h=0}
    if rawBodyText and rawBodyText ~= "" then bodySize = drawing.getTextDrawingSize(styledBody, {w=innerMaxW}) end
    local contentW = math.max(titleSize.w, bodySize.w)
    local newW = math.max(constants.minHudWidth, contentW + (constants.hudPadding * 2))
    local titleH = titleSize.h
    local bodyH = bodySize.h
    local spacer = (bodyH > 0) and 15 or 0
    local newH = constants.hudPadding + titleH + spacer + bodyH + constants.hudPadding
    if config.isEditMode then newH = newH + 20 end

    local newX, newY = 150, 100
    if config.hudPosIndex == 1 then newX, newY = 150, (constants.screen.h - newH) / 2
    elseif config.hudPosIndex == 2 then newX, newY = constants.screen.w - newW - 50, 50
    elseif config.hudPosIndex == 3 then newX, newY = constants.screen.w - newW - 50, constants.screen.h - newH - 50
    elseif config.hudPosIndex == 4 then newX, newY = (constants.screen.w - newW) / 2, (constants.screen.h - newH) / 2
    elseif config.hudPosIndex == 5 then newX, newY = config.customHudX, config.customHudY end

    _G.hud:frame({x=newX, y=newY, w=newW, h=newH})
    _G.hud[2].text = styledTitle; _G.hud[2].frame = {x=constants.hudPadding,y=constants.hudPadding,w=newW-(constants.hudPadding*2),h=titleH};
    _G.hud[3].text = styledBody; _G.hud[3].frame = {x=constants.hudPadding,y=constants.hudPadding+titleH+spacer,w=newW-(constants.hudPadding*2),h=bodyH};
    ui.updateDragHandles()
    _G.hud:show()
end

return ui
