//
//  CandidateListView.swift
//  numer0n-analysis
//

import SwiftUI

/// 推理の画面に出す、残り候補の先頭いくつか。全件は `CandidateListView` で見る。
struct CandidatePreviewSection: View {
    let candidates: [Numer0nNumber]

    /// 推理の画面にそのまま並べる件数。これより多ければ「すべて見る」から全件の画面に移る。
    static let previewLimit = 30

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: 8)]

    var body: some View {
        Section {
            if candidates.isEmpty {
                Text("候補がありません。")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(candidates.prefix(Self.previewLimit), id: \.self) { candidate in
                        CandidateCell(candidate: candidate)
                    }
                }
                .padding(.vertical, 4)
                if candidates.count > Self.previewLimit {
                    NavigationLink {
                        CandidateListView(candidates: candidates)
                    } label: {
                        Text("すべて見る（\(candidates.count.formatted()) 通り）")
                    }
                }
            }
        } header: {
            Text("残り候補（\(candidates.count.formatted()) 通り）")
        } footer: {
            if candidates.count > Self.previewLimit {
                Text("先頭の \(Self.previewLimit) 通りを小さい順に表示しています。")
            }
        }
    }
}

/// 残り候補の 1 つ。
struct CandidateCell: View {
    let candidate: Numer0nNumber

    var body: some View {
        Text(candidate.description)
            .font(.body.monospacedDigit())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
    }
}

/// 残り候補の全件。数万件でも固まらないよう、表示される行だけを作る `List` で並べる。
struct CandidateListView: View {
    let candidates: [Numer0nNumber]

    @State private var query = ""

    private var filtered: [Numer0nNumber] {
        guard !query.isEmpty else {
            return candidates
        }
        return candidates.filter { $0.description.hasPrefix(query) }
    }

    var body: some View {
        List(filtered, id: \.self) { candidate in
            Text(candidate.description)
                .font(.body.monospacedDigit())
        }
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .searchable(text: $query, prompt: "先頭の数字で絞り込む")
        .navigationTitle("残り候補 \(candidates.count.formatted()) 通り")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        List {
            CandidatePreviewSection(candidates: Rule(digitCount: .three).allNumbers())
        }
    }
}
