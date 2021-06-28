#if canImport(BraintreePayPal)
import BraintreeCore
#endif

protocol BTPayPalNativeRequest {
    var payPalReturnURL: String { get }
    var hermesPath: String { get }
}
