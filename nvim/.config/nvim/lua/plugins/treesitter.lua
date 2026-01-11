return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
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
      })
      vim.treesitter.language.register("markdown", "mdx")
    end,
  },
}
