# Neovim Keymaps Reference

`<leader>` = Space

Quick reference for repo-defined mappings first, followed by built-in and plugin-default references that are useful while learning.

## Repo-Defined Keymaps

### Core Editing & Navigation

| Keys | Mode | Action |
| --- | --- | --- |
| `J` | n | Join line below and keep cursor in place |
| `J` / `K` | v | Move selected lines down / up |
| `<C-d>` / `<C-u>` | n | Half-page down / up and center the view |
| `n` / `N` | n | Next / previous search result and center the view |
| `=ap` | n | Reindent paragraph and restore cursor |
| `<leader>zig` | n | Restart all LSP clients |
| `<leader>p` | x | Paste over selection without yanking |
| `<leader>y` / `<leader>Y` | n,v / n | Yank to system clipboard |
| `<leader>d` | n,v | Delete without yanking to the clipboard |
| `<C-c>` | i | Escape to Normal mode |
| `Q` | n | Disabled |
| `<leader>ff` | n,v | Format buffer via conform.nvim |
| `<C-k>` / `<C-j>` | n | Next / previous quickfix item |
| `<leader>k` / `<leader>j` | n | Next / previous location list item |
| `<leader>s` | n | Substitute word under cursor across the current file |
| `<leader>cx` | n | Make current file executable |
| `<leader>pv` | n | Open netrw file explorer |
| `<leader><leader>` | n | Source current file |

### LSP (Language Server Protocol)

These mappings are defined by the repo and become active when an LSP attaches to the current buffer.

| Keys | Mode | Action |
| --- | --- | --- |
| `<leader>vws` | n | Workspace symbol search |
| `<leader>vd` | n | Show line diagnostics |
| `<leader>vca` | n | Code actions |
| `<leader>vrr` | n | Show references |
| `<leader>vrn` | n | Rename symbol |
| `<C-h>` | i,s | Previous snippet tabstop / Signature help |

### Completion (native vim.lsp.completion)

Autotrigger is enabled — completions appear as you type when an LSP is attached.

| Keys | Mode | Action |
| --- | --- | --- |
| `<C-n>` | i | Next completion item |
| `<C-p>` | i | Previous completion item |
| `<C-y>` | i | Confirm selection |
| `<C-Space>` | i | Trigger completion manually |
| `<C-x><C-f>` | i | Path completion (built-in) |
| `<C-l>` | i,s | Next snippet tabstop |

### Copilot

| Keys | Mode | Action |
| --- | --- | --- |
| `<M-l>` | i | Accept suggestion |
| `<M-]>` | i | Next suggestion |
| `<M-[>` | i | Previous suggestion |
| `<C-]>` | i | Dismiss suggestion |

### Telescope (Fuzzy Finding)

| Keys | Action |
| --- | --- |
| `<leader>pf` | Find files |
| `<C-p>` | Git tracked files |
| `<leader>ps` | Live grep |
| `<leader>pb` | Browse open buffers |
| `<leader>pe` | File browser in the current file's directory |
| `<leader>pws` | Grep word under cursor |
| `<leader>pWs` | Grep WORD under cursor |
| `<leader>vh` | Help tags |

### Diagnostics (Trouble.nvim)

| Keys | Action |
| --- | --- |
| `<leader>xx` | Toggle workspace diagnostics |
| `<leader>xX` | Toggle buffer diagnostics |
| `<leader>cs` | Toggle symbols outline |
| `<leader>cl` | Toggle LSP items panel |
| `<leader>xL` | Toggle location list |
| `<leader>xQ` | Toggle quickfix list |

### Buffer Management (mini.bufremove)

| Keys | Action |
| --- | --- |
| `<leader>bd` | Delete buffer and keep layout |
| `<leader>bD` | Force delete buffer |

### Surround Operations (mini.surround defaults)

The repo enables `mini.surround` with its default keymaps.

| Keys | Mode | Action |
| --- | --- | --- |
| `sa{motion}{char}` | n | Add surrounding |
| `sd{char}` | n | Delete surrounding |
| `sr{old}{new}` | n | Replace surrounding |

Examples:

- `saiw"` surrounds the current word with double quotes
- `sd(` deletes surrounding parentheses
- `sr"'` replaces double quotes with single quotes

### Undo History (built-in :Undotree)

| Keys | Action |
| --- | --- |
| `<leader>u` | Toggle Undotree |

### TODO Comments

| Keys | Action |
| --- | --- |
| `]t` | Next TODO comment |
| `[t` | Previous TODO comment |
| `<leader>ft` | Find TODO comments with Telescope |

### Git (vim-fugitive)

| Keys | Context | Action |
| --- | --- | --- |
| `<leader>gs` | any | Open Git status |
| `<leader>gp` | Fugitive buffer | Git push |
| `<leader>gP` | Fugitive buffer | Git pull --rebase |
| `<leader>gt` | Fugitive buffer | Push to a new remote branch |
| `gu` | merge diff | Accept ours |
| `gh` | merge diff | Accept theirs |

### Git Hunks (gitsigns.nvim)

| Keys | Mode | Action |
| --- | --- | --- |
| `]h` / `[h` | n | Next / previous hunk |
| `<leader>hs` | n,v | Stage hunk |
| `<leader>hr` | n,v | Reset hunk |
| `<leader>hp` | n | Preview hunk diff |
| `<leader>hb` | n | Show git blame |
| `<leader>hd` | n | Diff this file |

### Which-Key Groups

Press `<leader>` and wait to see available commands.

| Prefix | Category |
| --- | --- |
| `<leader>b` | Buffer |
| `<leader>c` | Code |
| `<leader>f` | Format / Find |
| `<leader>g` | Git |
| `<leader>h` | Git Hunks |
| `<leader>p` | Project / Find |
| `<leader>v` | LSP |
| `<leader>x` | Diagnostics |
| `<leader>?` | Show buffer-local keymaps |

## Defaults and Learning Reference

These are built-in Vim or Neovim behaviors that are useful to keep nearby while learning. They are not defined in this repo unless noted above.

### Movement

| Motion | Action |
| --- | --- |
| `w` / `b` | Next / previous word start |
| `e` / `ge` | Next / previous word end |
| `0` / `^` / `$` | Line start / first non-blank / line end |
| `gg` / `G` | Top / bottom of file |
| `{` / `}` | Previous / next paragraph |
| `(` / `)` | Previous / next sentence |
| `f{char}` / `t{char}` | Find / till character on the current line |
| `F{char}` / `T{char}` | Same motions backward |
| `;` / `,` | Repeat / reverse last `f` or `t` motion |
| `%` | Matching pair |
| `<C-d>` / `<C-u>` | Half-page down / up |
| `<C-f>` / `<C-b>` | Full page down / up |
| `H` / `M` / `L` | Top / middle / bottom of screen |

### Text Objects

Use with operators like `d`, `c`, `y`, or with visual mode.

| Object | Inner (`i`) | Around (`a`) |
| --- | --- | --- |
| `w` | Word | Word plus space |
| `s` | Sentence | Sentence plus space |
| `p` | Paragraph | Paragraph plus blank lines |
| `(` / `)` / `b` | Inside parentheses | Including parentheses |
| `{` / `}` / `B` | Inside braces | Including braces |
| `[` / `]` | Inside brackets | Including brackets |
| `<` / `>` | Inside angle brackets | Including angle brackets |
| `"` / `'` / `` ` `` | Inside quotes | Including quotes |
| `t` | Inside XML / HTML tag | Including the tag |

Examples:

- `ciw` changes the current word
- `da"` deletes around quotes
- `yip` yanks the current paragraph
- `vi{` selects inside braces

### Visual Selection

| Keys | Action |
| --- | --- |
| `v` | Start character-wise visual mode |
| `V` | Start line-wise visual mode |
| `<C-v>` | Start block visual mode |
| `gv` | Reselect last visual selection |
| `o` | Jump to the other end of the selection |

### Operators

| Operator | Action |
| --- | --- |
| `d` | Delete |
| `c` | Change |
| `y` | Yank |
| `>` / `<` | Indent / outdent |
| `=` | Auto-indent |
| `gU` / `gu` | Uppercase / lowercase |

### Registers

| Register | Description |
| --- | --- |
| `""` | Unnamed register |
| `"0` | Last yank |
| `"1-9` | Delete history |
| `"+` | System clipboard |
| `"*` | Primary selection on X11 |
| `"_` | Blackhole register |

Usage example: `"+y` yanks into the system clipboard.

### Marks

| Keys | Action |
| --- | --- |
| `m{a-z}` | Set local mark |
| `m{A-Z}` | Set global mark |
| `` `{mark} `` | Jump to exact mark position |
| `'{mark}` | Jump to mark line |
| `` `. `` | Jump to last change |
| `` `^ `` | Jump to last insert |

### Treesitter Selection (built-in, nvim 0.12+)

| Keys | Mode | Action |
| --- | --- | --- |
| `an` | v | Select around node |
| `in` | v | Select inside node |
| `]n` | v | Next node |
| `[n` | v | Previous node |

### Neovim LSP Defaults

These are built-in Neovim LSP / diagnostic mappings available when an LSP is attached. They are not explicitly defined in this repo.

| Keys | Mode | Action |
| --- | --- | --- |
| `gd` | n | Go to definition |
| `grt` | n | Go to type definition |
| `grx` | n | Run code lens |
| `K` | n | Hover documentation |
| `[d` / `]d` | n | Previous / next diagnostic |

### Built-In Essentials

| Action | Keys / Command |
| --- | --- |
| Save | `:w` |
| Quit | `:q`, `:q!`, `:wq` |
| Vertical split | `:vsp` |
| Horizontal split | `:sp` |
| Navigate splits | `<C-w>h/j/k/l` |
| Close split | `<C-w>q` |
| Equalize splits | `<C-w>=` |
| Search word under cursor | `*` / `#` |
| Increment / decrement | `<C-a>` / `<C-x>` |
| Clear search highlight | `:noh` |
| Undo / redo | `u` / `<C-r>` |
| Repeat last change | `.` |
| Record macro | `q{register}` |
| Play macro | `@{register}` |

## Useful Commands

| Plugin / Area | Command |
| --- | --- |
| lazy.nvim | `:Lazy` |
| telescope.nvim | `:Telescope` |
| trouble.nvim | `:Trouble` |
| vim-fugitive | `:Git` |
| conform.nvim | `:ConformInfo` |
| copilot.lua | `:Copilot` |
| undotree (built-in) | `:Undotree` |

## LSP Servers (installed via Homebrew)

- Lua: `lua_ls`
- Python: `pyright`
- C/C++: `clangd`
- TypeScript: `ts_ls`
- Go: `gopls`
- Ruby: `ruby_lsp`
- Bash: `bashls`
- Swift: `sourcekit`

Add more via Homebrew and `vim.lsp.enable()` in `lua/vakesz/lazy/lsp.lua`.

## Maintenance Notes

- Core keymaps live in `lua/vakesz/remap.lua`.
- Plugin keymaps live in `lua/vakesz/lazy/*.lua`.
- LSP mappings live in `lua/vakesz/lazy/lsp.lua`.
- Update this file when you change mappings.
