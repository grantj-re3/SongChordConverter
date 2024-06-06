require 'yaml'
require 'optparse'

# Require local project files
require 'error_out'

##############################################################################
class Config
  # Singleton class: Has only class methods & class attributes

  # A hash of hashes. The key for the top-level hash is the class-name.
  @@cfg_data = {}

  class << self
    undef_method :new         # Make class method new() illegal

    def load(filename = CONFIG_PATH)
      unless @@cfg_data[self.name]       # Only load the config once
        cfg_default = {   # Set default values
          "inline_chord_prefix"         => '[',
          "inline_chord_suffix"         => ']',
          "instruction_regex_strings"   => [
            '^\s*(Chorus|CHORUS)\s*:?\s*$',
            '^\s*(Bridge|BRIDGE)\s*:?\s*$',
            '^\s*(Repeat|REPEAT)\s*:?\s*$',
            '^\s*(Verse|VERSE)\s*:?\s*$',
            '^\s*(Verse\s*\d+|VERSE\s*\d+)\s*:?\s*$',
          ],
          "bass_note_input_separator"   => '/',
          "bass_note_output_separator"  => '/',
          "no_chord_regex_string"       => 'N\.?C\.?|No-?[Cc]hord',
        }
        cfg = 
          begin
            YAML::load_file(filename)     # Returns hash (or false if no info is loaded)
          rescue Exception => e
            ErrorOut.show_message_exit("Error loading config file.\n#{e}", 1)
          end
        cfg ||= {}          # Repair when YAML::load_file() above returns false
        cfg = cfg_default.merge(cfg)
        @@cfg_data[self.name] = cfg       # key = the name of this class

        make_instruction_regexes
        define_class_attr_reader_methods
      end
    end

    private

    def make_instruction_regexes
      cfg = @@cfg_data[self.name]
      cfg["instruction_regex_list"] = cfg["instruction_regex_strings"].map{|s|
        begin
          Regexp.new(s)
        rescue Exception => e
          ErrorOut.show_message_exit("Error converting config file string '#{s}' to regular expression.\n#{e}", 4)
        end
      }
    end

    def define_class_attr_reader_methods
      #cfg = @@cfg_data[self.name]
      @@cfg_data[self.name].each{|key, val|
        name = key   #.to_s
        class_eval(<<-EOS
          def self.#{name}
            @@cfg_data[self.name]['#{name}']
          end
        EOS
        )
      }
    end

  end
end

##############################################################################
class UIOptions < Config
  # Singleton class: Has only class methods & class attributes

  def self.load
    cfg = {                 # Set default values
      "input_layout"        => :input_chords_above,
      "output_layout"       => :output_chords_inline,
      "debug_line_types?"   => false,

      # We will set "transpose?" true when:
      # - the user changes the transpose output format (tp_out_fmt), or
      # - points to a transpose output-format file (tp_out_file), or
      # - updates transpose steps (s_transpose_steps), even if the
      #   number of transpose steps is zero!
      "transpose?"          => false,
      "s_transpose_steps"   => "0",
      "tp_out_fmt"          => :sharps,
      "tp_out_file"         => nil,
    }
    unless @@cfg_data[self.name]       # Only load the config once
      op = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename(__FILE__)}  [options]  [SONG_FILENAME.txt]"
      
        opts.on("-h", "--help", "Prints this help") do
          puts opts
          exit
        end

        # Song input format
        opts.on("-a", "--input-ca", "Input file layout: chords above lyric [default]") do
          cfg["input_layout"] = :input_chords_above
        end

        opts.on("-i", "--input-ci", "Input file layout: chords inline with lyric") do
          cfg["input_layout"] = :input_chords_inline
        end

        # Song output format
        opts.on("-A", "--output-ca", "Output file layout: chords above lyric") do
          cfg["output_layout"] = :output_chords_above
        end

        opts.on("-I", "--output-ci", "Output file layout: chords inline with lyric [default]") do
          cfg["output_layout"] = :output_chords_inline
        end

        # Transpose steps
        opts.on("-s NUM", "--transpose-steps NUM", "Number of semitones/steps to transpose, e.g. 3 or -2") do |s_num|
          cfg["s_transpose_steps"] = s_num
          cfg["transpose?"] = true
        end

        # Transpose output format
        opts.on("-#", "--tp-fmt-#", "Transpose output format: All sharps [default]") do
          cfg["tp_out_fmt"] = :sharps
          cfg["transpose?"] = true
        end

        opts.on("-B", "--tp-fmt-#-Bb", "--tp-fmt-#-bb", "Transpose output format: All sharps except Bb") do
          cfg["tp_out_fmt"] = :sharps_bb
          cfg["transpose?"] = true
        end

        opts.on("-b", "--tp-fmt-b", "Transpose output format: All flats") do
          cfg["tp_out_fmt"] = :flats
          cfg["transpose?"] = true
        end

        opts.on("-n NOTES.yaml", "--tp-fmt-file NOTES.yaml", "Transpose output format: Customise in YAML file") do |filepath|
          cfg["tp_out_file"] = filepath
          cfg["transpose?"] = true
        end

        # Debug
        opts.on("-l", "--debug-line-types", "Debug only: Display the type of each line") do
          cfg["debug_line_types?"] = true
        end
      end
      begin
        op.parse!   # ARGV is left with song-filename(s) or empty (to read song from STDIN)
      rescue OptionParser::InvalidOption => e
        ErrorOut.show_message_exit(e, 6)
      end
      @@cfg_data[self.name] = cfg
    end

    if /^[+-]?\d$/.match(cfg["s_transpose_steps"])
      cfg["num_transpose_steps"] = cfg["s_transpose_steps"].to_i
    else
      msg = "ERROR: Number of steps to transpose must be an optional '+' or '-' followed by a digit, 0-9.\n#{op}"
      ErrorOut.show_message_exit(msg, 5)
    end

    if ARGV.size != 1
      msg = "ERROR: You must specify one song-filename (or hyphen '-' to read from STDIN).\n#{op}"
      ErrorOut.show_message_exit(msg, 2)
    end
    define_class_attr_reader_methods
  end

end
