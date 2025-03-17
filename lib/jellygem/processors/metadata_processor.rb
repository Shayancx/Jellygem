# frozen_string_literal: true

module Jellygem
  module Processors
    # Metadata processor handles creation of NFO files for media servers
    # Creates metadata files for series, seasons, and episodes
    class MetadataProcessor < BaseProcessor
      def initialize
        super
        @series_formatter = Formatters::SeriesFormatter.new
        @season_formatter = Formatters::SeasonFormatter.new
        @episode_formatter = Formatters::EpisodeFormatter.new
      end

      # Create series metadata file
      # @param series [Models::Series] series data
      # @param series_folder [String] path to series folder
      # @return [Boolean] true if successful
      def create_series_metadata(series, series_folder)
        return true if @config.dry_run

        nfo_path = File.join(series_folder, 'tvshow.nfo')
        create_metadata_file(nfo_path) do
          content = @series_formatter.format_nfo(series)
          File.write(nfo_path, content)
          puts success('Created series metadata file.')
          @logger.info("Created series NFO: #{nfo_path}")
          true
        end
      end

      # Create season metadata file
      # @param season [Models::Season] season data
      # @param season_folder [String] path to season folder
      # @param series [Models::Series] parent series data
      # @return [Boolean] true if successful
      def create_season_metadata(season, season_folder, series)
        return true if @config.dry_run

        nfo_path = File.join(season_folder, 'season.nfo')
        create_metadata_file(nfo_path) do
          content = @season_formatter.format_nfo(season, series)
          File.write(nfo_path, content)
          puts success('Created season metadata file.')
          @logger.info("Created season NFO: #{nfo_path}")
          true
        end
      end

      # Create episode metadata file
      # @param episode [Models::Episode] episode data
      # @param episode_path [String] path to episode file
      # @param series [Models::Series] parent series data
      # @return [Boolean] true if successful
      def create_episode_metadata(episode, episode_path, series)
        return true if @config.dry_run

        nfo_path = "#{File.dirname(episode_path)}/#{File.basename(episode_path, '.*')}.nfo"
        create_metadata_file(nfo_path) do
          content = @episode_formatter.format_nfo(episode, episode_path, series)
          File.write(nfo_path, content)
          @logger.info("Created episode NFO: #{nfo_path}")
          true
        end
      end

      private

      # Helper method to create metadata files with error handling
      # @param nfo_path [String] path to NFO file
      # @yield Block that creates the metadata file
      # @return [Boolean] true if successful
      def create_metadata_file(nfo_path)
        # Ensure the directory exists
        FileUtils.mkdir_p(File.dirname(nfo_path))

        # Execute the block to create the file
        yield
      rescue StandardError => e
        @logger.error("Failed to create NFO file #{nfo_path}: #{e.message}")
        false
      end
    end
  end
end
