import XCTest
import BraintreeCore
import BraintreeTestShared
@testable import BraintreePayPalNative

class BTPayPalNativeOrderCreationClient_Tests: XCTestCase {

    private var mockAPIClient: MockAPIClient!
    private var orderCreationClient: BTPayPalNativeOrderCreationClient!

    override func setUp() {
        mockAPIClient = MockAPIClient(authorization: "development_tokenization_key")!
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "environment": "sandbox",
            "paypalEnabled": true,
            "paypal": [
                "clientId": "some-client-id"
            ]
        ])

        orderCreationClient = BTPayPalNativeOrderCreationClient(with: mockAPIClient)
    }

    // MARK: - fetch configuration

    func testCreateOrder_whenRemoteConfigurationFetchFails_callsBackWithConfigurationError() {
        mockAPIClient.cannedConfigurationResponseBody = nil
        mockAPIClient.cannedConfigurationResponseError = NSError(domain: "", code: 0, userInfo: nil)

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        orderCreationClient.createOrder(with: request) { (order, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(order)
            XCTAssertEqual(error, self.mockAPIClient.cannedConfigurationResponseError)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testCreateOrder_whenConfigurationIsNil_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = nil

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        orderCreationClient.createOrder(with: request) { (order, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(order)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.unknown.rawValue)
            XCTAssertEqual(error.localizedDescription, "Failed to fetch Braintree configuration.")

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testCreateOrder_whenPayPalNotEnabledInConfiguration_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "paypalEnabled": false
        ])

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        orderCreationClient.createOrder(with: request) { (order, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(order)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.disabled.rawValue)
            XCTAssertEqual(error.localizedDescription, "PayPal is not enabled for this merchant")

            XCTAssertTrue(self.mockAPIClient.postedAnalyticsEvents.contains("ios.paypal-otc.preflight.disabled"))
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testCreateOrder_whenPayPalEnabledMissingFromConfiguration_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [])

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        orderCreationClient.createOrder(with: request) { (order, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(order)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.disabled.rawValue)
            XCTAssertEqual(error.localizedDescription, "PayPal is not enabled for this merchant")

            XCTAssertTrue(self.mockAPIClient.postedAnalyticsEvents.contains("ios.paypal-otc.preflight.disabled"))
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testCreateOrder_whenPayPalClientIDMissingFromConfiguration_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "paypalEnabled": true
        ])

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        orderCreationClient.createOrder(with: request) { (order, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(order)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.disabled.rawValue)
            XCTAssertEqual(error.localizedDescription, "Failed to fetch PayPalClientID from Braintree configuration.")

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testCreateOrder_whenEnvironmentMissingFromConfiguration_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "paypalEnabled": true,
            "paypal": [
                "clientId": "some-client-id"
            ]
        ])

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        orderCreationClient.createOrder(with: request) { (order, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(order)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.unknown.rawValue)
            XCTAssertEqual(error.localizedDescription, "PayPal Native Checkout failed because an invalid environment identifier was retrieved from the configuration.")

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testCreateOrder_whenEnvironmentIsNotProdOrSandbox_callsBackWithError() {
        mockAPIClient.cannedConfigurationResponseBody = BTJSON(value: [
            "environment": "invalid-environment",
            "paypalEnabled": true,
            "paypal": [
                "clientId": "some-client-id"
            ]
        ])

        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")

        orderCreationClient.createOrder(with: request) { (order, error) in
            guard let error = error as NSError? else { XCTFail(); return }
            XCTAssertNil(order)
            XCTAssertEqual(error.domain, BTPayPalNativeClient.errorDomain)
            XCTAssertEqual(error.code, BTPayPalNativeClient.ErrorType.unknown.rawValue)
            XCTAssertEqual(error.localizedDescription, "PayPal Native Checkout failed because an invalid environment identifier was retrieved from the configuration.")

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    // MARK: - POST to Hermes

    func testCreateOrder_whenRemoteConfigurationFetchSucceeds_postsToHermesEndpoint() {
        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        request.intent = .sale

        orderCreationClient.createOrder(with: request) { (_, _) in }

        XCTAssertEqual("v1/paypal_hermes/create_payment_resource", mockAPIClient.lastPOSTPath)
        guard let lastPostParameters = mockAPIClient.lastPOSTParameters else { XCTFail(); return }

        XCTAssertEqual(lastPostParameters["intent"] as? String, "sale")
        XCTAssertEqual(lastPostParameters["amount"] as? String, "1")
        XCTAssertEqual(lastPostParameters["return_url"] as? String, "sdk.ios.braintree://onetouch/v1/success")
        XCTAssertEqual(lastPostParameters["cancel_url"] as? String, "sdk.ios.braintree://onetouch/v1/cancel")
    }

    func testCreateOrder_whenPostToHermesFails_callsBackWithError() {
        mockAPIClient.cannedResponseError = NSError(domain: "", code: 0, userInfo: nil)

        let dummyRequest = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")
        orderCreationClient.createOrder(with: dummyRequest) { (_, error) -> Void in
            XCTAssertEqual(error! as NSError, self.mockAPIClient.cannedResponseError!)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)
    }

    func testCreateOrder_whenHermesRespondsWithoutOrderID_callsBackWithError() {
        let jsonString =
            """
            { "unexpected": "response" }
            """
        mockAPIClient.cannedResponseBody = BTJSON(data: jsonString.data(using: .utf8)!)

        let dummyRequest = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "1")
        let expectation = self.expectation(description: "Checkout fails with error")
        orderCreationClient.createOrder(with: dummyRequest) { (_, error) -> Void in
            XCTAssertEqual(error?.localizedDescription, "Failed to create PayPal order.")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)
    }

    func testCreateOrder_whenEnvironmentIsSand_returnsOrderWithEnvironment() {
        let jsonString =
            """
            {
                "paymentResource": {
                    "redirectUrl": "my-url.com?token=some-token"
                }
            }
            """
        mockAPIClient.cannedResponseBody = BTJSON(data: jsonString.data(using: .utf8)!)

        let expectation = self.expectation(description: "Constructs approvalURL")
        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "12")
        orderCreationClient.createOrder(with: request) { (order, error) in
            XCTAssertNil(error)
            XCTAssertEqual(order?.orderID, "some-token")
            XCTAssertEqual(order?.payPalClientID, "some-client-id")
            XCTAssertEqual(order?.environment, .sandbox)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)
    }

    func testCreateOrder_whenEnvironmentIsProd_returnsOrderWithEnvironment() {
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
        mockAPIClient.cannedResponseBody = BTJSON(data: jsonString.data(using: .utf8)!)

        let expectation = self.expectation(description: "Constructs approvalURL")
        let request = BTPayPalNativeCheckoutRequest(payPalReturnURL: "returnURL", amount: "12")
        orderCreationClient.createOrder(with: request) { (order, error) in
            XCTAssertNil(error)
            XCTAssertEqual(order?.orderID, "some-token")
            XCTAssertEqual(order?.payPalClientID, "some-client-id")
            XCTAssertEqual(order?.environment, .live)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)
    }
}
