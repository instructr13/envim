local M = {}

function M.setup()
  require("base.core.options")
  require("base.editor.keymap")

  require("base.core.bootstrap").setup()

  require("base.lsp").setup()

  require("base.editor").cd()
end

return M
