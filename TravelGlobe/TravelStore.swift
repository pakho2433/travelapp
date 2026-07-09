import Foundation
import Combine

final class TravelStore: ObservableObject {
    @Published var places: [TravelPlace] = [] {
        didSet {
            savePlaces()
        }
    }

    private let storageKey = "travel-globe-places-v1"

    init() {
        loadPlaces()
    }

    func addPlace(_ place: TravelPlace) {
        places.insert(place, at: 0)
    }

    func deletePlace(_ place: TravelPlace) {
        places.removeAll { $0.id == place.id }
    }

    func deletePlaces(at offsets: IndexSet) {
        places.remove(atOffsets: offsets)
    }

    func resetToSamplePlaces() {
        places = Self.samplePlaces
    }

    private func loadPlaces() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            places = Self.samplePlaces
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedPlaces = try decoder.decode([TravelPlace].self, from: data)
            places = decodedPlaces
        } catch {
            print("Failed to load places: \(error)")
            places = Self.samplePlaces
        }
    }

    private func savePlaces() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(places)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save places: \(error)")
        }
    }

    static let samplePlaces: [TravelPlace] = [
        TravelPlace(
            name: "Hong Kong",
            country: "Hong Kong",
            city: "Hong Kong",
            latitude: 22.3193,
            longitude: 114.1694,
            visitDate: Calendar.current.date(from: DateComponents(year: 2025, month: 7, day: 28)) ?? Date(),
            note: "維港夜景、城市步行和美食回憶。"
        ),
        TravelPlace(
            name: "Tokyo",
            country: "Japan",
            city: "Tokyo",
            latitude: 35.6762,
            longitude: 139.6503,
            visitDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 20)) ?? Date(),
            note: "東京街景、咖啡店、拉麵和夜晚燈光。"
        ),
        TravelPlace(
            name: "Taipei",
            country: "Taiwan",
            city: "Taipei",
            latitude: 25.0330,
            longitude: 121.5654,
            visitDate: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 1)) ?? Date(),
            note: "台北 101、夜市和輕鬆旅行日。"
        )
    ]
}
