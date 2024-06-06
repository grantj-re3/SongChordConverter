require 'yaml'
require 'error_out'
require 'config'

##############################################################################
class Transposer
  @@note_list_flats     = %w(A Bb B C Db D Eb E F Gb G Ab)
  @@note_list_sharps    = %w(A A# B C C# D D# E F F# G G#)
  @@note_list_sharps_bb = %w(A Bb B C C# D D# E F F# G G#)  # All sharps except Bb
  
  @@note_to_index = {}  # {"A"=>0, "A#"=>1, "Bb"=>1,... "G#"=>11, "Ab"=>11}

  def initialize
    self.class.populate_note_to_index if @@note_to_index.empty?
    @transposed_notes = {}  # Cache the transposed notes for quick lookup next time

    @note_list = if UIOptions.tp_out_file
      self.class.get_custom_note_list
    else

      case UIOptions.tp_out_fmt
      when :flats
          @@note_list_flats
      when :sharps_bb
          @@note_list_sharps_bb
      else    # Default is :sharps
          @@note_list_sharps
      end
    end
  end

  def transpose_note(note)
    return nil if note.nil?
    return @transposed_notes[note] if @transposed_notes[note]   # Returned cached result

    index = @@note_to_index[note]
    tp_index = index ? (index + UIOptions.num_transpose_steps) % 12 : nil
    @transposed_notes[note] = index_to_note(tp_index)  # Cache & return the result
  end

  private

  def index_to_note(index)
    index ? @note_list[index] : nil
  end

  #---------------------------------------------------------------------------
  # Class methods

  def self.populate_note_to_index
    @@note_list_sharps.each_with_index{|n, i| @@note_to_index[n] = i}
    @@note_list_flats .each_with_index{|n, i| @@note_to_index[n] = i}
  end

  def self.get_custom_note_list
    begin
      custom_note_list = YAML::load_file(UIOptions.tp_out_file)
    rescue Exception => e
      ErrorOut.show_message_exit("Error loading transpose custom-output-notes file.\n#{e}", 7)
    end
    verify_custom_note_list(custom_note_list)
    custom_note_list
  end

  def self.verify_custom_note_list(list)
    unless list.is_a?(Array) && list.size == 12 && list.all?{|e| e.is_a?(String)}
      msg = "Custom-note-list: #{list.inspect}\n"
      msg << "ERROR: YAML-file #{File.basename(UIOptions.tp_out_file)} does not produce an array of 12 strings!"
      ErrorOut.show_message_exit(msg, 8)
    end
  end
end
