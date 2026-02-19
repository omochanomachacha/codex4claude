# codex4claude - Claude Code x Codex CLI 双方向議論スキル

Claude Code のスキルとして [Codex CLI](https://github.com/openai/codex) を呼び出し、Claude と Codex（OpenAI GPT）が**複数ラウンドの双方向議論**を行うためのスキルです。

異なる AI モデル同士を議論させることで、単一モデルでは得られない多角的な視点・批判的分析・セカンドオピニオンを実現します。

## 特徴

- **双方向議論**: Claude と Codex が交互に論点を出し合い、合意・対立点を可視化
- **6つのモード**: debate / deep-analysis / critique / second-opinion / review / devils-advocate
- **動的ラウンド制御**: 収束条件により自動的に議論を終了（最大5ラウンド）
- **安全なサンドボックス**: Codex は read-only モードで実行、ファイル変更不可
- **コードレビュー**: `codex review` コマンドとの統合
- **プロジェクトコンテキスト**: 対象コードや差分を自動的に共有

## 前提条件

### 1. Claude Code（Anthropic）

Claude Code CLI がインストール・認証済みであること。

```bash
# インストール（npm）
npm install -g @anthropic-ai/claude-code

# 認証
claude login
```

公式ドキュメント: https://docs.anthropic.com/en/docs/claude-code

### 2. Codex CLI（OpenAI）

Codex CLI がインストール・認証済みであること。

```bash
# インストール（npm）
npm install -g @openai/codex

# 認証（OpenAI API キーの設定）
codex login
```

`codex login` を実行すると、API キーが `~/.codex/` に保存されます。このディレクトリは `.gitignore` に含まれており、リポジトリにコミットされません。

公式ドキュメント: https://github.com/openai/codex

### 3. 動作環境

- **OS**: macOS / Linux（Windows は WSL 推奨）
- **Node.js**: v18 以上
- **シェル**: bash / zsh

## インストール

### 方法 1: スキルディレクトリに直接配置（推奨）

```bash
# リポジトリをクローン
git clone https://github.com/omochanomachacha/codex4claude.git

# スキルファイルを配置
mkdir -p ~/.claude/skills/codex4claude
cp codex4claude/skill/SKILL.md ~/.claude/skills/codex4claude/SKILL.md

# プロンプトテンプレートを配置（オプション・CCGワークフロー用）
mkdir -p ~/.claude/prompts/codex
cp codex4claude/prompts/*.md ~/.claude/prompts/codex/
```

### 方法 2: シンボリックリンク（更新追従用）

```bash
git clone https://github.com/omochanomachacha/codex4claude.git ~/codex4claude

# スキル
ln -s ~/codex4claude/skill ~/.claude/skills/codex4claude

# プロンプト（オプション）
ln -s ~/codex4claude/prompts ~/.claude/prompts/codex
```

## 使い方

Claude Code のセッション内で `/codex4claude` コマンドを使用します。

```
# 設計について議論
/codex4claude このマイクロサービス分割は適切か議論したい

# コードの批判的レビュー
/codex4claude src/auth/jwt.ts のセキュリティを批判的にレビューして

# セカンドオピニオン
/codex4claude Redis vs Memcached の選定についてセカンドオピニオンが欲しい

# 深い分析
/codex4claude このN+1クエリ問題の根本解決策を深く考えて

# 反論を求める
/codex4claude SSRよりCSRの方がこのケースでは適切だと思う。反論して
```

引数なしで実行すると、現在の会話コンテキストに基づいて議論を開始します。

### モード一覧

| ユーザーの表現 | モード | 説明 |
|---------------|--------|------|
| 議論して / discuss | `debate` | 賛否両論を戦わせる |
| 深く考えて / think deeply | `deep-analysis` | 多角的に掘り下げる |
| 批判的に考えて / critique | `critique` | 弱点・リスクを徹底追求 |
| セカンドオピニオン | `second-opinion` | 別の専門家視点を得る |
| レビューして / review | `review` | コード・設計のレビュー |
| 反論して / challenge | `devils-advocate` | 意図的に反対意見を出す |

## ファイル構成

```
codex4claude/
├── README.md              # このファイル
├── .gitignore             # 機密ファイル除外設定
├── skill/
│   └── SKILL.md           # スキル定義（Claude Code が読み込む）
└── prompts/               # Codex 用プロンプトテンプレート（オプション）
    ├── analyzer.md        # Technical Analyst ロール
    ├── architect.md       # Backend Architect ロール
    ├── debugger.md        # Backend Debugger ロール
    ├── optimizer.md       # Performance Optimizer ロール
    ├── reviewer.md        # Code Reviewer ロール
    └── tester.md          # Backend Test Engineer ロール
```

## セキュリティに関する注意

- **API キーは絶対にコミットしない**: `.codex/`, `.env` などは `.gitignore` で除外されています
- **コンテキスト送信前チェック**: スキルは送信前に `sk-`, `ghp_`, `AKIA` 等のシークレットパターンを検知します
- **read-only サンドボックス**: Codex は `--sandbox read-only` で実行され、ファイルを変更できません
- **スコープ制限**: 議論に必要なファイルのみをコンテキストとして送信します

## トラブルシューティング

| 問題 | 解決策 |
|------|--------|
| `codex: command not found` | `npm install -g @openai/codex` を実行 |
| API キーエラー | `codex login` で再認証 |
| タイムアウト | プロンプトが長すぎる可能性。コンテキストを縮小して再試行 |
| 出力が空 | stderr を確認。プロンプトを簡略化して再試行 |
| スキルが認識されない | `~/.claude/skills/codex4claude/SKILL.md` にファイルがあるか確認 |

## ライセンス

MIT License
