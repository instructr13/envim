-- a
-- b
-- c
-- Single definition of the <leader>t toggles: the keymaps (base.editor.keymap)
-- and the statusline's toggle area (plugins.normal.ui) both read from here.
-- Plugin modules are only touched inside callbacks.

local M = {}

---@class base.editor.Toggle
---@field key string Suffix of the <leader>t mapping; also the icon key
---@field name string
---@field get fun(): boolean
---@field set fun(value: boolean)

---@type base.editor.Toggle[]
local toggles = {
  {
    key = "w",
    name = "wrap",
    get = function()
      return vim.wo.wrap
    end,
    set = function(v)
      vim.wo.wrap = v
    end,
  },
  {
    key = "s",
    name = "spell",
    get = function()
      return vim.wo.spell
    end,
    set = function(v)
      vim.wo.spell = v
    end,
  },
  {
    key = "l",
    name = "relative line numbers",
    -- 'relativenumber' itself flips in Insert mode (base.editor.autocommand)
    get = function()
      return vim.g.relative_numbers
    end,
    set = function(v)
      vim.g.relative_numbers = v
      vim.go.relativenumber = v

      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.wo[win].number then
          vim.wo[win].relativenumber = v
        end
      end
    end,
  },
  {
    key = "c",
    name = "conceal",
    get = function()
      return vim.wo.conceallevel > 0
    end,
    set = function(v)
      vim.wo.conceallevel = v and 2 or 0
    end,
  },
  {
    key = "d",
    name = "diagnostics",
    get = function()
      return vim.diagnostic.is_enabled()
    end,
    set = function(v)
      vim.diagnostic.enable(v)
    end,
  },
  {
    key = "h",
    name = "inlay hints",
    get = function()
      return vim.lsp.inlay_hint.is_enabled()
    end,
    set = function(v)
      vim.lsp.inlay_hint.enable(v)
    end,
  },
  {
    key = "f",
    name = "format on save",
    -- :FormatDisable! sets the buffer-local flag, which also has to be
    -- cleared to turn formatting back on
    get = function()
      return not (vim.g.disable_autoformat or vim.b.disable_autoformat)
    end,
    set = function(v)
      vim.g.disable_autoformat = not v

      if v then
        vim.b.disable_autoformat = false
      end
    end,
  },
  {
    key = "b",
    name = "current line blame",
    get = function()
      -- Before gitsigns loads, its config still has the default from the spec
      local config = package.loaded["gitsigns.config"]

      if config then
        return config.config.current_line_blame
      end

      return true
    end,
    set = function(v)
      require("gitsigns").toggle_current_line_blame(v)
    end,
  },
  {
    key = "i",
    name = "inline completion",
    get = function()
      return vim.lsp.inline_completion.is_enabled()
    end,
    set = function(v)
      vim.lsp.inline_completion.enable(v)
    end,
  },
  {
    key = "g",
    name = "indent guides",
    -- blink.indent keeps its state in this variable; reading it avoids
    -- loading the plugin
    get = function()
      return vim.g.indent_guide ~= false
    end,
    set = function(v)
      require("blink.indent").enable(v)
    end,
  },
  {
    key = "v",
    name = "whitespace",
    get = function()
      return vim.wo.list
    end,
    set = function(v)
      vim.wo.list = v
    end,
  },
}

local by_key = {}

for _, t in ipairs(toggles) do
  by_key[t.key] = t
end

---@return base.editor.Toggle[]
function M.list()
  return toggles
end

---@param key string
---@return boolean
function M.get(key)
  return by_key[key].get() and true or false
end

---Flip a toggle, report it, and refresh the statusline. Most of these do not
---fire OptionSet, so the statusline has to be told explicitly.
---@param key string
function M.toggle(key)
  local t = by_key[key]
  local value = not M.get(key)

  t.set(value)
  -- A new toggle replaces the previous toggle notification (juu.nvim `key`)
  vim.notify(
    t.name .. ": " .. (value and "on" or "off"),
    vim.log.levels.INFO,
    { key = "toggle" }
  )
  vim.cmd.redrawstatus()
end

return M
