local M = {}

function M.ufo_init()
  local keymap = require("base.utils.keymap").omit("append", { "n" }, "z")

  keymap("R", function()
    require("ufo").openAllFolds()
  end, "Open All Folds")

  keymap("M", function()
    require("ufo").closeAllFolds()
  end, "Close All Folds")

  keymap("r", function()
    require("ufo").openFoldsExceptKinds()
  end, "Open Folds Except Kinds")

  keymap("m", function()
    require("ufo").closeFoldsWith()
  end, "Close Current Fold Level")
end

return M
