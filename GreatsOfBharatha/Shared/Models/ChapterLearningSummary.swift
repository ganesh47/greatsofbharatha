import Foundation

struct ChapterLearningSummary: Equatable {
    let explored: Bool
    let checkedWithHelp: Bool
    let checkedWithoutClue: Bool
    let laterCardRecall: Bool
    let selfReported: Bool

    init(record: MasteryRecord?) {
        let evidence = record?.evidenceLog ?? []
        explored = (record?.exposureCount ?? 0) > 0
        let checks = evidence.filter { $0.type == .recallSuccess || $0.type == .reviewSuccess }
        checkedWithHelp = checks.contains { $0.support == .hinted || $0.support == .rescued }
        checkedWithoutClue = checks.contains { $0.support == .independent }
        laterCardRecall = checks.contains {
            $0.reviewKind == .laterIndependentRecall && $0.support == .independent && $0.cardID != nil
                && $0.participation == .typedResponse
        }
        selfReported = evidence.contains { $0.type == .selfReportedReview }
    }

    var activityText: String {
        var parts: [String] = []
        if explored { parts.append("Story explored") }
        if checkedWithHelp { parts.append("Answer checked with help") }
        if checkedWithoutClue { parts.append("Answer checked without a clue") }
        if laterCardRecall { parts.append("Card recalled with a changed prompt after at least a day") }
        if selfReported { parts.append("A card response was self-reported") }
        return parts.isEmpty ? "Ready to explore" : parts.joined(separator: ". ")
    }

    var nextStep: String {
        if !explored { return "Read the story and explore its details together." }
        if !checkedWithHelp && !checkedWithoutClue { return "Try the story question; use a clue whenever it helps." }
        if !checkedWithoutClue { return "Revisit the teaching, then try a fresh question without a clue when ready." }
        if !laterCardRecall { return "Revisit a learned card another day with a changed question." }
        return "Explain how this chapter connects to the next part of the story."
    }
}
