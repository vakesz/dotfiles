-- Language Server Protocol configuration
-- Uses native vim.lsp.completion (nvim 0.12+) and vim.snippet

return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        -- Configure individual servers
        vim.lsp.config('lua_ls', {
            settings = {
                Lua = {
                    runtime = { version = "LuaJIT" },
                    workspace = { checkThirdParty = false },
                    telemetry = { enable = false },
                },
            },
        })

        vim.lsp.config('pyright', {
            settings = {
                python = {
                    analysis = { typeCheckingMode = "basic" },
                },
            },
            on_attach = function(client)
                client.server_capabilities.documentFormattingProvider = false
            end,
        })

        -- All servers installed system-wide via Homebrew (see Brewfile)
        -- clangd provided by Xcode Command Line Tools
        -- sourcekit-lsp (Xcode) uses xcode-build-server via buildServer.json
        vim.lsp.enable({ 'lua_ls', 'pyright', 'clangd', 'ts_ls', 'gopls', 'ruby_lsp', 'bashls', 'sourcekit' })

        vim.diagnostic.config({
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "if_many",
                header = "",
                prefix = "",
            },
        })

        -- LSP keybindings and native completion (on attach)
        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(e)
                local client = vim.lsp.get_client_by_id(e.data.client_id)
                if not client then return end

                -- Enable native LSP completion with autotrigger
                vim.lsp.completion.enable(true, client.id, e.buf, { autotrigger = true })

                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = e.buf, desc = desc })
                end

                -- Snippet navigation
                map({ "i", "s" }, "<C-l>", function()
                    if vim.snippet.active({ direction = 1 }) then vim.snippet.jump(1) end
                end, "Next snippet stop")
                map({ "i", "s" }, "<C-h>", function()
                    if vim.snippet.active({ direction = -1 }) then
                        vim.snippet.jump(-1)
                    else
                        vim.lsp.buf.signature_help()
                    end
                end, "Prev snippet / Signature help")

                -- Trigger completion manually
                map("i", "<C-Space>", function() vim.lsp.completion.trigger() end, "Trigger completion")

                map("n", "<leader>vws", vim.lsp.buf.workspace_symbol, "Workspace symbol search")
                map("n", "<leader>vd", vim.diagnostic.open_float, "Show line diagnostics")
                map("n", "<leader>vca", vim.lsp.buf.code_action, "Code actions")
                map("n", "<leader>vrr", vim.lsp.buf.references, "Show references")
                map("n", "<leader>vrn", vim.lsp.buf.rename, "Rename symbol")
                map("n", "<leader>zig", "<cmd>LspRestart<cr>", "Restart LSP")
            end
        })
    end
}
