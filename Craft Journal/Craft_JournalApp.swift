//
//  Craft_JournalApp.swift
//  Craft Journal
//
//  Created by iMac13 on 9/28/26.
//

import SwiftUI
import CoreData

@main
struct Craft_JournalApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
