# frozen_string_literal: true

module Jellygem
  module Models
    # Series model represents a TV series
    # Contains all metadata for a series and references to its seasons
    class Series
      attr_reader :id, :name, :original_name, :overview, :first_air_date,
                  :status, :vote_average, :popularity, :poster_path,
                  :backdrop_path, :genres, :networks, :seasons

      # Initialize a new series from data
      # @param data [Hash] series data
      def initialize(data = {})
        initialize_base_attributes(data)
        initialize_artwork_attributes(data)
        initialize_collections(data)
        initialize_seasons(data)
      end

      # Returns the year the series first aired
      # @return [String, nil] year or nil if unknown
      def year
        @first_air_date ? @first_air_date[0..3] : nil
      end

      private

      # Initialize basic series attributes
      # @param data [Hash] series data
      def initialize_base_attributes(data)
        @id = data['id']
        @name = data['name']
        @original_name = data['original_name']
        @overview = data['overview']
        @first_air_date = data['first_air_date']
        @status = data['status']
        @vote_average = data['vote_average']
        @popularity = data['popularity']
      end

      # Initialize artwork-related attributes
      # @param data [Hash] series data
      def initialize_artwork_attributes(data)
        @poster_path = data['poster_path']
        @backdrop_path = data['backdrop_path']
      end

      # Initialize collection attributes
      # @param data [Hash] series data
      def initialize_collections(data)
        @genres = data['genres'] || []
        @networks = data['networks'] || []
        @seasons = []
      end

      # Initialize seasons if present in data
      # @param data [Hash] series data
      def initialize_seasons(data)
        return unless data['seasons']

        @seasons = data['seasons'].map { |season_data| Season.new(season_data) }
      end
    end
  end
end
