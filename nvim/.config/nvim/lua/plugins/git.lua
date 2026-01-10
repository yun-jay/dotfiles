return {
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gs", "<cmd>tab Git<cr>", desc = "Git Status" },
    },
    config = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "FugitiveDiff",
        callback = function()
          vim.keymap.set("n", "<leader>gh", "<cmd>diffget //2<cr>",
            { buffer = true, desc = "Get from Left (HEAD)" })
          vim.keymap.set("n", "<leader>gl", "<cmd>diffget //3<cr>",
            { buffer = true, desc = "Get from Right (Branch)" })
        end,
      })
    end,
  },
  {
    "sindrets/diffview.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    keys = {
      { "<leader>dv", ":DiffviewOpen<CR>",  desc = "Open Diffview" },
      { "<leader>dc", ":DiffviewClose<CR>", desc = "Close Diffview" },
    },
    config = function()
      require("diffview").setup({})
    end,
  },
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Octo",
    keys = {
      {
        "<leader>op",
        function()
          local handle = io.popen("gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null")
          local repo = handle:read("*a"):gsub("%s+", "")
          handle:close()
          if repo ~= "" then
            vim.cmd("Octo search is:pr is:open author:@me repo:" .. repo)
          else
            vim.notify("Not in a GitHub repository", vim.log.levels.ERROR)
          end
        end,
        desc = "My PRs",
      },
      {
        "<leader>or",
        function()
          local handle = io.popen("gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null")
          local repo = handle:read("*a"):gsub("%s+", "")
          handle:close()
          if repo ~= "" then
            vim.cmd("Octo search is:pr is:open review-requested:@me repo:" .. repo)
          else
            vim.notify("Not in a GitHub repository", vim.log.levels.ERROR)
          end
        end,
        desc = "PRs to Review",
      },
    },
    config = function()
      require("octo").setup({
        enable_builtin = true,
      })
    end,
  },
}
