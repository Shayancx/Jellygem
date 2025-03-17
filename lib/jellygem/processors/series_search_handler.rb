# frozen_string_literal: true

module Jellygem
  module Processors
    # Handler for searching and selecting series from TMDB
    # Extracted from SeriesProcessor to reduce class length
    class SeriesSearchHandler
      include Utils::UIHelper

      def initialize(tmdb_client, processor)
        @tmdb_client = tmdb_client
        @processor = processor
      end

      # Get series information based on user input
      # @param folder_name [String] series folder name
      # @return [Models::Series, nil] series model or nil if cancelled
      def get_series_from_user(folder_name)
        # Ask user for series name
        puts "\nPlease enter the series name in 'Name (Year)' format:"
        suggested_name = @processor.send(:process_folder_name, folder_name)
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
        selected_result = get_user_choice(top_results)

        display_selected_series(selected_result) if selected_result

        selected_result
      end

      # Get user's choice from search results
      # @param top_results [Array] top search results
      # @return [Hash, nil] selected result or nil if invalid
      def get_user_choice(top_results)
        choice = prompt("Select the correct series (1-#{top_results.length})", '1').to_i

        if choice < 1 || choice > top_results.length
          puts warning('Invalid selection. Exiting.')
          return nil
        end

        # Get selected series
        top_results[choice - 1]
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
    end
  end
end
