//
//  ProgressComparison.swift
//  Numer0nLens
//

import Foundation

/// 自分と相手のどちらが先に当てそうかの比較。残り候補数（少ないほど当てるのに近い）で比べる。
struct ProgressComparison: Equatable {
    /// 自分の推理で残っている、相手の数字の候補数。
    let myRemaining: Int
    /// 相手の推理で残っている、相手から見た自分の数字の候補数。
    let opponentRemaining: Int
    /// 自分が当てたか。
    let iSolved: Bool
    /// 相手が当てたか。
    let opponentSolved: Bool

    enum Status: Equatable {
        /// 自分が当てた。
        case iSolved
        /// 相手が当てた。
        case opponentSolved
        /// どちらも当てた。
        case bothSolved
        /// どちらかの候補が 0 件（入力が矛盾している）で比べられない。
        case undetermined
        /// まだ当てていない。どちらが近いか。
        case inProgress(Leader)
    }

    enum Leader: Equatable {
        case me
        case opponent
        case even
    }

    init(myRemaining: Int, opponentRemaining: Int, iSolved: Bool = false, opponentSolved: Bool = false) {
        self.myRemaining = myRemaining
        self.opponentRemaining = opponentRemaining
        self.iSolved = iSolved
        self.opponentSolved = opponentSolved
    }

    init(game: GameState) {
        self.init(
            myRemaining: game.myDeduction.candidateCount,
            opponentRemaining: game.opponentDeduction.candidateCount,
            iSolved: game.myDeduction.isSolved,
            opponentSolved: game.opponentDeduction.isSolved
        )
    }

    var status: Status {
        switch (iSolved, opponentSolved) {
        case (true, true):
            return .bothSolved
        case (true, false):
            return .iSolved
        case (false, true):
            return .opponentSolved
        case (false, false):
            break
        }
        guard myRemaining > 0, opponentRemaining > 0 else {
            return .undetermined
        }
        if myRemaining < opponentRemaining {
            return .inProgress(.me)
        }
        if myRemaining > opponentRemaining {
            return .inProgress(.opponent)
        }
        return .inProgress(.even)
    }

    /// 自分が当てるまでに残っている情報量（bit）。候補が 1 通りなら 0。
    var myRemainingBits: Double {
        Self.bits(for: myRemaining)
    }

    /// 相手が当てるまでに残っている情報量（bit）。
    var opponentRemainingBits: Double {
        Self.bits(for: opponentRemaining)
    }

    static func bits(for count: Int) -> Double {
        count > 0 ? log2(Double(count)) : 0
    }
}
