//
//  Store.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 9/24/25.
//

import Foundation
import StoreKit


typealias Transaction = StoreKit.Transaction
let virtualPrismBoxUpgradeID: String = "virtualskies.upgrade"


public enum StoreError: Error {
    case failedVerification
}


class Store: ObservableObject {
    
    @Published var upgraded = false
    var updateListenerTask: Task<Void, Error>? = nil
    
    init() {
        //Initialize empty products, and then do a product request asynchronously to fill them in.
        self.upgraded = false
        
        //Start a transaction listener as close to app launch as possible so you don't miss any transactions.
        updateListenerTask = listenForTransactions()
        
        Task {
            //Deliver products that the customer purchases.
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    //Deliver products to the user.
                    await self.updateCustomerProductStatus()
                    
                    //Always finish a transaction.
                    await transaction.finish()
                } catch {
                    //StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    print("Transaction failed verification")
                }
            }
        }
    }
    

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            //The result is verified. Return the unwrapped value.
            return safe
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        
        //Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                //Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)
                
                //Check the `productType` of the transaction and get the corresponding product from the store.
                switch transaction.productType {
                case .nonConsumable:
                    if transaction.productID == virtualPrismBoxUpgradeID {
                        upgraded = true
                    }
                    break
                default:
                    break
                }
            } catch {
                print("purchase verification failed.")
            }
        }
    }
}










