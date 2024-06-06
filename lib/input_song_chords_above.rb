# Require local project files
require 'line'

##############################################################################
class InputSongChordsAbove
  def initialize
    @lines = []       # List of Line objects (subclasses of Line)
  end

  def parse
    begin
      line_type_info = get_song_lines_and_type_info
    rescue Errno::ENOENT, Errno::EISDIR, Errno::EACCES => e
      ErrorOut.show_message_exit("Error processing song-file.\n#{e}", 3)
    end
    show_line_types_exit(line_type_info) if UIOptions.debug_line_types?

    create_line_objects(line_type_info)
    make_line_details
    @lines
  end

  private

  def get_song_lines_and_type_info
    # Add an (unwanted) blank line at the start so we can test with: types[-1]==:something
    text_lines = [""]             # List of text-lines
    types = [:unwanted]           # List of types for each element of text_lines

    ARGF.each_line{|raw_line|     # Read song from file or STDIN
      line = raw_line.rstrip
      text_lines << line

      if Line.blank?(line)
        types[-1] = :chord_no_lyric if types[-1] == :chord  # Fix the previous type
        types << ([:blank, :unwanted].include?(types[-1]) ? :unwanted : :blank)

      elsif Line.instruction_line?(line)
        types[-1] = :chord_no_lyric if types[-1] == :chord  # Fix the previous type
        types << :instr

      elsif Line.chord_line?(line)
        types[-1] = :chord_no_lyric if types[-1] == :chord  # Fix the previous type
        types << :chord

      elsif types[-1] == :chord
        types << :lyric

      else
        types << :other
      end
    }
    types[-1] = :chord_no_lyric if types[-1] == :chord  # Fix the previous type
    types[-1] = :unwanted if types[-1] == :blank        # Do not end with a blank line
    {:text_lines => text_lines, :types => types}        # Return the arrays
  end

  def show_line_types_exit(line_type_info)
    text_lines = line_type_info[:text_lines]
    line_type_info[:types].each_with_index{|type, i| puts "#{type}: '#{text_lines[i]}'"}
    exit 0
  end

  def create_line_objects(line_type_info)
    text_lines = line_type_info[:text_lines]

    line_type_info[:types].each_with_index{|type, i|
      unless [:unwanted, :chord].include?(type)
        case type
        when :lyric
          chord_line = text_lines[i-1]      # The previous line is the chord line
          @lines << ChordLyricLine.new(text_lines[i], chord_line)

        when :chord_no_lyric
          chord_line = text_lines[i]
          leading_spaces = /^\s*/.match(chord_line).to_s
          @lines << ChordLyricLine.new(leading_spaces, text_lines[i])

        when :instr
          @lines << OtherLine.new(text_lines[i].strip)

        when :blank
          @lines << OtherLine.new("")

        when :other
          @lines << OtherLine.new(text_lines[i])
        end
      end
    }
  end

  def make_line_details
    ChordLyricLine.all.each{|line| line.make_line_details}
  end

end
