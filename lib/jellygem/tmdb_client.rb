# frozen_string_literal: true

module Jellygem
  # Client for The Movie Database (TMDB) API
  # Handles searching and fetching TV series, season, and episode data
  class TMDBClient
    BASE_URL = 'https://api.themoviedb.org/3'

    def initialize
      @config = Jellygem.config
      @logger = Jellygem.logger
      @api_key = @config.tmdb_api_key
      @cache = {}
      @max_retries = @config.max_api_retries || 3
      @retry_delay = 5
      @request_handler = TMDBRequestHandler.new(@logger, @max_retries, @retry_delay, @cache)
    end

    # Search for TV series by name
    # @param query [String] search query
    # @return [Array, nil] search results or nil if not found
    def search_tv_series(query)
      # Normalize the query to handle different input formats
      @logger.debug("Original search query: #{query}")
      base_name, year = extract_name_and_year(query)
      @logger.debug("Normalized search query - Name: '#{base_name}', Year: #{year || 'none'}")

      # Perform search
      search_results = perform_series_search(base_name)
      return nil if search_results.nil?

      # Filter and sort results
      filter_and_sort_results(search_results, year)
    end

    # Fetch detailed information about a TV series
    # @param series_id [Integer] TMDB series ID
    # @return [Hash, nil] series data or nil if not found
    def fetch_series_details(series_id)
      return nil unless series_id

      url = "#{BASE_URL}/tv/#{series_id}"
      @request_handler.request(:get, url, { api_key: @api_key })
    end

    # Fetch detailed information about a TV season
    # @param series_id [Integer] TMDB series ID
    # @param season_num [Integer] season number
    # @return [Hash, nil] season data or nil if not found
    def fetch_season_details(series_id, season_num)
      return nil unless series_id

      url = "#{BASE_URL}/tv/#{series_id}/season/#{season_num}"
      @request_handler.request(:get, url, { api_key: @api_key })
    end

    # Fetch detailed information about a TV episode
    # @param series_id [Integer] TMDB series ID
    # @param season_num [Integer] season number
    # @param episode_num [Integer] episode number
    # @return [Hash, nil] episode data or nil if not found
    def fetch_episode_details(series_id, season_num, episode_num)
      return nil unless series_id

      url = "#{BASE_URL}/tv/#{series_id}/season/#{season_num}/episode/#{episode_num}"
      @request_handler.request(:get, url, { api_key: @api_key })
    end

    # Fetch images for a TV series
    # @param series_id [Integer] TMDB series ID
    # @return [Hash, nil] image data or nil if not found
    def fetch_series_images(series_id)
      return nil unless series_id

      url = "#{BASE_URL}/tv/#{series_id}/images"
      @request_handler.request(:get, url, { api_key: @api_key })
    end

    # Fetch images for a TV season
    # @param series_id [Integer] TMDB series ID
    # @param season_num [Integer] season number
    # @return [Hash, nil] image data or nil if not found
    def fetch_season_images(series_id, season_num)
      return nil unless series_id

      url = "#{BASE_URL}/tv/#{series_id}/season/#{season_num}/images"
      @request_handler.request(:get, url, { api_key: @api_key })
    end

    # Get the URL for an image
    # @param path [String] image path from TMDB
    # @param size [String] size of the image
    # @return [String, nil] image URL or nil if path is empty
    def image_url(path, size = 'original')
      return nil unless path && !path.empty?

      "https://image.tmdb.org/t/p/#{size}#{path}"
    end

    private

    # Perform the actual search for series
    # @param base_name [String] normalized series name
    # @return [Array, nil] search results or nil if not found
    def perform_series_search(base_name)
      url = "#{BASE_URL}/search/tv"
      params = build_search_params(base_name)

      # Get search results
      data = @request_handler.request(:get, url, params)
      return nil if data.nil? || !data['results'] || data['results'].empty?

      @logger.debug("Found #{data['results'].length} initial results")
      data['results']
    end

    # Build search parameters for TMDB
    # @param query [String] search query
    # @return [Hash] API parameters
    def build_search_params(query)
      {
        api_key: @api_key,
        query: query,
        include_adult: false
      }
    end

    # Extract the base name and year from a query string
    # @param query [String] query string
    # @return [Array] [base_name, year]
    def extract_name_and_year(query)
      year = nil
      base_name = query.dup

      # Handle parentheses format: "Show Name (2005)"
      if base_name =~ /(.+?)\s*\((\d{4})\)$/
        base_name = ::Regexp.last_match(1).strip
        year = ::Regexp.last_match(2)
      # Handle space format: "Show Name 2005"
      elsif base_name =~ /(.+?)\s+(\d{4})$/
        base_name = ::Regexp.last_match(1).strip
        year = ::Regexp.last_match(2)
      end

      # Trim and normalize
      [base_name.strip, year]
    end

    # Filter and sort search results, optionally prioritizing by year
    # @param results [Array] search results
    # @param year [String, nil] year to prioritize
    # @return [Array] filtered and sorted results
    def filter_and_sort_results(results, year)
      return sort_by_popularity(results) unless year

      # Find exact year matches
      year_matches = find_exact_year_matches(results, year)

      # If we have year matches, return those sorted by popularity
      if year_matches.any?
        @logger.debug("Found #{year_matches.length} matches with exact year #{year}")
        return sort_by_popularity(year_matches)
      end

      # Otherwise return all results sorted by popularity
      @logger.debug('No exact year matches, sorting all results by popularity')
      sort_by_popularity(results)
    end

    # Find results that match a specific year
    # @param results [Array] search results
    # @param year [String] year to match
    # @return [Array] results matching the year
    def find_exact_year_matches(results, year)
      results.select do |r|
        r['first_air_date'] && r['first_air_date'][0..3] == year
      end
    end

    # Sort results by popularity (highest first)
    # @param results [Array] results to sort
    # @return [Array] sorted results
    def sort_by_popularity(results)
      results.sort_by { |r| -(r['popularity'] || 0) }
    end
  end
end
