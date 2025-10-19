//
//  FietsRouteMeeApp.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI
import CoreData

@main
struct FietsRouteMeeApp: App {
    // Use CoreDataManager instead of PersistenceController
    let coreDataManager = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.container.viewContext)
        }
    }
}
