# Require local project files
require 'line_segment'

##############################################################################
class Line
  @@chord_regex = nil
  @@blank_regex = /^\s*$/

  attr_reader :line

  def initialize(text_line)
    self.class.set_chord_regex unless @@chord_regex
    @line = text_line
  end

  def to_s
    @line
  end

  # Subclasses must override this method
  def to_s_inline
    raise "\nI don't know how to #{__method__} in class #{self.class}!\n#{self.inspect}"
  end

  #---------------------------------------------------------------------------
  # Class methods
  def self.set_chord_regex
    @@chord_regex = /(^|\s)(#{Chord.chord_parts_regex_string}|#{Config.no_chord_regex_string})/
  end

  def self.blank?(line)
    @@blank_regex.match(line)
  end

  def self.chord_line?(line)
    set_chord_regex unless @@chord_regex
    not blank?(line) and line.split(' ').all?{|word| @@chord_regex.match(word)}
  end

  def self.instruction_line?(line)
    not blank?(line) and Config.instruction_regex_list.any?{|r| r.match(line)}
  end
end

##############################################################################
class ChordLyricLine < Line

  @@all_chord_lyric_lines = []

  attr_reader :chord_line

  def initialize(text_line, chord_line)
    super(text_line)
    @chord_line = chord_line
    @line_segs = []

    @@all_chord_lyric_lines << self
  end

  def make_line_details
    @line_segs = LineSegment.make_line_segments(@chord_line, @line)
  end

  # FIXME: Part of a ChordLyricLine output converter. Put in a new class?
  def to_s_inline
    all_segs = @line_segs.map{|seg| seg.to_s_inline}
    puts "All line segments: #{all_segs.inspect}"  if DEBUG
    all_segs.join('')
  end

  def self.all
    @@all_chord_lyric_lines
  end
end

##############################################################################
class OtherLine < Line

  def to_s_inline
    @line
  end
end
