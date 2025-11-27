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
