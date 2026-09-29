//
//  StorageService.swift
//  Scoop
//
//  Created by Art Ostin on 22/07/2025.
//

import UIKit
import FirebaseAuth
import FirebaseStorage

//Photos go up already resized, in one request, and come back with their URL: nothing waits on the Resize extension
final class StorageService: StorageServicing {

    private let storage = Storage.storage()
    private let imageLoader: ImageLoading
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15 //A black-holed link fails a save in seconds, not the SDK's 600
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    init(imageLoader: ImageLoading) { self.imageLoader = imageLoader }

    enum UploadError: Error { case signedOut, encodeFailed, http(Int), noToken }

    //Resized to the ≤1350 variant the extension used to derive, named as it would name it and flagged so it leaves the
    //file alone. One multipart POST: the reply carries the download token, so the URL is known on return, and the
    //bytes seed the loader's cache under it so the next load is a hit.
    func saveImage(_ image: UIImage, userId: String) async throws -> (path: String, url: URL) {
        guard let user = Auth.auth().currentUser else { throw UploadError.signedOut }
        async let idToken = user.getIDToken() //Cached; its hourly refresh overlaps the encode
        let data = try await Task.detached(priority: .userInitiated) { try Self.jpeg(image) }.value
        let path = "users/\(userId)/\(UUID().uuidString)_1350x1350.jpeg"
        let escaped = path.addingPercentEncoding(withAllowedCharacters: Self.unreserved)!
        let boundary = UUID().uuidString
        var body = Data("--\(boundary)\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n".utf8)
        body += try JSONSerialization.data(withJSONObject: ["name": path, "contentType": "image/jpeg", "metadata": ["resizedImage": "true"]])
        body += Data("\r\n--\(boundary)\r\nContent-Type: image/jpeg\r\n\r\n".utf8)
        body += data
        body += Data("\r\n--\(boundary)--\r\n".utf8)
        let auth = try await idToken
        var request = URLRequest(url: URL(string: "\(objects)?name=\(escaped)")!)
        request.httpMethod = "POST"
        request.setValue("Firebase \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("multipart", forHTTPHeaderField: "X-Goog-Upload-Protocol")
        request.httpBody = body
        let (reply, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw UploadError.http(status) }
        guard let tokens = (try JSONSerialization.jsonObject(with: reply) as? [String: Any])?["downloadTokens"] as? String,
              let token = tokens.split(separator: ",").first else { throw UploadError.noToken }
        let url = URL(string: "\(objects)/\(escaped)?alt=media&token=\(token)")! //Byte-identical to what the SDK's downloadURL() builds, :443 included
        await imageLoader.store(data, for: url)
        return (path, url)
    }

    func deleteImage(path: String) async throws {
        try await storage.reference(withPath: path).delete()
    }

    private var objects: String { "https://firebasestorage.googleapis.com:443/v0/b/\(storage.reference().bucket)/o" }
    private static let unreserved = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~")) //GCS escaping: every "/" in the path becomes %2F

    //Fit inside 1350×1350, never enlarged, drawn upright on white in sRGB: orientation baked in, alpha flattened
    private static func jpeg(_ image: UIImage) throws -> Data {
        let pixels = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        guard pixels.width > 0, pixels.height > 0 else { throw UploadError.encodeFailed }
        let k = min(1, 1350 / max(pixels.width, pixels.height))
        let size = CGSize(width: (pixels.width * k).rounded(.down), height: (pixels.height * k).rounded(.down))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: size, format: format).jpegData(withCompressionQuality: 0.8) { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
