import BoltSDK
import Testing

struct BoltSDKTests {
    @Test func testBasicFunctionality() {
        // Test basic SDK functionality without UIKit dependencies
        let adOptions = AdOptions(type: "timed")
        #expect(adOptions.type == "timed")
        
        let status = PaymentLinkStatus.pending
        #expect(String(describing: status) == "pending")
    }
    
    @Test func testAdMetadata() {
        let adOfferId = "test-ad-123"
        let adLink = "https://bolt.com/ad?id=test-ad-123"
        let metadata = AdMetadata(adOfferId: adOfferId, adLink: adLink)
        
        #expect(metadata.adOfferId == adOfferId)
        #expect(metadata.adLink == adLink)
        #expect(metadata.status == .opened)
    }
    
    @Test func testAdStatus() {
        let opened = AdStatus.opened
        let completed = AdStatus.completed
        let closed = AdStatus.closed
        let failed = AdStatus.failed
        
        #expect(String(describing: opened) == "opened")
        #expect(String(describing: completed) == "completed")
        #expect(String(describing: closed) == "closed")
        #expect(String(describing: failed) == "failed")
    }
    
    @Test @MainActor func testGamingNamespaceStateManagement() {
        let gaming = BoltSDK.shared.gaming
        let activeAds = gaming.getActiveAds()
        
        // Initially should be empty
        #expect(activeAds.isEmpty)
    }
}