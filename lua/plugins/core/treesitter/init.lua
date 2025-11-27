local C = require("plugins.core.treesitter.config")

return {
  {
    "nvim-treesitter/nvim-treesitter",

    branch = "main",

    lazy = false,

    build = ":TSUpdate",

    init = function()
      C.treesitter_init()
    end,

    config = function()
      C.treesitter()
    end,
  },
  {
    "CKolkey/ts-node-action",

    lazy = true,

    cmd = "NodeAction",

    init = function()
      local keymap = require("base.utils.keymap").keymap

      keymap("n", "<C-s>", function()
        require("ts-node-action").node_action()
      end, "Trigger Node Action")
    end,

    opts = {},
  },
  {
    "aaronik/treewalker.nvim",

    lazy = true,

    cmd = "Treewalker",

    init = function()
      local keymap = require("base.utils.keymap").keymap

      keymap({ "n", "v" }, "<C-h>", function()
        vim.cmd("Treewalker Left")
      end, "Treewalker (Left)")

      keymap({ "n", "v" }, "<C-j>", function()
        vim.cmd("Treewalker Down")
      end, "Treewalker (Down)")

      keymap({ "n", "v" }, "<C-k>", function()
        vim.cmd("Treewalker Up")
      end, "Treewalker (Up)")

      keymap({ "n", "v" }, "<C-l>", function()
        vim.cmd("Treewalker Right")
      end, "Treewalker (Right)")

      keymap("n", "<C-S-h>", function()
        vim.cmd("Treewalker SwapLeft")
      end, "Treewalker (Swap Left)")

      keymap("n", "<C-S-j>", function()
        vim.cmd("Treewalker SwapDown")
      end, "Treewalker (Swap Down)")

      keymap("n", "<C-S-k>", function()
        vim.cmd("Treewalker SwapUp")
      end, "Treewalker (Swap Up)")

      keymap("n", "<C-S-l>", function()
        vim.cmd("Treewalker SwapRight")
      end, "Treewalker (Swap Right)")
    end,

    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",

    branch = "main",

    dependencies = { "nvim-treesitter/nvim-treesitter" },

    lazy = false,

    opts = {},
  },
}
