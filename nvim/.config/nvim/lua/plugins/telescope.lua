return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find Files" },
    { "<leader>fg", function() require("telescope.builtin").live_grep() end,  desc = "Grep Files" },
    {
      "<leader>fG",
      function()
        require("telescope.builtin").live_grep({
          additional_args = function() return { "--fixed-strings" } end
        })
      end,
      desc = "Grep Files (Literal)"
    },
    { "<leader>fb", function() require("telescope.builtin").buffers() end,   desc = "Find Buffers" },
    { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help Tags" },
  },
  config = function()
    require("telescope").setup({})
  end,
}
