//
//  BestMove.swift
//  numer0n-analysis
//

import Foundation

/// 1 つの手を打ったときの評価。
struct MoveEvaluation: Hashable, Sendable {
    /// 打つ手。
    let guess: Numer0nNumber
    /// 情報量（エントロピー、bit）。並びの基準はこれだけ。
    let entropy: Double
    /// 残り候補の中にある（当たる可能性がある）手か。
    let isCandidate: Bool
    /// 最悪の場合の残り候補数。
    let worstCaseRemaining: Int
    /// 残り候補数の期待値。
    let expectedRemaining: Double
}

enum BestMove {
    /// エントロピーを同点とみなす幅。浮動小数点の誤差で並びが揺れないようにする。
    static let entropyTolerance = 1e-9

    /// 手 `guess` を、残り候補 `candidates` に対して評価する。
    static func evaluate(guess: Numer0nNumber, candidates: [Numer0nNumber], isCandidate: Bool) -> MoveEvaluation {
        let length = guess.length
        var counts = [Int](repeating: 0, count: (length + 1) * (length + 1))
        for candidate in candidates {
            let result = judge(guess: guess, answer: candidate)
            counts[result.eat * (length + 1) + result.bite] += 1
        }
        let total = Double(candidates.count)
        var entropy = 0.0
        var sumOfSquares = 0
        var worst = 0
        for count in counts where count > 0 {
            let p = Double(count) / total
            entropy -= p * log2(p)
            sumOfSquares += count * count
            worst = max(worst, count)
        }
        return MoveEvaluation(
            guess: guess,
            entropy: entropy,
            isCandidate: isCandidate,
            worstCaseRemaining: worst,
            expectedRemaining: total > 0 ? Double(sumOfSquares) / total : 0
        )
    }

    /// 打てる手を評価し、良い順に並べて返す。
    /// 並びは「エントロピーの降順 → 残り候補の中にある手を優先 → 数字の昇順」。
    /// - Parameters:
    ///   - candidates: 残り候補。0 件なら空を、1 件ならその数字だけを返す。
    ///   - guesses: 評価する手。省略するとルールで許されるすべての数字。空なら空を返す。桁数はルールと同じであること。
    static func rankedMoves(
        rule: Rule,
        candidates: [Numer0nNumber],
        guesses: [Numer0nNumber]? = nil
    ) -> [MoveEvaluation] {
        if candidates.isEmpty {
            return []
        }
        if candidates.count == 1 {
            return [evaluate(guess: candidates[0], candidates: candidates, isCandidate: true)]
        }
        let guesses = guesses ?? rule.allNumbers()
        if guesses.isEmpty {
            return []
        }
        precondition(guesses.allSatisfy { $0.length == rule.length }, "打てる手の桁数がルールと違う")
        let candidateSet = Set(candidates)

        let evaluations: [MoveEvaluation]
        if candidates.count == rule.numberCount {
            // 初手（候補 = 全数字）は対称性でどの手も同じ評価になるので、1 手だけ計算して使い回す。
            // 数字の置換と桁の入れ替えで任意の手どうしが移り合うため、`guesses` が全数字の一部でも成り立つ。
            let first = evaluate(guess: guesses[0], candidates: candidates, isCandidate: true)
            evaluations = guesses.map { guess in
                MoveEvaluation(
                    guess: guess,
                    entropy: first.entropy,
                    isCandidate: true,
                    worstCaseRemaining: first.worstCaseRemaining,
                    expectedRemaining: first.expectedRemaining
                )
            }
        } else {
            evaluations = guesses.map { guess in
                evaluate(guess: guess, candidates: candidates, isCandidate: candidateSet.contains(guess))
            }
        }
        return evaluations.sorted(by: isBetter)
    }

    /// `lhs` を `rhs` より前に並べるか。
    static func isBetter(_ lhs: MoveEvaluation, _ rhs: MoveEvaluation) -> Bool {
        if abs(lhs.entropy - rhs.entropy) > entropyTolerance {
            return lhs.entropy > rhs.entropy
        }
        if lhs.isCandidate != rhs.isCandidate {
            return lhs.isCandidate
        }
        return lhs.guess < rhs.guess
    }
}
