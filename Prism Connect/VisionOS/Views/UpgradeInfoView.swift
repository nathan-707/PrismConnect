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

                //                HStack {
                //                    Text(
                //                        "Upgrade to customize color of time and temperature, get more frequent weather updates, and set tour interval to as low as 1 minute"
                //                    ).foregroundStyle(.secondary).font(.headline).padding(.leading, 5)
                //
                //                    Spacer()
                //                }

                ProductView(id: virtualPrismBoxUpgradeID).padding()
                    .onInAppPurchaseCompletion { Product, Result in
                        Task {
                            await storeModel.updateCustomerProductStatus()
                        }
                    }

                //            .glassBackgroundEffect(in: .rect(cornerRadius: 20), displayMode: .always)

            }
        }
    }

    #Preview {
        UpgradeInfoView()
    }
#endif
