local C = require("plugins.core.fold.config")

return {
  {
    "jghauser/fold-cycle.nvim",

    lazy = true,

    init = function()
      C.fold_cycle_init()
    end,

    opts = {},
  },
}
