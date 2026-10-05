import SwiftUI
import CoreData

struct SummaryView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CraftEntry.title, ascending: true)],
        animation: .default)
    private var allEntries: FetchedResults<CraftEntry>

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Craft Distribution")) {
                    ForEach(crafts, id: \.self) { craft in
                        let count = countForCraft(craft)
                        HStack {
                            Text(craft)
                                .font(.body)
                            Spacer()
                            Text("\(count)")
                                .font(.headline)
                                .foregroundStyle(count > 0 ? .primary : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(count > 0 ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }

                Section(header: Text("Total Stats")) {
                    HStack {
                        Text("Total Journal Entries")
                        Spacer()
                        Text("\(allEntries.count)")
                            .bold()
                    }
                    HStack {
                        Text("Favorite Entries")
                        Spacer()
                        Text("\(allEntries.filter { $0.isFavorite }.count)")
                            .bold()
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .navigationTitle("Craft Summary")
        }
    }

    private func countForCraft(_ craft: String) -> Int {
        allEntries.filter { $0.craftType == craft }.count
    }
}
