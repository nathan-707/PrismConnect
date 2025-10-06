//
//  ThemeParkView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/11/25.
//

import SwiftUI

struct ThemeParkView: View {
    @EnvironmentObject private var prismSessionManager: ClockSessionManager
    var body: some View {
        VStack{
            Text(prismSessionManager.CurrentParkClockIsIn.fullParkName())
                .font(.title2).bold()
            Text(prismSessionManager.CurrentParkClockIsIn.fullLocationName())
                .font(.title3).bold()
                .padding(.bottom, 20)
            teleportCityInfoView()
        }
    }
}

#Preview {
    ThemeParkView()
}
