import Foundation
import Combine

@MainActor
final class OTPManager: ObservableObject {
  /// the last OTP we fetched from the backend
  @Published private(set) var otp: String?

  /// Any error from the last fetch
  @Published private(set) var errorMessage: String?

  /// call your Cloud Function, passing in `email`, and stash the returned code
  func fetchOtp(for email: String) async {
    // reset old state
    otp = nil
    errorMessage = nil

    guard let url = URL(string: "https://us-central1-scoop-31b4b.cloudfunctions.net/rawTestGenerateOtp") else {
      errorMessage = "Bad URL"
      return
    }

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["email": email]
    do {
      req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

      let (data, resp) = try await URLSession.shared.data(for: req)
      guard let http = resp as? HTTPURLResponse,
            (200...299).contains(http.statusCode) else
      {
        let txt = String(data: data, encoding: .utf8) ?? "no response body"
        errorMessage = "Server error \( (resp as? HTTPURLResponse)?.statusCode ?? -1 ): \(txt)"
        return
      }

      let json = try JSONSerialization.jsonObject(with: data) as? [String:Any]
      if let code = json?["code"] as? String {
        self.otp = code
      } else {
        errorMessage = "No code in response"
      }

    } catch {
      errorMessage = error.localizedDescription
    }
  }

  /// compare user input against the last‐fetched OTP
  func verify(input: String) -> Bool {
    return input == otp
  }
}
