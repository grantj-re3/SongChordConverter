# Require local project files
require 'transposer'

##############################################################################
class Chord
  @@chord_list = []

  @@chord_parts_regex_string = nil
  @@chord_parts_regex = nil

  def initialize(chord)
    self.class.set_chord_parts_regex unless @@chord_parts_regex
    m = @@chord_parts_regex.match(chord)
    @root_note  = m[1]
    @ext        = m[2]
    @bass_note  = m[4]
    @@chord_list << self
    puts "CHORD:#{m.inspect}|| root:#{@root_note}| ext:#{@ext}| bass:#{@bass_note}" if DEBUG
  end

  def to_s
    "%s%s%s%s" % [@root_note, @ext, (@bass_note ? Config.bass_note_output_separator : ''), @bass_note]
  end

  def inspect
    "#{super.gsub(/:[^ ]+/, ":")}"
  end

  def transpose(transposer)
    @root_note = transposer.transpose_note(@root_note)
    @bass_note = transposer.transpose_note(@bass_note)
  end

  #---------------------------------------------------------------------------
  # Class methods
  
  def self.set_chord_parts_regex
    sep = Config.bass_note_input_separator
    # We are delimiting with /.../ instead of '...' to regexp-escape the user-configurable separator
    @@chord_parts_regex_string = /([A-G][b#]?)([^#{sep}]*)?(#{sep}([A-G][b#]?))?/.to_s
    @@chord_parts_regex = /^#{@@chord_parts_regex_string}$/
  end

  def self.chord_parts_regex_string
    set_chord_parts_regex unless @@chord_parts_regex
    @@chord_parts_regex_string
  end

  def self.chord_list
    @@chord_list
  end

end