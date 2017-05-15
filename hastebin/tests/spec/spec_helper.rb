require 'serverspec'
require 'yarjuf'

set :backend, :exec

RSpec.configure do |c|

    c.formatter = 'JUnit'

end
