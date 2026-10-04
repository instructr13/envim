local C = require("plugins.normal.lsp.config")

return {
  {
    -- Adds Mason's bin directory to $PATH; servers are enabled by
    -- base.lsp.auto_enable
    "mason-org/mason.nvim",

    -- Must load at startup to put its bin directory on $PATH
    lazy = false,

    keys = {
      { "<leader>pm", "<cmd>Mason<cr>", desc = "Tool installer (Mason)" },
    },

    opts = {},
  },
  {
    -- Only used for its per-server fixes (mason-lspconfig.lsp.*)
    "mason-org/mason-lspconfig.nvim",

    lazy = true,

    event = { "VeryLazy" },

    dependencies = { "mason-org/mason.nvim" },

    opts = {
      automatic_enable = false,
    },
  },
  {
    -- Provides lsp/*.lua configs for vim.lsp.config
    "neovim/nvim-lspconfig",

    lazy = false,

    config = function()
      local keymap = require("base.utils.keymap").keymap

      keymap(
        "n",
        "<leader>lI",
        "<cmd>checkhealth vim.lsp<cr>",
        "LSP Information"
      )
      keymap("n", "<leader>lr", "<cmd>lsp restart<cr>", "Restart LSP")
      keymap("n", "<leader>ls", "<cmd>lsp stop<cr>", "Stop LSP")
      keymap("n", "<leader>ll", function()
        vim.cmd.edit(vim.lsp.log.get_filename())
      end, "LSP log")
      keymap("n", "<leader>lF", "<cmd>ConformInfo<cr>", "Formatter info")
    end,
  },
  {
    "stevearc/conform.nvim",

    lazy = true,

    event = { "BufWritePre" },

    cmd = { "ConformInfo" },

    init = function()
      C.conform_init()
    end,

    opts = function()
      return {
        -- Built from installed tools; filetypes without a formatter fall
        -- back to LSP formatting
        formatters_by_ft = C.formatters_by_ft(),
        default_format_opts = {
          lsp_format = "fallback",
          stop_after_first = true,
        },
        format_on_save = function(bufnr)
          return C.conform_format_on_save(bufnr)
        end,
        notify_no_formatters = false,
      }
    end,

    config = function(_, opts)
      require("conform").setup(opts)

      require("base.tools").on_install(function()
        require("conform").formatters_by_ft = C.formatters_by_ft()
      end)
    end,
  },
  {
    "mfussenegger/nvim-lint",

    lazy = true,

    event = { "BufReadPost", "BufNewFile", "BufWritePost" },

    config = function()
      C.lint_setup()
    end,
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
  {
    "rachartier/tiny-code-action.nvim",

    lazy = true,

    dependencies = { "nvim-lua/plenary.nvim" },

    opts = {
      picker = "buffer",
    },
  },
  {
    "dnlhc/glance.nvim",

    cmd = { "Glance" },

    opts = {},
  },
  {
    "chrisgrieser/nvim-lsp-endhints",

    event = { "LspAttach" },

    opts = {},
  },
}
