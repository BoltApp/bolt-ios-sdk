import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(WebKit)
import WebKit
#endif

#if canImport(SafariServices)
import SafariServices
#endif

// MARK: - Core SDK Entry
@MainActor
public class BoltSDK: Sendable {
    public static let shared = BoltSDK()
    public let gaming = GamingNamespace()
    private init() {}
}

// MARK: - Payment Models
public enum PaymentLinkStatus: Sendable {
    case pending, successful, abandoned, expired
}

public struct PaymentLinkSession: Sendable {
    public let paymentLinkId: String
    public let paymentLinkUrl: URL
    public var status: PaymentLinkStatus

    public init(paymentLinkId: String, paymentLinkUrl: URL, status: PaymentLinkStatus) {
        self.paymentLinkId = paymentLinkId
        self.paymentLinkUrl = paymentLinkUrl
        self.status = status
    }
}

public struct GetPaymentLinkResponse: Sendable {
    public let paymentLink: PaymentLink
    public let transaction: Transaction?

    public struct PaymentLink: Sendable { public let id: String }
    public struct Transaction: Sendable { public let status: String }
}


// MARK: - Ad Models
public struct AdOptions: Sendable {
    public var type: String
    public var useSafariViewController: Bool

    public init(type: String = "timed", useSafariViewController: Bool = false) {
        self.type = type
        self.useSafariViewController = useSafariViewController
    }
}

public enum AdError: Error, Sendable {
    case invalidURL
    case presentationFailed
}

public enum OpenAdResult: Sendable {
    case success(String)
    case failure(AdError)
}

public enum AdStatus: String, Codable, Sendable {
    case opened, completed, closed, failed
}

public struct AdMetadata: Sendable, Codable {
    public let adOfferId: String
    public let adLink: String
    public let timestamp: Date
    public var status: AdStatus

    public init(adOfferId: String, adLink: String) {
        self.adOfferId = adOfferId
        self.adLink = adLink
        self.timestamp = Date()
        self.status = .opened
    }
}

// MARK: - Gaming Namespace
public class GamingNamespace: @unchecked Sendable {
    private var activeAds: [String: AdMetadata] = [:]
    private let queue = DispatchQueue(label: "com.bolt.gaming", attributes: .concurrent)

    // MARK: - Checkout (only works on iOS)
    #if canImport(UIKit)
    @MainActor
    public func openCheckout(_ checkoutLink: String) {
        guard let url = URL(string: checkoutLink),
              ["https"].contains(url.scheme?.lowercased() ?? "") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    #else
    public func openCheckout(_ checkoutLink: String) {
        // No-op for non-iOS builds
        print("openCheckout is only available on iOS.")
    }
    #endif

    // MARK: - Ads
    #if canImport(UIKit)
    @MainActor
    public func preloadAd(_ adLink: String, options: AdOptions? = nil) -> PreloadedAd? {
        guard !adLink.isEmpty else { return nil }
        return WebviewAd(url: adLink, options: options)
    }

    @MainActor
    public func openAd(
        _ adLink: String,
        options: AdOptions? = nil,
        in vc: UIViewController,
        completion: @escaping (OpenAdResult) -> Void
    ) {
        guard let url = URL(string: adLink), !adLink.isEmpty else {
            completion(.failure(.invalidURL))
            return
        }

        let adOfferId = extractAdOfferId(from: adLink) ?? UUID().uuidString
        let metadata = AdMetadata(adOfferId: adOfferId, adLink: adLink)

        queue.async(flags: .barrier) { self.activeAds[adOfferId] = metadata }

        if (options?.useSafariViewController ?? false) {
            if let safariAd = SafariAd(url: adLink, adOfferId: adOfferId, options: options) {
                safariAd.completion = completion
                safariAd.show(in: vc)
            } else {
                completion(.failure(.presentationFailed))
            }
        } else {
            let webAd = WebviewAd(url: adLink, options: options)
            webAd.completion = completion
            webAd.show(in: vc)
        }
    }
    #else
    public func preloadAd(_ adLink: String, options: AdOptions? = nil) -> Any? {
        print("preloadAd is only available on iOS.")
        return nil
    }
    public func openAd(_ adLink: String, options: AdOptions? = nil, in _: Any?, completion: @escaping (OpenAdResult) -> Void) {
        completion(.failure(.presentationFailed))
    }
    #endif

    // MARK: - Ad Tracking
    public func extractAdOfferId(from url: String) -> String? {
        guard let url = URL(string: url),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }
        return queryItems.first { $0.name == "id" }?.value
    }

    public func getActiveAds() -> [AdMetadata] {
        queue.sync { Array(activeAds.values) }
    }

    public func markAdCompleted(_ adOfferId: String) {
        queue.async(flags: .barrier) {
            guard var ad = self.activeAds[adOfferId] else { return }
            ad.status = .completed
            self.activeAds[adOfferId] = ad
        }
    }

    public func markAdClosed(_ adOfferId: String) {
        queue.async(flags: .barrier) {
            guard var ad = self.activeAds[adOfferId] else { return }
            ad.status = .closed
            self.activeAds[adOfferId] = ad
        }
    }

    // MARK: - Payment Placeholders
    public func getPendingSessions() -> [PaymentLinkSession] { [] }
    public func resolveSession(_ response: GetPaymentLinkResponse) -> PaymentLinkSession? { nil }
    public func cleanup() {}
    public func cleanupExpired() {}
}

// MARK: - iOS-only Implementations
#if canImport(UIKit)
@MainActor
public protocol PreloadedAd {
    func show(in viewController: UIViewController)
}

@MainActor
private class SafariAd: NSObject, PreloadedAd, SFSafariViewControllerDelegate {
    private let url: String
    private let adOfferId: String
    private let options: AdOptions?
    var completion: ((OpenAdResult) -> Void)?

    init?(url: String, adOfferId: String, options: AdOptions?) {
        guard URL(string: url) != nil else { return nil }
        self.url = url
        self.adOfferId = adOfferId
        self.options = options
        super.init()
    }

    func show(in viewController: UIViewController) {
        guard let adURL = URL(string: url) else {
            completion?(.failure(.invalidURL))
            return
        }

        let safariVC = SFSafariViewController(url: adURL)
        safariVC.delegate = self
        safariVC.modalPresentationStyle = .fullScreen
        viewController.present(safariVC, animated: true) {
            self.completion?(.success(self.url))
        }
    }

    nonisolated func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        BoltSDK.shared.gaming.markAdClosed(adOfferId)
        completion?(.failure(.presentationFailed))
    }
}

@MainActor
private class WebviewAd: NSObject, PreloadedAd, WKNavigationDelegate, WKScriptMessageHandler {
    private let url: String
    private let options: AdOptions?
    private weak var presentedViewController: UIViewController?
    private var webView: WKWebView?
    var completion: ((OpenAdResult) -> Void)?

    init(url: String, options: AdOptions?) {
        self.url = url
        self.options = options
        super.init()
    }

    func show(in viewController: UIViewController) {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "boltAdHandler")
        config.userContentController = userContentController

        let webView = WKWebView(frame: viewController.view.bounds, configuration: config)
        webView.navigationDelegate = self
        self.webView = webView

        let webVC = UIViewController()
        webVC.view = webView
        webVC.title = "Ad"

        let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeAd))
        webVC.navigationItem.rightBarButtonItem = closeButton

        let navController = UINavigationController(rootViewController: webVC)
        navController.modalPresentationStyle = .fullScreen
        presentedViewController = navController

        viewController.present(navController, animated: true) {
            self.completion?(.success(self.url))
        }

        if let adURL = URL(string: url) {
            webView.load(URLRequest(url: adURL))
        } else {
            completion?(.failure(.invalidURL))
        }
    }

    @objc private func closeAd() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "boltAdHandler")
        webView?.stopLoading()
        presentedViewController?.dismiss(animated: true) {
            self.completion?(.failure(.presentationFailed))
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Ad finished loading: \(url)")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        completion?(.failure(.presentationFailed))
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "boltAdHandler" else { return }
        if let messageDict = message.body as? [String: Any],
           let action = messageDict["action"] as? String,
           action == "close" {
            closeAd()
        }
    }
}
#endif

