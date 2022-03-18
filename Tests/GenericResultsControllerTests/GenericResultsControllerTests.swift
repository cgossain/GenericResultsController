import XCTest
@testable import GenericResultsController

// MAKR: - Mock Classes

struct MockResult: Hashable, InstanceIdentifiable {
    let id = UUID().uuidString
    let timestamp: Date?
    let category: String?
}

class MockRequest: DataStoreRequest {
    var fetchLimit: Int = 0
}

class MockDataStore: DataStore<MockResult, MockRequest> {
    
    private let results = [
        MockResult(timestamp: Date(timeInterval: -9000, since: Date()), category: "Section A"),
        MockResult(timestamp: Date(timeInterval: -8500, since: Date()), category: "Section A"),
        MockResult(timestamp: Date(timeInterval: -8000, since: Date()), category: "Section A"),
        MockResult(timestamp: Date(timeInterval: -7500, since: Date()), category: "Section B"),
        MockResult(timestamp: Date(timeInterval: -7000, since: Date()), category: "Section B"),
        MockResult(timestamp: Date(timeInterval: -6500, since: Date()), category: "Section C")
    ]
    
    open override func execute(_ query: DataStoreQuery<MockResult, MockRequest>) {
        super.execute(query)
        query.enqueue(results, as: .insert)
    }
    
}

final class GenericResultsControllerTests: XCTestCase {
    
    let mockDataStore = MockDataStore()
    
    let mockRequest = MockRequest()
    
    var resultsController: GenericResultsController<MockResult, MockRequest>!
    
    override func setUpWithError() throws {
        let didChangeContentExpectation = XCTestExpectation(description: "controllerDidChangeContent")
        
        resultsController = GenericResultsController(store: mockDataStore)
        
        resultsController.delegate.controllerResultsConfiguration = { (controller, request) in
            return .makeDefaultConfiguration()
        }
        
        resultsController.delegate.controllerDidChangeContent = { (controller) in
            didChangeContentExpectation.fulfill()
        }
        
        resultsController.performFetch(request: mockRequest)
        
        wait(for: [didChangeContentExpectation], timeout: 5)
    }
    
    func testNumberOfSectionsGenerated() throws {
        XCTAssertEqual(resultsController.sections.count, 3)
    }
    
}

extension GenericResultsControllerConfiguration where ResultType == MockResult {
    /// Creates and returns a standard results configuration for TestModel.
    static func makeDefaultConfiguration() -> GenericResultsControllerConfiguration<MockResult> {
        var configuration = GenericResultsControllerConfiguration<MockResult>()
        configuration.sectionNameProvider = {
            return $0.category
        }
        return configuration
    }
}
