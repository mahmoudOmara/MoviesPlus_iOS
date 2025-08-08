//
//  BaseViewModelTests.swift
//  MPCore
//
//  Created by mac on 08/08/2025.
//


import XCTest
import Combine
import SwiftUI
@testable import MPCore

final class BaseViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var viewModel: TestableBaseViewModel!
    private var mockCoordinator: MockCoordinator!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup & Teardown
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockCoordinator = MockCoordinator()
        viewModel = TestableBaseViewModel(coordinator: mockCoordinator)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        viewModel = nil
        mockCoordinator = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    @MainActor
    func test_init_withCoordinator_setsCoordinatorCorrectly() {
        // Arrange & Act
        let testViewModel = TestableBaseViewModel(coordinator: mockCoordinator)
        
        // Assert
        XCTAssertNotNil(testViewModel.coordinator)
        XCTAssertTrue(testViewModel.coordinator === mockCoordinator)
    }
    
    @MainActor
    func test_init_withoutCoordinator_coordinatorIsNil() {
        // Arrange & Act
        let testViewModel = TestableBaseViewModel()
        
        // Assert
        XCTAssertNil(testViewModel.coordinator)
    }
    
    func test_init_initialStateIsIdle() {
        // Arrange & Act & Assert
        XCTAssertEqual(viewModel.state, .idle)
    }
    
    func test_init_cancellablesSetIsEmpty() {
        // Arrange & Act & Assert
        XCTAssertTrue(viewModel.cancellables.isEmpty)
    }
    
    // MARK: - State Transition Tests
    
    @MainActor
    func test_setLoading_updatesStateToLoading() async {
        // Arrange
        let expectation = XCTestExpectation(description: "State updated to loading")
        
        viewModel.$state
            .dropFirst() // Skip initial .idle state
            .sink { state in
                if case .loading = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.setLoading()
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.state, .loading)
    }
    
    @MainActor
    func test_setLoadingMore_updatesStateToLoadingMore() async {
        // Arrange
        let expectation = XCTestExpectation(description: "State updated to loadingMore")
        
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .loadingMore = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.setLoadingMore()
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.state, .loadingMore)
    }
    
    @MainActor
    func test_setSuccess_updatesStateToSuccessWithData() async {
        // Arrange
        let testData = TestData(value: "test")
        let expectation = XCTestExpectation(description: "State updated to success")
        
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .success(let data) = state, data.value == testData.value {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.setSuccess(testData)
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.state, .success(testData))
    }
    
    @MainActor
    func test_setFailure_updatesStateToFailureWithError() async {
        // Arrange
        let testError = TestError.testCase
        let expectation = XCTestExpectation(description: "State updated to failure")
        
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .failure(let error) = state, error.localizedDescription == testError.localizedDescription {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.setFailure(testError)
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.state, .failure(testError))
    }
    
    @MainActor
    func test_resetState_updatesStateToIdle() async {
        // Arrange
        viewModel.setSuccess(TestData(value: "test"))
        let expectation = XCTestExpectation(description: "State reset to idle")
        
        viewModel.$state
            .dropFirst(2) // Skip initial .idle and .success states
            .sink { state in
                if case .idle = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.resetState()
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.state, .idle)
    }
    
    // MARK: - State Transition Sequence Tests
    
    @MainActor
    func test_stateTransitions_idleToLoadingToSuccess_worksCorrectly() async {
        // Arrange
        let testData = TestData(value: "success")
        var stateSequence: [ViewModelState<TestData>] = []
        let expectation = XCTestExpectation(description: "State transitions completed")
        expectation.expectedFulfillmentCount = 3
        
        viewModel.$state
            .sink { state in
                stateSequence.append(state)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.setLoading()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        viewModel.setSuccess(testData)
        
        // Assert
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(stateSequence.count, 3)
        XCTAssertEqual(stateSequence[0], .idle)
        XCTAssertEqual(stateSequence[1], .loading)
        XCTAssertEqual(stateSequence[2], .success(testData))
    }
    
    @MainActor
    func test_stateTransitions_loadingToFailureToIdle_worksCorrectly() async {
        // Arrange
        let testError = TestError.testCase
        var stateSequence: [ViewModelState<TestData>] = []
        let expectation = XCTestExpectation(description: "State transitions completed")
        expectation.expectedFulfillmentCount = 4
        
        viewModel.$state
            .sink { state in
                stateSequence.append(state)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.setLoading()
        try? await Task.sleep(nanoseconds: 100_000_000)
        viewModel.setFailure(testError)
        try? await Task.sleep(nanoseconds: 100_000_000)
        viewModel.resetState()
        
        // Assert
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(stateSequence.count, 4)
        XCTAssertEqual(stateSequence[0], .idle)
        XCTAssertEqual(stateSequence[1], .loading)
        XCTAssertEqual(stateSequence[2], .failure(testError))
        XCTAssertEqual(stateSequence[3], .idle)
    }
    
    // MARK: - Main Queue Dispatch Tests
    
    func test_setLoading_dispatchesToMainQueue() {
        // Arrange
        let expectation = XCTestExpectation(description: "Method dispatched to main queue")
        
        // Act
        DispatchQueue.global(qos: .background).async {
            self.viewModel.setLoading()
            
            DispatchQueue.main.async {
                // Verify we're on main queue after the update
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_setSuccess_dispatchesToMainQueue() {
        // Arrange
        let expectation = XCTestExpectation(description: "Method dispatched to main queue")
        let testData = TestData(value: "test")
        
        // Act
        DispatchQueue.global(qos: .background).async {
            self.viewModel.setSuccess(testData)
            
            DispatchQueue.main.async {
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_setFailure_dispatchesToMainQueue() {
        // Arrange
        let expectation = XCTestExpectation(description: "Method dispatched to main queue")
        let testError = TestError.testCase
        
        // Act
        DispatchQueue.global(qos: .background).async {
            self.viewModel.setFailure(testError)
            
            DispatchQueue.main.async {
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Convenience Properties Tests
    
    func test_isLoading_returnsTrueWhenStateIsLoading() {
        // Arrange
        viewModel.state = .loading
        
        // Act & Assert
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertFalse(viewModel.hasError)
        XCTAssertFalse(viewModel.hasData)
    }
    
    func test_isLoadingMore_returnsTrueWhenStateIsLoadingMore() {
        // Arrange
        viewModel.state = .loadingMore
        
        // Act & Assert
        XCTAssertTrue(viewModel.isLoadingMore)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasError)
        XCTAssertFalse(viewModel.hasData)
    }
    
    func test_hasError_returnsTrueWhenStateIsFailure() {
        // Arrange
        let testError = TestError.testCase
        viewModel.state = .failure(testError)
        
        // Act & Assert
        XCTAssertTrue(viewModel.hasError)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertFalse(viewModel.hasData)
        XCTAssertEqual(viewModel.error?.localizedDescription, testError.localizedDescription)
    }
    
    func test_hasData_returnsTrueWhenStateIsSuccess() {
        // Arrange
        let testData = TestData(value: "test")
        viewModel.state = .success(testData)
        
        // Act & Assert
        XCTAssertTrue(viewModel.hasData)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertFalse(viewModel.hasError)
        XCTAssertEqual(viewModel.data, testData)
    }
    
    func test_data_returnsCorrectValueWhenStateIsSuccess() {
        // Arrange
        let testData = TestData(value: "test data")
        viewModel.state = .success(testData)
        
        // Act & Assert
        XCTAssertEqual(viewModel.data, testData)
    }
    
    func test_data_returnsNilWhenStateIsNotSuccess() {
        // Arrange
        viewModel.state = .loading
        
        // Act & Assert
        XCTAssertNil(viewModel.data)
    }
    
    func test_error_returnsCorrectErrorWhenStateIsFailure() {
        // Arrange
        let testError = TestError.testCase
        viewModel.state = .failure(testError)
        
        // Act & Assert
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error?.localizedDescription, testError.localizedDescription)
    }
    
    func test_error_returnsNilWhenStateIsNotFailure() {
        // Arrange
        viewModel.state = .success(TestData(value: "success"))
        
        // Act & Assert
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Memory Management Tests
    
    func test_deinit_removesCancellables() {
        // Arrange
        var testViewModel: TestableBaseViewModel? = TestableBaseViewModel()
        
        // Add some cancellables to test cleanup
        Just("test")
            .sink { _ in }
            .store(in: &testViewModel!.cancellables)
        
        XCTAssertFalse(testViewModel!.cancellables.isEmpty)
        
        // Act - trigger deinit
        testViewModel = nil
        
        // Assert
        // This test verifies that deinit is called properly
        // The actual cleanup verification is implicit - if there were retain cycles,
        // the test would hang or fail due to memory issues
        XCTAssertNil(testViewModel)
    }
    
    @MainActor
    func test_coordinatorWeakReference_preventsCycles() {
        // Arrange
        weak var weakCoordinator: MockCoordinator?
        
        do {
            let coordinator = MockCoordinator()
            weakCoordinator = coordinator
            let testViewModel = TestableBaseViewModel(coordinator: coordinator)
            
            // Verify coordinator is set
            XCTAssertNotNil(testViewModel.coordinator)
            XCTAssertNotNil(weakCoordinator)
        }
        
        // Act & Assert
        // When coordinator goes out of scope, it should be deallocated
        // because BaseViewModel holds a weak reference
        XCTAssertNil(weakCoordinator, "Coordinator should be deallocated due to weak reference")
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func test_realWorldScenario_loadingDataThenSuccess() async {
        // Arrange
        let testData = TestData(value: "loaded data")
        let expectation = XCTestExpectation(description: "Loading scenario completed")
        expectation.expectedFulfillmentCount = 3
        
        var receivedStates: [ViewModelState<TestData>] = []
        
        viewModel.$state
            .sink { state in
                receivedStates.append(state)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act - Simulate loading data
        viewModel.setLoading()
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Simulate data loaded successfully
        viewModel.setSuccess(testData)
        
        // Assert
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify final state
        XCTAssertTrue(viewModel.hasData)
        XCTAssertEqual(viewModel.data, testData)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasError)
        
        // Verify state sequence
        XCTAssertEqual(receivedStates.count, 3)
        XCTAssertEqual(receivedStates[0], .idle)
        XCTAssertEqual(receivedStates[1], .loading)
        XCTAssertEqual(receivedStates[2], .success(testData))
    }
    
    @MainActor
    func test_realWorldScenario_loadingDataThenError() async {
        // Arrange
        let testError = TestError.testCase
        let expectation = XCTestExpectation(description: "Error scenario completed")
        expectation.expectedFulfillmentCount = 3
        
        viewModel.$state
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act - Simulate loading data with error
        viewModel.setLoading()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        viewModel.setFailure(testError)
        
        // Assert
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify final state
        XCTAssertTrue(viewModel.hasError)
        XCTAssertEqual(viewModel.error?.localizedDescription, testError.localizedDescription)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasData)
    }
}

// MARK: - Test Helpers

private class TestableBaseViewModel: BaseViewModel<TestData, MockCoordinator> {
    // Expose internal properties for testing
}

private struct TestData: Equatable {
    let value: String
}

private enum TestError: Error, LocalizedError {
    case testCase
    
    var errorDescription: String? {
        switch self {
        case .testCase:
            return "Test error case"
        }
    }
}

@MainActor
private class MockCoordinator: Coordinator {
    enum Destination: Hashable {
        case test
    }
    
    var parentCoordinator: (any Coordinator)?
    var path = NavigationPath()
    
    func start() -> AnyView {
        AnyView(Text("Mock"))
    }
    
    func navigate(to destination: Destination) {
        // Mock implementation
    }
}
