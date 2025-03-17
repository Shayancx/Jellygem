# frozen_string_literal: true

module Jellygem
  # Command Line Interface for Jellygem
  # Handles parsing command line arguments and initializing processing
  class CLI
    include Utils::UIHelper

    def initialize
      @logger = Jellygem.logger
      @processor = Processors::SeriesProcessor.new
      @options_handler = CLIOptions.new(@logger)
    end

    # Main entry point for the command line interface
    # @param args [Array<String>] command line arguments
    # @return [void]
    def run(args)
      # Handle special commands first
      return show_help if help_requested?(args)
      return show_version if version_requested?(args)

      # Process normal command flow
      process_normal_command(args)
    rescue Interrupt
      handle_interrupt
    rescue StandardError => e
      handle_error(e)
    end

    private

    # Process a standard (non-help, non-version) command
    # @param args [Array<String>] command line arguments
    # @return [void]
    def process_normal_command(args)
      # Process options and get path
      options = @options_handler.parse_options(args)
      @options_handler.apply_options(options)
      series_path = @options_handler.extract_path(args)

      # Validate path and start processing
      validate_and_process_path(series_path)
    end

    # Validate path and process series if valid
    # @param series_path [String] path to process
    # @return [void]
    def validate_and_process_path(series_path)
      if valid_directory?(series_path)
        process_series(series_path)
      else
        exit_with_error("'#{series_path}' is not a valid directory.")
      end
    end

    # Check if help was requested
    # @param args [Array<String>] command line arguments
    # @return [Boolean] true if help was requested
    def help_requested?(args)
      args.empty? || args.include?('-h') || args.include?('--help')
    end

    # Check if version info was requested
    # @param args [Array<String>] command line arguments
    # @return [Boolean] true if version was requested
    def version_requested?(args)
      args.include?('-v') || args.include?('--version')
    end

    # Display help information
    # @return [void]
    def show_help
      @options_handler.show_help
    end

    # Display version information
    # @return [void]
    def show_version
      puts "Jellygem version #{VERSION}"
    end

    # Check if path is a valid directory
    # @param path [String] path to check
    # @return [Boolean] true if path is a valid directory
    def valid_directory?(path)
      File.directory?(path)
    end

    # Process a series directory
    # @param path [String] path to series directory
    # @return [void]
    def process_series(path)
      display_welcome_banner

      if @processor.process(path)
        display_success_message
      else
        puts warning("\nSeries processing was not completed.")
      end
    end

    # Display welcome banner
    # @return [void]
    def display_welcome_banner
      puts '=' * 80
      puts "Jellygem v#{VERSION} - TV Series Organizer".center(80)
      puts '=' * 80
      puts
    end

    # Display success message
    # @return [void]
    def display_success_message
      puts success("\nProcessing complete! Your media is now organized for Jellyfin/Kodi/Plex.")
      display_dry_run_message if Jellygem.config.dry_run
    end

    # Display message specific to dry-run mode
    # @return [void]
    def display_dry_run_message
      puts info('This was a dry run. No actual changes were made.')
      puts info('Run again without --dry-run to apply the changes.')
    end

    # Handle program interruption (Ctrl+C)
    # @return [void]
    def handle_interrupt
      puts "\nProcess interrupted. Exiting gracefully."
      exit 1
    end

    # Handle errors during processing
    # @param error [StandardError] error that occurred
    # @return [void]
    def handle_error(error)
      log_error(error)
      print_error_message(error)
      exit 1
    end

    # Log error details
    # @param error [StandardError] error that occurred
    # @return [void]
    def log_error(error)
      @logger.error("CLI Error: #{error.message}")
      @logger.error(error.backtrace.join("\n"))
    end

    # Print error message to user
    # @param error [StandardError] error that occurred
    # @return [void]
    def print_error_message(error)
      puts error("\nError: #{error.message}")
      puts 'Check the log file for details.'

      # Print backtrace in debug mode
      return unless ENV['JELLYGEM_DEBUG']

      puts "\nBacktrace:"
      puts error.backtrace
    end

    # Exit with error message
    # @param message [String] error message
    # @return [void]
    def exit_with_error(message)
      puts error("Error: #{message}")
      exit 1
    end
  end
end
