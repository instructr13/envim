return {
  {
    "lewis6991/gitsigns.nvim",

    version = "*",

    opts = {
      signcolumn = true,
      numhl = false,
      linehl = false,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local presets = require("base.utils.keymap.presets")

        local leader_visual_keymap = presets.leader("x", "g", {
          buffer = bufnr,
          silent = true,
        })

        local leader_keymap = presets.leader("n", "g", { buffer = bufnr })
        local keymap = presets.mode_only("n", { buffer = bufnr, expr = true })

        -- Navigation
        keymap("]c", function()
          if vim.wo.diff then
            return "]c"
          end

          vim.schedule(function()
            gs.next_hunk()
          end)

          return "<Ignore>"
        end, "Next Hunk")

        keymap("[c", function()
          if vim.wo.diff then
            return "[c"
          end

          vim.schedule(function()
            gs.prev_hunk()
          end)

          return "<Ignore>"
        end, "Previous Hunk")

        -- Actions
        local function selection()
          return { vim.fn.line("."), vim.fn.line("v") }
        end

        -- stage_hunk toggles, so it also unstages
        leader_keymap("s", gs.stage_hunk, "Stage / Unstage Hunk")
        leader_keymap("r", gs.reset_hunk, "Reset Hunk")
        leader_visual_keymap("s", function()
          gs.stage_hunk(selection())
        end, "Stage / Unstage Lines")
        leader_visual_keymap("r", function()
          gs.reset_hunk(selection())
        end, "Reset Lines")

        leader_keymap("S", gs.stage_buffer, "Stage Buffer")
        leader_keymap("R", gs.reset_buffer, "Reset Buffer")
        leader_keymap("p", gs.preview_hunk, "Preview Hunk")
        leader_keymap("B", function()
          gs.blame_line({
            full = true,
          })
        end, "Blame Line")
        leader_keymap(
          "T",
          gs.toggle_current_line_blame,
          "Toggle Current Line Blame"
        )
        leader_keymap("d", gs.diffthis, "Diff This")
        leader_keymap("D", function()
          gs.diffthis("~")
        end, "Diff Current Buffer")
        leader_keymap("t", gs.toggle_deleted, "Toggle Deleted")
        leader_keymap("b", gs.blame, "Blame Buffer")
        leader_keymap("q", function()
          gs.setqflist("all")
        end, "Hunks to Quickfix")

        -- Text object
        require("base.utils.keymap").keymap(
          { "o", "x" },
          "ih",
          function()
            vim.cmd("Gitsigns select_hunk")
          end,
          "Select Hunk",
          {
            buffer = bufnr,
            silent = true,
          }
        )
      end,
      watch_gitdir = {
        follow_files = true,
      },
      diff_opts = {
        algorithm = "histogram",
      },
      attach_to_untracked = true,
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        delay = 400,
      },
      preview_config = {
        border = "rounded",
        relative = "cursor",
        row = 0,
        col = 1,
      },
    },
  },
  {
    "sindrets/diffview.nvim",

    lazy = true,

    cmd = { "DiffviewOpen", "DiffviewFileHistory" },

    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diff view" },
      {
        "<leader>gh",
        "<cmd>DiffviewFileHistory %<cr>",
        desc = "File history",
      },
    },
  },
  {
    "NeogitOrg/neogit",

    lazy = true,

    cmd = { "Neogit" },

    init = function()
      local keymap = require("base.utils.keymap").keymap

      keymap("n", "<leader>gg", "<cmd>Neogit<cr>", "Open Neogit")
      keymap("n", "<leader>gl", "<cmd>Neogit log<cr>", "Git log")
      keymap("n", "<leader>gc", "<cmd>Neogit commit<cr>", "Git commit")
    end,

    opts = {
      integrations = {
        diffview = true,
      },
    },
  },
}
