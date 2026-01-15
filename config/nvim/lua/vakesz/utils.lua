-- Shared utility functions

local M = {}

function M.get_python_path()
    local cwd = vim.fn.getcwd()

    -- Check for venv (UV-created venvs work the same)
    for _, venv in ipairs({ '.venv', 'venv' }) do
        local path = cwd .. '/' .. venv .. '/bin/python'
        if vim.fn.executable(path) == 1 then
            return path
        end
    end

    -- Fall back to UV-managed Python
    if vim.fn.executable('uv') == 1 then
        local handle = io.popen('uv python find 2>/dev/null')
        if handle then
            local result = handle:read('*a')
            handle:close()
            if result and result ~= '' then
                return result:gsub('%s+$', '')
            end
        end
    end

    return 'python3'
end

return M
