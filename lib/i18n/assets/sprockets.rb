unless defined?(Sprockets::LOCALIZABLE_ASSETS_REGEX)
  require 'sprockets'

  module Sprockets
    LOCALIZABLE_ASSETS_EXT = %w( js css )
    LOCALIZABLE_ASSETS_REGEX = Regexp.new("\\.(?:#{ LOCALIZABLE_ASSETS_EXT * '|' })")

    module Helpers
      module RailsHelper

        alias_method :asset_path_without_locale, :asset_path

        # prevent asset from caching by adding timestamp
        def asset_path(source, options = {})
          path = asset_path_without_locale(source, options)

          if path =~ LOCALIZABLE_ASSETS_REGEX
            separator = path =~ /\?/ ? '&' : '?'
            "#{ path }#{ separator }t=#{ Time.now.to_i }"
          else
            path
          end
        end

        alias_method :path_to_asset, :asset_path

      end
    end

    class StaticCompiler

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
        path = logical_path_without_locale
        if !Rails.env.development? && path =~ LOCALIZABLE_ASSETS_REGEX
          "#{ I18n.locale }/#{ path }"
        else
          path
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

  module ActionView
    class AssetPaths
      alias_method :compute_public_path_without_locale, :compute_public_path

      def compute_public_path(source, dir, options = nil)
        source = prepend_locale(source) if file_localizable?(source, options) && !file_already_localized?(source)
        compute_public_path_without_locale(source, dir, options)
      end

      private

        def prepend_locale(source)
          "#{ I18n.locale }/#{ source }"
        end

        def file_localizable?(source, options)
          source =~ Sprockets::LOCALIZABLE_ASSETS_REGEX || Sprockets::LOCALIZABLE_ASSETS_EXT.include?(options.try(:[], :ext))
        end

        def file_already_localized?(source)
          source.starts_with?("#{ I18n.locale }/")
        end

    end
  end
end
