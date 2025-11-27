local M = {}

local api, uv, treesitter = vim.api, vim.uv, vim.treesitter

local ensure_installed = {
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
}

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
  require("nvim-treesitter").install(ensure_installed)

  api.nvim_create_autocmd("FileType", {
    group = api.nvim_create_augroup("treesitter.setup", {}),
    callback = function(args)
      local ft = args.match
      local buf = args.buf

      local language = treesitter.language.get_lang(ft) or ft

      if not treesitter.language.add(language) then
        return
      end

      -- fold
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

      -- indent
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

      -- highlight
      local max_filesize = 100 * 1024 -- 100 KB
      local ok, stats = pcall(uv.fs_stat, vim.api.nvim_buf_get_name(buf))

      if not ok or not stats or stats.size >= max_filesize then
        return
      end

      treesitter.start(buf, language)
    end,
  })
end

return M
