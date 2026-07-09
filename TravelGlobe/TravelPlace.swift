import Foundation

struct TravelPlace: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var country: String
    var city: String
    var latitude: Double
    var longitude: Double
    var visitDate: Date
    var note: String

    init(
        id: UUID = UUID(),
        name: String,
        country: String,
        city: String,
        latitude: Double,
        longitude: Double,
        visitDate: Date,
        note: String
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.visitDate = visitDate
        self.note = note
    }
}
