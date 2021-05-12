import BraintreeCore

@objc public class BTPayPalNativeClient: NSObject {

    let apiClient: BTAPIClient

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
    @objc public init(apiClient: BTAPIClient) {
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
    public func tokenizePayPalAccount(with request: BTPayPalNativeRequest, completion: @escaping (BTPayPalNativeAccountNonce?, NSError?) -> Void) {
        guard request is BTPayPalNativeCheckoutRequest || request is BTPayPalNativeVaultRequest else {
            let error = NSError(domain: BTPayPalNativeClient.errorDomain,
                                code: ErrorType.integration.rawValue,
                                userInfo: [NSLocalizedDescriptionKey: "BTPayPalNativeClient failed because request is not of type BTPayPalNativeCheckoutRequest or BTPayPalNativeVaultRequest."])

            completion(nil, error)
            return
        }

        apiClient.fetchOrReturnRemoteConfiguration { configuration, error in
            if let err = error as NSError? {
                completion(nil, err)
                return
            }

            guard let config = configuration, config.json["paypalEnabled"].isTrue else {
                self.apiClient.sendAnalyticsEvent("ios.paypal-otc.preflight.disabled") // TODO: - change analytics events for native flow?
                let payPalDisabledError = NSError(domain: BTPayPalNativeClient.errorDomain,
                                                  code: ErrorType.disabled.rawValue,
                                                  userInfo: [NSLocalizedDescriptionKey: "PayPal is not enabled for this merchant",
                                                             NSLocalizedRecoverySuggestionErrorKey: "Enable PayPal for this merchant in the Braintree Control Panel"])
                completion(nil, payPalDisabledError)
                return
            }

            self.apiClient.post(request.hermesPath, parameters: request.parameters(with: config)) { json, response, error in
                if var err = error as NSError? {
                    if let errorJSON = err.userInfo[NSLocalizedDescriptionKey].map({ BTJSON(value: $0) }),
                       let issue = errorJSON["paymentResources"]["errorDetails"].asArray()?.first?["issue"].asString(),
                       err.userInfo[NSLocalizedDescriptionKey] == nil {
                        var userInfo = err.userInfo
                        userInfo[NSLocalizedDescriptionKey] = issue
                        err = NSError(domain: err.domain, code: err.code, userInfo: userInfo)
                    }

                    completion(nil, err)
                    return
                }
            }
        }
    }
}
