-- Formatting plugin that wraps multiple formatters
-- Docs: https://github.com/stevearc/conform.nvim

return {
    'stevearc/conform.nvim',
    opts = {}, -- default options
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" }, -- Lua formatter: https://github.com/JohnnyMorganz/StyLua
                go = { "gofmt" }, -- Go formatter: https://pkg.go.dev/cmd/gofmt
                javascript = { "prettier" }, -- JS/TS formatter: https://prettier.io/
                typescript = { "prettier" },
                elixir = { "mix" }, -- Elixir formatter via mix format
            }
        })
    end
}