import Foundation

/// Original child teaching copy. Final copy approval remains explicit in the shared catalog.
enum ChapterKnowledgeChapters12 {
    static let definitions: [ChapterKnowledgeDefinition] = [
        ChapterKnowledgeDefinition(
            sceneID: "scene-1-shivneri",
            claims: [
                ChapterKnowledgeClaim(
                    id: "scene-1-shivneri-fact-birth-place", kind: .historical,
                    statement: "Shivaji Maharaj was born at Shivneri Fort.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed pp. 12–13; PDF pages 22–23")
                    ],
                    taughtBeatIDs: ["scene-1-shivneri-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-1-shivneri-fact-junnar", kind: .siteFeature,
                    statement: "Shivneri is a hill fort near Junnar in Pune district.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed p. 12; PDF page 22")
                    ],
                    taughtBeatIDs: ["scene-1-shivneri-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-1-shivneri-fact-parents", kind: .historical,
                    statement: "Jijabai was Shivaji Maharaj’s mother, and Shahaji was his father.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed pp. 12–13; PDF pages 22–23")
                    ],
                    taughtBeatIDs: ["scene-1-shivneri-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-1-shivneri-fact-seven-gates", kind: .siteFeature,
                    statement: "The present-day description of Shivneri identifies seven gates on the way into the fort.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "tourism-shivneri",
                            locator: "architectural highlights: seven gates")
                    ],
                    taughtBeatIDs: ["scene-1-shivneri-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-1-shivneri-fact-water-storage", kind: .siteFeature,
                    statement: "Shivneri has water-storage features, including cisterns and reservoirs.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "icomos-2025",
                            locator: "printed p. 93; PDF page 2: Shivneri water cisterns"),
                        ChapterKnowledgeCitation(
                            sourceID: "tourism-shivneri",
                            locator: "Badami Talav and water sources")
                    ],
                    taughtBeatIDs: ["scene-1-shivneri-meaning"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-1-shivneri-fact-cistern-meaning", kind: .vocabulary,
                    statement: "A cistern is a place built to collect or store water; stored water helps people living in a fort.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "icomos-2025",
                            locator: "printed p. 93; PDF page 2: water cisterns")
                    ],
                    taughtBeatIDs: ["scene-1-shivneri-meaning"], reviewStatus: .approved)
            ],
            beats: [
                ChapterKnowledgeBeat(
                    id: "scene-1-shivneri-story", title: "The story",
                    text: """
                    Shivaji Maharaj's story begins at Shivneri Fort. Jijabai's guidance helped him grow with courage, \
                    care, and responsibility.
                    """,
                    claimIDs: ["scene-1-shivneri-fact-birth-place", "scene-1-shivneri-fact-junnar"]),
                ChapterKnowledgeBeat(
                    id: "scene-1-shivneri-memory", title: "Remember this",
                    text: """
                    Shivaji Maharaj was born at Shivneri Fort, and Jijabai shaped his early values. Shivneri is the \
                    Birth Fort near Junnar. Jijabai's guidance taught courage, care, and responsibility.
                    """,
                    claimIDs: ["scene-1-shivneri-fact-parents", "scene-1-shivneri-fact-seven-gates"]),
                ChapterKnowledgeBeat(
                    id: "scene-1-shivneri-meaning", title: "Why it matters",
                    text: "Shivneri matters because it marks the beginning of the journey and the values Shivaji Maharaj carried forward.",
                    claimIDs: ["scene-1-shivneri-fact-water-storage", "scene-1-shivneri-fact-cistern-meaning"])
            ],
            questions: [
                ChapterKnowledgeQuestion(
                    id: "scene-1-shivneri-knowledge-question-mother", kind: .identity,
                    prompt: "Who was Shivaji Maharaj’s mother?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-mother-choice-1", text: "Jijabai"),
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-mother-choice-2", text: "Saibai"),
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-mother-choice-3", text: "Soyarabai")
                    ],
                    correctChoiceID: "scene-1-shivneri-knowledge-question-mother-choice-1",
                    claimIDs: ["scene-1-shivneri-fact-parents"],
                    requiredBeatIDs: ["scene-1-shivneri-memory"],
                    explanation: "Jijabai was his mother. Shahaji was his father.",
                    hints: ["Recall the mother named in this chapter’s family fact."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-1-shivneri-knowledge-question-junnar", kind: .geography,
                    prompt: "Which town is close to Shivneri?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-junnar-choice-3", text: "Mahabaleshwar"),
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-junnar-choice-1", text: "Junnar"),
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-junnar-choice-2", text: "Agra")
                    ],
                    correctChoiceID: "scene-1-shivneri-knowledge-question-junnar-choice-1",
                    claimIDs: ["scene-1-shivneri-fact-junnar"],
                    requiredBeatIDs: ["scene-1-shivneri-story"],
                    explanation: "Shivneri stands near Junnar in Pune district.",
                    hints: ["Look again at the place name beside Shivneri."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-1-shivneri-knowledge-question-gates", kind: .numericCount,
                    prompt: "How many gates does our present-day Shivneri description name?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-gates-choice-3", text: "Nine"),
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-gates-choice-1", text: "Five"),
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-gates-choice-2", text: "Seven")
                    ],
                    correctChoiceID: "scene-1-shivneri-knowledge-question-gates-choice-2",
                    claimIDs: ["scene-1-shivneri-fact-seven-gates"],
                    requiredBeatIDs: ["scene-1-shivneri-memory"],
                    explanation: "The site description identifies seven gates. This is a feature count, not a date.",
                    hints: ["Find the number in the gate fact."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-1-shivneri-knowledge-question-cistern", kind: .meaning,
                    prompt: "What is a cistern built to do?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-cistern-choice-1", text: "Store water"),
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-cistern-choice-2", text: "Keep written accounts"),
                        ChapterKnowledgeChoice(
                            id: "scene-1-shivneri-knowledge-question-cistern-choice-3", text: "House horses")
                    ],
                    correctChoiceID: "scene-1-shivneri-knowledge-question-cistern-choice-1",
                    claimIDs: ["scene-1-shivneri-fact-water-storage", "scene-1-shivneri-fact-cistern-meaning"],
                    requiredBeatIDs: ["scene-1-shivneri-meaning"],
                    explanation: "A cistern collects or stores water for people to use.",
                    hints: ["The chapter links cisterns with a daily need."],
                    retryFeedback: "Let’s look at the clue and try again.")
            ]),
        ChapterKnowledgeDefinition(
            sceneID: "scene-2-torna-rajgad",
            claims: [
                ChapterKnowledgeClaim(
                    id: "scene-2-torna-rajgad-fact-torna-name", kind: .historical,
                    statement: "Torna is also known as Prachandgad.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed p. 26; PDF page 36")
                    ],
                    taughtBeatIDs: ["scene-2-torna-rajgad-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-2-torna-rajgad-fact-first-capital", kind: .historical,
                    statement: "Rajgad became the first capital of Swaraj.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed p. 27; PDF page 37"),
                        ChapterKnowledgeCitation(
                            sourceID: "icomos-2025",
                            locator: "printed p. 94; PDF page 3: Rajgad")
                    ],
                    taughtBeatIDs: ["scene-2-torna-rajgad-story"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-2-torna-rajgad-fact-former-name", kind: .historical,
                    statement: "The earlier fort name Murumbdeo is associated with the site later named Rajgad.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed p. 27; PDF page 37")
                    ],
                    taughtBeatIDs: ["scene-2-torna-rajgad-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-2-torna-rajgad-fact-named-machis", kind: .siteFeature,
                    statement: "Three named machis at Rajgad are Padmavati, Sanjivani, and Suvela; the fort also has a citadel.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "tourism-rajgad",
                            locator: "features: Padmavati Machi, Sanjivani Machi, Suvela Machi, Balekilla")
                    ],
                    taughtBeatIDs: ["scene-2-torna-rajgad-memory"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-2-torna-rajgad-fact-builders", kind: .historical,
                    statement: "Stone masons, carpenters, blacksmiths, water carriers, and other workers helped build Rajgad.",
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "balbharati-std4",
                            locator: "printed p. 27; PDF page 37")
                    ],
                    taughtBeatIDs: ["scene-2-torna-rajgad-meaning"], reviewStatus: .approved),
                ChapterKnowledgeClaim(
                    id: "scene-2-torna-rajgad-fact-capital-work", kind: .vocabulary,
                    statement: """
                    A capital is a centre for government work. Rajgad included spaces for administration and storage as \
                    well as defence.
                    """,
                    citations: [
                        ChapterKnowledgeCitation(
                            sourceID: "icomos-2025",
                            locator: "printed p. 94; PDF page 3: administrative and storage spaces")
                    ],
                    taughtBeatIDs: ["scene-2-torna-rajgad-meaning"], reviewStatus: .approved)
            ],
            beats: [
                ChapterKnowledgeBeat(
                    id: "scene-2-torna-rajgad-story", title: "The story",
                    text: """
                    Shivaji Maharaj began building Swarajya, or self-rule, through important forts. Torna was an early \
                    win, and Rajgad became a planning home base.
                    """,
                    claimIDs: ["scene-2-torna-rajgad-fact-torna-name", "scene-2-torna-rajgad-fact-first-capital"]),
                ChapterKnowledgeBeat(
                    id: "scene-2-torna-rajgad-memory", title: "Remember this",
                    text: """
                    Torna was an early win, and Rajgad became an early capital, or main home base for planning. Torna is \
                    remembered as the First Big Fort. Rajgad is remembered as the Early Capital and planning base. First \
                    came Shivneri, then the early forts.

                    Here, a machi is a fortified terrace on the hillside. A citadel is the strongly defended inner part \
                    of a fort.
                    """,
                    claimIDs: ["scene-2-torna-rajgad-fact-former-name", "scene-2-torna-rajgad-fact-named-machis"]),
                ChapterKnowledgeBeat(
                    id: "scene-2-torna-rajgad-meaning", title: "Why it matters",
                    text: """
                    These forts matter because the story is not only about winning a fort. It is also about building a \
                    stronger home base.

                    A stone mason shapes and places stone to build things such as walls. Administration means organising \
                    the work of government.
                    """,
                    claimIDs: ["scene-2-torna-rajgad-fact-builders", "scene-2-torna-rajgad-fact-capital-work"])
            ],
            questions: [
                ChapterKnowledgeQuestion(
                    id: "scene-2-torna-rajgad-knowledge-question-torna-name", kind: .identity,
                    prompt: "Which other name belongs to Torna?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-torna-name-choice-3", text: "Purandar"),
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-torna-name-choice-1", text: "Prachandgad"),
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-torna-name-choice-2", text: "Pratapgad")
                    ],
                    correctChoiceID: "scene-2-torna-rajgad-knowledge-question-torna-name-choice-1",
                    claimIDs: ["scene-2-torna-rajgad-fact-torna-name"],
                    requiredBeatIDs: ["scene-2-torna-rajgad-story"],
                    explanation: "Torna is also known as Prachandgad.",
                    hints: ["Read the two names placed together in the story."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-2-torna-rajgad-knowledge-question-machis", kind: .numericCount,
                    prompt: "How many named machis are in our Rajgad list: Padmavati, Sanjivani, and Suvela?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-machis-choice-3", text: "Four"),
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-machis-choice-1", text: "Two"),
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-machis-choice-2", text: "Three")
                    ],
                    correctChoiceID: "scene-2-torna-rajgad-knowledge-question-machis-choice-2",
                    claimIDs: ["scene-2-torna-rajgad-fact-named-machis"],
                    requiredBeatIDs: ["scene-2-torna-rajgad-memory"],
                    explanation: "There are three named machis in this list. Rajgad also has other features, including a citadel.",
                    hints: ["Count the names in the list one at a time."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-2-torna-rajgad-knowledge-question-capital", kind: .meaning,
                    prompt: "What made Rajgad a capital as well as a fort?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-capital-choice-1", text: "Government planning and administration"),
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-capital-choice-2", text: "Only a place to store grain"),
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-capital-choice-3", text: "Only a place to keep horses")
                    ],
                    correctChoiceID: "scene-2-torna-rajgad-knowledge-question-capital-choice-1",
                    claimIDs: ["scene-2-torna-rajgad-fact-first-capital", "scene-2-torna-rajgad-fact-capital-work"],
                    requiredBeatIDs: ["scene-2-torna-rajgad-meaning", "scene-2-torna-rajgad-story"],
                    explanation: "A capital is a centre for government work. Rajgad also had defence and storage spaces.",
                    hints: ["Think about the work of running Swaraj."],
                    retryFeedback: "Let’s look at the clue and try again."),
                ChapterKnowledgeQuestion(
                    id: "scene-2-torna-rajgad-knowledge-question-masons", kind: .application,
                    prompt: "Which job best matches a stone mason helping to build a fort?",
                    choices: [
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-masons-choice-3", text: "Caring for horses"),
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-masons-choice-1", text: "Shaping and placing stone"),
                        ChapterKnowledgeChoice(
                            id: "scene-2-torna-rajgad-knowledge-question-masons-choice-2", text: "Keeping the state’s accounts")
                    ],
                    correctChoiceID: "scene-2-torna-rajgad-knowledge-question-masons-choice-1",
                    claimIDs: ["scene-2-torna-rajgad-fact-builders"],
                    requiredBeatIDs: ["scene-2-torna-rajgad-meaning"],
                    explanation: "A stone mason works with stone. Many kinds of workers helped build Rajgad.",
                    hints: ["The first word in the job name tells you its main material."],
                    retryFeedback: "Let’s look at the clue and try again.")
            ])
    ]
}
