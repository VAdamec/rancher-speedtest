require 'spec_helper'

describe file('/usr/local/bin/nodejs') do
  it { should be_symlink }
end

describe file('/usr/local/bin/node') do
  it { should be_mode 775 }
end

describe file('/opt/hastebin/config.js') do
  it { should exist }
end

describe host('redis') do
  it { should be_reachable.with( :port => 6379, :proto => 'tcp', :timeout => 1 ) }
end

describe command('(printf "PING\r\n"; sleep 1) | nc redis 6379 -qc') do
  its(:stdout) { should match 'PONG' }
end

describe port(8080) do
  it { should be_listening }
end

describe command('curl -sL -w "%{http_code}\\n" "localhost:8080/about.md" -o /dev/null | sed "s/200/OK/"') do
  its(:stdout) { should match 'OK' }
end

describe command('echo TOTOJETEST | /usr/local/bin/haste | cut -f 4 -d "/" | xargs -i curl -v http://127.0.0.1:8080/raw/{}') do
  its(:stdout) { should match 'TOTOJETEST' }
end
