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

class ReportTask < Thor
  namespace :report

  desc "user", "user quota report"
  method_option :inputfile, :required => true, :aliases => "-i", :desc => "File from running parser"
  def user
    @table_headers = ['User','UID','Space','mtime']
    execute!
  end

  desc "group", "group quota report"
  method_option :inputfile, :required => true, :aliases => "-i", :desc => "Files from running parser"
  def group
    @table_headers = ['Group','GID','Space','mtime']
    execute!
  end

  def self.banner(task, namespace = true, subcommand = false)
    "#{basename} #{task.formatted_usage(self, true, subcommand)}"
  end

  private

  def execute!
    entries = []
    rows = []
    total = 0

    if valid_yaml_file?(options.inputfile)
      entries = parse_yaml(options.inputfile)
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

class ParseTask < Thor
  namespace :parse
  
  desc "user", "user quota parser"
  method_option :output, :default => '/tmp/zfs_userspace.yaml', :aliases => "-o", :desc => "Where to output quota report"
  method_option :inputfiles, :required => true, :type => :array, :aliases => "-i", :desc => "Files from running 'zfs userspace'"
  method_option :format, :default => 'yaml', :aliases => "-f", :desc => "Output format"
  def user
    @get_id_method = 'getpwuid'
    execute!
  end

  desc "group", "group quota parser"
  method_option :output, :default => '/tmp/zfs_groupspace.yaml', :aliases => "-o", :desc => "Where to output quota report"
  method_option :inputfiles, :required => true, :type => :array, :aliases => "-i", :desc => "Files from running 'zfs groupspace'"
  method_option :format, :default => 'yaml', :aliases => "-f", :desc => "Output format"
  def group
    @get_id_method = 'getgrgid'
    execute!
  end

  def self.banner(task, namespace = true, subcommand = false)
    "#{basename} #{task.formatted_usage(self, true, subcommand)}"
  end

  private

  def execute!
    inputfiles = process_inputfiles_option
    entries = process_inputfiles(inputfiles)
    sorted_entries = entries.sort_by { |e| e[:id] }.flatten
    save_output(sorted_entries)
  end

  def process_inputfiles_option
    input_files = []

    # Take the --inputfiles argument and determine if a glob was given.
    # If glob is given, expand it and append filenames to input_files array
    options.inputfiles.each do |f|
      glob = Dir[f]

      if glob.first == f
        input_files << f
      else
        input_files.concat(glob)
      end
    end
  
    input_files
  end

  def process_inputfiles(inputfiles)
    entries = []

    inputfiles.each do |file|
      # Get mtime of input file and convert to epoch
      mtime = File.mtime(file).strftime("%s").to_i
      f = File.open(file, "r")
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
            e = {}
            e[:name] = Etc.send(@get_id_method, id).name
            e[:id] = id
            e[:space] = space
            e[:mtime] = mtime
            entries << e
          end
        end
      end
    end

    entries
  end

  def save_output(entries)
    case options.format
    when 'csv'
      CSV.open(options.output, "w") do |csv|
        entries.each do |e|
          csv << [e[:id],e[:name],e[:space],e[:mtime]]
        end
      end
    when 'yaml'
      File.open(options.output, "w") { |f| f.write entries.to_yaml }
    end
  end
end

class QuotaCheckZFS < Thor
  register(ParseTask, 'parse', "parse <command>", "Parse raw quota input files")
  register(ReportTask, 'report', "report <command>", "Print quota reports")
end

QuotaCheckZFS.start
