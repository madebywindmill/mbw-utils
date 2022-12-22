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
*/
public class CoreDataManager {
    
    // For convenience, assuming there's only ever one in the app
    public static var current: CoreDataManager!
    
    public var mainContext: NSManagedObjectContext!
        
    /// Instantiate a CoreDataManager.
    /// - Parameter modelName: the name of the CoreData model resource file
    /// - Parameter dbName: the name to use for the sqlite database stored on disk
    /// - Parameter moduleName: the module (e.g. Swift package) containing the Core Data model file, if any
    /// - Note If pulling the model from a Swift package:
    ///     * Check the actual name of the Swift package bundle. Sometimes it will be named "MyPackage_MyPackage.bundle" instead of just "MyPackage.bundle" in which case you will want to set `moduleName` to `MyPackage_MyPackage`. You can set a breakpoint and use `FileManager.enumerateContentsOfDirectory` to see the bundle name.
    ///     * For each Core Data entity, be sure to set the class module to the name of the package. It won't be listed in the popup. (You'll never need the underscore version here…)
    public init(modelName: String, dbName: String, moduleName: String? = nil) {
        let modelURL: URL
        
        if let moduleName = moduleName {
            guard let tempURL = Bundle.bundleFromModuleWithName(moduleName).url(forResource: modelName,
                                                                                withExtension: "momd") else {
                fatalError("Failed to locate DataModel in app bundle")
            }
            modelURL = tempURL
        } else {
            guard let tempURL = Bundle.main.url(forResource: modelName,
                                                 withExtension: "momd") else {
                fatalError("Failed to locate DataModel in app bundle")
            }
            modelURL = tempURL
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
        mainContext.delete(managedObject)
        do { try mainContext.save() } catch {
            Logger.fileLog("*** Caught: \(error)")
        }
    }
    
    /// Persist objects in the context
    /// - Returns: An optional error
    @discardableResult public func save() -> Error? {
        assert(Thread.isMainThread)
        do {
            try mainContext.save()
        } catch {
            Logger.fileLog("*** failure to save context: \(error)")
            return error
        }
        return nil
    }
    
    /// async/await-safe version of the above
    @available(iOS 13, macOS 11.0, *)
    open func save() async throws {
        @MainActor func saveMain() -> Error? {
            return save()
        }
        
        if let e = await saveMain() {
            throw e
        }
    }

    /// Print all objects in the store to console. **WARNING**: brings entire object graph into memory. For debugging use only.
    public func printAllObjects() {
        guard let model = mainContext.persistentStoreCoordinator?.managedObjectModel else {
            Logger.fileLog("*** persistentStoreCoordinator was nil")
            return
        }
        for nextEntityName in model.entities.compactMap({ $0.name }) {
            if nextEntityName == "CoreDataObject" {
                // Skip the abstract superclass since it's redundant
                continue
            }
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: nextEntityName)
            if let results = try? mainContext.fetch(fetchRequest) {
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
            try mainContext.execute(request)
            if let error = save() {
                throw(error)
            }
        } catch {
            Logger.fileLog("*** deleteAll() failed with \(error)")
        }
    }
    
    /// Use with extreme care. For debugging/tests purposes only.
    public func deleteAll() {
        deleteAllObjects(entityName: "CoreDataObject")
        mainContext.reset()
    }
}

// Taken from the SPM generated resource_bundle_accessor.swift that you normally get when including a Resources directory.
private class BundleFinder {} // Presumably Apple defines this somewhere
extension Foundation.Bundle {
    static func bundleFromModuleWithName(_ bundleName: String) -> Bundle {

        let overrides: [URL]
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["PACKAGE_RESOURCE_BUNDLE_URL"] {
            overrides = [URL(fileURLWithPath: override)]
        } else {
            overrides = []
        }
        #else
        overrides = []
        #endif

        let candidates = overrides + [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleFinder.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        fatalError("unable to find bundle named \(bundleName)")
    }
}
