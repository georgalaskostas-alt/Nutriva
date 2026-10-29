import SwiftUI

struct FoodEntry: Identifiable, Codable {
    var id = UUID()
    var name: String
    var calories: Int
    var protein: Int
    var recordedAt: Date = Date()
    var carbohydrates: Double? = nil
    var fat: Double? = nil
    var fiber: Double? = nil

    enum CodingKeys: String, CodingKey {
        case id, name, calories, protein, recordedAt, carbohydrates, fat, fiber
    }

    init(id: UUID = UUID(), name: String, calories: Int, protein: Int,
         recordedAt: Date = Date(), carbohydrates: Double? = nil,
         fat: Double? = nil, fiber: Double? = nil) {
        self.id = id; self.name = name; self.calories = calories
        self.protein = protein; self.recordedAt = recordedAt
        self.carbohydrates = carbohydrates; self.fat = fat; self.fiber = fiber
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        calories = try c.decode(Int.self, forKey: .calories)
        protein = try c.decode(Int.self, forKey: .protein)
        recordedAt = try c.decodeIfPresent(Date.self, forKey: .recordedAt) ?? Date()
        carbohydrates = try c.decodeIfPresent(Double.self, forKey: .carbohydrates)
        fat = try c.decodeIfPresent(Double.self, forKey: .fat)
        fiber = try c.decodeIfPresent(Double.self, forKey: .fiber)
    }
}

@MainActor
final class FoodDiary: ObservableObject {
    @Published var entries: [FoodEntry] = [] {
        didSet { save() }
    }
    @Published var rememberedMeals: [FoodEntry] = [] {
        didSet { saveRemembered() }
    }
    let calorieTarget = 2100
    let proteinTarget = 160

    init() {
        if let data = UserDefaults.standard.data(forKey: "nutriva.entries"),
           let decoded = try? JSONDecoder().decode([FoodEntry].self, from: data) {
            entries = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "nutriva.rememberedMeals"),
           let decoded = try? JSONDecoder().decode([FoodEntry].self, from: data) {
            rememberedMeals = decoded
        }
    }

    var calories: Int { entries.reduce(0) { $0 + $1.calories } }
    var protein: Int { entries.reduce(0) { $0 + $1.protein } }

    func add(name: String, calories: Int, protein: Int) {
        entries.append(FoodEntry(name: name, calories: calories, protein: protein))
    }

    func remember(_ entry: FoodEntry) {
        let key = LocalNutritionDatabase.normalize(entry.name).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        rememberedMeals.removeAll {
            LocalNutritionDatabase.normalize($0.name).trimmingCharacters(in: .whitespacesAndNewlines) == key
        }
        rememberedMeals.append(entry)
    }

    func recalled(_ name: String) -> FoodEntry? {
        let key = LocalNutritionDatabase.normalize(name).trimmingCharacters(in: .whitespacesAndNewlines)
        return rememberedMeals.first {
            LocalNutritionDatabase.normalize($0.name).trimmingCharacters(in: .whitespacesAndNewlines) == key
        }
    }

    private func saveRemembered() {
        if let data = try? JSONEncoder().encode(rememberedMeals) {
            UserDefaults.standard.set(data, forKey: "nutriva.rememberedMeals")
        }
    }

    func remove(at offsets: IndexSet) { entries.remove(atOffsets: offsets) }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "nutriva.entries")
        }
    }
}

struct ContentView: View {
    @StateObject private var diary = FoodDiary()
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var estimate: NutritionEstimate?
    @State private var mealItems: [NutritionEstimate] = []
    @State private var rememberMeal = true
    @State private var mealHint = ""

    var body: some View {
        TabView {
            NavigationStack {
                Form {
                    Section("Today's progress") {
                        LabeledContent("Calories", value: "\(diary.calories) / \(diary.calorieTarget) kcal")
                        ProgressView(value: min(Double(diary.calories) / Double(diary.calorieTarget), 1))
                        LabeledContent("Protein", value: "\(diary.protein) / \(diary.proteinTarget) g")
                        ProgressView(value: min(Double(diary.protein) / Double(diary.proteinTarget), 1))
                    }
                    Section("Log a meal") {
                        TextField("Food description", text: $foodName)
                            .onChange(of: foodName) { _, _ in estimate = nil; mealItems = []; calories = ""; protein = ""; mealHint = "" }
                        Button("Υπολόγισε αυτόματα") {
                            let result = LocalNutritionDatabase.estimateMeal(foodName)
                            estimate = result?.total
                            mealItems = result?.items ?? []
                            if let estimate {
                                calories = String(estimate.calories)
                                protein = String(estimate.protein)
                                mealHint = "Ενδεικτικές τιμές. Έλεγξε ποσότητες, λάδι και τρόπο παρασκευής."
                            } else if let saved = diary.recalled(foodName) {
                                calories = String(saved.calories)
                                protein = String(saved.protein)
                                mealHint = "Ανακλήθηκε προηγούμενη επιβεβαιωμένη καταχώριση. Έλεγξε αν η μερίδα είναι ίδια."
                            } else {
                                calories = ""; protein = ""
                                mealHint = "Δεν μπορώ να υπολογίσω αξιόπιστα το γεύμα. Δώσε ποσότητες ανά συστατικό ή συμπλήρωσε τις τιμές χειροκίνητα. Για μακαρόνια με κιμά χρειάζονται γραμμάρια μαγειρεμένων ζυμαρικών, κιμά, τυριού και λαδιού."
                            }
                        }
                        if !mealHint.isEmpty {
                            Text(mealHint).font(.footnote).foregroundStyle(.secondary)
                        }
                        if let estimate {
                            ForEach(Array(mealItems.enumerated()), id: \.offset) { _, item in
                                Text("\(item.name): \(item.calories) kcal · \(item.protein) g πρωτεΐνη")
                                    .font(.subheadline)
                            }
                            Text("Σύνολο: \(estimate.calories) kcal · \(estimate.protein) g πρωτεΐνη")
                                .fontWeight(.semibold)
                            Text("Υδατάνθρακες: \(estimate.carbohydrates.formatted()) g · Λιπαρά: \(estimate.fat.formatted()) g")
                            Text(estimate.note).font(.caption).foregroundStyle(.secondary)
                        } else if !foodName.isEmpty {
                            Text("Για σύνθετα ή άγνωστα γεύματα χρειάζονται περισσότερα στοιχεία. Γράψε κάθε συστατικό με ποσότητα, π.χ. «200 γραμμάρια κοτόπουλο, 150 γραμμάρια ρύζι, 100 γραμμάρια σαλάτα».")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        TextField("Calories (kcal)", text: $calories)
                            .keyboardType(.numberPad)
                        TextField("Protein (g)", text: $protein)
                            .keyboardType(.numberPad)
                        Toggle("Να θυμάται αυτό το γεύμα", isOn: $rememberMeal)
                        Button("Add food") {
                            guard let kcal = Int(calories), let grams = Int(protein),
                                  kcal >= 0, grams >= 0 else { return }
                            let trimmed = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            let entry = FoodEntry(name: trimmed, calories: kcal, protein: grams,
                                                  carbohydrates: estimate?.carbohydrates,
                                                  fat: estimate?.fat, fiber: estimate?.fiber)
                            diary.entries.append(entry)
                            if rememberMeal { diary.remember(entry) }
                            foodName = ""; calories = ""; protein = ""; estimate = nil; mealItems = []
                        }
                    }
                    Section("Food diary") {
                        if diary.entries.isEmpty {
                            Text("No meals recorded yet").foregroundStyle(.secondary)
                        }
                        ForEach(diary.entries) { entry in
                            VStack(alignment: .leading) {
                                Text(entry.name)
                                Text("\(entry.calories) kcal · \(entry.protein) g protein")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(entry.recordedAt, format: .dateTime.day().month().year().hour().minute())
                                    .font(.caption2).foregroundStyle(.secondary)
                                if let carbs = entry.carbohydrates, let fat = entry.fat {
                                    Text("Υδατάνθρακες: \(carbs.formatted()) g · Λιπαρά: \(fat.formatted()) g")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: diary.remove)
                    }
                }
                .navigationTitle("Nutriva")
            }
            .tabItem { Label("Today", systemImage: "house") }

            NavigationStack {
                List {
                    Section("Example meal plan — not personalized yet") {
                        Text("Breakfast: Greek yogurt, oats and fruit")
                        Text("Lunch: Chicken, rice and salad")
                        Text("Snack: Fruit and nuts")
                        Text("Dinner: Eggs, wholegrain bread and vegetables")
                    }
                    Section {
                        Text("AI-based plans will be enabled after the secure backend is connected.")
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Meal Plan")
            }
            .tabItem { Label("Plan", systemImage: "calendar") }

            NavigationStack {
                LocalCoachView(diary: diary)
            }
            .tabItem { Label("AI", systemImage: "sparkles") }
        }
        .tint(.green)
    }
}
