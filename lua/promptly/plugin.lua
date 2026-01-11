-- Lazy.nvim plugin spec (example for users who prefer lazy-loading on keys)
return {
  "HypeSafety/promptly.nvim",
  dependencies = {},
  opts = {},
  keys = {
    { "<leader>ps", function() require("promptly").selection() end, mode = "v", desc = "Send selection to Zellij pane" },
    { "<leader>pp", function() require("promptly").prompt() end, mode = "v", desc = "Pick prompt and send to Zellij pane" },
    { "<leader>pf", function() require("promptly").context() end, mode = "v", desc = "Send file + selection to Zellij pane" },
    { "<leader>pf", function() require("promptly").position() end, mode = "n", desc = "Send file position to Zellij pane" },
    { "<leader>pF", function() require("promptly").file() end, mode = "n", desc = "Send file path to Zellij pane" },
    { "<leader>pd", function() require("promptly").diagnostics() end, mode = "n", desc = "Send diagnostics to Zellij pane" },
    { "<leader>pt", function() require("promptly").this() end, mode = "n", desc = "Send smart context to Zellij pane" },
    { "<leader>pl", function() require("promptly").line() end, mode = "n", desc = "Send current line to Zellij pane" },
  },
}
