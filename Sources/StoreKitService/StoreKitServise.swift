import Combine
import StoreKit

public final class StoreKitService: NSObject, ObservableObject {
    
    typealias ProductsRequestFinished = ([StoreKitProduct]) -> Void
    typealias ProductProcessingCompleted = (ProcessingResult) -> Void
    
    private let purchaseHistory: StoreKitPurchaseHistory
    
    private var productsRequest: SKProductsRequest?
    
    private var onProductsRequestFinished: ProductsRequestFinished?
    
    private var onProductPurchasingCompleted: ProductProcessingCompleted?
    private var onProductsRestoringCompleted: ProductProcessingCompleted?
    
    @Published
    public private(set) var products: [StoreKitProduct] = []
    
    public init(verificationPassword: String) {
        self.purchaseHistory = StoreKitPurchaseHistory(password: verificationPassword)
    }
    
    public func prepare(with identifiers: [String]) async {
        let products = await loadProducts(with: identifiers)
        
        do {
            try await purchaseHistory.refreshHistory()
        } catch let error {
            #if DEBUG
            print("StoreKitService error:", error)
            #endif
        }
        
        await set(products: products)
        await updateProductSubscriptionActivity()
    }
    
    @discardableResult
    public func loadProducts(with identifiers: [String]) async -> [StoreKitProduct] {
        await withCheckedContinuation { continuation in
            loadProducts(with: identifiers) { products in
                continuation.resume(returning: products)
            }
        }
    }
    
    public func purchase(product: StoreKitProduct) async -> ProcessingResult {
        let result = await withCheckedContinuation { continuation in
            purchaseProduct(product: product) { result in
                continuation.resume(returning: result)
            }
        }
        
        try? await purchaseHistory.refreshHistory()
        await updateProductSubscriptionActivity()
        
        return result
    }
    
    public func restoreProducts() async -> ProcessingResult {
        let result = await withCheckedContinuation { continuation in
            restoreProducts { result in
                continuation.resume(returning: result)
            }
        }
        
        try? await purchaseHistory.refreshHistory()
        await updateProductSubscriptionActivity()
        
        return result
    }
    
    public func getProduct(withPeriod period: Int,
                           of unit: SKProduct.PeriodUnit) -> StoreKitProduct? {
        
        products.first {
            $0.product.subscriptionPeriod?.unit == unit &&
            $0.product.subscriptionPeriod?.numberOfUnits == period
        }
    }
    
    public func isSubscriptionActive(for product: StoreKitProduct) -> Bool {
        purchaseHistory.isSubscriptionActive(for: product)
    }
    
    public func bind(subscriptionGroupID: String,
                     subscriptionActivePublisher: inout Published<Bool>.Publisher) {
        
        $products.map {
            $0.contains {
                $0.isSubscriptionActive &&
                $0.product.subscriptionGroupIdentifier == subscriptionGroupID
            }
        }
        .assign(to: &subscriptionActivePublisher)
        
    }
    
    func bind(subscriptionIDs: [String],
              subscriptionActivePublisher: inout Published<Bool>.Publisher) {
        
        $products.map {
            $0.contains {
                $0.isSubscriptionActive &&
                subscriptionIDs.contains($0.product.productIdentifier)
            }
        }
        .assign(to: &subscriptionActivePublisher)
        
    }
    
}

private extension StoreKitService {
    
    @MainActor
    func set(products: [StoreKitProduct]) {
        self.products = products
    }
    
    func updateProductSubscriptionActivity() async {
        let markedProducts: [StoreKitProduct] = products.map {
            $0.markAsActiveSubscription(purchaseHistory.isSubscriptionActive(for: $0))
            return $0
        }
        await set(products: markedProducts)
    }
    
    func loadProducts(with identifiers: [String],
                      onProductsRequestFinished: @escaping ProductsRequestFinished) {
        
        guard self.productsRequest == nil else {
            return
        }
        
        self.onProductsRequestFinished = onProductsRequestFinished
        self.productsRequest = SKProductsRequest(productIdentifiers: Set(identifiers))
        self.productsRequest?.delegate = self
        self.productsRequest?.start()
    }
    
    func purchaseProduct(product: StoreKitProduct,
                         onProductPurchasingCompleted: @escaping ProductProcessingCompleted) {
        
        guard self.onProductPurchasingCompleted == nil else {
            return
        }
        
        self.onProductPurchasingCompleted = onProductPurchasingCompleted
        let payment = SKPayment(product: product.product)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(payment)
        
    }
    
    func restoreProducts(onProductsRestoringCompleted: @escaping ProductProcessingCompleted) {
        
        guard self.onProductsRestoringCompleted == nil else {
            return
        }
        
        self.onProductsRestoringCompleted = onProductsRestoringCompleted
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
        
    }
    
}

extension StoreKitService: SKProductsRequestDelegate {
    
    public func productsRequest(_ request: SKProductsRequest,
                                didReceive response: SKProductsResponse) {
        
        self.productsRequest = nil
        let products = response.products.map(StoreKitProduct.init(product:))
        
        #if DEBUG
        print("Products")
        products.forEach {
            print($0)
            if let subscriptionPeriod = $0.product.subscriptionPeriod {
                print("\(subscriptionPeriod.numberOfUnits) \(subscriptionPeriod.unit)/s")
            }
        }
        #endif
        
        self.onProductsRequestFinished?(products)
        self.onProductsRequestFinished = nil
    }
    
}

extension StoreKitService: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue,
                             updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                processTransaction(transaction,
                                   with: .purchased)
                
            case .failed:
                processTransaction(transaction,
                                   with: .failed)
                
            case .restored:
                processTransaction(transaction,
                                   with: .restored)
                
            default:
                break
            }
        }
        
    }
    
    private func processTransaction(_ transaction: SKPaymentTransaction,
                                    with processingResult: ProcessingResult) {
        
        SKPaymentQueue.default().finishTransaction(transaction)
        SKPaymentQueue.default().remove(self)
        
        self.onProductPurchasingCompleted?(processingResult)
        self.onProductPurchasingCompleted = nil
        
        self.onProductsRestoringCompleted?(processingResult)
        self.onProductsRestoringCompleted = nil
    }
    
}
