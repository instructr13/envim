-- Non-plugin-related keymaps

local keymap = require("base.utils.keymap").keymap
local constants = require("base.constants.buffers")

keymap("n", "<Space>", "<Nop>", "Leader")

vim.g.mapleader = " "
vim.g.maplocalleader = ","

local bufnr_keymap = function(bufnr)
  keymap("n", "<leader>" .. bufnr, function()
    local ok, bufferline = pcall(require, "bufferline")

    if not ok then
      vim.cmd.b(bufnr)

      return
    end

    bufferline.go_to(bufnr)
  end, "Buffer #" .. bufnr)
end

for i = 1, 9 do
  bufnr_keymap(i)
end

local function cycle_buffer(cmd)
  return function()
    if
      vim.list_contains(
        constants.window.ignore_buf_change_filetypes,
        vim.bo.filetype
      )
    then
      return
    end

    pcall(cmd)
  end
end

local bnext, bprevious =
  cycle_buffer(vim.cmd.bnext), cycle_buffer(vim.cmd.bprev)

keymap("n", "<Tab>", bnext, "Next Buffer")
keymap("n", "<S-Tab>", bprevious, "Previous Buffer")
keymap("n", "]b", bnext, "Next Buffer")
keymap("n", "[b", bprevious, "Previous Buffer")

-- join lines without moving the cursor (keeps the count, unlike `mzJ`z`)
keymap("n", "J", function()
  local view = vim.fn.winsaveview()

  vim.cmd.normal({ args = { math.max(vim.v.count1, 2) .. "J" }, bang = true })
  vim.fn.winrestview(view)
end, "Join lines")

-- better terminal esc
keymap("t", "<esc><esc>", [[<C-\><C-n>]], "Escape from Terminal")

-- split undo with
local function split_undo_keymap(key)
  keymap("i", key, key .. "<C-g>u", "Insert " .. key .. " and split undo")
end

for _, key in ipairs({ ";", ",", "!", ".", "?", "_" }) do
  split_undo_keymap(key)
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("quit_with_q", { clear = true }),
  pattern = constants.window.quit_with_q.filetypes,
  callback = function(e)
    keymap("n", "q", "<cmd>close<cr>", "Quit", { buffer = e.buf })
  end,
})

keymap(
  "n",
  "gl",
  vim.diagnostic.open_float,
  "Show diagnostics in a floating window"
)

keymap("c", "<C-f>", "<Nop>", "Disable command-line window")
keymap("n", "q:", "<Nop>", "Disable command-line window")

keymap("n", "<esc>", function()
  vim.cmd.nohlsearch()

  local ok, juu = pcall(require, "juu.notify")

  if ok and juu.clear then
    pcall(juu.clear)
  end
end, "Nohlsearch / Dismiss notifications")

-- Move by display lines; counted moves are added to the jumplist
local function vertical_move(key)
  return function()
    if vim.v.count == 0 then
      return "g" .. key
    end

    return "m'" .. vim.v.count .. key
  end
end

keymap(
  { "n", "x" },
  "j",
  vertical_move("j"),
  "Move cursor down",
  { expr = true }
)
keymap({ "n", "x" }, "k", vertical_move("k"), "Move cursor up", { expr = true })

-- split and vsplit
keymap("n", "-", "<cmd>split<cr>", "Split horizontally")
keymap("n", "|", "<cmd>vsplit<cr>", "Split vertically")

keymap("i", "<C-BS>", "<C-w>", "Kill word")

keymap("n", "x", function()
  local at_line_start = vim.api.nvim_win_get_cursor(0)[2] == 0

  if at_line_start and vim.api.nvim_get_current_line():match("^%s*$") then
    vim.cmd('normal! "_dd$')
  else
    vim.cmd("normal! " .. (vim.v.count > 0 and vim.v.count or "") .. '"_x')
  end
end, "Delete character without yanking")

keymap("x", "x", '"_x', "Delete character without yanking")

keymap({ "n", "x" }, "c", '"_c', "Change without yanking")
keymap({ "n", "x" }, "C", '"_C', "Change to end of line without yanking")

keymap("x", "<", "<gv", "Shift left and reselect")
keymap("x", ">", ">gv", "Shift right and reselect")

-- <C-r><C-o> inserts literally: no 'textwidth' wrapping or auto-indent
keymap({ "i", "c" }, "<C-v>", "<C-r><C-o>+", "Paste from clipboard")

local leader = require("base.utils.keymap.presets").leader("n", "")

leader("K", "<cmd>norm! K<cr>", "Keywordprg")

leader("bn", "<cmd>enew<cr>", "New buffer")

leader("Q", "<cmd>qa<cr>", "Quit all")

leader("cw", function()
  local view = vim.fn.winsaveview()

  vim.cmd([[keeppatterns %s/\s\+$//e]])
  vim.fn.winrestview(view)
end, "Trim trailing whitespace")

leader("xd", function()
  vim.diagnostic.setloclist({ open = true })
end, "Buffer diagnostics (location list)")
leader("xD", function()
  vim.diagnostic.setqflist({ open = true })
end, "Workspace diagnostics (quickfix)")

leader("ww", "<C-W>p", "Other window")
leader("wd", "<C-W>c", "Delete window")
leader("w-", "<C-W>s", "Split window below")
leader("w|", "<C-W>v", "Split window right")
leader("w=", "<C-W>=", "Equalize windows")
leader("wo", "<C-W>o", "Close other windows")
leader("wx", "<C-W>x", "Swap with next window")
leader("wT", "<C-W>T", "Move window to new tab")

leader("<tab>l", "<cmd>tablast<cr>", "Last Tab")
leader("<tab>f", "<cmd>tabfirst<cr>", "First Tab")
leader("<tab><tab>", "<cmd>tabnew<cr>", "New Tab")
leader("<tab>]", "<cmd>tabnext<cr>", "Next Tab")
leader("<tab>d", "<cmd>tabclose<cr>", "Close Tab")
leader("<tab>o", "<cmd>tabonly<cr>", "Close other tabs")
leader("<tab>[", "<cmd>tabprevious<cr>", "Previous Tab")

-- Toggles
local function toggle(lhs, name, get, set)
  leader("t" .. lhs, function()
    local value = not get()

    set(value)
    vim.notify(name .. ": " .. (value and "on" or "off"))
  end, "Toggle " .. name)
end

toggle("w", "wrap", function()
  return vim.wo.wrap
end, function(v)
  vim.wo.wrap = v
end)
toggle("s", "spell", function()
  return vim.wo.spell
end, function(v)
  vim.wo.spell = v
end)
toggle("l", "relative line numbers", function()
  return vim.g.relative_numbers
end, function(v)
  vim.g.relative_numbers = v
  vim.go.relativenumber = v

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.wo[win].number then
      vim.wo[win].relativenumber = v
    end
  end
end)
toggle("c", "conceal", function()
  return vim.wo.conceallevel > 0
end, function(v)
  vim.wo.conceallevel = v and 2 or 0
end)
toggle("d", "diagnostics", vim.diagnostic.is_enabled, vim.diagnostic.enable)
toggle(
  "h",
  "inlay hints",
  vim.lsp.inlay_hint.is_enabled,
  vim.lsp.inlay_hint.enable
)
toggle("f", "format on save", function()
  return not vim.g.disable_autoformat
end, function(v)
  vim.g.disable_autoformat = not v
end)
