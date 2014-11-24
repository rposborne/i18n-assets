unless defined?(Sprockets::LOCALIZABLE_ASSETS_REGEX)
  require 'sprockets'

  module Sprockets

    LOCALIZABLE_ASSETS_EXT = %w( js css )
    LOCALIZABLE_ASSETS_REGEX = Regexp.new("\\.(?:#{ LOCALIZABLE_ASSETS_EXT * '|' })")
    LOCALIZABLE_COMPILABLE_ASSETS_REGEX = Regexp.new("\\.(?:#{ LOCALIZABLE_ASSETS_EXT * '|' })\\..+$")
    GLOBAL_ASSET_REGEX = /^(https?)?:\/\//

    class Manifest

      def compile(*args)
        unless environment
          raise Error, "manifest requires environment for compilation"
        end

        paths = environment.each_logical_path(*args).to_a +
          args.flatten.select { |fn| Pathname.new(fn).absolute? if fn.is_a?(String)}

        paths.each do |path|
          I18n.available_locales.each do |locale|
            I18n.locale = locale

            if asset = find_asset(path)
              files[asset.digest_path] = {
                'logical_path' => asset.logical_path,
                'mtime'        => asset.mtime.iso8601,
                'size'         => asset.bytesize,
                'digest'       => asset.digest
              }
              assets[asset.logical_path] = asset.digest_path

              target = if asset.digest_path.start_with?("#{ I18n.locale.to_s }/")
                File.join(dir, asset.digest_path)
              else
                File.join(dir, I18n.locale.to_s, asset.digest_path)
              end

              if File.exist?(target)
                logger.debug "Skipping #{target}, already exists"
              else
                logger.info "Writing #{target}"
                asset.write_to target
                asset.write_to "#{target}.gz" if asset.is_a?(BundledAsset)
              end

            end
          end
        end

        I18n.locale = I18n.default_locale

        save
        paths
      end

    end

    class Asset

      protected

        alias_method :dependency_fresh_without_check?, :dependency_fresh?
        def dependency_fresh?(environment, dep)
          return false if ::Rails.configuration.assets.prevent_caching && dep.pathname.to_s =~ LOCALIZABLE_COMPILABLE_ASSETS_REGEX
          dependency_fresh_without_check?(environment, dep)
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

  module ActionView
    module Helpers
      module AssetUrlHelper

        alias_method :asset_path_without_locale, :asset_path

        # prevent asset from caching by adding timestamp
        def asset_path(source, options = {})
          source = source.to_s
          return "" unless source.present?
          return source if source =~ URI_REGEXP

          tail, source = source[/([\?#].+)$/], source.sub(/([\?#].+)$/, '')

          if extname = compute_asset_extname(source, options)
            source = "#{source}#{extname}"
          end

          if source[0] != ?/
            source = compute_asset_path(source, options)
          end

          relative_url_root = defined?(config.relative_url_root) && config.relative_url_root
          if relative_url_root
            source = File.join(relative_url_root, source) unless source.starts_with?("#{relative_url_root}/")
          end

          if host = compute_asset_host(source, options)
            source = File.join(host, source)
          end

          tail ||= ''

          if !digest_assets? && !tail.include?('locale') && source =~ Sprockets::LOCALIZABLE_ASSETS_REGEX
            separator = source.include?('?') || tail.include?('?') ? '&' : '?'
            tail = "#{ tail }#{ separator }t=#{ Time.now.to_i }&locale=#{ I18n.locale }"
          end

          "#{source}#{tail}".html_safe
        end
        alias_method :path_to_asset, :asset_path

      end
    end
  end
end
