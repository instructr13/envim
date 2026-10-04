local C = require("plugins.normal.ui.config")

return {
  {
    -- Colorscheme; colors are exposed to other modules through base.colors
    "catppuccin/nvim",

    name = "catppuccin",

    priority = 1000,

    opts = {
      term_colors = true,
      no_bold = true,

      lsp_styles = {
        virtual_text = {
          errors = {},
          hints = {},
          warnings = {},
          information = {},
          ok = {},
        },
        underlines = {
          errors = { "undercurl" },
          hints = { "underdashed" },
          warnings = { "undercurl" },
          information = { "underline" },
        },
      },

      auto_integrations = true,

      integrations = {},
    },
  },
  {
    "rachartier/tiny-devicons-auto-colors.nvim",

    lazy = true,

    event = "VeryLazy",

    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },

    opts = function()
      return {
        colors = vim.tbl_values(require("base.colors").palette()),
      }
    end,
  },
  {
    -- vim.notify, LSP progress, vim.ui.input/select, and editor messages on
    -- top of ui2 (enabled in base.core.options)
    "dont-be-evil-company/juu.nvim",

    lazy = false,

    priority = 900,

    opts = {
      notify = {
        configs = {
          -- No box around each notification
          default = { borders = false },
        },
      },
      -- The cmdline is handled by tiny-cmdline.nvim
      cmdline = false,
      select = {
        backend = { "fzf_lua", "builtin" },
      },
    },
  },
  {
    -- Centered floating cmdline on top of ui2
    "rachartier/tiny-cmdline.nvim",

    lazy = false,

    config = function()
      require("tiny-cmdline").setup({
        -- Keep blink.cmp's cmdline menu attached to the floating window
        on_reposition = require("tiny-cmdline").adapters.blink,
      })
    end,
  },
  {
    "luukvbaal/statuscol.nvim",

    dependencies = {
      "lewis6991/gitsigns.nvim",
    },

    opts = function()
      local builtin = require("statuscol.builtin")

      return {
        bt_ignore = { "nofile", "terminal" },
        ft_ignore = { "oil" },
        relculright = true,
        segments = {
          {
            -- Code action available on the line (base.lsp.code_action)
            sign = {
              namespace = { "code_action_sign" },
              colwidth = 1,
              maxwidth = 1,
            },
            click = "v:lua.ScSa",
          },
          {
            text = { builtin.lnumfunc, " " },
            click = "v:lua.ScLa",
          },
          {
            sign = {
              name = { ".*" }, -- table of lua patterns to match the sign name against
              auto = true,
              wrap = true,
            },
          },
          {
            text = { builtin.foldfunc },
            click = "v:lua.ScFa",
          },
          { text = { " " } },
          {
            sign = {
              namespace = { "gitsigns" },
              colwidth = 1,
            },
            click = "v:lua.ScSa",
          },
          { text = { "▏" } },
        },
        clickhandlers = {
          code_action_sign = function(args)
            if args.button == "l" then
              require("base.utils.mouse").picker(function()
                require("tiny-code-action").code_action({})
              end)()
            end
          end,
        },
      }
    end,
  },
  {
    "nvim-mini/mini.animate",

    lazy = true,

    event = "VeryLazy",

    opts = {
      cursor = { enable = false },
      scroll = { enable = false },
    },
  },
  {
    -- Per-window diagnostics summary, floating at the top right
    "b0o/incline.nvim",

    lazy = true,

    event = { "VeryLazy" },

    config = function()
      C.incline()
    end,
  },
  {
    -- Statusline
    "rebelot/heirline.nvim",

    event = "BufEnter",

    dependencies = {
      {
        -- Mode, file info, command info and virtual env building blocks
        "Zeioth/heirline-components.nvim",

        opts = {},

        version = "*",
      },
    },

    config = function()
      C.statusline()
    end,
  },
  {
    -- Bufferline
    "akinsho/bufferline.nvim",

    version = "*",

    event = "BufEnter",

    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },

    opts = function()
      -- Set indicator color
      local function set_indicator_hl()
        vim.api.nvim_set_hl(0, "TabLineSel", {
          bg = require("base.colors").palette().red,
        })
      end

      require("base.colors").on_change(
        "bufferline_hl",
        set_indicator_hl,
        { run = true }
      )

      local keymap = require("base.utils.keymap").keymap

      keymap("n", "gb", function()
        require("bufferline").pick()
      end, "Pick Buffer")

      keymap(
        "n",
        "<leader>bo",
        "<cmd>BufferLineCloseOthers<cr>",
        "Close other buffers"
      )
      keymap("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", "Pin buffer")

      return {
        highlights = require("base.colors").bufferline_highlights(),
        options = {
          close_command = function(bufnr)
            require("mini.bufremove").delete(bufnr)
          end,
          right_mouse_command = "vertical sbuffer %d",
          indicator = {
            style = "underline",
          },
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(count, level)
            local text = vim.diagnostic.config().signs.text
            local severity = vim.diagnostic.severity

            if level:match("error") then
              return text[severity.ERROR] .. count
            elseif level:match("warning") then
              return text[severity.WARN] .. count
            end

            return ""
          end,
          get_element_icon = function(element)
            local icon, hl = require("nvim-web-devicons").get_icon_by_filetype(
              element.filetype,
              { default = false }
            )

            return icon, hl
          end,
          always_show_bufferline = false,
          hover = {
            enabled = true,
            delay = 200,
            reveal = { "close" },
          },
        },
      }
    end,
  },
  {
    "folke/which-key.nvim",

    lazy = true,

    event = { "VeryLazy" },

    opts = {
      preset = "helix",

      -- <leader> is split by concern; keep this in sync with CLAUDE.md
      spec = {
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Code", mode = { "n", "x" } },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git", mode = { "n", "x" } },
        { "<leader>l", group = "LSP" },
        { "<leader>m", group = "Markdown" },
        { "<leader>p", group = "Plugins" },
        { "<leader>s", group = "Search & replace", mode = { "n", "x" } },
        { "<leader>t", group = "Toggle" },
        { "<leader>u", group = "Undo history" },
        { "<leader>w", group = "Window" },
        { "<leader>x", group = "Lists (quickfix)" },
        { "<leader><tab>", group = "Tab" },
        -- Buffer jumps are noise in the popup
        { "<leader>1", hidden = true },
        { "<leader>2", hidden = true },
        { "<leader>3", hidden = true },
        { "<leader>4", hidden = true },
        { "<leader>5", hidden = true },
        { "<leader>6", hidden = true },
        { "<leader>7", hidden = true },
        { "<leader>8", hidden = true },
        { "<leader>9", hidden = true },
      },
    },
  },
  {
    "saghen/blink.indent",

    event = { "BufReadPre", "BufNewFile" },

    opts = {
      static = {
        char = "▏",
      },
      scope = {
        char = "▏",
      },
    },
  },
  {
    "y3owk1n/time-machine.nvim",

    cmd = {
      "TimeMachineToggle",
      "TimeMachinePurgeBuffer",
      "TimeMachinePurgeAll",
      "TimeMachineLogShow",
      "TimeMachineLogClear",
    },

    keys = {
      {
        "<leader>uu",
        "<cmd>TimeMachineToggle<cr>",
        desc = "Toggle tree",
      },
      {
        "<leader>ux",
        "<cmd>TimeMachinePurgeBuffer<cr>",
        desc = "Purge current buffer",
      },
      {
        "<leader>uX",
        "<cmd>TimeMachinePurgeAll<cr>",
        desc = "Purge all",
      },
      {
        "<leader>ul",
        "<cmd>TimeMachineLogShow<cr>",
        desc = "Show log",
      },
    },

    opts = {},
  },
  {
    "lewis6991/satellite.nvim",

    event = { "BufReadPost", "BufNewFile" },

    opts = {
      excluded_filetypes = { "oil", "help", "qf", "fzf", "grug-far" },
    },
  },
  {
    "nvim-zh/colorful-winsep.nvim",

    lazy = true,

    event = { "WinLeave" },

    opts = {},
  },
  {
    -- LSP / Treesitter / path breadcrumbs in the winbar
    "Bekaboo/dropbar.nvim",

    event = { "BufReadPost", "BufNewFile", "FileType" },

    dependencies = { "nvim-tree/nvim-web-devicons" },

    keys = {
      {
        "<leader>;",
        function()
          require("dropbar.api").pick()
        end,
        desc = "Pick symbol in winbar",
      },
    },

    opts = function()
      return C.dropbar()
    end,

    config = function(_, opts)
      require("dropbar").setup(opts)
      C.set_dropbar_hl()

      -- After dropbar has redefined its own groups
      require("base.colors").on_change(
        "dropbar_hl",
        C.set_dropbar_hl,
        { schedule = true }
      )
    end,
  },
  {
    "OXY2DEV/foldtext.nvim",

    event = "VeryLazy",

    -- Defaults already use Nerd Font icons (conventional-commit kinds)
    opts = {},
  },
  {
    -- Show whitespace inside the Visual selection
    "mcauley-penney/visual-whitespace.nvim",

    event = "ModeChanged *:[vV\22]",

    opts = {
      match_types = {
        lead = true,
        trail = true,
      },
      -- Same dot as 'listchars' trail
      list_chars = {
        space = "•",
        lead = "•",
        trail = "•",
      },
      -- No end-of-line marker
      fileformat_chars = { unix = "", mac = "", dos = "" },
    },

    init = function()
      -- Whitespace in the selection: dimmed like 'listchars' (NonText) on the
      -- selection background. Always-visible trailing whitespace uses the
      -- same look.
      local function set_hl()
        local hl = require("base.colors").hl

        vim.api.nvim_set_hl(0, "VisualNonText", {
          fg = hl("NonText").fg,
          bg = hl("Visual").bg,
        })
        vim.api.nvim_set_hl(0, "Whitespace", { link = "VisualNonText" })
      end

      -- Also runs after the plugin's own (default) VisualNonText definition
      require("base.colors").on_change("whitespace_hl", set_hl, { run = true })
    end,
  },
  {
    -- Mapped to K in base.lsp
    "Fildo7525/pretty_hover",

    lazy = true,

    opts = {},
  },
  {
    -- Search count ([2/5]) at the end of the current match's line
    "kevinhwang91/nvim-hlslens",

    event = "CmdlineEnter",

    init = function()
      -- Defined at startup so tiny-glimmer (VeryLazy) wraps these mappings
      local function search_key(key)
        vim.keymap.set("n", key, function()
          local ok, err = pcall(
            vim.cmd.normal,
            { args = { vim.v.count1 .. key .. "zv" }, bang = true }
          )

          -- E486 and friends: report like the built-in command, not as a
          -- Lua error
          if not ok then
            vim.api.nvim_echo(
              { { (err:gsub("^Vim[^:]*:", "")), "ErrorMsg" } },
              true,
              {}
            )

            return
          end

          require("hlslens").start()
        end, { desc = "Search " .. key })
      end

      for _, key in ipairs({ "n", "N", "*", "#", "g*", "g#" }) do
        search_key(key)
      end
    end,

    opts = function()
      return vim.tbl_extend("error", C.hlslens(), {
        enable_incsearch = false,
        calm_down = true,
        nearest_only = true,
        nearest_float_when = "never",
      })
    end,
  },
  {
    "nacro90/numb.nvim",

    lazy = true,

    event = { "CmdlineEnter" },

    opts = {},
  },
  {
    "rachartier/tiny-glimmer.nvim",

    lazy = true,

    event = { "VeryLazy" },

    priority = 10,

    opts = {
      overwrite = {
        -- Wraps the n / N / * / # mappings set up for nvim-hlslens
        search = {
          enabled = true,
        },
        undo = {
          enabled = true,
        },
        redo = {
          enabled = true,
        },
      },
    },
  },
  {
    "mawkler/modicator.nvim",

    event = "ModeChanged",

    opts = function()
      -- Same colors as the statusline's mode block
      local function set_hl()
        local c = require("base.colors").mode_colors()

        for name, color in pairs({
          Normal = c.normal,
          Insert = c.insert,
          Visual = c.visual,
          Select = c.visual,
          Replace = c.replace,
          Command = c.command,
          Terminal = c.terminal,
          TerminalNormal = c.terminal,
        }) do
          vim.api.nvim_set_hl(0, name .. "Mode", { fg = color })
        end
      end

      require("base.colors").on_change("modicator_hl", set_hl, { run = true })

      return { show_warnings = false }
    end,
  },
}
