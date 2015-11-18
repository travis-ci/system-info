require 'socket'
require 'timeout'

module SystemInfo
  class Job
    attr_reader :cmd, :i, :output

    def initialize(cmd, i)
      @cmd = cmd
      @i = i
      @output = ''
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
  end
end
