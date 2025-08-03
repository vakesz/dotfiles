-- Debug Adapter Protocol integration
-- Docs: https://github.com/mfussenegger/nvim-dap

return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui", -- UI for nvim-dap https://github.com/rcarriga/nvim-dap-ui
        "nvim-neotest/nvim-nio", -- async library required by dap-ui
        "leoluz/nvim-dap-go", -- Go debug adapter https://github.com/leoluz/nvim-dap-go
        "williamboman/mason.nvim", -- package manager for DAP servers
        "jay-babu/mason-nvim-dap.nvim", -- bridge between mason and nvim-dap
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")
        local dap_go = require("dap-go")

        require("mason-nvim-dap").setup({
            automatic_installation = true, -- install adapters automatically
            handlers = {},
            ensure_installed = {
                -- "delve", -- example: Go debugger
            }
        })

        if vim.fn.executable("go") == 1 then
            dap_go.setup() -- only configure Go DAP if Go is installed
        end
        dapui.setup() -- setup UI panels

        -- Open/close dap-ui automatically
        dap.listeners.before.attach.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
            dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            dapui.close()
        end

        -- Key mappings for common DAP actions
        vim.keymap.set("n", "<Leader>dt", dap.toggle_breakpoint, {}) -- toggle breakpoint
        vim.keymap.set("n", "<Leader>dc", dap.continue, {}) -- start/continue debugging
        vim.keymap.set("n", "<Leader>dx", dap.terminate, {}) -- stop debugging
        vim.keymap.set("n", "<Leader>do", dap.step_over, {}) -- step over
    end,
}