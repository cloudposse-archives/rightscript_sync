#
# RightScript Sync - A utility for syncing RightScripts from the RightScale enterprise cloud platform.
# Copyright (C) 2012 Erik Osterman <e@osterman.com>
# 
# This file is part of RightScript Sync.
# 
# RightScript Sync is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# RightScript Sync is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with RightScript Sync.  If not, see <http://www.gnu.org/licenses/>.
#
require 'nokogiri'
require 'json'
require 'mechanize'
require 'logger'
require 'base64'
require 'yaml'
require 'fileutils'
require 'digest/md5'

module RightScriptSync
  class Downloader
    attr_accessor :agent, :account_id, :username, :password, :log, :cookie_jar, :output_path, :dry_run

    def initialize(options)
      @log = Logger.new(STDOUT)
      @account_id = options[:account_id]
      @username = options[:username]
      @password = options[:password]
      @output_path = options[:output_path]
      @dry_run = options[:dry_run] || false
      @api_uri = "https://my.rightscale.com/api/acct/#{@account_id}"
      @site_uri = "https://my.rightscale.com/acct/#{@account_id}"

      @log.debug("account_id:#{@account_id} username:#{@username} password:#{@password}")
      @cookie_jar = Mechanize::CookieJar.new
      @agent = Mechanize.new do |agent|
        #agent.log = @log
        agent.user_agent_alias = 'Mac Safari'
        agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
        agent.cookie_jar = @cookie_jar
      end
    end

    def parse_right_scripts(xml)
      doc = Nokogiri::XML(xml)
      doc.encoding = 'UTF-8'
      right_scripts = [] 
      xpath_right_scripts = doc.xpath('/right-scripts[@type="array"]/right-script')
      xpath_right_scripts.each do |xpath_right_script|
        right_script = {}
        right_script[:name] = xpath_right_script.at_xpath('name/text()').to_s.strip
        right_script[:updated_at] = xpath_right_script.at_xpath('updated-at/text()').to_s.strip
        right_script[:created_at] = xpath_right_script.at_xpath('created-at/text()').to_s.strip
        right_script[:is_head_version] = xpath_right_script.at_xpath('is-head-version/text()').to_s.strip
        right_script[:href] = xpath_right_script.at_xpath('href/text()').to_s.strip
        right_script[:id] = right_script[:href].gsub(/^.*\//, '').to_i
        right_script[:version] = xpath_right_script.at_xpath('version/text()').to_s.strip.to_i
        right_script[:script] = xpath_right_script.at_xpath('script/text()').to_s.strip
        right_script[:description] = xpath_right_script.at_xpath('description/text()').to_s.strip
        right_scripts << right_script
      end
      return right_scripts
    end

    def parse_right_script_attachments(html)
      doc = Nokogiri::HTML(html)
      doc.encoding = 'UTF-8'
      right_script_attachments = [] 
      xpath_right_script_attachments = doc.xpath('//table[@id="right_scripts_show_script_attachments"]/tbody/tr')
      xpath_right_script_attachments.each do |xpath_right_script_attachment|
        right_script_attachment = {}
        right_script_attachment[:filename] = xpath_right_script_attachment.xpath('td[@data-column_name="Filename"]/a/text()').to_s.strip
        next if right_script_attachment[:filename].nil? || right_script_attachment[:filename].empty?
        right_script_attachment[:uri] = xpath_right_script_attachment.xpath('td[@data-column_name="Filename"]/a/@href').to_s.strip
        right_script_attachment[:size] = xpath_right_script_attachment.xpath('td[@data-column_name="Size"]/text()').to_s.strip
        right_script_attachment[:created_at] = xpath_right_script_attachment.xpath('td[@data-column_name="Created At"]/text()').to_s.strip
        right_script_attachment[:updated_at] = xpath_right_script_attachment.xpath('td[@data-column_name="Updated At"]/text()').to_s.strip
        right_script_attachment[:md5sum] = xpath_right_script_attachment.xpath('td[@data-column_name="md5sum"]/text()').to_s.strip
        right_script_attachments << right_script_attachment
      end
      return right_script_attachments
    end

    def login
      @log.info("Logging in")
      headers = { 'X-API-VERSION' => '1.0' }
      headers['Authorization'] = 'Basic ' + Base64.encode64( @username + ':' + @password )
      url = "#{@api_uri}/login?api_version=1.0"
      download(url, headers)
    end

    def download_right_scripts
      @log.info("Downloading RightScripts")
      headers = { 'X-API-VERSION' => '1.0' }
      url = "#{@api_uri}/right_scripts.xml"
      xml = download(url, headers)
      #xml = File.open("right_scripts.xml", "rb").read
      parse_right_scripts(xml)
    end

    def download_right_script_attachments(right_script_id)
      @log.info("Downloading attachments for #{right_script_id}")
      headers = { 'X-Requested-With' => 'XMLHttpRequest' }
      url = "#{@site_uri}/right_scripts/#{right_script_id}/script_attachments"
      html = download(url, headers)
      #html = File.open("foo.html", "rb").read
      parse_right_script_attachments(html)
    end

    def download_file(url, headers, file)
      @log.debug("Downloading #{url} to '#{file}'")
      return if @dry_run
      mkbasedir(file)
      @agent.get(url, nil, nil, headers).save(file)
     end

    def download(url, headers)
      @log.debug("Downloading #{url}")
      @agent.get(url, nil, nil, headers) do |page|
        return page.body
      end
    end

    def mkbasedir(file)
      dirname = File.dirname(file)
      unless File.directory?(dirname)
        @log.debug("Creating directory '#{dirname}'")
        return if @dry_run
        FileUtils.mkdir_p(dirname) 
      end
    end
   
    def store_metadata(file, data)
      return if @dry_run
      mkbasedir(file)
      File.open(file, 'w') do |fh|
        YAML.dump(data, fh)
      end
    end

    def store_file(file, data)
      return if @dry_run
      mkbasedir(file)
      File.open(file, 'w') do |fh|
        fh.write(data)
      end
    end

    def store_right_script_attachment(right_script_attachment, right_script_attachment_path)
      @log.info("Storing RightScript attachment '#{right_script_attachment[:filename]}' (#{right_script_attachment[:size]}) #{right_script_attachment[:updated_at]}")
      right_script_attachment_file_path = right_script_attachment_path + '/' + right_script_attachment[:filename]
      headers = {}
      url = right_script_attachment[:uri]
      if File.exists?(right_script_attachment_file_path)
        if Digest::MD5.file(right_script_attachment_file_path) == right_script_attachment[:md5sum]
          @log.info("Already downloaded #{right_script_attachment_file_path} with #{right_script_attachment[:md5sum]} md5")
          return
        end
      end
      download_file(url, headers, right_script_attachment_file_path)
      File.utime(Time.parse(right_script_attachment[:updated_at]), Time.parse(right_script_attachment[:created_at]), right_script_attachment_file_path)
      @log.info("Attachment stored to #{right_script_attachment_file_path}")
    end

    def store_right_script_attachments(right_script, right_script_path)
      right_script_attachment_path = "#{right_script_path}/attachments"
      @log.info("Storing RightScript attachments for '#{right_script[:name]}' to #{right_script_attachment_path}")
      download_right_script_attachments(right_script[:id]).each do |right_script_attachment|
        store_right_script_attachment(right_script_attachment, right_script_attachment_path)
      end
    end

    def store_right_script(right_script)
      @log.info("Storing RightScript (#{right_script[:name]})")
      right_script_path = "#{@output_path}/#{right_script[:id]}/#{normalize_right_script_name(right_script[:name])}/#{right_script[:version]}"

      right_script_file_path = "#{right_script_path}/script.txt"
      store_file(right_script_file_path, right_script[:script])
      File.utime(Time.parse(right_script[:updated_at]), Time.parse(right_script[:created_at]), right_script_file_path)

      right_script_metadata_path = "#{right_script_path}/metadata.yml"
      store_metadata(right_script_metadata_path, right_script)

      store_right_script_attachments(right_script, right_script_path)
    end

    def store_right_scripts
      @log.info("Storing RightScripts")
      download_right_scripts.each do |right_script|
        store_right_script(right_script)
      end
    end

    def normalize_right_script_name(right_script_name)
      right_script_name.gsub(/[^A-Za-z0-9_\.]+/, '_').downcase
    end

    def execute
      begin
        login
        store_right_scripts      
      rescue Interrupt
        exit
      rescue Exception => e
        puts e.message
        puts e.backtrace.join("\n")
      end
    end
  end
end