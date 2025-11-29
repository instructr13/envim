local M = {}

function M.setup()
  require("base.core.options")
  require("base.editor.autocommand")
  require("base.editor.keymap")

  require("base.core.bootstrap").setup()

  require("base.colors").set_colorscheme()

  require("base.lsp").setup()

  require("base.editor").cd()
end

return M
