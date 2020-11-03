#import <BraintreePayPal/BTPayPalAccountNonce.h>
#import <BraintreePayPal/BTPayPalCreditFinancing.h>

@interface BTPayPalAccountNonce ()

- (instancetype)initWithNonce:(NSString *)nonce
                        email:(NSString *)email
                    firstName:(NSString *)firstName
                     lastName:(NSString *)lastName
                        phone:(NSString *)phone
               billingAddress:(BTPostalAddress *)billingAddress
              shippingAddress:(BTPostalAddress *)shippingAddress
             clientMetadataId:(NSString *)clientMetadataId
                      payerId:(NSString *)payerId
                    isDefault:(BOOL)isDefault
              creditFinancing:(BTPayPalCreditFinancing *)creditFinancing;

@end