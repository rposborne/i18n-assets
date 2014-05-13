require 'sprockets'

module Sprockets
  LOCALIZABLE_ASSETS_REGEX = /\.(?:js|css)/

  module Helpers
    module RailsHelper

      # add locale to asset_prefix, if assets compiled
      def asset_prefix_with_locale
        if Rails.env.development?
          Rails.application.config.assets.prefix
        else
          "#{ Rails.application.config.assets.prefix }/#{ I18n.locale }"
        end
      end

      alias_method :asset_path_without_locale, :asset_path

      # prevent asset from caching by adding timestamp
      def asset_path(source, options = {})
        assert_prefix = asset_prefix_with_locale
        asset_path = asset_path_without_locale(source, options)

        if asset_path =~ LOCALIZABLE_ASSETS_REGEX
          separator = asset_path =~ /\?/ ? '&' : '?'
          "#{ asset_path }#{ separator }locale=#{ I18n.locale }&t=#{ Time.now.to_i }"
        else
          asset_path
        end
      end
      
      alias_method :path_to_asset, :asset_path

    end
  end

  class StaticCompiler

    alias_method :compile_without_manifest, :compile

    # run compile for each available locale
    def compile(*paths)
      I18n.available_locales.each do |locale|
        env.logger.info "Compiling assets for #{ locale.upcase } locale..."

        I18n.locale = locale

        manifest = Sprockets::Manifest.new(env, target)
        manifest.compile *paths
      end

      I18n.locale = I18n.default_locale
    end

  end

  class Asset

    alias_method :digest_path_without_locale, :digest_path

    # add locale for css and js files
    def digest_path
      digest_path = digest_path_without_locale
      if digest_path =~ LOCALIZABLE_ASSETS_REGEX
        "#{ I18n.locale }/#{ digest_path }"
      else
        digest_path
      end
    end

  end

  class Base

    # set locale for asset request
    def call(env)
      I18n.locale = Rack::Request.new(env).params['locale'] || I18n.default_locale
      super
    end

    # add locale to assets cache key
    def cache_key_for(path, options)
      "#{path}:#{I18n.locale}:#{options[:bundle] ? '1' : '0'}"
    end
  
  end

end