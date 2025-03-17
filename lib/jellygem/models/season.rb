# frozen_string_literal: true

module Jellygem
  module Models
    # Season model represents a TV show season
    # Contains all metadata for a season and references to its episodes
    class Season
      attr_reader :id, :name, :overview, :season_number, :air_date,
                  :episode_count, :poster_path, :episodes

      # Initialize a new season from data
      # @param data [Hash] season data
      def initialize(data = {})
        @id = data['id']
        @name = data['name']
        @overview = data['overview']
        @season_number = data['season_number']
        @air_date = data['air_date']
        @episode_count = data['episode_count']
        @poster_path = data['poster_path']
        @episodes = []

        # Initialize episodes if present in data
        return unless data['episodes']

        @episodes = data['episodes'].map { |episode_data| Episode.new(episode_data) }
      end
    end
  end
end
