# frozen_string_literal: true
# frozen_string_literal: true

module Jellygem
  # Command Line Interface for Jellygem
  # Handles parsing command line arguments and initializing processing
  class CLI
    include Utils::UIHelper

    def initialize
      @logger = Jellygem.logger
      @processor = Processors::SeriesProcessor.new
    end

    # Main entry point for the command line interface
    # @param args [Array<String>] command line arguments
    # @return [void]
    def run(args)
      # Handle special commands first
      return show_help if help_requested?(args)
      return show_version if version_requested?(args)

      # Process options and get path
      options = parse_options(args)
      apply_options(options)
      series_path = extract_path(args)

      # Validate path
      exit_with_error("'#{series_path}' is not a valid directory.") unless valid_directory?(series_path)

      # Start processing
      process_series(series_path)
    rescue Interrupt
      handle_interrupt
    rescue StandardError => e
      handle_error(e)
    end

    private

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
      puts <<~HELP
        Jellygem #{VERSION}

        A tool to organize TV series folders with metadata for media centers.

        Usage: jellygem [options] [path/to/series]

        Options:
          -h, --help           Show this help message
          -v, --version        Show version information
          --dry-run            Simulate operations without making changes
          --verbose            Show detailed output
          --skip-images        Skip downloading images
          --force              Override existing files
          --no-prompt          Use defaults without prompting

        Examples:
          jellygem ~/TV/Supernatural
          jellygem --dry-run "Breaking Bad S01-S05 1080p"
          jellygem --skip-images --no-prompt /media/shows/GameOfThrones
      HELP
    end

    # Display version information
    # @return [void]
    def show_version
      puts "Jellygem version #{VERSION}"
    end

    # Parse command line options
    # @param args [Array<String>] command line arguments
    # @return [Hash] parsed options
    def parse_options(args)
      {
        dry_run: args.include?('--dry-run'),
        verbose: args.include?('--verbose'),
        skip_images: args.include?('--skip-images'),
        force: args.include?('--force'),
        no_prompt: args.include?('--no-prompt')
      }
    end

    # Apply parsed options to global configuration
    # @param options [Hash] parsed options
    # @return [void]
    def apply_options(options)
      Jellygem.config.update(options)

      # Configure logger verbosity
      Jellygem.logger.level = Logger::DEBUG if options[:verbose]

      # Log applied options
      @logger.info("Options: #{options.select { |_, v| v }.keys.join(', ')}")
    end

    # Extract path from command line arguments
    # @param args [Array<String>] command line arguments
    # @return [String] expanded path
    def extract_path(args)
      # Find the first argument that isn't an option
      path = args.find { |arg| !arg.start_with?('-') } || Dir.pwd
      File.expand_path(path)
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

      return unless Jellygem.config.dry_run

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
      puts error("\nError: #{error.message}")
      puts 'Check the log file for details.'
      @logger.error("CLI Error: #{error.message}")
      @logger.error(error.backtrace.join("\n"))

      # Print backtrace in debug mode
      if ENV['JELLYGEM_DEBUG']
        puts "\nBacktrace:"
        puts error.backtrace
      end

      exit 1
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
