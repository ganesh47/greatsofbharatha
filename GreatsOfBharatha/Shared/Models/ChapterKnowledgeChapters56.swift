import Foundation

/// Original child teaching copy. Final copy approval remains explicit in the shared catalog.
enum ChapterKnowledgeChapters56 {
    static let definitions: [ChapterKnowledgeDefinition] = [
        ChapterKnowledgeDefinition(
            sceneID: "scene-5-rajgad-recovery",
            claims: [
                ChapterKnowledgeClaim(
                    id: "scene-5-rajgad-recovery-fact-rajgad-return", kind: .historical,
                    statement: "Shivaji Maharaj reached Rajgad after leaving custody at Agra.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 25; PDF page 35")
                    ],
                    taughtBeatIDs: ["scene-5-rajgad-recovery-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-5-rajgad-recovery-fact-recaptured-forts", kind: .historical,
                    statement: "The later recovery campaigns regained several forts, including Purandar and Lohagad.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 25; PDF page 35")
                    ],
                    taughtBeatIDs: ["scene-5-rajgad-recovery-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-5-rajgad-recovery-fact-three-named-offices", kind: .historical,
                    statement: "Three named fort offices were Killedar, Sabnis, and Karkhanis; many other people also worked in forts.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 31; PDF page 41")
                    ],
                    taughtBeatIDs: ["scene-5-rajgad-recovery-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-5-rajgad-recovery-fact-stores-care", kind: .historical,
                    statement: "The Karkhanis looked after foodgrain storage and the upkeep of military supplies.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 31; PDF page 41")
                    ],
                    taughtBeatIDs: ["scene-5-rajgad-recovery-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-5-rajgad-recovery-fact-crop-relief", kind: .historical,
                    statement: "Revenue policy allowed relief when crops were lost through excessive rain or drought.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed pp. 29–30; PDF pages 39–40")
                    ],
                    taughtBeatIDs: ["scene-5-rajgad-recovery-meaning"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-5-rajgad-recovery-fact-fort-repair", kind: .historical,
                    statement: "Keeping forts ready included building and repairs, food storage, and maintaining supplies.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 31; PDF page 41")
                    ],
                    taughtBeatIDs: ["scene-5-rajgad-recovery-meaning"], reviewStatus: .approved)
            ],
            beats: [
                ChapterKnowledgeBeat(
                    id: "scene-5-rajgad-recovery-story", title: "The story",
                    text: """
                    After a difficult time in Agra, Shivaji Maharaj did not give up. He returned to Rajgad, rebuilt his \
                    strength, reorganized, and grew stronger again.
                    """,
                    claimIDs: ["scene-5-rajgad-recovery-fact-rajgad-return", "scene-5-rajgad-recovery-fact-recaptured-forts"]),
                ChapterKnowledgeBeat(
                    id: "scene-5-rajgad-recovery-memory", title: "Remember this",
                    text: """
                    After Agra, Shivaji Maharaj rebuilt strength, reorganized, and returned to growth. Rajgad now has a \
                    second memory hook: Comeback. Rebuilding strength and reorganizing mean steady recovery after a \
                    setback. This happened after the return from Agra.

                    The next facts describe wider Swaraj governance across Shivaji Maharaj’s rule. They help us explore \
                    the continuing work of managing forts.
                    """,
                    claimIDs: ["scene-5-rajgad-recovery-fact-three-named-offices", "scene-5-rajgad-recovery-fact-stores-care"]),
                ChapterKnowledgeBeat(
                    id: "scene-5-rajgad-recovery-meaning", title: "Why it matters",
                    text: """
                    Recovery matters because strength can be rebuilt through steady organization, not only dramatic \
                    moments.

                    These are wider Swaraj policies across his rule. Revenue is money a government collects, such as a \
                    tax. Relief can reduce or remove a payment. Drought means a long period with too little water.
                    """,
                    claimIDs: ["scene-5-rajgad-recovery-fact-crop-relief", "scene-5-rajgad-recovery-fact-fort-repair"])
            ],
            questions: [
                ChapterKnowledgeQuestion(
                    id: "scene-5-rajgad-recovery-knowledge-question-offices", kind: .numericCount,
                    prompt: "How many fort offices are named in our list: Killedar, Sabnis, and Karkhanis?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-offices-choice-1", text: "Two"),
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-offices-choice-2", text: "Three"),
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-offices-choice-3", text: "Four")
                    ],
                    correctChoiceID: "scene-5-rajgad-recovery-knowledge-question-offices-choice-2",
                    claimIDs: ["scene-5-rajgad-recovery-fact-three-named-offices"],
                    requiredBeatIDs: ["scene-5-rajgad-recovery-memory"],
                    explanation: "The list names three offices. Many other people also helped a fort work.",
                    hints: ["Count the three job names, not all the people living in a fort."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-5-rajgad-recovery-knowledge-question-stores", kind: .application,
                    prompt: "A fort needs its grain kept safely and supplies maintained. Which named office fits this task?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-stores-choice-2", text: "Killedar"),
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-stores-choice-3", text: "Sabnis"),
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-stores-choice-1", text: "Karkhanis")
                    ],
                    correctChoiceID: "scene-5-rajgad-recovery-knowledge-question-stores-choice-1",
                    claimIDs: ["scene-5-rajgad-recovery-fact-three-named-offices", "scene-5-rajgad-recovery-fact-stores-care"],
                    requiredBeatIDs: ["scene-5-rajgad-recovery-memory"],
                    explanation: "The Karkhanis looked after foodgrain stores and military supplies.",
                    hints: ["Look for the fort’s stores manager in the teaching card."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-5-rajgad-recovery-knowledge-question-crop-relief", kind: .application,
                    prompt: "A village loses its crops in a drought. Which response matches the revenue policy taught here?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-crop-relief-choice-1", text: "Allow relief in the revenue payment"),
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-crop-relief-choice-2", text: "Collect more than the fixed amount"),
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-crop-relief-choice-3", text: "Ignore the crop loss")
                    ],
                    correctChoiceID: "scene-5-rajgad-recovery-knowledge-question-crop-relief-choice-1",
                    claimIDs: ["scene-5-rajgad-recovery-fact-crop-relief"],
                    requiredBeatIDs: ["scene-5-rajgad-recovery-meaning"],
                    explanation: """
                    The policy allowed revenue relief for crop loss from drought or excessive rain. This shows care for \
                    farming communities.
                    """,
                    hints: ["Recall how the policy responded to failed crops."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-5-rajgad-recovery-knowledge-question-recovery", kind: .identity,
                    prompt: "Which fort named in this chapter was regained during the recovery campaigns?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-recovery-choice-3", text: "Raigad"),
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-recovery-choice-1", text: "Purandar"),
                        ChapterKnowledgeChoice(
                            id: "scene-5-rajgad-recovery-knowledge-question-recovery-choice-2", text: "Shivneri")
                    ],
                    correctChoiceID: "scene-5-rajgad-recovery-knowledge-question-recovery-choice-1",
                    claimIDs: ["scene-5-rajgad-recovery-fact-recaptured-forts"],
                    requiredBeatIDs: ["scene-5-rajgad-recovery-story"],
                    explanation: "Purandar is one of the forts named in the recovery account, along with Lohagad.",
                    hints: ["Look again at the examples of regained forts."],
                    retryFeedback: "Let’s look at the clue and try again.")
            ]),
        ChapterKnowledgeDefinition(
            sceneID: "scene-6-raigad-coronation",
            claims: [
                ChapterKnowledgeClaim(
                    id: "scene-6-raigad-coronation-fact-coronation-date", kind: .historical,
                    statement: "Shivaji Maharaj was crowned at Raigad on 6 June 1674.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 26; PDF page 36"),
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed p. 59; PDF page 69: year 1674")
                    ],
                    taughtBeatIDs: ["scene-6-raigad-coronation-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-6-raigad-coronation-fact-chhatrapati", kind: .historical,
                    statement: "The coronation formally presented Shivaji Maharaj as Chhatrapati, an independent sovereign ruler.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 26; PDF page 36")
                    ],
                    taughtBeatIDs: ["scene-6-raigad-coronation-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-6-raigad-coronation-fact-eight-ministers", kind: .historical,
                    statement: "The Ashtapradhan Mandal was a council of eight ministers responsible for different departments.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 29; PDF page 39"),
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed p. 70; PDF page 80")
                    ],
                    taughtBeatIDs: ["scene-6-raigad-coronation-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-6-raigad-coronation-fact-coin-materials", kind: .historical,
                    statement: "Two coin examples associated with the coronation are the gold Hon and the copper Shivrai.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 26; PDF page 36")
                    ],
                    taughtBeatIDs: ["scene-6-raigad-coronation-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-6-raigad-coronation-fact-capital-features", kind: .siteFeature,
                    statement: "Raigad included a palace, marketplace, rainwater-harvesting systems, and government facilities.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "icomos-2025",
                            locator: "printed p. 94; PDF page 3: Raigad")
                    ],
                    taughtBeatIDs: ["scene-6-raigad-coronation-meaning"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-6-raigad-coronation-fact-amatya-accounts", kind: .historical,
                    statement: "The Amatya’s work included keeping the accounts of the state.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std7",
                            locator: "printed p. 29; PDF page 39"),
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed p. 70; PDF page 80")
                    ],
                    taughtBeatIDs: ["scene-6-raigad-coronation-meaning"], reviewStatus: .approved)
            ],
            beats: [
                ChapterKnowledgeBeat(
                    id: "scene-6-raigad-coronation-story", title: "The story",
                    text: """
                    At Raigad in 1674, Shivaji Maharaj was crowned Chhatrapati in a coronation, or crowning ceremony. It \
                    marked Swarajya — self-rule for the people.

                    Sovereign means a ruler who governs independently.
                    """,
                    claimIDs: ["scene-6-raigad-coronation-fact-coronation-date", "scene-6-raigad-coronation-fact-chhatrapati"]),
                ChapterKnowledgeBeat(
                    id: "scene-6-raigad-coronation-memory", title: "Remember this",
                    text: """
                    At Raigad in 1674, Shivaji Maharaj was crowned Chhatrapati in a coronation, or crowning ceremony, \
                    for Swarajya. First came the return from Agra, then rebuilding at Rajgad, and then the coronation at \
                    Raigad in 1674. Coronation means a crowning ceremony. Swarajya means self-rule, with responsibility \
                    and care for people.
                    """,
                    claimIDs: ["scene-6-raigad-coronation-fact-eight-ministers", "scene-6-raigad-coronation-fact-coin-materials"]),
                ChapterKnowledgeBeat(
                    id: "scene-6-raigad-coronation-meaning", title: "Why it matters",
                    text: """
                    Raigad matters because the coronation shows the big idea of Swarajya and the duty to care for \
                    people.

                    Accounts are written records of money received and spent. They help a government keep track of its \
                    money.
                    """,
                    claimIDs: ["scene-6-raigad-coronation-fact-capital-features", "scene-6-raigad-coronation-fact-amatya-accounts"])
            ],
            questions: [
                ChapterKnowledgeQuestion(
                    id: "scene-6-raigad-coronation-knowledge-question-ministers", kind: .numericCount,
                    prompt: "How many ministers were in the Ashtapradhan Mandal?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-ministers-choice-3", text: "Ten"),
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-ministers-choice-1", text: "Six"),
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-ministers-choice-2", text: "Eight")
                    ],
                    correctChoiceID: "scene-6-raigad-coronation-knowledge-question-ministers-choice-2",
                    claimIDs: ["scene-6-raigad-coronation-fact-eight-ministers"],
                    requiredBeatIDs: ["scene-6-raigad-coronation-memory"],
                    explanation: "Ashtapradhan Mandal means the council of eight ministers. Their departments had different jobs.",
                    hints: ["The chapter gives the council’s number and its jobs together."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-6-raigad-coronation-knowledge-question-shivrai", kind: .material,
                    prompt: "Which material belongs to the Shivrai coin example?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-shivrai-choice-1", text: "Copper"),
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-shivrai-choice-2", text: "Gold"),
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-shivrai-choice-3", text: "Silver")
                    ],
                    correctChoiceID: "scene-6-raigad-coronation-knowledge-question-shivrai-choice-1",
                    claimIDs: ["scene-6-raigad-coronation-fact-coin-materials"],
                    requiredBeatIDs: ["scene-6-raigad-coronation-memory"],
                    explanation: "The Shivrai example is copper; the Hon example is gold.",
                    hints: ["Match each named coin to its material in the fact card."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-6-raigad-coronation-knowledge-question-year", kind: .numericDate,
                    prompt: "Which year belongs to the coronation at Raigad?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-year-choice-2", text: "1666"),
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-year-choice-3", text: "1674"),
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-year-choice-1", text: "1665")
                    ],
                    correctChoiceID: "scene-6-raigad-coronation-knowledge-question-year-choice-3",
                    claimIDs: ["scene-6-raigad-coronation-fact-coronation-date"],
                    requiredBeatIDs: ["scene-6-raigad-coronation-story"],
                    explanation: "The coronation took place at Raigad in 1674. Its full date is 6 June 1674.",
                    hints: ["It comes after Purandar, Agra, and the recovery phase on the story timeline."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-6-raigad-coronation-knowledge-question-accounts", kind: .application,
                    prompt: "Which task belongs to the Amatya?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-accounts-choice-2", text: "Looking after a fort’s grain store"),
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-accounts-choice-3", text: "Organising the army"),
                        ChapterKnowledgeChoice(
                            id: "scene-6-raigad-coronation-knowledge-question-accounts-choice-1", text: "Keeping the state’s accounts")
                    ],
                    correctChoiceID: "scene-6-raigad-coronation-knowledge-question-accounts-choice-1",
                    claimIDs: ["scene-6-raigad-coronation-fact-amatya-accounts"],
                    requiredBeatIDs: ["scene-6-raigad-coronation-meaning"],
                    explanation: "The Amatya kept the state’s accounts. Different offices had different responsibilities.",
                    hints: ["Look for the job that uses records of money and revenue."],
                    retryFeedback: "Let’s look at the clue and try again.")
            ])
    ]
}
