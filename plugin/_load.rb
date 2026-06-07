plugin_path = File.dirname(__FILE__)

[
  File.join(plugin_path, 'public'),
  File.join(plugin_path, 'helpers'),
  File.join(plugin_path, 'commands'),
  File.join(plugin_path, 'templates'),
  File.join(plugin_path, 'web')
].each do |dir|
  next unless Dir.exist?(dir)
  Dir[File.join(dir, '**', '*.rb')].sort.each { |f| load f }
end
