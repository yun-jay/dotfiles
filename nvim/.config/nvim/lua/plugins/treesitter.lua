local parsers = { "lua", "go", "javascript", "typescript", "vim", "markdown", "tsx", "json", "html", "css" }

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.setup()
      treesitter.install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = parsers,
        callback = function()
          vim.treesitter.start()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
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
