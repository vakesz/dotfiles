# Neovim Keymaps Reference

`<leader>` = Space

Quick reference for all keymaps in this Neovim configuration.

---

## Core Editing & Navigation

| Keys | Mode | Action |
| ------ | ------ | -------- |
| `J` | n | Join line below, keep cursor in place |
| `J` / `K` | v | Move selected lines down / up |
| `<C-d>` / `<C-u>` | n | Half-page down / up & center view |
| `n` / `N` | n | Next / previous search result centered |
| `=ap` | n | Reindent paragraph (restores cursor) |
| `<leader>zig` | n | Restart all LSP clients (`:LspRestart`) |
| `<leader>p` | x | Paste over selection without yanking |
| `<leader>y` / `<leader>Y` | n,v / n | Yank to system clipboard |
| `<leader>d` | n,v | Delete without yanking (blackhole) |
| `<C-c>` | i | Escape to Normal mode |
| `Q` | n | Disabled (no-op) |
| `<leader>tp` | n | Run Plenary test file |
| `<leader>f` | n,v | Format buffer via conform.nvim |
| `<C-k>` / `<C-j>` | n | Next / previous quickfix item |
| `<leader>k` / `<leader>j` | n | Next / previous location list item |
| `<leader>s` | n | Substitute word under cursor across file |
| `<leader>x` | n | Make current file executable (`chmod +x`) |
| `<leader><leader>` | n | Source current file (`:so`) |

---

## Vim Motions & Text Objects

### Movement

| Motion | Action |
| -------- | -------- |
| `w` / `b` | Next / previous word start |
| `e` / `ge` | Next / previous word end |
| `0` / `^` / `$` | Line start / first non-blank / line end |
| `gg` / `G` | Top / bottom of file |
| `{` / `}` | Previous / next paragraph |
| `(` / `)` | Previous / next sentence |
| `f{char}` / `t{char}` | Find / till (before) char on line |
| `F{char}` / `T{char}` | Same but backwards |
| `;` / `,` | Repeat / reverse last f/t motion |
| `%` | Matching pair ((), {}, []) |
| `<C-d>` / `<C-u>` | Half-page down / up (centered) |
| `<C-f>` / `<C-b>` | Full page down / up |
| `H` / `M` / `L` | Top / middle / bottom of screen |

### Text Objects

Use with operators (d, c, y, v): `{operator}{a/i}{object}`

| Object | Inner (`i`) | Around (`a`) |
| -------- | ------------- | -------------- |
| `w` | Word | Word + space |
| `s` | Sentence | Sentence + space |
| `p` | Paragraph | Paragraph + blank lines |
| `(` / `)` / `b` | Inside parens | Including parens |
| `{` / `}` / `B` | Inside braces | Including braces |
| `[` / `]` | Inside brackets | Including brackets |
| `<` / `>` | Inside angle brackets | Including brackets |
| `"` / `'` / `` ` `` | Inside quotes | Including quotes |
| `t` | Inside XML/HTML tag | Including tag |

Examples:

- `ciw` - Change inner word
- `da"` - Delete around quotes (including quotes)
- `yip` - Yank inner paragraph
- `vi{` - Select inside braces

### Visual Selection

| Keys | Action |
| ------ | -------- |
| `v` | Start character-wise visual |
| `V` | Start line-wise visual |
| `<C-v>` | Start block visual (column) |
| `gv` | Reselect last visual selection |
| `o` | Jump to other end of selection |

### Operators

| Operator | Action |
| ---------- | -------- |
| `d` | Delete |
| `c` | Change (delete + insert) |
| `y` | Yank (copy) |
| `>` / `<` | Indent / outdent |
| `=` | Auto-indent |
| `gU` / `gu` | Uppercase / lowercase |

### Registers

| Register | Description |
| ---------- | ------------- |
| `""` | Unnamed (default) |
| `"0` | Last yank |
| `"1-9` | Delete history |
| `"+` | System clipboard |
| `"*` | Primary selection (X11) |
| `"_` | Blackhole (discard) |

Usage: `"{register}{operator}` e.g., `"+y` to yank to clipboard

### Marks

| Keys | Action |
| ------ | -------- |
| `m{a-z}` | Set local mark |
| `m{A-Z}` | Set global mark |
| `` `{mark} `` | Jump to mark (exact position) |
| `'{mark}` | Jump to mark (line start) |
| `` `. `` | Jump to last change |
| `` `^ `` | Jump to last insert |

---

## LSP (Language Server Protocol)

Buffer-local keymaps, active when LSP attaches.

| Keys | Mode | Action |
| ------ | ------ | -------- |
| `gd` | n | Go to definition |
| `K` | n | Hover documentation |
| `<leader>vws` | n | Workspace symbol search |
| `<leader>vd` | n | Show line diagnostics |
| `<leader>vca` | n | Code actions |
| `<leader>vrr` | n | Show references |
| `<leader>vrn` | n | Rename symbol |
| `<C-h>` | i | Signature help |

### Completion (nvim-cmp)

| Keys | Mode | Action |
| ------ | ------ | -------- |
| `<C-p>` | i | Previous completion item |
| `<C-n>` | i | Next completion item |
| `<C-y>` | i | Confirm selection |
| `<C-Space>` | i | Trigger completion |

---

## Copilot (AI Completion)

| Keys | Mode | Action |
| ------ | ------ | -------- |
| `<M-l>` | i | Accept suggestion (Alt+l) |
| `<M-]>` | i | Next suggestion (Alt+]) |
| `<M-[>` | i | Previous suggestion (Alt+[) |
| `<C-]>` | i | Dismiss suggestion |

---

## Telescope (Fuzzy Finding)

| Keys | Action |
| ------ | -------- |
| `<leader>pf` | Find files |
| `<C-p>` | Git tracked files |
| `<leader>ps` | Live grep (search text) |
| `<leader>pb` | Browse open buffers |
| `<leader>pv` | Open netrw (file explorer) |
| `<leader>pe` | File browser (Telescope) |
| `<leader>pws` | Grep word under cursor |
| `<leader>pWs` | Grep WORD under cursor |
| `<leader>vh` | Help tags |
| `<leader>ft` | Find TODO comments |

---

## Diagnostics (Trouble.nvim)

| Keys | Action |
| ------ | -------- |
| `<leader>xx` | Toggle workspace diagnostics |
| `<leader>xX` | Toggle buffer diagnostics |
| `<leader>cs` | Toggle symbols outline |
| `<leader>cl` | Toggle LSP references panel |
| `<leader>xL` | Toggle location list |
| `<leader>xQ` | Toggle quickfix list |

---

## Buffer Management (mini.bufremove)

| Keys | Action |
| ------ | -------- |
| `<leader>bd` | Delete buffer (keep layout) |
| `<leader>bD` | Force delete buffer |

---

## Surround Operations (mini.surround)

| Keys | Mode | Action |
| ------ | ------ | -------- |
| `sa{motion}{char}` | n | Add surrounding |
| `sd{char}` | n | Delete surrounding |
| `sr{old}{new}` | n | Replace surrounding |

Examples:

- `saiw"` - Surround word with quotes
- `sd(` - Delete surrounding parens
- `sr"'` - Replace double with single quotes

---

## Undo History

| Keys | Action |
| ------ | -------- |
| `<leader>u` | Toggle Undotree panel |

---

## TODO Comments

| Keys | Action |
| ------ | -------- |
| `]t` | Next TODO comment |
| `[t` | Previous TODO comment |
| `<leader>ft` | Find TODOs with Telescope |

---

## Git (vim-fugitive)

| Keys | Context | Action |
| ------ | --------- | -------- |
| `<leader>gs` | any | Open Git status |
| `<leader>gp` | fugitive | Git push |
| `<leader>gP` | fugitive | Git pull --rebase |
| `<leader>gt` | fugitive | Push to new branch |
| `gu` | merge diff | Accept OURS |
| `gh` | merge diff | Accept THEIRS |

---

## Git Hunks (gitsigns.nvim)

| Keys | Mode | Action |
| ------ | ------ | -------- |
| `]h` / `[h` | n | Next / previous hunk |
| `<leader>hs` | n,v | Stage hunk |
| `<leader>hr` | n,v | Reset hunk |
| `<leader>hp` | n | Preview hunk diff |
| `<leader>hb` | n | Show git blame |
| `<leader>hd` | n | Diff this file |

---

## Which-Key Groups

Press `<leader>` and wait to see available commands:

| Prefix | Category |
| -------- | ---------- |
| `<leader>b` | Buffer |
| `<leader>c` | Code |
| `<leader>f` | Format |
| `<leader>g` | Git |
| `<leader>h` | Git Hunks |
| `<leader>p` | Project/Find |
| `<leader>v` | LSP |
| `<leader>x` | Diagnostics |
| `<leader>?` | Show buffer keymaps |

---

## Built-In Essentials

| Action | Keys |
| -------- | ------ |
| Save | `:w` |
| Quit | `:q`, `:q!`, `:wq` |
| Vertical split | `:vsp` |
| Horizontal split | `:sp` |
| Navigate splits | `<C-w>h/j/k/l` |
| Close split | `<C-w>q` |
| Equal splits | `<C-w>=` |
| Search word under cursor | `*` / `#` |
| Increment / Decrement | `<C-a>` / `<C-x>` |
| Clear search highlight | `:noh` |
| Undo / Redo | `u` / `<C-r>` |
| Repeat last change | `.` |
| Record macro | `q{register}` |
| Play macro | `@{register}` |

---

## Plugin Commands

| Plugin | Command |
| -------- | --------- |
| lazy.nvim | `:Lazy` |
| mason.nvim | `:Mason` |
| telescope.nvim | `:Telescope` |
| trouble.nvim | `:Trouble` |
| vim-fugitive | `:Git` |
| conform.nvim | `:ConformInfo` |

---

## LSP Servers (auto-installed)

- **Lua**: lua_ls
- **Python**: pyright
- **C/C++**: clangd
- **TypeScript**: ts_ls

Add more via `:Mason`.

---

## Maintenance

When adding keymaps:

1. Plugin keymaps go in `lua/vakesz/lazy/*.lua`
2. LSP keymaps are in `lua/vakesz/lazy/lsp.lua`
3. Core keymaps are in `lua/vakesz/remap.lua`
4. Update this file!
