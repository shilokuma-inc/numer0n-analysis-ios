//
//  ContentView.swift
//  Numer0nLens
//

import SwiftUI

/// ルートの画面。ゲームが始まっていなければ桁数を選ぶ画面を、始まっていればゲームの画面を出す。
struct ContentView: View {
    @State private var game: GameState?

    var body: some View {
        NavigationStack {
            if let game {
                GameView(game: game) {
                    self.game = nil
                }
            } else {
                StartView { digitCount in
                    game = GameState(digitCount: digitCount)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
