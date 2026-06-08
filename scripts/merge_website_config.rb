#!/usr/bin/env ruby
require 'yaml'

path = ARGV[0]
example_path = ARGV[1]

abort "Usage: merge_website_config.rb WEBSITE_YML EXAMPLE_YML" if path.nil? || example_path.nil?
abort "Missing #{path}" unless File.exist?(path)
abort "Missing #{example_path}" unless File.exist?(example_path)

data = YAML.load_file(path) || {}
example = YAML.load_file(example_path) || {}

website = data['website'] ||= {}
navbar = website['top_navbar'] ||= []

def menu_has_route?(menu, route)
  return false if menu.nil?

  menu.any? { |item| item['route'] == route }
end

def append_menu_items(menu, items)
  menu ||= []
  items.each do |item|
    next if menu_has_route?(menu, item['route'])

    menu << item
  end
  menu
end

example.dig('website', 'top_navbar')&.each do |entry|
  title = entry['title']
  items = entry['menu'] || []
  existing = navbar.find { |e| e['title'] == title }
  if existing
    existing['menu'] = append_menu_items(existing['menu'], items)
  else
    navbar << { 'title' => title, 'menu' => items.dup }
  end
end

if website['character_gallery_group'].to_s.empty?
  website['character_gallery_group'] = example.dig('website', 'character_gallery_group') || 'Kingdom'
  puts 'Set character_gallery_group to Kingdom (was blank).'
end
if website['character_gallery_subgroup'].to_s.empty?
  website['character_gallery_subgroup'] = example.dig('website', 'character_gallery_subgroup') || 'Region'
  puts 'Set character_gallery_subgroup to Region (was blank).'
end

website['top_navbar'] = navbar
data['website'] = website
File.write(path, data.to_yaml)
puts 'Merged OSR nav entries into website.yml'
