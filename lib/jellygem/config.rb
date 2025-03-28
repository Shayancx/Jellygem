# frozen_string_literal: true

module Jellygem
  # Configuration class for Jellygem
  # Handles loading configuration from default config, user config, and environment variables
  class Config
    DEFAULT_CONFIG_FILE = File.expand_path('../../config/defaults.yml', __dir__)
    USER_CONFIG_FILE = File.expand_path('~/.jellygem.yml')

    attr_accessor :tmdb_api_key, :dry_run, :verbose, :skip_images,
                  :max_api_retries, :force, :no_prompt

    def initialize
      set_defaults
      load_user_config if File.exist?(USER_CONFIG_FILE)
      load_environment_variables
    end

    # Updates configuration with provided options
    # @param options [Hash] options to update
    def update(options = {})
      options.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    private

    # Sets default configuration values
    def set_defaults
      # Set basic defaults before trying to load from file
      set_basic_defaults

      # Load from config file if it exists
      load_defaults_from_file if File.exist?(DEFAULT_CONFIG_FILE)
    end

    # Set basic default values
    def set_basic_defaults
      @tmdb_api_key = 'eb0e30eac4bf856683dbde0853e35bbb' # Default API key for TMDB
      @dry_run = false
      @verbose = false
      @skip_images = false
      @max_api_retries = 3
      @force = false
      @no_prompt = false
    end

    # Load default values from config file
    def load_defaults_from_file
      content = File.read(DEFAULT_CONFIG_FILE)
      config = YAML.safe_load(content)
      return unless config.is_a?(Hash)

      config.each do |key, value|
        instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
      end
    end

    # Loads configuration from user config file
    def load_user_config
      content = File.read(USER_CONFIG_FILE)
      config = YAML.safe_load(content)
      if config.is_a?(Hash)
        config.each do |key, value|
          instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
        end
      end
    rescue StandardError => e
      puts "Warning: Could not load user config file: #{e.message}"
    end

    # Loads configuration from environment variables
    def load_environment_variables
      # Load API key if set
      load_api_key_from_env

      # Load boolean options from environment variables
      load_boolean_options_from_env
    end

    # Load API key from environment
    def load_api_key_from_env
      @tmdb_api_key = ENV['TMDB_API_KEY'] if ENV['TMDB_API_KEY']
    end

    # Load boolean options from environment variables
    def load_boolean_options_from_env
      boolean_options = {
        'JELLYGEM_DRY_RUN' => :dry_run,
        'JELLYGEM_VERBOSE' => :verbose,
        'JELLYGEM_SKIP_IMAGES' => :skip_images,
        'JELLYGEM_FORCE' => :force,
        'JELLYGEM_NO_PROMPT' => :no_prompt
      }

      boolean_options.each do |env_var, option|
        instance_variable_set("@#{option}", string_to_bool(ENV[env_var])) if ENV[env_var]
      end
    end

    # Converts various string representations to boolean
    # @param str [String] string to convert
    # @return [Boolean] boolean representation
    def string_to_bool(str)
      %w[true yes 1 on].include?(str.to_s.downcase)
    end
  end
end
