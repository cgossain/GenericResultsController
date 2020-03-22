Pod::Spec.new do |s|
  s.name             = 'FetchedResultsController'
  s.version          = '1.0.0'
  s.summary          = 'An generic NSFetchedResultsController replacement for iOS, written in Swift.'
  s.description      = <<-DESC
                        The FetchedResultsController is an NSFetchedResultsController replacement that allows you to
                        monitor (fetch, filter, sort, section, and diff) data stored in any modern database.
                        
                        Your database must support attaching observers to your queries (i.e. insert, update, delete, refresh)
                       DESC
  s.homepage         = 'https://github.com/cgossain/FetchedResultsController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Christian Gossain' => 'cgossain@gmail.com' }
  s.source           = { :git => 'https://github.com/cgossain/FetchedResultsController.git', :tag => s.version.to_s }
  s.swift_versions   = ['5.0']
  s.ios.deployment_target = '11.4'
  s.source_files = 'FetchedResultsController/Classes/**/*'
  s.dependency 'Debounce'
  s.dependency 'Dwifft', '~> 0.9'
end
