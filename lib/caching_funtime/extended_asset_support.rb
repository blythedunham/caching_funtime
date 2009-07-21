require 'fileutils'

module CachingFuntime
  module ExtendedAssetSupport
    def self.extended( base )
      base.send :class_inheritable_accessor, :assets
      base.send :class_inheritable_accessor, :asset_extensions
      base.asset_extensions = {
        :javascripts => :js,
        :stylesheets => :css
      }
    end

    def sweep_assets( specified_assets = nil, options = {} )
      assets = specified_assets
      assets = self.assets || {} if assets.nil? || assets == :all
      assets.each do |folder, files |
        files.each do |file|
          file_path = if File.exists?( file )
            file.dup
          else
            File.join(RAILS_ROOT, 'public', folder.to_s, "#{file}.#{ self.asset_extensions[folder.to_sym] }")
          end
          puts "Deleting Asset: #{file_path}" if options[:verbose]
          FileUtils.rm_rf  file_path
        end
      end
    end
  end
end
