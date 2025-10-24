import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
/// A helper view controller that bridges SwiftUI with UIKit for Bolt SDK integration
@MainActor
public class BoltViewControllerHelper: UIViewController {
    
    /// Callback when the view controller is ready to present content
    public var onViewControllerReady: ((UIViewController) -> Void)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        onViewControllerReady?(self)
    }
    
    public override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent != nil {
            onViewControllerReady?(self)
        }
    }
}

/// A SwiftUI view that provides a UIViewController for Bolt SDK integration
public struct BoltViewControllerProvider: UIViewControllerRepresentable {
    let onViewControllerReady: (UIViewController) -> Void
    
    public init(onViewControllerReady: @escaping (UIViewController) -> Void) {
        self.onViewControllerReady = onViewControllerReady
    }
    
    public func makeUIViewController(context: Context) -> BoltViewControllerHelper {
        let helper = BoltViewControllerHelper()
        helper.onViewControllerReady = onViewControllerReady
        return helper
    }
    
    public func updateUIViewController(_ uiViewController: BoltViewControllerHelper, context: Context) {
        // No updates needed - the helper manages its own lifecycle
    }
}
#endif

#if canImport(UIKit)
/// A simplified SwiftUI view for easy Bolt SDK integration
@available(iOS 13.0, macOS 10.15, *)
public struct BoltAdButton: View {
    let adLink: String
    let buttonTitle: String
    let onResult: (OpenAdResult) -> Void
    
    @State private var viewController: UIViewController?
    
    public init(
        adLink: String,
        buttonTitle: String = "Open Ad",
        onResult: @escaping (OpenAdResult) -> Void = { _ in }
    ) {
        self.adLink = adLink
        self.buttonTitle = buttonTitle
        self.onResult = onResult
    }
    
    public var body: some View {
        Button(buttonTitle) {
            guard let viewController = viewController else { return }
            boltSDK.gaming.openAd(adLink, in: viewController, completion: onResult)
        }
        .disabled(viewController == nil)
        .background(
            BoltViewControllerProvider { vc in
                viewController = vc
            }
        )
    }
}
#endif

#if canImport(UIKit)
/// A simplified SwiftUI view for Bolt checkout integration
@available(iOS 13.0, macOS 10.15, *)
public struct BoltCheckoutButton: View {
    let checkoutLink: String
    let buttonTitle: String
    
    public init(
        checkoutLink: String,
        buttonTitle: String = "Open Checkout"
    ) {
        self.checkoutLink = checkoutLink
        self.buttonTitle = buttonTitle
    }
    
    public var body: some View {
        Button(buttonTitle) {
            boltSDK.gaming.openCheckout(checkoutLink)
        }
    }
}
#endif
