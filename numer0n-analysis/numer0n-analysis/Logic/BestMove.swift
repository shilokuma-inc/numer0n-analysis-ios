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

/// 判定を速くするための、数字のビット表現。最善手の計算では判定を数千万回行うため、配列を比べずにビット演算で数える。
struct PackedNumber: Hashable, Sendable {
    /// 桁と数字の組（`1 << (桁 * 10 + 数字)`）。EAT を数えるのに使う。
    let positions: UInt64
    /// 使っている数字（`1 << 数字`）。共通する数字を数えるのに使う。
    let digitSet: UInt16

    init(_ number: Numer0nNumber) {
        var positions: UInt64 = 0
        var digitSet: UInt16 = 0
        for (index, digit) in number.digits.enumerated() {
            positions |= 1 << UInt64(index * 10 + digit)
            digitSet |= 1 << UInt16(digit)
        }
        self.positions = positions
        self.digitSet = digitSet
    }

    /// `judge(guess:answer:)` と同じ結果を返す。桁数が同じ前提。
    func judge(answer: PackedNumber) -> (eat: Int, bite: Int) {
        let eat = (positions & answer.positions).nonzeroBitCount
        let common = (digitSet & answer.digitSet).nonzeroBitCount
        return (eat, common - eat)
    }
}

enum BestMove {
    /// エントロピーを同点とみなす幅。浮動小数点の誤差で並びが揺れないようにする。
    static let entropyTolerance = 1e-9

    /// 手 `guess` を、残り候補 `candidates` に対して評価する。
    static func evaluate(guess: Numer0nNumber, candidates: [Numer0nNumber], isCandidate: Bool) -> MoveEvaluation {
        evaluate(guess: guess, packedCandidates: candidates.map(PackedNumber.init), isCandidate: isCandidate)
    }

    /// 手 `guess` を、ビット表現にした残り候補に対して評価する。手ごとに候補を変換し直さないための版。
    static func evaluate(guess: Numer0nNumber, packedCandidates: [PackedNumber], isCandidate: Bool) -> MoveEvaluation {
        let length = guess.length
        let packedGuess = PackedNumber(guess)
        var counts = [Int](repeating: 0, count: (length + 1) * (length + 1))
        counts.withUnsafeMutableBufferPointer { counts in
            packedCandidates.withUnsafeBufferPointer { candidates in
                for candidate in candidates {
                    let (eat, bite) = packedGuess.judge(answer: candidate)
                    counts[eat * (length + 1) + bite] += 1
                }
            }
        }
        let total = Double(packedCandidates.count)
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
            let packedCandidates = candidates.map(PackedNumber.init)
            evaluations = guesses.map { guess in
                evaluate(guess: guess, packedCandidates: packedCandidates, isCandidate: candidateSet.contains(guess))
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
