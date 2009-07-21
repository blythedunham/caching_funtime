module CachingFuntime
  module ExtendedPageSupport
    def self.extended( base )
      base.send :class_inheritable_accessor, :page_cache_assets
    end

    # make do sweeper. This is actually better in the long run to use
    # native rm commands for Dir.glob and cache sweepers are super slow
    # === Options
    # <tt>:verbose</tt> - log output when true
    def sweep_pages( asset_files = nil, options = {} )
      assets = asset_files == :all ? nil : asset_files 
      assets ||= self.page_cache_assets || []

      puts assets.inspect
      assets.each do |file|
        FileUtils.rm_rf(File.join(RAILS_ROOT, file))
        ext_page_cache_log "Removed: #{file}" if options[:verbose]
      end
    end

    # Render a partial with the specified locals. This is so rake can
    # generate files. Better to go thru application controller
    def render_partial_from_action_view(partial_name, options={})
      av = ActionView::Base.new(Rails::Configuration.new.view_path)

      av.render(options.merge(:partial => partial_name))
    end

    # Render a partial and add it to the page cache
    # If the file name cannot be inferred from the partial name, use:
    #   options[:filename] 'myrelateivepath'
    # which is relative to the page cache dir
    def page_cache_rendered_view(partial_name, locals, options={})

      content = render_partial_from_action_view(partial_name, :locals => locals)

      file = ActionController::Base.send(:page_cache_path,
        options[:file_name]||"/" + partial_name.gsub('.erb','')
      )
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, "wb+") { |f| f.write(content) }

      if options[:verbose]
        log_msg = "Cached file #{file}"
        log_msg << "\n  from partial #{ partial_name } "
        log_msg << "\n  with locals #{ locals.to_s } " unless locals.blank?
        ext_page_cache_log log_msg
      end
    end

    def ext_page_cache_log( msg )
      $stdout.puts msg
    end
  end
end
