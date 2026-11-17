//
//  FishDexView.swift
//  RiverFishing
//
//  물고기 도감 시트. 수집률, 미발견 실루엣, 잡은 횟수·최대 길이를 보여준다.
//

import Foundation
import SwiftUI

struct FishDexView: View {

    let book: FishBook
    var onReset: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    /// 전설 → 희귀 → 조금 희귀 → 흔함 순으로 정렬.
    private var species: [Fish] {
        FishCatalog.all.sorted { lhs, rhs in
            if lhs.rarity.sortIndex == rhs.rarity.sortIndex {
                return lhs.minLengthCM > rhs.minLengthCM
            }
            return lhs.rarity.sortIndex > rhs.rarity.sortIndex
        }
    }

    private var progress: Double {
        guard FishCatalog.speciesCount > 0 else { return 0 }
        return Double(book.caughtSpeciesCount) / Double(FishCatalog.speciesCount)
    }

    private var legendaryCount: Int {
        FishCatalog.all.filter { $0.rarity == .legendary && book.hasCaught($0.id) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    summaryCard

                    ForEach(species) { fish in
                        row(for: fish)
                    }

                    Text("기록은 이 기기의 UserDefaults에 저장됩니다.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .scrollIndicators(.hidden)
            .background(background)
            .navigationTitle("물고기 도감")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("기록 초기화", role: .destructive) {
                            confirmReset = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .alert("도감을 초기화할까요?", isPresented: $confirmReset) {
                Button("취소", role: .cancel) {}
                Button("초기화", role: .destructive) {
                    onReset()
                }
            } message: {
                Text("지금까지 잡은 모든 기록이 사라집니다. 되돌릴 수 없어요.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - 배경

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.09, blue: 0.14),
                Color(red: 0.03, green: 0.04, blue: 0.07)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - 요약

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("수집률")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.6))
                Spacer(minLength: 8)
                Text("\(book.caughtSpeciesCount) / \(FishCatalog.speciesCount) 종")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.78, blue: 0.95),
                                    Color(red: 0.62, green: 0.92, blue: 0.75)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, proxy.size.width * CGFloat(progress)))
                }
            }
            .frame(height: 9)

            HStack(spacing: 18) {
                statItem(title: "총 낚은 수", value: "\(book.totalCatches)마리")
                statItem(title: "최대 길이", value: String(format: "%.1fcm", book.longestLengthCM))
                statItem(
                    title: "전설",
                    value: "\(legendaryCount)/\(FishCatalog.speciesCount(rarity: .legendary))"
                )
                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.45))
            Text(value)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.9))
        }
    }

    // MARK: - 어종 한 줄

    private func row(for fish: Fish) -> some View {
        let record = book.record(for: fish.id)
        let caught = record != nil

        return HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(caught ? fish.rarity.tint.opacity(0.16) : Color.white.opacity(0.05))
                Image(systemName: "fish.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(caught ? fish.rarity.tint : Color.white.opacity(0.14))
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(caught ? fish.name : "???")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(caught ? Color.white : Color.white.opacity(0.45))
                    if caught {
                        Text(fish.rarity.displayName)
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(fish.rarity.tint)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(fish.rarity.tint.opacity(0.16)))
                    }
                }

                if caught {
                    Text(fish.summary)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineLimit(2)
                } else {
                    Text("아직 만나지 못한 물고기 · \(fish.bandText)에 출현")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 4)

            if let record {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(record.catchCount)마리")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                    Text(String(format: "최대 %.1fcm", record.longestLengthCM))
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
            }
        }
        .padding(13)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

struct FishDexView_Previews: PreviewProvider {
    static var previews: some View {
        var book = FishBook()
        book.register(fishID: "crucian-carp", lengthCM: 24.3, at: Date())
        book.register(fishID: "crucian-carp", lengthCM: 28.9, at: Date())
        book.register(fishID: "catfish", lengthCM: 41.2, at: Date())
        return FishDexView(book: book)
    }
}
