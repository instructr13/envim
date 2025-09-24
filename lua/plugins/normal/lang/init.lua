-- Language-specific configurations

return {
  {
    "folke/lazydev.nvim",

    ft = "lua", -- only load on lua files

    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "OXY2DEV/helpview.nvim",

    opts = {
      preview = {
        icon_provider = "devicons",
      },
    },
  },
  {
    "OXY2DEV/markview.nvim",

    priority = 49,
  },
}
