//
//  SearchThrottler.swift
//
//  Copyright (c) 2021 Christian Gossain
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// An object that implements the `UISearchResultsUpdating` protocol and can be used to debounce search updates.
public final class SearchThrottler: NSObject {
    /// The throttler.
    public let throttler: Throttler
    
    /// The search results updater that will receive the throttled callbacks.
    public weak var throttledSearchResultsUpdater: UISearchResultsUpdating?
    
    
    // MARK: - Lifecycle
    /// Initializes a new SearchThrottler intance with the given throttler.
    ///
    /// - Parameters:
    ///     - throttler: The Throttler instance to use to debounce search updates.
    public init(throttler: Throttler = Throttler(throttlingInterval: 0.3, maxInterval: 0.6, qosClass: .userInitiated)) {
        self.throttler = throttler
        super.init()
    }
}

extension SearchThrottler: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
//        print("RAW: \(searchController.searchBar.text ?? "")")
        throttler.throttle {
            DispatchQueue.main.async {
//                print("THROTTLED: \(searchController.searchBar.text ?? "")")
                self.throttledSearchResultsUpdater?.updateSearchResults(for: searchController)
            }
        }
    }
}
