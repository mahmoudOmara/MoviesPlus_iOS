//
//  SwiftDataStackTests.swift
//  MPCore
//
//  Created by mac on 08/08/2025.
//

import XCTest
import SwiftData
@testable import MPCore

final class SwiftDataStackTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var swiftDataStack: SwiftDataStack!
    
    // MARK: - Test Setup & Teardown
    
    override func setUp() {
        super.setUp()
        // Each test gets a fresh in-memory stack with both test model types
        swiftDataStack = try! SwiftDataStack.forTesting(with: [TestModel.self, AnotherTestModel.self])
    }
    
    override func tearDown() {
        swiftDataStack = nil
        super.tearDown()
    }
    
    // MARK: - Container Initialization Tests
    
    func test_init_withValidModelTypes_initializesSuccessfully() throws {
        // Arrange & Act
        let stack = try SwiftDataStack.forTesting(with: [TestModel.self])
        
        // Assert
        XCTAssertNotNil(stack.modelContainer)
    }
    
    func test_init_withEmptyModelTypes_initializesSuccessfully() throws {
        // Arrange & Act
        let stack = try SwiftDataStack.forTesting(with: [])
        
        // Assert
        XCTAssertNotNil(stack.modelContainer)
    }
    
    func test_init_withMultipleModelTypes_initializesSuccessfully() throws {
        // Arrange & Act
        let stack = try SwiftDataStack.forTesting(with: [TestModel.self, AnotherTestModel.self])
        
        // Assert
        XCTAssertNotNil(stack.modelContainer)
    }
    
    // MARK: - Context Management Tests
    
    @MainActor
    func test_mainContext_returnsValidContext() {
        // Arrange & Act
        let context = swiftDataStack.mainContext
        
        // Assert
        XCTAssertNotNil(context)
    }
    
    @MainActor
    func test_backgroundContext_returnsNewContext() {
        // Arrange & Act
        let backgroundContext = swiftDataStack.backgroundContext()
        
        // Assert
        XCTAssertNotNil(backgroundContext)
        
        XCTAssertNotEqual(backgroundContext, swiftDataStack.mainContext)
    }
    
    func test_backgroundContext_multipleCallsReturnDifferentContexts() {
        // Arrange & Act
        let context1 = swiftDataStack.backgroundContext()
        let context2 = swiftDataStack.backgroundContext()
        
        // Assert
        XCTAssertNotNil(context1)
        XCTAssertNotNil(context2)
        XCTAssertNotEqual(context1, context2)
    }
    
    // MARK: - Save Operations Tests
    
    @MainActor
    func test_save_withValidData_savesSuccessfully() throws {
        // Arrange
        let testModel = TestModel(name: "Test Item", value: 42)
        swiftDataStack.mainContext.insert(testModel)
        
        // Act & Assert
        XCTAssertNoThrow(try swiftDataStack.save())
    }
    
    @MainActor
    func test_save_withNoChanges_savesSuccessfully() throws {
        // Arrange - no changes made to context
        
        // Act & Assert
        XCTAssertNoThrow(try swiftDataStack.save())
    }
    
    func test_saveContext_withValidData_savesSuccessfully() throws {
        // Arrange
        let backgroundContext = swiftDataStack.backgroundContext()
        let testModel = TestModel(name: "Background Test", value: 100)
        backgroundContext.insert(testModel)
        
        // Act & Assert
        XCTAssertNoThrow(try swiftDataStack.save(context: backgroundContext))
    }
    
    func test_saveContext_withNoChanges_savesSuccessfully() throws {
        // Arrange
        let backgroundContext = swiftDataStack.backgroundContext()
        
        // Act & Assert
        XCTAssertNoThrow(try swiftDataStack.save(context: backgroundContext))
    }
    
    // MARK: - Background Task Execution Tests
    
    func test_performBackgroundTask_withSuccessfulTask_returnsResult() async throws {
        // Arrange
        let expectedValue = 42
        
        // Act
        let result = try await swiftDataStack.performBackgroundTask { context in
            let testModel = TestModel(name: "Background Task Test", value: expectedValue)
            context.insert(testModel)
            return testModel.value
        }
        
        // Assert
        XCTAssertEqual(result, expectedValue)
    }
    
    func test_performBackgroundTask_withThrowingTask_propagatesError() async {
        // Arrange
        struct TestError: Error {
            let message: String
        }
        let expectedError = TestError(message: "Test error")
        
        // Act & Assert
        do {
            _ = try await swiftDataStack.performBackgroundTask { _ in
                throw expectedError
            }
            XCTFail("Should have thrown an error")
        } catch let error as TestError {
            XCTAssertEqual(error.message, expectedError.message)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_performBackgroundTask_automaticallySavesContext() async throws {
        // Arrange
        let testName = "Auto Save Test"
        
        // Act
        _ = try await swiftDataStack.performBackgroundTask { context in
            let testModel = TestModel(name: testName, value: 123)
            context.insert(testModel)
            return testModel
        }
        
        // Assert - Verify data was saved by fetching from main context
        try await MainActor.run {
            let fetchedItems = try self.swiftDataStack.fetchAll(of: TestModel.self)
            XCTAssertEqual(fetchedItems.count, 1)
            XCTAssertEqual(fetchedItems.first?.name, testName)
        }
    }
    
    // MARK: - Memory-Only Configuration Tests
    
    @MainActor
    func test_memoryOnlyStorage_doesNotPersistBetweenInstances() throws {
        // Arrange - Create first instance and add data
        let stack1 = try SwiftDataStack.forTesting(with: [TestModel.self])
        let testModel = TestModel(name: "Temporary", value: 999)
        
        stack1.mainContext.insert(testModel)
        try stack1.save()
        
        // Act - Create second instance
        let stack2 = try SwiftDataStack.forTesting(with: [TestModel.self])
        
        // Assert - Second instance should not have data from first
        let items = try stack2.fetchAll(of: TestModel.self)
        XCTAssertEqual(items.count, 0)
    }
    
    // MARK: - Utility Methods Tests
    
    @MainActor
    func test_deleteAll_removesAllEntitiesOfType() throws {
        // Arrange
        let testModel1 = TestModel(name: "Test 1", value: 1)
        let testModel2 = TestModel(name: "Test 2", value: 2)
        let anotherModel = AnotherTestModel(text: "Different type")
        
        swiftDataStack.mainContext.insert(testModel1)
        swiftDataStack.mainContext.insert(testModel2)
        swiftDataStack.mainContext.insert(anotherModel)
        try swiftDataStack.save()
        
        // Act
        try swiftDataStack.deleteAll(of: TestModel.self)
        
        // Assert
        let remainingTestModels = try swiftDataStack.fetchAll(of: TestModel.self)
        let remainingAnotherModels = try swiftDataStack.fetchAll(of: AnotherTestModel.self)
        
        XCTAssertEqual(remainingTestModels.count, 0)
        XCTAssertEqual(remainingAnotherModels.count, 1)
    }
    
    @MainActor
    func test_deleteAll_withNoEntities_completes() throws {
        // Arrange - no entities of this type exist
        
        // Act & Assert
        XCTAssertNoThrow(try swiftDataStack.deleteAll(of: TestModel.self))
    }
    
    @MainActor
    func test_fetchAll_returnsAllEntitiesOfType() throws {
        // Arrange
        let testModel1 = TestModel(name: "Test A", value: 10)
        let testModel2 = TestModel(name: "Test B", value: 20)
        let anotherModel = AnotherTestModel(text: "Different")
        
        swiftDataStack.mainContext.insert(testModel1)
        swiftDataStack.mainContext.insert(testModel2)
        swiftDataStack.mainContext.insert(anotherModel)
        try swiftDataStack.save()
        
        // Act
        let fetchedTestModels = try swiftDataStack.fetchAll(of: TestModel.self)
        let fetchedAnotherModels = try swiftDataStack.fetchAll(of: AnotherTestModel.self)
        
        // Assert
        XCTAssertEqual(fetchedTestModels.count, 2)
        XCTAssertEqual(fetchedAnotherModels.count, 1)
        
        let names = fetchedTestModels.map { $0.name }.sorted()
        XCTAssertEqual(names, ["Test A", "Test B"])
    }
    
    @MainActor
    func test_fetchAll_withNoEntities_returnsEmptyArray() throws {
        // Arrange - no entities exist
        
        // Act
        let result = try swiftDataStack.fetchAll(of: TestModel.self)
        
        // Assert
        XCTAssertEqual(result.count, 0)
    }
    
    @MainActor
    func test_count_returnsCorrectCount() throws {
        // Arrange
        let testModel1 = TestModel(name: "Count Test 1", value: 1)
        let testModel2 = TestModel(name: "Count Test 2", value: 2)
        let testModel3 = TestModel(name: "Count Test 3", value: 3)
        
        swiftDataStack.mainContext.insert(testModel1)
        swiftDataStack.mainContext.insert(testModel2)
        swiftDataStack.mainContext.insert(testModel3)
        try swiftDataStack.save()
        
        // Act
        let count = try swiftDataStack.count(of: TestModel.self)
        
        // Assert
        XCTAssertEqual(count, 3)
    }
    
    @MainActor
    func test_count_withNoEntities_returnsZero() throws {
        // Arrange - no entities exist
        
        // Act
        let count = try swiftDataStack.count(of: TestModel.self)
        
        // Assert
        XCTAssertEqual(count, 0)
    }
    
    // MARK: - Singleton Tests
    
    func test_configureShared_setsSharedInstance() throws {
        // Arrange
        let originalShared = SwiftDataStack.shared
        
        // Act
        try SwiftDataStack.configureShared(with: [TestModel.self])
        
        // Assert
        XCTAssertNotNil(SwiftDataStack.shared)
        XCTAssertNotNil(SwiftDataStack.shared.modelContainer)
        
        // Cleanup - restore original state
        SwiftDataStack.shared = originalShared
    }
    
    func test_configureShared_withEmptyModelTypes_succeeds() throws {
        // Arrange
        let originalShared = SwiftDataStack.shared
        
        // Act & Assert
        XCTAssertNoThrow(try SwiftDataStack.configureShared(with: []))
        XCTAssertNotNil(SwiftDataStack.shared)
        
        // Cleanup
        SwiftDataStack.shared = originalShared
    }
}

// MARK: - Test Models

@Model
private final class TestModel {
    var name: String
    var value: Int
    var createdAt: Date
    
    init(name: String, value: Int) {
        self.name = name
        self.value = value
        self.createdAt = Date()
    }
}

@Model
private final class AnotherTestModel {
    var text: String
    var createdAt: Date
    
    init(text: String) {
        self.text = text
        self.createdAt = Date()
    }
}
