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

/// A simplified SwiftUI view for easy Bolt SDK integration
@available(iOS 13.0, macOS 10.15, *)
public struct BoltAdButton: View {
    let adLink: String
    let buttonTitle: String
    let onResult: (OpenAdResult) -> Void
    let buttonStyle: BoltButtonStyle
    let isLoading: Bool
    
    @State private var viewController: UIViewController?
    @State private var isPresenting: Bool = false
    
    public init(
        adLink: String,
        buttonTitle: String = "Open Ad",
        buttonStyle: BoltButtonStyle = .default,
        isLoading: Bool = false,
        onResult: @escaping (OpenAdResult) -> Void = { _ in }
    ) {
        self.adLink = adLink
        self.buttonTitle = buttonTitle
        self.buttonStyle = buttonStyle
        self.isLoading = isLoading
        self.onResult = onResult
    }
    
    public var body: some View {
        buttonStyle.apply(to:
            Button(action: {
                guard let viewController = viewController, !isPresenting else { return }
                isPresenting = true
                boltSDK.gaming.openAd(adLink, in: viewController) { result in
                    isPresenting = false
                    onResult(result)
                }
            }) {
                HStack {
                    if isLoading || isPresenting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(buttonTitle)
                }
            }
            .disabled(viewController == nil || isLoading || isPresenting)
            .accessibilityLabel("Open advertisement")
            .accessibilityHint("Tap to open the advertisement")
            .background(
                BoltViewControllerProvider { vc in
                    viewController = vc
                }
            )
        )
    }
}

/// A simplified SwiftUI view for Bolt checkout integration
@available(iOS 13.0, macOS 10.15, *)
public struct BoltCheckoutButton: View {
    let checkoutLink: String
    let buttonTitle: String
    let buttonStyle: BoltButtonStyle
    let isLoading: Bool
    
    @State private var isPresenting: Bool = false
    
    public init(
        checkoutLink: String,
        buttonTitle: String = "Open Checkout",
        buttonStyle: BoltButtonStyle = .default,
        isLoading: Bool = false
    ) {
        self.checkoutLink = checkoutLink
        self.buttonTitle = buttonTitle
        self.buttonStyle = buttonStyle
        self.isLoading = isLoading
    }
    
    public var body: some View {
        buttonStyle.apply(to:
            Button(action: {
                guard !isPresenting else { return }
                isPresenting = true
                boltSDK.gaming.openCheckout(checkoutLink)
                // Reset presenting state after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPresenting = false
                }
            }) {
                HStack {
                    if isLoading || isPresenting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(buttonTitle)
                }
            }
            .disabled(isLoading || isPresenting)
            .accessibilityLabel("Open checkout")
            .accessibilityHint("Tap to open the payment checkout")
        )
    }
}

/// Custom button styles for Bolt SDK components
@available(iOS 13.0, macOS 10.15, *)
public enum BoltButtonStyle {
    case `default`
    case primary
    case secondary
    
    public func apply(to button: some View) -> AnyView {
        switch self {
        case .default:
            return AnyView(button)
        case .primary:
            return AnyView(
                button
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            )
        case .secondary:
            return AnyView(
                button
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            )
        }
    }
}
#endif

