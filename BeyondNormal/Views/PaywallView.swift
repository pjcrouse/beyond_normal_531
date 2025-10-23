//
//  PaywallView.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/23/25.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var purchases: PurchaseManager

    var body: some View {
        VStack(spacing: 16) {
            Text("Go Pro").font(.title2.bold())

            if let p = purchases.proMonthly {
                Button {
                    Task { await purchases.buyProMonthly() }
                } label: {
                    Text("Start Free Trial, then \(p.displayPrice)/mo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if let p = purchases.lifetime {
                Button {
                    Task { await purchases.buyLifetime() }
                } label: {
                    Text("Lifetime Access \(p.displayPrice)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button("Restore Purchases") {
                Task { await purchases.restore() }
            }
            .padding(.top, 8)

            if purchases.purchaseInFlight {
                ProgressView().padding(.top, 6)
            }
            if let err = purchases.lastError {
                Text(err).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
