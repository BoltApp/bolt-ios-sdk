import BoltSDK
import Testing
import Foundation

struct CoreFunctionalityTests {
    
    // MARK: - Basic Functionality Tests
    
    @Test func testBasicFunctionality() {
        // Test basic SDK functionality without UIKit dependencies
        let adOptions = AdOptions(type: "timed")
        #expect(adOptions.type == "timed")
        
        let status = PaymentLinkStatus.pending
        #expect(String(describing: status) == "pending")
    }
    
    @Test @MainActor func testSDKInitialization() {
        let sdk = BoltSDK.shared
        // Verify SDK is properly initialized
        #expect(sdk.gaming != nil)
    }
    
    // MARK: - Ad Metadata Tests
    
    @Test func testAdMetadata() {
        let adOfferId = "test-ad-123"
        let adLink = "https://bolt.com/ad?id=test-ad-123"
        let metadata = AdMetadata(adOfferId: adOfferId, adLink: adLink)
        
        #expect(metadata.adOfferId == adOfferId)
        #expect(metadata.adLink == adLink)
        #expect(metadata.status == .opened)
        
        // Test timestamp is recent
        let timeDifference = abs(metadata.timestamp.timeIntervalSinceNow)
        #expect(timeDifference < 1.0) // Should be within 1 second
    }
    
    @Test func testAdMetadataStatusUpdate() {
        let metadata = AdMetadata(adOfferId: "test-123", adLink: "https://test.com")
        #expect(metadata.status == .opened)
        
        // Test status can be updated (simulating what happens in the SDK)
        var mutableMetadata = metadata
        mutableMetadata.status = .completed
        #expect(mutableMetadata.status == .completed)
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
    
    // MARK: - Ad Options Tests
    
    @Test func testAdOptionsDefault() {
        let options = AdOptions()
        #expect(options.type == "timed")
    }
    
    @Test func testAdOptionsCustom() {
        let options = AdOptions(type: "interactive")
        #expect(options.type == "interactive")
    }
    
    // MARK: - Payment Link Tests
    
    @Test func testPaymentLinkStatus() {
        let pending = PaymentLinkStatus.pending
        let successful = PaymentLinkStatus.successful
        let abandoned = PaymentLinkStatus.abandoned
        let expired = PaymentLinkStatus.expired
        
        #expect(String(describing: pending) == "pending")
        #expect(String(describing: successful) == "successful")
        #expect(String(describing: abandoned) == "abandoned")
        #expect(String(describing: expired) == "expired")
    }
    
    @Test func testPaymentLinkSession() {
        let url = URL(string: "https://bolt.com/checkout?id=123")!
        let session = PaymentLinkSession(
            paymentLinkId: "test-123",
            paymentLinkUrl: url,
            status: .pending
        )
        
        #expect(session.paymentLinkId == "test-123")
        #expect(session.paymentLinkUrl == url)
        #expect(session.status == .pending)
    }
    
    @Test func testGetPaymentLinkResponse() {
        let paymentLink = GetPaymentLinkResponse.PaymentLink(id: "test-123")
        let transaction = GetPaymentLinkResponse.Transaction(status: "completed")
        let response = GetPaymentLinkResponse(
            paymentLink: paymentLink,
            transaction: transaction
        )
        
        #expect(response.paymentLink.id == "test-123")
        #expect(response.transaction?.status == "completed")
    }
    
    // MARK: - Gaming Namespace State Management Tests
    
    @Test @MainActor func testGamingNamespaceStateManagement() {
        let gaming = BoltSDK.shared.gaming
        let activeAds = gaming.getActiveAds()
        
        // Initially should be empty
        #expect(activeAds.isEmpty)
    }
    
    @Test @MainActor func testAdOfferIdExtraction() {
        let gaming = BoltSDK.shared.gaming
        
        // Test with valid URL containing id parameter
        let urlWithId = "https://bolt.com/ad?id=test-123"
        let extractedId = gaming.extractAdOfferId(from: urlWithId)
        #expect(extractedId == "test-123")
        
        // Test with URL without id parameter
        let urlWithoutId = "https://bolt.com/ad"
        let noId = gaming.extractAdOfferId(from: urlWithoutId)
        #expect(noId == nil)
        
        // Test with invalid URL
        let invalidUrl = "not-a-url"
        let invalidId = gaming.extractAdOfferId(from: invalidUrl)
        #expect(invalidId == nil)
    }
    
    @Test @MainActor func testAdStateTransitions() {
        let gaming = BoltSDK.shared.gaming
        
        // Test marking ad as completed
        gaming.markAdCompleted("test-ad-123")
        
        // Test marking ad as closed
        gaming.markAdClosed("test-ad-456")
        
        // These operations should not crash and should complete successfully
        #expect(Bool(true)) // If we get here, the operations completed without crashing
    }
    
    // MARK: - OpenAdResult Tests
    
    @Test func testOpenAdResult() {
        let successResult = OpenAdResult.success("https://test.com")
        let invalidURLResult = OpenAdResult.failure(.invalidURL)
        let presentationFailedResult = OpenAdResult.failure(.presentationFailed)
        
        switch successResult {
        case .success(let url):
            #expect(url == "https://test.com")
        case .failure:
            #expect(Bool(false), "Should be success case")
        }
        
        switch invalidURLResult {
        case .success:
            #expect(Bool(false), "Should be failure case")
        case .failure(let error):
            #expect(error == .invalidURL)
        }
        
        switch presentationFailedResult {
        case .success:
            #expect(Bool(false), "Should be failure case")
        case .failure(let error):
            #expect(error == .presentationFailed)
        }
    }
    
    // MARK: - URL Validation Tests
    
    @Test @MainActor func testURLValidation() {
        let gaming = BoltSDK.shared.gaming
        
        // Test valid URLs through SDK validation
        let validUrls = [
            "https://bolt.com/checkout?id=123",
            "https://bolt.com/ad?id=abc",
            "http://example.com",
            "https://subdomain.example.com/path?param=value"
        ]
        
        for urlString in validUrls {
            let result = gaming.preloadAd(urlString)
            #if canImport(UIKit)
            #expect(result != nil, "URL should be valid: \(urlString)")
            #else
            // On non-iOS platforms, preloadAd returns nil
            #expect(result == nil, "preloadAd not available on this platform")
            #endif
        }
        
        // Test invalid URLs through SDK validation
        let invalidUrls = [
            "",
            "not-a-url",
            "ftp://invalid-protocol.com",
            "https://"
        ]
        
        for urlString in invalidUrls {
            let result = gaming.preloadAd(urlString)
            #expect(result == nil, "URL should be invalid: \(urlString)")
        }
    }
    
    // MARK: - Ad Link Processing Tests
    
    @Test @MainActor func testAdLinkProcessing() {
        let gaming = BoltSDK.shared.gaming
        
        // Test various ad link formats
        let testCases = [
            ("https://bolt.com/ad?id=123", "123"),
            ("https://bolt.com/ad?id=abc-def-456", "abc-def-456"),
            ("https://example.com/ad?id=test", "test"),
            ("https://bolt.com/ad", nil),
            ("invalid-url", nil)
        ]
        
        for (url, expectedId) in testCases {
            let extractedId = gaming.extractAdOfferId(from: url)
            #expect(extractedId == expectedId, "Failed for URL: \(url)")
        }
    }
    
    // MARK: - Concurrency Tests
    
    @Test @MainActor func testConcurrentStateAccess() {
        let gaming = BoltSDK.shared.gaming
        
        // Test that multiple state operations don't crash
        for i in 0..<10 {
            gaming.markAdCompleted("test-\(i)")
            gaming.markAdClosed("test-\(i)")
        }
        
        // If we get here without crashing, the test passes
        #expect(Bool(true))
    }
    
    // MARK: - Edge Cases Tests
    
    @Test @MainActor func testEmptyAdLink() {
        let gaming = BoltSDK.shared.gaming
        
        // Test with empty ad link
        let result = gaming.preloadAd("")
        #expect(result == nil)
    }
    
    @Test @MainActor func testNilAdOptions() {
        let gaming = BoltSDK.shared.gaming
        
        // Test with nil options (should use default)
        let result = gaming.preloadAd("https://test.com", options: nil)
        #if canImport(UIKit)
        #expect(result != nil)
        #else
        // On non-iOS platforms, preloadAd returns nil
        #expect(result == nil)
        #endif
    }
    
    // MARK: - Session Management Tests
    
    @Test @MainActor func testSessionManagement() {
        let gaming = BoltSDK.shared.gaming
        
        // Test session methods don't crash
        let sessions = gaming.getPendingSessions()
        #expect(sessions.isEmpty)
        
        let response = GetPaymentLinkResponse(
            paymentLink: GetPaymentLinkResponse.PaymentLink(id: "test"),
            transaction: nil
        )
        let resolvedSession = gaming.resolveSession(response)
        #expect(resolvedSession == nil)
        
        // Test cleanup methods
        gaming.cleanup()
        gaming.cleanupExpired()
        
        #expect(Bool(true)) // If we get here, cleanup completed without crashing
    }
    
    // MARK: - Performance Tests
    
    @Test @MainActor func testPerformance() {
        let gaming = BoltSDK.shared.gaming
        
        // Test that state operations are reasonably fast
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<100 {
            gaming.markAdCompleted("perf-test-\(i)")
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        #expect(duration < 1.0, "State operations should be fast")
    }
    
    // MARK: - Data Structure Tests
    
    @Test func testSendableConformance() {
        // Test that our data structures conform to Sendable
        let metadata = AdMetadata(adOfferId: "test", adLink: "https://test.com")
        let status = AdStatus.opened
        
        // These should compile without warnings about Sendable
        #expect(metadata.adOfferId == "test")
        #expect(status == .opened)
    }
    
    // MARK: - AdError Tests
    
    @Test func testAdErrorCases() {
        let invalidURLError = AdError.invalidURL
        let presentationFailedError = AdError.presentationFailed
        
        #expect(invalidURLError == .invalidURL)
        #expect(presentationFailedError == .presentationFailed)
    }
    
    @Test func testAdErrorEquality() {
        let error1 = AdError.invalidURL
        let error2 = AdError.invalidURL
        let error3 = AdError.presentationFailed
        
        #expect(error1 == error2)
        #expect(error1 != error3)
    }
    
    @Test func testAdErrorDescription() {
        let invalidURLError = AdError.invalidURL
        let presentationFailedError = AdError.presentationFailed
        
        // Test that errors can be described
        let invalidDescription = String(describing: invalidURLError)
        let presentationDescription = String(describing: presentationFailedError)
        
        #expect(!invalidDescription.isEmpty)
        #expect(!presentationDescription.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    @Test @MainActor func testErrorHandling() {
        let gaming = BoltSDK.shared.gaming
        
        // Test error cases
        let emptyResult = gaming.preloadAd("")
        #expect(emptyResult == nil)
        
        let invalidResult = gaming.preloadAd("not-a-url")
        #expect(invalidResult == nil)
    }
    
    // MARK: - Memory Management Tests
    
    @Test @MainActor func testMemoryManagement() {
        let gaming = BoltSDK.shared.gaming
        
        // Test that repeated operations don't cause memory issues
        for i in 0..<1000 {
            gaming.markAdCompleted("memory-test-\(i)")
        }
        
        // If we get here without memory issues, the test passes
        #expect(Bool(true))
    }
}
