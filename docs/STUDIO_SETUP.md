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
| `SkeweredBanana` | 棒を刺した状態 |
| `DippedBanana` | チョコに漬けた状態 |
| `FinishedBanana` | トッピング後・販売台の商品 |
| `FinishedBananaTool` | 購入者へ渡すTool（任意） |

各Modelは `PrimaryPart` を設定してください。未設定の場合は、最初に見つかったBasePartが使われます。手持ち状態では、モデル内のBasePartがPrimaryPartへ自動的に固定されます。

皮付きバナナ、棒、チョコ後、完成品の4つがある場合は、4つを選択して
[`REGISTER_CHOCOLATE_BANANA_MESHES.command.lua`](../studio/REGISTER_CHOCOLATE_BANANA_MESHES.command.lua)
をコマンドバーで実行すると自動登録できます。

名前で判定できないメッシュは、Explorerで「皮付きバナナ → 棒 → チョコ後 → 完成品」の順にCtrlを押しながら選択します。`SpecialMesh`を選択した場合は、その親Partが登録されます。

`SkeweredBanana` を省略した場合は、登録した `Banana` と `Stick` から自動合成されます。`DippedBanana` と `FinishedBanana` は登録された実物メッシュが自動合成より優先されます。

`FinishedBananaTool` は任意です。省略した場合は、登録した `FinishedBanana` メッシュを使って購入者用Toolが自動生成されます。完成品Toolを個別に用意する場合は `Tool` 内に `Handle` というBasePartを置きます。

手に持つ角度は `Config.ItemOffsets`、串刺し合成時の位置は `Config.CompositeOffsets` で調整できます。

## 4. スタッフカメラ

スタッフになるとカメラは一人称になり、キャラクターの正面へ固定されます。マウス移動では視点が変わらず、PCでは `A` / `D` だけで左・右へ回転します。辞任すると、スタッフになる前のカメラ設定へ戻ります。

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
