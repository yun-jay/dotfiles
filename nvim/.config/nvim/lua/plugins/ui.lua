return {
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup()
    end,
  },

  -- Zen mode
  {
    "folke/zen-mode.nvim",
    keys = {
      { "<leader>zz", function() require("zen-mode").toggle() end, desc = "Toggle Zen Mode" },
    },
    opts = {
      window = { width = 90, options = {} },
    },
  },

  -- Undo tree
  {
    "mbbill/undotree",
    keys = {
      { "<leader>u", vim.cmd.UndotreeToggle, desc = "Toggle UndoTree" },
    },
  },

  -- Dependencies/utilities
  { "nvim-lua/plenary.nvim" },
  { "tpope/vim-unimpaired" },
  { "tpope/vim-eunuch",     cmd = { "Rename", "Move", "Delete", "Mkdir", "SudoWrite" } },
}
