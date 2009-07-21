module CachingFuntime
  class TheCacher
    include ActsAsSingletonCacher
    extend  ExtendedFragmentSupport
    extend  ExtendedPageSupport
    extend  ExtendedAssetSupport
  end
end

CachingFuntime::TheCacher.the_cacher ||= CachingFuntime::TheCacher.instance
