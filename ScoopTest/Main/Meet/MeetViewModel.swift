//
//  MeetViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/08/2025.

import Foundation

@Observable class MeetViewModel {
    
    let dep: AppDependencies
    
    
    var weeklyRec: WeeklyRecCycle {
        Task {
            dep.weeklyRecsManager.getWeeklyRecDoc()
        }
    }
    
    
}
