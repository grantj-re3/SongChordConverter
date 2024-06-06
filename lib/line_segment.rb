# Require local project files
require 'chord'
require 'config'

##############################################################################
class LineSegment
  # Pad the start of any end-of-line segments where required (i.e. where key is true).
  # An end-of-line segment is where there are chords beyond the end of the lyric text.
  @@end_seg_pad = {true => ' ', false => ''}
  @@no_chord_regex = nil

  def initialize
    self.class.set_no_chord_regex unless @@no_chord_regex
  end
  #---------------------------------------------------------------------------
  # Class methods
  def self.set_no_chord_regex
    @@no_chord_regex = /(^|\s)(#{Config.no_chord_regex_string})/
  end

  def self.get_line_segment_class(chord)
    set_no_chord_regex unless @@no_chord_regex
    (chord.empty? || @@no_chord_regex.match(chord)) ? NonTransposableLineSegment : TransposableLineSegment
  end

  def self.make_line_segments(chord_line, lyric_line)
    puts "+++ chord_line: #{chord_line.inspect}|lyric_line: #{lyric_line.inspect}" if DEBUG

    line_segs = []
    prev_index = 0
    prev_prev_chord = ""
    prev_chord = ""

    # Calculate chord-lyric segments. A segment:
    # - starts at the beginning of a chord (or start of line)
    # - ends immediately before the next chord (or end of line)
    scan = StringScanner.new(chord_line)
    while not scan.eos?
      chord = scan.scan_until(/[^\s]+/).strip # Scan to the next chord
      index = scan.charpos - chord.size       # The start-of-chord position
      unless index == 0
        is_eol_chord = prev_index >= lyric_line.size
        lyric_seg = is_eol_chord ? "" : lyric_line[prev_index, index - prev_index]
        is_prepend_space = is_eol_chord && line_segs.size > 0 && !prev_prev_chord.empty?
        line_segs << self.get_line_segment_class(prev_chord).new(prev_chord, lyric_seg, is_prepend_space)
        puts "line seg: #{line_segs.inspect}" if DEBUG
      end
      break if scan.eos?
      scan.scan_until(/\s/)                   # Scan to the next white-space
      prev_index = index
      prev_prev_chord = prev_chord
      prev_chord = chord
    end
    # Add the last line segment
    is_eol_chord = index >= lyric_line.size
    lyric_seg = is_eol_chord ? "" : lyric_line[index, lyric_line.size - index]
    is_prepend_space = is_eol_chord && line_segs.size > 0 && !prev_chord.to_s.empty?
    line_segs << self.get_line_segment_class(chord).new(chord, lyric_seg, is_prepend_space)
    puts "line seg: #{line_segs.inspect}" if DEBUG
    line_segs
  end
end

##############################################################################
class TransposableLineSegment < LineSegment
  def initialize(chord, lyric_seg, is_prepend_space)
    @chord_obj = Chord.new(chord)
    @lyric_seg = lyric_seg
    @is_prepend_space = is_prepend_space
  end

  def to_s_inline
    "#{@@end_seg_pad[@is_prepend_space]}#{Config.inline_chord_prefix}#{@chord_obj}#{Config.inline_chord_suffix}#{@lyric_seg}"
  end
end

##############################################################################
class NonTransposableLineSegment < LineSegment
  def initialize(chord, lyric_seg, is_prepend_space)
    super()
    @chord = chord
    @lyric_seg = lyric_seg
    @is_prepend_space = is_prepend_space
  end

  def to_s_inline
    if @chord.empty?
      "#{@lyric_seg}"
    else
      "#{@@end_seg_pad[@is_prepend_space]}#{Config.inline_chord_prefix}#{@chord}#{Config.inline_chord_suffix}#{@lyric_seg}"
    end
  end
end
