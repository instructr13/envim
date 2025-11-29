local C = require("plugins.normal.editor.config")

return {
  {
    "saghen/blink.cmp",

    lazy = true,

    event = { "InsertEnter", "CmdlineEnter" },

    dependencies = {
      "rafamadriz/friendly-snippets",
      {
        "xzbdmw/colorful-menu.nvim",

        opts = {},
      },
    },

    version = "1.*",

    opts = {
      cmdline = {
        keymap = {
          preset = "cmdline",
        },
        completion = { menu = { auto_show = true } },
      },
      keymap = {
        preset = "enter",

        -- For tabout.nvim
        ["<Tab>"] = { "snippet_forward", "fallback_to_mappings" },

        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<C-b>"] = {},
        ["<C-f>"] = {},
      },
      completion = {
        list = {
          selection = { preselect = true, auto_insert = false },
        },
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
        ghost_text = { enabled = true },
        menu = {
          border = "none",
          draw = {
            padding = { 0, 1 },
            columns = {
              { "kind_icon" },
              { "label", gap = 1 },
            },
            components = {
              label = {
                text = function(ctx)
                  return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                  return require("colorful-menu").blink_components_highlight(
                    ctx
                  )
                end,
              },
              kind_icon = {
                text = function(ctx)
                  local icon = ctx.kind_icon

                  if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local dev_icon, _ =
                      require("nvim-web-devicons").get_icon(ctx.label)

                    if dev_icon then
                      icon = dev_icon
                    end
                  else
                    icon = require("lspkind").symbolic(ctx.kind, {
                      mode = "symbol",
                    })
                  end

                  return " " .. icon .. ctx.icon_gap .. " "
                end,

                -- Optionally, use the highlight groups from nvim-web-devicons
                -- You can also add the same function for `kind.highlight` if you want to
                -- keep the highlight groups in sync with the icons.
                highlight = function(ctx)
                  local hl = ctx.kind_hl

                  if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local dev_icon, dev_hl =
                      require("nvim-web-devicons").get_icon(ctx.label)

                    if dev_icon then
                      hl = dev_hl
                    end
                  end

                  return hl
                end,
              },
            },
          },
          direction_priority = function()
            local ctx = require("blink.cmp").get_context()
            local item = require("blink.cmp").get_selected_item()

            if ctx == nil or item == nil then
              return { "s", "n" }
            end

            local item_text = item.textEdit ~= nil and item.textEdit.newText
              or item.insertText
              or item.label

            local is_multi_line = item_text:find("\n") ~= nil

            -- after showing the menu upwards, we want to maintain that direction
            -- until we re-open the menu, so store the context id in a global variable
            if is_multi_line or vim.g.blink_cmp_upwards_ctx_id == ctx.id then
              vim.g.blink_cmp_upwards_ctx_id = ctx.id

              return { "n", "s" }
            end

            return { "s", "n" }
          end,
        },
      },
      signature = {
        enabled = true,
        window = {
          border = "none",
          show_documentation = true,
        },
      },
      sources = {
        default = function(ctx)
          if vim.bo.filetype == "lua" then
            return { "lazydev", "lsp", "path", "snippets" }
          else
            return { "lsp", "path", "snippets" }
          end
        end,
        providers = {
          path = {
            opts = {
              get_cwd = function(_)
                return vim.fn.getcwd()
              end,
            },
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority
            score_offset = 100,
          },
          cmdline = {
            -- ignores cmdline completions when executing shell commands
            enabled = function()
              return vim.fn.getcmdtype() ~= ":"
                or not vim.fn.getcmdline():match("^[%%0-9,'<>%-]*!")
            end,
            min_keyword_length = function(ctx)
              -- when typing a command, only show when the keyword is 3 characters or longer
              if ctx.mode == "cmdline" and ctx.line:find("^%l+$") ~= nil then
                return 3
              end

              return 0
            end,
          },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },
  {
    "willothy/savior.nvim",

    lazy = true,

    event = { "InsertEnter", "TextChanged" },

    opts = {
      notify = false,
    },
  },
  {
    "RRethy/vim-illuminate",
  },
  {
    "andymass/vim-matchup",

    init = function()
      C.matchup_init()
    end,
  },
  {
    "altermo/ultimate-autopair.nvim",

    event = { "InsertEnter", "CmdlineEnter" },

    opts = {
      bs = {
        space = "balance",
        indent_ignore = true,
      },
      fastwarp = {
        enable = false,
      },
    },
  },
  {
    "qwavies/smart-backspace.nvim",

    event = { "InsertEnter", "CmdlineEnter" },

    opts = {
      enabled = true,
      silent = true,
    },
  },
  {
    "xzbdmw/clasp.nvim",

    lazy = true,

    init = function()
      C.clasp_init()
    end,

    opts = {},
  },
  {
    "abecodes/tabout.nvim",

    opts = {
      enable_backwards = false,
      completion = false,
    },
  },
  {
    -- colorcolumn
    "Bekaboo/deadcolumn.nvim",

    event = { "CursorMoved" },

    opts = {
      "visible",
      "cursor",
    },
  },
  {
    "ethanholz/nvim-lastplace",

    opts = {
      lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
      lastplace_ignore_filetype = {
        "gitcommit",
        "gitrebase",
        "svn",
        "hgcommit",
      },
      lastplace_open_folds = true,
    },
  },
  {
    "alexmozaidze/tree-comment.nvim",

    lazy = true,

    opts = {},
  },
  {
    "folke/todo-comments.nvim",

    dependencies = { "nvim-lua/plenary.nvim", "alexmozaidze/tree-comment.nvim" },

    config = function()
      C.todo_comment()
    end,
  },
}
