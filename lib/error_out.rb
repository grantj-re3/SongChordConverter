##############################################################################
class ErrorOut
  # Singleton class: Has only class methods & class attributes

  def self.show_message_exit(msg, exit_num=0)
    STDERR.puts msg
    exit(exit_num)
  end
end
