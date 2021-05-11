import XCTest
import BraintreeTestShared
@testable import BraintreePayPalNative

class BTPayPalNativeClient_Tests: XCTestCase {

    func testTokenize_whenRequestIsNotCheckoutOrVaultSubclass_returnsError() {
        let mockAPIClient = MockAPIClient(authorization: "development_tokenization_key")!
        let payPalNativeClient = BTPayPalNativeClient(apiClient: mockAPIClient)

        let expectation = self.expectation(description: "calls completion with error")
        payPalNativeClient.tokenizePayPalAccountWithPayPalNativeRequest(request: BTPayPalNativeRequest()) { nonce, error in
            XCTAssertNil(nonce)
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
}
