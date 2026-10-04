local M = {}

-- Tool windows of plugins in this config, pinned by filetype (in addition to
-- stickybuf's builtins: qf, help, grug-far, neogit, startuptime, ...)
local panel_filetypes = {
  -- diffview.nvim panels
  "DiffviewFiles",
  "DiffviewFileHistory",
  -- time-machine.nvim undo tree
  "time-machine-list",
}

-- Pinned only when opened as a split, so that using them as the main window
-- still lets `:edit` replace them
local split_filetypes = {
  "man",
  "checkhealth",
}

local function is_normal_win(win)
  return vim.api.nvim_win_get_config(win).relative == ""
end

local function is_split(win)
  local normal_wins =
    vim.iter(vim.api.nvim_tabpage_list_wins(0)):filter(is_normal_win):totable()

  return is_normal_win(win) and #normal_wins > 1
end

---@param bufnr integer
---@param win? integer Window showing the buffer (default: current)
---@return nil|"bufnr"|"buftype"|"filetype"
function M.sticky_pin(bufnr, win)
  win = win or vim.api.nvim_get_current_win()

  local builtin = vim.api.nvim_win_call(win, function()
    return require("stickybuf").should_auto_pin(bufnr)
  end)

  if builtin then
    return builtin
  end
  local ft, bt = vim.bo[bufnr].filetype, vim.bo[bufnr].buftype

  if vim.list_contains(panel_filetypes, ft) then
    return "filetype"
  end

  if not is_split(win) then
    return nil
  end

  if vim.list_contains(split_filetypes, ft) then
    return "filetype"
  end

  -- Terminal splits keep their own terminal
  if bt == "terminal" then
    return "bufnr"
  end

  -- oil.nvim as a sidebar (oil-bar.nvim, or any narrow split): directories
  -- stay in it, files open elsewhere
  if
    ft == "oil"
    and (vim.w[win].oil_sidebar or vim.api.nvim_win_get_width(win) <= 40)
  then
    return "filetype"
  end

  return nil
end

-- stickybuf only decides on BufEnter of the current window. Windows that are
-- filled without keeping focus (e.g. oil-bar's sidebar) are checked here.
function M.pin_background_windows()
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup(
      "stickybuf_background",
      { clear = true }
    ),
    callback = function(args)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(args.buf) then
          return
        end

        local stickybuf = require("stickybuf")

        for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
          if
            win ~= vim.api.nvim_get_current_win()
            and not stickybuf.is_pinned(win)
          then
            local pintype = M.sticky_pin(args.buf, win)

            if pintype then
              stickybuf.pin(win, { allow_type = pintype })
            end
          end
        end
      end)
    end,
  })
end

return M
