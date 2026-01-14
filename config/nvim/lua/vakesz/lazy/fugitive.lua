-- Git integration powered by fugitive
-- Docs: https://github.com/tpope/vim-fugitive

return {
    "tpope/vim-fugitive",
    cmd = "Git",
    keys = {
        { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
        { "gu", "<cmd>diffget //2<cr>", desc = "Diffget ours (merge conflict)" },
        { "gh", "<cmd>diffget //3<cr>", desc = "Diffget theirs (merge conflict)" },
    },
    config = function()
        local vakeszGrp_Fugitive = vim.api.nvim_create_augroup("vakeszGrp_Fugitive", {})
        local autocmd = vim.api.nvim_create_autocmd

        autocmd("BufWinEnter", {
            group = vakeszGrp_Fugitive,
            pattern = "*",
            callback = function()
                if vim.bo.ft ~= "fugitive" then
                    return
                end

                local bufnr = vim.api.nvim_get_current_buf()
                local opts = { buffer = bufnr, remap = false }

                vim.keymap.set("n", "<leader>gp", function()
                    vim.cmd.Git("push")
                end, opts)

                vim.keymap.set("n", "<leader>gP", function()
                    vim.cmd.Git({ "pull", "--rebase" })
                end, opts)

                vim.keymap.set("n", "<leader>gt", ":Git push -u origin ", opts)
            end,
        })
    end,
}