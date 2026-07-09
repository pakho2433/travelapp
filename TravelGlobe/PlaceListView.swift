import SwiftUI

struct PlaceListView: View {
    @ObservedObject var travelStore: TravelStore
    var onSelectPlace: (TravelPlace) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if travelStore.places.isEmpty {
                    ContentUnavailableView(
                        "未有旅行記錄",
                        systemImage: "mappin.slash",
                        description: Text("新增地點後，這裡會顯示所有去過的地方。")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(travelStore.places) { place in
                        Button {
                            onSelectPlace(place)
                            dismiss()
                        } label: {
                            PlaceRow(place: place)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: travelStore.deletePlaces)
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.03, blue: 0.08),
                        Color(red: 0.03, green: 0.09, blue: 0.17),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("所有地點")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

private struct PlaceRow: View {
    let place: TravelPlace

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 42, height: 42)

                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(place.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(place.city), \(place.country)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(1)

                Text(formattedDate(place.visitDate))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.48))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month(.abbreviated).day())
    }
}
