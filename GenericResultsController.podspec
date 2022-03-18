Pod::Spec.new do |s|
  s.name             = 'GenericResultsController'
  s.version          = '2.3.1'
  s.summary          = 'A generic NSFetchedResultsController replacement for iOS, written in Swift.'
  s.description      = <<-DESC
  The GenericResultsController is an NSFetchedResultsController replacement for iOS, that is used to
  manage the results of any data fetch from any data source and to display that data to the user. The
  controller provides an abstracted API that is intentionally simple and makes no assumptions about 
  how you manage your connection to the underlying data store. It also provides strong support for Swift
  generics by enabling you to customize the request and result types. The goal of this project is to 
  provide a data controller with similar functionality to NSFetchedResultsController but with the core 
  functionality (e.g. sectionning and diffing) abstracted out, giving you the ability to interface with 
  any data source using any kind of data model.
                       DESC
  s.homepage         = 'https://github.com/cgossain/GenericResultsController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Christian Gossain' => 'cgossain@gmail.com' }
  s.source           = { :git => 'https://github.com/cgossain/GenericResultsController.git', :tag => s.version.to_s }
  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/GenericResultsController/**/*'
  s.dependency 'Debounce', '~> 1.5.1'
  s.dependency 'Dwifft', '0.9'
end
