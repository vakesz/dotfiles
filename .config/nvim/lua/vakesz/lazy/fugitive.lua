-- Git integration powered by fugitive
-- Docs: https://github.com/tpope/vim-fugitive

return {
    "tpope/vim-fugitive",
    config = function()
        vim.keymap.set("n", "<leader>gs", vim.cmd.Git) -- open Git status window

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
                local opts = {buffer = bufnr, remap = false}
                vim.keymap.set("n", "<leader>p", function()
                    vim.cmd.Git('push') -- push current branch
                end, opts)

                -- rebase always
                vim.keymap.set("n", "<leader>P", function()
                    vim.cmd.Git({'pull',  '--rebase'}) -- pull with rebase
                end, opts)

                -- Allows specifying remote branch for push
                vim.keymap.set("n", "<leader>t", ":Git push -u origin ", opts)
            end,
        })

        -- Diffget shortcuts for resolving merges
        vim.keymap.set("n", "gu", "<cmd>diffget //2<CR>") -- ours
        vim.keymap.set("n", "gh", "<cmd>diffget //3<CR>") -- theirs
    end
}