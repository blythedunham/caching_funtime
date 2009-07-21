# Utility to accesss the caching methods
#   KashCache::TheCacher.expire_fragment(:controller => 'listings', :action => 'index')
#
# class MyClass
#   include ActsAsCacher
# end
#
# MyClass.new.delete_fragment(:controller => 'listings', :action => 'index')
#
# This file is not automatically included as it instanciates its own memcache. Please manually include
#  require 'caching_funtime/acts_as_cacher'
#
#  CachingFuntime::TheCacher.read_fragment( :controller => 'grapes', :action => 'fun' )
# Requiring this class shares @@perform_caching and @@cache_store with
# ActionController::Base. Don't include if using with action controller

module CachingFuntime
  module Caching
    autoload :Actions,    'action_controller/caching/actions'
    autoload :Fragments,  'action_controller/caching/fragments'
    autoload :Pages,      'action_controller/caching/pages'
    autoload :Sweeper,    'action_controller/caching/sweeping'
    autoload :Sweeping,   'action_controller/caching/sweeping'

    def self.included(base) #:nodoc:
      base.class_eval do
        class_inheritable_accessor :perform_caching
        class_inheritable_accessor :cache_store

        include ActionController::Caching::Pages
        include ActionController::Caching::Actions
        include ActionController::Caching::Fragments
        include ActionController::Caching::Sweeping if defined?(::ActiveRecord)

        def self.cache_store=(store_option)
           write_inheritable_attribute(:cache_store, ActiveSupport::Cache.lookup_store(store_option));
        end

        def self.cache_configured?
          perform_caching && cache_store
        end
      end
 
      base.cache_store =     ::Rails.configuration.cache_store
      base.perform_caching = ::Rails.configuration.action_controller.perform_caching
    end

    protected
      # Convenience accessor
      def cache(key, options = {}, &block)
        if cache_configured?
          cache_store.fetch(ActiveSupport::Cache.expand_cache_key(key, :controller), options, &block)
        else
          yield
        end
      end

    private
      def cache_configured?
        self.class.cache_configured?
      end
  end

  module ActsAsCacher
    def self.included(base)
      base.send :class_inheritable_accessor, :logger
      base.send :include,   ::ActionController::UrlWriter
      base.send :include,   ::CachingFuntime::Caching
      base.send :include,   ::ActionController::Benchmarking
    end

    def perform_action; end;
    def render; end;
  end

  # A singleton. when included both MyClass.cache_method and 
  # MyClass.instance.cache_method work
  module ActsAsSingletonCacher
    def self.included(base)
      base.send :include, Singleton
      base.send :include, ActsAsCacher
      base.send :extend,  ActsAsSingletonCacher::ClassMethods
    end
    module ClassMethods
      def method_missing(method, *args, &block)
        if self.instance.respond_to?(method)
          self.instance.send(method, *args, &block)
        else
          super(method, *args, &block)
        end
      end
    end
  end
end