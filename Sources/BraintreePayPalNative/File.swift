import Foundation
import PayPalCheckout
#if canImport(BraintreePayPal)
import BraintreePayPal
//import BraintreeCore
#endif

class BraintreePayPalNative {
    func thisTestRocks() {

        // use native XO module
        guard let id = PayPalCheckout.State.correlationIDs.riskCorrelationID else {
            print("booo")
            return
        }
        print(id)
//
//        // use BT PayPal module
//        let nonce = BTPayPalAccountNonce.init(nonce: "woek")
//
//        // use BT Core
//        let apiClient = BTAPIClient.init(authorization: "INITME")
//
//        let driver = BTPayPalDriver.init(apiClient: apiClient!)

    }
}
