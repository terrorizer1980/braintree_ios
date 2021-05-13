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
        payPalNativeClient.tokenizePayPalAccount(with: BTPayPalNativeRequest(payPalReturnURL: "returnURL")) { nonce, error in
            XCTAssertNil(nonce)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, "BTPayPalNativeClient failed because request is not of type BTPayPalNativeCheckoutRequest or BTPayPalNativeVaultRequest.")

            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: - constructNativeSDKRequest

    func testConstructNativeSDKRequest_whenRemoteConfigurationFetchFails_callsBackWithConfigurationError() {
        mockAPIClient.cannedConfigurationResponseBody = nil
        mockAPIClient.cannedConfigurationResponseError = NSError(domain: "", code: 0, userInfo: nil)

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(nativeSDKRequest)
            XCTAssertEqual(error, self.mockAPIClient.cannedConfigurationResponseError)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testConstructNativeSDKRequest_whenConfigurationIsNil_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = nil

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(nativeSDKRequest)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.unknown.rawValue)
            XCTAssertEqual(error.localizedDescription, "Failed to fetch Braintree configuration.")

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testConstructNativeSDKRequest_whenPayPalNotEnabledInConfiguration_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "paypalEnabled": false
        ])

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(nativeSDKRequest)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.disabled.rawValue)
            XCTAssertEqual(error.localizedDescription, "PayPal is not enabled for this merchant")

            XCTAssertTrue(self.mockAPIClient.postedAnalyticsEvents.contains("ios.paypal-otc.preflight.disabled"))
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testConstructNativeSDKRequest_whenPayPalEnabledMissingFromConfiguration_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [])

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(nativeSDKRequest)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.disabled.rawValue)
            XCTAssertEqual(error.localizedDescription, "PayPal is not enabled for this merchant")

            XCTAssertTrue(self.mockAPIClient.postedAnalyticsEvents.contains("ios.paypal-otc.preflight.disabled"))
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testConstructNativeSDKRequest_whenPayPalClientIDMissingFromConfiguration_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "paypalEnabled": true
        ])

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(nativeSDKRequest)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.disabled.rawValue)
            XCTAssertEqual(error.localizedDescription, "Failed to fetch PayPalClientID from Braintree configuration.")

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testConstructNativeSDKRequest_whenEnvironmentMissingFromConfiguration_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "paypalEnabled": true,
            "paypal": [
                "clientId": "some-client-id"
            ]
        ])

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(nativeSDKRequest)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.unknown.rawValue)
            XCTAssertEqual(error.localizedDescription, "PayPal Native Checkout failed because an invalid environment identifier was retrieved from the configuration.")

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testConstructNativeSDKRequest_whenEnvironmentIsNotProdOrSandbox_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "environment": "invalid-environment",
            "paypalEnabled": true,
            "paypal": [
                "clientId": "some-client-id"
            ]
        ])

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(nativeSDKRequest)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.unknown.rawValue)
            XCTAssertEqual(error.localizedDescription, "PayPal Native Checkout failed because an invalid environment identifier was retrieved from the configuration.")

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    // MARK: - constructNativeSDKRequest - POST request to Hermes endpoint

    func testConstructNativeSDKRequest_whenRemoteConfigurationFetchSucceeds_postsToCorrectEndpoint() {
        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        request.intent = .sale

        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (_, _) in }

        XCTAssertEqual("v1/paypal_hermes/create_payment_resource", mockAPIClient.lastPOSTPath)
        guard let lastPostParameters = mockAPIClient.lastPOSTParameters else { XCTFail(); return }

        XCTAssertEqual(lastPostParameters["intent"] as? String, "sale")
        XCTAssertEqual(lastPostParameters["amount"] as? String, "1")
        XCTAssertEqual(lastPostParameters["return_url"] as? String, "sdk.ios.braintree://onetouch/v1/success")
        XCTAssertEqual(lastPostParameters["cancel_url"] as? String, "sdk.ios.braintree://onetouch/v1/cancel")
    }

    func testConstructNativeSDKRequest_whenPaymentResourceCreationFails_callsBackWithError() {
        mockAPIClient.cannedResponseError = NSError(domain: "", code: 0, userInfo: nil)

        let dummyRequest = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")
        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: dummyRequest) { (_, error) -> Void in
            XCTAssertEqual(error! as NSError, self.mockAPIClient.cannedResponseError!)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)
    }

    // MARK: - constructNativeSDKRequest - request

    func testConstructNativeSDKRequest_whenEnvironmentIsProd_returnsRequestWithEnvironment() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "environment": "production",
            "paypalEnabled": true,
            "paypal": [
                "clientId": "some-client-id"
            ]
        ])

        let jsonString =
            """
            {
                "paymentResource": {
                    "redirectUrl": "my-url.com?token=some-token"
                }
            }
            """
        mockAPIClient.cannedResponseBody = BTJSON(data: jsonString.data(using: String.Encoding.utf8)!)

        let expectation = self.expectation(description: "Constructs approvalURL")
        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "12")
        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            XCTAssertNil(error)
            XCTAssertEqual(nativeSDKRequest?.orderID, "some-token")
            XCTAssertEqual(nativeSDKRequest?.payPalClientID, "some-client-id")
            XCTAssertEqual(nativeSDKRequest?.environment, 0)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)
    }

    func testConstructNativeSDKRequest_whenHermesReturnsPaymentResourceURL_returnsRequestWithOrderID() {
        let jsonString =
            """
            {
                "paymentResource": {
                    "redirectUrl": "my-url.com?token=some-token"
                }
            }
            """
        mockAPIClient.cannedResponseBody = BTJSON(data: jsonString.data(using: String.Encoding.utf8)!)

        let expectation = self.expectation(description: "Constructs approvalURL")
        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "12")
        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            XCTAssertNil(error)
            XCTAssertEqual(nativeSDKRequest?.orderID, "some-token")
            XCTAssertEqual(nativeSDKRequest?.payPalClientID, "some-client-id")
            XCTAssertEqual(nativeSDKRequest?.environment, 1)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)
    }

    func testConstructNativeSDKRequest_whenHermesReturnsAgreementSetupURL_returnsRequestWithOrderID() {
        let jsonString =
            """
            {
                "agreementSetup": {
                    "approvalUrl": "my-url.com?ba_token=some-token"
                }
            }
            """
        mockAPIClient.cannedResponseBody = BTJSON(data: jsonString.data(using: String.Encoding.utf8)!)

        let expectation = self.expectation(description: "Constructs approvalURL")
        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "12")
        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            XCTAssertNil(error)
            XCTAssertEqual(nativeSDKRequest?.orderID, "some-token")
            XCTAssertEqual(nativeSDKRequest?.payPalClientID, "some-client-id")
            XCTAssertEqual(nativeSDKRequest?.environment, 1)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)
    }

    func testConstructNativeSDKRequest_whenCannotParseApprovalURL_callsCompletionWithError() {
        let jsonString =
            """
            {
                "fake-values": {
                    "url": "spam.com"
                }
            }
            """
        mockAPIClient.cannedResponseBody = BTJSON(data: jsonString.data(using: String.Encoding.utf8)!)

        let expectation = self.expectation(description: "Constructs approvalURL")
        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "12")
        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            XCTAssertNil(nativeSDKRequest)
            XCTAssertEqual(error?.code, BTPayPalNativeClient.ErrorType.unknown.rawValue)
            XCTAssertEqual(error?.localizedDescription, "Failed to fetch PayPal approvalURL.")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)
    }

    func testConstructNativeSDKRequest_whenApprovalURLDoesNotContainOrderID_callsCompletionWithError() {
        let jsonString =
            """
            {
                "paymentResource": {
                    "redirectUrl": "my-url.com"
                }
            }
            """
        mockAPIClient.cannedResponseBody = BTJSON(data: jsonString.data(using: String.Encoding.utf8)!)

        let expectation = self.expectation(description: "Calls completion with missing order id error")
        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "12")
        payPalNativeClient.constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            XCTAssertNil(nativeSDKRequest)
            XCTAssertEqual(error?.code, BTPayPalNativeClient.ErrorType.unknown.rawValue)
            XCTAssertEqual(error?.localizedDescription, "Failed to fetch PayPal order id.")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)
    }
}
