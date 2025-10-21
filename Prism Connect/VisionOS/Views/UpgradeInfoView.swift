//
//  UpgradeInfoView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 9/24/25.
//

#if os(visionOS)

    import SwiftUI
    import StoreKit

    struct UpgradeInfoView: View {
        @EnvironmentObject var storeModel: Store

        var body: some View {
            VStack {
                ProductView(id: virtualPrismBoxUpgradeID).padding()
                    .onInAppPurchaseCompletion { Product, Result in
                        Task {
                            await storeModel.updateCustomerProductStatus()
                        }
                    }
            }
        }
    }

    #Preview {
        UpgradeInfoView()
    }
#endif
