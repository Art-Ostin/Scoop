import Foundation

@MainActor
final class OTPManager: ObservableObject {
    @Published var expectedOtp: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Make this configurable (you can later wire from env/config)
    private let endpoint: URL

    init(endpoint: String = "https://us-central1-scoop-31b4b.cloudfunctions.net/rawTestGenerateOtp") {
        guard let url = URL(string: endpoint) else {
            fatalError("Invalid OTP endpoint URL")
        }
        self.endpoint = url
    }

    func fetchOtp() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data("{}".utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            let bodyText = String(data: data, encoding: .utf8) ?? "<no body>"
            guard (200...299).contains(http.statusCode) else {
                throw NSError(domain: "OTP", code: http.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "Server error \(http.statusCode): \(bodyText)"
                ])
            }
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let code = json["code"] as? String
            else {
                throw NSError(domain: "OTP", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Missing or malformed code in response: \(bodyText)"
                ])
            }
            expectedOtp = code
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func verify(input: String) -> Bool {
        return input == expectedOtp
    }
}
