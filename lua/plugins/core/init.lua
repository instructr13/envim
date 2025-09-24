local fn, fs = vim.fn, vim.fs

local reload_dirs = { "core", "editor" }

return {
  {
    "tpope/vim-repeat",
  },
  {
    "Zeioth/hot-reload.nvim",

    dependencies = { "nvim-lua/plenary.nvim" },

    event = "BufEnter",

    opts = function()
      local conf_dir = fs.joinpath(fn.stdpath("config"), "lua", "base")
      local files = vim
        .iter(reload_dirs)
        :map(function(p)
          return vim.split(
            fn.globpath(fs.joinpath(conf_dir, files), "**/*"),
            "\n"
          )
        end)
        :flatten()
        :filter(function(p)
          return vim.endswith(p, ".lua")
        end)
        :totable()

      return {
        reload_files = files,
        reload_callback = function() end,
      }
    end,
  },
  {
    "pteroctopus/faster.nvim",

    opts = {},
  },
}
