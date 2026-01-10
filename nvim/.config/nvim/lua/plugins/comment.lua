return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  config = function()
    require("Comment").setup({
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      padding = true,
      ignore = "^$",
      toggler = {
        line = "gcc",
        block = "gbc",
      },
      opleader = {
        line = "gc",
        block = "gb",
      },
      mappings = {
        basic = true,
        extra = false, -- Disable since we'll create our own
      },
    })

    -- Create the extra mappings manually
    local api = require("Comment.api")

    -- Add comment at end of line
    vim.keymap.set("n", "gcA", function()
      vim.cmd("normal! A ")
      api.insert.linewise.eol()
    end, { desc = "Comment end of line" })
  end,
}
