return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    opts = {
      ensure_installed = {
        "lua", "go", "javascript", "typescript", "vim", "markdown",
        "tsx", "json", "html", "css" -- Added for better comment support
      },
      highlight = { enable = true },
      indent = { enable = true },
      auto_install = true,
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
      -- Enable context-aware commenting
      require("ts_context_commentstring").setup({
        enable_autocmd = false,
      })
    end,
  },
  {
    "nvim-treesitter/playground",
    cmd = "TSPlaygroundToggle",
  },
}
