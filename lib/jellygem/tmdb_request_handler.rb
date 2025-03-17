# frozen_string_literal: true

module Jellygem
  # Handles HTTP requests to TMDB API
  # Separated to reduce complexity of TMDBClient
  class TMDBRequestHandler
    def initialize(logger, max_retries, retry_delay, cache)
      @logger = logger
      @max_retries = max_retries
      @retry_delay = retry_delay
      @cache = cache
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

    private

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
        response = perform_http_request(method, url, params)

        # Handle response
        handle_response(response, url, method, retries, cache_key)
      rescue StandardError => e
        handle_request_error(e, url, retries)
      end
    end

    # Perform the actual HTTP request
    # @param method [Symbol] HTTP method
    # @param url [String] URL to request
    # @param params [Hash] query parameters or post body
    # @return [HTTParty::Response] HTTP response
    def perform_http_request(method, url, params)
      case method
      when :get
        HTTParty.get(url, query: params)
      when :post
        HTTParty.post(url, body: params)
      else
        raise "Unsupported HTTP method: #{method}"
      end
    end

    # Handle HTTP request errors
    # @param error [StandardError] the error
    # @param url [String] the URL that failed
    # @param retries [Integer] current retry count
    # @return [nil] if max retries reached
    def handle_request_error(error, url, retries)
      @logger.error("Error fetching #{url}: #{error.message}")
      if retries < @max_retries
        @logger.warn("Retrying... (#{retries}/#{@max_retries})")
        sleep(@retry_delay)
        retry # This will retry the begin block
      else
        @logger.error("Max retries reached for #{url}")
        nil
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
      handle_rate_limiting(retries) if response.code == 429

      # Handle other errors
      return handle_error_response(response, url, method) unless response.success?

      # Parse and cache successful response
      cache_successful_response(response, cache_key)
    end

    # Handle rate limiting (429) response
    # @param retries [Integer] current retry count
    # @return [void]
    def handle_rate_limiting(retries)
      @logger.warn("HTTP 429: Too Many Requests. Attempt #{retries}")
      sleep(@retry_delay)
      raise 'Rate limited, retrying'
    end

    # Handle error response
    # @param response [HTTParty::Response] HTTP response
    # @param url [String] requested URL
    # @param method [Symbol] HTTP method
    # @return [nil] for error response
    def handle_error_response(response, url, method)
      @logger.error("Failed #{method.upcase} #{url}, code=#{response.code}")
      nil
    end

    # Parse and cache a successful response
    # @param response [HTTParty::Response] HTTP response
    # @param cache_key [String] cache key
    # @return [Hash] parsed response
    def cache_successful_response(response, cache_key)
      result = JSON.parse(response.body)
      @cache[cache_key] = result
      result
    end
  end
end
