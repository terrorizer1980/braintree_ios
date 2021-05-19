import XCTest
import BraintreeCore
import BraintreePayPal
import BraintreeTestShared

@testable import BraintreePayPalNative

class BTPayPalNativeClient_Tests: XCTestCase {

    private var mockAPIClient: MockAPIClient!
    private var payPalNativeClient: BTPayPalNativeClient!

    override func setUp() {
        mockAPIClient = MockAPIClient(authorization: "development_tokenization_key")!
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "environment": "sandbox",
            "paypalEnabled": true,
            "paypal": [
                "clientId": "some-client-id"
            ]
        ])

        payPalNativeClient = BTPayPalNativeClient(apiClient: mockAPIClient)
    }

    // MARK: - tokenizePayPalAccount

    func testTokenize_whenRequestIsNotCheckoutOrVaultSubclass_returnsError() {
        let expectation = self.expectation(description: "calls completion with error")
        payPalNativeClient.tokenizePayPalAccount(with: BTPayPalRequest()) { nonce, error in
            XCTAssertNil(nonce)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, "BTPayPalNativeClient failed because request is not of type BTPayPalNativeCheckoutRequest or BTPayPalNativeVaultRequest.")

            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
}
