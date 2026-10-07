//
//  BestMoveSearch.swift
//  Numer0nLens
//

/// 種を固定できる乱数（SplitMix64）。近似の結果をテストで決定的にするために使う。
struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}

/// 最善手を、メインスレッドを止めずに（キャンセル可能に）計算する。
enum BestMoveSearch {
    /// 近似で計算するときのサンプリングの設定。
    struct SamplingOptions: Hashable, Sendable {
        /// ルールで許されるすべての数字から抜き出す手の数。
        var guessSampleCount: Int
        /// 残り候補から、手として追加で抜き出す数（当たる可能性がある手を必ず混ぜるため）。
        var candidateGuessSampleCount: Int
        /// 評価に使う残り候補の数。これより多ければ抜き出した候補で評価する。
        var candidateSampleCount: Int
        /// 乱数の種。
        var seed: UInt64

        static let standard = SamplingOptions(
            guessSampleCount: 5_000,
            candidateGuessSampleCount: 1_000,
            candidateSampleCount: 4_000,
            seed: 0x5EED
        )
    }

    enum Strategy: Hashable, Sendable {
        /// 打てる手すべてを、残り候補すべてに対して評価する。
        case exhaustive
        /// 手と候補を抜き出して評価する。
        case sampled(SamplingOptions)
    }

    struct Result: Hashable, Sendable {
        /// 良い順に並べた手。近似のときは、最悪・期待値の残り候補数を全体の件数に換算している。
        let moves: [MoveEvaluation]
        /// 近似で計算したか。
        let isApproximate: Bool
        /// 評価した手の数。
        let evaluatedGuessCount: Int
        /// 評価に使った残り候補の数。
        let evaluatedCandidateCount: Int
    }

    /// 桁数ごとの既定の計算方法。3・4 桁は全探索、5 桁は近似。
    static func defaultStrategy(for rule: Rule) -> Strategy {
        switch rule.digitCount {
        case .three, .four:
            return .exhaustive
        case .five:
            return .sampled(.standard)
        }
    }

    /// バックグラウンドで計算する。呼び出し元の Task をキャンセルすると、計算も途中で止まり `CancellationError` を投げる。
    static func search(
        rule: Rule,
        candidates: [Numer0nNumber],
        strategy: Strategy? = nil
    ) async throws -> Result {
        let strategy = strategy ?? defaultStrategy(for: rule)
        let task = Task.detached(priority: .userInitiated) {
            try compute(rule: rule, candidates: candidates, strategy: strategy)
        }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    /// 計算の本体。手を評価する合間にキャンセルを確かめる。
    static func compute(
        rule: Rule,
        candidates: [Numer0nNumber],
        strategy: Strategy
    ) throws -> Result {
        // 候補 0・1 件と初手（候補 = 全数字）は、全探索でもすぐ終わる。
        if candidates.count <= 1 || candidates.count == rule.numberCount {
            let moves = BestMove.rankedMoves(rule: rule, candidates: candidates)
            return Result(
                moves: moves,
                isApproximate: false,
                evaluatedGuessCount: moves.count,
                evaluatedCandidateCount: candidates.count
            )
        }

        let allNumbers = rule.allNumbers()
        let (guesses, evaluatedCandidates) = selectTargets(
            allNumbers: allNumbers,
            candidates: candidates,
            strategy: strategy
        )

        let candidateSet = Set(candidates)
        let packedCandidates = evaluatedCandidates.map(PackedNumber.init)
        let scale = Double(candidates.count) / Double(evaluatedCandidates.count)
        var moves: [MoveEvaluation] = []
        moves.reserveCapacity(guesses.count)
        for (index, guess) in guesses.enumerated() {
            if index.isMultiple(of: 64) {
                try Task.checkCancellation()
            }
            let evaluation = BestMove.evaluate(
                guess: guess,
                packedCandidates: packedCandidates,
                isCandidate: candidateSet.contains(guess)
            )
            if scale == 1 {
                moves.append(evaluation)
            } else {
                moves.append(MoveEvaluation(
                    guess: evaluation.guess,
                    entropy: evaluation.entropy,
                    isCandidate: evaluation.isCandidate,
                    worstCaseRemaining: Int((Double(evaluation.worstCaseRemaining) * scale).rounded()),
                    expectedRemaining: evaluation.expectedRemaining * scale
                ))
            }
        }
        try Task.checkCancellation()
        moves.sort(by: BestMove.isBetter)
        return Result(
            moves: moves,
            isApproximate: evaluatedCandidates.count < candidates.count || guesses.count < allNumbers.count,
            evaluatedGuessCount: guesses.count,
            evaluatedCandidateCount: evaluatedCandidates.count
        )
    }

    /// 評価する手と、評価に使う候補を `strategy` に従って選ぶ。
    static func selectTargets(
        allNumbers: [Numer0nNumber],
        candidates: [Numer0nNumber],
        strategy: Strategy
    ) -> (guesses: [Numer0nNumber], evaluatedCandidates: [Numer0nNumber]) {
        switch strategy {
        case .exhaustive:
            return (allNumbers, candidates)
        case let .sampled(options):
            var generator = SeededRandomNumberGenerator(seed: options.seed)
            let sampledGuesses = sample(allNumbers, count: options.guessSampleCount, using: &generator)
            let candidateGuesses = sample(candidates, count: options.candidateGuessSampleCount, using: &generator)
            let guesses = Array(Set(sampledGuesses).union(candidateGuesses))
            let evaluatedCandidates = sample(candidates, count: options.candidateSampleCount, using: &generator)
            return (guesses, evaluatedCandidates)
        }
    }

    /// `elements` から重複なしで `count` 件を抜き出す（部分的な Fisher–Yates）。件数が足りなければ全件を返す。
    static func sample<T>(_ elements: [T], count: Int, using generator: inout SeededRandomNumberGenerator) -> [T] {
        guard count < elements.count else {
            return elements
        }
        var pool = elements
        for index in 0..<count {
            let other = Int.random(in: index..<pool.count, using: &generator)
            pool.swapAt(index, other)
        }
        return Array(pool.prefix(count))
    }
}
