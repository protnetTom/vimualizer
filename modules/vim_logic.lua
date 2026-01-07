local vim_logic = {}

local styledtext = require("hs.styledtext")
local constants = require("modules.constants")
local config = require("modules.config")
local stats = require("modules.stats")

vim_logic.currentState = constants.VIM_STATE.NORMAL
vim_logic.keyHistory = {}
vim_logic.recordingRegister = nil
vim_logic.pendingMacroStart = false

function vim_logic.getSequenceDescription()
    local len = #vim_logic.keyHistory
    if len == 0 then return "" end
    local k1 = vim_logic.keyHistory[len]
    local k2 = (len >= 2) and vim_logic.keyHistory[len-1] or nil
    local k3 = (len >= 3) and vim_logic.keyHistory[len-2] or nil

    if k3 and k2 and k1 then
        if constants.vimOps[k3] and constants.vimContext[k2] then
            local objName = constants.vimObjects[k1] or ("'" .. k1 .. "'")
            return constants.vimOps[k3] .. " " .. constants.vimContext[k2] .. " " .. objName
        end
    end
    if k2 and k1 then
        if constants.argMotions[k2] then return constants.argMotions[k2] .. " '" .. k1 .. "'" end
        if constants.vimOps[k2] and constants.vimContext[k1] then return constants.vimOps[k2] .. " " .. constants.vimContext[k1] .. "..." end
        if constants.vimOps[k2] and k2 == k1 then return constants.vimOps[k2] .. " Line" end
    end
    if k1 and constants.vimOps[k1] then return constants.vimOps[k1] .. "..." end
    local desc = constants.simpleActions[k1] or constants.vimMotions[k1]
    if not desc and #k1 > 1 and k1:sub(1,1) == "^" then desc = "Ctrl + " .. k1:sub(2) end
    return desc or ""
end

function vim_logic.updateStateDisplay()
    local stateText, color = vim_logic.currentState, constants.colorTitle
    if vim_logic.recordingRegister then 
        stateText = "REC @" .. vim_logic.recordingRegister
        color = constants.colorRec
    elseif vim_logic.currentState == constants.VIM_STATE.INSERT then 
        color = {red=0.4, green=1, blue=0.4, alpha=1}
    elseif vim_logic.currentState == constants.VIM_STATE.VISUAL then 
        color = {red=1, green=0.6, blue=0.2, alpha=1}
    elseif vim_logic.currentState == constants.VIM_STATE.PENDING_CHANGE then 
        stateText = "PENDING"
        color = constants.colorAccent 
    end
    _G.keyBuffer[2].text = stateText
    _G.keyBuffer[2].textColor = color
end

function vim_logic.addToBuffer(str)
    table.insert(vim_logic.keyHistory, str)
    if #vim_logic.keyHistory > constants.bufferMaxLen then table.remove(vim_logic.keyHistory, 1) end
    
    -- Build a styled string for the buffer to handle glyph font fallback
    local baseAttr = { font={name=config.fontCode, size=34}, color=constants.bufferTxtColor, paragraphStyle={alignment="right"} }
    local specialAttr = { font={name=config.fontUI, size=34}, color=constants.bufferTxtColor, paragraphStyle={alignment="right"} }
    local styledBuf = styledtext.new("", baseAttr)
    
    for i, key in ipairs(vim_logic.keyHistory) do
        -- Use code font for single-length alphanumeric/basic symbols
        local isStandard = (#key == 1 and key:match("[%w%p%s]"))
        local attr = isStandard and baseAttr or specialAttr
        styledBuf = styledBuf .. styledtext.new(key .. (i < #vim_logic.keyHistory and " " or ""), attr)
    end
    
    _G.keyBuffer[3].text = styledBuf

    if config.isActionInfoEnabled then 
        _G.keyBuffer[4].text = vim_logic.getSequenceDescription() 
    end
    vim_logic.updateStateDisplay()
    if config.isBufferEnabled then _G.keyBuffer:show() end

    -- Statistical Tracking
    stats.recordCommand(str)
    
    -- Detection of efficiency: e.g. "5j" or "d3w"
    local fullBuf = table.concat(vim_logic.keyHistory, "")
    local countStr, motionStr = fullBuf:match("(%d+)(%a+)$")
    if countStr and motionStr then
        local num = tonumber(countStr)
        if num and num > 1 then
            -- Efficiency gained by using a count prefix
            -- We only record this once when the motion completes the sequence
            local saved = num - 1 -- Each digit + the motion represents 1 key typed. 
                                 -- "10j" (3 keys) replaces 10 "j"s. Saved = 10 - 3 = 7.
                                 -- In our logic: num (10) - length of prefix (2) - 1 (motion)
            local overhead = #countStr
            local actualSaved = num - overhead - 1
            if actualSaved > 0 then
                -- Note: This is a simple heuristic. It might double count if not careful,
                -- but since we check only when motionStr is at the end, it's fairly safe.
                stats.recordKeysSaved(actualSaved)
            end
        end
    end
end

function vim_logic.resetToNormal()
    vim_logic.currentState = constants.VIM_STATE.NORMAL
    vim_logic.pendingMacroStart = false
    vim_logic.keyHistory = {}
    _G.keyBuffer[3].text = ""
    _G.keyBuffer[4].text = ""
    vim_logic.updateStateDisplay()
    _G.hud:hide()
end

return vim_logic
