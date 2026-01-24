//
//  Frozen Screen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct FrozenView: View {
    
    let vm: FrozenViewModel
    
    let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
    
    @State var showWhyFrozen: Bool = false
    @Binding var tabSelection: Int
    
    var body: some View {
        
        if let frozenContext = vm.user.blockedContext {
            VStack(spacing: 72) {
                VStack(spacing: 12) {
                    Text("Account Frozen Until")
                        .font(.body(17, .medium))
                    
                    Text(EventFormatting.expandedDate(twoWeeksFromNow))
                        .font(.custom("SFProRounded-Bold", size: 32))
                }
                Image("Monkey")

                VStack(spacing: 12) {
                    Text("Account Frozen for Cancelling")
                        .font(.body(17, .italic))
                        .foregroundStyle(Color.grayText)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)

                    
                    TabView(selection: $tabSelection) {
                        Tab(value: 0) {
                            BlockedContextView(frozenContext: frozenContext, vm: vm)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        }
                        
                        Tab(value: 1) {
                            VStack(spacing: 48) {
                                LargeClockView(targetTime: twoWeeksFromNow) {}
                                    .frame(maxWidth: .infinity)
                                
                                Text(verbatim: vm.user.email)
                                    .font(.body(14, .medium))
                                    .foregroundStyle(Color.grayText)
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                            .padding(.top, 24)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .overlay(alignment: .bottom) {
                        PageIndicator(count: 2, selection: tabSelection)
                            .padding(.bottom, 36)
                    }
                }
            }
            .padding(.top, 72)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay (alignment: .topTrailing){
                TabInfoButton(showScreen: $showWhyFrozen)
                    .padding(.horizontal)
            }
            .sheet(isPresented: $showWhyFrozen) {
                FrozenExplainedScreen(vm: vm)
            }
            .background(Color.background)
        }
    }
}
