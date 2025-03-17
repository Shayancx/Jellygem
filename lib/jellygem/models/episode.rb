# frozen_string_literal: true

module Jellygem
  module Models
    # Episode model represents a single TV show episode
    # Contains all metadata for an episode
    class Episode
      attr_reader :id, :name, :overview, :episode_number, :season_number,
                  :air_date, :vote_average, :still_path, :crew, :guest_stars

      # Initialize a new episode from data
      # @param data [Hash] episode data
      def initialize(data = {})
        @id = data['id']
        @name = data['name']
        @overview = data['overview']
        @episode_number = data['episode_number']
        @season_number = data['season_number']
        @air_date = data['air_date']
        @vote_average = data['vote_average']
        @still_path = data['still_path']
        @crew = data['crew'] || []
        @guest_stars = data['guest_stars'] || []
      end

      # Returns a list of directors for this episode
      # @return [Array<String>] list of director names
      def directors
        @crew.select { |c| c['job'] == 'Director' }.map { |d| d['name'] }
      end
    end
  end
end
