return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "smjonas/inc-rename.nvim",
  },
  config = function()
    require("inc_rename").setup()

    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    local function on_attach(_, bufnr)
      local opts = { buffer = bufnr }
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
      vim.keymap.set("n", "<leader>rn", ":IncRename ", opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
      vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
      vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
    end

    -- Lua LSP
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "lua",
      callback = function()
        vim.lsp.start({
          name = "lua_ls",
          cmd = { "lua-language-server" },
          root_dir = vim.fs.dirname(vim.fs.find({ ".git", ".luarc.json" }, { upward = true })[1]),
          capabilities = capabilities,
          on_attach = on_attach,
        })
      end,
    })

    -- Go LSP
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "go",
      callback = function()
        vim.lsp.start({
          name = "gopls",
          cmd = { "gopls" },
          root_dir = vim.fs.dirname(vim.fs.find({ ".git", "go.mod" }, { upward = true })[1]),
          capabilities = capabilities,
          on_attach = on_attach,
        })
      end,
    })

    -- TypeScript/JavaScript LSP
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
      callback = function()
        vim.lsp.start({
          name = "ts_ls",
          cmd = { "typescript-language-server", "--stdio" },
          root_dir = vim.fs.dirname(vim.fs.find({ ".git", "package.json", "tsconfig.json" }, { upward = true })[1]),
          capabilities = capabilities,
          on_attach = on_attach,
        })
      end,
    })

    vim.diagnostic.config({
      float = { border = "rounded" },
      severity_sort = true,
      signs = true,
    })

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
}
