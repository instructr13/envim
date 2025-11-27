local M = {}

function M.treesitter_init()
  -- Wrap vim.treesitter.start with pcall
  vim.treesitter.start = (function(wrapped)
    return function(bufnr, lang)
      lang = lang or vim.fn.getbufvar(bufnr or "", "&filetype")

      pcall(wrapped, bufnr, lang)
    end
  end)(vim.treesitter.start)
end

function M.treesitter()
  require("nvim-treesitter.configs").setup({
    ensure_installed = {
      -- Defaults
      "c",
      "lua",
      "vim",
      "vimdoc",
      "query",
      "markdown",
      "markdown_inline",

      -- noice.nvim
      "regex",
      "bash",

      -- Treesitter
      "query",

      -- tree-comment.nvim
      "comment",

      -- puppeteer.nvim
      "python",
      "javascript",
      "typescript",
    },

    auto_install = true,

    highlight = {
      enable = true,

      disable = function(lang, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats =
          pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
          return true
        end
      end,

      additional_vim_regex_highlighting = false,
    },

    indent = { enable = true },
  })
end

return M
