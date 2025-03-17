# frozen_string_literal: true

module Jellygem
  module Processors
    # Series processor handles the main processing of TV series folders
    # Coordinates the processing of seasons and episodes
    class SeriesProcessor < BaseProcessor
      def initialize
        super
        @season_processor = SeasonProcessor.new
        @episode_processor = EpisodeProcessor.new
        @metadata_processor = MetadataProcessor.new
        @formatter = Formatters::SeriesFormatter.new
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

      # Process the series folder
      # @param series_folder [String] path to series folder
      # @param folder_name [String] series folder name
      # @return [Boolean] true if successful
      def process_series_folder(series_folder, folder_name)
        # Get series information from user
        series = get_series_from_user(folder_name)
        return false unless series

        # Display series info and confirm
        display_series_info(series)
        unless confirm_continue
          puts warning('Skipping this series.')
          return false
        end

        # Process the series
        renamed_folder = rename_series_folder(series_folder, series)
        create_series_metadata(renamed_folder, series)
        download_series_artwork(series, renamed_folder) unless @config.skip_images
        process_seasons_and_episodes(renamed_folder, series)

        puts success("\nCompleted processing #{series.name}.")
        true
      end

      # Ask for confirmation to continue
      # @return [Boolean] true if user confirms
      def confirm_continue
        @config.no_prompt || prompt_yes_no('Continue processing this series?')
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

      # Get series information based on user input
      # @param folder_name [String] series folder name
      # @return [Models::Series, nil] series model or nil if cancelled
      def get_series_from_user(folder_name)
        # Ask user for series name
        puts "\nPlease enter the series name in 'Name (Year)' format:"
        suggested_name = process_folder_name(folder_name)
        series_name = prompt('Series name', suggested_name)

        return nil if series_name.empty?

        # Search for the series on TMDB
        series_results = search_for_series(series_name)
        return nil unless series_results

        # Let user choose from results
        selected_result = get_user_selection(series_results)
        return nil unless selected_result

        # Get detailed series info
        get_detailed_series_data(selected_result)
      end

      # Search for a series on TMDB
      # @param series_name [String] series name to search for
      # @return [Array, nil] search results or nil if none found
      def search_for_series(series_name)
        puts info("\nSearching for series '#{series_name}'...")
        results = @tmdb_client.search_tv_series(series_name)

        if !results || results.empty?
          puts warning("No results found for '#{series_name}'. Please try again with a different name.")
          return nil
        end

        results
      end

      # Let user select the correct series from search results
      # @param results [Array] search results
      # @return [Hash, nil] selected result or nil if invalid
      def get_user_selection(results)
        puts "\nFound #{results.length} potential matches. Please select the correct series:"

        # Only show top 5 results
        top_results = results.take(5)
        display_search_results(top_results)

        # Let user choose
        choice = prompt("Select the correct series (1-#{top_results.length})", '1').to_i

        if choice < 1 || choice > top_results.length
          puts warning('Invalid selection. Exiting.')
          return nil
        end

        # Get selected series
        selected_result = top_results[choice - 1]
        display_selected_series(selected_result)

        selected_result
      end

      # Display search results for selection
      # @param results [Array] search results to display
      # @return [void]
      def display_search_results(results)
        results.each_with_index do |result, idx|
          year = result['first_air_date'] ? result['first_air_date'][0..3] : 'N/A'
          popularity = result['popularity']&.round(1) || 'N/A'
          puts "#{idx + 1}. #{result['name']} (#{year}) - Popularity: #{popularity}"
        end
      end

      # Display the selected series
      # @param result [Hash] selected search result
      # @return [void]
      def display_selected_series(result)
        year = result['first_air_date'] ? result['first_air_date'][0..3] : 'N/A'
        puts success("\nSelected: #{result['name']} (#{year})")
      end

      # Get detailed series data from TMDB
      # @param selected_result [Hash] selected search result
      # @return [Models::Series] series model
      def get_detailed_series_data(selected_result)
        series_id = selected_result['id']
        detailed_data = @tmdb_client.fetch_series_details(series_id)

        if !detailed_data
          puts warning('Failed to get detailed information for the series. Using basic info instead.')
          Models::Series.new(selected_result)
        else
          Models::Series.new(detailed_data)
        end
      end

      # Display series information
      # @param series [Models::Series] series model
      # @return [void]
      def display_series_info(series)
        puts "\nSeries Information:"
        puts "  Title: #{info(series.name)}"

        puts "  Original Title: #{series.original_name}" if series.original_name && series.original_name != series.name

        puts "  Year: #{series.year || 'Unknown'}"
        puts "  Status: #{series.status}" if series.status

        display_series_overview(series)
        display_series_genres(series)
      end

      # Display series overview if available
      # @param series [Models::Series] series model
      # @return [void]
      def display_series_overview(series)
        return unless series.overview

        # Truncate long overviews
        overview = if series.overview.length > 200
                     "#{series.overview[0..200]}..."
                   else
                     series.overview
                   end
        puts "  Overview: #{overview}"
      end

      # Display series genres if available
      # @param series [Models::Series] series model
      # @return [void]
      def display_series_genres(series)
        return unless series.genres && !series.genres.empty?

        genre_names = series.genres.map { |g| g['name'] }.join(', ')
        puts "  Genres: #{genre_names}"
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

      # Find and process all seasons and episodes
      # @param series_folder [String] path to series folder
      # @param series [Models::Series] series model
      # @return [void]
      def process_seasons_and_episodes(series_folder, series)
        # First, check if there are video files directly in the series folder
        @episode_processor.process_files(series_folder, series, 1)

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
