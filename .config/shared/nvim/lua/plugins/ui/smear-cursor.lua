return {
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      -- カーソル軌跡の追従感（高いほど機敏、低いほど慣性が強い）
      stiffness = 0.8,
      trailing_stiffness = 0.5,
      -- アニメーション停止距離（ピクセル）
      distance_stop_animating = 0.5,
      -- ターミナルカーソルを隠さない（WezTerm との整合性を優先）
      hide_target_hack = false,
      -- 軌跡フェードアウト
      trailing_exponent = 2,
    },
  },
}
