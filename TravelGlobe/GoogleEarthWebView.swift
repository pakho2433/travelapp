import SwiftUI
import WebKit

struct GoogleEarthWebView: UIViewRepresentable {
    var focusPlace: TravelPlace?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.bounces = false
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: googleEarthURL(for: focusPlace)))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let newURL = googleEarthURL(for: focusPlace)

        if webView.url?.absoluteString != newURL.absoluteString {
            webView.load(URLRequest(url: newURL))
        }
    }

    private func googleEarthURL(for place: TravelPlace?) -> URL {
        if let place {
            let query = "\(place.latitude),\(place.longitude)"
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""

            return URL(string: "https://earth.google.com/web/search/\(query)") ?? URL(string: "https://earth.google.com/web/")!
        }

        return URL(string: "https://earth.google.com/web/")!
    }
}
