import StoreKit

final class SKProductsRequestProxy: NSObject, SKProductsRequestDelegate {
    
    private var productsRequest: SKProductsRequest!
    private var continuation: CheckedContinuation<[SKProduct], Never>!
    
    @MainActor
    func requestProducts(withProductIdentifiers productIdentifiers: [String]) async -> [SKProduct] {
        let productsRequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        productsRequest.delegate = self
        self.productsRequest = productsRequest
        
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            productsRequest.start()
        }
    }
    
    // MARK: - SKProductsRequestDelegate
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        #if DEBUG
        var log = "SKProductsRequestProxy summary\n"
        log += "Received products:\n"
        log += response.products.map { $0.productIdentifier }.joined(separator: "\n") + "\n"
        log += "Invalid products:\n"
        log += response.invalidProductIdentifiers.joined(separator: "\n")
        print(log)
        #endif
        continuation?.resume(returning: response.products)
        continuation = nil
    }
    
}
