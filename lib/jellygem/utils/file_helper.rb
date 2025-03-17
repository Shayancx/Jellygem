# frozen_string_literal: true

require 'open-uri'
require 'net/http'

module Jellygem
  module Utils
    # File Helper module provides utilities for file operations
    # Including file/folder renaming and image downloading
    module FileHelper
      # Safely rename a folder
      # @param original_path [String] original folder path
      # @param new_name [String] new folder name
      # @return [String] resulting folder path
      def rename_folder(original_path, new_name)
        parent_dir = File.dirname(original_path)
        new_path = File.join(parent_dir, new_name)

        # Skip if it's already correctly named
        return original_path if original_path == new_path

        # Skip if in dry run mode
        if Jellygem.config.dry_run
          log_dry_run_rename_folder(original_path, new_name)
          return original_path
        end

        # Perform the rename
        safely_rename_folder(original_path, new_path)
      end

      # Safely rename a file
      # @param original_path [String] original file path
      # @param new_path [String] new file path
      # @return [Boolean] true if successful
      def rename_file(original_path, new_path)
        # Skip if it's already correctly named
        return true if original_path == new_path

        # Skip if in dry run mode
        if Jellygem.config.dry_run
          log_dry_run_rename_file(original_path, new_path)
          return true
        end

        # Perform the rename
        safely_rename_file(original_path, new_path)
      end

      # Download an image file
      # @param url [String] image URL
      # @param save_path [String] path to save the image
      # @return [Boolean] true if successful
      def download_image(url, save_path)
        return true if Jellygem.config.dry_run

        # Skip if the file already exists and force isn't enabled
        if File.exist?(save_path) && !Jellygem.config.force
          Jellygem.logger.debug("Image already exists and force not enabled: #{save_path}")
          return true
        end

        # Validate URL
        unless valid_url?(url)
          Jellygem.logger.error("Invalid download URL: #{url.inspect}")
          return false
        end

        # Download the image
        safely_download_image(url, save_path)
      end

      # Sanitize a filename for filesystem compatibility
      # @param name [String] filename to sanitize
      # @return [String, nil] sanitized filename or nil if input was nil
      def sanitize_filename(name)
        return nil unless name

        # Replace characters that are problematic in filenames
        sanitized = name.gsub(%r{[/\\:*?"<>|]}, '_')

        # Replace multiple spaces/underscores with single underscore
        sanitized = sanitized.gsub(/\s+/, '_').gsub(/_+/, '_')

        # Trim leading/trailing underscores
        sanitized.gsub(/^_+|_+$/, '')
      end

      private

      # Check if URL is valid
      # @param url [String] URL to validate
      # @return [Boolean] true if valid
      def valid_url?(url)
        !url.nil? && !url.empty? && url.start_with?('http')
      end

      # Log a dry run folder rename operation
      # @param original_path [String] original folder path
      # @param new_name [String] new folder name
      # @return [void]
      def log_dry_run_rename_folder(original_path, new_name)
        Jellygem.logger.info(
          "[DRY RUN] Would rename folder: #{File.basename(original_path)} -> #{new_name}"
        )
      end

      # Log a dry run file rename operation
      # @param original_path [String] original file path
      # @param new_path [String] new file path
      # @return [void]
      def log_dry_run_rename_file(original_path, new_path)
        original_name = File.basename(original_path)
        new_name = File.basename(new_path)
        Jellygem.logger.info("[DRY RUN] Would rename file: #{original_name} -> #{new_name}")
      end

      # Safely rename a folder with error handling
      # @param original_path [String] original folder path
      # @param new_path [String] new folder path
      # @return [String] resulting folder path
      def safely_rename_folder(original_path, new_path)
        Jellygem.logger.info("Renaming folder: #{File.basename(original_path)} -> #{File.basename(new_path)}")

        begin
          # Check if source exists and is a directory
          unless File.directory?(original_path)
            Jellygem.logger.error("Cannot rename folder: source is not a directory: #{original_path}")
            return original_path
          end

          # Handle destination exists case
          return handle_existing_destination(original_path, new_path) if File.exist?(new_path)

          # Create parent directory if needed
          FileUtils.mkdir_p(File.dirname(new_path)) unless File.exist?(File.dirname(new_path))

          # Perform the rename
          FileUtils.mv(original_path, new_path)
          Jellygem.logger.info("Successfully renamed folder to: #{new_path}")
          new_path
        rescue StandardError => e
          Jellygem.logger.error("Failed to rename #{original_path}: #{e.message}")
          original_path
        end
      end

      # Handle case where destination already exists
      # @param original_path [String] original folder path
      # @param new_path [String] new folder path
      # @return [String] resulting folder path
      def handle_existing_destination(original_path, new_path)
        Jellygem.logger.warn("Destination already exists: #{new_path}")
        # If it's a directory, use it instead of trying to rename
        if File.directory?(new_path)
          Jellygem.logger.info("Using existing directory: #{new_path}")
          new_path
        else
          Jellygem.logger.error('Destination exists but is not a directory')
          original_path
        end
      end

      # Safely rename a file with error handling
      # @param original_path [String] original file path
      # @param new_path [String] new file path
      # @return [Boolean] true if successful
      def safely_rename_file(original_path, new_path)
        Jellygem.logger.info(
          "Renaming file: #{File.basename(original_path)} -> #{File.basename(new_path)}"
        )

        begin
          # Check if source exists and is a file
          unless File.file?(original_path)
            Jellygem.logger.error("Cannot rename file: source is not a file: #{original_path}")
            return false
          end

          # Handle case where target exists
          return handle_existing_file(new_path) if File.exist?(new_path)

          # Create target directory if needed
          ensure_directory_exists(File.dirname(new_path))

          # Perform the rename
          FileUtils.mv(original_path, new_path)
          Jellygem.logger.info("Successfully renamed file to: #{new_path}")
          true
        rescue StandardError => e
          Jellygem.logger.error("Failed to rename #{original_path}: #{e.message}")
          false
        end
      end

      # Handle case where target file already exists
      # @param file_path [String] path to existing file
      # @return [Boolean] true if handled successfully
      def handle_existing_file(file_path)
        if Jellygem.config.force
          Jellygem.logger.warn("Overwriting existing file: #{file_path}")
          FileUtils.rm_f(file_path)
        else
          Jellygem.logger.warn("Target file already exists: #{file_path}")
        end
        true
      end

      # Ensure a directory exists, creating it if needed
      # @param directory [String] directory path
      # @return [void]
      def ensure_directory_exists(directory)
        FileUtils.mkdir_p(directory) unless File.exist?(directory)
      end

      # Safely download an image with error handling
      # @param url [String] image URL
      # @param save_path [String] path to save the image
      # @return [Boolean] true if successful
      def safely_download_image(url, save_path)
        Jellygem.logger.debug("Downloading image from #{url} => #{save_path}")

        begin
          # Create directory
          ensure_directory_exists(File.dirname(save_path))

          # Download using Net::HTTP
          download_with_http(url, save_path)
        rescue StandardError => e
          Jellygem.logger.error("Failed to download image from #{url}: #{e.message}")
          false
        end
      end

      # Download image using Net::HTTP
      # @param url [String] image URL
      # @param save_path [String] path to save the image
      # @return [Boolean] true if successful
      def download_with_http(url, save_path)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')

        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          File.open(save_path, 'wb') do |file|
            file.write(response.body)
          end
          Jellygem.logger.info("Successfully downloaded image to: #{save_path}")
          true
        else
          Jellygem.logger.error("Failed to download: HTTP error #{response.code}")
          false
        end
      end
    end
  end
end
