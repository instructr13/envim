local C = require("plugins.core.treesitter.config")

return {
  {
    "nvim-treesitter/nvim-treesitter",

    branch = "main",

    lazy = false,

    build = ":TSUpdate",

    config = function()
      C.treesitter()
    end,
  },
  {
    "Wansmer/treesj",

    lazy = true,

    keys = {
      {
        "<C-s>",
        function()
          require("treesj").toggle()
        end,
        mode = "n",
        desc = "Toggle split or join",
      },
    },

    opts = {},
  },
  {
    "aaronik/treewalker.nvim",

    lazy = true,

    cmd = "Treewalker",

    init = function()
      local keymap = require("base.utils.keymap").keymap

      for key, dir in pairs({ h = "Left", j = "Down", k = "Up", l = "Right" }) do
        keymap({ "n", "x" }, "<C-" .. key .. ">", function()
          vim.cmd.Treewalker(dir)
        end, "Treewalker (" .. dir .. ")")

        keymap("n", "<C-S-" .. key .. ">", function()
          vim.cmd.Treewalker("Swap" .. dir)
        end, "Treewalker (Swap " .. dir .. ")")
      end
    end,

    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",

    branch = "main",

    event = "VeryLazy",

    opts = {
      move = { set_jumps = true },
    },

    config = function(_, opts)
      require("nvim-treesitter-textobjects").setup(opts)

      C.textobjects()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",

    event = "VeryLazy",

    opts = {
      max_lines = 3,
      multiline_threshold = 1,
    },
  },
}
