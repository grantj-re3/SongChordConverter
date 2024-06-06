# Require local project files
require 'line'
require 'transposer'

##############################################################################
class SongHolder
  def initialize(input_song)
    @lines = input_song.parse       # List of Line objects (subclasses of Line)
  end

  def chords_inline
    @lines.each{|line| puts line.to_s_inline}
  end

  # FIXME
  def chords_above
  end

  def transpose
    return unless UIOptions.transpose?
    tp = Transposer.new
    Chord.chord_list.each{|c| c.transpose(tp)}
  end
end
