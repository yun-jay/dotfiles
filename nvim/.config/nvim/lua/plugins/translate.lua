return {
  "uga-rosa/translate.nvim",
  keys = {
    -- Visual mode: replace selected text with translation
    {
      "<leader>tr",
      "<cmd>Translate DE -output=replace<cr>",
      mode = "x",
      desc = "Translate to German and replace",
    },
    -- Visual mode: translate to English
    {
      "<leader>te",
      "<cmd>Translate EN -output=replace<cr>",
      mode = "x",
      desc = "Translate to English and replace",
    },
    -- Visual mode: show translation in floating window
    {
      "<leader>tp",
      "<cmd>Translate DE -output=floating<cr>",
      mode = "x",
      desc = "Translate to German (popup)",
    },
    -- Translate empty msgstr entries in .po files
    {
      "<leader>mt",
      "<cmd>TranslatePoEmpty<cr>",
      mode = "n",
      desc = "Translate empty msgstr in .po file",
    },
  },
  config = function()
    -- Set API key from environment variable
    vim.g.deepl_api_auth_key = vim.env.DEEPL_AUTH_KEY

    -- Custom command with formality support (informal "du")
    require("translate").setup({
      default = {
        command = "deepl_informal",
        output = "replace",
        parse_after = "deepl_informal",
      },
      command = {
        deepl_informal = {
          cmd = function(lines, command_args)
            local auth_key = vim.g.deepl_api_auth_key
            if not auth_key then
              error("vim.g.deepl_api_auth_key is not set")
            end

            local url = "https://api-free.deepl.com/v2/translate"
            -- Change to this for Pro: "https://api.deepl.com/v2/translate"

            local body = vim.json.encode({
              text = lines,
              target_lang = command_args.target,
              source_lang = command_args.source ~= "" and command_args.source or nil,
              formality = "less", -- "less" = informal (du), "more" = formal (Sie)
            })

            local cmd = "curl"
            local args = {
              "-sS",
              "-X", "POST",
              url,
              "-H", "Authorization: DeepL-Auth-Key " .. auth_key,
              "-H", "Content-Type: application/json",
              "-d", body,
            }

            return cmd, args
          end,
        },
      },
      parse_after = {
        deepl_informal = {
          cmd = function(lines)
            -- lines is a table, join it to parse JSON
            local output = table.concat(lines, "")
            local result = vim.json.decode(output)
            if result and result.translations then
              local texts = {}
              for _, t in ipairs(result.translations) do
                table.insert(texts, t.text)
              end
              return texts
            end
            return lines
          end,
        },
      },
    })

    -- Function to translate empty msgstr entries in .po files
    local function translate_po_empty()
      local auth_key = vim.g.deepl_api_auth_key
      if not auth_key then
        vim.notify("DEEPL_AUTH_KEY not set", vim.log.levels.ERROR)
        return
      end

      local bufnr = vim.api.nvim_get_current_buf()
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

      -- Find all empty msgstr entries (msgstr "" followed by empty line only)
      local entries = {}
      local i = 1
      while i <= #lines do
        local line = lines[i]

        -- Check for msgstr ""
        if line:match('^msgstr ""$') then
          -- Check if next line is empty (not a continuation line)
          local next_line = lines[i + 1] or ""
          if next_line == "" then
            -- Found empty msgstr, now find the msgid
            local msgid_parts = {}
            local j = i - 1

            -- Go back to find msgid
            while j >= 1 do
              local prev = lines[j]
              if prev:match('^".*"$') then
                -- Continuation line
                local content = prev:match('^"(.*)"$')
                table.insert(msgid_parts, 1, content)
                j = j - 1
              elseif prev:match('^msgid "') then
                -- Start of msgid
                local content = prev:match('^msgid "(.*)"$')
                if content then
                  table.insert(msgid_parts, 1, content)
                end
                break
              elseif prev:match('^msgid_plural') or prev:match('^msgctxt') then
                break
              else
                j = j - 1
              end
            end

            local msgid = table.concat(msgid_parts, "")
            if msgid ~= "" then
              table.insert(entries, { line_num = i, msgid = msgid })
            end
          end
        end
        i = i + 1
      end

      if #entries == 0 then
        vim.notify("No empty msgstr entries found", vim.log.levels.INFO)
        return
      end

      vim.notify(string.format("Found %d empty msgstr entries, translating...", #entries), vim.log.levels.INFO)

      -- Translate all msgids in one batch
      local msgids = {}
      for _, entry in ipairs(entries) do
        table.insert(msgids, entry.msgid)
      end

      local body = vim.json.encode({
        text = msgids,
        target_lang = "DE",
        source_lang = "EN",
        formality = "less",
      })

      local curl_cmd = string.format(
        'curl -sS -X POST "https://api-free.deepl.com/v2/translate" -H "Authorization: DeepL-Auth-Key %s" -H "Content-Type: application/json" -d %s',
        auth_key,
        vim.fn.shellescape(body)
      )

      vim.fn.jobstart(curl_cmd, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          if not data or #data == 0 then return end
          local output = table.concat(data, "")
          local ok, result = pcall(vim.json.decode, output)

          if not ok or not result or not result.translations then
            vim.schedule(function()
              vim.notify("Translation failed: " .. output, vim.log.levels.ERROR)
            end)
            return
          end

          vim.schedule(function()
            -- Update buffer with translations
            local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

            for idx, entry in ipairs(entries) do
              local translation = result.translations[idx]
              if translation then
                local text = translation.text
                -- Escape quotes and handle newlines for .po format
                text = text:gsub('\\', '\\\\'):gsub('"', '\\"')
                current_lines[entry.line_num] = 'msgstr "' .. text .. '"'
              end
            end

            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, current_lines)
            vim.notify(string.format("Translated %d entries", #entries), vim.log.levels.INFO)
          end)
        end,
        on_stderr = function(_, data)
          if data and #data > 0 and data[1] ~= "" then
            vim.schedule(function()
              vim.notify("Error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
            end)
          end
        end,
      })
    end

    -- Create command
    vim.api.nvim_create_user_command("TranslatePoEmpty", translate_po_empty, {})
  end,
}
