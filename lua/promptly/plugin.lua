-- Lazy.nvim plugin spec (example for users who prefer lazy-loading on keys)
local keys = {
  { "<leader>ps", function() require("promptly").selection() end, mode = "v", desc = "Send selection to Zellij pane" },
  { "<leader>pp", function() require("promptly").prompt() end, mode = "v", desc = "Pick prompt and send to Zellij pane" },
  { "<leader>pf", function() require("promptly").context() end, mode = "v", desc = "Send file + selection to Zellij pane" },
  { "<leader>pf", function() require("promptly").position() end, mode = "n", desc = "Send file position to Zellij pane" },
  { "<leader>pF", function() require("promptly").file() end, mode = "n", desc = "Send file path to Zellij pane" },
  { "<leader>pd", function() require("promptly").diagnostics() end, mode = "n", desc = "Send diagnostics to Zellij pane" },
  { "<leader>pt", function() require("promptly").this() end, mode = "n", desc = "Send smart context to Zellij pane" },
  { "<leader>py", function() require("promptly").line() end, mode = "n", desc = "Send current line to Zellij pane" },
}

-- Directional keymaps: <leader>p{h,j,k,l}{cmd}
local dirs = { h = "left", j = "down", k = "up", l = "right" }
for key, dir in pairs(dirs) do
  local o = { direction = dir }
  -- Group labels for which-key
  table.insert(keys, { "<leader>p" .. key, group = "Send " .. dir })
  table.insert(keys, { "<leader>p" .. key .. "s", function() require("promptly").selection(o) end, mode = "v", desc = "Send selection " .. dir })
  table.insert(keys, { "<leader>p" .. key .. "p", function() require("promptly").prompt(o) end, mode = "v", desc = "Pick prompt " .. dir })
  table.insert(keys, { "<leader>p" .. key .. "f", function() require("promptly").context(o) end, mode = "v", desc = "Send file + selection " .. dir })
  table.insert(keys, { "<leader>p" .. key .. "f", function() require("promptly").position(o) end, mode = "n", desc = "Send file position " .. dir })
  table.insert(keys, { "<leader>p" .. key .. "F", function() require("promptly").file(o) end, mode = "n", desc = "Send file path " .. dir })
  table.insert(keys, { "<leader>p" .. key .. "d", function() require("promptly").diagnostics(o) end, mode = "n", desc = "Send diagnostics " .. dir })
  table.insert(keys, { "<leader>p" .. key .. "t", function() require("promptly").this(o) end, mode = "n", desc = "Send smart context " .. dir })
  table.insert(keys, { "<leader>p" .. key .. "y", function() require("promptly").line(o) end, mode = "n", desc = "Send current line " .. dir })
end

return {
  "HypeSafety/promptly.nvim",
  dependencies = {},
  opts = {},
  keys = keys,
}
