# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'yaml'
require 'logger'
require 'httparty'
require 'cgi'

# Utils
require 'jellygem/utils/file_operations'
require 'jellygem/utils/file_downloader'
require 'jellygem/utils/file_helper'
require 'jellygem/utils/ui_helper'

# Core components
require 'jellygem/config'
require 'jellygem/tmdb_request_handler'
require 'jellygem/tmdb_client'
require 'jellygem/cli_options'

# Formatters
require 'jellygem/formatters/base_formatter'
require 'jellygem/formatters/series_formatter'
require 'jellygem/formatters/season_formatter'
require 'jellygem/formatters/episode_formatter'

# Models
require 'jellygem/models/series'
require 'jellygem/models/season'
require 'jellygem/models/episode'

# Processors
require 'jellygem/processors/base_processor'
require 'jellygem/processors/metadata_processor'
require 'jellygem/processors/episode_processor_helper'
require 'jellygem/processors/episode_processor'
require 'jellygem/processors/season_processor'
require 'jellygem/processors/series_info_formatter'
require 'jellygem/processors/series_artwork_handler'
require 'jellygem/processors/series_search_handler'
require 'jellygem/processors/series_processor'

# CLI interface
require 'jellygem/cli'

# Version
VERSION_FILE = File.expand_path('../VERSION', __dir__)
VERSION = File.exist?(VERSION_FILE) ? File.read(VERSION_FILE).strip : '1.0.0'

# Jellygem is a TV series organization tool that helps rename and organize
# your TV show files according to proper naming conventions for media servers.
# It uses The Movie Database (TMDB) API to gather metadata about TV shows
# and creates proper folder structure and metadata files.
module Jellygem
  class << self
    attr_accessor :logger, :config

    # Sets up initial configuration and logger for Jellygem
    def setup
      # Create new instances
      @config = Config.new
      @logger = setup_logger

      # Set debug mode if environment variable is set
      @logger.level = Logger::DEBUG if ENV['JELLYGEM_DEBUG']
    end

    # Creates and configures a new logger instance
    # @return [Logger] configured logger instance
    def setup_logger
      logger = Logger.new('jellygem.log', 'weekly')
      logger.level = Logger::INFO

      # Set formatter
      logger.formatter = proc do |severity, datetime, _, msg|
        "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
      end

      logger
    end
  end
end

# Initialize the application
Jellygem.setup
