return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },
  { "catppuccin/nvim" },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      --colorscheme = "wildcharm",
      colorscheme = "tokyonight-moon",
    },
  },
}
