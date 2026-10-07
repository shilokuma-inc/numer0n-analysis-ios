//
//  StartView.swift
//  Numer0nLens
//

import SwiftUI

/// 桁数を選んでゲームを始める画面。
struct StartView: View {
    let onStart: (DigitCount) -> Void

    @State private var digitCount: DigitCount = .three

    var body: some View {
        Form {
            Section {
                Picker("桁数", selection: $digitCount) {
                    ForEach(DigitCount.allCases, id: \.self) { digitCount in
                        Text(digitCount.label).tag(digitCount)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("桁数")
            } footer: {
                Text("0〜9 の数字を重複なしで使います。候補は \(Rule(digitCount: digitCount).numberCount.formatted()) 通りです。")
            }

            Section {
                Button("ゲームを始める") {
                    onStart(digitCount)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("ヌメロン解析")
    }
}

extension DigitCount {
    /// 画面に出す名前（例: "3 桁"）。
    var label: String {
        "\(rawValue) 桁"
    }
}

#Preview {
    NavigationStack {
        StartView { _ in }
    }
}
