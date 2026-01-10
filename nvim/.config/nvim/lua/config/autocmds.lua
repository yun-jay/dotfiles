-- Custom migration renaming command
vim.api.nvim_create_user_command("RenNextMigration", function()
  local path = vim.fn.expand("%:p")
  local dir = vim.fn.fnamemodify(path, ":h")
  local filename = vim.fn.fnamemodify(path, ":t")

  local num, desc = filename:match("^(%d+)_(.+)$")
  if not num or not desc then
    print("File doesn't match pattern: <number>_<description>.sql")
    return
  end

  local max = 0
  for _, f in ipairs(vim.fn.readdir(dir)) do
    local n = tonumber(f:match("^(%d+)_"))
    if n and n > max then max = n end
  end

  local new_num = string.format("%0" .. #num .. "d", max + 1)
  local new_path = dir .. "/" .. new_num .. "_" .. desc

  os.rename(path, new_path)
  vim.cmd("edit " .. new_path)
  print("Renamed to " .. new_num .. "_" .. desc)
end, {})

vim.keymap.set("n", "<leader>mg", ":RenNextMigration<CR>",
  { desc = "Rename current migration file to next available one" })
