require 'rack'
require 'securerandom'
require 'dalli'
require 'rack/session/dalli'
require 'rufus-scheduler'
require 'oj'

# Load ENV configuration
require_relative 'config/environment'

# Load predefined schedules
require_relative 'lib/predefined_schedules'

# Load web interfaces
require_relative 'api/api_app'
require_relative 'web/web_app'

configure do
  $dalli_cache.set('mod_list', Array.new) if $dalli_cache.get('mod_list').nil?
  Repository.register(:mod_list, DalliAdapter::ModRepository.new)
end

use Rack::Session::Dalli,  cache: Dalli::Client.new
use Rack::Session::Pool,   expire_after: 2592000
use Rack::Session::Cookie, key: "#{DOMAIN_NAME}.session",
                           domain: DOMAIN_NAME,
                           path: '/',
                           expire_after: 2592000,
                           secret: SecureRandom.hex(64)

use Rack::Protection
use Rack::Protection::RemoteToken
use Rack::Protection::SessionHijacking





if find_executable('memcached') or ARK_MANAGER_CLI
  raise 'I was unable to find arkmanager in your path!! please run "bundle exec rake install_server_tools"' unless ARK_MANAGER_CLI
  raise 'I was unable to find memcached!!! please have your system administrator install memcached' unless find_executable('memcached')
else
  run Rack::Cascade.new [
                            ApiApp,
                            WebApp
                        ]
end

