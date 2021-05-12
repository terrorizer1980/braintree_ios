import XCTest
import BraintreeCore
import BraintreeTestShared
@testable import BraintreePayPalNative

class BTPayPalNativeClient_Tests: XCTestCase {

    private var mockAPIClient: MockAPIClient!
    private var payPalNativeClient: BTPayPalNativeClient!

    override func setUp() {
        mockAPIClient = MockAPIClient(authorization: "development_tokenization_key")!
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "paypalEnabled": true,
            "paypal": [
                "environment": "offline"
            ]
        ])

        payPalNativeClient = BTPayPalNativeClient(apiClient: mockAPIClient)
    }

    func testTokenize_whenRequestIsNotCheckoutOrVaultSubclass_returnsError() {
        let expectation = self.expectation(description: "calls completion with error")
        payPalNativeClient.tokenizePayPalAccount(with: BTPayPalNativeRequest()) { nonce, error in
            XCTAssertNil(nonce)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, "BTPayPalNativeClient failed because request is not of type BTPayPalNativeCheckoutRequest or BTPayPalNativeVaultRequest.")

            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testTokenizePayPalAccount_whenRemoteConfigurationFetchFails_callsBackWithConfigurationError() {
        mockAPIClient.cannedConfigurationResponseBody = nil
        mockAPIClient.cannedConfigurationResponseError = NSError(domain: "", code: 0, userInfo: nil)

        let request = BTPayPalNativeCheckoutRequest(amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        payPalNativeClient.tokenizePayPalAccount(with: request) { (nonce, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(nonce)
            XCTAssertEqual(error, self.mockAPIClient.cannedConfigurationResponseError)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testTokenizePayPalAccount_whenPayPalNotEnabledInConfiguration_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "paypalEnabled": false
        ])

        let request = BTPayPalNativeCheckoutRequest(amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        payPalNativeClient.tokenizePayPalAccount(with: request) { (nonce, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(nonce)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.disabled.rawValue)
            XCTAssertEqual(error.localizedDescription, "PayPal is not enabled for this merchant")

            XCTAssertTrue(self.mockAPIClient.postedAnalyticsEvents.contains("ios.paypal-otc.preflight.disabled"))
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    // MARK: - POST request to Hermes endpoint

    func testPayPalAccount_whenRemoteConfigurationFetchSucceeds_postsToCorrectEndpoint() {
        let request = BTPayPalNativeCheckoutRequest(amount: "1")
        request.intent = .sale

        payPalNativeClient.tokenizePayPalAccount(with: request) { _,_  -> Void in }

        XCTAssertEqual("v1/paypal_hermes/create_payment_resource", mockAPIClient.lastPOSTPath)
        guard let lastPostParameters = mockAPIClient.lastPOSTParameters else { XCTFail(); return }

        XCTAssertEqual(lastPostParameters["intent"] as? String, "sale")
        XCTAssertEqual(lastPostParameters["amount"] as? String, "1")
        XCTAssertEqual(lastPostParameters["return_url"] as? String, "sdk.ios.braintree://onetouch/v1/success")
        XCTAssertEqual(lastPostParameters["cancel_url"] as? String, "sdk.ios.braintree://onetouch/v1/cancel")
    }

    func testTokenizePayPalAccount_whenPaymentResourceCreationFails_callsBackWithError() {
        mockAPIClient.cannedResponseError = NSError(domain: "", code: 0, userInfo: nil)

        let dummyRequest = BTPayPalNativeCheckoutRequest(amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")
        payPalNativeClient.tokenizePayPalAccount(with: dummyRequest) { (_, error) -> Void in
            XCTAssertEqual(error! as NSError, self.mockAPIClient.cannedResponseError!)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)
    }
}
