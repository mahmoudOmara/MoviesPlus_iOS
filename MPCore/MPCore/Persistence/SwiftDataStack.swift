//
//  SwiftDataStack.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//


import Foundation
import SwiftData

/// SwiftData stack manager for the MoviesPlus app
/// Provides centralized model container and context management
public final class SwiftDataStack: ObservableObject {
    
    // MARK: - Properties
    
    /// The main model container for the app
    public let modelContainer: ModelContainer
    
    /// The main context for UI operations
    @MainActor
    public var mainContext: ModelContext {
        return modelContainer.mainContext
    }
    
    /// Background context for data operations
    public func backgroundContext() -> ModelContext {
        return ModelContext(modelContainer)
    }
    
    // MARK: - Initialization
    
    /// Initializes the SwiftData stack with the app's model configuration
    /// - Parameter isStoredInMemoryOnly: Whether to store data in memory only (useful for testing)
    public init(isStoredInMemoryOnly: Bool = false) throws {
        let schema = Schema([
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            cloudKitDatabase: .none // Can be configured later for CloudKit sync
        )
        
        do {
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            throw SwiftDataError.containerInitializationFailed(error)
        }
    }
    
    // MARK: - Context Management
    
    /// Saves the main context
    /// - Throws: SwiftDataError if save fails
    @MainActor
    public func save() throws {
        do {
            try mainContext.save()
        } catch {
            throw SwiftDataError.saveFailed(error)
        }
    }
    
    /// Saves a specific context
    /// - Parameter context: The context to save
    /// - Throws: SwiftDataError if save fails
    public func save(context: ModelContext) throws {
        do {
            try context.save()
        } catch {
            throw SwiftDataError.saveFailed(error)
        }
    }
    
    /// Performs a background task with a new context
    /// - Parameter block: The task to perform
    /// - Returns: The result of the task
    /// - Throws: Any error thrown by the task
    public func performBackgroundTask<T>(_ block: @escaping (ModelContext) throws -> T) async throws -> T {
        let context = backgroundContext()
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let result = try block(context)
                    try save(context: context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Deletes all data for a specific model type
    /// - Parameter modelType: The model type to delete
    /// - Throws: SwiftDataError if deletion fails
    @MainActor
    public func deleteAll<T: PersistentModel>(of modelType: T.Type) throws {
        do {
            try mainContext.delete(model: modelType)
            try save()
        } catch {
            throw SwiftDataError.deletionFailed(error)
        }
    }
    
    /// Fetches all entities of a specific type
    /// - Parameter modelType: The model type to fetch
    /// - Returns: Array of entities
    /// - Throws: SwiftDataError if fetch fails
    @MainActor
    public func fetchAll<T: PersistentModel>(of modelType: T.Type) throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        do {
            return try mainContext.fetch(descriptor)
        } catch {
            throw SwiftDataError.fetchFailed(error)
        }
    }
    
    /// Counts entities of a specific type
    /// - Parameter modelType: The model type to count
    /// - Returns: Count of entities
    /// - Throws: SwiftDataError if count fails
    @MainActor
    public func count<T: PersistentModel>(of modelType: T.Type) throws -> Int {
        let descriptor = FetchDescriptor<T>()
        do {
            return try mainContext.fetchCount(descriptor)
        } catch {
            throw SwiftDataError.fetchFailed(error)
        }
    }
}

// MARK: - Singleton Access

public extension SwiftDataStack {
    
    /// Shared instance of SwiftDataStack
    /// Note: This should be initialized early in the app lifecycle
    static var shared: SwiftDataStack = {
        do {
            return try SwiftDataStack()
        } catch {
            fatalError("Failed to initialize SwiftDataStack: \(error)")
        }
    }()
    
    /// Creates a new instance for testing
    /// - Returns: SwiftDataStack configured for in-memory storage
    static func forTesting() throws -> SwiftDataStack {
        return try SwiftDataStack(isStoredInMemoryOnly: true)
    }
}
