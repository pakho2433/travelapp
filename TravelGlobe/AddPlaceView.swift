import SwiftUI

struct AddPlaceView: View {
    @ObservedObject var travelStore: TravelStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var country = ""
    @State private var city = ""
    @State private var visitDate = Date()
    @State private var note = ""

    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("例：東京旅行", text: $name)
                    TextField("例：Japan", text: $country)
                    TextField("例：Tokyo", text: $city)
                } header: {
                    Text("基本資料")
                } footer: {
                    Text("城市名稱需要與內置座標表相符，例如 Hong Kong、Tokyo、Taipei。")
                }

                Section {
                    DatePicker("到訪日期", selection: $visitDate, displayedComponents: .date)
                }

                Section("備註") {
                    TextEditor(text: $note)
                        .frame(minHeight: 130)
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
            .navigationTitle("新增地點")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") { savePlace() }
                        .fontWeight(.bold)
                }
            }
            .alert("無法新增地點", isPresented: $showingAlert) {
                Button("知道了", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func savePlace() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            alertMessage = "地點名稱不可空白。"
            showingAlert = true
            return
        }

        guard let coordinate = cityCoordinate(for: cleanCity) else {
            alertMessage = "暫時未有此城市座標，請先加入內置座標表。"
            showingAlert = true
            return
        }

        let newPlace = TravelPlace(
            name: cleanName,
            country: cleanCountry.isEmpty ? cleanCity : cleanCountry,
            city: cleanCity,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            visitDate: visitDate,
            note: cleanNote
        )

        travelStore.addPlace(newPlace)
        dismiss()
    }

    private func cityCoordinate(for city: String) -> (latitude: Double, longitude: Double)? {
        let key = city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let coordinates: [String: (latitude: Double, longitude: Double)] = [
            "hong kong": (22.3193, 114.1694),
            "香港": (22.3193, 114.1694),
            "tokyo": (35.6762, 139.6503),
            "東京": (35.6762, 139.6503),
            "taipei": (25.0330, 121.5654),
            "台北": (25.0330, 121.5654),
            "osaka": (34.6937, 135.5023),
            "大阪": (34.6937, 135.5023),
            "seoul": (37.5665, 126.9780),
            "首爾": (37.5665, 126.9780),
            "bangkok": (13.7563, 100.5018),
            "曼谷": (13.7563, 100.5018),
            "singapore": (1.3521, 103.8198),
            "新加坡": (1.3521, 103.8198),
            "london": (51.5072, -0.1276),
            "倫敦": (51.5072, -0.1276),
            "paris": (48.8566, 2.3522),
            "巴黎": (48.8566, 2.3522),
            "new york": (40.7128, -74.0060),
            "紐約": (40.7128, -74.0060)
        ]

        return coordinates[key]
    }
}
