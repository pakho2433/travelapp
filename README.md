# TravelGlobe iOS App

Open `TravelGlobe.xcodeproj` in Xcode, select an iPhone or iPad simulator, then press Run.

If you run on a real iPhone or iPad, open Signing & Capabilities and select your Apple Developer Team.

## Features

- SwiftUI + SceneKit native iOS app
- iPhone and iPad responsive layout
- Default Google Earth mode using `WKWebView` to load Google Earth Web
- Selecting a saved place opens that coordinate in Google Earth Web search
- Local Travel Globe fallback using SceneKit 3D Earth
- Accurate equirectangular Earth sphere geometry for local fallback
- NASA Blue Marble image loaded as preferred local Earth texture
- Offline procedural Earth texture fallback if the device has no network
- Clouds, atmosphere glow, dark space background and directional sunlight
- Correct latitude / longitude conversion for travel pins in local mode
- Drag to rotate and pinch to zoom
- Tap local glowing pins to view travel records
- Add places by city name using built-in coordinates
- Delete records
- UserDefaults local persistence

## Important notes

This project now includes a true Google Earth Web mode. Google Earth itself is loaded through `WKWebView` because Google does not provide a native SceneKit Google Earth model that can be copied into an iOS app. The local 3D globe remains available as a fallback travel-pin view.
