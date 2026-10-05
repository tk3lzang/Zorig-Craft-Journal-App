import SwiftUI
import CoreData
import PhotosUI

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var craftType = crafts[0]
    @State private var artisanName = ""
    @State private var notes = ""
    @State private var image: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingCamera = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    Picker("Craft", selection: $craftType) {
                        ForEach(crafts, id: \.self) { craft in
                            Text(craft)
                        }
                    }
                    // M1: Add Artisan Name attribute
                    TextField("Artisan Name", text: $artisanName)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                Section("Photo") {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Button("Take Photo") {
                        showingCamera = true
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEntry() }
                        .disabled(title.isEmpty)
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(image: $image)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        image = uiImage
                    }
                }
            }
        }
    }

    private func saveEntry() {
        let entry = CraftEntry(context: viewContext)
        entry.id = UUID()
        entry.title = title
        entry.craftType = craftType
        entry.artisanName = artisanName
        entry.notes = notes
        entry.date = Date()
        entry.isFavorite = false

        if let image = image {
            entry.photo = image.jpegData(compressionQuality: 0.7)
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Could not save: \(error)")
        }
    }
}
