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
                "delve",      -- Go debugger
                "python",     -- Python debugger (debugpy)
                "codelldb",   -- C/C++/Rust/Swift debugger
            }
        })

        -- Go debugger setup
        if vim.fn.executable("go") == 1 then
            dap_go.setup() -- only configure Go DAP if Go is installed
        end

        -- Python debugger setup
        dap.adapters.python = {
            type = 'executable',
            command = 'python3',
            args = { '-m', 'debugpy.adapter' },
        }

        dap.configurations.python = {
            {
                type = 'python',
                request = 'launch',
                name = 'Launch file',
                program = '${file}',
                pythonPath = function()
                    -- Try to use virtual environment first
                    local cwd = vim.fn.getcwd()
                    if vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                        return cwd .. '/.venv/bin/python'
                    elseif vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                        return cwd .. '/venv/bin/python'
                    else
                        return 'python3'
                    end
                end,
            },
            {
                type = 'python',
                request = 'launch',
                name = 'Launch file with arguments',
                program = '${file}',
                args = function()
                    local args_string = vim.fn.input('Arguments: ')
                    return vim.split(args_string, " +")
                end,
                pythonPath = function()
                    local cwd = vim.fn.getcwd()
                    if vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                        return cwd .. '/.venv/bin/python'
                    elseif vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                        return cwd .. '/venv/bin/python'
                    else
                        return 'python3'
                    end
                end,
            },
            {
                type = 'python',
                request = 'attach',
                name = 'Attach remote',
                connect = function()
                    local host = vim.fn.input('Host [127.0.0.1]: ')
                    host = host ~= '' and host or '127.0.0.1'
                    local port = tonumber(vim.fn.input('Port [5678]: ')) or 5678
                    return { host = host, port = port }
                end,
            },
        }

        -- C/C++/Rust/Swift debugger setup (codelldb)
        dap.adapters.codelldb = {
            type = 'server',
            port = '${port}',
            executable = {
                command = vim.fn.stdpath('data') .. '/mason/bin/codelldb',
                args = { '--port', '${port}' },
            }
        }

        dap.configurations.cpp = {
            {
                name = 'Launch file',
                type = 'codelldb',
                request = 'launch',
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                end,
                cwd = '${workspaceFolder}',
                stopOnEntry = false,
            },
        }

        -- Use same config for C
        dap.configurations.c = dap.configurations.cpp

        -- Rust configuration
        dap.configurations.rust = {
            {
                name = 'Launch file',
                type = 'codelldb',
                request = 'launch',
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
                end,
                cwd = '${workspaceFolder}',
                stopOnEntry = false,
            },
        }

        -- Swift configuration
        dap.configurations.swift = {
            {
                name = 'Launch file',
                type = 'codelldb',
                request = 'launch',
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/.build/debug/', 'file')
                end,
                cwd = '${workspaceFolder}',
                stopOnEntry = false,
            },
        }

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