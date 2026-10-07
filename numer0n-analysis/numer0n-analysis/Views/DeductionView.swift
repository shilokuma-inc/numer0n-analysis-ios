//
//  DeductionView.swift
//  numer0n-analysis
//

import SwiftUI

/// 推理の画面。コールと回答を入力して履歴に足し、履歴と残り候補数を表示する。
struct DeductionView: View {
    let deduction: Deduction
    let role: Role

    /// どちらの推理か。文言と、最善手を出すかが変わる。
    enum Role {
        /// 自分の推理: 自分のコールと相手の回答から、相手の数字を当てる。
        case mine
        /// 相手の推理: 相手のコールと自分の回答から、相手から見た自分の数字の候補を出す。
        case opponent

        var description: String {
            switch self {
            case .mine: "自分のコールと相手の回答から、相手の数字の候補を出します。"
            case .opponent: "相手のコールと自分の回答から、相手から見た自分の数字の候補を出します。相手がどこまで絞れているかの目安になります。"
            }
        }

        var inputTitle: String {
            switch self {
            case .mine: "自分のコールと相手の回答"
            case .opponent: "相手のコールと自分の回答"
            }
        }

        func solvedMessage(length: Int) -> String {
            switch self {
            case .mine: "当たりました（\(length)EAT）"
            case .opponent: "相手に当てられました（\(length)EAT）"
            }
        }

        /// 最善手は自分がコールするときにだけ使う。
        var showsBestMove: Bool {
            self == .mine
        }
    }

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
                Text(role.description)
            }

            if deduction.isSolved {
                Section {
                    Label(role.solvedMessage(length: rule.length), systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                } footer: {
                    Text("続けるときは、右上の「やり直す」から新しいゲームを始めてください。")
                }
            } else {
                inputSection

                if role.showsBestMove {
                    BestMoveSection(deduction: deduction) { guess in
                        input.text = guess.description
                    }
                }
            }

            historySection

            CandidatePreviewSection(candidates: deduction.candidates)
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
            Text(role.inputTitle)
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
    NavigationStack {
        DeductionView(deduction: Deduction(rule: Rule(digitCount: .three)), role: .mine)
    }
}
