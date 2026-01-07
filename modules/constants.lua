local constants = {}

constants.screen = hs.screen.mainScreen():frame()

-- HUD / BUFFER Geometry
constants.bufferMaxLen = 12
constants.bufferW, constants.bufferH = 550, 85
constants.bufferBgColor = { red=0.15, green=0.15, blue=0.15, alpha=0.95 }
constants.bufferTxtColor = { red=0.6, green=1, blue=0.6, alpha=1 }

-- MAIN PREFS GEOMETRY
constants.prefW, constants.prefH = 450, 1100
constants.prefX, constants.prefY = (constants.screen.w - constants.prefW) / 2, (constants.screen.h - constants.prefH) / 2

-- EXCLUSION LIST GEOMETRY
constants.exclW, constants.exclH = 500, 600
constants.exclX, constants.exclY = constants.prefX + constants.prefW + 20, constants.prefY

-- STATS PANEL GEOMETRY
constants.statsW, constants.statsH = 600, 750
constants.statsX, constants.statsY = constants.prefX - constants.statsW - 20, constants.prefY

-- THEME: macOS Dark Mode
constants.hudBgColor = { hex="#1e1e1e", alpha=0.90 }
constants.hudStrokeColor = { white=1, alpha=0.15 }
constants.panelColor = { hex="#1e1e1e", alpha=0.95 }

constants.colorTitle = { white=1, alpha=1 }
constants.colorKey = { hex="#0A84FF", alpha=1 }
constants.colorDesc = { white=0.8, alpha=1 }
constants.colorHeader = { white=0.6, alpha=1 }
constants.colorAccent = { hex="#FF453A", alpha=1 }
constants.colorInfo = { white=0.9, alpha=1 }
constants.colorRec = { hex="#FF453A", alpha=1 }

constants.colorDrag = { hex="#30D158", alpha=0.9 }
constants.btnColorAction = { hex="#0A84FF", alpha=1 }
constants.btnColorSave = { hex="#30D158", alpha=1 }
constants.btnColorExclude = { hex="#FF453A", alpha=1 }
constants.btnColorOn = { hex="#30D158", alpha=1 }
constants.btnColorOff = { hex="#FF453A", alpha=1 }

constants.shadowSpec = { blurRadius=20, color={alpha=0.5, white=0}, offset={h=10, w=0} }

constants.maxHudWidth = 700
constants.minHudWidth = 350
constants.hudPadding = 30
constants.displayTime = 8.0

constants.VIM_STATE = { NORMAL="NORMAL", INSERT="INSERT", VISUAL="VISUAL", PENDING_CHANGE="PENDING_CHANGE" }

-- VIM DEFINITIONS
constants.vimOps = { d="Delete", c="Change", y="Yank", v="Select", [">"]="Indent", ["<"]="Outdent", ["="]="Format" }
constants.vimContext = { i="Inside", a="Around" }
constants.vimObjects = {
    w="Word", W="WORD", p="Paragraph", s="Sentence", t="Tag",
    ["("]="Parens", [")"]="Parens", b="Parens",
    ["{"]="Braces", ["}"]="Braces", B="Braces",
    ["["]="Brackets", ["]"]="Brackets",
    ["<"]="Angle Brackets", [">"]="Angle Brackets",
    ["'"]="Quotes", ['"']="Double Quotes", ["`"]="Backticks"
}
constants.vimMotions = {
    h="Left", j="Down", k="Up", l="Right",
    w="Word", b="Back", e="End Word",
    ["0"]="Start Line", ["$"]="End Line", ["^"]="First Char",
    G="Bottom", H="Top Screen", M="Mid Screen", L="Bot Screen"
}
constants.argMotions = { f="Find", F="Find Back", t="Until", T="Until Back", r="Replace", m="Mark", ["`"]="Jump Mark", ["'"]="Jump Mark Line" }
constants.simpleActions = {
    u="Undo", ["^r"]="Redo", x="Delete Char", s="Sub Char",
    i="Insert Mode", a="Append", o="Open Below",
    I="Insert Start", A="Append End", O="Open Above",
    p="Paste After", P="Paste Before",
    J="Join Lines", D="Delete to End", C="Change to End", Y="Yank Line",
    ["/"]="Search", ["?"]="Search Back", n="Next Match", N="Prev Match",
    [":"]="Command Line", ["%"]="Match Bracket", ["*"]="Find Word Under",
    ["~"]="Toggle Case", ["."]="Repeat Last",
    ["{"]="Prev Paragraph", ["}"]="Next Paragraph",
    ["⌥h"]="Focus Left", ["⌥j"]="Focus Down", ["⌥k"]="Focus Up", ["⌥l"]="Focus Right",
    ["⌥⇧h"]="Move Left", ["⌥⇧j"]="Move Down", ["⌥⇧k"]="Move Up", ["⌥⇧l"]="Move Right",
    ["⌥f"]="Toggle Float", ["⌥s"]="Layout Stack", ["⌥/"]="Vertical Split", ["⌥-"]="Horizontal Split",
    ["⌥tab"]="Next Workspace", ["⌥comma"]="Layout Tiles"
}

constants.insertTriggers = { ["i"]=true, ["I"]=true, ["a"]=true, ["A"]=true, ["o"]=true, ["O"]=true, ["s"]=true, ["S"]=true, ["C"]=true }
constants.visualTriggers = { ["v"]=true, ["V"]=true, ["^v"]=true }

return constants
