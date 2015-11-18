describe 'version command' do
  before do
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  after do
    $stdout = STDOUT
    $stderr = STDERR
  end

  it 'reports name and version' do
    SystemInfo::Cli.start(['version'])
    expect($stdout.string).to match(/^system-info \d/)
  end
end
