import SwiftUI

struct CoachReply {
    let message: String
    let suggestedFood: FoodEntry?
}

enum LocalNutritionCoach {
    static func reply(to input: String, diary: FoodDiary) -> CoachReply {
        let query = input.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "el_GR")).lowercased()
        let remaining = diary.calorieTarget - diary.calories
        let proteinLeft = max(0, diary.proteinTarget - diary.protein)
        let context = "Έχεις καταχωρίσει \(diary.calories) kcal και \(diary.protein) g πρωτεΐνης. Υπόλοιπο ως προς τον ενδεικτικό στόχο: \(remaining) kcal και \(proteinLeft) g πρωτεΐνης. Αν δεν έχουν καταχωριστεί όλα τα γεύματα, η εικόνα είναι ελλιπής."

        if query.contains("μηλ") || query.contains("apple") {
            let apple = FoodEntry(name: "Μέτριο μήλο (εκτίμηση)", calories: 95, protein: 0)
            return CoachReply(message: "Ναι, ένα μέτριο μήλο είναι μια λογική επιλογή για σνακ (~95 kcal). \(context) Αν πεινάς πολύ, συνδύασέ το με πηγή πρωτεΐνης. Θέλεις να το καταχωρίσεις; Η ποσότητα είναι ενδεικτική.", suggestedFood: apple)
        }
        if query.contains("γλυκ") || query.contains("σοκολατ") {
            return CoachReply(message: "Μπορείς να απολαύσεις και κάτι γλυκό. Διάλεξε μερίδα που σε ικανοποιεί και καταχώρισέ τη. \(context) Αν θέλεις, πες μου ποιο γλυκό και τι ποσότητα.", suggestedFood: nil)
        }
        if query.contains("πρωτειν") || query.contains("πεινα") || query.contains("φαω") || query.contains("γευμα") || query.contains("βραδιν") {
            let idea = proteinLeft > 30 ? "Μια επιλογή είναι γιαούρτι στραγγιστό 2% με φρούτο ή κοτόπουλο με σαλάτα, ανάλογα με την πείνα σου." : "Μια επιλογή είναι φρούτο με γιαούρτι ή ένα ισορροπημένο γεύμα με λαχανικά."
            return CoachReply(message: "\(context) \(idea) Πες μου τι έχεις διαθέσιμο και αν θέλεις σνακ ή πλήρες γεύμα.", suggestedFood: nil)
        }
        return CoachReply(message: "Μπορώ να βοηθήσω με γνωστά τρόφιμα, σνακ και ιδέες γευμάτων. \(context) Δεν έχω ακόμη επαρκή τοπική γνώση για αυτή την ερώτηση. Δώσε μου περισσότερες λεπτομέρειες. Δεν έγινε online κλήση.", suggestedFood: nil)
    }
}

struct LocalCoachView: View {
    @ObservedObject var diary: FoodDiary
    @State private var question = ""
    @State private var answer: CoachReply?
    @State private var confirmation = ""

    var body: some View {
        Form {
            Section("Ρώτησε το Nutriva · Χωρίς tokens") {
                TextField("Π.χ. Μπορώ να φάω ένα μήλο τώρα;", text: $question, axis: .vertical)
                    .lineLimit(2...4)
                Button("Ρώτησε") {
                    let cleaned = question.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleaned.isEmpty else { return }
                    answer = LocalNutritionCoach.reply(to: cleaned, diary: diary)
                    confirmation = ""
                }
            }
            if let answer {
                Section("Nutriva Coach") {
                    Text(answer.message)
                    if let food = answer.suggestedFood {
                        Button("Καταχώρισε: \(food.name)") {
                            diary.add(name: food.name, calories: food.calories, protein: food.protein)
                            self.answer = nil
                            confirmation = "Το γεύμα καταχωρίστηκε."
                        }
                    }
                }
            }
            if !confirmation.isEmpty {
                Section { Text(confirmation).foregroundStyle(.green) }
            }
            Section("Σημείωση") {
                Text("Πρώτη offline έκδοση με τοπικούς κανόνες, όχι ακόμη γλωσσικό μοντέλο. Οι διατροφικές τιμές είναι ενδεικτικές και οι συμβουλές δεν αντικαθιστούν επαγγελματία υγείας.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("AI Coach")
    }
}
