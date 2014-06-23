require 'sprockets'

module Sprockets
  LOCALIZABLE_ASSETS_REGEX = /\.(?:js|css)/

  module Helpers
    module RailsHelper

      # add locale to asset_prefix, if assets compiled
      def asset_prefix
        if Rails.env.development?
          Rails.application.config.assets.prefix
        else
          "#{ Rails.application.config.assets.prefix }/#{ I18n.locale }"
        end
      end

      alias_method :asset_path_without_locale, :asset_path

      # prevent asset from caching by adding timestamp
      def asset_path(source, options = {})
        asset_path = asset_path_without_locale(source, options)

        if asset_path =~ LOCALIZABLE_ASSETS_REGEX
          separator = asset_path =~ /\?/ ? '&' : '?'
          "#{ asset_path }#{ separator }t=#{ Time.now.to_i }"
        else
          asset_path
        end
      end

      alias_method :path_to_asset, :asset_path

    end
  end

  class StaticCompiler

    # alias_method :compile_without_manifest, :compile
    #
    # # run compile for each available locale
    # def compile(*paths)
    #   I18n.available_locales.each do |locale|
    #     env.logger.info "Compiling assets for #{ locale.upcase } locale..."
    #
    #     I18n.locale = locale
    #
    #     manifest = Sprockets::Manifest.new(env, target)
    #     manifest.compile *paths
    #   end
    #
    #   I18n.locale = I18n.default_locale
    # end

    def compile
      manifest = {}
      env.each_logical_path(paths) do |logical_path|
        process = lambda do
          if asset = env.find_asset(logical_path)
            digest_path = write_asset(asset)
            manifest[asset.logical_path] = digest_path
            manifest[aliased_path_for(asset.logical_path)] = digest_path
          end
        end

        if logical_path =~ LOCALIZABLE_ASSETS_REGEX
          I18n.available_locales.each do |locale|
            I18n.locale = locale
            process.call
          end
        else
          process.call
        end
      end

      I18n.locale = I18n.default_locale

      write_manifest(manifest) if @manifest
    end

  end

  class Asset

    alias_method :logical_path_without_locale, :logical_path

    # add locale for css and js files
    def logical_path
      logical_path = logical_path_without_locale
      if !Rails.env.development? && logical_path =~ LOCALIZABLE_ASSETS_REGEX
        "#{ I18n.locale }/#{ logical_path }"
      else
        logical_path
      end
    end

  end

  class Base

    # set locale for asset request
    def call(env)
      locale = extract_locale(env['PATH_INFO'])
      env['PATH_INFO'].gsub!(Regexp.new("^/#{ locale }"), '') if locale
      I18n.locale = Rack::Request.new(env).params['locale'] || locale || I18n.default_locale
      super
    end

    # add locale to assets cache key
    def cache_key_for(path, options)
      "#{path}:#{I18n.locale}:#{options[:bundle] ? '1' : '0'}"
    end

    private

      def extract_locale(path)
        locale = path[/^\/([a-z\-_]+?)\//, 1]
        if I18n.available_locales.map(&:to_s).include? locale
          locale
        else
          nil
        end
      end

  end

end
