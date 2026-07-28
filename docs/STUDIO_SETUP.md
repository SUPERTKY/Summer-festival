# Roblox Studio セットアップ

## 1. 屋台モデル

Workspace に屋台用の `Model` を作り、次の属性を付けます。

| 属性 | 型 | 例 |
|---|---|---|
| `StallId` | String | `choco-banana-01` |

複数屋台を置く場合は、屋台ごとに異なる `StallId` を使います。以下の部品をすべてこのModelの子にすると、各部品へ同じ属性を繰り返し付ける必要はありません。

## 2. 部品へ付けるタグ

Studio のタグ編集画面から、部品へ次の CollectionService タグを付けます。

| 部品 | タグ | 動作 |
|---|---|---|
| スタッフ募集ブロック | `ChocolateBananaStaffJoinBlock` | 触れたプレイヤーへ確認UIを表示 |
| 作業位置ブロック | `ChocolateBananaWorkAnchor` | スタッフを位置固定。向きが初期方向 |
| バナナ置き場 | `ChocolateBananaBananaSource` | 左手へバナナを追加 |
| 棒置き場 | `ChocolateBananaStickSource` | 右手へ棒を追加 |
| チョコ入り筒 | `ChocolateBananaChocolateVat` | 筒の方向へ固定して漬ける |
| トッピング容器 | `ChocolateBananaToppingContainer` | アニメーションと3秒の粒エフェクト |
| 販売操作ブロック | `ChocolateBananaSellBlock` | 完成品を販売台へ置く |
| 完成品の設置位置 | `ChocolateBananaDisplayPoint` | 位置と回転を完成品へ適用 |

`WorkAnchor` と `DisplayPoint` は次の設定がおすすめです。

- `Transparency = 1`
- `CanCollide = false`
- `Anchored = true`

`WorkAnchor` の中心は、スタッフの `HumanoidRootPart` を置きたい高さ（床から約3スタッド）に合わせます。
`DisplayPoint` を回転させると、完成品も同じ向きで設置されます。

## 3. 用意した商品モデルを使う

`ServerStorage` に `ChocolateBananaAssets` フォルダーを作り、用意したモデルを次の名前で入れます。

| 名前 | 用途 |
|---|---|
| `Banana` | 左手で持つバナナ |
| `Stick` | 右手で持つ棒 |
| `SkeweredBanana` | 棒を刺した未コーティング状態（今回用意したメッシュ） |
| `DippedBanana` | チョコに漬けた状態 |
| `FinishedBanana` | トッピング後・販売台の商品 |
| `FinishedBananaTool` | 購入者へ渡すTool（任意） |

各Modelは `PrimaryPart` を設定してください。未設定の場合は、最初に見つかったBasePartが使われます。手持ち状態では、モデル内のBasePartがPrimaryPartへ自動的に固定されます。

`FinishedBananaTool` は `Tool` とし、内部に `Handle` というBasePartを用意します。省略した場合は簡易Toolが自動生成されます。ほかの商品モデルを省略した場合も、動作確認用の仮モデルが使われます。

手に持つ角度は `Config.ItemOffsets` で調整できます。

## 4. 展示板とメッシュをコマンドバーで設定

1. 屋台Modelへ空でない `StallId` 属性があることを確認します。
2. 用意した未コーティングの串バナナを `SkeweredBanana` に改名します。
3. Explorerで屋台Modelと `SkeweredBanana` を選択します。
4. `FinishedBanana` が `ServerStorage/ChocolateBananaAssets` にまだ無い場合は、現在のチョコバナナを `FinishedBanana` に改名して一緒に選択します。
5. [`STALL_DISPLAY_COMMAND_BAR.lua`](STALL_DISPLAY_COMMAND_BAR.lua) 全体をStudioの **View → Command Bar** へ貼り付けて実行します。

スクリプトは次を設定します。

- 屋台上の木製展示板
- 完成チョコバナナと未コーティング串バナナの見本
- 展示板上の販売用 `DisplayPoint`
- `ServerStorage/ChocolateBananaAssets/SkeweredBanana` と `FinishedBanana`

既存の `DisplayPoint` があればその真下へ板を作ります。無い場合はスクリプト先頭の `BOARD_OFFSET` を屋台の形に合わせて調整してください。メッシュを差し替えた場合、以前のアセットは `CommandBarBackups` に残ります。

## 5. アニメーション

所有グループまたはゲーム所有者としてアニメーションを公開し、`Config.AnimationIds` に数値IDを設定します。

```lua
AnimationIds = {
    Skewer = "1234567890",
    Dip = "2345678901",
    Topping = "3456789012",
},
```

| 名前 | 推奨長さ | タイミング |
|---|---:|---|
| `Skewer` | 約1.6秒 | 左手のバナナへ右手の棒を刺す |
| `Dip` | 約2.5秒 | チョコの筒へ下ろして戻す |
| `Topping` | 約4.2秒 | 1秒後から3秒間、下向きエフェクト |

工程時間を変える場合は `Config.ActionDurations` も合わせて変更します。

## 6. 所持金保存

公開ゲームではDataStoreへ自動保存されます。Studioでも保存を試す場合：

1. Game Settings の Security を開く
2. Studio Access to API Services を有効化
3. `Config.SaveInStudio = true` に変更

本番データとStudioテストを分ける場合は、`DataStoreName` をテスト用の名前へ変更してください。
