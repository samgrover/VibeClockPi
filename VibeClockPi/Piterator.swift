import OSLog

/// Pi Delivery (https://pi.delivery) provides an API to get any value of pi up to 100 trillion.
/// This iterator provides those values from a starting index `start`up to the ending index `start + limit`.
///
/// Usage Example:
/// for try await value in Piterator(start: start, step: step, limit: limit) {
///   ...
/// }

struct Piterator: AsyncSequence, AsyncIteratorProtocol {
  private static let logger = Logger(subsystem: "", category: "Piterator")

  typealias Element = Int

  private let start: Int
  private let step: Int
  private let limit: Int?

  private var cursor = 0

  private let client = PiDeliveryClient()
  private var calls = 0
  private var content: String = ""

  init(start: Int = 0, step: Int = 1000, limit: Int? = nil) {
    self.start = start
    self.step = step
    self.limit = limit
  }

  mutating func next() async throws -> Int? {
    guard !Task.isCancelled else {
      return nil
    }

    if let limit {
      guard limit > 0, (calls - 1) * step + cursor < limit else {
        return nil
      }
    }

    if content.isEmpty {
      cursor = 0
      content = try await fetch()
      calls += 1
    }

    let idx = content.index(content.startIndex, offsetBy: cursor)
    let x = Int(String(content[idx]))

    if cursor == step - 1 {
      content = try await fetch()
      calls += 1
      cursor = 0
    } else {
      cursor += 1
    }

    return x
  }

  func makeAsyncIterator() -> Piterator {
    self
  }
}

extension Piterator {

  private func fetch() async throws -> String {
    do {
      return try await client.digits(start: start + calls * step, number: step)
    } catch {
      Self.logger.log("Fetching digits failed: \(error.localizedDescription)")
      throw error
    }
  }

  private struct PiDeliveryClient {
    private struct Response: Codable {
      let content: String
    }

    private static let logger = Logger(subsystem: "", category: "PiDeliveryClient")
    private static let base = URL(string: "https://api.pi.delivery/")!

    func digits(start: Int = 0, number: Int = 100) async throws -> String {
      var components = URLComponents()
      components.path = "v1/pi"
      components.queryItems = [
        URLQueryItem(name: "start", value: String(start)),
        URLQueryItem(name: "numberOfDigits", value: String(number)),
      ]

      var request = URLRequest(url: components.url(relativeTo: PiDeliveryClient.base)!)
      request.httpMethod = "GET"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      Self.logger.log(level: .debug, "\(request)")
      do {
        let (result, urlResponse) = try await URLSession.shared.data(for: request)
        if let httpResponse = urlResponse as? HTTPURLResponse, httpResponse.statusCode != 200 {
          Self.logger.log(level: .error, "Response Metadata: \(httpResponse)")
          if let errorResponse = String(data: result, encoding: .utf8) {
            Self.logger.log(level: .error, "\(errorResponse)")
          }
        }
        let actualAPIResponse = try JSONDecoder().decode(Response.self, from: result)
        return actualAPIResponse.content
      } catch {
        Self.logger.log("Pi Delivery request failed: \(error.localizedDescription)")
        throw error
      }
    }
  }
}

