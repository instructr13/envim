return {
  {
    "nvim-telescope/telescope.nvim",

    cmd = { "Telescope" },

    dependencies = {
      "plenary.nvim",
    },

    init = function()
      local keymap = require("base.utils.keymap.presets").leader(
        "n",
        "f",
        { noremap = true }
      )

      keymap("f", "<cmd>Telescope find_files<cr>", "Find files")
      keymap("g", "<cmd>Telescope live_grep<cr>", "Live Grep")
      keymap("b", "<cmd>Telescope buffers<cr>", "Buffers")
      keymap("h", "<cmd>Telescope oldfiles<cr>", "Find recently opened files")
      keymap("t", "<cmd>Telescope treesitter<cr>", "Treesitter")
      keymap("c", "<cmd>Telescope commands<cr>", "Commands")
      keymap("m", "<cmd>Telescope marks<cr>", "Marks")
      keymap("q", "<cmd>Telescope quickfix<cr>", "Quickfix")
    end,

    opts = function()
      require("base.utils.telescope").load_registered_extensions()

      local actions = require("telescope.actions")
      local actions_layout = require("telescope.actions.layout")

      return {
        defaults = {
          winblend = 10,
          path_display = {
            shorten = {
              len = 1,
              exclude = { 3, 4, -1 },
            },
          },
          dynamic_preview_title = true,
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-o>"] = actions.select_vertical,
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<C-l>"] = actions_layout.toggle_preview,
              ["<C-d>"] = actions.preview_scrolling_up,
              ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-u>"] = actions.cycle_history_prev,
              ["<Esc>"] = actions.close,
              ["<cr>"] = actions.select_default + actions.center,
            },
          },
        },
      }
    end,
  },
}
