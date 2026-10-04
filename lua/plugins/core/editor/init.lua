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

    lazy = true,

    event = "VeryLazy",

    version = "*",

    opts = function()
      local ik = require("base.utils.keymap").omit(
        "append",
        { "x", "o" },
        "ij",
        { remap = true }
      )

      local ak = require("base.utils.keymap").omit(
        "append",
        { "x", "o" },
        "aj",
        { remap = true }
      )

      ik("[", "i?「<cr>」<cr>")
      ak("[", "a?「<cr>」<cr>")

      ik("<", "i?＜<cr>＞<cr>")
      ak("<", "a?＜<cr>＞<cr>")
      ik("{", "i?｛<cr>｝<cr>")
      ak("{", "a?｛<cr>｝<cr>")

      local ai = require("mini.ai")
      local ts = ai.gen_spec.treesitter

      return {
        n_lines = 500,
        custom_textobjects = {
          -- Treesitter queries from nvim-treesitter-textobjects
          f = ts({ a = "@function.outer", i = "@function.inner" }),
          c = ts({ a = "@class.outer", i = "@class.inner" }),
          o = ts({
            a = { "@conditional.outer", "@loop.outer", "@block.outer" },
            i = { "@conditional.inner", "@loop.inner", "@block.inner" },
          }),
          u = ai.gen_spec.function_call(),
        },
        -- Keep an / in free for Nvim's incremental selection
        mappings = {
          around_next = "aN",
          inside_next = "iN",
          around_last = "aL",
          inside_last = "iL",
        },
      }
    end,
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

    -- vim-surround style keys, leaving `s` to flash.nvim
    keys = {
      { "ys", mode = "n", desc = "Add surrounding" },
      { "ds", desc = "Delete surrounding" },
      { "cs", desc = "Replace surrounding" },
      { "yss", "ys_", remap = true, desc = "Surround line" },
      {
        "S",
        ":<C-u>lua MiniSurround.add('visual')<cr>",
        mode = "x",
        silent = true,
        desc = "Surround selection",
      },
    },

    opts = {
      mappings = {
        add = "ys",
        delete = "ds",
        replace = "cs",
        find = "",
        find_left = "",
        highlight = "",
        update_n_lines = "",
        suffix_last = "",
        suffix_next = "",
      },
      search_method = "cover_or_next",
    },

    config = function(_, opts)
      require("mini.surround").setup(opts)

      -- `ys` in Visual mode would shadow `y`; use `S` instead
      pcall(vim.keymap.del, "x", "ys")
    end,
  },
  {

    "folke/flash.nvim",

    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        -- Visual `S` belongs to mini.surround
        "S",
        mode = { "n", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesiteer Search",
      },
      "f",
      "F",
      "t",
      "T",
    },
    opts = {
      modes = {
        char = {
          jump_labels = true,
        },
      },
    },
  },
  {
    -- Per-language commentstring for the built-in `gc`
    "folke/ts-comments.nvim",

    event = "VeryLazy",

    opts = {},
  },
  {
    "chrisgrieser/nvim-puppeteer",

    lazy = false,
  },
  {
    "chrisgrieser/nvim-recorder",

    lazy = true,

    -- Default mappings of the plugin
    keys = { "q", "<C-q>", "cq", "dq", "yq", "##" },

    opts = {
      lessNotifications = true,
    },
  },
}
