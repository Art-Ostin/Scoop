//
//  OnboardingImageViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 29/10/2025.
//

import Foundation
import SwiftUI
import UIKit


@MainActor
@Observable final class OnboardingImageViewModel {
    
    private let defaults: DefaultsManager
    private let storageService: StorageServicing
    private let auth: AuthServicing
    
    init(defaults: DefaultsManager, storageService: StorageServicing, auth: AuthServicing) {
        self.defaults = defaults
        self.storageService  = storageService
        self.auth = auth
    }
    
    private enum ImageEncodingError: Error {
        case encodingFailed
    }
    
    //Have a guard statement on the actual button for 'valid tap' so that the images are all non-optional (as they should be)
    func saveAll(images: [UIImage?]) async  {
        guard let userId = await auth.fetchAuthUser()?.uid else { return }
        let items = Array(images.enumerated())
        let storage = self.storageService
        var results: [(index: Int, path: String, url: URL)] = []
        do {
            try await withThrowingTaskGroup(of: (Int, String, URL).self) { group in
                for (i, image) in items {
                    group.addTask {
                        guard let image = image, let data = Self.jpegDataForUpload(from: image) else {
                            throw ImageEncodingError.encodingFailed
                        }
                        let (path, url) = try await storage.saveImage(data: data, userId: userId)
                        return (i, path, url)
                    }
                }
                for try await r in group {
                    results.append(r)
                }
            }
        } catch {print(error) }
        let sorted = results.sorted { $0.index < $1.index }
        await MainActor.run {
            defaults.signUpDraft?.imagePath = sorted.map { $0.path }
            defaults.signUpDraft?.imagePathURL = sorted.map { $0.url.absoluteString }
        }
    }
    
    nonisolated static func jpegDataForUpload( from image: UIImage, backgroundColor: UIColor = .white) -> Data? {
        let hasAlpha: Bool = {
            guard let info = image.cgImage?.alphaInfo else { return false }
            switch info {
            case .first, .last, .premultipliedFirst, .premultipliedLast: return true
            default: return false
            }
        }()

        // Redraw to normalize orientation & optionally flatten alpha
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = !hasAlpha

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let rendered = renderer.image { ctx in
            if hasAlpha {
                backgroundColor.setFill()
                ctx.fill(CGRect(origin: .zero, size: image.size))
            }
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }

        // Max quality JPEG (still compressed, but least lossy)
        return rendered.jpegData(compressionQuality: 1.0)
    }
}

