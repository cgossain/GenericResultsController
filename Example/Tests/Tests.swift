import XCTest
@testable import GenericResultsController

// MAKR: - Mock Classes

struct TestModel: Hashable, InstanceIdentifiable {
    let id = UUID().uuidString
    let timestamp: Date?
    let category: String?
}

class TestStoreRequest: DataStoreRequest {
    var fetchLimit: Int = 0
}

class TestStoreConnector: DataStore<TestModel, TestStoreRequest> {
    private let results = [TestModel(timestamp: Date(timeInterval: -9000, since: Date()), category: "Section A"),
                           TestModel(timestamp: Date(timeInterval: -8500, since: Date()), category: "Section A"),
                           TestModel(timestamp: Date(timeInterval: -8000, since: Date()), category: "Section A"),
                           TestModel(timestamp: Date(timeInterval: -7500, since: Date()), category: "Section B"),
                           TestModel(timestamp: Date(timeInterval: -7000, since: Date()), category: "Section B"),
                           TestModel(timestamp: Date(timeInterval: -6500, since: Date()), category: "Section C")]
    
    open override func execute(_ query: DataStoreQuery<TestModel, TestStoreRequest>) {
        results.forEach { query.enqueue($0, as: .insert) }
    }
}

// MAKR: - FetchedResultsControllerTests

class FetchedResultsControllerTests: XCTestCase {
    
    let didChangeContentExpectation = XCTestExpectation(description: "FetchedResultsController did change content")
    
    let testStoreConnector = TestStoreConnector()
    
    let testStoreRequest = TestStoreRequest()
    
    var fetchedResultsController: GenericResultsController<TestModel, TestStoreRequest>!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        fetchedResultsController = GenericResultsController(store: testStoreConnector)
        
        fetchedResultsController.delegate.controllerResultsConfiguration = { (controller, request) in
            return .makeDefaultConfiguration()
        }
        
        fetchedResultsController.delegate.controllerDidChangeContent = { [unowned self] (controller) in
            self.didChangeContentExpectation.fulfill()
        }
        
        fetchedResultsController.performFetch(storeRequest: testStoreRequest)
        
        wait(for: [didChangeContentExpectation], timeout: 5)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNumberOfSectionsGenerated() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(fetchedResultsController.sections.count, 3)
    }
}

extension GenericResultsControllerConfiguration where ResultType == TestModel {
    /// Creates and returns a standard results configuration for TestModel.
    static func makeDefaultConfiguration() -> GenericResultsControllerConfiguration<TestModel> {
        var configuration = GenericResultsControllerConfiguration<TestModel>()
        configuration.sectionNameProvider = {
            return $0.category
        }
        return configuration
    }
}
