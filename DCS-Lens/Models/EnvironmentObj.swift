import Foundation

struct EnvironmentObj: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let dayImage: String
    let nightImage: String
    let imagePreview: String
    let isEnabled: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case description
        case dayImage
        case nightImage
        case imagePreview
        case isEnabled
        case createdAt
        case updatedAt
    }
    
    // Implement Equatable
    static func == (lhs: EnvironmentObj, rhs: EnvironmentObj) -> Bool {
        return lhs.id == rhs.id
    }
} 
