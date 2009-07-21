# CachingFuntime
require File.dirname(__FILE__) + '/caching_funtime/acts_as_cacher'
require File.dirname(__FILE__) + '/caching_funtime/cache_key_builder'
require File.dirname(__FILE__) + '/caching_funtime/extended_fragment_support'
require File.dirname(__FILE__) + '/caching_funtime/extended_page_support'
require File.dirname(__FILE__) + '/caching_funtime/extended_asset_support'

module CachingFuntime
  def self.included( base )
    base.send :include,  ActsAsCacher
    base.send :include,  ExtendedFragmentSupport
    base.send :include,  ExtendedPageSupport
    base.send :include,  ExtendedAssetSupport
  end
end
