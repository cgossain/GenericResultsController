//
//  FetchedResultsControllerTests.swift
//  FetchedResultsController_Tests
//
//  Created by Christian Gossain on 2021-01-27.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import FetchedResultsController

// MAKR: - Mock Classes

struct TestModel: Hashable, Identifiable {
    let id = UUID().uuidString
    let timestamp: Date?
    let category: String?
}

class TestStoreRequest: StoreRequest {
    typealias ResultType = TestModel
    
    var fetchLimit: Int = 0
    
    var isIncluded: ((TestModel) -> Bool)?
    
    var areInIncreasingOrder: ((TestModel, TestModel) -> Bool)?
    
    
    // MARK: - NSCopying
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TestStoreRequest()
        copy.fetchLimit = fetchLimit
        copy.isIncluded = isIncluded
        copy.areInIncreasingOrder = areInIncreasingOrder
        return copy
    }
    
}

class TestStoreConnector: StoreConnector<TestStoreRequest> {
    private let results = [TestModel(timestamp: Date(timeInterval: -9000, since: Date()), category: "Section A"),
                           TestModel(timestamp: Date(timeInterval: -8500, since: Date()), category: "Section A"),
                           TestModel(timestamp: Date(timeInterval: -8000, since: Date()), category: "Section A"),
                           TestModel(timestamp: Date(timeInterval: -7500, since: Date()), category: "Section B"),
                           TestModel(timestamp: Date(timeInterval: -7000, since: Date()), category: "Section B"),
                           TestModel(timestamp: Date(timeInterval: -6500, since: Date()), category: "Section C")]
    
    open override func execute(_ request: ObserverQuery<TestStoreRequest>) {
        // simulate inserting fake results
//        for result in results {
//            self.enqueue(inserted: result)
//        }
    }
}

// MAKR: - FetchedResultsControllerTests

class FetchedResultsControllerTests: XCTestCase {
    
    let didChangeContentExpectation = XCTestExpectation(description: "FetchedResultsController did change content")
    
    let testStoreConnector = TestStoreConnector()
    
    let testStoreRequest = TestStoreRequest()
    
    var fetchedResultsController: FetchedResultsController<TestStoreRequest>!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        fetchedResultsController = FetchedResultsController(storeRequest: testStoreRequest, storeConnector: testStoreConnector) { $0.category }
        fetchedResultsController.delegate.controllerDidChangeContent = { [unowned self] (controller) in
            self.didChangeContentExpectation.fulfill()
        }
        fetchedResultsController.performFetch()
        
        wait(for: [didChangeContentExpectation], timeout: 5)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNumberOfSections() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(fetchedResultsController.sections.count, 3)
    }

}
