//
//  GameState.swift
//  numer0n-analysis
//

import Observation

/// 1 回のゲームの状態。自分の推理と相手の推理を並行して持つ。
@Observable
final class GameState {
    /// 今のゲームのルール（桁数）。
    private(set) var rule: Rule
    /// 自分の推理: 自分のコールと相手の回答から、相手の数字の候補を出す。
    private(set) var myDeduction: Deduction
    /// 相手の推理: 相手のコールと自分の回答から、相手から見た自分の数字の候補を出す。
    private(set) var opponentDeduction: Deduction

    init(digitCount: DigitCount = .three) {
        let rule = Rule(digitCount: digitCount)
        self.rule = rule
        self.myDeduction = Deduction(rule: rule)
        self.opponentDeduction = Deduction(rule: rule)
    }

    var digitCount: DigitCount { rule.digitCount }

    /// 桁数を選び直して、両方の推理を最初からやり直す。
    func restart(digitCount: DigitCount) {
        let rule = Rule(digitCount: digitCount)
        self.rule = rule
        myDeduction = Deduction(rule: rule)
        opponentDeduction = Deduction(rule: rule)
    }

    /// 同じ桁数で最初からやり直す。
    func restart() {
        restart(digitCount: digitCount)
    }
}
