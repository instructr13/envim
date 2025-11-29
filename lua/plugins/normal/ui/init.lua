local C = require("plugins.normal.ui.config")

return {
  {
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
        colors = require("catppuccin.palettes").get_palette(),
      }
    end,
  },
  {
    "j-hui/fidget.nvim",

    opts = {
      progress = {
        ignore_done_already = true,
        ignore_empty_message = true,
      },
      notification = {
        override_vim_notify = true,
      },
    },
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
        relculright = true,
        segments = {
          { text = { " " } },
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
            sign = {
              name = { "LightbulbSign" },
              maxwidth = 1,
              colwidth = 1,
            },
            click = "v:lua.ScSa",
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
          LightbulbSign = function(args)
            if args.button == "l" then
              vim.lsp.buf.code_action()
            end
          end,
        },
      }
    end,
  },
  {
    "onsails/lspkind.nvim",

    lazy = true,

    opts = {
      symbol_map = {
        Array = " ",
        Boolean = " 󰨙 ",
        Class = " 󰯳 ",
        Color = " ",
        Collapsed = " > ",
        Constant = " 󰯱 ",
        Control = "  ",
        Constructor = "  ",
        Enum = " 󰯹 ",
        EnumMember = " ",
        Event = " ",
        Field = " ",
        File = " ",
        Folder = "  ",
        Function = " ",
        Interface = " 󰰅 ",
        Key = "  ",
        Keyword = " ",
        Method = " 󰰑 ",
        Module = " ",
        Namespace = " 󰰔 ",
        Null = "  ",
        Number = " ",
        Object = " 󰲟 ",
        Operator = " ",
        Package = " 󰰚 ",
        Property = " 󰲽 ",
        Reference = " 󰰠 ",
        Snippet = " ",
        String = " ",
        Struct = " 󰰣 ",
        Text = " ",
        TypeParameter = " 󰰦 ",
        Unit = " ",
        Value = " ",

        Copilot = " ",
      },
    },
  },
  {
    "sphamba/smear-cursor.nvim",

    cond = not vim.g.neovide,

    opts = {
      smear_between_buffers = false,
      smear_insert_mode = false,
    },
  },
  {
    "nvim-mini/mini.animate",

    opts = {
      cursor = { enable = false },
      scroll = { enable = false },
    },
  },
  {
    "folke/noice.nvim",

    event = "VeryLazy",

    dependencies = { "MunifTanjim/nui.nvim" },

    opts = {
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
        progress = {
          enabled = false,
        },
        signature = {
          enabled = false,
        },
      },
      notify = {
        enabled = false,
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
    },
  },
  {
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
        "Zeioth/heirline-components.nvim",

        opts = {
          icons = {
            GitAdd = "",
            GitChange = "",
            GitDelete = "",
          },
        },

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
      vim.cmd.hi({ "TabLineSel guibg=#ed8796", bang = true })

      local keymap = require("base.utils.keymap").keymap

      keymap("n", "gb", function()
        require("bufferline").pick()
      end, "Pick Buffer")

      return {
        highlights = require("catppuccin.special.bufferline").get_theme({
          styles = {},
          custom = {
            all = {
              fill = {
                bg = {
                  attribute = "bg",
                  highlight = "StatusLine",
                },
              },
            },
          },
        }),
        options = {
          close_command = function(bufnr)
            require("mini.bufremove").delete(bufnr, true)
          end,
          right_mouse_command = "vertical sbuffer %d",
          indicator = {
            style = "underline",
          },
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(count, level)
            if level:match("error") then
              return " " .. count
            elseif level:match("warning") then
              return " " .. count
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
        "<leader>t",
        "",
        desc = "Undo tree",
      },
      {
        "<leader>tt",
        "<cmd>TimeMachineToggle<cr>",
        desc = "Toggle tree",
      },
      {
        "<leader>tx",
        "<cmd>TimeMachinePurgeCurrent<cr>",
        desc = "Purge current",
      },
      {
        "<leader>tX",
        "<cmd>TimeMachinePurgeAll<cr>",
        desc = "Purge all",
      },
      {
        "<leader>tl",
        "<cmd>TimeMachineLogShow<cr>",
        desc = "Show log",
      },
    },

    opts = {},
  },
  {
    "lewis6991/satellite.nvim",

    opts = {
      excluded_filetypes = { "neo-tree" },
    },
  },
  {
    "nvim-zh/colorful-winsep.nvim",

    lazy = true,

    event = { "WinLeave" },

    opts = {},
  },
  {
    "nacro90/numb.nvim",

    lazy = true,

    event = { "CmdlineEnter" },

    opts = {},
  },
}
