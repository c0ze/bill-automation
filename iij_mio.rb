# coding: utf-8
require 'rubygems'
require 'pry-byebug'
require 'fileutils'
require 'csv'
require 'dotenv/load'

require_relative 'browser'
require_relative 'drive'

HTML_FOLDER = ENV['IIJ_MIO_FOLDER_KEY']

class IIJ_MIO
  attr_accessor :br, :drive

  def initialize
    @download_dir = ENV['DOWNLOAD_DIR']
    @br = Browser.new
    @drive = Drive.new ENV['IIJ_MIO_DRIVE_KEY']
  end

  def login
    @br.chrome.goto ENV['IIJ_MIO_URL']
    @br.chrome.text_field(name: 'j_username').set ENV['IIJ_MIO_USER']
    @br.chrome.text_field(name: 'j_password').set ENV['IIJ_MIO_PASS']
    @br.chrome.button(name: 'login').click
  end

  def go_to_main
    @br.chrome.back
  end

  def get_amount(index)
    @br.chrome.table(class: 'base2').rows[index].cells[1].text
  end

  def get_month(index)
    @br.chrome.table(class: 'base2').rows[index].cells[0].text
  end

  def download_all(from = nil)
    should_download = from ? false : true

    (1..@br.chrome.table(class: 'base2').rows.count-1).each do |i|
      month = get_month(i)
      if month == from
        should_download = true
        next
      end

      if should_download
        @drive.update_sheet(month, get_amount(i))

        @br.chrome.table(class: 'base2').rows[i].cells[2].button.click
        sleep 3

        file = "#{month}.html"
        File.open(file, 'w:UTF-8') do |f|
          f.write @br.chrome.table(id: 'main-contents').html
        end

        @drive.upload(file, HTML_FOLDER)
        File.delete file
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
  iij = IIJ_MIO.new
  iij.login
  # iij.download_all
  iij.update_from_sheet
  iij.quit
end
