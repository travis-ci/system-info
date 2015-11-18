#!/usr/bin/env ruby
require 'rbconfig'
require 'yaml'
require 'stringio'
require 'socket'
require 'shellwords'
require 'timeout'

require 'term/ansicolor'
require 'thor'

include Term::ANSIColor

module SystemInfo
  class Cli < Thor
    desc 'version', 'report version and exit'
    def version
      puts "system-info #{VERSION}"
    end

    option(
      :cookbooks_sha,
      type: :string, aliases: '-S',
      desc: 'SHA1 of the travis-cookbooks tree at master, e.g. "a1b2c3d"',
      default: ENV['COOKBOOKS_SHA']
    )
    option(
      :formats,
      type: :string, aliases: '-F',
      desc: 'Output format(s), e.g. "human,json" or "human"',
      default: (ENV['FORMATS'] || 'human').split(/\s*,\s+/)
    )
    option(
      :human_output,
      type: :string, aliases: '-H',
      desc: 'Output file of the human format (default $stdout)',
      default: ENV['HUMAN_OUTPUT']
    )
    option(
      :json_output,
      type: :string, aliases: '-J',
      desc: 'Output file of the json format (default $stdout, after human)'
    )
    option(
      :commands_file,
      type: :string, aliases: '-f',
      desc: 'YAML commands file to run',
      default: (ENV['COMMANDS_FILE'] || File.expand_path('../commands.yml', __FILE__))
    )
    desc 'report', 'runs a Travis-style system info scan/report'
    long_desc <<-LONGDESC
      Gather and report a bunch of system information specific to the
      travis build environment.
    LONGDESC
    def report
      @system_info = { system_info: {} }

      @human_stdout = options[:human_output] ? File.open(options[:human_output], 'w') : $stdout
      @json_stdout = options[:json_output] ? File.open(options[:json_output], 'w') : $stdout

      @human_stdout.sync = true if @human_stdout.respond_to?(:sync=)
      @json_stdout.sync = true if @json_stdout.respond_to?(:sync=)

      commands = YAML.load_file(options[:commands_file])['commands']

      @cookbooks_sha = (/\A(?<sha>[0-9a-f]{7})\z/.match(options[:cookbooks_sha]) || {})[:sha]

      all_commands = (
        Array(commands[host_os]) + [print_cookbooks_sha] + Array(commands['common'])
      )

      all_commands.compact.each do |cmd|
        begin
          if cmd.is_a?(Hash)
            command = Array(cmd['command'])
            name = cmd['name']
            pipe = " | #{cmd['pipe']}" if cmd['pipe']
            pre = cmd['pre']
            post = cmd['post']
            port = cmd['port']
          else
            command = Array(cmd)
          end

          system(pre, [:out, :err] => '/dev/null') if pre

          wait_for(port) if port

          invoke = [
            'bash', '-l', '-c', command.map(&:shellescape), pipe
          ].compact.flatten.join(' ')

          output = `#{invoke} 2>/dev/null`.chomp

          system(post, [:out, :err] => '/dev/null') if post

          if output.length > 0
            job = { name: name, command: command, output: output }
            output_human_readable(job) if formats.include?('human')
            output_json(job) if formats.include?('json')
          end
        rescue Errno::ENOENT
        rescue => e
          warn e
        end
      end

      if formats.include?('json') && !@system_info[:system_info].empty?
        require 'json'
        @json_stdout.puts JSON.pretty_generate(@system_info)
      end

      0
    end

    default_task :report

    private

    def formats
      @formats ||= Array(
        options[:formats]
      ).map { |s| s.split(/,/) }.reject(&:empty?).flatten.compact
    end

    def host_os
      return @host_os if @host_os

      case RbConfig::CONFIG['host_os']
      when /^darwin/
        @host_os = 'osx'
      when /^linux/
        @host_os = 'linux'
      else
        fail "Unknown host OS: #{RbConfig::CONFIG['host_os']}"
      end
    end

    def cookbooks_sha
      ENV['COOKBOOKS_SHA']
    end

    def cookbooks_commit_url_template
      'https://github.com/travis-ci/travis-cookbooks/tree/%s'
    end

    def output_human_readable(job)
      if defined?(Term) && defined?(Term::ANSIColor)
        @human_stdout.print(
          blue,
          bold,
          (job[:name] || Array(job[:command]).join(' ')),
          reset,
          "\n"
        )
        @human_stdout.print(job[:output], "\n")
        return
      end

      @human_stdout.print (job[:name] || Array(job[:command]).join(' ')), "\n"
      @human_stdout.print job[:output], "\n"
    end

    def output_json(job)
      out = job[:output].split(/\n/).reject(&:empty?)
      out = out.first if out.length == 1
      info = { output: out }
      info[:name] = job[:name] if job[:name]
      info[:name] ||= job[:command]
      key = (
        job[:key] ||
        [*info[:name]].first.downcase.gsub(
          /[^a-zA-z0-9]/, '_'
        ).gsub(
          /_+/, '_'
        ).sub(
          /_*$/, ''
        )
      )
      @system_info[:system_info][key] = info
    end

    def wait_for(port, timer = 60)
      port_open = false
      Timeout.timeout(timer) do
        until port_open
          %w(127.0.0.1 localhost).each do |host|
            next if port_open
            begin
              TCPSocket.new(host, port).close
              sleep 10
              port_open = true
            rescue Errno::ECONNREFUSED, Errno::ENETUNREACH
              sleep 1
            end
          end
        end
      end
    rescue Timeout::Error
      $stderr.puts "Port #{port} still unavailable after #{timer} seconds"
    end

    def print_cookbooks_sha
      {
        'command' => "echo #{@cookbooks_sha} " \
                     "'#{cookbooks_commit_url_template % @cookbooks_sha}'",
        'name' => 'Cookbooks Version'
      } if @cookbooks_sha
    end
  end
end

SystemInfo::Cli.start(ARGV) if $PROGRAM_NAME == __FILE__
