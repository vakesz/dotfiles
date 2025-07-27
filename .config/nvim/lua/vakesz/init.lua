-- Load custom key remappings from vakesz/remap.lua
require("vakesz.remap")
-- Load custom settings from vakesz/set.lua
require("vakesz.set")

-- Open netrw in the current window instead of splitting
vim.g.netrw_browse_split = 0
-- Disable the netrw banner at the top of the window
vim.g.netrw_banner = 0
-- Set the netrw window size to 25 columns
vim.g.netrw_winsize = 25
