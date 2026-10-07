//
//  DeductionView.swift
//  numer0n-analysis
//

import SwiftUI

/// 推理の画面。コールと回答を入力して履歴に足し、履歴と残り候補数を表示する。
struct DeductionView: View {
    let deduction: Deduction
    let description: String
    /// 入力欄の見出し（例: 「自分のコール」）。
    let inputTitle: String

    @State private var input = CallInput()
    @FocusState private var isNumberFieldFocused: Bool

    private var rule: Rule { deduction.rule }

    private var validation: Result<HistoryEntry, CallInput.Problem>? {
        input.validate(rule: rule)
    }

    var body: some View {
        List {
            Section {
                LabeledContent("残り候補", value: "\(deduction.candidateCount.formatted()) 通り")
            } footer: {
                Text(description)
            }

            if deduction.isSolved {
                Section {
                    Label("当たりました（\(rule.length)EAT）", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                } footer: {
                    Text("続けるときは、右上の「やり直す」から新しいゲームを始めてください。")
                }
            } else {
                inputSection
            }

            historySection
        }
    }

    private var inputSection: some View {
        Section {
            TextField("\(rule.length) 桁の数字", text: $input.text)
                .keyboardType(.numberPad)
                .font(.title2.monospacedDigit())
                .focused($isNumberFieldFocused)
            resultPicker(title: "EAT", selection: $input.eat)
            resultPicker(title: "BITE", selection: $input.bite)
            if case let .failure(problem) = validation {
                Text(problem.message(for: rule))
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            Button("履歴に追加", action: add)
                .disabled(!canAdd)
        } header: {
            Text(inputTitle)
        }
    }

    private func resultPicker(title: String, selection: Binding<Int>) -> some View {
        LabeledContent(title) {
            Picker(title, selection: selection) {
                ForEach(0...rule.length, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var historySection: some View {
        Section {
            if deduction.history.isEmpty {
                Text("まだ履歴はありません。")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(deduction.history.enumerated()), id: \.offset) { index, entry in
                    HistoryRow(number: index + 1, entry: entry)
                }
            }
        } header: {
            Text("履歴")
        }
    }

    private var canAdd: Bool {
        if case .success = validation {
            return true
        }
        return false
    }

    private func add() {
        guard case let .success(entry) = validation else {
            return
        }
        deduction.add(entry)
        input.clear()
        isNumberFieldFocused = !deduction.isSolved
    }
}

/// 履歴の 1 行。
struct HistoryRow: View {
    let number: Int
    let entry: HistoryEntry

    var body: some View {
        switch entry {
        case let .call(guess, result):
            HStack {
                Text("\(number).")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text(guess.description)
                    .font(.body.monospacedDigit())
                Spacer()
                Text(result.description)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview {
    DeductionView(
        deduction: Deduction(rule: Rule(digitCount: .three)),
        description: "自分のコールと相手の回答から、相手の数字の候補を出します。",
        inputTitle: "自分のコールと相手の回答"
    )
}
