import Foundation

struct ChapterKnowledgeSource: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let publisher: String
    let url: URL
    let edition: String?
}

/// Public bibliographic details only; textbook pages and learner data are not bundled.
enum ChapterKnowledgeSourceCatalog {
    static let sources: [ChapterKnowledgeSource] = [
        ChapterKnowledgeSource(
            id: "balbharati-std4",
            title: "Shivachhatrapati, Environmental Studies Part Two, Standard Four",
            publisher: "Maharashtra State Bureau of Textbook Production and Curriculum Research",
            url: URL(string: "https://books.ebalbharati.in/pdfs/403000542.pdf")!,
            edition: "First edition 2014; revised September 2016; reprint September 2021 (PDF page 4)"),
        ChapterKnowledgeSource(
            id: "balbharati-std7",
            title: "History and Civics, Standard Seven",
            publisher: "Maharashtra State Bureau of Textbook Production and Curriculum Research",
            url: URL(string: "https://books.ebalbharati.in/pdfs/703000584.pdf")!,
            edition: "First edition 2017; reprint October 2021"),
        ChapterKnowledgeSource(
            id: "icomos-2025",
            title: "ICOMOS evaluation: Maratha Military Landscapes of India",
            publisher: "ICOMOS, hosted by UNESCO World Heritage Centre",
            url: URL(string: "https://whc.unesco.org/document/222061")!,
            edition: "12 March 2025 advisory evaluation"),
        ChapterKnowledgeSource(
            id: "tourism-shivneri",
            title: "Shivneri Fort",
            publisher: "Maharashtra Tourism",
            url: URL(string: "https://maharashtratourism.gov.in/fort/shivneri/")!,
            edition: nil),
        ChapterKnowledgeSource(
            id: "tourism-rajgad",
            title: "Rajgad Fort",
            publisher: "Maharashtra Tourism",
            url: URL(string: "https://maharashtratourism.gov.in/fort/rajgad/")!,
            edition: nil),
        ChapterKnowledgeSource(
            id: "satara-pratapgad",
            title: "Pratapgad",
            publisher: "District Satara, Government of Maharashtra",
            url: URL(string: "https://www.satara.gov.in/en/tourist-place/pratapgad/")!,
            edition: nil),
        ChapterKnowledgeSource(
            id: "tourism-purandar",
            title: "Purandar Fort",
            publisher: "Maharashtra Tourism",
            url: URL(string: "https://maharashtratourism.gov.in/fort/purandar/")!,
            edition: nil),
        ChapterKnowledgeSource(
            id: "agra-district",
            title: "About District: Agra",
            publisher: "District Administration Agra, Government of Uttar Pradesh",
            url: URL(string: "https://agra.nic.in/")!,
            edition: nil)
    ]

    static func source(id: String) -> ChapterKnowledgeSource? {
        sources.first { $0.id == id }
    }
}

/// Both platforms receive exactly the same authored definitions and stable IDs.
enum ChapterKnowledgeCatalog {
    static let definitions = ChapterKnowledgeChapters12.definitions + ChapterKnowledgeChapters34.definitions +
        ChapterKnowledgeChapters56.definitions

    static func definition(sceneID: String) -> ChapterKnowledgeDefinition? {
        definitions.first { $0.sceneID == sceneID }
    }

    static var validationIssues: [String] {
        var issues = definitions.flatMap(\.validationIssues)
        if Set(definitions.map(\.sceneID)).count != definitions.count { issues.append("Duplicate knowledge scene IDs") }
        for claim in definitions.flatMap(\.claims) {
            for citation in claim.citations where ChapterKnowledgeSourceCatalog.source(id: citation.sourceID) == nil {
                issues.append("Unknown knowledge source: \(citation.sourceID), \(claim.id)")
            }
        }
        return issues
    }
}
