import Foundation

struct Verse: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let book: String
    let chapter: Int
    let verse: Int
    let reference: String
    let text: String
}
