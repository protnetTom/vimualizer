local easymotion = {}

local ax = require("hs.axuielement")
local canvas = require("hs.canvas")
local eventtap = require("hs.eventtap")
local window = require("hs.window")
local mouse = require("hs.mouse")
local timer = require("hs.timer")
local config = require("modules.config")

easymotion.isActive = false
easymotion.hints = {}
easymotion.inputBuffer = ""
easymotion.labels = "SDFJKLAHWERUIOVMNXC"

local function getElements(win)
    local found = {}
    local winAX = ax.windowElement(win)
    if not winAX then return {} end

    local winFrame = win:frame()
    local bf = 5  -- Buffer for fuzzy matching
    local aggression = config.easyMotionAggression or 2
    
    local function search(el, depth)
        -- Increase depth for aggressive mode
        local maxDepth = aggression == 3 and 25 or 15
        if depth > maxDepth then return end
        
        local children = el:attributeValue("AXChildren")
        if not children then return end

        for _, child in ipairs(children) do
            local role = child:attributeValue("AXRole")
            local actions = child:attributeValue("AXActionNames")
            local hasActions = (actions ~= nil and #actions > 0)
            local title = child:attributeValue("AXTitle")
            local desc = child:attributeValue("AXDescription")
            local value = child:attributeValue("AXValue")
            local enabled = child:attributeValue("AXEnabled")
            
            -- Skip disabled elements
            if enabled == false then
                search(child, depth + 1)
                goto continue
            end
            
            local shouldInclude = false
            local shouldRecurse = true
            
            if role then
                -- CONSERVATIVE: Only basic form elements (strict matching)
                if aggression >= 1 then
                    if role == "AXButton" or 
                       role == "AXTextField" or role == "AXTextArea" or
                       role == "AXCheckBox" or role == "AXRadioButton" or
                       role == "AXPopUpButton" or role == "AXComboBox" then
                        shouldInclude = true
                        shouldRecurse = false
                    end
                end
                
                -- MODERATE: All interactive elements + anything with actions
                if aggression >= 2 then
                    -- Catch all button types
                    if role:match("Button") or role:match("MenuItem") then
                        shouldInclude = true
                        shouldRecurse = false
                    end
                    
                    -- Any element with actions is clickable
                    if hasActions then
                        shouldInclude = true
                    end
                    
                    -- Common interactive elements
                    if role == "AXLink" or role == "AXImage" or role == "AXTab" or
                       role == "AXCell" or role == "AXRow" or
                       role:match("Slider") or role:match("Stepper") or
                       role:match("Picker") or role:match("Incrementor") or
                       role:match("Disclosure") or role == "AXSwitch" or
                       role == "AXSegmentedControl" or role:match("Color") then
                        shouldInclude = true
                    end
                    
                    -- Include groups/containers that have titles/descriptions AND actions
                    if (role:match("Group") or role == "AXRadioGroup") and (title or desc) and hasActions then
                        shouldInclude = true
                    end
                end
                
                -- AGGRESSIVE: Include almost everything
                if aggression >= 3 then
                    -- Include any element with a title, description, or value
                    if (title and title ~= "") or (desc and desc ~= "") or (value and value ~= "") then
                        if role:match("Group") or role:match("List") or 
                           role:match("Outline") or role:match("Table") or
                           role:match("Toolbar") or role:match("Static") or
                           role:match("Scroll") or role:match("Web") or
                           role:match("Layout") or role:match("Split") or
                           role:match("Container") then
                            shouldInclude = true
                        end
                    end
                    
                    -- Include anything with actions that we haven't caught yet
                    if hasActions and not shouldInclude then
                        shouldInclude = true
                    end
                end
            end

            local frame = child:attributeValue("AXFrame")
            
            if shouldInclude and frame then
                -- Adjust size thresholds based on aggression
                local minSize = aggression == 3 and 2 or (aggression == 2 and 4 or 8)
                local maxW = aggression == 3 and 1200 or (aggression == 2 and 1000 or 800)
                local maxH = aggression == 3 and 1000 or (aggression == 2 and 800 or 600)
                
                if frame.w > minSize and frame.h > minSize and frame.w < maxW and frame.h < maxH then
                    -- Must be within current window
                    if frame.x >= (winFrame.x - bf) and frame.y >= (winFrame.y - bf) and 
                       (frame.x + frame.w) <= (winFrame.x + winFrame.w + bf) and
                       (frame.y + frame.h) <= (winFrame.y + winFrame.h + bf) then
                        table.insert(found, {el = child, frame = frame})
                        
                        -- In aggressive mode, still recurse to find nested elements
                        if aggression < 3 then
                            shouldRecurse = false
                        end
                    end
                end
            end
            
            -- Recurse into children
            if shouldRecurse then
                search(child, depth + 1)
            end
            
            ::continue::
        end
    end

    search(winAX, 0)
    
    -- Fallback to application level if window scan is sparse
    if #found < 8 then
        local appAX = ax.applicationElement(win:application())
        if appAX then search(appAX, 0) end
    end
    
    -- Deduplicate overlapping elements
    local unique = {}
    local seen = {}
    for _, item in ipairs(found) do
        local key = string.format("%d,%d,%d,%d", 
            math.floor(item.frame.x), 
            math.floor(item.frame.y), 
            math.floor(item.frame.w), 
            math.floor(item.frame.h))
        if not seen[key] then
            table.insert(unique, item)
            seen[key] = true
        end
    end
    
    return unique
end

local function generateLabels(count)
    local chars = {}
    for i = 1, #easymotion.labels do table.insert(chars, easymotion.labels:sub(i, i)) end
    local n = #chars
    
    if count <= n then
        local labels = {}
        for i = 1, count do table.insert(labels, chars[i]) end
        return labels
    end
    
    -- Prefix-safe labels: (n - m) single-char labels + (m * n) two-char labels
    -- Solve for m: count <= (n - m) + (m * n)  => count - n <= m * (n - 1)
    local m = math.ceil((count - n) / (n - 1))
    local labels = {}
    
    -- Single character labels from the start of the list
    for i = 1, (n - m) do
        table.insert(labels, chars[i])
    end
    
    -- Two character labels using the end of the list as prefixes
    for i = (n - m + 1), n do
        local prefix = chars[i]
        for j = 1, n do
            if #labels < count then
                table.insert(labels, prefix .. chars[j])
            end
        end
    end
    
    return labels
end

function easymotion.start()
    if easymotion.isActive then easymotion.stop() return end
    local win = window.focusedWindow()
    if not win then return end
    
    hs.alert.show("EasyMotion", 0.4)
    local elements = getElements(win)
    if #elements == 0 then return end
    
    easymotion.isActive = true
    easymotion.inputBuffer = ""
    easymotion.hints = {}
    
    -- CREATE SINGLE CANVAS FOR ALL LABELS
    local screen = hs.screen.mainScreen():fullFrame()
    easymotion.mainCanvas = canvas.new(screen):level(hs.canvas.windowLevels.overlay)
    
    local labels = generateLabels(#elements)
    for i, item in ipairs(elements) do
        local label = labels[i]
        local f = item.frame
        local lw = #label * 10 + 10
        local lh = 20
        
        -- Position label at the top-left corner of the element
        local lx = f.x
        local ly = f.y
        
        -- Ensure label stays within screen bounds with padding
        local padding = 5
        local minX = screen.x + padding
        local minY = screen.y + padding
        local maxX = screen.x + screen.w - lw - padding
        local maxY = screen.y + screen.h - lh - padding
        
        -- Clamp to screen bounds
        lx = math.max(minX, math.min(lx, maxX))
        ly = math.max(minY, math.min(ly, maxY))
        
        -- If element is too close to edge and centering failed, position at top-left of element
        if lx <= minX or ly <= minY or lx >= maxX or ly >= maxY then
            lx = math.max(minX, math.min(f.x, maxX))
            ly = math.max(minY, math.min(f.y, maxY))
        end
        
        local idx = (i - 1) * 2 + 1 -- Sequential 1-based indexing
        easymotion.mainCanvas[idx] = {
            type = "rectangle", action = "fill", fillColor = {hex="#FFD60A", alpha=0.95},
            roundedRectRadii = {xRadius=4, yRadius=4}, frame = {x=lx, y=ly, w=lw, h=20},
            strokeColor = {black=1}, strokeWidth = 1, shadow = {blurRadius=2, offset={h=1,w=0}}
        }
        easymotion.mainCanvas[idx+1] = {
            type = "text", text = label, textColor = {black=1}, textSize = 14,
            textAlignment = "center", frame = {x=lx, y=ly+1, w=lw, h=20}, textFont = ".AppleSystemUIFontBold"
        }
        table.insert(easymotion.hints, {label = label, element = item.el, frame = f, layerIdx = idx})
    end
    
    easymotion.mainCanvas:show()
    
    easymotion.tap = eventtap.new({eventtap.event.types.keyDown}, function(e)
        local char = e:getCharacters():upper()
        if e:getKeyCode() == 53 then easymotion.stop(); return true end
        if not char or #char == 0 then return false end
        
        easymotion.inputBuffer = easymotion.inputBuffer .. char
        local match = nil
        local hasPartial = false
        
        for _, hint in ipairs(easymotion.hints) do
            if hint.label == easymotion.inputBuffer then
                match = hint
                break
            elseif hint.label:sub(1, #easymotion.inputBuffer) == easymotion.inputBuffer then
                hasPartial = true
            else
                -- Hide non-matching hints
                easymotion.mainCanvas[hint.layerIdx].action = "skip"
                easymotion.mainCanvas[hint.layerIdx+1].text = ""
            end
        end
        
        if match then
            local center = {x = match.frame.x + match.frame.w/2, y = match.frame.y + match.frame.h/2}
            easymotion.stop()
            -- Perform click with slight delay to ensure focus
            mouse.absolutePosition(center)
            timer.doAfter(0.02, function()
                eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDown, center):post()
                eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, center):post()
            end)
            return true
        elseif not hasPartial then
            easymotion.stop()
        end
        return true
    end):start()
end

function easymotion.stop()
    easymotion.isActive = false
    if easymotion.tap then easymotion.tap:stop(); easymotion.tap = nil end
    if easymotion.mainCanvas then easymotion.mainCanvas:delete(); easymotion.mainCanvas = nil end
    easymotion.hints = {}
    easymotion.inputBuffer = ""
end

return easymotion
