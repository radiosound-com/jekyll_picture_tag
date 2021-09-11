module PictureTag
  module Parsers
    # Returns information regarding image handlers
    class ImageBackend
      def handler_for(format)
        if (vips_formats & all_names(format)).any?
          :vips
        elsif (magick_formats & all_names(format)).any?
          :magick
        else
          puts error_string(format)
          :magick
        end
      end

      # Returns array of formats that vips can save to
      def vips_formats
        @vips_formats ||= `vips -l filesave`
                          .scan(/\.[a-z]{1,5}/)
                          .uniq
                          .map { |format| format.strip.delete_prefix('.') }
      end

      # Returns an array of formats that imagemagick can handle.
      def magick_formats
        @magick_formats ||= `convert -version`
                            .split("\n")
                            .last
                            .delete_prefix('Delegates (built-in):')
                            .split
      end

      # Returns an array of all known names of a format, for the purposes of
      # parsing supported output formats.
      def all_names(format)
        alts = alternates.select { |a| a.include? format }.flatten
        alts.any? ? alts : [format]
      end

      private

      def error_string(format)
        <<~HEREDOC
          \tWARNING:
          \tNo support for generating #{format} files in this environment!
          \t\tLibvips known savers: #{vips_formats.join(', ')}
          \t\tImagemagick known savers:  #{magick_formats.join(', ')}

          \tFalling back to ImageMagick in case a delegate is available that is not built in at compile time

          \tIf this fails, check convert -l delegate and make sure you have the appropriate program installed for this file format
        HEREDOC
      end

      def alternates
        [%w[jpg jpeg], %w[avif heic heif], %w[svg rsvg]]
      end
    end
  end
end
