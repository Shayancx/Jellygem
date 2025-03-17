# frozen_string_literal: true

module Jellygem
  module Processors
    # Episode processor handles processing of individual episode files
    # Renames files according to naming convention and adds metadata
    class EpisodeProcessor < BaseProcessor
      def initialize
        super
        @metadata_processor = MetadataProcessor.new
        @formatter = Formatters::EpisodeFormatter.new
      end

      # Process all episode files in a folder
      # @param folder [String] folder containing episode files
      # @param series [Models::Series] parent series
      # @param default_season [Integer] default season number
      # @param season [Models::Season, nil] season data if available
      # @return [void]
      def process_files(folder, series, default_season, season = nil)
        video_files = Dir.glob(File.join(folder, '*.{mkv,mp4,avi,m4v}'))

        if video_files.empty?
          puts warning('No video files found in this folder.')
          return
        end

        puts "Found #{video_files.length} video files."

        # Set up processing
        episode_cache = {}
        sorted_files = sort_files(video_files)
        total_files = sorted_files.length
        renamed_files = 0
        failed_files = 0

        # Process each file
        sorted_files.each_with_index do |file, index|
          filename = File.basename(file)
          extension = File.extname(file)[1..] # Remove the leading dot

          # Print progress
          print_progress_bar(index + 1, total_files)

          # Process individual episode file
          if process_single_file(file, folder, filename, extension, series, default_season, season, episode_cache)
            renamed_files += 1
          else
            failed_files += 1
          end
        end

        # Print final stats
        puts "\nRenamed #{renamed_files} of #{total_files} episode files."
        puts warning("Failed to rename #{failed_files} files.") if failed_files.positive?
      end

      private

      # Process a single episode file
      # @param file [String] path to episode file
      # @param folder [String] containing folder
      # @param filename [String] episode filename
      # @param extension [String] file extension
      # @param series [Models::Series] parent series
      # @param default_season [Integer] default season number
      # @param season [Models::Season, nil] season data if available
      # @param episode_cache [Hash] cache for episode details
      # @return [Boolean] true if successful
      def process_single_file(file, folder, filename, extension, series, default_season, _season, episode_cache)
        # Get episode info (season and episode numbers)
        episode_info = get_episode_info(filename, default_season)
        return false unless episode_info

        # Get episode data from TMDB
        episode_data = get_episode_data(
          series.id,
          episode_info[:season],
          episode_info[:episode],
          episode_cache
        )

        # Process with episode data if available
        if episode_data
          process_with_episode_data(file, folder, extension, series, episode_data)
        else
          # Basic renaming without TMDB data
          basic_rename(file, folder, extension, episode_info)
        end
      end

      # Get episode info from filename or ask user
      # @param filename [String] episode filename
      # @param default_season [Integer] default season number
      # @return [Hash, nil] hash with season and episode numbers or nil if failed
      def get_episode_info(filename, default_season)
        # Try to parse episode info from filename
        episode_info = parse_episode_info(filename)

        # If we can't determine automatically, ask user
        unless episode_info
          puts "\n#{warning("Could not determine season/episode for: #{filename}")}"

          season_num = default_season || prompt('Enter season number', '1').to_i
          episode_num = prompt('Enter episode number', '1').to_i

          episode_info = { season: season_num, episode: episode_num }
        end

        episode_info
      end

      # Process episode with available TMDB data
      # @param file [String] path to episode file
      # @param folder [String] containing folder
      # @param extension [String] file extension
      # @param series [Models::Series] parent series
      # @param episode_data [Hash] episode data from TMDB
      # @return [Boolean] true if successful
      def process_with_episode_data(file, folder, extension, series, episode_data)
        # Create Episode model
        episode = Models::Episode.new(episode_data)

        # Get new filename
        new_filename = @formatter.format_filename(episode, extension)

        # Rename file
        if rename_file(file, File.join(folder, new_filename))
          new_file_path = File.join(folder, new_filename)

          # Create metadata for this episode
          @metadata_processor.create_episode_metadata(episode, new_file_path, series)

          # Download episode images
          process_episode_images(episode, folder, File.basename(new_file_path, '.*'))

          return true
        end
        false
      end

      # Perform basic rename without TMDB data
      # @param file [String] path to episode file
      # @param folder [String] containing folder
      # @param extension [String] file extension
      # @param episode_info [Hash] hash with season and episode numbers
      # @return [Boolean] true if successful
      def basic_rename(file, folder, extension, episode_info)
        season_str = episode_info[:season].to_s.rjust(2, '0')
        episode_str = episode_info[:episode].to_s.rjust(2, '0')
        basic_filename = "S#{season_str}E#{episode_str}.#{extension}"

        rename_file(file, File.join(folder, basic_filename))
      end

      # Sort episode files in proper order
      # @param files [Array<String>] list of file paths
      # @return [Array<String>] sorted list of file paths
      def sort_files(files)
        files.sort_by do |file|
          info = parse_episode_info(File.basename(file))
          if info
            # Sort by season and episode number if available
            [info[:season], info[:episode]]
          else
            # Otherwise sort by filename
            File.basename(file)
          end
        end
      end

      # Fetch episode data from TMDB
      # @param series_id [Integer] TMDB series ID
      # @param season_num [Integer] season number
      # @param episode_num [Integer] episode number
      # @param cache [Hash] cache for episode details
      # @return [Hash, nil] episode data or nil if not found
      def get_episode_data(series_id, season_num, episode_num, cache)
        # Check cache first
        cache_key = "s#{season_num}e#{episode_num}"
        return cache[cache_key] if cache.key?(cache_key)

        # Skip TMDB lookup if we don't have series ID
        return nil unless series_id

        # Fetch from TMDB
        data = @tmdb_client.fetch_episode_details(series_id, season_num, episode_num)

        # Cache the result (even if nil)
        cache[cache_key] = data

        data
      end

      # Download episode thumbnail image
      # @param episode [Models::Episode] episode model
      # @param folder [String] containing folder
      # @param file_basename [String] base filename without extension
      # @return [Boolean] true if successful
      def process_episode_images(episode, folder, file_basename)
        return if @config.skip_images || !episode || !episode.still_path

        # Download episode thumbnail
        image_url = @tmdb_client.image_url(episode.still_path)
        thumb_path = File.join(folder, "#{file_basename}-thumb.jpg")

        return unless download_image(image_url, thumb_path)

        @logger.debug("Downloaded thumbnail for episode S#{episode.season_number}E#{episode.episode_number}")
        true
      end
    end
  end
end
