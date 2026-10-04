local C = require("plugins.normal.editor.config")

local comment_nodes = {
  comment = true,
  line_comment = true,
  block_comment = true,
}

return {
  {
    "saghen/blink.cmp",

    lazy = true,

    event = { "InsertEnter", "CmdlineEnter" },

    dependencies = {
      -- Loaded by blink's built-in (vim.snippet) snippet source
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
      keymap = vim.tbl_extend("error", C.blink_accept_keys(), {
        preset = "enter",

        -- For tabout.nvim
        ["<Tab>"] = { "snippet_forward", "fallback_to_mappings" },

        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },

        -- Mouse wheel over the menu moves the selection, over the docs scrolls
        ["<ScrollWheelDown>"] = { C.blink_mouse_scroll(1), "fallback" },
        ["<ScrollWheelUp>"] = { C.blink_mouse_scroll(-1), "fallback" },
        ["<C-b>"] = {},
        ["<C-f>"] = {},
      }),
      completion = {
        list = {
          selection = { preselect = true, auto_insert = false },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
          window = { scrollbar = true },
        },
        ghost_text = { enabled = true },
        menu = {
          border = "none",
          scrollbar = true,
          -- Lets the mouse wheel scroll as far as possible before the
          -- selection has to follow
          scrolloff = 0,
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
                  return " " .. C.blink_kind_icon(ctx) .. " "
                end,
                highlight = function(ctx)
                  return select(2, C.blink_kind_icon(ctx))
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
        default = function(_)
          local success, node = pcall(vim.treesitter.get_node)

          if success and node and comment_nodes[node:type()] then
            return { "buffer", "lsp", "path" }
          elseif vim.bo.filetype == "lua" then
            return { "lazydev", "lsp", "path", "snippets" }
          else
            return { "lsp", "path", "snippets" }
          end
        end,
        providers = {
          snippets = {
            should_show_items = function(ctx)
              if
                #vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
                == 0
              then
                return false
              end

              return ctx.trigger.initial_kind ~= "trigger_character"
            end,
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

    event = { "BufReadPost", "BufNewFile" },

    config = function()
      require("illuminate").configure({
        -- The treesitter provider needs nvim-treesitter's master branch
        providers = { "lsp", "regex" },
      })
    end,
  },
  {
    "andymass/vim-matchup",

    lazy = true,

    event = { "BufReadPost", "BufNewFile" },

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
    "xzbdmw/clasp.nvim",

    lazy = true,

    init = function()
      C.clasp_init()
    end,

    opts = {},
  },
  {
    "abecodes/tabout.nvim",

    lazy = true,

    event = "InsertEnter",

    opts = {
      enable_backwards = false,
      completion = false,
    },
  },
  {
    -- Re-indent linewise pastes to fit the destination
    "nemanjamalesija/smart-paste.nvim",

    event = "VeryLazy",

    opts = {},
  },
  {
    -- Preview :norm / :g and friends like 'inccommand'
    "smjonas/live-command.nvim",

    main = "live-command",

    event = "CmdlineEnter",

    opts = {
      commands = {
        Norm = { cmd = "norm" },
        G = { cmd = "g" },
      },
    },
  },
  {
    "alexmozaidze/tree-comment.nvim",

    lazy = true,

    opts = {},
  },
  {
    "folke/todo-comments.nvim",

    event = { "BufReadPost", "BufNewFile" },

    dependencies = { "nvim-lua/plenary.nvim", "alexmozaidze/tree-comment.nvim" },

    config = function()
      C.todo_comment()
    end,
  },
}
