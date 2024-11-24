return {
  "williamboman/mason.nvim",
  keys = {
    { "<leader>cm", false },
  },
  opts = {
    ensure_installed = {
      "bash-language-server",
      "lua-language-server",
      "shfmt",
      "stylua",
    },
  },
}
