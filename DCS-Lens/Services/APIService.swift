import Foundation



// MARK: - API Error Enum

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
}

class APIService {
    static let shared = APIService()
//    private let baseURL = "http://localhost:3000"
    private let baseURL = "http://37.27.87.170:3000"
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()

    private init() {}

    // Generic Fetch Function
    private func fetchData<T: Decodable>(from endpoint: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            print("[API] Error: Invalid URL for endpoint \(endpoint)")
            throw APIError.invalidURL
        }
        
//        print("[API] Requesting: \(url)")

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("[API] Error: Invalid response status code \(statusCode) for \(url)")
                // TODO: Handle specific error codes if needed
                throw APIError.invalidResponse
            }

            do {
                 let decodedData = try decoder.decode(T.self, from: data)
//                 print("[API] Success: Decoded \(String(describing: T.self)) from \(url)")
                 return decodedData
             } catch let decodingError {
                 print("[API] Error: Decoding Error for \(url): \(decodingError)")
                 // Optionally log the raw data string if decoding fails (be cautious with large/sensitive data)
                 // if let dataString = String(data: data, encoding: .utf8) {
                 //     print("[API] Raw Data: \(dataString)")
                 // }
                 throw APIError.decodingError(decodingError)
             }
        } catch let error as APIError {
            // Re-throw APIErrors that were already logged or created above
            throw error
        } catch {
            print("[API] Error: Network Error for \(url): \(error)")
            throw APIError.networkError(error)
        }
    }

    // MARK: - Environment Fetching
    func fetchEnvironments() async throws -> [EnvironmentObj] {
       try await fetchData(from: "environments")
    }

    // MARK: - Tag Fetching
    func fetchTags() async throws -> [Tag] {
        try await fetchData(from: "tags")
    }

    // MARK: - Video Fetching
    func fetchFeaturedVideos() async throws -> [Video] {
        try await fetchData(from: "videos/featured")
    }

    func fetchAllVideos() async throws -> [Video] {
        try await fetchData(from: "videos/all")
    }

    func fetchVideos(tagged tagId: String) async throws -> [Video] {
        try await fetchData(from: "videos/tagged/\(tagId)")
    }
} 
