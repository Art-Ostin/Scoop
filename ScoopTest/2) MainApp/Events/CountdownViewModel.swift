//
//  CountdownViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//

import Foundation
import Combine 


@Observable class CountdownViewModel {
    
    let dependencies: AppDependencies
    
    var hourRemaining: String = ""
    
    var minuteRemaining: String = ""
    
    var secondRemaining: String = ""
    
    var A = Set<AnyCancellable> ()
    
    
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        setUpTimer()
        updateTimeRemaining()
    }
    
    func updateTimeRemaining() {
        let remaining = Calendar.current.dateComponents([.hour, .minute, .second], from: Date(), to: Event.sample(dependencies: dependencies).time)
        let hour = remaining.hour ?? 0
        let minute = remaining.minute ?? 0
        let second = remaining.second ?? 0
        
        hourRemaining = ("\(hour)")
        
        minuteRemaining = ("\(minute)")
        
        secondRemaining = ("\(second)")
    }
    
    func setUpTimer() {
        Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else {return}
                updateTimeRemaining()
            }
            .store(in: &A)
    }
}
