# frozen_string_literal: true

module Jellygem
  module Utils
    # UI Helper module provides utilities for terminal output and user interaction
    # Includes colorized output, progress bars, and prompts
    module UIHelper
      # Print colored text
      # @param text [String] text to colorize
      # @param color_code [Integer] ANSI color code
      # @return [String] colorized text
      def colorize(text, color_code)
        "\e[#{color_code}m#{text}\e[0m"
      end

      # Format text as success (green)
      # @param text [String] text to format
      # @return [String] formatted text
      def success(text)
        colorize(text, 32) # green
      end

      # Format text as info (cyan)
      # @param text [String] text to format
      # @return [String] formatted text
      def info(text)
        colorize(text, 36) # cyan
      end

      # Format text as warning (yellow)
      # @param text [String] text to format
      # @return [String] formatted text
      def warning(text)
        colorize(text, 33) # yellow
      end

      # Format text as error (red)
      # @param text [String] text to format
      # @return [String] formatted text
      def error(text)
        colorize(text, 31) # red
      end

      # Print a progress bar to the terminal
      # @param current [Integer] current progress
      # @param total [Integer] total items
      # @param bar_width [Integer] width of the progress bar
      # @return [void]
      def print_progress_bar(current, total, bar_width = 40)
        percent = (current.to_f / total * 100).to_i
        complete_width = (current.to_f / total * bar_width).to_i
        print "\r[#{('█' * complete_width).ljust(bar_width, '░')}] #{current}/#{total} (#{percent}%)"
        $stdout.flush
      end

      # Prompt the user for input
      # @param message [String] prompt message
      # @param default [String, nil] default value
      # @return [String] user input or default
      def prompt(message, default = nil)
        # Skip prompts in no-prompt mode
        if Jellygem.config.no_prompt
          Jellygem.logger.info("[NO PROMPT] Using default value: #{default}")
          return default
        end

        default_display = default ? " [#{default}]" : ''
        print "#{message}#{default_display}: "
        response = $stdin.gets.chomp.strip
        response.empty? ? default : response
      end

      # Prompt the user for a yes/no response
      # @param message [String] prompt message
      # @param default [Boolean] default value
      # @return [Boolean] true for yes, false for no
      def prompt_yes_no(message, default: true)
        # Skip prompts in no-prompt mode
        if Jellygem.config.no_prompt
          Jellygem.logger.info("[NO PROMPT] Using default value for yes/no: #{default}")
          return default
        end

        default_str = default ? 'Y/n' : 'y/N'
        print "#{message} [#{default_str}]: "
        response = $stdin.gets.chomp.strip.downcase
        return default if response.empty?

        response.start_with?('y')
      end

      # Display a header with borders
      # @param text [String] header text
      # @return [void]
      def show_header(text)
        puts '=' * 80
        puts text.center(80)
        puts '=' * 80
        puts
      end
    end
  end
end
