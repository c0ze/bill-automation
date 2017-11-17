require 'watir'

class Browser
  attr_accessor :chrome

  def initialize
    profile = Selenium::WebDriver::Chrome::Profile.new
    download_dir = File.join("./")
    # doesnt work ?
    profile['browser.download.dir'] = download_dir
    #profile['download.prompt_for_download'] = false

    @chrome = Watir::Browser.new ENV['BROWSER'].to_sym, profile: profile
#    , :switches => %w[--ignore-certificate-errors --disable-popup-blocking --disable-translate --disable-notifications --start-maximized --disable-gpu --headless]

  end
end
