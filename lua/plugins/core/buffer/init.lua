return {
  {
    "nvim-mini/mini.bufremove",

    lazy = true,

    init = function()
      local keymap = require("base.utils.keymap").keymap

      local function close()
        require("mini.bufremove").delete()
      end

      keymap("n", "<leader>q", close, "Close buffer")
      keymap("n", "<leader>bd", close, "Close buffer")

      keymap("n", "<leader>bD", function()
        require("mini.bufremove").delete(0, true)
      end, "Close buffer (discard changes)")
    end,
  },
}
