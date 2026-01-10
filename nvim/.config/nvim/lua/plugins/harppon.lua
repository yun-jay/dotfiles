return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({})

    local km = vim.keymap.set
    km("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon Add File" })
    km("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon Menu" })
    km("n", "<C-n>", function() harpoon:list():next() end)
    km("n", "<C-p>", function() harpoon:list():prev() end)
  end,
}
