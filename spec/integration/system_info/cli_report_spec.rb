require 'tmpdir'
require 'fileutils'

describe 'report command', integration: true do
  def tmpdir
    @tmpdir ||= Dir.mktmpdir
  end

  def commands_file
    ENV.fetch(
      'COMMANDS_FILE',
      File.expand_path(
        '../../../../lib/system_info/config/mini_commands.yml',
        __FILE__
      )
    )
  end

  def human_output
    File.join(tmpdir, 'system_info.txt')
  end

  def json_output
    File.join(tmpdir, 'system_info.json')
  end

  def argv
    %W(
      report
      --human-output #{human_output}
      --json-output #{json_output}
      --commands-file #{commands_file}
      --cookbooks-sha fffffff
      --formats human,json
    )
  end

  before :all do
    SystemInfo::Cli.start(argv)
  end

  after :all do
    FileUtils.rm_rf(tmpdir)
  end

  it 'reports cookbooks version as text' do
    expect(File.read(human_output)).to match(/Cookbooks Version/)
  end

  it 'reports cookbooks version as json' do
    report = JSON.parse(File.read(json_output))
    expect(report).to include('system_info')
    expect(report['system_info']).to include('cookbooks_version')
    expect(report['system_info']['cookbooks_version']).to include('output')
    expect(report['system_info']['cookbooks_version']['output']).to match(/^fffffff\b/)
  end
end
