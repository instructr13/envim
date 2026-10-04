local function neovide_setup()
  vim.opt.linespace = 12
  vim.opt.winblend = 24

  vim.g.neovide_theme = "auto"

  vim.g.neovide_cursor_animation_length = 0.05

  vim.g.neovide_hide_mouse_when_typing = true

  require("base.colors").on_change("neovide_title", function()
    local bg = require("base.colors").hl("Normal").bg

    if bg then
      vim.g.neovide_title_background_color = string.format("%06x", bg)
    end
  end)

  vim.g.neovide_show_border = true
  vim.g.experimental_layer_grouping = true
  vim.g.neovide_input_macos_option_key_is_meta = "only_left"
  vim.g.neovide_input_ime = false
  vim.g.neovide_unlink_border_highlights = true
  vim.g.neovide_cursor_trail_size = 0
  vim.g.neovide_cursor_animate_in_insert_mode = false
  vim.g.neovide_cursor_animate_command_line = false
  vim.g.neovide_cursor_smooth_blink = true

  local function set_ime(args)
    if args.event:match("Enter$") then
      vim.g.neovide_input_ime = true
    else
      vim.g.neovide_input_ime = false
    end
  end

  local ime_input = vim.api.nvim_create_augroup("ime_input", { clear = true })

  vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
    group = ime_input,
    pattern = "*",
    callback = set_ime,
  })

  vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineLeave" }, {
    group = ime_input,
    pattern = "[/\\?]",
    callback = set_ime,
  })

  local keymap = require("base.utils.keymap").keymap

  keymap("v", "<D-c>", '"+y', "Copy to clipboard")
  keymap("v", "<C-S-c>", '"+y', "Copy to clipboard")
  keymap({ "i", "c" }, "<C-S-v>", "<C-r><C-o>+", "Paste from clipboard")
  keymap({ "i", "c" }, "<D-v>", "<C-r><C-o>+", "Paste from clipboard")
  keymap("n", "<C-S-v>", '"+p', "Paste from clipboard")
  keymap("n", "<D-v>", '"+p', "Paste from clipboard")
end

vim.opt.number = true
-- Absolute in Insert mode only (see base.editor.autocommand, <leader>tl)
vim.opt.relativenumber = true
vim.opt.foldcolumn = "1"
vim.opt.signcolumn = "auto:2-3"
vim.opt.winborder = "rounded"
vim.opt.cmdheight = 0
vim.opt.laststatus = 3

if not vim.g.vscode then
  -- Private API: warn instead of silently losing the new cmdline / messages
  local ok, err = pcall(function()
    require("vim._core.ui2").enable({})
  end)

  if not ok then
    vim.notify_once("ui2 could not be enabled: " .. err, vim.log.levels.WARN)
  end
end

-- foldmethod / foldexpr are set per window when Treesitter or LSP attaches
vim.opt.foldlevel = 9999
vim.opt.foldlevelstart = 9999
vim.opt.foldtext = ""

-- Make the settings do not override editorconfig
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 0
vim.opt.shiftround = true
vim.opt.softtabstop = -1

vim.opt.mouse = "a"
vim.opt.mousemoveevent = true

vim.opt.updatetime = 250
vim.opt.redrawtime = 1500
vim.opt.timeoutlen = 350
vim.opt.ttimeoutlen = 10

vim.opt.showmode = false
-- Pending keys and the Visual selection size, shown by the statusline
-- (cmdheight is 0, so there is no room for them elsewhere)
vim.opt.showcmdloc = "statusline"
vim.opt.history = 10000

vim.opt.wrapscan = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.infercase = true

vim.opt.inccommand = "nosplit"

vim.opt.textwidth = 80
vim.opt.colorcolumn = "+1"

vim.opt.wrap = false
vim.opt.breakindent = true

vim.opt.breakindentopt = {
  shift = 2,
  min = 20,
}

vim.opt.showbreak = "⌐"
vim.opt.cpoptions:append("n")

vim.opt.whichwrap = {
  b = true,
  s = true,
  ["<"] = true,
  [">"] = true,
  ["["] = true,
  ["]"] = true,
  h = true,
  l = true,
}

vim.opt.hidden = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.switchbuf = "useopen"

vim.opt.smartindent = true

vim.opt.shortmess:append("cmsW")

vim.opt.pumheight = 10
vim.opt.winminwidth = 5
vim.opt.winaltkeys = "no"

vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 16

vim.opt.tabclose = "left"
vim.opt.showtabline = 0

vim.opt.cursorline = true
vim.opt.guicursor:append("n-v-c:blinkon1000-blinkoff1000")
vim.opt.concealcursor = "nc"
vim.opt.virtualedit = "block"

vim.opt.formatoptions:remove("cro")
vim.opt.formatoptions:append("1Mjlmnq")

-- ftplugins re-add "cro" after FileType
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("formatoptions", { clear = true }),
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

vim.opt.matchpairs = {
  "(:)",
  "{:}",
  "[:]",
  "「:」",
  "（:）",
  "【:】",
  "『:』",
  "［:］",
  "｛:｝",
  "《:》",
  "〈:〉",
  "‘:’",
  "“:”",
}

vim.opt.jumpoptions = { "stack", "clean" }

vim.opt.fillchars = {
  eob = " ",
  foldopen = "",
  foldsep = " ",
  foldclose = "",
  diff = "╱",
}

vim.opt.list = true
vim.opt.listchars = {
  tab = "  ",
  trail = "•",
  nbsp = "␣",
  precedes = "<",
  extends = ">",
}

vim.opt.viewoptions = {
  "cursor",
  "folds",
  "curdir",
  "slash",
  "unix",
}

vim.opt.synmaxcol = 2500

-- backup is executed by other plugin
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.confirm = true

vim.opt.autowrite = true
vim.opt.writeany = true

vim.opt.sessionoptions = {
  "buffers",
  "curdir",
  "folds",
  "globals",
  "help",
  "winsize",
  "winpos",
  "tabpages",
  "terminal",
}

vim.opt.errorbells = false

vim.opt.exrc = true
vim.opt.secure = true

vim.opt.undofile = true

vim.opt.spelllang:append("cjk")

vim.opt.conceallevel = 2

vim.opt.splitkeep = "screen"

vim.opt.swapfile = false

vim.opt.smoothscroll = true

if vim.g.neovide then
  neovide_setup()
end
