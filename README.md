# リポジトリ名
numer0n-analysis-ios

## 概要
ヌメロン解析アプリ
選択と相手の回答から可能性のパターンを提示する
最善手を提示する機能も作成予定

## 使用技術
- SwiftUI（`@main` の `App` から起動。Storyboard は使わない）
- Observation（`@Observable` で状態を管理）
- XCTest（判定・候補の絞り込み・最善手のロジックを単体テスト）
- 最低 iOS 17.0。外部ライブラリ・サーバーは使わない（オフラインで完結）
