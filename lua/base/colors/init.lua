local M = {}

local colorscheme = "catppuccin"

function M.set_colorscheme()
  vim.cmd.colorscheme(colorscheme)
end

return M
