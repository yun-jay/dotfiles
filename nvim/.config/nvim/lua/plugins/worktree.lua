return {
  "polarmutex/git-worktree.nvim",
  version = "^2",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    local git_worktree = require("git-worktree")
    local Hooks = require("git-worktree.hooks")

    -- ===== HOOKS =====

    -- Built-in hook to update buffer when switching
    Hooks.register(Hooks.type.SWITCH, Hooks.builtins.update_current_buffer_on_switch)

    -- Custom hook: Switch tmux session when switching worktrees
    Hooks.register(Hooks.type.SWITCH, function(path, prev_path)
      vim.fn.system(string.format("tmux-worktree '%s'", path))

      local marker_file = path .. "/.tmux-session-type"
      local session_type = "default"
      local f = io.open(marker_file, "r")
      if f then
        session_type = f:read("*line") or "default"
        f:close()
      end

      vim.notify(string.format("Switched to: %s (session: %s)",
        vim.fn.fnamemodify(path, ":t"), session_type))
    end)

    -- Custom hook: Prompt for session template when creating worktree
    Hooks.register(Hooks.type.CREATE, function(path, branch, upstream)
      local configs = vim.fn.systemlist(
        "ls " ..
        vim.fn.expand("~/.config/tmux-sessions") .. "/*.conf 2>/dev/null | xargs -n1 basename | sed 's/.conf$//'"
      )

      if #configs == 0 then
        vim.notify("No session templates found, using default", vim.log.levels.WARN)
        vim.fn.system(string.format("tmux-worktree '%s' 'default'", path))
        return
      end

      vim.ui.select(
        configs,
        {
          prompt = "Select session template for new worktree:",
          format_item = function(item)
            return "📁 " .. item
          end
        },
        function(choice)
          if choice then
            vim.fn.system(string.format("tmux-worktree '%s' '%s'", path, choice))
            vim.notify(string.format("Created worktree with '%s' session template", choice))
          else
            vim.fn.system(string.format("tmux-worktree '%s' 'default'", path))
            vim.notify("Created worktree with default session template")
          end
        end
      )
    end)

    -- Custom hook: Kill tmux session when deleting worktree
    Hooks.register(Hooks.type.DELETE, function(path)
      local session_name = vim.fn.fnamemodify(path, ":t"):gsub("%.", "_")
      vim.fn.system(string.format("tmux kill-session -t '%s' 2>/dev/null", session_name))
      vim.notify(string.format("Cleaned up session for: %s", vim.fn.fnamemodify(path, ":t")))
    end)

    -- ===== HELPER FUNCTIONS =====

    -- Helper function to delete worktree and cleanup
    local function delete_and_cleanup(path, branch)
      -- Try git worktree remove with force
      local result = vim.fn.system(string.format("git worktree remove '%s' --force 2>&1", path))

      if vim.v.shell_error ~= 0 then
        vim.notify("Git worktree remove failed, trying force delete...", vim.log.levels.WARN)

        -- Force delete: remove git entry and folder
        vim.fn.system(string.format("git worktree remove '%s' --force 2>/dev/null", path))
        vim.fn.system(string.format("rm -rf '%s'", path))
      end

      -- Kill tmux session
      local session_name = vim.fn.fnamemodify(path, ":t"):gsub("%.", "_")
      vim.fn.system(string.format("tmux kill-session -t '%s' 2>/dev/null", session_name))

      vim.notify(string.format("Deleted worktree: %s", branch), vim.log.levels.INFO)
    end

    -- ===== TELESCOPE PICKERS =====

    -- Custom telescope picker to list and switch worktrees
    local function telescope_git_worktree()
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      local worktrees = vim.fn.systemlist("git worktree list")
      local results = {}

      for _, worktree in ipairs(worktrees) do
        local parts = vim.split(worktree, "%s+")
        if #parts >= 3 then
          table.insert(results, {
            path = parts[1],
            branch = parts[3]:gsub("[%[%]]", ""),
          })
        end
      end

      pickers.new({}, {
        prompt_title = "Git Worktrees",
        finder = finders.new_table({
          results = results,
          entry_maker = function(entry)
            return {
              value = entry,
              display = entry.branch .. " → " .. entry.path,
              ordinal = entry.branch .. " " .. entry.path,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then
              git_worktree.switch_worktree(selection.value.path)
            end
          end)

          -- Ctrl-d to delete from picker
          map("i", "<C-d>", function()
            local selection = action_state.get_selected_entry()
            if selection then
              local confirm = vim.fn.input("Delete worktree " .. selection.value.branch .. "? (y/N): ")
              if confirm:lower() == "y" then
                actions.close(prompt_bufnr)
                delete_and_cleanup(selection.value.path, selection.value.branch)
              end
            end
          end)

          return true
        end,
      }):find()
    end

    -- Create worktree at git root
    local function telescope_create_worktree()
      vim.ui.input({ prompt = "Branch name: " }, function(branch)
        if not branch or branch == "" then
          return
        end

        -- Verify we're in a git repository
        local worktree_list = vim.fn.systemlist("git worktree list")
        if vim.v.shell_error ~= 0 then
          vim.notify("Not in a git repository", vim.log.levels.ERROR)
          return
        end

        -- Get default branch
        local function get_default_branch()
          local gh_result = vim.fn
              .system("gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null")
              :gsub("\n", "")

          if gh_result ~= "" and vim.v.shell_error == 0 then
            return gh_result
          end

          local git_result = vim.fn
              .system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'")
              :gsub("\n", "")

          if git_result ~= "" and vim.v.shell_error == 0 then
            return git_result
          end

          return "dev"
        end

        local default_branch = get_default_branch()

        vim.ui.input({ prompt = "Base branch (default: " .. default_branch .. "): " }, function(base)
          base = base and base ~= "" and base or default_branch

          -- Pass just the branch name, git will create it as a sibling to bare repo
          vim.notify("Creating worktree: " .. branch .. " based on " .. base)
          git_worktree.create_worktree(branch, base)
        end)
      end)
    end

    -- ===== KEYMAPS =====

    vim.keymap.set("n", "<leader>gww", telescope_git_worktree, { desc = "Switch worktree" })
    vim.keymap.set("n", "<leader>gwc", telescope_create_worktree, { desc = "Create worktree" })

    vim.keymap.set("n", "<leader>gwd", function()
      -- Get list of worktrees
      local worktrees = vim.fn.systemlist("git worktree list")
      local results = {}

      for _, worktree in ipairs(worktrees) do
        local parts = vim.split(worktree, "%s+")
        if #parts >= 3 then
          local branch = parts[3]:gsub("[%[%]]", "")
          -- Filter out default branches
          if branch ~= "dev" and branch ~= "main" and branch ~= "master" then
            table.insert(results, {
              path = parts[1],
              branch = branch,
            })
          end
        end
      end

      if #results == 0 then
        vim.notify("No worktrees available to delete", vim.log.levels.WARN)
        return
      end

      -- Show picker to select worktree
      vim.ui.select(
        results,
        {
          prompt = "Select worktree to delete:",
          format_item = function(item)
            return item.branch .. " → " .. item.path
          end,
        },
        function(choice)
          if not choice then return end

          -- Confirm deletion
          vim.ui.input(
            {
              prompt = string.format("Delete worktree '%s'? (y/N): ", choice.branch),
            },
            function(confirm)
              if confirm and confirm:lower() == "y" then
                -- Check if we're currently in the worktree being deleted
                local current_path = vim.loop.cwd()

                if current_path == choice.path or current_path:find(choice.path, 1, true) == 1 then
                  vim.notify("Switching to main worktree before deletion...", vim.log.levels.INFO)

                  -- Find and switch to dev/main worktree
                  for _, worktree in ipairs(worktrees) do
                    local parts = vim.split(worktree, "%s+")
                    if #parts >= 3 then
                      local branch = parts[3]:gsub("[%[%]]", "")
                      if branch == "dev" or branch == "main" or branch == "master" then
                        git_worktree.switch_worktree(parts[1])
                        -- Delay deletion to ensure switch completes
                        vim.defer_fn(function()
                          delete_and_cleanup(choice.path, choice.branch)
                        end, 500)
                        return
                      end
                    end
                  end
                else
                  delete_and_cleanup(choice.path, choice.branch)
                end
              else
                vim.notify("Deletion cancelled", vim.log.levels.INFO)
              end
            end
          )
        end
      )
    end, { desc = "Delete Worktree" })
  end,
}
