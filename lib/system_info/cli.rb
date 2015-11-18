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
    desc 'report', 'runs a Travis-style system info scan/report'
    def report
      if ARGV.first =~ /-h|--help|help/
        puts <<-EOF.gsub(/^\s+>/, '')
        >Usage: #{File.basename($PROGRAM_NAME)}
        >
        >Gather and report a bunch of system information specific to the
        >travis build environment.
        >
        >Influential environment variables:
        >
        >  COOKBOOKS_SHA - SHA1 of the travis-cookbooks tree at master, e.g. "a1b2c3d"
        >  FORMATS       - Output format(s), e.g. "human,json" or "human"
        >  HUMAN_OUTPUT  - Output file of the human format (default $stdout)
        >  JSON_OUTPUT   - Output file of the json format (default $stdout, after human)
        >  COMMANDS_FILE - YAML commands file to run (default commands.yml)
        >
        EOF
        exit 0
      end

      ENV['FORMATS'] ||= 'human'

      host_os = case RbConfig::CONFIG['host_os']
                when /^darwin/
                  'osx'
                when /^linux/
                  'linux'
                else
                  fail "Unknown host OS: #{RbConfig::CONFIG['host_os']}"
                end

      @system_info = { system_info: {} }

      @human_stdout = ENV['HUMAN_OUTPUT'] ? File.open(ENV['HUMAN_OUTPUT'], 'w') : $stdout
      @json_stdout = ENV['JSON_OUTPUT'] ? File.open(ENV['JSON_OUTPUT'], 'w') : $stdout

      commands = YAML.load_file(
        ENV['COMMANDS_FILE'] || File.expand_path('../system_info/commands.yml', __FILE__)
      )['commands']

      @cookbooks_sha = (/\A(?<sha>[0-9a-f]{7})\z/.match(cookbooks_sha) || {})[:sha]

      at_exit do
        if ENV['FORMATS'] =~ /\bjson\b/ && !@system_info[:system_info].empty?
          require 'json'
          @json_stdout.puts JSON.pretty_generate(@system_info)
        end
      end

      (Array(commands[host_os]) + [print_cookbooks_sha] + Array(commands['common'])).compact.each do |cmd|
        begin
          if cmd.is_a? Hash
            command = Array(cmd['command'])
            name    = cmd['name']
            pipe    = " | #{cmd['pipe']}" if cmd['pipe']
            pre     = cmd['pre']
            post    = cmd['post']
            port    = cmd['port']
          else
            command = Array(cmd)
          end

          pre && `#{pre}`

          wait_for port if port

          invoke = ['bash', '-l', '-c', command.map(&:shellescape), pipe].compact.flatten.join ' '
          output = `#{invoke} 2>/dev/null`.chomp

          post && `#{post}`

          if output.length > 0
            job = { name: name, command: command, output: output }
            output_human_readable(job) if ENV['FORMATS'] =~ /\bhuman\b/
            output_json(job) if ENV['FORMATS'] =~ /\bjson\b/
          end
        rescue Errno::ENOENT
        rescue => e
          warn e
        end
      end

      0
    end

    default_task :report

    private

    def cookbooks_sha
      ENV['COOKBOOKS_SHA']
    end

    def cookbooks_commit_url_template
      'https://github.com/travis-ci/travis-cookbooks/tree/%s'
    end

    def output_human_readable(job)
      if defined?(Term) && defined?(Term::ANSIColor)
        @human_stdout.print blue, bold, (job[:name] || Array(job[:command]).join(' ')), reset, "\n"
        @human_stdout.print job[:output], "\n"
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
      key = job[:key] || [*info[:name]].first.downcase.gsub(/[^a-zA-z0-9]/, '_').gsub(/_+/, '_').sub(/_*$/, '')
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
        'command' => "echo #{@cookbooks_sha} '#{cookbooks_commit_url_template % @cookbooks_sha}'",
        'name' => 'Cookbooks Version'
      } if @cookbooks_sha
    end
  end
end

SystemInfo::Cli.start(ARGV) if $PROGRAM_NAME == __FILE__