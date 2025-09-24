local M = {}

function M.spider_init()
  local keymap =
    require("base.utils.keymap").omit("append", { "n", "o", "x" }, "")

  keymap("w", function()
    require("spider").motion("w")
  end, "Spider-w")

  keymap("e", function()
    require("spider").motion("e")
  end, "Spider-e")

  keymap("b", function()
    require("spider").motion("b")
  end, "Spider-b")

  keymap("ge", function()
    require("spider").motion("ge")
  end, "Spider-ge")
end

function M.dial_init()
  local keymap = require("base.utils.keymap").keymap

  keymap("n", "<C-a>", function()
    require("dial.map").manipulate("increment", "normal")
  end)

  keymap("n", "<C-x>", function()
    require("dial.map").manipulate("decrement", "normal")
  end)

  keymap("n", "g<C-a>", function()
    require("dial.map").manipulate("increment", "gnormal")
  end)

  keymap("n", "g<C-x>", function()
    require("dial.map").manipulate("decrement", "gnormal")
  end)

  keymap("x", "<C-a>", function()
    require("dial.map").manipulate("increment", "visual")
  end)

  keymap("x", "<C-x>", function()
    require("dial.map").manipulate("decrement", "visual")
  end)

  keymap("x", "g<C-a>", function()
    require("dial.map").manipulate("increment", "gvisual")
  end)

  keymap("x", "g<C-x>", function()
    require("dial.map").manipulate("decrement", "gvisual")
  end)
end

return M
