//
//  BestMoveSection.swift
//  numer0n-analysis
//

import SwiftUI

/// 最善手（情報量の上位）を出すセクション。履歴が変わるたびにバックグラウンドで計算し直す。
struct BestMoveSection: View {
    let deduction: Deduction
    /// 手をタップしたときに呼ぶ（入力欄に入れるため）。
    let onSelect: (Numer0nNumber) -> Void

    /// 表示する上位の件数。
    static let displayCount = 5

    @State private var result: BestMoveSearch.Result?
    @State private var isComputing = false

    var body: some View {
        Section {
            if deduction.candidates.isEmpty {
                Text("候補が無いため、最善手を出せません。")
                    .foregroundStyle(.secondary)
            } else if let result, !isComputing {
                ForEach(Array(result.moves.prefix(Self.displayCount).enumerated()), id: \.element.guess) { rank, move in
                    Button {
                        onSelect(move.guess)
                    } label: {
                        BestMoveRow(rank: rank + 1, move: move)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("計算しています…")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("最善手")
        } footer: {
            Text(footerText)
        }
        // 履歴が増えたら前の計算をキャンセルして計算し直す（`task(id:)` が前の Task をキャンセルする）。
        .task(id: deduction.history.count) {
            await compute()
        }
    }

    private var footerText: String {
        var text = "情報量（bit）が大きい手ほど、回答で候補を細かく分けられます。タップすると入力欄に入ります。"
        if result?.isApproximate == true, !isComputing {
            text += "\n5 桁は手と候補を抜き出して近似しています。"
        }
        return text
    }

    private func compute() async {
        isComputing = true
        let rule = deduction.rule
        let candidates = deduction.candidates
        do {
            let computed = try await BestMoveSearch.search(rule: rule, candidates: candidates)
            result = computed
            isComputing = false
        } catch {
            // キャンセルされた（次の計算が始まる）ときは何もしない。
        }
    }
}

/// 最善手の 1 行。
struct BestMoveRow: View {
    let rank: Int
    let move: MoveEvaluation

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(rank).")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(move.guess.description)
                        .font(.title3.monospacedDigit())
                    if move.isCandidate {
                        Text("当たりの可能性あり")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.2), in: Capsule())
                    }
                }
                Text("最悪 \(move.worstCaseRemaining.formatted()) 通り・平均 \(move.expectedRemaining.formatted(.number.precision(.fractionLength(1)))) 通りに絞れる")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(move.entropy.formatted(.number.precision(.fractionLength(2)))) bit")
                .monospacedDigit()
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
