# frozen_string_literal: true

module Jellygem
  module Formatters
    # Formatter for TV show seasons
    # Handles generating NFO metadata files and proper folder names for seasons
    class SeasonFormatter < BaseFormatter
      # Format season NFO content for media servers
      # @param season [Models::Season] season data
      # @param series [Models::Series] parent series data
      # @return [String] formatted NFO XML content
      def format_nfo(season, series)
        @logger.debug("Formatting season NFO for: Season #{season.season_number}")
        nfo_content = build_base_season_nfo(season)
        nfo_content = add_series_info_to_nfo(nfo_content, series, season)
        nfo_content = add_season_metadata_to_nfo(nfo_content, season)
        nfo_content << "    <poster>season.jpg</poster>\n"
        nfo_content << "  </season>\n"
        nfo_content
      end

      # Format season folder name
      # @param season [Models::Season] season data
      # @return [String] formatted folder name
      def format_folder_name(season)
        # Generate standard format: S01 or S01_Name if name isn't just "Season X"
        base = "S#{season.season_number.to_s.rjust(2, '0')}"

        # Only append name if it's meaningful (not just "Season X")
        if season.name && !season.name.match?(/^Season\s+\d+$/i)
          format_filename(base, season.name)
        else
          base
        end
      end

      private

      # Builds the base season NFO structure
      # @param season [Models::Season] season data
      # @return [String] base NFO XML content
      def build_base_season_nfo(season)
        <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <season>
            <number>#{season.season_number}</number>
        XML
      end

      # Adds series information to the season NFO
      # @param content [String] current NFO content
      # @param series [Models::Series] parent series data
      # @param season [Models::Season] season data
      # @return [String] updated NFO content
      def add_series_info_to_nfo(content, series, season)
        # Add series title
        content << "    <showtitle>#{escape_xml(series.name)}</showtitle>\n" if series

        # Add season name if not just "Season X"
        if season.name && !season.name.match?(/^Season\s+\d+$/i)
          content << "    <title>#{escape_xml(season.name)}</title>\n"
        end

        content
      end

      # Adds basic season metadata to NFO
      # @param content [String] current NFO content
      # @param season [Models::Season] season data
      # @return [String] updated NFO content
      def add_season_metadata_to_nfo(content, season)
        content << <<~XML
          <plot>#{escape_xml(season.overview || '')}</plot>
          <premiered>#{season.air_date || ''}</premiered>
          <episode_count>#{season.episode_count || ''}</episode_count>
        XML

        content
      end
    end
  end
end
