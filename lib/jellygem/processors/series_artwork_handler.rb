# frozen_string_literal: true

module Jellygem
  module Processors
    # Helper class to handle downloading and managing series artwork
    # Extracted from SeriesProcessor to reduce complexity
    class SeriesArtworkHandler
      include Utils::UIHelper
      include Utils::FileHelper

      def initialize(tmdb_client, config, logger)
        @tmdb_client = tmdb_client
        @config = config
        @logger = logger
      end

      # Download series artwork (poster and fanart)
      # @param series [Models::Series] series model
      # @param series_folder [String] path to series folder
      # @return [Boolean] true if at least one artwork was downloaded
      def download_series_artwork(series, series_folder)
        puts "\nDownloading series artwork..."

        # Skip if folder doesn't exist
        unless File.directory?(series_folder)
          puts error("Cannot download artwork: series folder does not exist: #{series_folder}")
          return false
        end

        poster_success = download_series_poster(series, series_folder)
        fanart_success = download_series_fanart(series, series_folder)

        poster_success || fanart_success
      end

      # Download series poster
      # @param series [Models::Series] series model
      # @param series_folder [String] path to series folder
      # @return [Boolean] true if successful
      def download_series_poster(series, series_folder)
        return false unless series&.poster_path

        poster_url = @tmdb_client.image_url(series.poster_path)
        return false unless poster_url

        poster_path = File.join(series_folder, 'poster.jpg')
        if download_image(poster_url, poster_path)
          puts success('Downloaded series poster.')
          return true
        end

        false
      end

      # Download series fanart/backdrop
      # @param series [Models::Series] series model
      # @param series_folder [String] path to series folder
      # @return [Boolean] true if successful
      def download_series_fanart(series, series_folder)
        return false unless series&.backdrop_path

        backdrop_url = @tmdb_client.image_url(series.backdrop_path)
        return false unless backdrop_url

        backdrop_path = File.join(series_folder, 'fanart.jpg')
        if download_image(backdrop_url, backdrop_path)
          puts success('Downloaded series fanart.')
          return true
        end

        puts warning('No backdrop available for this series.')
        false
      end
    end
  end
end
