import Foundation

public struct Book: Identifiable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let testament: String
    public let abbreviation: String

    public init(id: Int, name: String, testament: String, abbreviation: String) {
        self.id = id
        self.name = name
        self.testament = testament
        self.abbreviation = abbreviation
    }
}
