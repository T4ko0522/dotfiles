# Go TUI Guidelines

Go で TUI ツールを開発する際の共通規約。`system-designer` と Codex（実装フェーズ）が参照する。

## 技術スタック

- **TUI フレームワーク**: `github.com/charmbracelet/bubbletea`（Elm アーキテクチャ）
- **スタイリング**: `github.com/charmbracelet/lipgloss`
- **追加コンポーネント**: `github.com/charmbracelet/bubbles`（list, table, viewport, textinput, spinner, progress, paginator など）

これら以外の TUI ライブラリ（tview, termui, gocui, termbox-go 等）は **使用禁止**。

## アーキテクチャ（Elm アーキテクチャ）

```
┌──────────┐  Msg   ┌──────────┐
│  View    │ ←──── │  Update  │
└──────────┘        └──────────┘
     ↑                    ↑
     │                    │
     │   Model            │ Cmd
     └────────────────────┘
```

### 責務分離

| 要素 | 配置 | 責務 |
|------|------|------|
| Model | `internal/ui/model/` | アプリの状態。純粋データ。 |
| Update | `Model.Update(msg) (Model, Cmd)` | メッセージで状態遷移。副作用は Cmd で返す |
| View | `Model.View() string` | Model から表示文字列を生成。副作用なし |
| Msg | `internal/ui/msg/` | イベントの型定義 |
| Cmd | tea.Cmd | I/O やタイマー等の副作用を tea.Msg に変換 |

### ディレクトリ構成例

```
cmd/<tool>/
  main.go              # tea.NewProgram を起動
internal/
  ui/
    model/
      app.go           # ルート Model
      list.go          # サブ View 用 Model
    msg/
      events.go        # 独自 Msg 型
    style/
      palette.go       # カラーパレット定義
      style.go         # lipgloss.Style 定義
    keys/
      binding.go       # キーマップ定義
  domain/              # TUI と独立したドメインロジック
```

ドメインロジックは `internal/domain/` に置き、UI から呼び出す形にする。
UI レイヤーがドメインに依存し、逆は禁止。

## カラーパレット

`internal/ui/style/palette.go` に集約する。

### 基本パレット（ライト / ダーク両対応）

```go
package style

import "github.com/charmbracelet/lipgloss"

var (
    // ベースカラー
    Primary   = lipgloss.AdaptiveColor{Light: "#0969da", Dark: "#58a6ff"}
    Secondary = lipgloss.AdaptiveColor{Light: "#6e7781", Dark: "#8b949e"}
    Accent    = lipgloss.AdaptiveColor{Light: "#1f883d", Dark: "#3fb950"}

    // セマンティック
    Success = lipgloss.AdaptiveColor{Light: "#1a7f37", Dark: "#3fb950"}
    Warning = lipgloss.AdaptiveColor{Light: "#9a6700", Dark: "#d29922"}
    Error   = lipgloss.AdaptiveColor{Light: "#cf222e", Dark: "#f85149"}
    Info    = lipgloss.AdaptiveColor{Light: "#0969da", Dark: "#58a6ff"}

    // テキスト
    Text     = lipgloss.AdaptiveColor{Light: "#1f2328", Dark: "#e6edf3"}
    Muted    = lipgloss.AdaptiveColor{Light: "#6e7781", Dark: "#8b949e"}
    Subtle   = lipgloss.AdaptiveColor{Light: "#afb8c1", Dark: "#484f58"}

    // 背景
    BgBase    = lipgloss.AdaptiveColor{Light: "#ffffff", Dark: "#0d1117"}
    BgSubtle  = lipgloss.AdaptiveColor{Light: "#f6f8fa", Dark: "#161b22"}
    BgEmphasis = lipgloss.AdaptiveColor{Light: "#ddf4ff", Dark: "#1f6feb"}

    // 境界
    Border    = lipgloss.AdaptiveColor{Light: "#d1d9e0", Dark: "#30363d"}
    BorderFocus = lipgloss.AdaptiveColor{Light: "#0969da", Dark: "#58a6ff"}
)
```

要件で別パレットが指定された場合のみ差し替える。デフォルトは上記。

## スタイル規約

`internal/ui/style/style.go` に共通スタイルを集約する。

```go
package style

import "github.com/charmbracelet/lipgloss"

var (
    // タイトル
    Title = lipgloss.NewStyle().
        Bold(true).
        Foreground(Primary).
        Padding(0, 1)

    // ステータスバー
    StatusBar = lipgloss.NewStyle().
        Foreground(Muted).
        Background(BgSubtle).
        Padding(0, 1)

    // フォーカス枠
    FocusedBorder = lipgloss.NewStyle().
        Border(lipgloss.RoundedBorder()).
        BorderForeground(BorderFocus)

    UnfocusedBorder = lipgloss.NewStyle().
        Border(lipgloss.RoundedBorder()).
        BorderForeground(Border)

    // 選択中アイテム
    Selected = lipgloss.NewStyle().
        Bold(true).
        Foreground(Primary)

    // エラー
    ErrorMsg = lipgloss.NewStyle().
        Bold(true).
        Foreground(Error)
)
```

### スタイル運用ルール

1. **インラインスタイル禁止** — `lipgloss.NewStyle()...` を View 内で書かない。必ず `style.go` に名前付きで定義
2. **色は直接指定しない** — `palette.go` の変数経由のみ
3. **AdaptiveColor を使う** — `lipgloss.Color("#...")` 単独ではなく `AdaptiveColor` で light/dark 両対応
4. **`MaxWidth` / `MaxHeight` を設定** — ウィンドウリサイズで崩れないようにする

## キーバインド規約

`internal/ui/keys/binding.go` に集約する。

```go
package keys

import "github.com/charmbracelet/bubbles/key"

type KeyMap struct {
    Up     key.Binding
    Down   key.Binding
    Left   key.Binding
    Right  key.Binding
    Enter  key.Binding
    Back   key.Binding
    Quit   key.Binding
    Help   key.Binding
    Filter key.Binding
}

var DefaultKeyMap = KeyMap{
    Up:    key.NewBinding(key.WithKeys("up", "k"), key.WithHelp("↑/k", "up")),
    Down:  key.NewBinding(key.WithKeys("down", "j"), key.WithHelp("↓/j", "down")),
    Left:  key.NewBinding(key.WithKeys("left", "h"), key.WithHelp("←/h", "left")),
    Right: key.NewBinding(key.WithKeys("right", "l"), key.WithHelp("→/l", "right")),
    Enter: key.NewBinding(key.WithKeys("enter"), key.WithHelp("enter", "select")),
    Back:  key.NewBinding(key.WithKeys("esc"), key.WithHelp("esc", "back")),
    Quit:  key.NewBinding(key.WithKeys("q", "ctrl+c"), key.WithHelp("q", "quit")),
    Help:  key.NewBinding(key.WithKeys("?"), key.WithHelp("?", "help")),
    Filter: key.NewBinding(key.WithKeys("/"), key.WithHelp("/", "filter")),
}
```

### キーバインド規約

- **必須キー**: `quit (q, ctrl+c)`, `up (↑, k)`, `down (↓, j)`, `enter`, `back (esc)`
- **vim ライク**: `h j k l` を方向キーと併存させる
- **`?`** でヘルプ表示
- **`/`** でインクリメンタルフィルタ（list / table 系のみ）
- **アプリ固有キーは英字単独** を割り当てる（`r` reload, `d` delete, `a` add 等）
- **ヘルプ表示** は `bubbles/help` パッケージで自動生成

## レイアウトパターン

### フルスクリーン単一ビュー

```go
type Model struct {
    width, height int
    list          list.Model
}

func (m Model) View() string {
    return lipgloss.NewStyle().
        Width(m.width).
        Height(m.height).
        Render(m.list.View())
}
```

### 上下分割（リスト + 詳細）

```go
func (m Model) View() string {
    listView := style.FocusedBorder.
        Width(m.width).
        Height(m.height * 2 / 3).
        Render(m.list.View())

    detailView := style.UnfocusedBorder.
        Width(m.width).
        Height(m.height / 3).
        Render(m.detail.View())

    return lipgloss.JoinVertical(lipgloss.Left, listView, detailView)
}
```

### 左右分割（ナビ + コンテンツ）

```go
func (m Model) View() string {
    nav := style.UnfocusedBorder.
        Width(m.width / 4).
        Height(m.height).
        Render(m.nav.View())

    content := style.FocusedBorder.
        Width(m.width * 3 / 4).
        Height(m.height).
        Render(m.content.View())

    return lipgloss.JoinHorizontal(lipgloss.Top, nav, content)
}
```

## WindowSizeMsg の扱い

ウィンドウサイズ変更は必ず捕捉し、子コンポーネントにも伝播する:

```go
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.WindowSizeMsg:
        m.width = msg.Width
        m.height = msg.Height
        m.list.SetSize(msg.Width, msg.Height-2)  // ステータスバー分を引く
        return m, nil
    }
    return m, nil
}
```

## エラー表示

エラーは Model に保持してフッターに表示する。ポップアップは控えめに。

```go
type Model struct {
    err error
}

func (m Model) View() string {
    var footer string
    if m.err != nil {
        footer = style.ErrorMsg.Render("Error: " + m.err.Error())
    }
    return lipgloss.JoinVertical(lipgloss.Left, m.mainView(), footer)
}
```

## テスト

- View のスナップショットテストは `teatest` パッケージを使う
- Update のテストは Msg を渡して期待 Model と比較する純粋な単体テスト
- I/O Cmd は依存注入してモックする

```go
func TestUpdate_Quit(t *testing.T) {
    m := New()
    updated, cmd := m.Update(tea.KeyMsg{Type: tea.KeyCtrlC})
    if cmd == nil || cmd().(tea.QuitMsg) != (tea.QuitMsg{}) {
        t.Errorf("expected Quit cmd")
    }
    _ = updated
}
```

## アクセシビリティ

- 色のみで情報を伝えない（記号・テキストも併用）
- `NO_COLOR` 環境変数を尊重する（`lipgloss.SetColorProfile(termenv.Ascii)` で切替）
- フォーカス可視化はボーダーと配色の両方で示す
- スクリーンリーダ対応は本質的に難しいため、`--no-tui` フラグで非 TUI 出力も提供する

## パフォーマンス

- 大量データは `viewport` または `list` のページネーションで扱う（全件レンダリングしない）
- 1 フレームの View 生成は **16ms 以内**（60fps 想定）
- 非同期処理は必ず `tea.Cmd` で返し、`Update` をブロックしない
- 60fps を超えるリフレッシュは無意味（ターミナルの描画レートに依存）
