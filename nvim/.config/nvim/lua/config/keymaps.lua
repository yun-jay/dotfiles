local keymap = vim.keymap.set

-- File explorer
keymap("n", "<leader>pv", vim.cmd.Ex)

-- Move selected lines up/down
keymap("v", "J", ":m '>+1<CR>gv=gv")
keymap("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor centered
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "N", "Nzzzv")
keymap("n", "n", "nzzzv")

-- Clipboard / delete
keymap({ "n", "v" }, "<leader>d", '"_d')
keymap({ "n", "v" }, "<leader>y", '"+y')
keymap("n", "<leader>Y", '"+Y')
keymap("x", "<leader>p", [["_dP]])

-- LSP hover (if not in plugin config)
keymap("n", "K", function() vim.lsp.buf.hover() end)

-- Toggle Claude side panel in tmux (only works inside tmux)
if vim.env.TMUX then
  keymap("n", "<leader>cc", function()
    vim.fn.system("~/.local/bin/tmux-toggle-claude")
  end, { desc = "Toggle Claude Side Panel" })
end
