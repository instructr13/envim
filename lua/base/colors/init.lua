-- The only module that knows which colorscheme is in use. Other modules ask
-- for semantic colors through `palette()`.

local M = {}

M.colorscheme = "catppuccin"

function M.set_colorscheme()
  vim.cmd.colorscheme(M.colorscheme)
end

---@param color integer|string 0xRRGGBB or "#rrggbb"
---@return integer[]
local function to_rgb(color)
  if type(color) == "string" then
    color = tonumber(color:sub(2), 16)
  end

  return {
    bit.rshift(color, 16),
    bit.band(bit.rshift(color, 8), 0xff),
    bit.band(color, 0xff),
  }
end

---Mix two colors: `from` at 0, `to` at 1
---@param from integer|string 0xRRGGBB or "#rrggbb"
---@param to integer|string
---@param alpha number 0..1
---@return integer
function M.blend(from, to, alpha)
  local a, b = to_rgb(from), to_rgb(to)
  local rgb = {}

  for i = 1, 3 do
    rgb[i] = math.floor(a[i] + (b[i] - a[i]) * alpha + 0.5)
  end

  return rgb[1] * 0x10000 + rgb[2] * 0x100 + rgb[3]
end

---Resolved (link-free) definition of a highlight group
---@param name string
---@return vim.api.keyset.get_hl_info
function M.hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

---Run `fn` after every colorscheme change (and now, with `opts.run`).
---`opts.schedule` waits until the colorscheme's own handlers (e.g. a plugin
---redefining its groups) have run. Registering the same `group` again
---replaces the previous handler.
---@param group string augroup name
---@param fn fun()
---@param opts? { run?: boolean, schedule?: boolean }
function M.on_change(group, fn, opts)
  opts = opts or {}

  local callback = opts.schedule and vim.schedule_wrap(fn)
    or function()
      fn()
    end

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup(group, { clear = true }),
    callback = callback,
  })

  if opts.run then
    fn()
  end
end

---@class base.colors.Palette
---@field text string Main text
---@field subtle string Secondary text (statusline)
---@field muted string De-emphasized text
---@field faint string Inactive indicators
---@field border string Separators
---@field bar_bg string Background of bars (statusline)
---@field bright_bg string Raised background
---@field red string
---@field orange string
---@field yellow string
---@field green string
---@field blue string
---@field purple string

---@return base.colors.Palette
function M.palette()
  local c = require("catppuccin.palettes").get_palette()

  return {
    text = c.text,
    subtle = c.subtext1,
    muted = c.overlay0,
    faint = c.surface1,
    border = c.surface0,
    bar_bg = c.mantle,
    bright_bg = c.surface0,
    red = c.red,
    orange = c.peach,
    yellow = c.yellow,
    green = c.green,
    blue = c.blue,
    purple = c.mauve,
  }
end

---Mode name -> color, shared by the statusline's mode block and the
---line number color of modicator.nvim
---@return table<"normal"|"insert"|"visual"|"replace"|"command"|"terminal", string>
function M.mode_colors()
  local p = M.palette()

  return {
    normal = p.blue,
    insert = p.green,
    visual = p.purple,
    replace = p.red,
    command = p.orange,
    terminal = p.green,
  }
end

---Highlights for bufferline.nvim, with the tab bar filled like the statusline
function M.bufferline_highlights()
  return require("catppuccin.special.bufferline").get_theme({
    custom = {
      all = {
        fill = {
          bg = { attribute = "bg", highlight = "StatusLine" },
        },
      },
    },
  })
end

return M
