require 'optparser'

module RightScriptSync
  class MissingArgumentException < Exception; end

  class CommandLine
    attr_accessor :downloader
    def initialize
      @options = {}
      begin
        @optparse = OptionParser.new do |opts|
          opts.banner = "Usage: #{$0} options"
          
          @options[:dry_run] = false
          opts.on( '--dry-run', 'Output the parsed files to STDOUT' ) do
            @options[:dry_run] = true
          end
          
          opts.on( '--output-path DIR', 'Use DIR as output directory') do |dir|
            @options[:output_dir] = dir + '/'
          end
          
          opts.on( '--account-id ID', 'RightScale Account ID' ) do|account_id|
            @options[:account_id] = account_id
          end

          opts.on( '--username USERNAME', 'RightScale Username' ) do|username|
            @options[:username] = username
          end

          opts.on( '--password PASSWORD', 'RightScale Password' ) do|password|
            @options[:password] = password
          end

          opts.on( '-V', '--version', 'Display version information' ) do
            puts "RightScript Sync #{RightScriptSync::VERSION}"
            puts "Copyright (C) 2012 Erik Osterman <e@osterman.com>"
            puts "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>"
            puts "This is free software: you are free to change and redistribute it."
            puts "There is NO WARRANTY, to the extent permitted by law."
            exit
          end

          opts.on( '-h', '--help', 'Display this screen' ) do
            puts opts
            exit
          end
        end

        @optparse.parse!

        raise MissingArgumentException.new("Missing --account-id argument") if @options[:account_id].nil?
        raise MissingArgumentException.new("Missing --username argument") if @options[:username].nil?
        raise MissingArgumentException.new("Missing --password argument") if @options[:password].nil?
        raise MissingArgumentException.new("Missing --output-path argument") if @options[:output_path].nil?

        @downloader = Downloader.new(@options)
      rescue MissingArgumentException => e
        puts e.message
        puts @optparse
        exit (1)
      end
    end

    def execute
      @downloader.execute
    end

  end
end
