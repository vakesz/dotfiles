-- Shared utility functions

local M = {}

function M.get_python_path()
    local cwd = vim.fn.getcwd()
    for _, venv in ipairs({ '.venv', 'venv' }) do
        local path = cwd .. '/' .. venv .. '/bin/python'
        if vim.fn.executable(path) == 1 then
            return path
        end
    end
    return 'python3'
end

return M
