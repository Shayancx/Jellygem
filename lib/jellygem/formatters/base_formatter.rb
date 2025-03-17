# frozen_string_literal: true

module Jellygem
  module Formatters
    # Base formatter class that provides common utilities for all formatters
    # Includes methods for XML escaping and filename formatting
    class BaseFormatter
      def initialize
        @logger = Jellygem.logger
      end

      protected

      # Escape special characters for XML
      # @param text [String] text to escape
      # @return [String] escaped text
      def escape_xml(text)
        return '' unless text

        xml_mappings = {
          '&' => '&amp;',
          '<' => '&lt;',
          '>' => '&gt;',
          '"' => '&quot;'
        }

        text.to_s.gsub(/[&<>"]/) { |match| xml_mappings[match] }
      end

      # Format filename to consistent pattern with sanitization
      # @param base [String] base filename
      # @param name [String, nil] optional name to append
      # @param extension [String, nil] optional file extension
      # @return [String] formatted filename
      def format_filename(base, name = nil, extension = nil)
        if name
          # Sanitize the name
          sanitized_name = name.gsub(%r{[/\\:*?"<>|]}, '_')
                               .gsub(/\s+/, '_')
                               .gsub(/_+/, '_')
                               .gsub(/^_+|_+$/, '')

          extension ? "#{base}_#{sanitized_name}.#{extension}" : "#{base}_#{sanitized_name}"
        else
          extension ? "#{base}.#{extension}" : base
        end
      end
    end
  end
end
