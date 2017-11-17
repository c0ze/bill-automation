require 'google_drive'

class Drive
  attr_accessor :ws

  def initialize(key)
    @session = GoogleDrive::Session.from_config("config.json")
    get_spread_sheet(key)
    get_work_sheet(current_year)
  end

  def update_sheet(key, value)
    row = @ws.num_rows + 1
    @ws[row, 1] = key
    @ws[row, 2] = value
    @ws.save
  end

  def current_year
    Date.today.year.to_s
  end

  def get_spread_sheet(key)
    @ss = @session.spreadsheet_by_key(key)
  end

  def get_work_sheet(title)
    unless @ws = @ss.worksheet_by_title(title)
      @ws = @ss.add_worksheet(title)
    end
  end

  def upload(name, parent)
     @session.upload_from_file(name, name, {convert:false, parents: [parent]})
  end

  def last_month
    if @ws.num_rows > 0
      @ws[@ws.num_rows, 1]
    end
  end
end

