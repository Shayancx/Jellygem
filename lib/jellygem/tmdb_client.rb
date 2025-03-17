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
    end

    # Search for TV series by name
    # @param query [String] search query
    # @return [Array, nil] search results or nil if not found
    def search_tv_series(query)
      # Normalize the query to handle different input formats
      @logger.debug("Original search query: #{query}")
      base_name, year = extract_name_and_year(query)
      @logger.debug("Normalized search query - Name: '#{base_name}', Year: #{year || 'none'}")

      # Perform the search with just the name
      url = "#{BASE_URL}/search/tv"
      params = {
        api_key: @api_key,
        query: base_name,
        include_adult: false
      }

      # Get search results
      data = request(:get, url, params)
      return nil if data.nil? || !data['results'] || data['results'].empty?

      results = data['results']
      @logger.debug("Found #{results.length} initial results")

      # Filter and sort results
      filter_and_sort_results(results, year)
    end

    # Fetch detailed information about a TV series
    # @param series_id [Integer] TMDB series ID
    # @return [Hash, nil] series data or nil if not found
    def fetch_series_details(series_id)
      return nil unless series_id

      url = "#{BASE_URL}/tv/#{series_id}"
      request(:get, url, { api_key: @api_key })
    end

    # Fetch detailed information about a TV season
    # @param series_id [Integer] TMDB series ID
    # @param season_num [Integer] season number
    # @return [Hash, nil] season data or nil if not found
    def fetch_season_details(series_id, season_num)
      return nil unless series_id

      url = "#{BASE_URL}/tv/#{series_id}/season/#{season_num}"
      request(:get, url, { api_key: @api_key })
    end

    # Fetch detailed information about a TV episode
    # @param series_id [Integer] TMDB series ID
    # @param season_num [Integer] season number
    # @param episode_num [Integer] episode number
    # @return [Hash, nil] episode data or nil if not found
    def fetch_episode_details(series_id, season_num, episode_num)
      return nil unless series_id

      url = "#{BASE_URL}/tv/#{series_id}/season/#{season_num}/episode/#{episode_num}"
      request(:get, url, { api_key: @api_key })
    end

    # Fetch images for a TV series
    # @param series_id [Integer] TMDB series ID
    # @return [Hash, nil] image data or nil if not found
    def fetch_series_images(series_id)
      return nil unless series_id

      url = "#{BASE_URL}/tv/#{series_id}/images"
      request(:get, url, { api_key: @api_key })
    end

    # Fetch images for a TV season
    # @param series_id [Integer] TMDB series ID
    # @param season_num [Integer] season number
    # @return [Hash, nil] image data or nil if not found
    def fetch_season_images(series_id, season_num)
      return nil unless series_id

      url = "#{BASE_URL}/tv/#{series_id}/season/#{season_num}/images"
      request(:get, url, { api_key: @api_key })
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
      # If year was provided, boost matches with the correct year
      if year
        # First, try exact year matches
        year_matches = results.select do |r|
          r['first_air_date'] && r['first_air_date'][0..3] == year
        end

        # If we found exact year matches, prioritize those
        if year_matches.any?
          @logger.debug("Found #{year_matches.length} matches with exact year #{year}")
          return year_matches.sort_by { |r| -(r['popularity'] || 0) }
        end

        @logger.debug('No exact year matches, sorting all results by popularity')
      end

      # Return all results sorted by popularity
      results.sort_by { |r| -(r['popularity'] || 0) }
    end

    # Make an HTTP request to the TMDB API
    # @param method [Symbol] HTTP method (:get or :post)
    # @param url [String] URL to request
    # @param params [Hash] query parameters or post body
    # @return [Hash, nil] parsed response or nil if request failed
    def request(method, url, params)
      # Generate cache key
      cache_key = "#{method}:#{url}:#{params.sort}"

      # Check cache first
      return @cache[cache_key] if @cache.key?(cache_key)

      # Validate URL
      if url.nil? || url.empty? || !url.start_with?('http')
        @logger.error("Invalid URL: #{url.inspect}")
        return nil
      end

      make_request_with_retries(method, url, params, cache_key)
    end

    # Make HTTP request with retry logic
    # @param method [Symbol] HTTP method
    # @param url [String] URL to request
    # @param params [Hash] query parameters or post body
    # @param cache_key [String] cache key for storing response
    # @return [Hash, nil] parsed response or nil if request failed
    def make_request_with_retries(method, url, params, cache_key)
      retries = 0
      begin
        retries += 1
        @logger.debug("HTTP #{method.upcase} => #{url} (attempt #{retries})")

        # Make the request
        response = case method
                   when :get
                     HTTParty.get(url, query: params)
                   when :post
                     HTTParty.post(url, body: params)
                   else
                     raise "Unsupported HTTP method: #{method}"
                   end

        # Handle response
        handle_response(response, url, method, retries, cache_key)
      rescue StandardError => e
        @logger.error("Error fetching #{url}: #{e.message}")
        if retries < @max_retries
          @logger.warn("Retrying... (#{retries}/#{@max_retries})")
          sleep(@retry_delay)
          retry # This is within a rescue block now
        else
          @logger.error("Max retries reached for #{url}")
          nil
        end
      end
    end

    # Handle HTTP response
    # @param response [HTTParty::Response] HTTP response
    # @param url [String] requested URL
    # @param method [Symbol] HTTP method
    # @param retries [Integer] current retry count
    # @param cache_key [String] cache key for storing response
    # @return [Hash, nil] parsed response or nil if request failed
    def handle_response(response, url, method, retries, cache_key)
      # Handle rate limiting
      if response.code == 429
        @logger.warn("HTTP 429: Too Many Requests. Attempt #{retries}")
        sleep(@retry_delay)
        raise 'Rate limited, retrying'
      end

      # Handle other errors
      unless response.success?
        @logger.error("Failed #{method.upcase} #{url}, code=#{response.code}")
        return nil
      end

      # Parse and cache successful response
      result = JSON.parse(response.body)
      @cache[cache_key] = result
      result
    end
  end
end
