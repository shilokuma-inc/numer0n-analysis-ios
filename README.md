# リポジトリ名
numer0n-lens-ios

## 概要
ヌメロン解析アプリ
選択と相手の回答から可能性のパターンを提示する
最善手を提示する機能も作成予定

## 使用技術
- SwiftUI（`@main` の `App` から起動。Storyboard は使わない）
- Observation（`@Observable` で状態を管理）
- XCTest（判定・候補の絞り込み・最善手のロジックを単体テスト）
- 最低 iOS 17.0。アプリは外部ライブラリ・サーバーを使わない（オフラインで完結。SwiftLint はビルド時だけ使う）

## Environment

- Xcode 26.6（CI で固定）
- iOS 17.0 以上
- SwiftUI（Observation）/ XCTest
- SwiftLint 0.65.1（Build Tool Plugin。バイナリだけを配布する [SwiftLintPlugins](https://github.com/SimplyDanny/SwiftLintPlugins) 経由）

## Status

<div style="margin:0px;padding:0px;">
  <table width="98%" style="border-collapse: collapse;border:2px double #000080;text-align:center;margin:auto;">
    <tbody>
      <tr>
        <td style="border:2px double #000080;">branch \ workflow</td>
        <td style="border:2px double #000080;">Build</td>
        <td style="border:2px double #000080;">Archive</td>
        <td style="border:2px double #000080;">Upload</td>
      </tr>
      <tr>
        <td style="border:2px double #000080;text-align:left;">main</td>
        <td style="border:2px double #000080;text-align:center;">
          <a href="https://github.com/shilokuma-inc/numer0n-lens-ios/actions/workflows/build.yml?query=branch%3Amain">
            <img src="https://github.com/shilokuma-inc/numer0n-lens-ios/actions/workflows/build.yml/badge.svg?branch=main" alt="Build">
          </a>
        </td>
        <td style="border:2px double #000080;text-align:center;">
          <a href="https://github.com/shilokuma-inc/numer0n-lens-ios/actions/workflows/archive.yml?query=branch%3Amain">
            <img src="https://github.com/shilokuma-inc/numer0n-lens-ios/actions/workflows/archive.yml/badge.svg?branch=main" alt="Archive">
          </a>
        </td>
        <td style="border:2px double #000080;text-align:center;">
        </td>
      </tr>
      <tr>
        <td style="border:2px double #000080;text-align:left;">develop</td>
        <td style="border:2px double #000080;text-align:center;">
          <a href="https://github.com/shilokuma-inc/numer0n-lens-ios/actions/workflows/build.yml?query=branch%3Adevelop">
            <img src="https://github.com/shilokuma-inc/numer0n-lens-ios/actions/workflows/build.yml/badge.svg?branch=develop" alt="Build">
          </a>
        </td>
        <td style="border:2px double #000080;text-align:center;">
        </td>
        <td style="border:2px double #000080;text-align:center;">
          <a href="https://github.com/shilokuma-inc/numer0n-lens-ios/actions/workflows/upload.yml?query=branch%3Adevelop">
            <img src="https://github.com/shilokuma-inc/numer0n-lens-ios/actions/workflows/upload.yml/badge.svg?branch=develop" alt="Upload">
          </a>
        </td>
      </tr>
    </tbody>
  </table>
</div>

## ビルド

```bash
xcodebuild -project Numer0nLens.xcodeproj -scheme Numer0nLens -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild test -project Numer0nLens.xcodeproj -scheme Numer0nLens -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:Numer0nLensTests -parallel-testing-enabled NO
```

- SwiftLint は Build Tool Plugin として全ターゲットに適用されます。コマンドラインで初めてビルドするときは、Xcode でプラグインを信頼する（Trust & Enable）か、`-skipPackagePluginValidation` を付けてください
- CI と同じ検証は、SPM が解決した SwiftLint で `swiftlint lint --strict` を実行します（ルールは [.swiftlint.yml](.swiftlint.yml)）

## 署名情報とバージョン

署名情報・Bundle ID・バージョンは pbxproj ではなく [Configs/Project.xcconfig](Configs/Project.xcconfig) に集約しています。

| 設定 | 内容 |
|---|---|
| `DEVELOPMENT_TEAM` | Apple Developer Program の Team ID（`XU74X3434S`） |
| `APP_BUNDLE_IDENTIFIER` | アプリ本体の Bundle Identifier（`jp.shilokuma.Numer0nLens`）。テストターゲットは `.Tests` / `.UITests` を付けて派生します |
| `APP_DISPLAY_NAME` | ホーム画面に表示するアプリ名（`Numer0n Lens`） |
| `APP_MODULE_NAME` | アプリ本体の Swift モジュール名（`Numer0nLens`）。テストは `@testable import Numer0nLens` で読み込みます |
| `MARKETING_VERSION` | アプリのバージョン。ビルド番号（`CURRENT_PROJECT_VERSION`）は Upload のときに App Store Connect の最新ビルドを見て Xcode が自動で増やすため、手で上げる必要はありません |
| `IPHONEOS_DEPLOYMENT_TARGET` | 最低サポート OS（17.0） |

## CI（GitHub Actions）

ワークフローは [shilokuma-inc/template-app-ios](https://github.com/shilokuma-inc/template-app-ios) のものを移植しています。

| ブランチ | Build（ビルド + テスト + SwiftLint） | Archive（IPA Export） | Upload（App Store Connect） |
|---|:-:|:-:|:-:|
| `main` | ✅ | ✅ | |
| `develop` | ✅ | | ✅ |
| `release/**` | ✅ | | ✅ |
| その他の作業ブランチ | ✅（Unit テストのみ） | | |
| Pull Request の作成時（opened / reopened / ready_for_review） | ✅ | | |
| Fork からの Pull Request | ✅ | | |
| `assets/**` ブランチへの push（PR 用スクリーンショット置き場。PR を作ったときは上の Pull Request の行のとおり） | | | |

- Upload は Archive → IPA Export を含むため、`develop` / `release/**` では Archive を別途実行しません
- Archive / Upload は Actions タブから手動でも実行できます（Run workflow）
- `epic/**` 宛ての Pull Request（ralph-loop の子 PR）では PR イベントで Build を実行しません（ブランチへの push で実行されます）
- ドキュメントだけの変更（`**/*.md`、`docs/**`）では Build を実行しません
- Xcode のバージョンは [.github/workflows/_build.yml](.github/workflows/_build.yml) と [.github/workflows/_archive.yml](.github/workflows/_archive.yml) の `xcode-version` で固定しています
- CI のワークフローは、リポジトリ直下の `*.xcodeproj` と同名の共有スキーム（`Numer0nLens`）があることを前提にしています

### Archive / Upload を動かすために必要な設定

Archive / Upload は App Store Connect API Key で認証します。以下はリポジトリの外での設定で、人が行います。

1. **リポジトリ変数 `ENABLE_DELIVERY`**（Settings → Secrets and variables → Actions → Variables）:
   App Store Connect にアプリを作るまでは `ENABLE_DELIVERY=false` を設定して Upload を止めます（`develop` への push で Upload が走るため）。アプリを作ったら変数を消すか `true` にします
2. **Secrets**（org で共有しているものを使います。このリポジトリから使えることを確認してください）:

   | Secret | 内容 |
   |---|---|
   | `EXPORT_OPTIONS` | `ExportOptions.plist` の内容。[docs/ExportOptions.sample.plist](docs/ExportOptions.sample.plist) の `teamID` を `DEVELOPMENT_TEAM` と同じ値にしたもの |
   | `APPLE_API_KEY_BASE64` | App Store Connect の API Key（`.p8`）を base64 エンコードした文字列 |
   | `APPLE_API_KEY_ID` | API Key の Key ID |
   | `APPLE_API_ISSUER_ID` | API Key の Issuer ID |

3. **App Store Connect のアプリ**: Bundle ID `jp.shilokuma.Numer0nLens` のアプリを Web 画面で作成します（API では作れません）。
   アプリが無いまま Upload が走ると、[.github/scripts/check-app-store-app.rb](.github/scripts/check-app-store-app.rb) が「新規アプリ」画面に入力する値を Job Summary に出して止まります

## 構成

```
.
├── Configs/                 # xcconfig（署名情報・バージョン・Deployment Target）
├── Numer0nLens/             # アプリ本体（SwiftUI。Logic/・Model/・Views/）
├── Numer0nLensTests/        # Unit テスト（XCTest）
├── Numer0nLensUITests/      # UI テスト（XCTest）
├── Numer0nLens.xcodeproj    # 共有スキーム Numer0nLens を含む
├── docs/                    # ExportOptions.plist のサンプル
├── .swiftlint.yml           # SwiftLint 設定
└── .github/
    ├── scripts/             # check-app-store-app.rb（App Store Connect のアプリの有無を確認）
    └── workflows/
        ├── _build.yml       # 共通処理: ビルド + テスト + SwiftLint（workflow_call）
        ├── _archive.yml     # 共通処理: Archive → Export（→ Upload）（workflow_call）
        ├── build.yml        # 全ブランチの push / PR
        ├── archive.yml      # main の push
        ├── upload.yml       # develop / release/** の push
        └── close-goal-discussion.yml  # epic の最終 PR のマージでゴール元の Discussion を閉じる
```
