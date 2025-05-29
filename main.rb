require 'json'
require 'csv'
require 'fileutils'
require_relative 'utils'

$settings = JSON.parse(File.read('settings.local.json'))
$essentials_path = $settings['essentials_path']
$essentials_script_path = File.join($essentials_path, 'Data/Scripts')
$datapacks_path = File.join($settings['datapacks_path'], 'Gen 9/scarlet-violet')

require File.join($essentials_script_path, '010_Data/001_GameData')
require File.join($essentials_script_path, '001_Technical/003_Intl_Messages')

dir = File.expand_path(File.join($essentials_script_path, '010_Data/001_Hardcoded data'), __dir__)
Dir.glob("#{dir}/*.rb").sort.each do |file|
  require file
end

dir = File.expand_path(File.join($essentials_script_path, '010_Data/002_PBS data'), __dir__)
Dir.glob("#{dir}/*.rb").sort.each do |file|
  require file
end

Dir.glob('migrations/*.rb').sort.each do |file|
  require_relative file
end

# Prepare existing entities lists to avoid doing it multiple times
$existing_items = read_existing_entities('items')
$existing_moves = read_existing_entities('moves')
$existing_species = read_existing_entities('pokemon')
$existing_types = read_existing_entities('types')
$existing_abilities = read_existing_entities('abilities')
$existing_dexes = read_existing_entities('dex')

start_time = Time.now

prepare_folders
puts 'Migrating Abilities...'
migrate_abilities
# puts 'Migrating Types...'
# migrate_types
# puts 'Migrating Moves...'
# migrate_moves
# puts 'Migrating Pokédexes...'
# migrate_dexes
# puts 'Migrating Items...'
# migrate_items
# puts 'Migrating Pokémon...'
# migrate_pokemon
# puts 'Migrating Trainers...'
# migrate_trainers
# puts 'Migrating Zones...'
# migrate_zones
# puts 'Migrating Groups...'
# migrate_groups

end_time = Time.now
puts "Duration of generation : #{end_time - start_time} seconds"
