import SwiftUI
import CoreData
import PhotosUI

// M2: Edit entry screen updating existing Core Data record
struct EditEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var entry: CraftEntry

    @State private var title: String = ""
    @State private var craftType: String = crafts[0]
    @State private var artisanName: String = ""
    @State private var notes: String = ""
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
                    // M1: Artisan Name field
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
            .navigationTitle("Edit Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveUpdates() }
                        .disabled(title.isEmpty)
                }
            }
            .onAppear {
                title = entry.title ?? ""
                craftType = entry.craftType ?? crafts[0]
                artisanName = entry.artisanName ?? ""
                notes = entry.notes ?? ""
                if let photoData = entry.photo {
                    image = UIImage(data: photoData)
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

    private func saveUpdates() {
        entry.title = title
        entry.craftType = craftType
        entry.artisanName = artisanName
        entry.notes = notes
        if let image = image {
            entry.photo = image.jpegData(compressionQuality: 0.7)
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Could not update entry: \(error)")
        }
    }
}
