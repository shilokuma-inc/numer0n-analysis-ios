//
//  CallInput.swift
//  Numer0nLens
//

/// コールと回答の入力欄の中身。画面に依存しない形で検証する。
struct CallInput: Equatable {
    /// コールした数字（文字列のまま）。
    var text = ""
    var eat = 0
    var bite = 0

    /// 入力を受け付けられない理由。
    enum Problem: Error, Equatable {
        case number(Numer0nNumberError)
        case result(EatBiteError)

        /// 画面に出す説明。
        func message(for rule: Rule) -> String {
            switch self {
            case let .number(.wrongLength(expected, _)):
                return "\(expected) 桁の数字を入力してください。"
            case let .number(.duplicateDigit(digit)):
                return "同じ数字（\(digit)）は 2 回使えません。"
            case .number(.invalidCharacter), .number(.digitOutOfRange):
                return "数字（0〜9）だけを入力してください。"
            case .result(.negative):
                return "EAT と BITE は 0 以上です。"
            case let .result(.exceedsLength(length)):
                return "EAT と BITE の合計は \(length) 以下です。"
            case .result(.impossibleCombination):
                return "\(rule.length - 1)EAT 1BITE はあり得ません。"
            }
        }
    }

    /// 入力を検証して履歴の 1 件にする。コールが未入力なら `nil`。
    func validate(rule: Rule) -> Result<HistoryEntry, Problem>? {
        guard !text.isEmpty else {
            return nil
        }
        let guess: Numer0nNumber
        do {
            guess = try Numer0nNumber(text, rule: rule)
        } catch let error as Numer0nNumberError {
            return .failure(.number(error))
        } catch {
            preconditionFailure("想定外のエラー: \(error)")
        }
        let result: EatBite
        do {
            result = try EatBite(eat: eat, bite: bite, rule: rule)
        } catch let error as EatBiteError {
            return .failure(.result(error))
        } catch {
            preconditionFailure("想定外のエラー: \(error)")
        }
        return .success(.call(guess: guess, result: result))
    }

    /// 入力欄を空に戻す。
    mutating func clear() {
        self = CallInput()
    }
}
