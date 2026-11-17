//
//  ContentView.swift
//  RiverFishing
//
//  3D 강가 씬을 배경으로 깔고, 현재 시간대/낚시 상태/도감 버튼/획득 토스트를 얹은 HUD.
//

import Foundation
import SwiftUI

struct ContentView: View {

    @StateObject private var timeOfDay = TimeOfDayService()
    @StateObject private var engine = FishingEngine()

    @State private var showDex = false

    var body: some View {
        ZStack {
            RiverSceneView(
                mood: timeOfDay.mood,
                phase: engine.phase,
                catchToken: engine.catchToken
            )
            .ignoresSafeArea()

            // 화면 아무 곳이나 탭하면 챔질
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    engine.strike()
                }

            LinearGradient(
                colors: [Color.black.opacity(0.55), .clear, .clear, Color.black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                header
                Spacer(minLength: 0)
                controlPanel
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 10)

            toastLayer
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: engine.toast?.id)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showDex) {
            FishDexView(book: engine.book) {
                engine.resetBook()
            }
        }
        .onAppear {
            engine.attach(timeOfDay: timeOfDay)
            timeOfDay.start()
            engine.start()
        }
        .onDisappear {
            engine.stop()
        }
    }

    // MARK: - 상단

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Image(systemName: timeOfDay.band.symbolName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(timeOfDay.band.accent)
                    Text(timeOfDay.band.displayName)
                        .font(.system(size: 14, weight: .bold))
                    Text(timeOfDay.clockText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                    if timeOfDay.isPreviewing {
                        Text("미리보기")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.18)))
                    }
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.black.opacity(0.32)))
                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.8))

                Text(timeOfDay.band.moodLine)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .padding(.leading, 5)
                    .shadow(color: .black.opacity(0.6), radius: 3, y: 1)
            }

            Spacer(minLength: 6)

            collectionBadge
        }
    }

    private var collectionBadge: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("도감 \(engine.caughtSpeciesCount)/\(engine.speciesCount)")
                .font(.system(size: 12, weight: .semibold))
            Text("오늘 \(engine.sessionCatches)마리")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.65))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.32)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.14), lineWidth: 0.8))
    }

    // MARK: - 하단 패널

    private var controlPanel: some View {
        VStack(spacing: 10) {
            statusCard

            HStack(spacing: 9) {
                secondaryButton(title: "도감", systemImage: "book.closed.fill") {
                    showDex = true
                }
                strikeButton
                autoButton
            }

            previewBar
        }
    }

    private var statusCard: some View {
        VStack(spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: engine.phase.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(statusColor)
                Text(engine.phase.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                Spacer(minLength: 4)
                if let notice = engine.notice {
                    Text(notice)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .lineLimit(1)
                }
            }

            if engine.phase == .biting {
                biteBar
            } else {
                HStack(spacing: 6) {
                    Text(engine.statusText)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.34)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.13), lineWidth: 0.8))
    }

    private var biteBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.16))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.00, green: 0.76, blue: 0.32),
                                Color(red: 1.00, green: 0.36, blue: 0.22)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, proxy.size.width * CGFloat(engine.biteProgress)))
            }
        }
        .frame(height: 8)
    }

    private var strikeButton: some View {
        Button {
            engine.strike()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: engine.phase == .biting ? "hand.point.up.left.fill" : "figure.fishing")
                    .font(.system(size: 15, weight: .bold))
                Text(engine.phase == .biting ? "지금 낚아채기" : "낚아채기")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(engine.phase == .biting ? Color(red: 1.00, green: 0.42, blue: 0.24) : Color.white.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
            )
            .scaleEffect(engine.phase == .biting ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: engine.phase)
        }
        .buttonStyle(.plain)
    }

    private var autoButton: some View {
        Button {
            engine.isAutoFishing.toggle()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: engine.isAutoFishing ? "arrow.triangle.2.circlepath" : "hand.tap.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text(engine.isAutoFishing ? "자동" : "수동")
                    .font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundStyle(engine.isAutoFishing ? Color(red: 0.55, green: 0.86, blue: 0.72) : Color.white)
            .frame(width: 62)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.34)))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        engine.isAutoFishing
                            ? Color(red: 0.55, green: 0.86, blue: 0.72).opacity(0.5)
                            : Color.white.opacity(0.14),
                        lineWidth: 0.8
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundStyle(Color.white)
            .frame(width: 62)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.34)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.14), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    /// 테스트/미리보기용 시간대 전환.
    private var previewBar: some View {
        HStack(spacing: 6) {
            Text("시간대")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.45))

            ForEach(TimeBand.allCases) { band in
                Button {
                    timeOfDay.togglePreview(band)
                } label: {
                    Text(band.displayName)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(timeOfDay.forcedBand == band ? Color.black.opacity(0.85) : Color.white.opacity(0.75))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(timeOfDay.forcedBand == band ? band.accent : Color.white.opacity(0.10))
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
    }

    // MARK: - 획득 토스트

    @ViewBuilder
    private var toastLayer: some View {
        if let result = engine.toast {
            VStack {
                catchToast(result)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 112)
            .allowsHitTesting(false)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func catchToast(_ result: CatchResult) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(result.fish.rarity.tint.opacity(0.22))
                Image(systemName: "fish.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(result.fish.rarity.tint)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(result.fish.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text(result.fish.rarity.displayName)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(result.fish.rarity.tint)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(result.fish.rarity.tint.opacity(0.16)))
                }
                Text("\(result.lengthText) · \(result.badgeText)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.white.opacity(0.72))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.55)))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(result.fish.rarity.tint.opacity(0.45), lineWidth: 1)
        )
    }

    // MARK: - 색

    private var statusColor: Color {
        switch engine.phase {
        case .biting:
            return Color(red: 1.00, green: 0.55, blue: 0.25)
        case .caught:
            return Color(red: 0.55, green: 0.88, blue: 0.72)
        case .missed:
            return Color(red: 0.95, green: 0.55, blue: 0.55)
        default:
            return Color.white.opacity(0.55)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
