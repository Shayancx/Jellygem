# frozen_string_literal: true

module Jellygem
  module Processors
    # Season processor handles processing of season folders
    # Renames folders according to naming convention and adds metadata
    class SeasonProcessor < BaseProcessor
      def initialize
        super
        @episode_processor = EpisodeProcessor.new
        @metadata_processor = MetadataProcessor.new
        @formatter = Formatters::SeasonFormatter.new
      end

      # Process a season folder
      # @param season_folder [String] path to season folder
      # @param series [Models::Series] parent series data
      # @return [Models::Season] processed season model
      def process(season_folder, series)
        folder_name = File.basename(season_folder)
        season_num = get_season_number(folder_name)

        puts "\nProcessing Season #{season_num} (#{folder_name})..."

        # Get season details and create season model
        season = create_season_model(series.id, season_num)

        # Process the season folder
        process_season_folder(season_folder, season, series)

        # Return the processed season
        season
      end

      private

      # Get season number from folder name or ask user
      # @param folder_name [String] season folder name
      # @return [Integer] season number
      def get_season_number(folder_name)
        # Try to detect season number from the folder name
        season_num = detect_season_number(folder_name)

        unless season_num
          puts warning("\nCould not automatically determine season number for folder: #{folder_name}")
          season_num = prompt('Enter season number', '1').to_i
        end

        season_num
      end

      # Create a season model with data from TMDB
      # @param series_id [Integer] TMDB series ID
      # @param season_num [Integer] season number
      # @return [Models::Season] season model
      def create_season_model(series_id, season_num)
        # Get season details from TMDB
        season_details = @tmdb_client.fetch_season_details(series_id, season_num)

        # Create a Season model
        if season_details
          Models::Season.new(season_details)
        else
          # Create minimal season object
          Models::Season.new({
                               'season_number' => season_num,
                               'name' => "Season #{season_num}"
                             })
        end
      end

      # Process the season folder - rename, add metadata, process episodes
      # @param season_folder [String] path to season folder
      # @param season [Models::Season] season model
      # @param series [Models::Series] parent series data
      # @return [void]
      def process_season_folder(season_folder, season, series)
        # Rename the season folder if needed
        new_season_name = @formatter.format_folder_name(season)
        new_season_folder = rename_folder(season_folder, new_season_name)

        if new_season_folder != season_folder
          puts success("Renamed season folder to: #{File.basename(new_season_folder)}")
          season_folder = new_season_folder
        end

        # Download season poster if available
        download_season_artwork(series.id, season, season_folder) unless @config.skip_images

        # Create season metadata
        @metadata_processor.create_season_metadata(season, season_folder, series)

        # Process episode files in this season folder
        @episode_processor.process_files(season_folder, series, season.season_number, season)
      end

      # Download season poster or artwork
      # @param series_id [Integer] TMDB series ID
      # @param season [Models::Season] season model
      # @param season_folder [String] path to season folder
      # @return [Boolean] true if successful
      def download_season_artwork(series_id, season, season_folder)
        poster_path = File.join(season_folder, 'season.jpg')

        # Try direct poster if available
        if season.poster_path
          poster_url = @tmdb_client.image_url(season.poster_path)
          return puts success('Downloaded season poster.') if download_image(poster_url, poster_path)
        end

        # Try to fetch season images and get the best one if direct poster not available
        download_best_season_poster(series_id, season.season_number, poster_path)
      end

      # Find and download the best rated season poster
      # @param series_id [Integer] TMDB series ID
      # @param season_number [Integer] season number
      # @param poster_path [String] path to save poster
      # @return [Boolean] true if successful
      def download_best_season_poster(series_id, season_number, poster_path)
        season_images = @tmdb_client.fetch_season_images(series_id, season_number)

        if season_images && !season_images['posters'].empty?
          # Get best rated poster
          best_poster = season_images['posters'].max_by { |p| p['vote_average'] || 0 }
          poster_url = @tmdb_client.image_url(best_poster['file_path'])

          if download_image(poster_url, poster_path)
            puts success('Downloaded season poster.')
            return true
          end
        end

        puts warning('No season poster available from TMDB.')
        false
      end
    end
  end
end
