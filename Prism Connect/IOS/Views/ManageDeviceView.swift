import SwiftUI

struct ManageDeviceView: View {
    @EnvironmentObject var prismSessionManager: ClockSessionManager

    var body: some View {
        ScrollView{
        VStack(spacing: 20) {
            ForEach(prismSessionManager.session.accessories, id: \.self) { accessory in
                Button {
                    heavyImpact.impactOccurred()
                    prismSessionManager.switchToKnownAccessory(accessory: accessory)
                    prismSessionManager.presentManagerDeviceView = false
                    
                } label: {
                    HStack {
                        Text(accessory.displayName)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
            
            Button {
                heavyImpact.impactOccurred()
                prismSessionManager.presentPicker()
                prismSessionManager.authenticated = false
            } label: {
                Label("Add Device", systemImage: "plus.circle.fill")
            }
            .controlSize(.large)
            .buttonStyle(.glassProminent)
            .tint(.green)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            
            Spacer()
        }
    }
        .padding()
    }
}
