local M = {}

function M.spider_init()
  local keymap =
    require("base.utils.keymap").omit("append", { "n", "o", "x" }, "")

  for _, key in ipairs({ "w", "e", "b", "ge" }) do
    keymap(key, function()
      require("spider").motion(key)
    end, "Spider-" .. key)
  end
end

function M.dial_init()
  local keymap = require("base.utils.keymap").keymap

  for mode, kind in pairs({ n = "normal", x = "visual" }) do
    for _, m in ipairs({
      { "<C-a>", "increment", kind, "Increment" },
      { "<C-x>", "decrement", kind, "Decrement" },
      { "g<C-a>", "increment", "g" .. kind, "Increment (progressive)" },
      { "g<C-x>", "decrement", "g" .. kind, "Decrement (progressive)" },
    }) do
      keymap(mode, m[1], function()
        require("dial.map").manipulate(m[2], m[3])
      end, m[4])
    end
  end
end

return M
