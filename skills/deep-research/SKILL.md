---
name: deep-research
description: |
  Deep research using OpenAI Deep Research API (o3/o4-mini).
  Fetches OpenAI keys via secrets4claude, selects model by topic complexity,
  submits background research request, polls for completion, returns structured report.
  Auto-fires when deep factual investigation or multi-source synthesis is needed.
---

# deep-research — OpenAI Deep Research パイプライン

secrets4claude で API キーを取得し、OpenAI Deep Research API（Responses API）で
Web 上の数百ソースを探索・分析・統合した詳細レポートを生成する。

## モデル選定ガイドライン

| モデル | ID | 用途 | コスト |
|---|---|---|---|
| **o3-deep-research** | `o3-deep-research-2025-06-26` | 複雑・高重要度の調査 | $10/$40 per 1M tokens |
| **o4-mini-deep-research** | `o4-mini-deep-research-2025-06-26` | 標準的な調査・速度優先 | $2/$8 per 1M tokens |

### o3 を選ぶべき場面（難しい調査）

- 複数ドメインにまたがる学際的リサーチ
- 競合分析・市場調査など100+ソースの統合が必要
- 矛盾する情報源の比較・信頼性評価が重要
- 学術的・技術的に深い分析が求められる
- ステークホルダーへの最終レポートとして使う

### o4-mini を選ぶべき場面（標準的な調査）

- 単一ドメインの事実確認・背景調査
- 技術仕様やAPI仕様の調査
- トレンド・最新動向の把握
- 予備調査・方向性の確認
- 時間・コスト制約がある

### 判断フロー

```
トピックの複雑さ？
├─ 高（学際的/多数ソース統合/矛盾情報の評価） → o3-deep-research
└─ 中〜低（単一ドメイン/事実確認/仕様調査） → o4-mini-deep-research

重要度？
├─ 高（最終成果物/意思決定の根拠） → o3-deep-research
└─ 中〜低（予備調査/背景情報） → o4-mini-deep-research
```

**迷ったら o4-mini から始める。** 結果が不十分なら o3 にエスカレート。

## API アーキテクチャ（トリッキーな部分）

### Responses API 専用

- エンドポイント: `POST https://api.openai.com/v1/responses`
- Chat Completions (`/v1/chat/completions`) では**使えない**
- function calling / structured outputs は**非対応**

### 非同期バックグラウンドモード（必須）

1. `"background": true` でリクエスト送信 → 即座に `id` + `status: "queued"` が返る
2. `GET /v1/responses/{id}` でポーリング（15秒間隔）
3. `status: "completed"` になったら結果取得
4. 完了後 **約10分** でデータが消える → すぐに取得すること

### ツール指定が必須

最低1つのデータソースツールが必要:
- `web_search_preview` — Web検索（必須）
- `code_interpreter` — コード実行による分析（推奨）

### レスポンス構造

```
output[]:
  ├─ reasoning (思考過程サマリー)
  ├─ web_search_call[] (検索クエリ・訪問URL)
  ├─ code_interpreter_call[] (実行コード・結果)
  └─ message (最終レポート)
       └─ content[0]
            ├─ text: "レポート本文..."
            └─ annotations[]: [{title, url, start_index, end_index}]
```

## 実行手順

### Step 1: OpenAI キーを取得

```bash
SKILLS_DIR="$HOME/.claude/skills/codex4claude/skills"
eval $($SKILLS_DIR/secrets4claude/scripts/secret-fetch --bundle openai)
```

### Step 2: モデルを選定してリサーチ実行

```bash
# o4-mini（標準調査）
$SKILLS_DIR/deep-research/scripts/deep-research \
  o4-mini-deep-research-2025-06-26 \
  "調査クエリをここに記述"

# o3（複雑な調査）
$SKILLS_DIR/deep-research/scripts/deep-research \
  o3-deep-research-2025-06-26 \
  "複雑な調査クエリをここに記述"
```

### Step 3: 結果を取得

スクリプトは JSON で出力する:
```json
{
  "report": "レポート本文（Markdown形式、引用付き）",
  "citations": [{"title": "...", "url": "..."}],
  "metadata": {
    "model": "o4-mini-deep-research-2025-06-26",
    "response_id": "resp_...",
    "elapsed_seconds": 180,
    "web_search_count": 45,
    "input_tokens": 5000,
    "output_tokens": 15000
  }
}
```

## オプション

| パラメータ | デフォルト | 説明 |
|---|---|---|
| `--max-tool-calls N` | なし | ツール呼び出し上限（コスト・レイテンシ制御の主要手段） |
| `--poll-interval S` | 15 | ポーリング間隔（秒） |
| `--timeout S` | 1800 | 最大待機時間（秒、デフォルト30分） |

### コスト制御の目安

| max-tool-calls | 想定コスト (o4-mini) | 用途 |
|---|---|---|
| 20 | ~$0.30-0.50 | クイック調査 |
| 50 | ~$0.80-1.50 | 標準調査 |
| 100+ | ~$2.00-5.00 | 徹底調査 |

## AUTO-FIRE RULES

以下の場面でこのスキルを **自動的に起動** する:

1. ユーザーが「深く調べて」「詳しく調査して」「deep research」と言った
2. 前提知識が不足しており、正確な情報が必要な場面
3. 最新の市場動向・技術仕様・競合情報が必要
4. 複数ソースの統合・比較が求められる調査タスク

### 起動しない場面

- Claude の既存知識で十分回答できる質問
- 単純なコード生成・編集タスク
- ユーザーが「solo」「自分でやって」と指示した場合
- secrets4claude のキー取得だけで済む場合

## プロンプトエンリッチメント（推奨）

Deep Research API は clarification ステップをスキップするため、
Claude 側でクエリを補強してから投げると品質が上がる:

1. ユーザーの質問を分析
2. 必要な文脈・制約条件・期待する出力形式を付加
3. 補強したクエリを deep-research スクリプトに渡す

```
元のクエリ: "TikTok広告の最新トレンド"
↓ 補強後
"2025-2026年のTikTok広告プラットフォームの最新トレンドを調査してください。
対象: 日本市場およびグローバル市場。
含めるべき内容: (1) 新しい広告フォーマット (2) ターゲティング機能の変更
(3) CPM/CPA のトレンド (4) 主要な成功事例 (5) 2026年の予測
形式: セクション見出し付きの構造化レポート、各主張にソースURL付き"
```

## エラーハンドリング

| エラー | 対処 |
|---|---|
| `OPENAI_API_KEY is not set` | `secrets4claude --bundle openai` を先に実行 |
| Submit失敗 | APIキーの有効性・レート制限を確認 |
| Timeout | `--timeout` を延長、または `--max-tool-calls` で制限 |
| `status: failed` | レスポンスのerrorフィールドを確認、クエリを簡略化して再試行 |

## コスト見積もり

スクリプトは完了時に stderr にコスト見積もりを出力する:
```
>>> Estimated cost: $1.10 (tokens: 60506in/22883out, 77 web searches)
```

Web検索は1回あたり $0.01、code_interpreter は1セッション $0.03。
