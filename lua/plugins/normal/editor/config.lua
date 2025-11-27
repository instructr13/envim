local M = {}

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
  vim.g.matchup_matchparen_offscreen = {
    method = "status_manual",
    scrolloff = true,
  }

  vim.g.matchup_matchparen_deferred = 1
  vim.g.matchup_surround_enabled = 1
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
