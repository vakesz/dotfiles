-- Live markdown preview using Deno
-- Docs: https://github.com/toppair/peek.nvim

return {
    {
    "toppair/peek.nvim",
    event = { "VeryLazy" }, -- load plugin when UI is idle
    build = "deno task --quiet build:fast", -- combile with Deno
    config = function()
        require("peek").setup()
        vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
        vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    end,
},
}