import SwiftUI

enum EarthDisplayMode: String, CaseIterable, Identifiable {
    case googleEarth = "Google Earth"
    case travelGlobe = "Travel Globe"

    var id: String { rawValue }
}

struct ContentView: View {
    @StateObject private var travelStore = TravelStore()

    @State private var showingAddPlace = false
    @State private var showingPlaceList = false
    @State private var selectedPlace: TravelPlace?
    @State private var earthMode: EarthDisplayMode = .googleEarth

    private var countryCount: Int {
        let countries = travelStore.places
            .map { $0.country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        return Set(countries).count
    }

    var body: some View {
        GeometryReader { geometry in
            let isWideLayout = geometry.size.width >= 820
            let globeHeight = isWideLayout
                ? max(560, min(geometry.size.height * 0.76, 780))
                : max(380, min(geometry.size.height * 0.58, 600))

            ZStack(alignment: .bottom) {
                backgroundView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        headerView

                        if isWideLayout {
                            HStack(alignment: .top, spacing: 18) {
                                globeCard(height: globeHeight)
                                    .frame(maxWidth: .infinity)

                                sideDashboard
                                    .frame(width: min(380, geometry.size.width * 0.35))
                            }
                        } else {
                            VStack(spacing: 16) {
                                globeCard(height: globeHeight)
                                statsView
                                actionButtons
                            }
                        }

                        Color.clear
                            .frame(height: selectedPlace == nil ? 12 : 270)
                    }
                    .padding(.horizontal, isWideLayout ? 30 : 14)
                    .padding(.top, isWideLayout ? 26 : 14)
                    .padding(.bottom, 24)
                    .frame(maxWidth: isWideLayout ? 1280 : 760)
                    .frame(maxWidth: .infinity)
                }

                if let selectedPlace {
                    PlaceDetailView(
                        place: selectedPlace,
                        onDelete: { place in
                            deletePlace(place)
                        },
                        onClose: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                self.selectedPlace = nil
                            }
                        }
                    )
                    .frame(maxWidth: isWideLayout ? 560 : .infinity)
                    .padding(.horizontal, isWideLayout ? 28 : 12)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                }
            }
        }
        .sheet(isPresented: $showingAddPlace) {
            AddPlaceView(travelStore: travelStore)
        }
        .sheet(isPresented: $showingPlaceList) {
            PlaceListView(travelStore: travelStore) { place in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    selectedPlace = place
                    earthMode = .googleEarth
                }
            }
        }
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.015, green: 0.02, blue: 0.06),
                Color(red: 0.03, green: 0.08, blue: 0.16),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            RadialGradient(
                colors: [Color.cyan.opacity(0.24), Color.clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 520
            )
            .ignoresSafeArea()
        }
        .overlay {
            RadialGradient(
                colors: [Color.blue.opacity(0.16), Color.clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 620
            )
            .ignoresSafeArea()
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Google Earth Travel Journal")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.cyan.opacity(0.88))

            Text("我的旅行地球儀")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.78)

            Text("可切換真正 Google Earth Web 或本機 3D 旅行地球儀，iPhone / iPad 都適用。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.70))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
        }
        .padding(.top, 6)
    }

    private func globeCard(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(earthMode == .googleEarth ? "Google Earth 模式" : "本機 3D Travel Globe")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(earthMode == .googleEarth ? "載入 Google Earth Web；點列表地點會跳到該座標。" : "可點擊 App 自己的旅行圖釘，支援離線顯示。")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.60))
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    travelStore.resetToSamplePlaces()
                    selectedPlace = nil
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline)
                        .foregroundStyle(.cyan)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .accessibilityLabel("重設示例地點")
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Picker("Earth Mode", selection: $earthMode) {
                ForEach(EarthDisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            ZStack(alignment: .bottomLeading) {
                if earthMode == .googleEarth {
                    GoogleEarthWebView(focusPlace: selectedPlace)
                        .overlay(alignment: .topLeading) {
                            Text("Google Earth Web")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.black.opacity(0.45))
                                .clipShape(Capsule())
                                .padding(12)
                        }
                } else {
                    GlobeSceneView(travelStore: travelStore) { place in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            selectedPlace = place
                        }
                    }
                }

                if earthMode == .googleEarth {
                    Text("提示：Google Earth Web 需要網絡；若 WKWebView 未能載入，請改用 Travel Globe 模式。")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.78))
                        .padding(10)
                        .background(.black.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(12)
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .background(.ultraThinMaterial.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.40), radius: 28, x: 0, y: 18)
    }

    private var sideDashboard: some View {
        VStack(spacing: 14) {
            statsView
                .layoutPriority(1)

            actionButtons

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("最近地點")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    Button("全部") {
                        showingPlaceList = true
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.cyan)
                }

                ForEach(travelStore.places.prefix(6)) { place in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            selectedPlace = place
                            earthMode = .googleEarth
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(place.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                Text("\(place.city), \(place.country)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.55))
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(11)
                        .background(.white.opacity(selectedPlace?.id == place.id ? 0.14 : 0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
        }
    }

    private var statsView: some View {
        HStack(spacing: 12) {
            StatCard(title: "已去過地方", value: "\(travelStore.places.count)", icon: "mappin.and.ellipse")
            StatCard(title: "國家 / 地區", value: "\(countryCount)", icon: "flag.fill")
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingAddPlace = true
            } label: {
                Label("新增地點", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryGlassButtonStyle())

            Button {
                showingPlaceList = true
            } label: {
                Label("列表", systemImage: "list.bullet")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryGlassButtonStyle())
        }
    }

    private func deletePlace(_ place: TravelPlace) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            travelStore.deletePlace(place)
            if selectedPlace?.id == place.id {
                selectedPlace = nil
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.cyan)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.ultraThinMaterial.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct PrimaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color(red: 0.02, green: 0.08, blue: 0.13))
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [.cyan, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .shadow(color: .cyan.opacity(0.18), radius: 16, x: 0, y: 10)
    }
}

private struct SecondaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .background(.ultraThinMaterial.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
