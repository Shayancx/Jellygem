# frozen_string_literal: true

module Jellygem
  module Utils
    # Core file operations - moved to a separate module to reduce the size of FileHelper
    module FileOperations
      # Safely rename a folder with error handling
      # @param original_path [String] original folder path
      # @param new_path [String] new folder path
      # @return [String] resulting folder path
      def safely_rename_folder(original_path, new_path)
        Jellygem.logger.info("Renaming folder: #{File.basename(original_path)} -> #{File.basename(new_path)}")

        # Validate source directory
        return original_path unless valid_source_directory?(original_path)

        # Handle destination exists case
        return handle_existing_destination(original_path, new_path) if File.exist?(new_path)

        # Create parent directory if needed
        ensure_directory_exists(File.dirname(new_path))

        # Perform the rename
        perform_folder_rename(original_path, new_path)
      rescue StandardError => e
        handle_folder_rename_error(original_path, e)
      end

      # Validate source directory
      # @param path [String] directory path to check
      # @return [Boolean] true if valid
      def valid_source_directory?(path)
        unless File.directory?(path)
          Jellygem.logger.error("Cannot rename folder: source is not a directory: #{path}")
          return false
        end
        true
      end

      # Perform the actual folder rename operation
      # @param original_path [String] original folder path
      # @param new_path [String] new folder path
      # @return [String] new path
      def perform_folder_rename(original_path, new_path)
        FileUtils.mv(original_path, new_path)
        Jellygem.logger.info("Successfully renamed folder to: #{new_path}")
        new_path
      end

      # Handle errors during folder rename
      # @param original_path [String] original folder path
      # @param error [StandardError] error that occurred
      # @return [String] original path
      def handle_folder_rename_error(original_path, error)
        Jellygem.logger.error("Failed to rename #{original_path}: #{error.message}")
        original_path
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

        rename_preparation(original_path, new_path)
        perform_rename_operation(original_path, new_path)
      rescue StandardError => e
        log_rename_error(original_path, e)
        false
      end

      # Prepare for file rename
      # @param original_path [String] original file path
      # @param new_path [String] new file path
      # @return [Boolean] true if preparation successful
      def rename_preparation(original_path, new_path)
        # Validate source file
        return false unless validate_source_file(original_path)

        # Handle existing target
        handle_existing_target(new_path) if File.exist?(new_path)

        # Create target directory
        ensure_directory_exists(File.dirname(new_path))

        true
      end

      # Validate source file
      # @param path [String] path to file
      # @return [Boolean] true if file exists
      def validate_source_file(path)
        unless File.file?(path)
          Jellygem.logger.error("Cannot rename file: source is not a file: #{path}")
          return false
        end
        true
      end

      # Handle existing target file
      # @param path [String] path to file
      # @return [void]
      def handle_existing_target(path)
        if Jellygem.config.force
          Jellygem.logger.warn("Overwriting existing file: #{path}")
          FileUtils.rm_f(path)
        else
          Jellygem.logger.warn("Target file already exists: #{path}")
        end
      end

      # Perform rename operation
      # @param original_path [String] original file path
      # @param new_path [String] new file path
      # @return [Boolean] true if successful
      def perform_rename_operation(original_path, new_path)
        FileUtils.mv(original_path, new_path)
        Jellygem.logger.info("Successfully renamed file to: #{new_path}")
        true
      end

      # Log file rename error
      # @param original_path [String] original file path
      # @param error [StandardError] error that occurred
      # @return [void]
      def log_rename_error(original_path, error)
        Jellygem.logger.error("Failed to rename #{original_path}: #{error.message}")
      end

      # Ensure a directory exists, creating it if needed
      # @param directory [String] directory path
      # @return [void]
      def ensure_directory_exists(directory)
        FileUtils.mkdir_p(directory) unless File.exist?(directory)
      end
    end
  end
end
