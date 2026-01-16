return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua",
          "go",
          "javascript",
          "typescript",
          "tsx",
          "vim",
          "vimdoc",
          "markdown",
          "json",
          "html",
          "css",
          "bash",
        },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
        },
      })
      vim.treesitter.language.register("markdown", "mdx")
    end,
  },
}
