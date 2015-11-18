require 'tmpdir'
require 'fileutils'

describe 'report command' do
  after do
    FileUtils.rm_rf(tmpdir)
  end

  let(:tmpdir) { Dir.mktmpdir }

  let(:commands_file) do
    ENV.fetch(
      'COMMANDS_FILE',
      File.expand_path('../../../../lib/system_info/mini_commands.yml', __FILE__)
    )
  end

  let(:human_output) do
    File.join(tmpdir, 'system_info.txt')
  end

  let(:json_output) do
    File.join(tmpdir, 'system_info.json')
  end

  let(:argv) do
    %W(
      report
      --human-output #{human_output}
      --json-output #{json_output}
      --commands-file #{commands_file}
      --cookbooks-sha fffffff
      --formats human,json
    )
  end

  it 'does not explode' do
    expect { SystemInfo::Cli.start(argv) }.not_to raise_error
  end

  it 'reports cookbooks version as text' do
    SystemInfo::Cli.start(argv)
    expect(File.read(human_output)).to match(/Cookbooks Version/)
  end

  it 'reports cookbooks version as json' do
    SystemInfo::Cli.start(argv)
    report = JSON.parse(File.read(json_output))
    expect(report).to include('system_info')
    expect(report['system_info']).to include('cookbooks_version')
    expect(report['system_info']['cookbooks_version']).to include('output')
    expect(report['system_info']['cookbooks_version']['output']).to match(/^fffffff\b/)
  end
end
