# frozen_string_literal: true

module Jellygem
  module Formatters
    # Formatter for TV show episodes
    # Handles generating NFO metadata files and proper filenames for episodes
    class EpisodeFormatter < BaseFormatter
      # Format episode NFO content for media servers
      # @param episode [Models::Episode] episode data
      # @param episode_path [String] path to the episode file
      # @param series [Models::Series] parent series data
      # @return [String] formatted NFO XML content
      def format_nfo(episode, episode_path, series)
        @logger.debug("Formatting episode NFO for: S#{episode.season_number}E#{episode.episode_number}")
        nfo_content = build_base_episode_nfo(episode, series)
        nfo_content = add_thumb_to_nfo(nfo_content, episode_path, episode)
        nfo_content = add_directors_to_nfo(nfo_content, episode)
        nfo_content = add_guest_stars_to_nfo(nfo_content, episode)
        nfo_content << "  </episodedetails>\n"
        nfo_content
      end

      # Format episode filename
      # @param episode [Models::Episode] episode data
      # @param extension [String] file extension
      # @return [String] formatted filename
      def format_filename(episode, extension = 'mkv')
        # Base format: S01E01
        base = "S#{episode.season_number.to_s.rjust(2, '0')}E#{episode.episode_number.to_s.rjust(2, '0')}"

        # Append name if available
        if episode.name
          super(base, episode.name, extension)
        else
          "#{base}.#{extension}"
        end
      end

      private

      # Builds the base episode NFO structure
      # @param episode [Models::Episode] episode data
      # @param series [Models::Series] parent series data
      # @return [String] base NFO XML content
      def build_base_episode_nfo(episode, series)
        <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <episodedetails>
            <title>#{escape_xml(episode.name || '')}</title>
            <showtitle>#{escape_xml(series ? series.name : '')}</showtitle>
            <season>#{episode.season_number}</season>
            <episode>#{episode.episode_number}</episode>
            <aired>#{episode.air_date || ''}</aired>
            <plot>#{escape_xml(episode.overview || '')}</plot>
            <rating>#{episode.vote_average || ''}</rating>
        XML
      end

      # Adds thumb reference to NFO if available
      # @param content [String] current NFO content
      # @param episode_path [String] path to the episode file
      # @param episode [Models::Episode] episode data
      # @return [String] updated NFO content
      def add_thumb_to_nfo(content, episode_path, episode)
        # Determine thumb filename
        return content unless episode_path

        thumb_path = "#{File.dirname(episode_path)}/#{File.basename(episode_path, '.*')}-thumb.jpg"
        thumb_filename = File.basename(thumb_path)

        # Add thumb reference if image exists or will exist
        thumb_exists = File.exist?("#{File.dirname(episode_path)}/#{thumb_filename}")
        content << "    <thumb>#{thumb_filename}</thumb>\n" if thumb_filename && (thumb_exists || episode.still_path)

        content
      end

      # Adds director information to NFO if available
      # @param content [String] current NFO content
      # @param episode [Models::Episode] episode data
      # @return [String] updated NFO content
      def add_directors_to_nfo(content, episode)
        # Add directors
        if episode.respond_to?(:directors) && episode.directors.any?
          episode.directors.each do |director|
            content << "    <director>#{escape_xml(director)}</director>\n"
          end
        end

        content
      end

      # Adds guest star information to NFO if available
      # @param content [String] current NFO content
      # @param episode [Models::Episode] episode data
      # @return [String] updated NFO content
      def add_guest_stars_to_nfo(content, episode)
        return content unless episode.guest_stars&.any?

        episode.guest_stars.each do |actor|
          content << format_actor_nfo(actor)
        end

        content
      end

      # Formats a single actor for the NFO file
      # @param actor [Hash] actor data
      # @return [String] XML for the actor
      def format_actor_nfo(actor)
        <<~ACTOR
          <actor>
            <name>#{escape_xml(actor['name'])}</name>
            <role>#{escape_xml(actor['character'] || '')}</role>
          </actor>
        ACTOR
      end
    end
  end
end
