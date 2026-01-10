return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "lua", "go", "javascript", "typescript", "vim", "markdown",
        "tsx", "json", "html", "css",
      },
      highlight = { enable = true },
      indent = { enable = true },
      auto_install = true,
    },
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = {
      enable_autocmd = false,
    },
  },
  {
    "nvim-treesitter/playground",
    cmd = "TSPlaygroundToggle",
  },
}
