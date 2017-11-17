# coding: utf-8
require 'rubygems'
require 'pry-byebug'
require 'fileutils'
require 'csv'
require 'dotenv/load'

require_relative 'browser'
require_relative 'drive'

PDF_FOLDER = ENV['NTT_FACILITIES_PDF_FOLDER_KEY']
CSV_FOLDER = ENV['NTT_FACILITIES_CSV_FOLDER_KEY']

class NTT
  attr_accessor :br, :drive

  def initialize
    @download_dir = ENV['DOWNLOAD_DIR']
    @br = Browser.new
    @drive = Drive.new ENV['NTT_FACILITIES_DRIVE_KEY']
  end

  def login
    @br.chrome.goto ENV['NTT_FACILITIES_URL']
    @br.chrome.text_field(name: 'idUser').set ENV['NTT_FACILITIES_USER']
    @br.chrome.text_field(name: 'wtPassword').set ENV['NTT_FACILITIES_PASS']
    @br.chrome.button(class: 'cBtn_login').click
    go_to_main
  end

  def go_to_main
    @br.chrome.link(text: "ご利用明細").click
  end

  def get_amount(csv_file)
    CSV.read(File.open(csv_file, 'r:UTF-8'))[1][3]
  end

  def get_month(index)
    @br.chrome.table(class: 'tablefixed').rows[index].cells[3].text.gsub("/", ".")
  end

  def download_all(from = nil)
    should_download = from ? false : true
    (1..@br.chrome.table(class: 'tablefixed').rows.count-1).each do |i|
      month = get_month(i)
      if month == from
        should_download = true
        next
      end

      if should_download
        @br.chrome.table(class: 'tablefixed').rows[i].cells[1].link.click
        @br.chrome.button(id: "pdf").click
        sleep 5
        file = Dir.glob("#{@download_dir}/*.pdf").first
        FileUtils.mv(file, "./#{month}.pdf")
        @drive.upload("#{month}.pdf", PDF_FOLDER)
        File.delete "#{month}.pdf"

        @br.chrome.button(id: "csv").click
        sleep 5
        file = Dir.glob("#{@download_dir}/*.csv").first

        csv_file = "#{month}.csv"
        File.open(csv_file, 'w:UTF-8') do |f|
          f.write File.open(file, "r:Shift_JIS").read
        end
        @drive.upload(csv_file, CSV_FOLDER)

        @drive.update_sheet(month, get_amount(csv_file))
        File.delete file
        File.delete csv_file
        go_to_main
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

if __FILE__==$0
  ntt = NTT.new
  ntt.login
  ntt.update_from_sheet
  # ntt.download_all
  ntt.quit
end
