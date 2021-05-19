import BraintreeCore
import BraintreePayPal
import PayPalCheckout

@objc public class BTPayPalNativeClient: NSObject {

    // MARK: - Public

    /**
     Domain for PayPal errors.
     */
    // TODO: - is this the right naming convention?
    @objc public static let errorDomain = "com.braintreepayments.BTPayPalNativeClientErrorDomain"

    /**
     Error codes associated with PayPal.
     */
    @objc public enum ErrorType: Int {
        /// Unknown error
        case unknown
        /// PayPal is disabled in configuration
        case disabled
        /// Invalid request, e.g. missing PayPal request
        case invalidRequest
        /// Braintree SDK is integrated incorrectly
        case integration
        /// Payment flow was canceled, typically initiated by the user when exiting early from the flow.
        case canceled
    }

    /**
     Initializes a PayPal client.

     - Parameter apiClient: The Braintree API client

     - Returns: A PayPal client
     */
    @objc(initWithAPIClient:)
    public init(apiClient: BTAPIClient) {
        self.apiClient = apiClient
    }

    /**
     Tokenize a PayPal account for vault or checkout.

     @note You can use this as the final step in your order/checkout flow. If you want, you may create a transaction from your
     server when this method completes without any additional user interaction.

     On success, you will receive an instance of `BTPayPalAccountNonce`; on failure or user cancelation you will receive an error. If the user cancels out of the flow, the error code will be `BTPayPalDriverErrorTypeCanceled`.

     @param request Either a BTPayPalCheckoutRequest or a BTPayPalVaultRequest
     @param completionBlock This completion will be invoked exactly once when tokenization is complete or an error occurs.
    */
    // TODO: - use Error instead of NSError?
    @objc(tokenizePayPalAccountWithPayPalRequest:completion:)
    public func tokenizePayPalAccount(with nativeRequest: BTPayPalRequest, completion: @escaping (BTPayPalNativeAccountNonce?, NSError?) -> Void) {
        guard let request = nativeRequest as? (BTPayPalRequest & BTPayPalNativeRequest) else {
            let error = NSError(domain: BTPayPalNativeClient.errorDomain,
                                code: ErrorType.integration.rawValue,
                                userInfo: [NSLocalizedDescriptionKey: "BTPayPalNativeClient failed because request is not of type BTPayPalNativeCheckoutRequest or BTPayPalNativeVaultRequest."])

            completion(nil, error)
            return
        }

        let orderCreationClient = BTPayPalNativeOrderCreationClient(with: apiClient)
        orderCreationClient.createOrder(with: request) { (order, error) in
            if let err = error {
                completion(nil, err)
                return
            }

            guard let order = order else {
                let missingOrderError = NSError(domain: BTPayPalNativeClient.errorDomain,
                                    code: ErrorType.unknown.rawValue,
                                    userInfo: [NSLocalizedDescriptionKey: "Failed to create a PayPal order."])
                completion(nil, missingOrderError)
                return
            }

            let payPalNativeConfig = PayPalCheckout.CheckoutConfig(clientID: order.payPalClientID,
                                                                   returnUrl: request.payPalReturnURL,
                                                                   createOrder: nil,
                                                                   onApprove: nil,
                                                                   onCancel: nil,
                                                                   onError: nil,
                                                                   environment: order.environment)

            PayPalCheckout.Checkout.set(config: payPalNativeConfig)

            PayPalCheckout.Checkout.start(presentingViewController: nil, createOrder: { action in
                action.set(orderId: order.orderID)
            }, onApprove: { approval in

            }, onCancel: {

            }, onError: { error in

            })
        }
    }

    // MARK: - Private

    private let apiClient: BTAPIClient
}
