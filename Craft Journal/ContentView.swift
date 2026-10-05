import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CraftEntry.date, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<CraftEntry>

    @State private var showingAddEntry = false
    @State private var showingSummary = false
    @State private var showFavoritesOnly = false
    @State private var searchText = ""
    @State private var selectedCraftFilter = "All"

    private var filteredEntries: [CraftEntry] {
        entries.filter { entry in
            let matchesSearch = searchText.isEmpty ||
                (entry.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.artisanName?.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesCraft = selectedCraftFilter == "All" || entry.craftType == selectedCraftFilter
            let matchesFavorite = !showFavoritesOnly || entry.isFavorite

            return matchesSearch && matchesCraft && matchesFavorite
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredEntries.isEmpty {
                    ContentUnavailableView(
                        "No Entries Found",
                        systemImage: "book.closed",
                        description: Text("Tap '+' to log a new craft entry or adjust your filters.")
                    )
                } else {
                    List {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: EntryDetailView(entry: entry)) {
                                EntryRowView(entry: entry)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    toggleFavorite(for: entry)
                                } label: {
                                    Label(
                                        entry.isFavorite ? "Unfavorite" : "Favorite",
                                        systemImage: entry.isFavorite ? "star.slash" : "star.fill"
                                    )
                                }
                                .tint(.yellow)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("Craft Journal")
            .searchable(text: $searchText, prompt: "Search title or artisan")
            .toolbar {
                // Leading Toolbar: Summary View Icon, Favorites Filter (Star), and Craft Filter
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Button {
                            showingSummary = true
                        } label: {
                            Image(systemName: "chart.pie")
                        }

                        Button {
                            showFavoritesOnly.toggle()
                        } label: {
                            Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                                .foregroundStyle(showFavoritesOnly ? .yellow : .accentColor)
                        }

                        Menu {
                            Picker("Craft Filter", selection: $selectedCraftFilter) {
                                Text("All Crafts").tag("All")
                                ForEach(crafts, id: \.self) { craft in
                                    Text(craft).tag(craft)
                                }
                            }
                        } label: {
                            Image(systemName: selectedCraftFilter == "All"
                                  ? "line.3.horizontal.decrease.circle"
                                  : "line.3.horizontal.decrease.circle.fill")
                        }
                    }
                }

                // Trailing Toolbar: Add Entry Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView()
            }
            .sheet(isPresented: $showingSummary) {
                SummaryView()
            }
        }
    }

    private func toggleFavorite(for entry: CraftEntry) {
        withAnimation {
            entry.isFavorite.toggle()
            try? viewContext.save()
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredEntries[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

// MARK: - Entry Row Component
struct EntryRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var entry: CraftEntry

    var body: some View {
        HStack(spacing: 12) {
            if let photoData = entry.photo, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title ?? "Untitled")
                    .font(.headline)

                HStack(spacing: 6) {
                    if let craft = entry.craftType, !craft.isEmpty {
                        Text(craft)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }

                    if let artisan = entry.artisanName, !artisan.isEmpty {
                        Text(artisan)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Interactive Favorite Star Button on Card (.borderless prevents triggering row tap)
            Button {
                withAnimation {
                    entry.isFavorite.toggle()
                    try? viewContext.save()
                }
            } label: {
                Image(systemName: entry.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(entry.isFavorite ? .yellow : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }
}
