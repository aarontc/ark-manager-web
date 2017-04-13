require_relative '../config/environment'
class ArkMod < Hashie::Dash
  include Hashie::Extensions::MethodAccess
  include Hashie::Extensions::IgnoreUndeclared
  property :id, required: true
  property :version, required: true, default: Base64.encode64('Mod Not Tracked Yet').gsub!(/\n/, '')
  property :name, required: true, default: 'unknown'
  property :created_at, required: true, default: Time.now.utc.strftime('%m-%d-%Y %H:%M:%S')
  property :updated_at, required: true, default: Time.now.utc.strftime('%m-%d-%Y %H:%M:%S')
end
