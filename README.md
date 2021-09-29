# GenericResultsController

The GenericResultsController is an NSFetchedResultsController replacement for iOS, that is used to manage the results of any data fetch from any data store and to display that data to the user. The controller provides an abstracted API that is intentionally simple and makes no assumptions about how you manage your connection to the underlying data store. The goal of this project is to provide a data controller with similar functionality to NSFetchedResultsController but with the ability to interface with any data set from any data store using any kind of data model.

The included example project showcases the core functionality of this library by implementing a custom connection to CoreData. However, the purpose of this library is to provide you with a set of features similar to NSFetchedResultsController while enabling you to plug in a connection to any database (e.g. CoreData, Firebase, MongoDB, SQL, etc.).

![Core Data Fetch & Diff](./Example/core-data-fetch-and-diff.gif)

[![CI Status](https://img.shields.io/travis/cgossain/GenericResultsController.svg?style=flat)](https://travis-ci.org/cgossain/GenericResultsController)
[![Version](https://img.shields.io/cocoapods/v/GenericResultsController.svg?style=flat)](https://cocoapods.org/pods/GenericResultsController)
[![License](https://img.shields.io/cocoapods/l/GenericResultsController.svg?style=flat)](https://cocoapods.org/pods/GenericResultsController)
[![Platform](https://img.shields.io/cocoapods/p/GenericResultsController.svg?style=flat)](https://cocoapods.org/pods/GenericResultsController)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

GenericResultsController is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'GenericResultsController'
```

## Author

cgossain, cgossain@gmail.com

## License

GenericResultsController is available under the MIT license. See the LICENSE file for more info.
