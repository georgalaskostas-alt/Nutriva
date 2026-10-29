import SwiftUI

struct FoodEntry: Identifiable, Codable {
    var id = UUID()
    var name: String
    var calories: Int
    var protein: Int
}

@MainActor
final class FoodDiary: ObservableObject {
    @Published var entries: [FoodEntry] = [] {
        didSet { save() }
    }
    let calorieTarget = 2100
    let proteinTarget = 160

    init() {
        if let data = UserDefaults.standard.data(forKey: "nutriva.entries"),
           let decoded = try? JSONDecoder().decode([FoodEntry].self, from: data) {
            entries = decoded
        }
    }

    var calories: Int { entries.reduce(0) { $0 + $1.calories } }
    var protein: Int { entries.reduce(0) { $0 + $1.protein } }

    func add(name: String, calories: Int, protein: Int) {
        entries.append(FoodEntry(name: name, calories: calories, protein: protein))
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
                            .onChange(of: foodName) { _, _ in estimate = nil; mealItems = []; calories = ""; protein = "" }
                        Button("Υπολόγισε αυτόματα") {
                            let result = LocalNutritionDatabase.estimateMeal(foodName)
                            estimate = result?.total
                            mealItems = result?.items ?? []
                            if let estimate {
                                calories = String(estimate.calories)
                                protein = String(estimate.protein)
                            }
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
                        Button("Add food") {
                            guard let kcal = Int(calories), let grams = Int(protein),
                                  kcal >= 0, grams >= 0 else { return }
                            let trimmed = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            diary.add(name: trimmed, calories: kcal, protein: grams)
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
