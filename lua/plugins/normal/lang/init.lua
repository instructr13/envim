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
    -- Renders Markdown in a separate view (float / tab / split / in-place)
    "delphinus/md-render.nvim",

    version = "*",

    ft = "markdown",

    cmd = "MdRender",

    dependencies = { "nvim-tree/nvim-web-devicons" },

    keys = {
      {
        "<leader>mp",
        "<Plug>(md-render-preview)",
        ft = "markdown",
        desc = "Markdown preview",
      },
      {
        "<leader>mt",
        "<Plug>(md-render-preview-tab)",
        ft = "markdown",
        desc = "Markdown preview (tab)",
      },
      {
        "<leader>ms",
        "<Plug>(md-render-split)",
        ft = "markdown",
        desc = "Markdown source / render split",
      },
      {
        "<leader>mm",
        "<Plug>(md-render-toggle)",
        ft = "markdown",
        desc = "Toggle Markdown render in place",
      },
      {
        "<leader>ma",
        "<Plug>(md-render-auto)",
        ft = "markdown",
        desc = "Toggle Markdown auto render (outside Insert)",
      },
    },
  },
}
