# Neovim Keymaps Reference

`<leader>` = Space

Quick reference for all keymaps in this Neovim configuration. Generated from `config/nvim/lua/vakesz/`.

---

## Core Editing & Navigation

| Keys | Mode | Action |
|------|------|--------|
| `J` | n | Join line below, keep cursor in place |
| `J` / `K` | v | Move selected lines down / up |
| `<C-d>` / `<C-u>` | n | Half-page down / up & center view |
| `n` / `N` | n | Next / previous search result centered |
| `=ap` | n | Reindent paragraph (restores cursor) |
| `<leader>zig` | n | Restart all LSP clients (`:LspRestart`) |
| `<leader>p` | x | Paste over selection without yanking (blackhole) |
| `<leader>y` / `<leader>Y` | n,v / n | Yank to system clipboard (linewise for `Y`) |
| `<leader>d` | n,v | Delete without yanking (blackhole) |
| `<C-c>` | i | Escape to Normal mode |
| `Q` | n | Disabled (no-op) |
| `<leader>tp` | n | Run Plenary test file (`<Plug>PlenaryTestFile`) |
| `<leader>f` | n,v | Format current buffer/selection via conform.nvim |
| `<C-k>` / `<C-j>` | n | Next / previous quickfix item (center) |
| `<leader>k` / `<leader>j` | n | Next / previous location list item (center) |
| `<leader>s` | n | Substitute word under cursor across file (pre-fills command) |
| `<leader>x` | n | Make current file executable (`chmod +x`) |
| `<leader><leader>` | n | Source current file (`:so`) |

## Basic Vim Operations (Essentials)

Common built-ins not overridden by custom mappings.

### Selecting ("Highlighting") Text

| Action | Keys | Notes |
|--------|------|-------|
| Start character-wise visual | `v` | Then move with motions (`w`, `e`, `j`, etc.) |
| Start line-wise visual | `V` | Selects whole lines; repeat motions to expand |
| Start block visual | `<C-v>` | Column/block selection (great for multiple cursors–like edits) |
| Select entire file | `ggVG` | Go to top, linewise visual to bottom |
| Select inside word | `viw` | Without surrounding whitespace |
| Select a word (incl. whitespace) | `vaw` | “a word” text object |
| Select paragraph | `vap` / `vip` | Around / inside paragraph |
| Cancel visual mode | `<Esc>` | Keeps cursor at start (or end) |

### Copy / Yank

| Action | Keys | Notes |
|--------|------|-------|
| Yank current line | `yy` | Copies line (including newline) |
| Yank N lines | `4yy` | Example: 4 lines starting here |
| Yank to end of line | `y$` | From cursor to end |
| Yank to start of line | `y0` | From cursor back to column 0 |
| Yank inside word | `yiw` | Word under cursor |
| Yank paragraph | `yip` | Inside paragraph |
| Yank visual selection | (select) then `y` | Works in any visual mode |
| Yank whole file to system clipboard | `:%y+` | Uses `+` register (clipboard) |

### Paste

| Action | Keys | Notes |
|--------|------|-------|
| Paste after cursor | `p` | After cursor / below line |
| Paste before cursor | `P` | Before cursor / above line |
| Paste from system clipboard | `"+p` | Or `"*p` on some systems |
| Replace visual selection (keep original) | (select) then `p` | Original yanked into unnamed register |
| Our custom “paste without yanking” | Visual then `<leader>p` | Uses blackhole register |

### Delete

| Action | Keys | Notes |
|--------|------|-------|
| Delete current line | `dd` | Line removed, yanked into register |
| Delete N lines downward | `4dd` | Current + next 3 lines (total 4) |
| Delete current + next 4 lines | `d4j` | Inclusive motion (5 lines total) |
| Delete current + previous 4 lines | `d4k` | Cursor stays where motion ends |
| Delete inside word | `diw` | Removes word, leaves space |
| Change inside word | `ciw` | Delete + enter Insert mode |
| Delete to end of line | `D` | Equivalent to `d$` |
| Delete to start of line | `d0` | From cursor back |
| Delete inside parentheses | `di(` | Works with any surrounding pair |
| Delete without yanking (custom) | `<leader>d` | Uses blackhole register |

### Motions (Move Faster)

| Motion | Meaning |
|--------|---------|
| `w` / `b` | Next / previous word start |
| `e` / `ge` | Next / previous word end |
| `0` / `^` / `$` | Line start / first non-blank / line end |
| `gg` / `G` | Top / bottom of file |
| `{` / `}` | Previous / next blank-line paragraph |
| `(` / `)` | Previous / next sentence |
| `f{char}` / `t{char}` | Find / till (before) char on line |
| `;` / `,` | Repeat / reverse last `f`/`t`/`F`/`T` |
| `%` | Matching pair ((), {}, [], etc.) |
| `Ctrl-d` / `Ctrl-u` | Half‑page down / up (recenters via custom remap) |
| `Ctrl-f` / `Ctrl-b` | Page down / up |

### Counts + Motions

Prefix any motion with a number: `10w` (10 words forward), `5j` (down 5), `3f,` (3rd comma to right), etc.

### Practical Examples

| Goal | Keys |
|------|------|
| Copy 20 lines | `20yy` |
| Delete 4 lines (starting here) | `4dd` |
| Delete 4 lines above current | `d4k` |
| Select word & replace it | `ciw` then type new text |
| Copy whole file to clipboard | `ggVG"+y` or `:%y+` |
| Change text inside parentheses | `ci(` |
| Select block column 10–20 across 5 lines | Move to start, `<C-v>` then move down & right, `y`/`c` |

Tip: If you accidentally yank something over your unnamed register but wanted to preserve earlier content, use registers (`"0p` re-pastes last yanked text not from a delete/change).

## LSP (buffer-local, set on `LspAttach`)

| Keys | Mode | Action |
|------|------|--------|
| `gd` | n | Go to definition |
| `K` | n | Hover documentation |
| `<leader>vws` | n | Workspace symbol search |
| `<leader>vd` | n | Show line diagnostics in float |
| `<leader>vca` | n | Code actions |
| `<leader>vrr` | n | Show references |
| `<leader>vrn` | n | Rename symbol |
| `<C-h>` | i | Signature help |
| `[d` / `]d` | n | Previous / next diagnostic |

**Note**: Neovim 0.11+ also provides built-in LSP keymaps:

- `grn` - Rename symbol
- `gra` - Code action
- `grr` - Show references
- `gri` - Go to implementation
- `gO` - Document symbols

### Completion (nvim-cmp)

| Keys | Mode | Action |
|------|------|--------|
| `<C-p>` | i | Select previous completion item |
| `<C-n>` | i | Select next completion item |
| `<C-y>` | i | Confirm selection |
| `<C-Space>` | i | Trigger completion manually |

## Telescope (fuzzy finding)

| Keys | Action |
|------|--------|
| `<leader>pf` | Find files (respecting `.gitignore`) |
| `<C-p>` | Git tracked files |
| `<leader>ps` | Live grep (search text in files) |
| `<leader>pb` | Browse open buffers |
| `<leader>pws` | Grep word under cursor |
| `<leader>pWs` | Grep WORD under cursor |
| `<leader>pv` | File browser (in current directory) |
| `<leader>vh` | Help tags |
| `<leader>ft` | Find TODO comments in project |

## Testing (neotest)

Supports Go, Python, Zig, and PHP test adapters.

| Keys | Action |
|------|--------|
| `<leader>tc` | Run nearest test |
| `<leader>tf` | Run all tests in current file |
| `<leader>td` | Debug nearest test (with DAP) |
| `<leader>ts` | Toggle test summary panel |
| `<leader>to` | Open test output window |
| `<leader>tS` | Stop running tests |

## Debugging (nvim-dap + dap-ui)

Supports Go (delve), Python (debugpy), C/C++/Rust/Swift (codelldb) debuggers.

| Keys | Action |
|------|--------|
| `<leader>dt` | Toggle breakpoint |
| `<leader>dc` | Start / Continue debugging |
| `<leader>dx` | Terminate debugging session |
| `<leader>do` | Step over |

UI automatically opens/closes with debug sessions.

## Diagnostics & Lists (Trouble.nvim)

Trouble provides multiple toggles (each opens/closes its dedicated view):

| Keys | Action |
|------|--------|
| `<leader>xx` | Toggle workspace diagnostics |
| `<leader>xX` | Toggle buffer diagnostics |
| `<leader>cs` | Toggle symbols (outline) |
| `<leader>cl` | Toggle LSP definitions/references/etc (right panel) |
| `<leader>xL` | Toggle location list |
| `<leader>xQ` | Toggle quickfix list |

## Undo History (Undotree)

| Keys | Action |
|------|--------|
| `<leader>u` | Toggle Undotree panel |

## Mini.nvim Utilities

### Buffer Management

| Keys | Action |
|------|--------|
| `<leader>bd` | Delete current buffer (preserves window layout) |
| `<leader>bD` | Force delete current buffer |

### Surround Operations

Mini.surround provides easy manipulation of surrounding characters.

| Keys | Mode | Action | Example |
|------|------|--------|---------|
| `sa{motion}{char}` | n | Add surrounding | `saiw"` = surround word with " |
| `sd{char}` | n | Delete surrounding | `sd"` = delete surrounding " |
| `sr{old}{new}` | n | Replace surrounding | `sr"'` = replace " with ' |

Common examples:

- `saiw"` - Surround inner word with quotes
- `sa)` - Add parentheses around selection
- `sd]` - Delete surrounding brackets
- `sr"'` - Change double quotes to single quotes

### Indent Guides

Automatic visual indent guides with scope highlighting (always visible).

## TODO Comments

Highlights and navigates TODO, FIXME, HACK, WARN, PERF, NOTE, TEST comments in code.

| Keys | Action |
|------|--------|
| `]t` | Jump to next TODO comment |
| `[t` | Jump to previous TODO comment |
| `<leader>ft` | Find all TODOs with Telescope |

## Git (vim-fugitive)

| Keys | Context | Action |
|------|---------|--------|
| `<leader>gs` | any | Open Git status (fugitive) |
| `<leader>gp` | fugitive status buffer | Git push |
| `<leader>gP` | fugitive status buffer | Git pull --rebase |
| `<leader>gt` | fugitive status buffer | Prepare `Git push -u origin ...` |
| `gu` | merge diff | Accept OURS (diffget //2) |
| `gh` | merge diff | Accept THEIRS (diffget //3) |

## Git Signs (gitsigns.nvim)

Inline git change indicators in the gutter.

| Keys | Mode | Action |
|------|------|--------|
| `]h` / `[h` | n | Next / previous git hunk |
| `<leader>hs` | n,v | Stage hunk (or visual selection) |
| `<leader>hr` | n,v | Reset hunk (or visual selection) |
| `<leader>hp` | n | Preview hunk diff |
| `<leader>hb` | n | Show git blame for current line |
| `<leader>hd` | n | Diff this file |

## Which-Key Leader Groups

Press `<leader>` and wait to see available commands organized by category:

| Prefix | Category |
|--------|----------|
| `<leader>c` | Code actions |
| `<leader>d` | Debug operations |
| `<leader>f` | Format buffer |
| `<leader>g` | Git operations |
| `<leader>h` | Git hunks (gitsigns) |
| `<leader>p` | Project/Find (Telescope) |
| `<leader>t` | Test operations |
| `<leader>v` | LSP operations |
| `<leader>x` | Diagnostics |
| `<leader>b` | Buffer operations |
| `<leader>?` | Show buffer-local keymaps |

## Misc / Aesthetics

| Aspect | Notes |
|--------|-------|
| Colorscheme | `github_dark_colorblind` with transparent background |
| Statusline | Mini.statusline with icons and git integration |
| Treesitter | Auto-install & syntax highlighting for all languages |
| Clipboard | System clipboard integration via `<leader>y` / `<leader>Y` |
| Auto-trim | Trailing whitespace removed on save |
| Yank highlight | Briefly highlights yanked text |
| Indent guides | Visual indent scope with `│` character |

## Plugin Commands & Entrypoints

| Plugin | Primary Commands / Notes |
|--------|--------------------------|
| lazy.nvim | `:Lazy` - Manage plugins (install, update, clean) |
| trouble.nvim | `:Trouble diagnostics toggle`, `:Trouble symbols toggle` |
| vim-fugitive | `:Git`, `:Gdiffsplit`, `:Gblame`, `:Git commit` |
| gitsigns.nvim | `:Gitsigns` - Git hunk operations |
| undotree | `:UndotreeToggle` (mapped to `<leader>u`) |
| nvim-dap / dap-ui | Use keymaps; `:lua require'dap'.repl.open()` for REPL |
| conform.nvim | Format via `<leader>f` or `:ConformInfo` |
| which-key.nvim | `<leader>?` - Show buffer-local keymaps |
| neotest | Use keymaps; `:lua require('neotest').summary.toggle()` |
| telescope.nvim | `:Telescope` - Browse all pickers |
| mason.nvim | `:Mason` - Manage LSP servers, DAP adapters, linters |
| todo-comments.nvim | `:TodoTelescope`, `:TodoQuickFix`, `:TodoLocList` |
| mini.nvim | Multiple utilities (statusline, surround, indentscope, bufremove) |
| GitHub Copilot | Auto-completion integration via nvim-cmp; `Alt+l` to accept |

## Built-In Essentials (Reference)

| Action | Keys / Command |
|--------|----------------|
| Save / Quit | `:w`, `:wq`, `:q`, `:qa`, `:q!` |
| Splits | `:vsp`, `:sp`, move: `<C-w> h/j/k/l`, resize: `<C-w>=` / `<C-w>+/-` / `<C-w><` / `<C-w>>` |
| Tabs | `:tabnew`, `:tabclose`, next/prev: `gt` / `gT` |
| Buffers | Next / prev: `:bn` / `:bp`, close: `:bd` |
| Search word under cursor | `*` / `#` |
| Increment / Decrement number | `<C-a>` / `<C-x>` |
| Start / End of file | `gg` / `G` |
| Start / End of line | `0` / `$` |
| Clear search highlight | `:noh` |

## Installed LSP Servers

Auto-installed via mason-lspconfig:

- **Lua**: `lua_ls` (workspace configured for Neovim)
- **Python**: `pyright` (formatting disabled, use ruff via conform)
- **C/C++**: `clangd`
- **TypeScript/JavaScript**: `ts_ls`

Other servers can be added via `:Mason` and will be auto-configured.

## Discovering Keymaps

| Task | Command |
|------|---------|
| Show all leader mappings | `:verbose map <leader>` |
| Show all normal mode mappings | `:nmap` |
| Browse keymaps with Telescope | `:Telescope keymaps` |
| Show buffer-local keymaps | `<leader>?` (which-key) |

## Maintenance

When adding plugin keymaps:
1. Define them in the plugin's lazy spec file (`lua/vakesz/lazy/*.lua`)
2. For LSP keymaps, add to the `LspAttach` autocmd in `lua/vakesz/init.lua`
3. Update this KEYMAPS.md file

---

Happy hacking!
