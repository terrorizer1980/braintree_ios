import BraintreeCore
import PayPalCheckout

struct BTPayPalNativeOrder {
    let payPalClientID: String
    let environment: PayPalCheckout.Environment
    let orderID: String
}

class BTPayPalNativeOrderCreationClient {

    private let apiClient: BTAPIClient

    init(with apiClient: BTAPIClient) {
        self.apiClient = apiClient
    }

    func createOrder(with request: BTPayPalNativeRequest, completion: @escaping (BTPayPalNativeOrder?, NSError?) -> Void) {
        apiClient.fetchOrReturnRemoteConfiguration { configuration, error in
            if let err = error as NSError? {
                completion(nil, err)
                return
            }

            guard let config = configuration else {
                let configError = NSError(domain: BTPayPalNativeClient.errorDomain,
                                          code: BTPayPalNativeClient.ErrorType.unknown.rawValue,
                                          userInfo: [NSLocalizedDescriptionKey: "Failed to fetch Braintree configuration."])
                completion(nil, configError)
                return
            }

            guard config.json["paypalEnabled"].isTrue else {
                self.apiClient.sendAnalyticsEvent("ios.paypal-otc.preflight.disabled") // TODO: - change analytics events for native flow?
                let payPalDisabledError = NSError(domain: BTPayPalNativeClient.errorDomain,
                                                  code: BTPayPalNativeClient.ErrorType.disabled.rawValue,
                                                  userInfo: [NSLocalizedDescriptionKey: "PayPal is not enabled for this merchant",
                                                             NSLocalizedRecoverySuggestionErrorKey: "Enable PayPal for this merchant in the Braintree Control Panel"])
                completion(nil, payPalDisabledError)
                return
            }

            guard let payPalClientID = config.json["paypal"]["clientId"].asString() else {
                let clientIDError = NSError(domain: BTPayPalNativeClient.errorDomain,
                                            code: BTPayPalNativeClient.ErrorType.disabled.rawValue,
                                            userInfo: [NSLocalizedDescriptionKey: "Failed to fetch PayPalClientID from Braintree configuration."])
                completion(nil, clientIDError)
                return
            }

            let payPalEnvironment: PayPalCheckout.Environment?
            if config.environment == "production" {
                payPalEnvironment = .live
            } else if config.environment == "sandbox" {
                payPalEnvironment = .sandbox
            } else {
                payPalEnvironment = nil
            }

            guard let environment = payPalEnvironment else {
                let environmentError = NSError(domain: BTPayPalNativeClient.errorDomain,
                                               code: BTPayPalNativeClient.ErrorType.unknown.rawValue,
                                               userInfo: [NSLocalizedDescriptionKey: "PayPal Native Checkout failed because an invalid environment identifier was retrieved from the configuration."])
                completion(nil, environmentError)
                return
            }

            self.apiClient.post(request.hermesPath, parameters: request.parameters(with: config)) { json, response, error in
                if let err = error as NSError? {
                    completion(nil, err)
                    return
                }

                guard let hermesResponse = BTPayPalNativeHermesResponse(json: json) else {
                    let hermesError = NSError(domain: BTPayPalNativeClient.errorDomain,
                                              code: BTPayPalNativeClient.ErrorType.unknown.rawValue,
                                              userInfo: [NSLocalizedDescriptionKey: "Failed to create PayPal order."])
                    completion(nil, hermesError)
                    return
                }

                let order = BTPayPalNativeOrder(payPalClientID: payPalClientID,
                                                environment: environment,
                                                orderID: hermesResponse.orderID)
                completion(order, nil)
            }
        }
    }
}
