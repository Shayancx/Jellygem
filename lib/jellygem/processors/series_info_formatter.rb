# frozen_string_literal: true

module Jellygem
  module Processors
    # Helper class to format series information for display
    # Extracted from SeriesProcessor to reduce complexity
    class SeriesInfoFormatter
      include Utils::UIHelper

      # Format series information for display
      # @param series [Models::Series] series model
      # @return [String] formatted series information
      def format_series_info(series)
        info_sections = build_info_sections(series)
        info_sections.join("\n")
      end

      private

      # Build information sections for display
      # @param series [Models::Series] series model
      # @return [Array<String>] array of information sections
      def build_info_sections(series)
        sections = [
          "\nSeries Information:",
          "  Title: #{info(series.name)}"
        ]

        add_original_title(sections, series)
        add_basic_info(sections, series)
        add_overview(sections, series)
        add_genres(sections, series)

        sections
      end

      # Add original title section if different from title
      # @param sections [Array<String>] sections array
      # @param series [Models::Series] series model
      # @return [void]
      def add_original_title(sections, series)
        return unless series.original_name && series.original_name != series.name

        sections << "  Original Title: #{series.original_name}"
      end

      # Add basic information sections
      # @param sections [Array<String>] sections array
      # @param series [Models::Series] series model
      # @return [void]
      def add_basic_info(sections, series)
        sections << "  Year: #{series.year || 'Unknown'}"
        sections << "  Status: #{series.status}" if series.status
      end

      # Add overview section
      # @param sections [Array<String>] sections array
      # @param series [Models::Series] series model
      # @return [void]
      def add_overview(sections, series)
        return unless series.overview

        # Truncate long overviews
        overview = if series.overview.length > 200
                     "#{series.overview[0..200]}..."
                   else
                     series.overview
                   end
        sections << "  Overview: #{overview}"
      end

      # Add genres section
      # @param sections [Array<String>] sections array
      # @param series [Models::Series] series model
      # @return [void]
      def add_genres(sections, series)
        return unless series.genres&.any?

        genre_names = series.genres.map { |g| g['name'] }.join(', ')
        sections << "  Genres: #{genre_names}"
      end
    end
  end
end
