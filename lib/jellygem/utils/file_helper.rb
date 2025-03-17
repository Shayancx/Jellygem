# frozen_string_literal: true

require 'open-uri'
require 'net/http'

module Jellygem
  module Utils
    # File Helper module provides utilities for file operations
    # Including file/folder renaming and image downloading
    module FileHelper
      include FileOperations

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

      # Safely download an image with error handling
      # @param url [String] image URL
      # @param save_path [String] path to save the image
      # @return [Boolean] true if successful
      def safely_download_image(url, save_path)
        Jellygem.logger.debug("Downloading image from #{url} => #{save_path}")

        # Create directory and download file
        ensure_directory_exists(File.dirname(save_path))

        # Use file downloader utility to handle complexity
        FileDownloader.new.download(url, save_path)
      rescue StandardError => e
        Jellygem.logger.error("Failed to download image from #{url}: #{e.message}")
        false
      end
    end
  end
end
