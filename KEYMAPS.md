# Neovim Keymaps

`<leader>` is mapped to the **space** key.

## Custom keymaps

### General editing and navigation

- `<leader>pv` – open the built-in file explorer (`:Ex`)
- Visual `J` / `K` – move highlighted lines down or up
- `J` – join the line below without moving the cursor
- `<C-d>` / `<C-u>` – half-page down/up and recenter the view
- `n` / `N` – next/previous search result and center the match
- `=ap` – reindent paragraph and return cursor to mark
- `<leader>zig` – restart LSP servers
- Visual `<leader>p` – paste over selection without yanking
- `<leader>y` / `<leader>Y` – yank to the system clipboard
- `<leader>d` – delete without affecting any register
- Insert `<C-c>` – exit insert mode
- `Q` – disabled to avoid accidental Ex mode
- `<leader>tp` – run tests in the current file with Plenary
- `<leader>f` – format current buffer via conform.nvim
- `<C-k>` / `<C-j>` – next/previous entry in the quickfix list
- `<leader>k` / `<leader>j` – next/previous entry in the location list
- `<leader>s` – substitute word under cursor across the file
- `<leader>x` – make current file executable
- `<leader>ee` / `<leader>ea` / `<leader>ef` / `<leader>el` – insert common Go error-handling snippets
- `<leader>ca` – trigger the "make it rain" animation
- `<leader><leader>` – source the current file

### Tmux integration

- `<C-f>` – open a project selector in a new tmux window
- `<M-h>` – open project in a vertical split via tmux-sessionizer
- `<M-H>` – open project in a new tmux window via tmux-sessionizer

### LSP and diagnostics

- `gd` – go to definition
- `K` – hover documentation
- `<leader>vws` – search workspace symbols
- `<leader>vd` – show diagnostics for current line
- `<leader>vca` – code action menu
- `<leader>vrr` – list references
- `<leader>vrn` – rename symbol
- Insert `<C-h>` – signature help
- `[d` / `]d` – jump to next/previous diagnostic

### Telescope

- `<leader>pf` – find files in project
- `<C-p>` – list git-tracked files
- `<leader>pws` – grep word under cursor
- `<leader>pWs` – grep WORD under cursor
- `<leader>ps` – grep for custom input
- `<leader>vh` – search help tags

### Testing

- `<leader>tc` – run nearest test with neotest
- `<leader>tf` – run all tests in current file

### Debugging

- `<Leader>dt` – toggle breakpoint
- `<Leader>dc` – start/continue debugging
- `<Leader>dx` – terminate debugging
- `<Leader>do` – step over

### Diagnostics list

- `<leader>tt` – toggle Trouble diagnostics list
- `[t` / `]t` – next/previous Trouble item

### Undo history

- `<leader>u` – toggle the undo tree viewer

### Git integration (vim-fugitive)

- `<leader>gs` – open Git status window
- In the status window:
  - `<leader>p` – push current branch
  - `<leader>P` – pull with rebase
  - `<leader>t` – push to a specified upstream branch
- During merge conflicts:
  - `gu` – accept ours (`//2`)
  - `gh` – accept theirs (`//3`)

## Useful built-in commands

| Action | Command |
| ------ | ------- |
| Yank current line | `yy` |
| Yank N lines | `Nyy` (e.g. `3yy`) |
| Delete current line | `dd` |
| Delete N lines | `Ndd` or `dNj` (e.g. `3dd`) |
| Jump six lines down | `6j` (up: `6k`) |
| Jump to line number *n* | `:n` or `nG` |

### Git workflow tips

1. Press `<leader>gs` to open the Git status window.
2. Stage files with `-` and commit using `:Git commit`.
3. Use `<leader>p` to push or `<leader>P` to pull with rebase.
4. Resolve merge conflicts using `gu` (ours) and `gh` (theirs).
