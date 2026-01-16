return {
  "stevearc/oil.nvim",
  lazy = false,
  config = function()
    local sort_modes = {
      { { "name", "asc" } },
      { { "name", "desc" } },
      { { "type", "asc" }, { "name", "asc" } },
      { { "mtime", "desc" } },
    }
    local current_sort = 1

    require("oil").setup({
      default_file_explorer = true,
      columns = {},
      win_options = {
        winbar = "%=%{v:lua.require('oil').get_current_dir()}",
      },
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ["gS"] = {
          callback = function()
            current_sort = current_sort % #sort_modes + 1
            require("oil").set_sort(sort_modes[current_sort])
          end,
          desc = "Cycle sort order",
        },
      },
    })
    vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
    vim.keymap.set("n", "<leader>_", function()
      require("oil").open(vim.fn.getcwd())
    end, { desc = "Open cwd (where nvim started)" })
  end,
}
