local snippets = {}

local eventtap = require("hs.eventtap")
local config = require("modules.config")

snippets.buffer = ""
snippets.maxBufferLen = 20
snippets.isExpanding = false

function snippets.expand(trigger, expansion)
    -- Delete the trigger
    -- Since we suppress the last character typed, we only need to delete 
    -- the previous (length - 1) characters that already entered the app.
    local charCount = utf8.len(trigger)
    local backspaces = charCount - 1
    for i = 1, backspaces do
        eventtap.keyStroke({}, "delete", 0)
    end

    -- Process dynamic expansions
    local finalExpansion = expansion
    if expansion == "{{date}}" then
        finalExpansion = os.date("%Y-%m-%d")
    elseif expansion == "{{time}}" then
        finalExpansion = os.date("%H:%M:%S")
    end

    -- Type the expansion
    snippets.isExpanding = true
    eventtap.keyStrokes(finalExpansion)
    timer.doAfter(0.1, function() snippets.isExpanding = false end)
end

function snippets.processKey(char, keyCode)
    if not config.isSnippetsEnabled then return false end
    
    -- We only care about characters that could be part of a trigger
    -- Or backspace which should clear/reduce the buffer
    if keyCode == 51 then -- Backspace
        snippets.buffer = snippets.buffer:sub(1, -2)
        return false
    end

    if not char or char == "" then 
        -- Non-character key, usually resets the buffer
        snippets.buffer = ""
        return false 
    end

    snippets.buffer = snippets.buffer .. char
    if #snippets.buffer > snippets.maxBufferLen then
        snippets.buffer = snippets.buffer:sub(-snippets.maxBufferLen)
    end

    -- Check for matches
    for trigger, expansion in pairs(config.snippets) do
        if snippets.buffer:sub(-#trigger) == trigger then
            snippets.expand(trigger, expansion)
            snippets.buffer = "" -- Reset buffer after expansion
            return true -- Consume the event
        end
    end

    return false
end

function snippets.clear()
    snippets.buffer = ""
end

return snippets
