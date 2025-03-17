# frozen_string_literal: true

require 'net/http'

module Jellygem
  module Utils
    # Helper class for downloading files
    # Extracted to reduce complexity in the FileHelper module
    class FileDownloader
      def initialize(logger = nil)
        @logger = logger || Jellygem.logger
      end

      # Download a file from URL to save path
      # @param url [String] URL to download from
      # @param save_path [String] path to save to
      # @return [Boolean] true if successful
      def download(url, save_path)
        uri = URI.parse(url)
        response = perform_http_request(uri)
        process_response(response, save_path)
      end

      private

      # Perform HTTP request
      # @param uri [URI] URI to request
      # @return [Net::HTTPResponse] HTTP response
      def perform_http_request(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')

        request = Net::HTTP::Get.new(uri.request_uri)
        http.request(request)
      end

      # Process HTTP response
      # @param response [Net::HTTPResponse] HTTP response
      # @param save_path [String] path to save to
      # @return [Boolean] true if successful
      def process_response(response, save_path)
        if response.is_a?(Net::HTTPSuccess)
          save_file_from_response(response, save_path)
          true
        else
          log_download_error(response)
          false
        end
      end

      # Save file from HTTP response
      # @param response [Net::HTTPResponse] HTTP response
      # @param save_path [String] path to save to
      # @return [void]
      def save_file_from_response(response, save_path)
        File.open(save_path, 'wb') do |file|
          file.write(response.body)
        end
        @logger.info("Successfully downloaded to: #{save_path}")
      end

      # Log download error
      # @param response [Net::HTTPResponse] HTTP response
      # @return [void]
      def log_download_error(response)
        @logger.error("Failed to download: HTTP error #{response.code}")
      end
    end
  end
end
