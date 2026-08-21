//
//  HistoryContainer.swift
//  Scoop
//
//  Created by Art Ostin on 20/08/2026.
//

import SwiftUI
import Glur

struct HistoryContainer: View {

    @State var vm: HistoryViewModel

    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)

    var body: some View {
        ZoomNavigationStack {
            NavigationStack {
                ZStack {
                    if vm.declines.isEmpty {
                        Text("No Profiles")
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(vm.declines) { decline in
                                HistoryCard(decline: decline, vm: vm)
                            }
                        }
                        .padding(.horizontal, Spacing.gutter)
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        dismissButton
                    }
                }
                .navigationTitle("History")
            }
        }
        .environment(ZoomPresentationHost?.none)
        .ignoresSafeArea()
    }
}


extension HistoryContainer {

    private var dismissButton: some View {
        Image(systemName: "xmark")
            .foregroundStyle(.black)
            .font(.icon(14))
            .onTapGesture {
                dismiss()
            }
    }
}


