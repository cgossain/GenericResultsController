# GenericResultsController

The GenericResultsController is an NSFetchedResultsController replacement for iOS, that is used to manage the results of any data fetch from any data source and to display that data to the user. 

The controller provides an abstracted API that is intentionally simple and makes no assumptions about how you manage your connection to the underlying data store. It also **provides strong support for Swift generics** by enabling you to customize the request and result types. The goal of this project is to provide a data controller with similar functionality to NSFetchedResultsController but with the core functionality (e.g. sectionning and diffing) abstracted out, giving you the ability to interface with any data source using any kind of data model.

The included example project showcases the core functionality of this library by implementing a custom connection to CoreData. However, the purpose of this library is to provide you with a set of features similar to NSFetchedResultsController while enabling you to plug in a connection to any data source (e.g. CoreData, Firebase, MongoDB, SQL, a REST API, etc.).

![Core Data Fetch & Diff](./Example/core-data-fetch-and-diff.gif)

[![CI Status](https://img.shields.io/travis/cgossain/GenericResultsController.svg?style=flat)](https://travis-ci.org/cgossain/GenericResultsController)
[![Version](https://img.shields.io/cocoapods/v/GenericResultsController.svg?style=flat)](https://cocoapods.org/pods/GenericResultsController)
[![License](https://img.shields.io/cocoapods/l/GenericResultsController.svg?style=flat)](https://cocoapods.org/pods/GenericResultsController)
[![Platform](https://img.shields.io/cocoapods/p/GenericResultsController.svg?style=flat)](https://cocoapods.org/pods/GenericResultsController)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate GenericResultsController into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'GenericResultsController', '~> 2.4.0'
```

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. 

Once you have your Swift package set up, adding GenericResultsController as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/cgossain/GenericResultsController.git", .upToNextMajor(from: "2.4.0"))
]
```

## Basics

### GenericResultsController

`GenericResultsController` is the controller object that you use to manage the results of a query performed against a data store and to display that data to the user. 

You initialize it with a `DataStore` instance, and it effectively acts as a middle man between your UI and some underlying source of data.

You must specify the generic parameters for the *result* and *request* types which means they both need to be defined before you can use the results controller. These parameters can be automatically inferred by Swift based on the `DataStore` instance passed during initialization.

### DataStore

`DataStore` is a generic abstract class that enables you to implement a connection to any data source (e.g. local database, cloud database, or even an API).

You implement a `DataStore` by overriding the `execute(_:)` method which takes a `DataStoreQuery` object as its only argument. You would then typically inspect the `request` parameter of the query object to determine the fetch cirteria, fetch the actual data, and finally deliver the results by enqueuing them into the query object.

There are also some basic CRUD methods that can be overriden. These are provided for convenience given that your subclass would already have enough context to perform these types of operations.

In this example, we override the `execute(_:)` method in our data store subclass to fetch data from a CoreData managed object context (see example project for more details).

```
override func execute(_ query: DataStoreQuery<EntityType, NSFetchRequest<EntityType>>) {
    super.execute(query)
    
    // perform the query and then call the query's `enqueue` method when
    // data becomes available
    //
    // note if your database supports observing changes to the
    // executed query you can setup observers here and then call
    // the query's `enqueue` method to add incremental changes
    // to the initial fetch results; these would then be picked
    // up by the results controller providing realtime updates to
    // the displayed results
    //
    // in this example we're executing a core data fetch request, and
    // then observing the for `NSManagedObjectContextObjectsDidChange` notification
    // to detect further incrementation changes

    // note, realistically you would use NSFetchedResultsController if you're
    // using CoreData.
    
    // observe incremental changes (since the last save)
    observersByQueryID[query.id] = NotificationCenter.default.addObserver(
        forName: .NSManagedObjectContextObjectsDidChange,
        object: self.managedObjectContext,
        queue: nil,
        using: { [unowned self] (note) in
            // enqueue incremental changes
            self.handleContextObjectsDidChangeNotification(note, query: query)
        })
    
    // enqueue initial fetch results
    let fetch = NSAsynchronousFetchRequest(fetchRequest: query.request) { [unowned self] (result) in
        if self.observersByQueryID[query.id] == nil {
            return
        }
        
        // enqueue each result into the query
        guard let objects = result.finalResult else { return }
        objects.forEach { query.enqueue($0, as: .insert) }
    }
    try! managedObjectContext.execute(fetch)
}
```

### DataStoreQuery

`DataStoreQuery` is an object that represents a unique instance of a fetch and is initialized with a `DataStoreRequest`.

### DataStoreRequest

`DataStoreRequest` is a type that *request* objects must conform to and its purpose is to define criteria used to retrieve data from a persistent store.

A request object can be anything that conforms to the `DataStoreRequest` protocol which itself has very minimal requirements. The core idea here is that a request object should be something that can be inspected within your data store implementation to gather criteria and build a query to your underlying data source.

### InstanceIdentifiable

`InstanceIdentifiable` is a type that *result* objects must conform to and enables the results controller to uniquely identify result objects.

## Usage

### Initializing a GenericResultsController (snippet from example project)

```
let store = CoreDataStore(managedObjectContext: self.managedObjectContext)

// this results controller uses NSFetchRequest as its request type, and a 
// model object called Event as its result type
var resultsController: GenericResultsController<Event, NSFetchRequest<Event>>!
resultsController = GenericResultsController(store: store)

// get notified when content is about to change
resultsController.delegate.controllerWillChangeContent = { (controller) in
    print("Will change content.")
}

// get notified when content has changed
resultsController.delegate.controllerDidChangeContent = { (controller) in
    print("Did change content.")
    self.tableView.reloadData()
    self.refreshControl?.endRefreshing()
}
```

### Triggering a Fetch with GenericResultsController (snippet from example project)

```
// create the fetch request
let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
fetchRequest.returnsObjectsAsFaults = false

// ask the result controller to fetch the results and arrange into sections
resultsController.performFetch(request: fetchRequest)
```

### Binding GenericResultsController to your UI (snippet from example project)

In this example we bind the controller to a UITableView.

```
// MARK: - UITableViewDataSource

let cellIdentifier = "cellIdentifier"

override func numberOfSections(in tableView: UITableView) -> Int {
    return resultsController.sections.count
}

override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return resultsController.sections[section].numberOfObjects
}

override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
    let event = try! resultsController.object(at: indexPath)
    cell.textLabel!.text = event.timestamp!.description
    return cell
}

override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return resultsController.sections[section].name
}

override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
        let event = try! resultsController.object(at: indexPath)
        let context = managedObjectContext
        context.delete(event)

        // save the core data context
        CoreDataManager.shared.saveContext()
    }
}
```

There are many more advanced ways to implement this. The example project provides a good starting point. Feel free to reach out if you'd like more details.

I'll be linking to projects that use this library in the future.

## Author

Christian Gossain, cgossain@gmail.com

## License

GenericResultsController is available under the MIT license. See the LICENSE file for more info.
