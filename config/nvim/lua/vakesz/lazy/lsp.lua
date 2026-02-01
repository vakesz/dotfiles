-- Language Server Protocol configuration
-- Docs: https://github.com/williamboman/mason.nvim

return {
    "williamboman/mason.nvim",
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig", -- Provides lsp/*.lua server configs for vim.lsp.config
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "j-hui/fidget.nvim",
    },
    config = function()
        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")

        -- Set default capabilities for ALL LSP servers
        vim.lsp.config('*', {
            capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities()
            ),
        })

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

        -- clangd and ts_ls use defaults (no custom config needed)

        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = { "lua_ls", "pyright", "clangd", "ts_ls" },
            automatic_enable = true, -- Calls vim.lsp.enable() for installed servers
        })

        -- nvim-cmp setup
        local cmp_select = { behavior = cmp.SelectBehavior.Select }
        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body)
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "path" },
            }, {
                { name = "buffer" },
            }),
        })

        vim.diagnostic.config({
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = true,
                header = "",
                prefix = "",
            },
        })

        -- LSP keybindings (on attach)
        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(e)
                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = e.buf, desc = desc })
                end
                map("n", "gd", vim.lsp.buf.definition, "Go to definition")
                map("n", "K", vim.lsp.buf.hover, "Hover documentation")
                map("n", "<leader>vws", vim.lsp.buf.workspace_symbol, "Workspace symbol search")
                map("n", "<leader>vd", vim.diagnostic.open_float, "Show line diagnostics")
                map("n", "<leader>vca", vim.lsp.buf.code_action, "Code actions")
                map("n", "<leader>vrr", vim.lsp.buf.references, "Show references")
                map("n", "<leader>vrn", vim.lsp.buf.rename, "Rename symbol")
                map("i", "<C-h>", vim.lsp.buf.signature_help, "Signature help")
            end
        })
    end
}
