# frozen_string_literal: true

module Jellygem
  module Processors
    # Base processor class that provides common utilities for all processors
    # Contains helper methods for file and folder name processing
    class BaseProcessor
      include Utils::UIHelper
      include Utils::FileHelper

      def initialize
        @logger = Jellygem.logger
        @config = Jellygem.config
        @tmdb_client = TMDBClient.new
      end

      protected

      # Process a folder name to extract likely series name
      # @param folder_name [String] original folder name
      # @return [String] processed name suitable for searching
      def process_folder_name(folder_name)
        clean_name = sanitize_folder_name(folder_name)

        # Extract year if present for the "Name (Year)" format
        if clean_name =~ /(.+?)\s+(19|20)\d{2}/
          name = ::Regexp.last_match(1).strip
          year = ::Regexp.last_match(2)
          "#{name} (#{year})"
        else
          clean_name
        end
      end

      # Detect season number from folder name
      # @param folder_name [String] folder name
      # @return [Integer, nil] season number or nil if not detected
      def detect_season_number(folder_name)
        # Common patterns: "Season 1", "S01", "S1", etc.
        return ::Regexp.last_match(1).to_i if folder_name =~ /\bS(?:eason)?\s*(\d+)\b/i

        # Try patterns like "1" (standalone number)
        return ::Regexp.last_match(1).to_i if folder_name =~ /^(\d+)$/ && ::Regexp.last_match(1).to_i < 50

        nil
      end

      # Parse episode info from a filename
      # @param filename [String] episode filename
      # @return [Hash, nil] hash with season and episode numbers or nil if not detected
      def parse_episode_info(filename)
        # Try to match common episode numbering patterns
        patterns = [
          # S01E01 pattern
          { regex: /S(\d+)E(\d+)/i, season_index: 1, episode_index: 2 },

          # 1x01 pattern
          { regex: /(\d+)x(\d+)/i, season_index: 1, episode_index: 2 },

          # Series 101 pattern (S01E01)
          { regex: /\b(\d)(\d{2})\b/, season_index: 1, episode_index: 2 }
        ]

        patterns.each do |pattern|
          if filename =~ pattern[:regex]
            return {
              season: ::Regexp.last_match(pattern[:season_index]).to_i,
              episode: ::Regexp.last_match(pattern[:episode_index]).to_i
            }
          end
        end

        nil
      end

      private

      # Sanitize folder name by removing common patterns and noise
      # @param folder_name [String] original folder name
      # @return [String] sanitized folder name
      def sanitize_folder_name(folder_name)
        clean_name = folder_name.dup

        # Remove common patterns
        clean_name = clean_name.gsub(/\b(720p|1080p|2160p|x264|x265|HEVC|BluRay|WEB-DL|COMPLETE)\b/i, '')
        clean_name = clean_name.gsub(/\bS\d+E\d+\b|\bSeason\s+\d+\b/i, '')
        clean_name = clean_name.gsub(/\[.*?\]|\(.*?\)/, '')
        clean_name = clean_name.gsub(/\._-/, ' ')
        clean_name.gsub(/\s+/, ' ').strip
      end
    end
  end
end
