//
//  ScanView.swift
//  ResiApp
//
//  Created by Dev Jr.23 on 5/5/26.
//

import SwiftUI

struct ScanView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        Text("Escanear")
            .navigationTitle("Escanear")
    }
}

#Preview {
    ScanView(selectedTab: .constant(.scan))
}
