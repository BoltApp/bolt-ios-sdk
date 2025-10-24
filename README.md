# Bolt IOS SDK

<!-- Todo add an image -->

## What is this?

Native IOS support support for Bolt Web Payments. A programmatic way to for out-of-app purchases, interactive ads, and subscriptions.

We also support other platforms:

<table>
  <tr>
    <td align="center" width="150">
      <img src="https://upload.wikimedia.org/wikipedia/commons/6/6a/JavaScript-logo.png" width="60" height="60" alt="JavaScript"/><br>
      <div>
      <b>JavaScript</b><br>
      <a href="https://github.com/BoltApp/bolt-frontend-sdk">Javascript SDK</a>
      </div>
    </td>
    <td align="center" width="150">
      <img src="https://cdn.sanity.io/images/fuvbjjlp/production/bd6440647fa19b1863cd025fa45f8dad98d33181-2000x2000.png" width="60" height="60" alt="Unity"/><br>
      <b>Unity</b><br>
      <a href="https://github.com/BoltApp/bolt-unity-sdk">Unity SDK</a>
    </td>
    <td align="center" width="150">
      <img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRUf3R8LFTgqC_8mooGEx7Fpas9kHu8OUxhLA&s" width="60" height="60" alt="Unreal"/><br>
      <b>Unreal Engine</b><br>
      <a href="https://github.com/BoltApp/bolt-unreal-engine-sdk">Unreal SDK</a>
    </td>
  </tr>
  <tr>
    <td align="center" width="150">
      <img src="https://developer.apple.com/assets/elements/icons/swift/swift-64x64.png" width="60" height="60" alt="iOS"/><br>
      <b>iOS</b><br>
      <i>This Repo</i>
    </td>
    <td align="center" width="150">
      <img src="https://avatars.githubusercontent.com/u/32689599?s=200&v=4" width="60" height="60" alt="Android"/><br>
      <b>Android</b><br>
      Coming Soon 🚧
    </td>
    <td align="center" width="150">
      <!-- filler -->
    </td>
  </tr>
</table>

<br>

<div align="center">

[![Discord](https://img.shields.io/badge/Discord-Have%20A%20Request%3F-7289DA?style=for-the-badge&logo=discord&logoColor=white&logoWidth=60)](https://discord.gg/BSUp9qjtnc)

### Chat with us on Discord for help and inquiries!

</div>

## 📚 Documentation

For documentation and API reference visit our [quick start guide](https://bolt-gaming-docs.vercel.app/guide/checkout-quickstart.html).

## 💰 Why Bolt

Only with Bolt you get **2.1% + $0.30 on all transactions**. That's 10x better than traditional app stores which take 30% of your revenue! That's the fair and transparent pricing you get with using Bolt.

<p style="font-size:12px;font-style:italic;opacity:85%">
<strong>Disclaimer:</strong> Fees are subject to change but will continue to remain highly competitive. See <a href="https://www.bolt.com/pricing">bolt.com/pricing</a> for up to date rates and visit  <a href="https://www.bolt.com/end-user-terms">bolt.com/end-user-terms</a> for end user terms and conditions.
</p>

## 🛠️ Prerequisites

You need 3 things to get started:

1. **Existing IOS App:** You will need an ios application that supports SVM (Swift Version Manager)
2. **Backend Server:** You will need to bring your own backend server (any language)
3. **Bolt Merchant Account:** Dashboard access to manage your gaming store ([signup](https://merchant.bolt.com/onboarding/get-started/gaming) or [login](https://merchant.bolt.com/))

## 📦 Installation

### Step 1: Install the IOS SDK

Add the Bolt iOS SDK to your project using Swift Package Manager:

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/BoltApp/bolt-ios-sdk`
3. Click **Add Package**
4. Select **BoltSDK** and click **Add Package**

Alternatively, you can add it directly to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/BoltApp/bolt-ios-sdk", from: "1.0.0")
]
```

### Step 2: Add code to your app

Import the SDK in your Swift files:

```swift
import BoltSDK
```

Then use the SDK in your app:

```swift
// Links in this sample are examples. You will need to follow our quickstart guide on how to fetch URLs from the API.

// For checkout functionality
boltSDK.gaming.openCheckout("https://bolt.com/checkout?id=123")

// For ad functionality
boltSDK.gaming.openAd("https://bolt.com/ad?id=abc", in: self) { result in
    switch result {
    case .success(let link):
        print("Ad opened: \(link)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

For SwiftUI integration, see the examples in Step 4 below.

### Step 3: Continue with Backend Integration

You will need to bring your own backend server to complete integration.

- [**Quick Start**](https://bolt-gaming-docs.vercel.app/guide/checkout-quickstart.html): View our quickstart guide to get the API running
- [**Example Server**](https://github.com/BoltApp/bolt-gameserver-sample): We also have a sample server in NodeJS for your reference during implementation

### Step 4: Example Usage

#### UIKit Integration
```swift
// Example usage. For real URLs you will need to use our api. See our quickstart above.
boltSDK.gaming.openCheckout("https://bolt.com/checkout?id=123")

boltSDK.gaming.openAd("https://bolt.com/ad?id=abc", in: self) { result in
    switch result {
    case .success(let link):
        print("Ad opened: \(link)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

#### SwiftUI Integration

For SwiftUI apps, use our helper components for a simple:

```swift
import SwiftUI
import BoltSDK

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Bolt SDK Demo")
                .font(.title)
            
            // Simple checkout button for testing
            // Replace button with your own and grab link from the API
            BoltCheckoutButton(
                checkoutLink: "https://bolt.com/checkout?id=123",
                buttonTitle: "Buy Now"
            )
            
            // Simple ad button for testing
            // Replace button with your own and grab link from the API
            BoltAdButton(
                adLink: "https://bolt.com/ad?id=123",
                buttonTitle: "Watch Ad"
            ) { result in
                switch result {
                case .success(let link):
                    print("Ad completed: \(link)")
                case .failure(let error):
                    print("Ad failed: \(error)")
                }
            }
        }
        .padding()
    }
}
```

#### Manual SwiftUI Integration

If you need more control, you can manually integrate with the helper:

```swift
import SwiftUI
import BoltSDK
import UIKit

struct ContentView: View {
    @State private var viewController: UIViewController?

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Press me") {
                guard let viewController else { return }
                boltSDK.gaming.openAd("https://sandbox.gcom.toffeepay.com/love.com/offer_01k5y8wdbk5b390mmwdz5ja7cd", in: viewController) { result in
                    print("Webview closed")
                }
            }
        }
        .padding()
        .background(
            BoltViewControllerProvider { vc in
                viewController = vc
            }
        )
    }
}
```


## Need help?

<div class="discord-link">
    Got questions, roadmap suggestions, or requesting new SDKs?
    <br>
    <a href="https://discord.gg/BSUp9qjtnc" 
    target="_blank" class="discord-link-anchor">
      <span class="discord-text mr-2">Get help and chat with 
      us about anything on Discord</span>
      <span class="discord-icon-wrapper">
        <img src="https://cdn.prod.website-files.com/6257adef93867e50d84d30e2/66e3d80db9971f10a9757c99_Symbol.svg"
        alt="Discord" class="discord-icon" 
        width="16px">
      </span>
    </a>
  </div>

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
