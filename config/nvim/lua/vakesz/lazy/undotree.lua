-- Visualize Vim undo history
-- Docs: https://github.com/mbbill/undotree

return {
    "mbbill/undotree",
    keys = {
        { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle undotree" },
    },
    cmd = "UndotreeToggle",
}
