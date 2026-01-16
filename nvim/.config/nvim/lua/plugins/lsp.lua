return {
  {
    "hrsh7th/nvim-cmp",
    lazy = false,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },
  {
    "smjonas/inc-rename.nvim",
    lazy = false,
    config = function()
      require("inc_rename").setup()
    end,
  },
  {
    -- Only used for its LSP server configurations (cmd, filetypes, root_dir, settings)
    "neovim/nvim-lspconfig",
    lazy = true,
  },
  {
    "hrsh7th/cmp-nvim-lsp",
    lazy = false,
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", ":IncRename ", opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, opts)
          vim.keymap.set("n", "]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, opts)
        end,
      })

      -- Configure LSP servers using native Neovim 0.11+ API
      vim.lsp.config("lua_ls", {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.config("gopls", {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_markers = { "go.mod", "go.work", ".git" },
        capabilities = capabilities,
      })

      vim.lsp.config("ts_ls", {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
        capabilities = capabilities,
      })

      -- Enable LSP servers
      vim.lsp.enable({ "lua_ls", "gopls", "ts_ls" })

      vim.diagnostic.config({
        float = { border = "rounded" },
        severity_sort = true,
        signs = true,
      })
    end,
  },
}
