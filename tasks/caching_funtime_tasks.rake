require 'fileutils'

namespace :caching_funtime do
  #good to overwrite this in order to load the correct fragment_trackerfiles
  task :cache_environment => :environment do
    require 'action_controller'
    begin
      require 'caching_config'
    rescue LoadError => le
    end
    CachingFuntime::TheCacher.perform_caching = true
  end

  namespace :assets do
    desc 'remove cached assets'
    task :sweep => :cache_environment do
      CachingFuntime::TheCacher.sweep_assets :all, :verbose => true
    end
    task :remove => :sweep
  end

  namespace :fragments do
    desc 'remove cached fragments (and actions)'
    task :sweep => [ :cache_environment ] do
      CachingFuntime::TheCacher.sweep_fragments( :all, :verbose => true )
    end

    desc 'sweep specified fragment  rake caching_funtime:fragments:sweep_by_name NAME=_browse'
    task :sweep_by_name => [:cache_environment] do
      CachingFuntime::TheCacher.sweep_fragments( ENV['NAME'], :verbose => true )
    end
  end

  namespace :page do
    desc 'Clear the page cache'
    task :sweep  => :cache_environment do
      CachingFuntime::TheCacher.sweep_pages :all, :verbose => true
    end
  end

  namespace :public do
    desc 'Remove all page caches and assets'
    task :sweep => ["page:sweep", "assets:sweep"]
  end
end