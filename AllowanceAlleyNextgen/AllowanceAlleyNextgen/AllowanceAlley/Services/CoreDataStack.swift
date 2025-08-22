// Auto-generated stub because the source section had no code.
// Replace with your real CoreDataStack implementation.
import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "AllowanceAlley")
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Unresolved Core Data error: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var context: NSManagedObjectContext { container.viewContext }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do { try context.save() } catch { print("Core Data save failed: \(error)") }
        }
    }
}
