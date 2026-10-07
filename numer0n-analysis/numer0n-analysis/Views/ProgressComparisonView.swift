//
//  ProgressComparisonView.swift
//  numer0n-analysis
//

import SwiftUI

/// 自分と相手のどちらが先に当てそうかを、残り候補数で並べて見せる。
struct ProgressComparisonView: View {
    let comparison: ProgressComparison

    var body: some View {
        VStack(spacing: 8) {
            Text(headline)
                .font(.headline)
                .foregroundStyle(headlineColor)
            HStack(spacing: 12) {
                side(title: "自分 → 相手の数字", remaining: comparison.myRemaining, bits: comparison.myRemainingBits, solved: comparison.iSolved)
                Divider()
                side(title: "相手 → 自分の数字", remaining: comparison.opponentRemaining, bits: comparison.opponentRemainingBits, solved: comparison.opponentSolved)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private func side(title: String, remaining: Int, bits: Double, solved: Bool) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(solved ? "当てた" : "残り \(remaining.formatted()) 通り")
                .font(.title3.monospacedDigit())
            if !solved {
                Text("あと約 \(bits.formatted(.number.precision(.fractionLength(1)))) bit")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var headline: String {
        switch comparison.status {
        case .iSolved: "自分が先に当てました"
        case .opponentSolved: "相手が先に当てました"
        case .bothSolved: "どちらも当てました"
        case .undetermined: "候補が 0 通りの推理があり、比べられません"
        case .inProgress(.me): "自分のほうが当てるのに近い"
        case .inProgress(.opponent): "相手のほうが当てるのに近い"
        case .inProgress(.even): "互角"
        }
    }

    private var headlineColor: Color {
        switch comparison.status {
        case .iSolved, .inProgress(.me): .green
        case .opponentSolved, .inProgress(.opponent): .orange
        case .bothSolved, .undetermined, .inProgress(.even): .primary
        }
    }
}

#Preview {
    ProgressComparisonView(comparison: ProgressComparison(myRemaining: 12, opponentRemaining: 40))
        .padding()
}
