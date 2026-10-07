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

extension Array where Element == Numer0nNumber {
    /// 履歴が 1 件増えたときに、矛盾しない候補だけを残す。並びは保つ。
    func narrowed(by entry: HistoryEntry) -> [Numer0nNumber] {
        filter { entry.isConsistent(with: $0) }
    }
}
