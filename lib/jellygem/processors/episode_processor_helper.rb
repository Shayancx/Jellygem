# frozen_string_literal: true

module Jellygem
  module Processors
    # Helper class for EpisodeProcessor
    # Handles processing-specific operations for episode files
    class EpisodeProcessorHelper
      def initialize(formatter, metadata_processor, tmdb_client, config, logger)
        @formatter = formatter
        @metadata_processor = metadata_processor
        @tmdb_client = tmdb_client
        @config = config
        @logger = logger
        @processor = nil
      end

      # Process a single episode file
      # @param params [Hash] processing parameters
      # @return [Boolean] true if successful
      def process_single_file(params)
        # Get episode info (season and episode numbers)
        episode_info = get_episode_info(params[:filename], params[:default_season])
        return false unless episode_info

        # Choose processing method based on TMDB data availability
        determine_processing_approach(params, episode_info)
      end

      # Determine whether to process with TMDB data or basic info
      # @param params [Hash] processing parameters
      # @param episode_info [Hash] season and episode numbers
      # @return [Boolean] true if successful
      def determine_processing_approach(params, episode_info)
        # Get episode data from TMDB
        episode_data = fetch_episode_data(
          params[:series]&.id,
          episode_info,
          params[:episode_cache]
        )

        # Process based on data availability
        if episode_data
          process_with_tmdb_data(params, episode_data)
        else
          process_without_tmdb_data(params, episode_info)
        end
      end

      # Fetch episode data from TMDB
      # @param series_id [Integer, nil] series ID
      # @param episode_info [Hash] episode info
      # @param cache [Hash] episode cache
      # @return [Hash, nil] episode data or nil
      def fetch_episode_data(series_id, episode_info, cache)
        # Skip if no series ID
        return nil unless series_id

        season_num = episode_info[:season]
        episode_num = episode_info[:episode]

        # Check cache first
        cache_key = "s#{season_num}e#{episode_num}"
        return cache[cache_key] if cache.key?(cache_key)

        # Fetch and cache the data
        data = @tmdb_client.fetch_episode_details(series_id, season_num, episode_num)
        cache[cache_key] = data

        data
      end

      # Process with TMDB data available
      # @param params [Hash] processing parameters
      # @param episode_data [Hash] episode data from TMDB
      # @return [Boolean] true if successful
      def process_with_tmdb_data(params, episode_data)
        # Create Episode model
        episode = Models::Episode.new(episode_data)

        # Get new filename
        new_filename = @formatter.format_filename(episode, params[:extension])

        # Rename and process metadata
        rename_and_process_metadata(params[:file], params[:folder], params[:series], episode, new_filename)
      end

      # Process without TMDB data available
      # @param params [Hash] processing parameters
      # @param episode_info [Hash] basic episode information
      # @return [Boolean] true if successful
      def process_without_tmdb_data(params, episode_info)
        # Basic renaming without TMDB data
        basic_rename(params[:file], params[:folder], params[:extension], episode_info)
      end

      # Rename file and process metadata
      # @param file [String] path to episode file
      # @param folder [String] containing folder
      # @param series [Models::Series] parent series
      # @param episode [Models::Episode] episode model
      # @param new_filename [String] new filename
      # @return [Boolean] true if successful
      def rename_and_process_metadata(file, folder, series, episode, new_filename)
        new_path = File.join(folder, new_filename)
        if rename_file(file, new_path)
          process_episode_metadata(new_path, series, episode)
          return true
        end
        false
      end

      # Process episode metadata after renaming
      # @param file_path [String] path to renamed file
      # @param series [Models::Series] parent series
      # @param episode [Models::Episode] episode model
      # @return [void]
      def process_episode_metadata(file_path, series, episode)
        # Create metadata for this episode
        @metadata_processor.create_episode_metadata(episode, file_path, series)

        # Download episode images if enabled
        process_episode_images(episode, File.dirname(file_path), File.basename(file_path, '.*'))
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

      # Associate with parent processor
      # @param processor [EpisodeProcessor] parent processor
      # @return [void]
      def associate_processor(processor)
        @processor = processor
      end

      # Helper methods that need to be forwarded to the processor
      %i[warning prompt parse_episode_info rename_file download_image].each do |method|
        define_method(method) do |*args|
          raise "Method #{method} not available" unless @processor.respond_to?(method, true)

          @processor.send(method, *args)
        end
      end
    end
  end
end
