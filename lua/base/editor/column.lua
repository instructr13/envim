-- 'colorcolumn' drawn as a thin line that fades in while typing.

local api = vim.api

local M = {}

local char = "│"
local threshold = 0.75
local hl_group = "FadeColumn"

local ns = api.nvim_create_namespace("fade_column")

local state = { alpha = nil, active = false }

local function set_hl(alpha)
  if state.alpha == alpha then
    return
  end

  state.alpha = alpha

  local hl = require("base.colors").hl
  local bg = hl("Normal").bg or 0
  local fg = hl("NonText").fg or 0x808080

  api.nvim_set_hl(
    0,
    hl_group,
    { fg = require("base.colors").blend(bg, fg, alpha) }
  )
end

---@return integer[]
local function columns(win, buf)
  local tw = vim.bo[buf].textwidth
  local result = {}

  for item in vim.gsplit(vim.wo[win].colorcolumn, ",", { trimempty = true }) do
    local sign, n = item:match("^([+-]?)(%d+)$")
    n = tonumber(n)

    if n then
      if sign == "" then
        table.insert(result, n)
      elseif tw > 0 then
        table.insert(result, sign == "+" and tw + n or tw - n)
      end
    end
  end

  return result
end

local function is_target(win, buf)
  local mode = api.nvim_get_mode().mode

  return (mode:find("^i") or mode:find("^R"))
    and api.nvim_win_get_config(win).relative == ""
    and vim.bo[buf].buftype == ""
end

-- Fade amount for the current line in the current window, or nil to hide
local function current_alpha(win, buf)
  local cols = columns(win, buf)

  if #cols == 0 then
    return nil
  end

  local col = math.min(unpack(cols))
  local width = vim.fn.strdisplaywidth(api.nvim_get_current_line())
  local start = col * threshold

  if width < start then
    return nil
  end

  return math.min(1, (width - start) / math.max(1, col - 1 - start))
end

local function update()
  local win, buf = api.nvim_get_current_win(), api.nvim_get_current_buf()
  local alpha = is_target(win, buf) and current_alpha(win, buf) or nil
  local active = alpha ~= nil

  if active then
    set_hl(alpha)
  end

  if active or state.active then
    state.active = active
    api.nvim__redraw({ win = win, valid = false })
  end
end

function M.setup()
  local function hide_native()
    api.nvim_set_hl(0, "ColorColumn", {})
    state.alpha = nil
  end

  require("base.colors").on_change(
    "fade_column_colors",
    hide_native,
    { run = true }
  )

  api.nvim_create_autocmd(
    { "InsertEnter", "InsertLeave", "TextChangedI", "CursorMovedI" },
    {
      group = api.nvim_create_augroup("fade_column", { clear = true }),
      callback = update,
    }
  )

  -- Drawn per window / line while redrawing (only for the current window)
  local cols, leftcol, width

  api.nvim_set_decoration_provider(ns, {
    on_win = function(_, win, buf)
      if not state.active or win ~= api.nvim_get_current_win() then
        return false
      end

      cols = columns(win, buf)
      leftcol = vim.fn.winsaveview().leftcol
      width = api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff
    end,
    on_line = function(_, _, buf, row)
      local line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
      local line_width = vim.fn.strdisplaywidth(line)

      for _, col in ipairs(cols) do
        local win_col = col - 1 - leftcol

        -- Don't cover text
        if win_col >= 0 and win_col < width and line_width < col then
          api.nvim_buf_set_extmark(buf, ns, row, 0, {
            virt_text = { { char, hl_group } },
            virt_text_win_col = win_col,
            hl_mode = "combine",
            ephemeral = true,
            priority = 1,
          })
        end
      end
    end,
  })
end

return M
