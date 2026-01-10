
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load options first
require("config.options")

-- Bootstrap lazy.nvim and load plugins
require("config.lazy")

-- Load keymaps and autocmds
require("config.keymaps")
require("config.autocmds")
