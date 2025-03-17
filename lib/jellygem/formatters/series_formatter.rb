# frozen_string_literal: true

module Jellygem
  module Formatters
    # Formatter for TV series
    # Handles generating NFO metadata files and proper folder names for TV series
    class SeriesFormatter < BaseFormatter
      # Format series NFO content for media servers
      # @param series [Models::Series] series data
      # @return [String] formatted NFO XML content
      def format_nfo(series)
        @logger.debug("Formatting series NFO for: #{series.name}")
        nfo_content = build_base_series_nfo(series)
        nfo_content = add_extended_metadata_to_nfo(nfo_content, series)
        nfo_content = add_genres_to_nfo(nfo_content, series)
        nfo_content = add_artwork_references_to_nfo(nfo_content)
        nfo_content << "  </tvshow>\n"
        nfo_content
      end

      # Format series folder name
      # @param series [Models::Series] series data
      # @return [String] formatted folder name
      def format_folder_name(series)
        series.year ? "#{series.name} (#{series.year})" : series.name
      end

      private

      # Builds the base series NFO structure
      # @param series [Models::Series] series data
      # @return [String] base NFO XML content
      def build_base_series_nfo(series)
        content = <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <tvshow>
            <title>#{escape_xml(series.name)}</title>
        XML

        # Add original title if different
        if series.original_name && series.original_name != series.name
          content << "    <originaltitle>#{escape_xml(series.original_name)}</originaltitle>\n"
        end

        content
      end

      # Adds extended metadata to the series NFO
      # @param content [String] current NFO content
      # @param series [Models::Series] series data
      # @return [String] updated NFO content
      def add_extended_metadata_to_nfo(content, series)
        content << <<~XML
          <year>#{series.year || ''}</year>
          <rating>#{series.vote_average || ''}</rating>
          <plot>#{escape_xml(series.overview || '')}</plot>
          <status>#{escape_xml(series.status || '')}</status>
        XML

        # Add network if available
        content << "    <network>#{escape_xml(series.networks.first['name'])}</network>\n" if series.networks&.any?

        content
      end

      # Adds genre information to the series NFO
      # @param content [String] current NFO content
      # @param series [Models::Series] series data
      # @return [String] updated NFO content
      def add_genres_to_nfo(content, series)
        # Add genres
        if series.genres&.any?
          series.genres.each do |genre|
            content << "    <genre>#{escape_xml(genre['name'])}</genre>\n"
          end
        end

        content
      end

      # Adds artwork references to the series NFO
      # @param content [String] current NFO content
      # @return [String] updated NFO content
      def add_artwork_references_to_nfo(content)
        # Add poster and fanart references
        content << "    <poster>poster.jpg</poster>\n"
        content << "    <fanart>fanart.jpg</fanart>\n"

        content
      end
    end
  end
end
