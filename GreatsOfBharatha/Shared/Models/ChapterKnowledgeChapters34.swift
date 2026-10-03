import Foundation

/// Original child teaching copy. Final copy approval remains explicit in the shared catalog.
enum ChapterKnowledgeChapters34 {
    static let definitions: [ChapterKnowledgeDefinition] = [
        ChapterKnowledgeDefinition(
            sceneID: "scene-3-pratapgad-turning-point",
            claims: [
                ChapterKnowledgeClaim(
                    id: "scene-3-pratapgad-turning-point-fact-built-1656", kind: .historical,
                    statement: "Pratapgad was built in 1656.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "satara-pratapgad",
                            locator: "main description: construction in 1656"),
                        ChapterKnowledgeCitation(
                            sourceID: "icomos-2025",
                            locator: "printed p. 94; PDF page 3: Pratapgad")
                    ],
                    taughtBeatIDs: ["scene-3-pratapgad-turning-point-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-3-pratapgad-turning-point-fact-battle-1659", kind: .historical,
                    statement: """
                    The encounter and battle associated with Shivaji Maharaj and Afzal Khan at Pratapgad occurred in \
                    1659; Afzal Khan served Bijapur.
                    """,
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "satara-pratapgad",
                            locator: "main description: 10 November 1659"),
                        ChapterKnowledgeCitation(
                            sourceID: "icomos-2025",
                            locator: "printed p. 94; PDF page 3: 1659 battle and Bijapur general")
                    ],
                    taughtBeatIDs: ["scene-3-pratapgad-turning-point-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-3-pratapgad-turning-point-fact-year-label-gap", kind: .derivedReasoning,
                    statement: "On a year-labelled timeline, the difference between 1656 and 1659 is three.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "satara-pratapgad",
                            locator: "1656 construction and 1659 encounter"),
                        ChapterKnowledgeCitation(
                            sourceID: "icomos-2025",
                            locator: "printed p. 94; PDF page 3")
                    ],
                    taughtBeatIDs: ["scene-3-pratapgad-turning-point-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-3-pratapgad-turning-point-fact-built-before-battle", kind: .derivedReasoning,
                    statement: "The 1656 construction comes before the 1659 battle on the timeline.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "satara-pratapgad",
                            locator: "construction and encounter years")
                    ],
                    taughtBeatIDs: ["scene-3-pratapgad-turning-point-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-3-pratapgad-turning-point-fact-hill-forest", kind: .siteFeature,
                    statement: "Pratapgad stands in hilly, forested terrain in the Sahyadri region near Mahabaleshwar.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "satara-pratapgad",
                            locator: "location near Mahabaleshwar"),
                        ChapterKnowledgeCitation(
                            sourceID: "icomos-2025",
                            locator: "printed p. 94; PDF page 3: forested hill region")
                    ],
                    taughtBeatIDs: ["scene-3-pratapgad-turning-point-meaning"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-3-pratapgad-turning-point-fact-water-reservoirs", kind: .siteFeature,
                    statement: "Pratapgad includes water reservoirs, showing that a fort needed supplies as well as protective walls.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "icomos-2025",
                            locator: "printed p. 94; PDF page 3: water reservoirs")
                    ],
                    taughtBeatIDs: ["scene-3-pratapgad-turning-point-meaning"], reviewStatus: .approved)
            ],
            beats: [
                ChapterKnowledgeBeat(
                    id: "scene-3-pratapgad-turning-point-story", title: "The story",
                    text: """
                    At Pratapgad, careful planning, courage, and hill terrain — the shape of the land — mattered in a \
                    dangerous moment. The story stays focused on preparation and wise choices.
                    """,
                    claimIDs: ["scene-3-pratapgad-turning-point-fact-built-1656", "scene-3-pratapgad-turning-point-fact-battle-1659"]),
                ChapterKnowledgeBeat(
                    id: "scene-3-pratapgad-turning-point-memory", title: "Remember this",
                    text: """
                    The dangerous meeting near Pratapgad in 1659 became a major turning point in Shivaji Maharaj's rise. \
                    Pratapgad is the Turning Point. Hill terrain means the shape of the land; careful planning means \
                    being prepared. First came Shivneri, then the early forts, and then Pratapgad in 1659.

                    Compare the year labels: 1659 − 1656 = 3. These labels are three apart; exact time between events \
                    also depends on their dates.
                    """,
                    claimIDs: ["scene-3-pratapgad-turning-point-fact-year-label-gap", "scene-3-pratapgad-turning-point-fact-built-before-battle"]),
                ChapterKnowledgeBeat(
                    id: "scene-3-pratapgad-turning-point-meaning", title: "Why it matters",
                    text: "Pratapgad matters because the hill terrain and careful planning changed what happened next.",
                    claimIDs: ["scene-3-pratapgad-turning-point-fact-hill-forest", "scene-3-pratapgad-turning-point-fact-water-reservoirs"])
            ],
            questions: [
                ChapterKnowledgeQuestion(
                    id: "scene-3-pratapgad-turning-point-knowledge-question-year-gap", kind: .numericYearLabelGap,
                    prompt: "Pratapgad’s timeline labels are 1656 for building and 1659 for the battle. What is 1659 − 1656?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-year-gap-choice-3", text: "Four"),
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-year-gap-choice-1", text: "Two"),
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-year-gap-choice-2", text: "Three")
                    ],
                    correctChoiceID: "scene-3-pratapgad-turning-point-knowledge-question-year-gap-choice-2",
                    claimIDs: [
                        "scene-3-pratapgad-turning-point-fact-built-1656",
                        "scene-3-pratapgad-turning-point-fact-battle-1659",
                        "scene-3-pratapgad-turning-point-fact-year-label-gap"
                    ],
                    requiredBeatIDs: ["scene-3-pratapgad-turning-point-memory", "scene-3-pratapgad-turning-point-story"],
                    explanation: "The year labels differ by three. We are comparing labels, not claiming an exact elapsed duration.",
                    hints: ["Move from 1656 to 1657, then 1658, then 1659."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-3-pratapgad-turning-point-knowledge-question-before", kind: .sequence,
                    prompt: "Which comes first on this timeline?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-before-choice-1", text: "Building Pratapgad in 1656"),
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-before-choice-2", text: "The battle at Pratapgad in 1659"),
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-before-choice-3", text: "Both have the same year label")
                    ],
                    correctChoiceID: "scene-3-pratapgad-turning-point-knowledge-question-before-choice-1",
                    claimIDs: ["scene-3-pratapgad-turning-point-fact-built-before-battle"],
                    requiredBeatIDs: ["scene-3-pratapgad-turning-point-memory"],
                    explanation: "1656 comes before 1659, so the fort’s construction is earlier.",
                    hints: ["Compare the two year labels."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-3-pratapgad-turning-point-knowledge-question-bijapur", kind: .identity,
                    prompt: "Afzal Khan came from the forces of which kingdom?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-bijapur-choice-3", text: "The Portuguese"),
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-bijapur-choice-1", text: "Bijapur"),
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-bijapur-choice-2", text: "The Mughals")
                    ],
                    correctChoiceID: "scene-3-pratapgad-turning-point-knowledge-question-bijapur-choice-1",
                    claimIDs: ["scene-3-pratapgad-turning-point-fact-battle-1659"],
                    requiredBeatIDs: ["scene-3-pratapgad-turning-point-story"],
                    explanation: "Afzal Khan served Bijapur. The chapter’s turning point is associated with Pratapgad in 1659.",
                    hints: ["Look for the kingdom named with Afzal Khan."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-3-pratapgad-turning-point-knowledge-question-terrain", kind: .geography,
                    prompt: "Which landscape best fits Pratapgad?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-terrain-choice-2", text: "An open sea shore"),
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-terrain-choice-3", text: "A broad, flat plain"),
                        ChapterKnowledgeChoice(
                            id: "scene-3-pratapgad-turning-point-knowledge-question-terrain-choice-1", text: "Forested hills")
                    ],
                    correctChoiceID: "scene-3-pratapgad-turning-point-knowledge-question-terrain-choice-1",
                    claimIDs: ["scene-3-pratapgad-turning-point-fact-hill-forest"],
                    requiredBeatIDs: ["scene-3-pratapgad-turning-point-meaning"],
                    explanation: "Pratapgad stands in hilly, forested Sahyadri terrain near Mahabaleshwar.",
                    hints: ["Remember the hills and forest in the place fact."],
                    retryFeedback: "Let’s look at the clue and try again.")
            ]),
        ChapterKnowledgeDefinition(
            sceneID: "scene-4-purandar-agra",
            claims: [
                ChapterKnowledgeClaim(
                    id: "scene-4-purandar-agra-fact-treaty-1665", kind: .historical,
                    statement: "The Treaty of Purandar was agreed in 1665 following negotiations with Jai Singh.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed p. 48; PDF page 58"),
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 25; PDF page 35")
                    ],
                    taughtBeatIDs: ["scene-4-purandar-agra-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-4-purandar-agra-fact-twenty-three-forts", kind: .historical,
                    statement: "The treaty required Shivaji Maharaj to give twenty-three forts to the Mughals.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed p. 48; PDF page 58"),
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 25; PDF page 35"),
                        ChapterKnowledgeCitation(
                            sourceID: "tourism-purandar",
                            locator: "Treaty of Purandar section")
                    ],
                    taughtBeatIDs: ["scene-4-purandar-agra-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-4-purandar-agra-fact-return-1666", kind: .historical,
                    statement: "The Agra visit, custody, and return belong to 1666; the return led back to Rajgad.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed pp. 50–52; PDF pages 60–62"),
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 25; PDF page 35")
                    ],
                    taughtBeatIDs: ["scene-4-purandar-agra-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-4-purandar-agra-fact-sambhaji", kind: .historical,
                    statement: "Shivaji Maharaj’s son Sambhaji accompanied him on the journey to Agra.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed p. 50; PDF page 60")
                    ],
                    taughtBeatIDs: ["scene-4-purandar-agra-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-4-purandar-agra-fact-agra-yamuna", kind: .siteFeature,
                    statement: "Agra is a city on the Yamuna River in present-day Uttar Pradesh.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "agra-district",
                            locator: "About District paragraph")
                    ],
                    taughtBeatIDs: ["scene-4-purandar-agra-meaning"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-4-purandar-agra-fact-year-label-gap", kind: .derivedReasoning,
                    statement: "The year labels 1665 and 1666 differ by one, and Purandar comes before the Agra return.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed pp. 48, 52; PDF pages 58, 62")
                    ],
                    taughtBeatIDs: ["scene-4-purandar-agra-meaning"], reviewStatus: .approved)
            ],
            beats: [
                ChapterKnowledgeBeat(
                    id: "scene-4-purandar-agra-story", title: "The story",
                    text: """
                    Sometimes leaders face hard pressure. Shivaji Maharaj made a difficult agreement at Purandar. Later, \
                    he found a clever way to return home from Agra.
                    """,
                    claimIDs: ["scene-4-purandar-agra-fact-treaty-1665", "scene-4-purandar-agra-fact-twenty-three-forts"]),
                ChapterKnowledgeBeat(
                    id: "scene-4-purandar-agra-memory", title: "Remember this",
                    text: """
                    Purandar brought heavy pressure, and Agra was the northern city where Shivaji Maharaj was kept under \
                    close watch before returning home. First came the agreement at Purandar; later came Agra and the \
                    return home. After Pratapgad in 1659 came pressure and a difficult agreement at Purandar in 1665. \
                    Later came Agra, a northern city, in 1666 and the return home. Purandar comes before Agra.

                    Being kept in custody means guards watch someone and do not let them leave freely. House arrest \
                    means having to stay in a guarded house.
                    """,
                    claimIDs: ["scene-4-purandar-agra-fact-return-1666", "scene-4-purandar-agra-fact-sambhaji"]),
                ChapterKnowledgeBeat(
                    id: "scene-4-purandar-agra-meaning", title: "Why it matters",
                    text: """
                    This scene matters because leaders can face pressure, make hard choices, and still find a way back \
                    with patience and planning.

                    Compare the year labels: 1666 − 1665 = 1. These labels are one apart; exact time between events also \
                    depends on their dates.
                    """,
                    claimIDs: ["scene-4-purandar-agra-fact-agra-yamuna", "scene-4-purandar-agra-fact-year-label-gap"])
            ],
            questions: [
                ChapterKnowledgeQuestion(
                    id: "scene-4-purandar-agra-knowledge-question-forts", kind: .numericCount,
                    prompt: "How many forts were included in the Treaty of Purandar’s transfer term?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-forts-choice-2", text: "Twenty-three"),
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-forts-choice-3", text: "Thirty-three"),
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-forts-choice-1", text: "Thirteen")
                    ],
                    correctChoiceID: "scene-4-purandar-agra-knowledge-question-forts-choice-2",
                    claimIDs: ["scene-4-purandar-agra-fact-twenty-three-forts"],
                    requiredBeatIDs: ["scene-4-purandar-agra-story"],
                    explanation: "The treaty term named twenty-three forts. This is not the total number of forts in the whole kingdom.",
                    hints: ["Read the number attached to this treaty, not to all of Swaraj."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-4-purandar-agra-knowledge-question-year-gap", kind: .numericYearLabelGap,
                    prompt: "Purandar is labelled 1665 and the Agra return 1666. What is 1666 − 1665?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-year-gap-choice-3", text: "Three"),
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-year-gap-choice-1", text: "One"),
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-year-gap-choice-2", text: "Two")
                    ],
                    correctChoiceID: "scene-4-purandar-agra-knowledge-question-year-gap-choice-1",
                    claimIDs: ["scene-4-purandar-agra-fact-treaty-1665", "scene-4-purandar-agra-fact-return-1666", "scene-4-purandar-agra-fact-year-label-gap"],
                    requiredBeatIDs: ["scene-4-purandar-agra-meaning", "scene-4-purandar-agra-memory", "scene-4-purandar-agra-story"],
                    explanation: "The labels differ by one. Year labels alone do not give an exact elapsed duration.",
                    hints: ["1666 is the next year label after 1665."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-4-purandar-agra-knowledge-question-sambhaji", kind: .identity,
                    prompt: "Which member of Shivaji Maharaj’s family accompanied him to Agra?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-sambhaji-choice-2", text: "His mother Jijabai"),
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-sambhaji-choice-3", text: "His father Shahaji"),
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-sambhaji-choice-1", text: "His son Sambhaji")
                    ],
                    correctChoiceID: "scene-4-purandar-agra-knowledge-question-sambhaji-choice-1",
                    claimIDs: ["scene-4-purandar-agra-fact-sambhaji"],
                    requiredBeatIDs: ["scene-4-purandar-agra-memory"],
                    explanation: "His son Sambhaji accompanied him on the journey to Agra.",
                    hints: ["The chapter names the son who travelled with him."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-4-purandar-agra-knowledge-question-river", kind: .geography,
                    prompt: "Agra is on the banks of which river?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-river-choice-1", text: "Yamuna"),
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-river-choice-2", text: "Godavari"),
                        ChapterKnowledgeChoice(
                            id: "scene-4-purandar-agra-knowledge-question-river-choice-3", text: "Krishna")
                    ],
                    correctChoiceID: "scene-4-purandar-agra-knowledge-question-river-choice-1",
                    claimIDs: ["scene-4-purandar-agra-fact-agra-yamuna"],
                    requiredBeatIDs: ["scene-4-purandar-agra-meaning"],
                    explanation: "Agra lies on the Yamuna. Present-day Uttar Pradesh helps us locate the city today.",
                    hints: ["Find the river name in the Agra place fact."],
                    retryFeedback: "Let’s look at the clue and try again.")
            ])
    ]
}
