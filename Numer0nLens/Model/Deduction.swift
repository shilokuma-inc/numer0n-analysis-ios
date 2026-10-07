//
//  Deduction.swift
//  Numer0nLens
//

import Observation

/// 片方のプレイヤーの推理（コールと回答の履歴と、そこから残る候補）。
@Observable
final class Deduction {
    let rule: Rule
    /// コールと回答の履歴（古い順）。
    private(set) var history: [HistoryEntry] = []
    /// 履歴と矛盾しない候補（昇順）。
    private(set) var candidates: [Numer0nNumber]
    /// 候補が 0 件になった最初の履歴の位置（その入力が前の入力と矛盾している）。矛盾が無ければ `nil`。
    private(set) var contradictionIndex: Int?

    init(rule: Rule) {
        self.rule = rule
        self.candidates = rule.allNumbers()
    }

    /// 候補の件数。
    var candidateCount: Int { candidates.count }

    /// 当たり（EAT = 桁数）の回答が履歴にあるか。
    var isSolved: Bool {
        history.contains { entry in
            switch entry {
            case let .call(_, result):
                return result.isCorrect(for: rule)
            }
        }
    }

    /// 履歴を 1 件足し、候補を絞り込む。桁数がルールと違う履歴は受け付けない。
    func add(_ entry: HistoryEntry) {
        switch entry {
        case let .call(guess, _):
            precondition(guess.length == rule.length, "桁数がルールと違うコール")
        }
        history.append(entry)
        candidates = candidates.narrowed(by: entry)
        if candidates.isEmpty, contradictionIndex == nil {
            contradictionIndex = history.count - 1
        }
    }

    /// 最後の履歴を 1 件取り消し、残りの履歴から候補を計算し直す。履歴が無ければ何もしない。
    func undoLast() {
        guard !history.isEmpty else {
            return
        }
        history.removeLast()
        candidates = rule.candidates(matching: history)
        contradictionIndex = rule.firstContradictionIndex(in: history)
    }

    /// コールと回答を 1 件足す。
    func addCall(guess: Numer0nNumber, result: EatBite) {
        add(.call(guess: guess, result: result))
    }
}
