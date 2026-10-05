import SwiftUI
import CoreData

struct EntryDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var entry: CraftEntry
    @State private var showingEditView = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let photoData = entry.photo, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // C6: Share Photo using ShareLink
                    ShareLink(
                        item: Image(uiImage: uiImage),
                        preview: SharePreview(entry.title ?? "Craft Photo", image: Image(uiImage: uiImage))
                    ) {
                        Label("Share Photo", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
                }

                HStack {
                    Text(entry.title ?? "Untitled")
                        .font(.largeTitle)
                        .bold()

                    Spacer()

                    // C4: Favorites Star Toggle Persisted in Core Data
                    Button {
                        entry.isFavorite.toggle()
                        try? viewContext.save()
                    } label: {
                        Image(systemName: entry.isFavorite ? "star.fill" : "star")
                            .font(.title)
                            .foregroundStyle(entry.isFavorite ? .yellow : .gray)
                    }
                }

                Text(entry.craftType ?? "")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                // M1: Artisan Name Display
                if let artisan = entry.artisanName, !artisan.isEmpty {
                    Text("Artisan: \(artisan)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let date = entry.date {
                    Text(date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                if let notes = entry.notes, !notes.isEmpty {
                    Text("Notes")
                        .font(.headline)
                    Text(notes)
                        .font(.body)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        // M2: Edit Entry Trigger
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditEntryView(entry: entry)
        }
    }
}
