// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GenericResultsController",
    platforms: [.iOS(v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "GenericResultsController", targets: ["GenericResultsController"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/cgossain/Debounce.git", .upToNextMajor(from: "1.5.0")),
        .package(url: "https://github.com/jflinter/Dwifft", .upToNextMajor(from: "0.9.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GenericResultsController",
            dependencies: [
                .product(name: "Debounce", package: "Debounce"),
                .product(name: "Dwifft", package: "Dwifft"),
            ]
        ),
        .testTarget(
            name: "GenericResultsControllerTests",
            dependencies: [
                "GenericResultsController"
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
