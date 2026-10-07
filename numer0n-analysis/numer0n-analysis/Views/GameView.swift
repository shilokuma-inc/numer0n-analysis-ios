//
//  GameView.swift
//  numer0n-analysis
//

import SwiftUI

/// ゲーム中の画面。自分の推理と相手の推理を切り替えて見る。
struct GameView: View {
    let game: GameState
    /// 桁数を選び直すとき（スタート画面に戻るとき）に呼ぶ。
    let onChooseDigitCount: () -> Void

    @State private var side: Side = .mine
    @State private var isConfirmingRestart = false

    enum Side: Hashable, CaseIterable {
        case mine
        case opponent

        var title: String {
            switch self {
            case .mine: "自分の推理"
            case .opponent: "相手の推理"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("推理", selection: $side) {
                ForEach(Side.allCases, id: \.self) { side in
                    Text(side.title).tag(side)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            switch side {
            case .mine:
                DeductionSummaryView(
                    deduction: game.myDeduction,
                    description: "自分のコールと相手の回答から、相手の数字の候補を出します。"
                )
            case .opponent:
                DeductionSummaryView(
                    deduction: game.opponentDeduction,
                    description: "相手のコールと自分の回答から、相手から見た自分の数字の候補を出します。"
                )
            }
        }
        .navigationTitle("\(game.digitCount.label)のゲーム")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("やり直す") {
                    Button("同じ桁数でやり直す") {
                        isConfirmingRestart = true
                    }
                    Button("桁数を選び直す") {
                        onChooseDigitCount()
                    }
                }
            }
        }
        .confirmationDialog("履歴を消してやり直しますか？", isPresented: $isConfirmingRestart, titleVisibility: .visible) {
            Button("やり直す", role: .destructive) {
                game.restart()
                side = .mine
            }
        }
    }
}

/// 推理の概要（候補の件数と履歴の件数）。入力・一覧は後続の画面で足す。
struct DeductionSummaryView: View {
    let deduction: Deduction
    let description: String

    var body: some View {
        List {
            Section {
                LabeledContent("残り候補", value: "\(deduction.candidateCount.formatted()) 通り")
                LabeledContent("履歴", value: "\(deduction.history.count) 件")
            } footer: {
                Text(description)
            }
        }
    }
}

#Preview {
    NavigationStack {
        GameView(game: GameState(digitCount: .four)) {}
    }
}
