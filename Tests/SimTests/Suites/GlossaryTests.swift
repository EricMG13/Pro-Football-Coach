import Foundation
import ProFootballCoachUI

func runGlossaryTests() {
    suite("Glossary") {
        test("every term is defined once, plainly, and briefly") {
            // 04's copy register: short and plain. The bound is a contract rather than a habit,
            // because a paragraph in a glossary is a manual and nobody reads a manual mid-decision.
            expect(!Glossary.terms.isEmpty, "the glossary is empty")
            expectEqual(Set(Glossary.terms.map(\.term)).count, Glossary.terms.count,
                        "a term is defined twice")
            for entry in Glossary.terms {
                expect(!entry.term.isEmpty, "a term has no name")
                expect(!entry.definition.isEmpty, "\(entry.term) has no definition")
                expect(entry.definition.count <= Glossary.maximumDefinitionCharacters,
                       "\(entry.term) runs to \(entry.definition.count) characters, which is a "
                           + "paragraph rather than a definition")
                expect(entry.definition.hasSuffix("."),
                       "\(entry.term)'s definition is not a sentence")
                expect(!entry.definition.lowercased().contains("lorem"),
                       "\(entry.term) carries placeholder copy")
            }
        }

        test("every area a reader can enter from has something in it") {
            // An area with no terms is a door into an empty room.
            for area in GlossaryArea.allCases {
                expect(!Glossary.terms(in: area).isEmpty,
                       "the \(area.rawValue) area of the glossary is empty")
                let names = Glossary.terms(in: area).map(\.term)
                expectEqual(names, names.sorted(),
                            "the \(area.rawValue) area is not in the order a reader scans")
            }
        }

        test("the words this game invents are the words it explains") {
            // Not every football word — the ones a player meets in *this* product and cannot look up
            // anywhere else.
            for term in ["Call-in", "Scheme fit", "The portal", "NIL", "Dead money", "Redshirt",
                         "Job security", "Depth chart"] {
                expect(Glossary.definition(of: term) != nil,
                       "\(term) is used across the product and defined nowhere")
            }
            expect(Glossary.definition(of: "CALL-IN") != nil,
                   "a lookup is case-sensitive, so a caller has to know how it was typed")
        }
    }
}
