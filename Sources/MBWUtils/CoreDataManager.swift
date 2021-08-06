//
//  CoreDataManager.swift
//
//  Created by John Scalo on 8/6/21.
//

import CoreData

public typealias IDType = String

/** A convenience class that manages Core Data stores.
 
 `CoreDataManager` makes some assumptions about how the CD store is managed:
 
 * The MOC is concurrent with the main thread
 * It uses an overwrite merge policy
 * It uses sqlite as the backing store
 
 `CoreDataManager` and `CoreDataObject` work together so all entities managed through `CoreDataManager` should be subclasses of  `CoreDataObject`.
 
 After instantiating a `CoreDataManager`, register each your model classes like so:
 ```swift
 dm.register(class: Account.self, entityName: "Account")
 ```
 */
public class CoreDataManager {
    
    // For convenience, assuming there's only ever one in the app
    public static var current: CoreDataManager!
    
    public var mainContext: NSManagedObjectContext!
    
    private var classEntityRegistry = [String:String]() // key = class string, val = entity name
    
    /// Instantiate a CoreDataManager.
    /// - Parameter modelName: the name of the CoreData model resource file
    /// - Parameter dbName: the name to use for the sqlite database stored on disk
    public init(modelName: String, dbName: String) {
        guard let modelURL = Bundle.main.url(forResource: modelName,
                                             withExtension: "momd") else {
            fatalError("Failed to locate DataModel in app bundle")
        }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to initialize MOM")
        }
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext?.persistentStoreCoordinator = psc
        mainContext?.mergePolicy = NSOverwriteMergePolicy // prevents merge errors
        
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Failed to resolve documents directory")
        }
        let storeURL = documentsURL.appendingPathComponent(dbName)
        Logger.shortLog("Core Data db path: \(storeURL.path)")
        
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                           NSInferMappingModelAutomaticallyOption: true]
            try psc.addPersistentStore(ofType: NSSQLiteStoreType,
                                       configurationName: nil, at: storeURL, options: options)
        } catch let error as NSError {
            fatalError("Failed to add persistent store: \(error)")
        }
        
        CoreDataManager.current = self
    }
    
    /// Look up the registered entity name for a model class
    /// - Parameter class: The class of a previously registered model
    /// - Returns: The entity name of that model class
    public func entityNameForClass(_ class: CoreDataObject.Type) -> String! {
        let classStr = "\(`class`)"
        return classEntityRegistry[classStr]
    }
    
    /// Create and return a CD entity
    /// - Parameter name: The name of a previously registered CD entity
    /// - Returns: An NSEntityDescription in the NSManagedObjectContext
    public func entity(name: String) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: name, in: self.mainContext)
    }
    
    private func register(class: CoreDataObject.Type, entityName: String) {
        let classStr = "\(`class`)"
        classEntityRegistry[classStr] = entityName
    }
    
    /// Update an object in the store
    /// - Parameters:
    ///   - managedObject: The object currently in the store to be updated
    ///   - newObject: The object to update to
    public func update(managedObject: NSManagedObject, with newObject: NSManagedObject) {
        let entity = managedObject.entity
        for (key,_) in entity.attributesByName {
            let newValue = newObject.value(forKey: key)
            managedObject.setValue(newValue, forKey: key)
        }
    }
    
    /// Replace an object in the store
    /// - Parameters:
    ///   - managedObject: The object currently in the store to be replaced
    ///   - newObject: The object to replace it with
    public func replace(managedObject: NSManagedObject, with newObject: NSManagedObject) {
        self.mainContext.delete(managedObject)
        do { try self.mainContext.save() } catch {
            Logger.fileLog("*** Caught: \(error)")
        }
    }
    
    /// Persist objects in the context
    /// - Returns: An optional error
    @discardableResult public func save() -> Error? {
        assert(Thread.isMainThread)
        do {
            try self.mainContext.save()
        } catch {
            Logger.fileLog("*** failure to save context: \(error)")
            return error
        }
        return nil
    }
    
    /// Print all objects in the store to console. **WARNING**: brings entire object graph into memory. For debugging use only.
    public func printAllObjects() {
        for nextEntityName in classEntityRegistry.values {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: nextEntityName)
            if let results = try? self.mainContext.fetch(fetchRequest) {
                for next in results {
                    if let o = next as? CoreDataObject {
                        print(o.coreDataAttrs)
                    } else {
                        print("*** warning, not a Core Data object: \(next)")
                    }
                }
            }
        }
    }
    
    /// Use with extreme care. Deleting objects with remaining references from other objects will result in an exception. Further, all relationship entities that these objects reference will also be deleted.
    /// - Parameter entityName: The name of the entity for which all objects are to be deleted
    public func deleteAllObjects(entityName: String) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do {
            try self.mainContext.execute(request)
            if let error = self.save() {
                throw(error)
            }
        } catch {
            Logger.fileLog("*** deleteAll() failed with \(error)")
        }
    }
    
    /// Use with extreme care. For debugging/tests purposes only.
    public func deleteAll() {
        for nextEntityName in classEntityRegistry.values {
            self.deleteAllObjects(entityName: nextEntityName)
        }
        self.mainContext.reset()
    }
}
