import SwiftUI

struct PlaceDetailView: View {
    let place: TravelPlace
    var onDelete: (TravelPlace) -> Void
    var onClose: () -> Void = { }

    @State private var showingDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(.white.opacity(0.28))
                .frame(width: 42, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(place.name)
                            .font(.system(size: 25, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)

                        Text("\(place.country) / \(place.city)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.66))
                    }

                    Spacer()

                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }

                HStack(spacing: 10) {
                    InfoChip(icon: "calendar", title: "到訪日期", value: formattedDate(place.visitDate))
                    InfoChip(
                        icon: "location.fill",
                        title: "座標",
                        value: "\(String(format: "%.2f", place.latitude)), \(String(format: "%.2f", place.longitude))"
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("備註")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.cyan.opacity(0.85))
                        .tracking(1)

                    ScrollView {
                        Text(place.note.isEmpty ? "未加入備註。" : place.note)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.82))
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 105)
                }
                .padding(14)
                .background(.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.09), lineWidth: 1)
                }

                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Label("刪除這個旅行記錄", systemImage: "trash")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.red.opacity(0.25), lineWidth: 1)
                        }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .background(.ultraThinMaterial.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.45), radius: 30, x: 0, y: -8)
        .confirmationDialog(
            "確定刪除這個旅行記錄？",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("刪除", role: .destructive) {
                onDelete(place)
            }

            Button("取消", role: .cancel) { }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month(.abbreviated).day())
    }
}

private struct InfoChip: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.cyan)
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.09))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.48))

                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            Spacer(minLength: 0)
        }
        .padding(11)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        }
    }
}
