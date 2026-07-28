# Summer Festival — チョコバナナ屋台

Roblox Studio で使う、チョコバナナの作成・販売システムです。Rojo で同期できます。

## 入っている機能

- 募集ブロックに触れると、スタッフになるか確認
- 1つの屋台につきスタッフは1人
- スタッフを作業位置へ固定し、左右の回転だけ許可
- スタッフ中は一人称視点になり、手動・作業中の旋回へカメラが追従
- 画面の辞任ボタン
- 左手にバナナ、右手に棒を持つ
- 刺す → チョコに漬ける → トッピング → 販売台へ置く工程
- チョコ工程中は筒の方向へ一時的に固定
- トッピング開始1秒後から、下向きの粒を3秒表示
- 完成品を `DisplayPoint` の位置と回転で設置
- コマンドバーから屋台上の展示板、完成品・未コーティング串バナナの見本を作成
- スタッフ以外が50円で購入可能
- 初期100円の所持金とUI
- サーバー側の工程・価格・役職検証
- 所持金のDataStore保存（公開ゲームで有効）

## 導入

1. [Rojo](https://rojo.space/) と Roblox Studio の Rojo プラグインを用意します。
2. このリポジトリのルートで `rojo serve` を実行します。
3. Studio の Rojo プラグインから接続して同期します。
4. [`docs/STUDIO_SETUP.md`](docs/STUDIO_SETUP.md) に従って屋台の部品へタグを付けます。
5. [`docs/STALL_LAYOUT.md`](docs/STALL_LAYOUT.md) を参考に部品を配置します。
6. 屋台と商品メッシュを選択し、[`docs/STALL_DISPLAY_COMMAND_BAR.lua`](docs/STALL_DISPLAY_COMMAND_BAR.lua) を Studio のコマンドバーで実行します。
7. Studio の **Test → Start** で2人以上を起動し、[`docs/TEST_CHECKLIST.md`](docs/TEST_CHECKLIST.md) を確認します。

アニメーション未設定でも工程は進みます。公開済みアニメーションのIDを
[`Config.lua`](src/ReplicatedStorage/ChocolateBanana/Config.lua) に入れると再生されます。

## 主な設定

`Config.lua` で変更できます。

| 設定 | 初期値 | 内容 |
|---|---:|---|
| `InitialYen` | `100` | 初回所持金 |
| `ProductPrice` | `50` | チョコバナナ価格 |
| `SaveInStudio` | `false` | StudioテストでDataStoreを使うか |
| `RotationSpeedDegrees` | `100` | スタッフの回転速度 |
| `AnimationIds` | 空 | 刺す・漬ける・トッピングのアニメーションID |

## 操作

- PC：`A` / `D`、`←` / `→`、`Q` / `E` で回転
- スマートフォン：スタッフUIの「左回転」「右回転」を長押し
- 各材料・設備：自動生成される ProximityPrompt を使用
- 棒とバナナを持った後：画面の「バナナを刺す」
- 辞任：画面の「辞任」

## セキュリティ

商品の工程、屋台の空き、購入価格、残高変更はサーバーで判定します。クライアントはUIと回転入力だけを担当します。

