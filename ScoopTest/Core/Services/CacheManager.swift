//
//  CacheManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 31/07/2025.
//

import Foundation
import UIKit
import SwiftUI



@Observable class CacheManager: ImageCaching {
    
    private let cache: NSCache<NSURL, Image>

    init() {
        cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100
    }
    
    
    func addProfileImagesToCache(profile: UserProfile) async {
        
        
        let urls = profile.imagePathURL?.compactMap { URL(string: $0) } ?? []
        
        var images: [Image] = []
        
        
        for url in urls {
            
            AsyncImage(url: url) { image in
                cache.setObject(image, forKey: url as NSURL)
                
            } placeholder: {
                
            }
        }
        
        
    }

}
