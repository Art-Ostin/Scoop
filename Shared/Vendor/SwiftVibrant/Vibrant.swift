//
//  Vibrant.swift
//  swift-vibrant-ios
//
//  Created by Bryce Dougherty on 5/3/20.
//  Copyright © 2020 Bryce Dougherty. All rights reserved.
//

import Foundation
import UIKit

public class Vibrant {
    
    public struct Options {
        var colorCount: Int = 64
        
        var quality: Int = 5
        
        var quantizer: Quantizer.quantizer = Quantizer.defaultQuantizer
        
        var generator: Generator.generator = Generator.defaultGenerator
        
        var maxDimension: CGFloat?
        
        var filters: [VibrantFilter] = [VibrantFilter.defaultFilter]
        
        fileprivate var combinedFilter: VibrantFilter?
    }
    
    public static func from( _ src: UIImage)->Builder {
        return Builder(src)
    }

    var opts: Options
    var src: UIImage
    
    private var _palette: Palette?
    public var palette: Palette? { _palette }
    
    public init(src: UIImage, opts: Options?) {
        self.src = src
        self.opts = opts ?? Options()
        self.opts.combinedFilter = VibrantFilter.combineFilters(filters: self.opts.filters)
    }
    
    static func process(image: VibrantImage, opts: Options)->Palette {
        let quantizer = opts.quantizer
        let generator = opts.generator
        let combinedFilter = opts.combinedFilter!
        let maxDimension = opts.maxDimension
        
        image.scaleTo(size: maxDimension, quality: opts.quality)
        
        
        let imageData = image.applyFilter(combinedFilter)
        let swatches = quantizer(imageData, opts)
        let colors = Swatch.applyFilter(colors: swatches, filter: combinedFilter)
        let palette = generator(colors)
        return palette
    }
    
    public func getPalette(_ cb: @escaping Callback<Palette>) {
        DispatchQueue.init(label: "colorProcessor", qos: .background).async {
            let palette = self.getPalette()
            DispatchQueue.main.async {
                cb(palette)
            }
        }
    }
    
    public func getPalette()->Palette {
        let image = VibrantImage(image: self.src)
        let palette = Vibrant.process(image: image, opts: self.opts)
        self._palette = palette
        return palette
    }
}
