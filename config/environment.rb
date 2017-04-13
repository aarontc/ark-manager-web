require 'oj'
require 'json'
require 'mkmf'
require 'hashie'
require 'dalli'
require 'logger'
require 'base64'
require 'rufus-scheduler'
require_relative '../lib/repository'
require_relative '../lib/mod_repository'

if File.exists?("#{WORKING_DIR}/config/env_config.json")
  @env_config = Oj.load_file("#{WORKING_DIR}/config/env_config.json", Hash.new)
  @env_config.each_pair { |key,value|  ENV[key] = value  }
else
  env_hash = {
      RACK_ENV: 'production',
      LISTENING_IP: '0.0.0.0',
      LISTENING_PORT: '8080',
      MEMCACHED_IP: '127.0.0.1',
      MEMCACHED_PORT: '11211',
      DOMAIN_NAME: 'localhost'
  }
  @env_config = Hashie::Mash.parse(env_hash)
end

WORKING_DIR       = File.dirname(File.expand_path('..', __FILE__)) unless defined?(WORKING_DIR)
EGREP_EXEC        = find_executable 'egrep'
CURL_EXEC         = find_executable 'curl'
USER_HOME         = Dir.home unless defined?(USER_HOME)
RACK_ENV          = ENV.fetch('RACK_ENV', 'development')
ARK_MANAGER_CLI   = find_executable('arkmanager', "#{USER_HOME}/bin") unless defined?(ARK_MANAGER_CLI)
SERVER_IP         = ENV.fetch('LISTENING_IP', '0.0.0.0')
SERVER_PORT       = ENV.fetch('LISTENING_PORT', '8080')
MEMCACHED_IP      = ENV.fetch('MEMCACHED_IP', '127.0.0.1')
MEMCACHED_PORT    = ENV.fetch('MEMCACHED_PORT', '11211')
DOMAIN_NAME       = ENV.fetch('DOMAIN_NAME', 'localhost')
UNICORN_STDOUT    = ENV.fetch('UNICORN_STDOUT')
UNICORN_STDERR    = ENV.fetch('UNICORN_STDERR')

unless File.exists?("#{WORKING_DIR}/config/env_config.json")
  File.open("#{WORKING_DIR}/config/env_config.json", 'w') do |f|
    f.write()
  end
end


$logger = Logger.new(STDOUT)
$logger.datetime_format = '%m-%d-%Y %H:%M:%S'
$logger.progname = 'web interface'
if RACK_ENV == 'production'
  $logger.level = Logger::WARN
else
  $logger.level = Logger::DEBUG
end

$scheduler = Rufus::Scheduler.new unless defined?($scheduler)
$dalli_cache = Dalli::Client.new('localhost:11211', { namespace: 'boop_on_your_nose', compress: true }) unless defined?($dalli_cache)
$dalli_cache.flush_all


$dalli_cache.set('arkmanager_updates_running', false)

if File.exists?("#{WORKING_DIR}/config/schedules.json")
  Oj.load_file("#{WORKING_DIR}/config/schedules.json", Hash.new).each_pair do |key, value|
    $dalli_cache.set(key, value)
  end
else
  $dalli_cache.set('run_automatic_start', true)
  $dalli_cache.set('mod_update_check_schedule', true)
  $dalli_cache.set('server_update_check_schedule', true)
  File.write("#{WORKING_DIR}/config/schedules.json", "{\n\t\"run_automatic_start\": true,\n\t\"mod_update_check_schedule\": true,\n\t\"server_update_check_schedule\": true\n}")
end

unless File.exist?("#{WORKING_DIR}/config/mod_list.json")
  File.write("#{WORKING_DIR}/config/mod_list.json", "{\n}")
end