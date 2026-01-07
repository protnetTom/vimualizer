local menus = {}

menus.indexMenu = { 
    title = "Vim Entry Points", 
    text = "-- Operators --\nd : Delete Actions\nc : Change Actions\ny : Yank (Copy)\np : Paste\n-- Modes --\nv : Visual Char Mode\nV : Visual Line Mode\n^v : Visual Block Mode\n-- Macros --\nq : Record Macro\n-- Navigation --\ng : Go / Extended\nz : Folds / View\nm : Marks\n/ : Search" 
}

menus.previewMenu = { 
    title = "Visual Preview", 
    text = "-- Section Header --\nkey : description text\ncmd : another command\n-- Another Section --\ntest : checking font size" 
}

menus.modifierMenus = {
    shift = { title = "Shift Held (Upper Case)", text = "-- Operators --\nD : Delete rest of line\nC : Change rest of line\nY : Yank line (yy)\n-- Insert --\nI : Insert at START\nA : Insert at END\nO : Insert line ABOVE\n-- Modes --\nV : Visual LINE Mode" },
    ctrl = { title = "Ctrl Held (Commands)", text = "-- Visual --\n^v : Visual BLOCK Mode\n-- Window --\n^w : Window Splits...\n-- Navigation --\n^d : Scroll Down\n^u : Scroll Up\n^o : Jump Back\n^i : Jump Forward" },
    alt = { title = "Aerospace (Option)", text = "-- Focus --\nh/j/k/l : Focus Window\n-- Move --\n⇧ + h/j/k/l : Move Window\n-- Layout --\n/ : Vertical Split\n- : Horizontal Split\ns : Layout Stack\nf : Toggle Floating\n, : Layout Tiles\n-- Workspaces --\n1-9 : Switch Workspace\n⇧ + 1-9 : Move to Workspace\nTab : Next Workspace" }
}

menus.triggers = {
    d = { title = "Delete (d...)", text = "-- Basics --\ndd : Entire line\nD : Rest of line (d$)\n-- Objects --\ndw : Next word\ndiw : Inner word\ndi\" : Inside quotes\ndi( : Inside parens\ndt{x} : Delete until {x}" },
    c = { title = "Change (c...)", text = "-- Basics --\ncc : Entire line\nC : Rest of line (c$)\ncw : Change word\n-- Objects --\nciw : Change inner word\nci\" : Change inside quotes\nci( : Change inside parens" },
    y = { title = "Yank/Copy (y...)", text = "-- Basics --\nyy : Entire line\ny$ : To end of line\np/P : Paste after/before\n-- Objects --\nyiw : Inner word\nyip : Inner paragraph" },
    v = { title = "Visual Char (v)", text = "v : Start selection\no : Swap cursor end\n-- Actions --\nd/y : Delete / Yank\n~ : Toggle Case\n>/< : Indent / Dedent" },
    V = { title = "Visual Line (Shift+v)", text = "V : Start Line Mode\nj/k : Extend selection\n} : Extend Paragraph\n= : Auto-indent\nJ : Join lines" },
    ["^v"] = { title = "Visual Block (Ctrl+v)", text = "^v : Start Block Mode\nI : Insert on ALL lines\nA : Append on ALL lines\nc : Change block\n$ : Extend to end" },
    g = { title = "Go / Extended (g...)", text = "-- Nav --\ngg : Top of file\nG : Bottom of file\ngi : Last insert spot\ngv : Reselect Visual\ngd : Go definition\n-- Format --\ngq : Format paragraph\ngu/gU : Lower/Upper case" },
    z = { title = "Folds & View (z...)", text = "-- Scroll --\nzz : Center screen\nzt/zb : Top/Bottom screen\n-- Folds --\nzo/zc : Open/Close fold\nza : Toggle fold\nzM/zR : Close/Open ALL" },
    m = { title = "Marks (m...)", text = "m{a-z} : Set local mark\nm{A-Z} : Set GLOBAL mark\n'{a-z} : Jump to mark line\n`{a-z} : Jump to mark pos" },
    q = { title = "Macros (q)", text = "q{a-z} : Record to register\nq : Stop recording\n@{a-z} : Replay macro\n@@ : Replay last macro" },
    ["^w"] = { title = "Window (Ctrl+w ...)", text = "-- Split --\nv/s : Vert/Horiz Split\n-- Move --\nh/j/k/l : Move Focus\nw : Cycle\n-- Actions --\nc : Close Window\n= : Equalize sizes" },
}

menus.tooltips = {
    toggle_master = "Enable/Disable Vimualizer",
    toggle_hud = "Show key hint suggestions",
    toggle_buffer = "Show typed key history",
    toggle_action = "Explain what keys do",
    toggle_entry = "Escape key help menu",
    toggle_macro = "Allow macro recording (q)",
    toggle_aerospace = "Option/Alt window commands",
    toggle_tooltips = "Toggle these help cards",
    toggle_ghost = "Fade UI when inactive",
    toggle_trainer = "Practice Vim motions with challenges",
    toggle_snippets = "Expand custom triggers (e.g. ;date) while typing",
    btn_manage_snippets = "Add or remove expansion snippets",
    btn_analytics = "View efficiency stats & heatmap"
}

return menus
