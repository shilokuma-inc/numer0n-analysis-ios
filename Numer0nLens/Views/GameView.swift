//
//  GameView.swift
//  Numer0nLens
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

            ProgressComparisonView(comparison: ProgressComparison(game: game))
                .padding(.horizontal)
                .padding(.bottom, 8)

            switch side {
            case .mine:
                DeductionView(deduction: game.myDeduction, role: .mine)
                    // やり直したら入力欄も空に戻す。
                    .id(ObjectIdentifier(game.myDeduction))
            case .opponent:
                DeductionView(deduction: game.opponentDeduction, role: .opponent)
                    .id(ObjectIdentifier(game.opponentDeduction))
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

#Preview {
    NavigationStack {
        GameView(game: GameState(digitCount: .four)) {}
    }
}
