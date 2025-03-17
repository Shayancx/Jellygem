# frozen_string_literal: true

module Jellygem
  module Processors
    # Series processor handles the main processing of TV series folders
    # Coordinates the processing of seasons and episodes
    class SeriesProcessor < BaseProcessor
      def initialize
        super
        initialize_collaborators
      end

      # Main processing entry point
      # @param series_folder [String] path to series folder
      # @return [Boolean] true if successful
      def process(series_folder)
        # Verify the folder exists
        raise "Cannot process: not a directory: #{series_folder}" unless File.directory?(series_folder)

        folder_name = File.basename(series_folder)
        show_header("Processing Series Folder: #{folder_name}")

        # Get series information and process
        process_series_folder(series_folder, folder_name)
      end

      private

      # Initialize collaborator objects
      # @return [void]
      def initialize_collaborators
        @season_processor = SeasonProcessor.new
        @episode_processor = EpisodeProcessor.new
        @metadata_processor = MetadataProcessor.new
        @formatter = Formatters::SeriesFormatter.new
        @artwork_handler = SeriesArtworkHandler.new(@tmdb_client, @config, @logger)
        @info_formatter = SeriesInfoFormatter.new
        @search_handler = SeriesSearchHandler.new(@tmdb_client, self)
      end

      # Process the series folder
      # @param series_folder [String] path to series folder
      # @param folder_name [String] series folder name
      # @return [Boolean] true if successful
      def process_series_folder(series_folder, folder_name)
        # Get series information from user
        series = @search_handler.get_series_from_user(folder_name)
        return false unless series

        # Display series info and confirm
        display_series_info(series)
        unless confirm_continue
          puts warning('Skipping this series.')
          return false
        end

        finalize_series_processing(series_folder, series)
      end

      # Complete the processing of the series
      # @param series_folder [String] path to series folder
      # @param series [Models::Series] series model
      # @return [Boolean] true if successful
      def finalize_series_processing(series_folder, series)
        renamed_folder = rename_series_folder(series_folder, series)
        create_series_metadata(renamed_folder, series)
        process_series_artwork(series, renamed_folder)
        process_seasons_and_episodes(renamed_folder, series)

        puts success("\nCompleted processing #{series.name}.")
        true
      end

      # Process series artwork (if enabled)
      # @param series [Models::Series] series model
      # @param renamed_folder [String] path to series folder
      # @return [void]
      def process_series_artwork(series, renamed_folder)
        return if @config.skip_images

        @artwork_handler.download_series_artwork(series, renamed_folder)
      end

      # Ask for confirmation to continue
      # @return [Boolean] true if user confirms
      def confirm_continue
        @config.no_prompt || prompt_yes_no('Continue processing this series?', default: true)
      end

      # Rename the series folder if needed
      # @param series_folder [String] path to series folder
      # @param series [Models::Series] series model
      # @return [String] updated series folder path
      def rename_series_folder(series_folder, series)
        new_folder_name = @formatter.format_folder_name(series)
        new_series_folder = rename_folder(series_folder, new_folder_name)

        if new_series_folder != series_folder
          puts success("Renamed series folder to: #{File.basename(new_series_folder)}")
          return new_series_folder
        end

        series_folder
      end

      # Create series metadata
      # @param series_folder [String] path to series folder
      # @param series [Models::Series] series model
      # @return [Boolean] true if successful
      def create_series_metadata(series_folder, series)
        @metadata_processor.create_series_metadata(series, series_folder)
      end

      # Display series information
      # @param series [Models::Series] series model
      # @return [void]
      def display_series_info(series)
        formatted_info = @info_formatter.format_series_info(series)
        puts formatted_info
      end

      # Find and process all seasons and episodes
      # @param series_folder [String] path to series folder
      # @param series [Models::Series] series model
      # @return [void]
      def process_seasons_and_episodes(series_folder, series)
        # First, check if there are video files directly in the series folder
        process_root_video_files(series_folder, series)

        # Look for and process season folders
        process_season_folders(series_folder, series)
      end

      # Process video files in the root series folder
      # @param series_folder [String] path to series folder
      # @param series [Models::Series] series model
      # @return [void]
      def process_root_video_files(series_folder, series)
        @episode_processor.process_files(series_folder, series, 1)
      end

      # Process season folders
      # @param series_folder [String] path to series folder
      # @param series [Models::Series] series model
      # @return [void]
      def process_season_folders(series_folder, series)
        # Look for season folders
        season_dirs = find_season_directories(series_folder)

        if season_dirs.empty?
          puts warning('No season folders found.')
          return
        end

        puts "\nFound #{season_dirs.length} season folders."

        # Process each season folder
        season_dirs.each do |season_dir|
          @season_processor.process(season_dir, series)
        end
      end

      # Find season directories
      # @param series_folder [String] path to series folder
      # @return [Array<String>] list of season directory paths
      def find_season_directories(series_folder)
        Dir.glob(File.join(series_folder, '*')).select do |f|
          File.directory?(f) && File.basename(f) =~ /\b(?:S\d+|[Ss]eason\s*\d+)/
        end
      end
    end
  end
end
