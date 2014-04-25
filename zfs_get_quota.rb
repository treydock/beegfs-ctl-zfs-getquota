#!/usr/bin/env ruby

require 'rubygems'
require 'etc'
require 'csv'
require 'json'
require 'yaml'
require 'optparse'
require 'logger'
require 'terminal-table'
require 'filesize'
require 'pp'
require 'thor'

class ZFSQuotaReporter
  def initialize(quotatype, inputfile)
    @quotatype = quotatype
    @inputfile = inputfile
    
    case quotatype
    when 'user'
      @table_headers = ['User','UID','Space','mtime']
    when 'group'
      @table_headers = ['Group','GID','Space','mtime']
    end
  end

  def execute!
    entries = []
    rows = []
    total = 0

    if valid_yaml_file?(@inputfile)
      entries = parse_yaml(@inputfile)
    else
      puts "Must provide valid YAML file"
      exit 1
    end

    entries.sort_by { |h| h[:space] }.each do |e|
      total = total + e[:space]
      a = [e[:name],e[:id],Filesize.from("#{e[:space]} B").pretty,e[:mtime]]
      rows << a
    end

    table = Terminal::Table.new(:headings => @table_headers, :rows => rows)

    table.add_separator
    table.add_row(['Total', '---', Filesize.from("#{total} B").pretty, '---'])

    puts table
  end

  private

  def valid_yaml_file?(file)
    begin
      contents = YAML.load(File.open(file))
      return false unless contents.is_a?(Array)
    rescue Exception => e
      STDERR.puts e.message
      return false
    else
      return true
    end
  end

  def parse_yaml(file)
    contents = YAML.load(File.open(file))
    contents
  end
end

class ZFSQuotaParser
  def initialize(quotatype, inputfile, output, format)
    @quotatype = quotatype
    @inputfile = inputfile
    @output = output
    @format = format
    
    case quotatype
    when 'user'
      @get_id_method = 'getpwuid'
    when 'group'
      @get_id_method = 'getgrgid'
    end
  end

  def execute!
    entries = process_inputfile
    sorted_entries = entries.sort_by { |e| e[:id] }.flatten
    save_output(sorted_entries)
  end

  private

  def process_inputfile
    entries = []

    # Get mtime of input file and convert to epoch
    mtime = File.mtime(@inputfile).strftime("%s").to_i
    f = File.open(@inputfile, "r")
    lines = f.readlines

    lines.each do |line|
      # Match each line that contains UID BYTES
      if line =~ /^([0-9]+)\s+([0-9]+)$/
        id = $1.to_i
        space = $2.to_i

        # Find existing entries else create new entry
        if e = entries.find { |e| e[:id] == id }
          # For existing entries, add the current space used to new value
          # This allows sum of space across multiple input files
          cur = e[:space]
          e[:space] = cur.to_i + space.to_i
        else
          begin
            name = Etc.send(@get_id_method, id).name
          rescue ArgumentError
            next
          end
          e = {}
          e[:name] = name
          e[:id] = id
          e[:space] = space
          e[:mtime] = mtime
          entries << e
        end
      end
    end

    entries
  end

  def save_output(entries)
    case @format
    when 'csv'
      CSV.open(@output, "w") do |csv|
        entries.each do |e|
          csv << [e[:id],e[:name],e[:space],e[:mtime]]
        end
      end
    when 'yaml'
      File.open(@output, "w") { |f| f.write entries.to_yaml }
    end
  end
end

class ZFSGetQuota < Thor
  method_option :quotatype, :default => 'user', :aliases => "-t", :desc => "Type of quota output to parse. Valid options are 'user' and 'group'."
  method_option :output, :default => '/tmp/zfs_userspace.yaml', :aliases => "-o", :desc => "Where to output quota report"
  method_option :inputfile, :required => true, :aliases => "-i", :desc => "File from running 'zfs userspace'"
  method_option :format, :default => 'yaml', :aliases => "-f", :desc => "Output format"
  desc 'parse', "Parse raw quota input files"
  def parse
    validate_quotatype(options.quotatype, 'parse')
    @parser = ZFSQuotaParser.new(options.quotatype, options.inputfile, options.output, options.format)
    @parser.execute!
  end

  method_option :quotatype, :default => 'user', :aliases => "-t", :desc => "Type of quota to report.  Valid options are 'user' and 'group'."
  method_option :inputfile, :required => true, :aliases => "-i", :desc => "File from running parser"
  desc 'report', "Print quota reports"
  def report
    validate_quotatype(options.quotatype, 'report')
    @reporter = ZFSQuotaReporter.new(options.quotatype, options.inputfile)
    @reporter.execute!
  end

  private

  def validate_quotatype(quotatype, command_name)
    if quotatype !~ /^(user|group)$/
      puts "Invalid quotatype: #{quotatype}"
      help(command_name)
      exit 1
    end
  end
end

ZFSGetQuota.start
