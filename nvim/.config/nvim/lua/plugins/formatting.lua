return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      javascript = { "oxlint" },
      typescript = { "oxlint" },
      javascriptreact = { "oxlint" },
      typescriptreact = { "oxlint" },
      lua = { "stylua" },
      go = { "gofmt" },
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    format_on_save = { timeout_ms = 500 },
    formatters = {
      oxlint = {
        command = "oxlint",
        args = { "--fix" },
        stdin = false,
        cwd = function(self, ctx)
          return require("conform.util").root_file({ "package.json", ".oxlintrc.json" })(self, ctx)
        end,
      },
    },
  },
}
