#!/usr/bin/ruby
# songcc.rb - song chord converter
##############################################################################
# Add dirs to the library path & require local project files
$: << File.expand_path("../lib", File.dirname(__FILE__))
require 'config'
require 'song_holder'
require 'input_song_chords_above'
require 'input_song_chords_inline'

##############################################################################
# For executable path /mypath/bin/app.rb, config path will be /mypath/config/app.yaml
CONFIG_DIR = File.expand_path("../config", File.dirname(__FILE__))
CONFIG_PATH = "#{File.join(CONFIG_DIR, File.basename(__FILE__, ".rb"))}.yaml"

DEBUG = false

##############################################################################
# Main
##############################################################################
Config.load
UIOptions.load
input_song = UIOptions.input_layout == :input_chords_above ? InputSongChordsAbove.new : InputSongChordsInline.new
song = SongHolder.new(input_song)
song.transpose
UIOptions.output_layout == :output_chords_inline ? song.show_chords_inline : song.show_chords_above
