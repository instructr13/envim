local C = require("plugins.normal.lsp.config")

return {
  {
    "mason-org/mason.nvim",

    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",

    lazy = true,

    event = { "VeryLazy" },

    dependencies = {
      "williamboman/mason.nvim",
      {
        "neovim/nvim-lspconfig",

        config = function()
          local keymap = require("base.utils.keymap").keymap

          keymap("n", "<leader>lI", function()
            vim.cmd("LspInfo")
          end, "LSP Information", { silent = true })
        end,
      },
    },

    opts = {},
  },
  {
    "stevearc/conform.nvim",

    lazy = true,

    event = { "BufWritePre" },

    cmd = { "ConformInfo" },

    init = function()
      C.conform_init()
    end,

    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = function(bufnr)
        return C.conform_format_on_save(bufnr)
      end,
      notify_no_formatters = false,
    },
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",

    lazy = true,

    event = { "VeryLazy" },

    opts = {
      show_source = {
        enabled = true,
      },
      multilines = {
        enabled = true,
      },
      use_icons_from_diagnostic = true,
      enable_on_select = true,
      show_all_diags_on_cursorline = true,
    },
  },
  {
    "KostkaBrukowa/definition-or-references.nvim",

    lazy = true,

    opts = {},
  },
  {
    "oribarilan/lensline.nvim",

    version = "*",

    event = { "LspAttach" },

    opts = {},
  },
  {
    "saecki/live-rename.nvim",

    lazy = true,

    opts = {},
  },
}
