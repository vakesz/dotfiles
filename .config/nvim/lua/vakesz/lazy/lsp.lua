-- Language Server Protocol configuration
-- Docs:
--  nvim-lspconfig: https://github.com/neovim/nvim-lspconfig
--  mason.nvim: https://github.com/williamboman/mason.nvim
--  nvim-cmp: https://github.com/hrsh7th/nvim-cmp

return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "stevearc/conform.nvim", -- formatter integration
        "williamboman/mason.nvim", -- LSP/DAP/tool installer
        "williamboman/mason-lspconfig.nvim", -- bridge mason <-> lspconfig
        "hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
        "hrsh7th/cmp-buffer", -- buffer completions
        "hrsh7th/cmp-path", -- path completions
        "hrsh7th/nvim-cmp", -- completion engine
        "j-hui/fidget.nvim", -- LSP progress UI
    },

    config = function()
        require("conform").setup({
            formatters_by_ft = {}, -- configure formatters per filetype
        })
        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities()
        )

        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = { "lua_ls", "pyright", "clangd", "ts_ls" },
            handlers = {
                -- Default handler for all servers
                function(server_name)
                    require("lspconfig")[server_name].setup({
                        capabilities = capabilities,
                    })
                end,

                -- Lua language server with custom settings
                ["lua_ls"] = function()
                    require("lspconfig").lua_ls.setup({
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                runtime = { version = "LuaJIT" },
                                workspace = { checkThirdParty = false },
                                telemetry = { enable = false },
                            },
                        },
                    })
                end,

                -- Python with formatting disabled (use ruff via conform)
                ["pyright"] = function()
                    require("lspconfig").pyright.setup({
                        capabilities = capabilities,
                        settings = {
                            python = {
                                analysis = {
                                    typeCheckingMode = "basic",
                                },
                            },
                        },
                        on_attach = function(client)
                            client.server_capabilities.documentFormattingProvider = false
                        end,
                    })
                end,
            },
        })

        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
                { name = "copilot", group_index = 2 },
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
                source = "always",
                header = "",
                prefix = "",
            },
        })
    end
}