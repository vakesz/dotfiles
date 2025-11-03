-- Formatting plugin that wraps multiple formatters
-- Docs: https://github.com/stevearc/conform.nvim

return {
    'stevearc/conform.nvim',
    opts = {}, -- default options
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" }, -- Lua formatter: https://github.com/JohnnyMorganz/StyLua
                go = { "gofmt", "goimports" }, -- Go formatter: https://pkg.go.dev/cmd/gofmt
                javascript = { "prettier" }, -- JS/TS formatter: https://prettier.io/
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                vue = { "prettier" },
                css = { "prettier" },
                scss = { "prettier" },
                html = { "prettier" },
                json = { "prettier" },
                yaml = { "prettier" },
                markdown = { "prettier" },
                elixir = { "mix" }, -- Elixir formatter via mix format
                python = { "ruff_fix", "ruff_format" }, -- Python: ruff is much faster than black
                c = { "clang_format" }, -- C/C++ formatter
                cpp = { "clang_format" },
                objc = { "clang_format" },
                objcpp = { "clang_format" },
                swift = { "swift_format" }, -- Swift formatter (requires swift-format)
                rust = { "rustfmt" }, -- Rust formatter
                zig = { "zigfmt" }, -- Zig formatter
            },
            -- Format on save configuration
            format_on_save = function(bufnr)
                -- Disable format on save for certain filetypes
                local disable_filetypes = { c = true, cpp = true }
                return {
                    timeout_ms = 500,
                    lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
                }
            end,
        })
    end
}