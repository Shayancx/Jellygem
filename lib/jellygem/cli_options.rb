# frozen_string_literal: true

module Jellygem
  # Handles options parsing and help display for the CLI
  class CLIOptions
    include Utils::UIHelper

    def initialize(logger)
      @logger = logger
    end

    # Display help information
    # @return [void]
    def show_help
      help_sections.each { |section| puts section }
    end

    # Generate help sections for better organization
    # @return [Array<String>] sections of help text
    def help_sections
      [
        help_header_section,
        help_usage_section,
        help_options_section,
        help_examples_section
      ]
    end

    # Generate header section for help
    # @return [String] header section
    def help_header_section
      "Jellygem #{VERSION}\n\nA tool to organize TV series folders with metadata for media centers.\n"
    end

    # Generate usage section for help
    # @return [String] usage section
    def help_usage_section
      "Usage: jellygem [options] [path/to/series]\n"
    end

    # Generate options section for help
    # @return [String] options section
    def help_options_section
      <<~OPTIONS
        Options:
          -h, --help           Show this help message
          -v, --version        Show version information
          --dry-run            Simulate operations without making changes
          --verbose            Show detailed output
          --skip-images        Skip downloading images
          --force              Override existing files
          --no-prompt          Use defaults without prompting
      OPTIONS
    end

    # Generate examples section for help
    # @return [String] examples section
    def help_examples_section
      <<~EXAMPLES
        Examples:
          jellygem ~/TV/Supernatural
          jellygem --dry-run "Breaking Bad S01-S05 1080p"
          jellygem --skip-images --no-prompt /media/shows/GameOfThrones
      EXAMPLES
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
      log_applied_options(options)
    end

    # Log which options were applied
    # @param options [Hash] applied options
    # @return [void]
    def log_applied_options(options)
      enabled_options = options.select { |_, v| v }.keys
      @logger.info("Options: #{enabled_options.join(', ')}")
    end

    # Extract path from command line arguments
    # @param args [Array<String>] command line arguments
    # @return [String] expanded path
    def extract_path(args)
      # Find the first argument that isn't an option
      path = args.find { |arg| !arg.start_with?('-') } || Dir.pwd
      File.expand_path(path)
    end
  end
end
