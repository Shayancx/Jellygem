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
        @helper = setup_helper
      end

      # Process all episode files in a folder
      # @param folder [String] folder containing episode files
      # @param series [Models::Series] parent series
      # @param default_season [Integer] default season number
      # @param season [Models::Season, nil] season data if available
      # @return [void]
      def process_files(folder, series, default_season, season = nil)
        video_files = find_video_files(folder)
        return if video_files.empty?

        puts "Found #{video_files.length} video files."

        # Process found video files
        process_batch(folder, series, default_season, season, video_files)
      end

      private

      # Setup the helper class
      # @return [EpisodeProcessorHelper] configured helper
      def setup_helper
        helper = EpisodeProcessorHelper.new(
          @formatter,
          @metadata_processor,
          @tmdb_client,
          @config,
          @logger
        )
        helper.associate_processor(self)
        helper
      end

      # Process a batch of video files
      # @param folder [String] containing folder
      # @param series [Models::Series] parent series
      # @param default_season [Integer] default season number
      # @param season [Models::Season, nil] season data if available
      # @param video_files [Array<String>] list of video file paths
      # @return [void]
      def process_batch(folder, series, default_season, season, video_files)
        stats = batch_process_stats(folder, series, default_season, season, video_files)
        print_final_stats(stats[:renamed], stats[:total], stats[:failed])
      end

      # Find all video files in a folder
      # @param folder [String] folder to search
      # @return [Array<String>] list of video file paths
      def find_video_files(folder)
        video_files = Dir.glob(File.join(folder, '*.{mkv,mp4,avi,m4v}'))

        puts warning('No video files found in this folder.') if video_files.empty?

        video_files
      end

      # Process files and collect statistics
      # @param folder [String] containing folder
      # @param series [Models::Series] parent series
      # @param default_season [Integer] default season number
      # @param season [Models::Season, nil] season data if available
      # @param video_files [Array<String>] list of video file paths
      # @return [Hash] processing statistics
      def batch_process_stats(folder, series, default_season, season, video_files)
        # Setup processing
        context = create_processing_context(folder, series, default_season, season)
        sorted_files = sort_files(video_files)

        # Process files with progress tracking
        processing_results = process_files_with_progress(sorted_files, context)

        # Calculate statistics
        calculate_stats(sorted_files.length, processing_results)
      end

      # Create processing context for file processing
      # @param folder [String] containing folder
      # @param series [Models::Series] parent series
      # @param default_season [Integer] default season number
      # @param season [Models::Season, nil] season data if available
      # @return [Hash] processing context
      def create_processing_context(folder, series, default_season, season)
        {
          folder: folder,
          series: series,
          default_season: default_season,
          season: season,
          cache: {}
        }
      end

      # Calculate processing statistics
      # @param total_files [Integer] total number of files
      # @param results [Array<Boolean>] processing results
      # @return [Hash] statistics hash
      def calculate_stats(total_files, results)
        renamed_files = results.count(true)
        failed_files = results.count(false)

        { renamed: renamed_files, failed: failed_files, total: total_files }
      end

      # Process files with progress bar
      # @param files [Array<String>] files to process
      # @param context [Hash] processing context
      # @return [Array<Boolean>] success/failure for each file
      def process_files_with_progress(files, context)
        files.each_with_index.map do |file, index|
          print_progress_bar(index + 1, files.length)
          process_single_file(file, context)
        end
      end

      # Process a single file
      # @param file [String] file to process
      # @param context [Hash] processing context
      # @return [Boolean] success or failure
      def process_single_file(file, context)
        # Extract file information
        file_info = extract_file_info(file)

        # Create processing parameters
        params = create_processing_params(file, file_info, context)

        # Process the file
        @helper.process_single_file(params)
      end

      # Extract information from a file path
      # @param file [String] file path
      # @return [Hash] file information
      def extract_file_info(file)
        {
          filename: File.basename(file),
          extension: File.extname(file)[1..] # Remove leading dot
        }
      end

      # Create parameters for processing a file
      # @param file [String] file path
      # @param file_info [Hash] file information
      # @param context [Hash] processing context
      # @return [Hash] processing parameters
      def create_processing_params(file, file_info, context)
        {
          file: file,
          folder: context[:folder],
          filename: file_info[:filename],
          extension: file_info[:extension],
          series: context[:series],
          default_season: context[:default_season],
          season: context[:season],
          episode_cache: context[:cache]
        }
      end

      # Print final statistics after processing
      # @param renamed_files [Integer] number of successfully renamed files
      # @param total_files [Integer] total number of processed files
      # @param failed_files [Integer] number of failed files
      # @return [void]
      def print_final_stats(renamed_files, total_files, failed_files)
        puts "\nRenamed #{renamed_files} of #{total_files} episode files."
        puts warning("Failed to rename #{failed_files} files.") if failed_files.positive?
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
    end
  end
end
