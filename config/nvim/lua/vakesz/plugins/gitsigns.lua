-- Git signs in the gutter and hunk management
-- Docs: https://github.com/lewis6991/gitsigns.nvim

return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add = { text = "▎" },
            change = { text = "▎" },
            delete = { text = "" },
            topdelete = { text = "" },
            changedelete = { text = "▎" },
        },
        on_attach = function(bufnr)
            local gs = package.loaded.gitsigns

            -- Navigation
            vim.keymap.set("n", "]h", gs.next_hunk, { buffer = bufnr, desc = "Next git hunk" })
            vim.keymap.set("n", "[h", gs.prev_hunk, { buffer = bufnr, desc = "Prev git hunk" })

            -- Actions
            vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { buffer = bufnr, desc = "Stage hunk" })
            vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { buffer = bufnr, desc = "Reset hunk" })
            vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
            vim.keymap.set("n", "<leader>hb", gs.blame_line, { buffer = bufnr, desc = "Blame line" })
            vim.keymap.set("n", "<leader>hd", gs.diffthis, { buffer = bufnr, desc = "Diff this" })

            -- Stage/reset visual selection
            vim.keymap.set("v", "<leader>hs", function()
                gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, { buffer = bufnr, desc = "Stage hunk" })
            vim.keymap.set("v", "<leader>hr", function()
                gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, { buffer = bufnr, desc = "Reset hunk" })
        end,
    },
}
