# promptly.nvim

Sends stuff from neovim to an adjacent zellij pane. For talking to claude or whatever.

## Installation

```lua
{
    "HypeSafety/promptly.nvim",
    event = "VeryLazy",
    opts = {
        direction = "right",    -- "right" | "left" | "up" | "down"
        submit = false,         -- press Enter after sending
        return_focus = false,   -- stay on target pane (set true to return to neovim)
        keys = true,            -- enable default keymaps (see below)
    },
}
```

## Default Keymaps

When `keys = true`:

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>ps` | visual | Send selection |
| `<leader>pp` | visual | Pick prompt |
| `<leader>pf` | visual | Send file + selection |
| `<leader>pf` | normal | Send file position |
| `<leader>pF` | normal | Send file path |
| `<leader>pd` | normal | Send diagnostics |
| `<leader>pt` | normal | Send smart context |
| `<leader>py` | normal | Send current line |

### Directional Keymaps

Use `<leader>p{h,j,k,l}{cmd}` to send to a specific pane direction:

| Direction Key | Pane | Description |
|---------------|------|-------------|
| `h` | left | Send to pane on the left |
| `j` | down | Send to pane below |
| `k` | up | Send to pane above |
| `l` | right | Send to pane on the right |

Examples:
- `<leader>pls` → send selection right
- `<leader>phf` → send file position left
- `<leader>pjd` → send diagnostics down

## Custom Keymaps

If you prefer to define your own keymaps, leave `keys = false` (default) and add:

```lua
{
    "HypeSafety/promptly.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
        { "<leader>ps", function() require("promptly").selection() end, mode = "v", desc = "Send selection" },
        { "<leader>pp", function() require("promptly").prompt() end, mode = "v", desc = "Pick prompt" },
        -- add your own...
    },
}
```

Override per-call: `p.selection({ direction = "left", submit = true })`

## Functions

```lua
local p = require("promptly")

-- Basic
p.selection()        -- visual selection
p.line()             -- current line
p.file()             -- file path (relative)
p.position()         -- @file L:1 C:1
p.context()          -- @file L:1 C:1 + selection
p.this()             -- selection if visual, else position

-- LSP/Treesitter
p.diagnostics()      -- buffer diagnostics
p.diagnostics_all()  -- all workspace diagnostics
p.func()             -- treesitter function/method
p.class()            -- treesitter class/struct/impl
p.quickfix()         -- quickfix list

-- Other
p.buffers()          -- list of open buffers
p.send(template)     -- send with template variables
p.send_raw(text)     -- send raw text
p.prompt()           -- open prompt picker
```

## Template Variables

Use with `p.send()`:

```lua
p.send("Fix this:\n{selection}")
p.send("Review {file}")
```

| Variable | Description |
|----------|-------------|
| `{selection}` | Visual selection |
| `{file}` | Current file path |
| `{line}` | Current line content |
| `{position}` | `@file L:n C:n` format |
| `{diagnostics}` | Buffer diagnostics |
| `{diagnostics_all}` | All workspace diagnostics |
| `{quickfix}` | Quickfix list |
| `{buffers}` | Open buffer list |
| `{function}` | Current function (treesitter) |
| `{class}` | Current class (treesitter) |
| `{this}` | Selection or position |

## Prompt Picker

The prompt picker (`p.prompt()` or `<leader>pp`) shows a menu of pre-defined prompts using `vim.ui.select`.

Built-in prompts include:
- Explain
- Refactor
- Fix Bug
- Optimize
- Add Types
- Review
- Document
- Tests
- Summarize File

You can override these or add your own in `setup({ prompts = { ... } })`.

MIT
