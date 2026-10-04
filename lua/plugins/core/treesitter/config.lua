local M = {}

local api, uv, treesitter = vim.api, vim.uv, vim.treesitter

local max_filesize = 100 * 1024 -- 100 KB

-- Parsers installed up front because plugins use them for injections
local ensure_installed = {
  "regex",
  "comment",
  "luadoc",
  "markdown_inline",
}

local pending, failed = {}, {}

local function is_large(buf)
  local name = api.nvim_buf_get_name(buf)
  local stat = name ~= "" and uv.fs_stat(name) or nil

  return stat ~= nil and stat.size >= max_filesize
end

local function attach(buf, lang)
  if not api.nvim_buf_is_valid(buf) or is_large(buf) then
    return
  end

  if not pcall(treesitter.start, buf, lang) then
    return
  end

  -- LSP folding takes precedence (see base.lsp)
  if not vim.b[buf].lsp_folding and treesitter.query.get(lang, "folds") then
    require("base.editor").set_foldexpr(buf, "v:lua.vim.treesitter.foldexpr()")
  end

  if treesitter.query.get(lang, "indents") then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

local function has_parser(lang)
  local ok, added = pcall(treesitter.language.add, lang)

  return ok and added
end

-- Install the parser, then attach to every loaded buffer of that language
local function install(lang)
  if pending[lang] or failed[lang] then
    return
  end

  if not require("nvim-treesitter.parsers")[lang] then
    -- no parser exists for this language
    failed[lang] = true

    return
  end

  if vim.fn.executable("tree-sitter") == 0 then
    vim.notify_once(
      "tree-sitter CLI not found: parsers cannot be installed",
      vim.log.levels.WARN
    )

    return
  end

  pending[lang] = true

  require("nvim-treesitter").install(lang):await(function(err, ok)
    vim.schedule(function()
      pending[lang] = nil

      if err or not ok or not has_parser(lang) then
        failed[lang] = true

        return
      end

      for _, buf in ipairs(api.nvim_list_bufs()) do
        if
          api.nvim_buf_is_loaded(buf)
          and treesitter.language.get_lang(vim.bo[buf].filetype) == lang
        then
          attach(buf, lang)
        end
      end
    end)
  end)
end

function M.treesitter()
  local installed = require("nvim-treesitter").get_installed()
  local missing = vim
    .iter(ensure_installed)
    :filter(function(lang)
      return not vim.list_contains(installed, lang)
    end)
    :totable()

  if #missing > 0 then
    require("nvim-treesitter").install(missing)
  end

  api.nvim_create_autocmd("FileType", {
    group = api.nvim_create_augroup("treesitter.setup", { clear = true }),
    callback = function(args)
      local lang = treesitter.language.get_lang(args.match)

      if not lang or failed[lang] then
        return
      end

      if has_parser(lang) then
        attach(args.buf, lang)
      else
        install(lang)
      end
    end,
  })
end

-- Selection is handled by mini.ai (see plugins.core.editor); this sets up
-- movement and swapping
function M.textobjects()
  local keymap = require("base.utils.keymap").keymap
  local move = require("nvim-treesitter-textobjects.move")
  local swap = require("nvim-treesitter-textobjects.swap")

  -- ]c / [c are used by gitsigns for hunks
  local moves = {
    ["]f"] = { "goto_next_start", "@function.outer", "Next function" },
    ["[f"] = { "goto_previous_start", "@function.outer", "Previous function" },
    ["]F"] = { "goto_next_end", "@function.outer", "Next function end" },
    ["[F"] = { "goto_previous_end", "@function.outer", "Previous function end" },
    ["]]"] = { "goto_next_start", "@class.outer", "Next class" },
    ["[["] = { "goto_previous_start", "@class.outer", "Previous class" },
    ["]a"] = { "goto_next_start", "@parameter.inner", "Next argument" },
    ["[a"] = { "goto_previous_start", "@parameter.inner", "Previous argument" },
  }

  for lhs, m in pairs(moves) do
    keymap({ "n", "x", "o" }, lhs, function()
      move[m[1]](m[2], "textobjects")
    end, m[3])
  end

  keymap("n", "<leader>ca", function()
    swap.swap_next("@parameter.inner")
  end, "Swap with next argument")

  keymap("n", "<leader>cA", function()
    swap.swap_previous("@parameter.inner")
  end, "Swap with previous argument")
end

return M
