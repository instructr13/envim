local C = require("plugins.core.editor.config")

return {
  {
    "chrisgrieser/nvim-spider",

    lazy = true,

    init = function()
      C.spider_init()
    end,
  },
  {
    "nvim-mini/mini.ai",

    version = "*",

    opts = function()
      local ik = require("base.utils.keymap").omit(
        "append",
        { "x", "o" },
        "ij",
        { remap = true }
      )

      local ak = require("base.utils.keymap").omit(
        "append",
        { "x", "o" },
        "aj",
        { remap = true }
      )

      ik("[", "i?「<cr>」<cr>")
      ak("[", "a?「<cr>」<cr>")

      ik("<", "i?＜<cr>＞<cr>")
      ak("<", "a?＜<cr>＞<cr>")
      ik("{", "i?｛<cr>｝<cr>")
      ak("{", "a?｛<cr>｝<cr>")

      return {}
    end,
  },
  {
    "monaqa/dial.nvim",

    lazy = true,

    init = function()
      C.dial_init()
    end,
  },
  {
    "nvim-mini/mini.surround",

    opts = {},
  },
  {

    "folke/flash.nvim",

    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesiteer Search",
      },
      "f",
      "F",
      "t",
      "T",
    },
    opts = {
      modes = {
        char = {
          jump_labels = true,
        },
      },
    },
  },
  {
    "numToStr/Comment.nvim",

    keys = {
      { "gc", mode = { "n", "v" } },
      "gb",
      "gcO",
      "gco",
      "gcA",
    },

    opts = function()
      return {
        pre_hook = require(
          "ts_context_commentstring.integrations.comment_nvim"
        ).create_pre_hook(),
      }
    end,

    dependencies = {
      {
        "JoosepAlviste/nvim-ts-context-commentstring",

        enabled = not vim.g.vscode,

        opts = {
          enable_autocmd = false,
        },
      },
    },
  },
  {
    "chrisgrieser/nvim-puppeteer",

    lazy = false,
  },
  {
    "chrisgrieser/nvim-recorder",

    opts = {
      lessNotifications = true,
    },
  },
}
