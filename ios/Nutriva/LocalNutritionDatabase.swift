import Foundation

struct NutritionEstimate {
    let name: String
    let grams: Double
    let calories: Int
    let protein: Int
    let carbohydrates: Double
    let fat: Double
    let fiber: Double?
    let note: String
}

struct NutritionFood {
    let aliases: [String]
    let kcal100: Double
    let protein100: Double
    let carbs100: Double
    let fat100: Double
    let fiber100: Double?
    let defaultGrams: Double?
    let servingDescription: String
}

enum LocalNutritionDatabase {
    // Approximate reference values per 100 g. Cooked/raw state matters.
    static let foods: [NutritionFood] = [
        .init(aliases: ["μηλο", "apple"], kcal100: 52, protein100: 0.3, carbs100: 13.8, fat100: 0.2, fiber100: 2.4, defaultGrams: 180, servingDescription: "μέτριο μήλο ~180 g"),
        .init(aliases: ["μπανανα", "banana"], kcal100: 89, protein100: 1.1, carbs100: 22.8, fat100: 0.3, fiber100: 2.6, defaultGrams: 120, servingDescription: "μέτρια μπανάνα ~120 g"),
        .init(aliases: ["κοτοπουλο", "chicken"], kcal100: 165, protein100: 31, carbs100: 0, fat100: 3.6, fiber100: 0, defaultGrams: nil, servingDescription: "μαγειρεμένο στήθος χωρίς πέτσα"),
        .init(aliases: ["ρυζι", "rice"], kcal100: 130, protein100: 2.7, carbs100: 28.2, fat100: 0.3, fiber100: 0.4, defaultGrams: nil, servingDescription: "βρασμένο ρύζι"),
        .init(aliases: ["αυγο", "egg"], kcal100: 143, protein100: 12.6, carbs100: 0.7, fat100: 9.5, fiber100: 0, defaultGrams: 50, servingDescription: "ένα μεγάλο αυγό ~50 g χωρίς κέλυφος"),
        .init(aliases: ["γιαουρτι", "yogurt"], kcal100: 73, protein100: 10, carbs100: 3.9, fat100: 2, fiber100: 0, defaultGrams: nil, servingDescription: "ενδεικτικό στραγγιστό 2%, διαφέρει ανά μάρκα"),
        .init(aliases: ["σαλατα", "salad"], kcal100: 25, protein100: 1.2, carbs100: 4.5, fat100: 0.3, fiber100: 1.8, defaultGrams: nil, servingDescription: "απλή σαλάτα χωρίς λάδι ή σος"),
        .init(aliases: ["ελαιολαδο", "λαδι", "olive oil"], kcal100: 884, protein100: 0, carbs100: 0, fat100: 100, fiber100: 0, defaultGrams: nil, servingDescription: "ελαιόλαδο"),
        .init(aliases: ["βρωμη", "oats"], kcal100: 389, protein100: 16.9, carbs100: 66.3, fat100: 6.9, fiber100: 10.6, defaultGrams: nil, servingDescription: "ξηρή βρώμη")
    ]

    static func estimateMeal(_ input: String) -> (items: [NutritionEstimate], total: NutritionEstimate)? {
        let cleaned = normalize(input)
        let segments = cleaned
            .replacingOccurrences(of: #"\\s+και\\s+"#, with: ",", options: .regularExpression)
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !segments.isEmpty else { return nil }
        var items: [NutritionEstimate] = []
        for segment in segments {
            guard let item = estimate(segment) else { return nil }
            items.append(item)
        }
        let total = NutritionEstimate(
            name: input,
            grams: items.reduce(0) { $0 + $1.grams },
            calories: items.reduce(0) { $0 + $1.calories },
            protein: items.reduce(0) { $0 + $1.protein },
            carbohydrates: items.reduce(0) { $0 + $1.carbohydrates },
            fat: items.reduce(0) { $0 + $1.fat },
            fiber: items.allSatisfy { $0.fiber != nil } ? items.reduce(0) { $0 + ($1.fiber ?? 0) } : nil,
            note: items.map { $0.note }.joined(separator: "\n")
        )
        return (items, total)
    }

    static func normalize(_ input: String) -> String {
        input.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "el_GR")).lowercased()
    }

    static func estimate(_ input: String) -> NutritionEstimate? {
        let normalized = normalize(input)
        // Only one recognizable food per entry. Mixed meals need ingredient-level quantities.
        let matches = foods.filter { food in
            food.aliases.contains { normalized.contains($0) }
        }
        guard matches.count == 1, let food = matches.first else { return nil }
        let grams: Double
        let note: String
        if let range = normalized.range(of: #"\b\d+(?:[.,]\d+)?\s*(?:g|gr|γρ|γραμμαρια|γραμμα|γραμ)\b"#, options: .regularExpression) {
            let number = String(normalized[range]).prefix { $0.isNumber || $0 == "." || $0 == "," }
            guard let parsed = Double(number.replacingOccurrences(of: ",", with: ".")), parsed > 0, parsed <= 3000 else { return nil }
            grams = parsed
            note = "Εκτίμηση με βάση \(Int(grams)) g — \(food.servingDescription)."
        } else if let serving = food.defaultGrams {
            grams = serving
            note = "Υποτέθηκε \(food.servingDescription). Επιβεβαίωσε τη μερίδα."
        } else {
            return nil
        }
        let ratio = grams / 100
        return NutritionEstimate(name: input, grams: grams, calories: Int((food.kcal100 * ratio).rounded()),
                                 protein: Int((food.protein100 * ratio).rounded()),
                                 carbohydrates: (food.carbs100 * ratio * 10).rounded() / 10,
                                 fat: (food.fat100 * ratio * 10).rounded() / 10,
                                 fiber: food.fiber100.map { ($0 * ratio * 10).rounded() / 10 },
                                 note: note)
    }
}
