//
//  DetailsExtraInfo.swift
//  Scoop
//
//  Created by Art Ostin on 20/01/2026.
//

import SwiftUI

struct DetailsExtraInfo: View {
    
    let p: UserProfile
    
    enum infoType: CaseIterable { case alcohol, smoking, weed, drugs, movie, song, book, languages, gender}
        
    var vicesOnTwoLines: Bool {
        (p.favouriteSong == nil) && (p.favouriteMovie == nil) && (p.favouriteBook == nil)
    }
    
    var genderAndLanguagesCount: Int {
        p.sex.count + p.languages.joined().count
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: Spacing.md) {
            if vicesOnTwoLines {
                twoLineVices
            } else {
                oneLineVice
            }
            Divider().foregroundStyle(Color.border)
            
            if let favouriteSong = p.favouriteSong {
                    InfoItem(image: "MusicIcon", info: favouriteSong)
                    Divider().foregroundStyle(Color.border)
            }
            
            if let favouriteBook = p.favouriteBook {
                InfoItem(image: "BookIcon", info: favouriteBook)
                Divider().foregroundStyle(Color.border)
            }
            
            if let favouriteMovie = p.favouriteMovie {
                InfoItem(image: "MovieIcon", info: favouriteMovie)
                Divider().foregroundStyle(Color.border)
            }
            
            if genderAndLanguagesCount <= 26 {
                genderAndLanguages
            } else {
                genderaAndLanguagesScroll
            }
        }
    }
}

extension DetailsExtraInfo {
    
    @ViewBuilder
    private var twoLineVices: some View {
        HStack {
            InfoItem(image: "AlcoholIcon", info: p.drinking)
            Spacer()
            InfoItem(image: "CigaretteIcon", info: p.smoking)
        }
        Divider().foregroundStyle(Color.border)
        HStack {
            InfoItem(image: "WeedIcon", info: p.marijuana)
            Spacer()
            InfoItem(image: "DrugsIcon",info: p.drugs)
        }
    }
    
    private var oneLineVice: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.md) {
                InfoItem(image: "AlcoholIcon", info: p.drinking)
                InfoItem(image: "CigaretteIcon", info: p.smoking)
                InfoItem(image: "WeedIcon", info: p.marijuana)
                InfoItem(image: "DrugsIcon",info: p.drugs)
            }
        }
        .padding(.vertical, Spacing.sm) //Trick to expand the tap area of the view so scrolls easier
        .contentShape(Rectangle())
        .padding(.vertical, -12)
    }
    
    private var genderAndLanguages: some View {
        HStack {
            InfoItem(image: "GenderIcon", info: p.sex)
            
            Spacer()
            
            if !p.languages.isEmpty {
                InfoItem(image: "Languages", info: p.languages.joined(separator: ", "))
                    .lineLimit(1)
            }
        }
    }
    
    private var genderaAndLanguagesScroll: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.lg) {
                InfoItem(image: "GenderIcon", info: p.sex)
                if !p.languages.isEmpty {
                    InfoItem(image: "Languages", info: p.languages.joined(separator: ", "))
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, Spacing.sm) //Trick to expand the tap area of the view so scrolls easier
        .contentShape(Rectangle())
        .padding(.vertical, -12)
    }
    
    
    
    
}
