# frozen_string_literal: true
require 'socket'
require 'timeout'

module SystemInfo
  class Job
    attr_reader :cmd, :i, :output, :job_port_timeout_max

    def initialize(cmd, i, job_port_timeout_max = 60)
      @cmd = cmd
      @i = i
      @output = ''
      @job_port_timeout_max = job_port_timeout_max
    end

    def run
      system(pre, [:out, :err] => '/dev/null') if pre

      wait_for(port) if port

      invoke = [
        'bash', '-l', '-c', command.map(&:shellescape), '2>/dev/null',
        pipe
      ].compact.flatten.join(' ')

      @output = `#{invoke} 2>/dev/null`.chomp

      system(post, [:out, :err] => '/dev/null') if post
    rescue Errno::ENOENT => e
      warn e
    end

    def command
      return Array(cmd.fetch('command')) if cmd_hashy?
      Array(cmd)
    end

    def pipe
      return " | #{cmd['pipe']}" if cmd_hashy? && cmd['pipe']
      nil
    end

    %w(name pre post port).each do |key|
      define_method(key) do
        return cmd[key] if cmd_hashy?
        nil
      end
    end

    private

    def cmd_hashy?
      cmd.respond_to?(:key?)
    end

    def wait_for(port)
      port_open = false

      Timeout.timeout(job_port_timeout_max) do
        until port_open
          %w(127.0.0.1 localhost).each do |host|
            next if port_open
            begin
              TCPSocket.new(host, port).close
              sleep 10
              port_open = true
            rescue Errno::ECONNREFUSED, Errno::ENETUNREACH, Errno::EINVAL
              sleep 1
            end
          end
        end
      end
    rescue Timeout::Error
      warn "Port #{port} unavailable after #{job_port_timeout_max} seconds"
    end
  end
end
