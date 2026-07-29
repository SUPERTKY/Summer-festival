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
| バナナ置き場 | `ChocolateBananaBananaSource` | 工程表示を皮なしバナナへ更新 |
| 棒置き場 | `ChocolateBananaStickSource` | 串刺し可能な工程へ進める |
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
| `Banana` | 皮付きバナナ。材料の初期表示に使用 |
| `PeeledBanana` | 皮なし・串なしバナナ。工程展示の串刺し前に使用 |
| `Stick` | 串付きモデルの代替合成に使用する棒 |
| `SkeweredBanana` | 串刺し済み・チョコ前の別メッシュ |
| `DippedBanana` | チョコに漬けた状態 |
| `FinishedBanana` | トッピング後・販売台の商品 |

各Modelは `PrimaryPart` を設定してください。未設定の場合は、最初に見つかったBasePartが使われます。工程展示の移動・回転はModelのPivotを使います。

`FinishedBanana` はトッピング後の工程展示、販売台の商品、購入者へ渡すToolの3か所で共通利用されます。購入時は完成品メッシュのPrimaryPartがToolの `Handle` になります。ほかの商品モデルを省略した場合は動作確認用の仮モデルが使われます。

名前で判定できないメッシュは、Explorerで「皮付きバナナ → 皮なし・串なしバナナ → 棒 → 串刺し済み・チョコ前 → チョコ後 → 完成品」の順にCtrlを押しながら6つを選択します。`SpecialMesh`を選択した場合は、その親Partが登録されます。

串刺し後は登録した `SkeweredBanana` をそのまま使用します。`SkeweredBanana` を省略した場合だけ、`PeeledBanana` と `Stick` から代替品を自動合成します。`PeeledBanana` が未登録の古い場所では `Banana` を代用します。個別に差し替える場合は [`REGISTER_PEELED_BANANA.command.lua`](../studio/REGISTER_PEELED_BANANA.command.lua) と [`REGISTER_SKEWERED_BANANA.command.lua`](../studio/REGISTER_SKEWERED_BANANA.command.lua) を使えます。`DippedBanana` と `FinishedBanana` は登録された実物メッシュが自動合成より優先されます。

`FinishedBananaTool` は任意です。省略した場合は、登録した `FinishedBanana` メッシュを使って購入者用Toolが自動生成されます。完成品Toolを個別に用意する場合は `Tool` 内に `Handle` というBasePartを置きます。

購入Toolの持ち方は `Config.ItemOffsets.FinishedBanana`、串刺し代替合成時の位置は `Config.CompositeOffsets` で調整できます。

- 屋台上の木製展示板
- 展示板左側の工程表示用 `CurrentStepDisplayPoint`
- 展示板右側の販売用 `DisplayPoint`
- `ServerStorage/ChocolateBananaAssets/SkeweredBanana` と `FinishedBanana`

既存の `DisplayPoint` があれば販売位置を維持するように板を作ります。工程表示は `Banana → PeeledBanana → SkeweredBanana → DippedBanana → FinishedBanana` の順でサーバーから自動更新されます。板が無い場合はスクリプト先頭の `BOARD_OFFSET` を屋台の形に合わせて調整してください。メッシュを差し替えた場合、以前のアセットは `CommandBarBackups` に残ります。

## 5. 独自トッピングエフェクト

トッピング用の `ParticleEmitter` を1つ選択し、
[`REGISTER_TOPPING_EFFECT.command.lua`](../studio/REGISTER_TOPPING_EFFECT.command.lua)
をコマンドバーで実行します。

登録先は `ServerStorage/ChocolateBananaEffects/ToppingParticle` です。既存の登録物はバックアップ名で残ります。

- ParticleEmitterがAttachment内にある場合：元モデルのルートPart基準の位置・向きを自動保存
- 古い登録コマンドを実行済みの場合：更新後のコマンドで同じEmitterを再登録
- 自動保存後も向きが逆の場合：`Config.EffectOffsets.ToppingOrientationOffset` にX/Y/Zいずれかの180度回転を設定
- Attachment以外にある場合：`Config.EffectOffsets.Topping` を使用
- `Rate = 0` のEmitter：トッピング開始時に30個を一度だけ放出
- `Rate > 0` のEmitter：3秒間有効化

チョコ漬けは常に `ChocolateVat` の上方向から下方向へ移動します。バナナ自体の上下は
`Config.ActionVisuals.DipOrientationOffset` で調整します。

## 6. アニメーション

`Config.AnimationIds` が空でも、棒を刺す一時モデル、チョコ筒で上下する一時モデル、進行バー、完了エフェクトが動きます。独自のキャラクターアニメーションも加える場合は、所有グループまたはゲーム所有者として公開し、`Config.AnimationIds` に数値IDを設定します。商品自体は手に持たず、見た目の変化は工程展示で行います。

```lua
AnimationIds = {
    Skewer = "1234567890",
    Dip = "2345678901",
    Topping = "3456789012",
},
```

| 名前 | 推奨長さ | タイミング |
|---|---:|---|
| `Skewer` | 約1.6秒 | 皮なしバナナの前で棒が移動し、終了時に串付きへ交換 |
| `Dip` | 約2.5秒 | 工程展示から消え、チョコ筒の上で沈んで戻る |
| `Topping` | 約4.2秒 | 工程展示が小刻みに動き、1秒後から3秒間粒を表示 |

工程時間を変える場合は `Config.ActionDurations` も合わせて変更します。

## 7. 所持金保存

公開ゲームではDataStoreへ自動保存されます。Studioでも保存を試す場合：

1. Game Settings の Security を開く
2. Studio Access to API Services を有効化
3. `Config.SaveInStudio = true` に変更

本番データとStudioテストを分ける場合は、`DataStoreName` をテスト用の名前へ変更してください。
