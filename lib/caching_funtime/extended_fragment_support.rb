module CachingFuntime
  module ExtendedFragmentSupport
    def self.extended( base )
      base.send :class_inheritable_accessor, :the_cacher unless base.respond_to?( :the_cacher )
      class << base
        delegate :cache_key_params, :tracked_fragment, :tracked_fragments, :to => CacheKeyBuilder
      end
    end

    def self.included ( base )
      base.send :attr_accessor, :the_cacher unless base.method_defined?( :the_cacher )
    end

    # loop through all of the different permutations of cache key parameters
    # if a block is given, call yield
    # otherwise, return an array of [ name, cache_key_params ]
    def all_tracked_fragments( names = nil, options={}, &block )
      frag_names = names == :all ? nil : names

      #load_caching_components
      fragments = []
      CacheKeyBuilder.all_tracked_fragments( frag_names, options[:dynamic_params] || {} ) do |name, cache_key_params|
        result = if block_given?
          yield( name, cache_key_params )
        else
          [ name, cache_key_params ]
        end
        fragments << result
      end
      fragments
    end

    # Return the [ name, fragment_cache_key ] pairs for all of the permutations
    # of each possible fragment
    def all_fragment_keys( names, options )
      all_tracked_fragments( names, options) do |name, cache_key_params|
        [ name, the_cacher.fragment_cache_key( cache_key_params ) ]
      end
    end

    # Delete (expire) the specified fragments. If no fragment is specified, all are
    # destroyed. The following deletes all permutations of the tracked fragments named
    # :_list and :_show
    #
    #  delete_all_cached_fragments( :_list, :_show )
    #
    #  options[:verbose] = true will puts
    def delete_tracked_fragments( names = nil, options={}, &block )
      all_tracked_fragments( names, options ) do |name, cache_key_params|
        the_cacher.expire_fragment cache_key_params
        $stdout.puts "Expire fragment #{name}: #{self.the_cacher.fragment_cache_key( cache_key_params )}" if options[:verbose]
        yield name, cache_key_params, self.the_cacher if block_given?
      end
    end

    # Sweep fragments specified by +name+
    # +name+ defaults to all tracked fragments
    #  options[:verbose] = true will puts
    def sweep_fragments( names = :all, options = {}, &block)
      if (names == :all || names.nil?) && the_cacher.is_a?(ActiveSupport::Cache::FileStore)
        sweep_file_store options
      else
        delete_tracked_fragments names, options, &block
      end
    end

    # Remove the cache_path if the_casher is a file store
    def sweep_file_store( options = {} )
      if the_cacher.is_a?(ActiveSupport::Cache::FileStore) && the_cacher.cache_path && File.exists?(the_cacher.cache_path)
        $stdout.puts "Delete File Store: #{the_cacher.cache_path}" if options[:verbose]
        FileUtils.rm_rf the_cacher.cache_path
      else
        $stdout.puts "No File Store: #{the_cacher.cache_path if the_cacher.respond_to?(:cache_path) }" if options[:verbose]
      end
    end
  end
end