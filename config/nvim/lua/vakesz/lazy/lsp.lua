-- Language Server Protocol configuration
-- Docs:
--  nvim-lspconfig: https://github.com/neovim/nvim-lspconfig
--  mason.nvim: https://github.com/williamboman/mason.nvim
--  nvim-cmp: https://github.com/hrsh7th/nvim-cmp

local root_files = {
  '.luarc.json',
  '.luarc.jsonc',
  '.luacheckrc',
  '.stylua.toml',
  'stylua.toml',
  'selene.toml',
  'selene.yml',
  '.git',
}

return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "stevearc/conform.nvim", -- formatter integration
        "williamboman/mason.nvim", -- LSP/DAP/tool installer
        "williamboman/mason-lspconfig.nvim", -- bridge mason <-> lspconfig
        "hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
        "hrsh7th/cmp-buffer", -- buffer completions
        "hrsh7th/cmp-path", -- path completions
        "hrsh7th/cmp-cmdline", -- cmdline completions
        "hrsh7th/nvim-cmp", -- completion engine
        "L3MON4D3/LuaSnip", -- snippet engine
        "saadparwaiz1/cmp_luasnip", -- luasnip completion source
        "j-hui/fidget.nvim", -- LSP progress UI https://github.com/j-hui/fidget.nvim
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

        require("fidget").setup({}) -- show LSP progress
        require("mason").setup() -- setup Mason package manager
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "rust_analyzer",
                "gopls",
                "zls",
                "pyright",
                "clangd",
                "vue_ls",
                "ts_ls",      -- TypeScript/JavaScript LSP
            }, -- automatically install these servers
            handlers = {
                function(server_name) -- default handler
                    require("lspconfig")[server_name].setup {
                        capabilities = capabilities
                    }
                end,

                -- Zig language server
                ["zls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.zls.setup({
                        capabilities = capabilities,
                        root_dir = lspconfig.util.root_pattern(".git", "build.zig", "zls.json"), -- project root
                        settings = {
                            zls = {
                                enable_inlay_hints = true,
                                enable_snippets = true,
                                warn_style = true,
                            },
                        },
                    })
                    vim.g.zig_fmt_parse_errors = 0
                    vim.g.zig_fmt_autosave = 0
                end,

                -- Go language server
                ["gopls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.gopls.setup({
                        capabilities = capabilities,
                        cmd = {"gopls"},
                        root_dir = lspconfig.util.root_pattern("go.mod", ".git"), -- Go project root
                        settings = {
                            gopls = {
                                analyses = {
                                    unusedparams = true, -- warn about unused params
                                },
                                staticcheck = true,
                                gofumpt = true,
                            },
                        },
                    })
                end,

                -- Lua language server
                ["lua_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup {
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                format = {
                                    enable = true,
                                    defaultConfig = { -- stylua formatting
                                        indent_style = "space",
                                        indent_size = "2",
                                    }
                                },
                            }
                        }
                    }
                end,

                -- Python language server
                ["pyright"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.pyright.setup({
                        capabilities = capabilities,
                        settings = {
                            python = {
                                analysis = {
                                    autoSearchPaths = true,
                                    useLibraryCodeForTypes = true,
                                    diagnosticMode = "workspace",
                                    typeCheckingMode = "basic", -- Enable type checking
                                },
                                pythonPath = vim.fn.exepath("python3"), -- Use system Python
                            },
                        },
                        on_attach = function(client, bufnr)
                            -- Disable Pyright's formatting in favor of ruff
                            client.server_capabilities.documentFormattingProvider = false
                        end,
                    })
                end,

                -- C/C++ language server
                ["clangd"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.clangd.setup({
                        capabilities = capabilities,
                        cmd = {
                            "clangd",
                            "--background-index",
                            "--clang-tidy",
                            "--completion-style=detailed",
                            "--function-arg-placeholders",
                        }, -- more detailed completions
                        init_options = {
                            usePlaceholders = true,
                            completeUnimported = true,
                            clangdFileStatus = true,
                        },
                    })
                end,

                -- Vue language server
                ["vue_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.vue_ls.setup({
                        capabilities = capabilities,
                        init_options = {
                            vue = {
                                hybridMode = false,
                            },
                        },
                    })
                end,

                -- Swift language server (sourcekit-lsp)
                ["sourcekit"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.sourcekit.setup({
                        capabilities = capabilities,
                        cmd = {
                            "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp"
                        },
                        root_dir = lspconfig.util.root_pattern(
                            "Package.swift",
                            ".git",
                            "*.xcodeproj",
                            "*.xcworkspace"
                        ),
                        filetypes = { "swift", "objective-c", "objective-cpp" },
                    })
                end,

                -- TypeScript/JavaScript language server
                ["ts_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.ts_ls.setup({
                        capabilities = capabilities,
                        settings = {
                            typescript = {
                                inlayHints = {
                                    includeInlayParameterNameHints = "all",
                                    includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                                    includeInlayFunctionParameterTypeHints = true,
                                    includeInlayVariableTypeHints = true,
                                    includeInlayPropertyDeclarationTypeHints = true,
                                    includeInlayFunctionLikeReturnTypeHints = true,
                                    includeInlayEnumMemberValueHints = true,
                                },
                            },
                            javascript = {
                                inlayHints = {
                                    includeInlayParameterNameHints = "all",
                                    includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                                    includeInlayFunctionParameterTypeHints = true,
                                    includeInlayVariableTypeHints = true,
                                    includeInlayPropertyDeclarationTypeHints = true,
                                    includeInlayFunctionLikeReturnTypeHints = true,
                                    includeInlayEnumMemberValueHints = true,
                                },
                            },
                        },
                    })
                end,
            }
        })

        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- snippet expansion
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<C-y>'] = cmp.mapping.confirm({ select = true }), -- confirm selection
                ["<C-Space>"] = cmp.mapping.complete(), -- trigger completion
            }),
            sources = cmp.config.sources({
                { name = "copilot", group_index = 2 }, -- GitHub Copilot
                { name = 'nvim_lsp' },
                { name = 'luasnip' },
            }, {
                { name = 'buffer' }, -- buffer words
            })
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