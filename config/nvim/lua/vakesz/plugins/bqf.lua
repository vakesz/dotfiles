-- Better quickfix window with preview and fuzzy search
-- Docs: https://github.com/kevinhwang91/nvim-bqf

return {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {
        preview = {
            win_height = 12,
            win_vheight = 12,
            delay_syntax = 80,
            border = "rounded",
        },
        func_map = {
            vsplit = "",
            ptogglemode = "z,",
            stoggleup = "",
        },
        filter = {
            fzf = {
                action_for = { ["ctrl-s"] = "split" },
                extra_opts = { "--bind", "ctrl-o:toggle-all", "--prompt", "> " },
            },
        },
    },
}
