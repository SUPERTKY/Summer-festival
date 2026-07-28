# Summer Festival — チョコバナナ屋台

Roblox Studio で使う、チョコバナナの作成・販売システムです。Rojo で同期できます。

## 入っている機能

- 募集ブロックに触れると、スタッフになるか確認
- 1つの屋台につきスタッフは1人
- スタッフを作業位置へ固定し、左右の回転だけ許可
- スタッフ中は一人称視点になり、手動・作業中の旋回へカメラが追従
- 画面の辞任ボタン
- 左手に皮なしバナナ、右手に棒を持つ
- 刺す → チョコに漬ける → トッピング → 販売台へ置く工程
- チョコ工程中は筒の方向へ一時的に固定
- トッピング開始1秒後から、下向きの粒を3秒表示
- 完成品を `DisplayPoint` の位置と回転で設置
- 屋台上の展示板へ工程中のバナナを自動表示し、販売中の商品とは別スロットで管理
- 購入Toolには `FinishedBanana` の完成品メッシュを使用
- スタッフ以外が50円で購入可能
- 初期100円の所持金とUI
- サーバー側の工程・価格・役職検証
- 所持金のDataStore保存（公開ゲームで有効）

## 導入

1. [Rojo](https://rojo.space/) と Roblox Studio の Rojo プラグインを用意します。
2. このリポジトリのルートで `rojo serve` を実行します。
3. Studio の Rojo プラグインから接続して同期します。
4. 屋台を自動作成する場合は、[`studio/CREATE_CHOCOLATE_BANANA_STALL.command.lua`](studio/CREATE_CHOCOLATE_BANANA_STALL.command.lua) の全体をStudioのコマンドバーへ貼り付けて実行します。
5. 自作の屋台を使う場合は、[`docs/STUDIO_SETUP.md`](docs/STUDIO_SETUP.md) に従って屋台の部品へタグを付けます。
6. [`docs/STALL_LAYOUT.md`](docs/STALL_LAYOUT.md) を参考に部品を配置します。
7. Studio の **Test → Start** で2人以上を起動し、[`docs/TEST_CHECKLIST.md`](docs/TEST_CHECKLIST.md) を確認します。

### コマンドバーで屋台を自動作成

1. Studioで床にするBasePartを1つ選択します。未選択ならワールド原点へ作成されます。
2. **表示 → コマンドバー** を開きます。
3. `studio/CREATE_CHOCOLATE_BANANA_STALL.command.lua` のコード全体を貼り付けてEnterを押します。
4. 作成された屋台Modelは選択状態になります。必要ならModelごと移動します。

実行するたびに `ChocolateBananaStall_01`、`ChocolateBananaStall_02` のように別の屋台が作られます。誤って作成した場合はStudioの「元に戻す」を使えます。

### 用意済みメッシュを登録

1. Explorerで「皮付きバナナ → 皮なしバナナ → 棒 → チョコ後 → 完成品」の順に、Ctrlを押しながら5つを選択します。
2. 名前が `Banana`、`PeeledBanana`、`Stick`、`DippedBanana`、`FinishedBanana` と判別できる場合は、選択順は問いません。
3. [`studio/REGISTER_CHOCOLATE_BANANA_MESHES.command.lua`](studio/REGISTER_CHOCOLATE_BANANA_MESHES.command.lua) の全体をコマンドバーへ貼り付けて実行します。

皮付きバナナ、皮なしバナナ、棒、チョコ後、完成品の実物メッシュが登録されます。串刺し状態は皮なしバナナと棒から自動合成し、購入後のToolにも完成品メッシュを使います。

皮なしバナナだけを後から登録・差し替える場合は、対象を1つ選択して [`studio/REGISTER_PEELED_BANANA.command.lua`](studio/REGISTER_PEELED_BANANA.command.lua) をコマンドバーで実行します。

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

- スタッフ中：一人称カメラをキャラクターの前方へ固定
- PC：`A` / `D` で左・右へ回転
- スマートフォン：スタッフUIの「左回転」「右回転」を長押し
- 各材料・設備：自動生成される ProximityPrompt を使用
- 棒とバナナを持った後：画面の「バナナを刺す」
- 辞任：画面の「辞任」

## セキュリティ

商品の工程、屋台の空き、購入価格、残高変更はサーバーで判定します。クライアントはUIと回転入力だけを担当します。
