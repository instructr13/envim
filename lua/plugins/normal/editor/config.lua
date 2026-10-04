local M = {}

local path_cmdline_types = {
  file = true,
  dir = true,
  file_in_path = true,
  dir_in_path = true,
}

-- <A-1> .. <A-9>, <A-0>: accept the Nth completion item
---@return table<string, table>
function M.blink_accept_keys()
  local keys = {}

  for i = 1, 10 do
    keys[("<A-%d>"):format(i % 10)] = {
      function(cmp)
        cmp.accept({ index = i })
      end,
    }
  end

  return keys
end

-- Icon and highlight for a blink.cmp item: devicons / folder icon for file
-- paths (Path source and :e-style cmdline completion), kind icons otherwise
---@return string icon, string? hl
function M.blink_kind_icon(ctx)
  local icons = require("base.constants.icons").kinds
  local is_path = ctx.source_id == "path"
    or (
      ctx.source_id == "cmdline"
      and path_cmdline_types[vim.fn.getcmdcompltype()]
    )

  if is_path then
    if vim.endswith(ctx.label, "/") then
      return icons.Folder, "Directory"
    end

    local icon, hl = require("nvim-web-devicons").get_icon(
      vim.fs.basename(ctx.label),
      nil,
      { default = false }
    )

    if icon then
      return icon, hl
    end

    return icons.File, ctx.kind_hl
  end

  return icons[ctx.kind] or ctx.kind_icon, ctx.kind_hl
end

-- blink.cmp keymap action: scroll the window under the mouse pointer
---@param direction 1|-1
function M.blink_mouse_scroll(direction)
  return function(cmp)
    local winid = vim.fn.getmousepos().winid
    local menu = require("blink.cmp.completion.windows.menu").win:get_win()
    local docs =
      require("blink.cmp.completion.windows.documentation").win:get_win()

    if menu and winid == menu then
      -- Scroll the view; the selection (the window's cursor line) only moves
      -- when it would leave the window
      vim.schedule(function()
        if not vim.api.nvim_win_is_valid(menu) then
          return
        end

        local before = vim.api.nvim_win_get_cursor(menu)[1]

        vim.api.nvim_win_call(menu, function()
          vim.cmd.normal({
            args = { "3" .. (direction > 0 and "\5" or "\25") },
            bang = true,
          })
        end)

        local after = vim.api.nvim_win_get_cursor(menu)[1]

        if after ~= before then
          require("blink.cmp.completion.list").select(after, {
            auto_insert = false,
          })
        end
      end)

      return true
    end

    if docs and winid == docs then
      return direction > 0 and cmp.scroll_documentation_down(3)
        or cmp.scroll_documentation_up(3)
    end
  end
end

function M.clasp_init()
  local keymap = require("base.utils.keymap").keymap

  keymap({ "n", "i" }, "<C-e>", function()
    require("clasp").wrap("next", function(nodes)
      local n = {}

      for _, node in ipairs(nodes) do
        if node.end_row == vim.api.nvim_win_get_cursor(0)[1] - 1 then
          table.insert(n, node)
        end
      end

      return n
    end)
  end, "Wrap next")

  keymap({ "n", "i" }, "<C-;>", function()
    require("clasp").wrap("prev")
  end, "Wrap previous")
end

function M.matchup_init()
  vim.g.matchup_matchparen_offscreen = {}

  vim.g.matchup_matchparen_deferred = 1
  vim.g.matchup_surround_enabled = 1

  vim.g.matchup_treesitter_enable_quotes = true
  vim.g.matchup_treesitter_disable_virtual_text = true
  vim.g.matchup_treesitter_include_match_words = true
end

function M.todo_comment()
  local keymap = require("base.utils.keymap").keymap

  keymap("n", "]t", function()
    require("todo-comments").jump_next()
  end, "Next todo comment")

  keymap("n", "[t", function()
    require("todo-comments").jump_prev()
  end, "Previous todo comment")

  local tree_comment = require("tree-comment")
  local folkified_keywords, colors =
    tree_comment.folkify_keywords(tree_comment.get_keywords())

  require("todo-comments").setup({
    keywords = folkified_keywords,
    colors = colors,
    highlight = { keyword = "wide_fg", after = "" },
  })
end

return M
