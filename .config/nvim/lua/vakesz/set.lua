-- Disable the GUI (blinking) cursor styling so it behaves like terminal Vim
vim.opt.guicursor = ""

-- Show the absolute line number for the current line
vim.opt.nu = true
-- Show line numbers relative to the cursor for all other lines
vim.opt.relativenumber = true

-- A hard tab (“\t”) counts for 4 spaces
vim.opt.tabstop = 4
-- In insert mode, hitting <Tab> or <BS> inserts/removes 4 spaces
vim.opt.softtabstop = 4
-- Number of spaces to use for each step of (auto)indent
vim.opt.shiftwidth = 4
-- Convert tabs to spaces
vim.opt.expandtab = true

-- Enable smart auto-indenting when starting a new line
vim.opt.smartindent = true

-- Don’t wrap long lines; let them scroll off-screen instead
vim.opt.wrap = false

-- Don’t create a swapfile (avoid `.swp` files)
vim.opt.swapfile = false
-- Don’t keep a backup file before overwriting (avoid `file~`)
vim.opt.backup = false
-- Directory to store persistent undo history
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
-- Enable persistent undo so you can undo across Vim sessions
vim.opt.undofile = true

-- Don’t highlight all matches after a search is done
vim.opt.hlsearch = false
-- Highlight matches as you type the search pattern
vim.opt.incsearch = true

-- Enable 24‑bit RGB color in the terminal
vim.opt.termguicolors = true

-- Always keep at least 8 lines visible above and below the cursor
vim.opt.scrolloff = 8
-- Always reserve a column for signs (e.g. GitGutter, diagnostics) to prevent text shifting
vim.opt.signcolumn = "yes"
-- Treat “@-@” as part of file names (makes it easier to edit things like “foo@bar-baz.txt”)
vim.opt.isfname:append("@-@")

-- Reduce the time Vim waits before triggering CursorHold events (e.g. for LSP diagnostics)
vim.opt.updatetime = 50

-- Visually mark the 80‑character column to encourage shorter lines
vim.opt.colorcolumn = "80"
