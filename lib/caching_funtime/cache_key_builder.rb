module CachingFuntime
  CacheKeyBuilder = Struct.new( :controller, :action, :dynamic_parameter_list, :base_parameters ) unless defined? CachingFuntime::CacheKeyBuilder
  class CacheKeyBuilder

    cattr_accessor :parameter_types
    @@parameter_types = {}

    cattr_accessor :tracked_fragments
    @@tracked_fragments = {}
    
    cattr_accessor :dynamic_input_transforms
    @@dynamic_input_transformations = {}
    
    def initialize( *args )
      super( *args )
      self.base_parameters        ||= {}
      self.dynamic_parameter_list ||= []
    end

    # Return all the base parameters including the controller and the action
    def all_base_parameters
      base_parameters.reverse_merge( :controller => self.controller, :action => self.action )
    end

    # interate through all permutations of cache key parameters
    def all_fragments( &block )
      collect_parameters(all_base_parameters, &block)
    end

    #recursively return the cache key map of parameters permutations of this cache key
    def collect_parameters( map, idx = 0, &block )#:nodoc:
      name = self.dynamic_parameter_list[ idx ]
      self.class.parameter_types[ name ].each do | value |
        map[ name ] = value
        if idx == self.dynamic_parameter_list.length - 1
          yield map
        else
          collect_parameters( map, idx + 1, &block )
        end
      end
    end

    # convert the inputs to cache key params
    # builder.cache_key_params(:user => current_user, :geo => current_geography)
    def cache_key_params( dynamic_inputs = {} )
      # for each defined dynamic parameter, add a value by calling the Proc (value in dynamic_parameter_list)
      dynamic_params = self.dynamic_parameter_list.inject( {} ) do | params, key |
        params[ key ] ||= dynamic_input_transforms[ key ].call( dynamic_inputs )
        params
      end

      all_params( dynamic_params )
    end

    def all_params( dynamic_params = {} )
      all_base_parameters.merge( dynamic_params )
    end
  
    class << self
      # return the fragment (CacheKeyBuilder instance) with +name+
      def tracked_fragment( name )
        frag = self.tracked_fragments[ name.to_sym ]
        raise "UNKNOWN FRAGMENT: #{name.inspect}. Please define in CachingFuntime::CacheKeyBuilder.tracked_fragments " unless frag
        frag
      end

      # return the params that can be send to url_for, expire_fragment, cache, etc
      # for the named CacheKeyBuilder and input params
      def cache_key_params( name, dynamic_inputs = {} )
        tracked_fragment( name ).cache_key_params( dynamic_inputs )
      end

      # Return all permutations of +fragments+
      # Return all when
      def all_tracked_fragments( fragments = nil, additional_params = {}, &block )
        fragments ||= self.tracked_fragments.keys
        [ fragments ].flatten.each do | name |
          tracked_fragment( name ).all_fragments { |params| yield name.to_sym, params.merge( additional_params ) }
        end
      end
    end
  end
end
