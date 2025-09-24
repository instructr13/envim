return {
  {
    "0xAdk/full_visual_line.nvim",

    lazy = true,

    keys = "V",

    opts = {},
  },
  {
    "rachartier/tiny-glimmer.nvim",

    lazy = true,

    event = { "VeryLazy" },

    priority = 10,

    opts = {
      overwrite = {
        search = {
          enabled = true,

          next_mapping = "nzzzv",
          prev_mapping = "Nzzzv",
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

    opts = {
      show_warnings = false,
    },
  },
}
