# TravelGlobe iOS App

Open `TravelGlobe.xcodeproj` in Xcode, select an iPhone or iPad simulator, then press Run.

If you run on a real iPhone or iPad, open Signing & Capabilities and select your Apple Developer Team.

## Features

- SwiftUI + SceneKit 3D globe
- iPhone and iPad responsive layout
- Google Earth style dark-space globe presentation
- Accurate equirectangular Earth sphere geometry
- NASA Blue Marble image loaded as the preferred Earth texture
- Offline procedural Earth texture fallback if the device has no network
- Clouds, atmosphere glow, dark space background and directional sunlight
- Correct latitude / longitude conversion for travel pins
- Drag to rotate and pinch to zoom
- Tap glowing pins to view travel records
- Add places by city name using built-in coordinates
- Delete records
- UserDefaults local persistence

## Notes

The app does not use Google Earth assets or Google Maps APIs. It uses a public NASA Blue Marble texture when online, and automatically falls back to a built-in procedural Earth texture when offline. Pin placement uses real latitude and longitude coordinates.
