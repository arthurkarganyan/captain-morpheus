class UserNotifier
  def notify!(action = nil)
    `cvlc ~/Dropbox/Sounds/beep18.mp3 --play-and-exit`
  end
end