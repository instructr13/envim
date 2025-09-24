return {
  {
    "nvim-mini/mini.bufremove",

    lazy = true,

    init = function()
      local keymap = require("base.utils.keymap").keymap

      keymap("n", "<leader>q", function()
        require("mini.bufremove").delete()
      end, "Close buffer")
    end,
  },
}
