return {
  "uga-rosa/translate.nvim",
  config = function()
    require("translate").setup({
      -- 可以在这里进行个性化配置
      default = {
        command = "google", -- 默认使用 Google 翻译
        output = "floating", -- 翻译结果显示在悬浮窗口
      },
      preset = {
        -- 你可以添加自定义预设
      },
    })
  end,
  keys = {
    -- 添加快捷键映射
    { "<leader>t", "<Cmd>Translate<CR>", mode = { "n", "v" }, desc = "Translate" },
    { "<leader>tr", "<Cmd>TranslateR<CR>", mode = { "n", "v" }, desc = "Translate Reverse" },
  },
}
