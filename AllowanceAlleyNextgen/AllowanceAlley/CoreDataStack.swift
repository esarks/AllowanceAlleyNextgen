import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AllowanceAlley")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var context: NSManagedObjectContext { persistentContainer.viewContext }
    var backgroundContext: NSManagedObjectContext { persistentContainer.newBackgroundContext() }
    
    func save() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do { try context.save() } catch { print("Failed to save context: \(error)") }
        }
    }
}
