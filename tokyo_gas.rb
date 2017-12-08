# coding: utf-8
require 'rubygems'
require 'pry-byebug'
require 'fileutils'
require 'csv'
require 'dotenv/load'

require_relative 'browser'
require_relative 'drive'

PDF_FOLDER = ENV['TOKYO_GAS_PDF_FOLDER_KEY']
CSV_FOLDER = ENV['TOKYO_GAS_CSV_FOLDER_KEY']

class TOKYO_GAS
  attr_accessor :br, :drive

  def initialize
    @download_dir = ENV['DOWNLOAD_DIR']
    @br = Browser.new
    @drive = Drive.new ENV['TOKYO_GAS_DRIVE_KEY']

    @bill_page = "https://members.tokyo-gas.co.jp/mytokyogas/mtgmenu/mieru/total.aspx"
  end

  def login
    @br.chrome.goto ENV['TOKYO_GAS_URL']
    @br.chrome.text_field(name: 'main_2$txtLoginId').set ENV['TOKYO_GAS_USER']
    @br.chrome.text_field(name: 'main_2$txtPassword').set ENV['TOKYO_GAS_PASS']
    @br.chrome.button(name: 'main_2$btnSubmit').click
    go_to_main
  end

  def go_to_main
    @br.chrome.goto @bill_page
    @br.chrome.td(class: "list-more-view").click
  end

  def update_sheet(row, key, value)
    @drive.ws[row, 1] = key
    @drive.ws[row, 2] = value
    @drive.ws.save
  end

  def base_table
    @br.chrome.table(class: 'billing-all')
  end

  def get_amount(index)
    base_table.rows[index].cells[1].text
  end

  def get_month(index)
    base_table.rows[index].cells[0].text
  end

  def pdf_button
    @br.chrome.link(text: "ガスPDFダウンロード")
  end

  def csv_button
    @br.chrome.link(text: "CSVダウンロード")
  end

  def download_pdf(month)
    if pdf_button.exists?
      pdf_button.click
      sleep 5
      file = Dir.glob("#{@download_dir}/*.pdf").first
      FileUtils.mv(file, "./#{month}.pdf")
      @drive.upload("#{month}.pdf", PDF_FOLDER)
      File.delete "#{month}.pdf"
    end
  end

  def download_csv(month)
    if csv_button.exists?
      csv_button.click
      sleep 5
      file = Dir.glob("#{@download_dir}/*.csv").first

      csv_file = "#{month}.csv"
      File.open(csv_file, 'w:UTF-8') do |f|
        f.write File.open(file, "r:Shift_JIS").read
      end
      @drive.upload(csv_file, CSV_FOLDER)

      File.delete file
      File.delete csv_file
    end
  end

  def download_all(from = nil)
    should_download = from ? false : true

    (1..base_table.rows.count-2).each do |i|
      table_row = (base_table.rows.count-1-i)
      month = get_month(table_row)
      if month == from
        should_download = true
        next
      end

      if should_download
        update_sheet(i, month, get_amount(table_row))

#        base_table.rows[table_row].cells[4].link.click
#        download_pdf(month)
#        download_csv(month)
#        go_to_main
#        sleep 3

      end
    end
  end

  def update_from_sheet
    last_month = @drive.last_month
    download_all last_month
  end

  def quit
    @br.chrome.quit
  end
end


gas = TOKYO_GAS.new
gas.login
# iij.download_all
gas.update_from_sheet

gas.quit
