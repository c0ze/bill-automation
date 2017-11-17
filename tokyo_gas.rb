# coding: utf-8
require 'rubygems'
require 'pry-byebug'
require 'fileutils'
require 'csv'
require 'dotenv/load'

require_relative 'browser'
require_relative 'drive'

class TOKYO_GAS
  attr_accessor :br, :drive

  def initialize
    @download_dir = ENV['DOWNLOAD_DIR']
    @br = Browser.new
    @drive = Drive.new ENV['TOKYO_GAS_DRIVE_KEY']
  end

  def login
    @br.chrome.goto ENV['TOKYO_GAS_URL']
    @br.chrome.text_field(name: 'main_2$txtLoginId').set ENV['TOKYO_GAS_USER']
    @br.chrome.text_field(name: 'main_2$txtPassword').set ENV['TOKYO_GAS_PASS']
    @br.chrome.button(name: 'main_2$btnSubmit').click
  end

  def go_to_main
    @br.chrome.link(text: "見える").click
    @br.chrome.link(text: "料金明細を見る ＞").click
  end

  def update_sheet(row, key, value)
    @drive.ws[row, 1] = key
    @drive.ws[row, 2] = value
    @drive.ws.save
  end

  def get_amount(index)
    @br.chrome.table(class: 'base2').rows[index].cells[1].text
  end

  def get_month(index)
    @br.chrome.table(class: 'base2').rows[index].cells[0].text
  end

  def download_all(from = nil)
    binding.pry
    should_download = from ? false : true

    @br.chrome.button(class: "dropdown-toggle").click
    (1..@br.chrome.table(class: 'base2').rows.count-1).each do |i|
      month = get_month(i)
      if month == from
        should_download = true
        next
      end

      if should_download
        update_sheet(i, month, get_amount(i))

        @br.chrome.table(class: 'base2').rows[i].cells[2].button.click
        sleep 3

        file = "#{month}.html"
        File.open(file, 'w:UTF-8') do |f|
          f.write @br.chrome.table(id: 'main-contents').html
        end

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


gas = TOKYO_GAS.new
gas.login
# iij.download_all
gas.update_from_sheet

gas.quit
