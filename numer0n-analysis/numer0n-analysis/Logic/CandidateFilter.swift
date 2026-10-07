//
//  CandidateFilter.swift
//  numer0n-analysis
//

extension Rule {
    /// 履歴のすべてと矛盾しない候補を、昇順で返す。
    func candidates(matching history: [HistoryEntry]) -> [Numer0nNumber] {
        history.reduce(allNumbers()) { candidates, entry in
            candidates.narrowed(by: entry)
        }
    }
}

extension Rule {
    /// 履歴を古い順に当てはめて、候補が 0 件になった最初の位置を返す。0 件にならなければ `nil`。
    /// その位置の入力が、それより前の入力と矛盾している。
    func firstContradictionIndex(in history: [HistoryEntry]) -> Int? {
        var candidates = allNumbers()
        for (index, entry) in history.enumerated() {
            candidates = candidates.narrowed(by: entry)
            if candidates.isEmpty {
                return index
            }
        }
        return nil
    }
}

extension Array where Element == Numer0nNumber {
    /// 履歴が 1 件増えたときに、矛盾しない候補だけを残す。並びは保つ。
    func narrowed(by entry: HistoryEntry) -> [Numer0nNumber] {
        filter { entry.isConsistent(with: $0) }
    }
}
