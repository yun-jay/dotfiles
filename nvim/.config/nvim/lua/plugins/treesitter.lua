local parsers = { "lua", "go", "javascript", "typescript", "vim", "vimdoc", "markdown", "tsx", "json", "html", "css", "bash" }

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = function()
      require("nvim-treesitter").install(parsers):wait()
    end,
    config = function()
      require("nvim-treesitter").setup()

      -- Enable treesitter highlighting and indentation for supported filetypes
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          if vim.treesitter.get_parser(0, vim.bo.filetype, { error = false }) then
            vim.treesitter.start()
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      -- Enable treesitter-based folding
      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.opt.foldenable = false
    end,
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = {
      enable_autocmd = false,
    },
  },
}
