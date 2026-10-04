return {
  {
    "ibhagwan/fzf-lua",

    cmd = "FzfLua",

    dependencies = { "nvim-tree/nvim-web-devicons" },

    keys = {
      { "<leader><space>", "<cmd>FzfLua files<cr>", desc = "Find files" },
      { "<leader>/", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
      { "<leader>,", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
      {
        "<leader>fw",
        "<cmd>FzfLua grep_cword<cr>",
        desc = "Grep word under cursor",
      },
      {
        "<leader>fw",
        "<cmd>FzfLua grep_visual<cr>",
        mode = "x",
        desc = "Grep selection",
      },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>fo", "<cmd>FzfLua oldfiles<cr>", desc = "Recent files" },
      { "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Help tags" },
      { "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
      { "<leader>fc", "<cmd>FzfLua commands<cr>", desc = "Commands" },
      {
        "<leader>f:",
        "<cmd>FzfLua command_history<cr>",
        desc = "Command history",
      },
      { '<leader>f"', "<cmd>FzfLua registers<cr>", desc = "Registers" },
      { "<leader>fm", "<cmd>FzfLua marks<cr>", desc = "Marks" },
      { "<leader>fj", "<cmd>FzfLua jumps<cr>", desc = "Jump list" },
      { "<leader>fq", "<cmd>FzfLua quickfix<cr>", desc = "Quickfix list" },
      { "<leader>fH", "<cmd>FzfLua highlights<cr>", desc = "Highlight groups" },
      { "<leader>fM", "<cmd>FzfLua manpages<cr>", desc = "Man pages" },
      {
        "<leader>ft",
        function()
          require("todo-comments.fzf").todo()
        end,
        desc = "Todo comments",
      },
      { "<leader>fr", "<cmd>FzfLua resume<cr>", desc = "Resume last picker" },
      {
        "<leader>fs",
        "<cmd>FzfLua lsp_document_symbols<cr>",
        desc = "Document symbols",
      },
      {
        "<leader>fS",
        "<cmd>FzfLua lsp_live_workspace_symbols<cr>",
        desc = "Workspace symbols",
      },
      {
        "<leader>fd",
        "<cmd>FzfLua diagnostics_document<cr>",
        desc = "Document diagnostics",
      },
      {
        "<leader>fD",
        "<cmd>FzfLua diagnostics_workspace<cr>",
        desc = "Workspace diagnostics",
      },
      { "<leader>f/", "<cmd>FzfLua blines<cr>", desc = "Search buffer" },
      {
        "<leader>gf",
        "<cmd>FzfLua git_status<cr>",
        desc = "Git changed files",
      },
    },

    opts = function()
      return {
        "default-title",
        winopts = {
          preview = {
            layout = "flex",
          },
        },
        lsp = {
          symbols = {
            -- Same kind icons as dropbar and completion; kinds missing from
            -- the table keep fzf-lua's own
            symbol_icons = require("base.constants.icons").kinds,
          },
        },
      }
    end,
  },
  {
    "stevearc/quicker.nvim",

    ft = "qf",

    keys = {
      {
        "<leader>xq",
        function()
          require("quicker").toggle()
        end,
        desc = "Toggle quickfix",
      },
      {
        "<leader>xl",
        function()
          require("quicker").toggle({ loclist = true })
        end,
        desc = "Toggle location list",
      },
    },

    opts = {
      keys = {
        {
          ">",
          function()
            require("quicker").expand({
              before = 2,
              after = 2,
              add_to_existing = true,
            })
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      },
    },
  },
  {
    "MagicDuck/grug-far.nvim",

    cmd = { "GrugFar", "GrugFarWithin" },

    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open()
        end,
        desc = "Search and replace",
      },
      {
        "<leader>sr",
        function()
          require("grug-far").with_visual_selection()
        end,
        mode = "x",
        desc = "Search and replace selection",
      },
      {
        "<leader>sf",
        function()
          require("grug-far").open({
            prefills = { paths = vim.fn.expand("%") },
          })
        end,
        desc = "Search and replace in file",
      },
      {
        "<leader>sw",
        function()
          require("grug-far").open({
            prefills = { search = vim.fn.expand("<cword>") },
          })
        end,
        desc = "Search and replace word",
      },
    },

    opts = {},
  },
  {
    -- Keep other buffers from opening in tool windows (quickfix, help,
    -- sidebars, panels, ...)
    "stevearc/stickybuf.nvim",

    event = "VeryLazy",

    opts = {
      get_auto_pin = function(bufnr)
        return require("plugins.normal.search.config").sticky_pin(bufnr)
      end,
    },

    config = function(_, opts)
      require("stickybuf").setup(opts)
      require("plugins.normal.search.config").pin_background_windows()
    end,
  },
}
