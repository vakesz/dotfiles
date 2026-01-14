-- Load custom key remappings from vakesz/remap.lua
require("vakesz.remap")

-- Load custom settings from vakesz/set.lua
require("vakesz.set")

-- Load lazy.nvim plugin manager
require("vakesz.lazy_init")

local augroup = vim.api.nvim_create_augroup
local vakeszGrp = augroup('vakesz', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

vim.filetype.add({
    extension = {
        templ = 'templ',
    }
})

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

autocmd({"BufWritePre"}, {
    group = vakeszGrp,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})