require 'json'
require 'fileutils'

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

Dir.glob('utils/*.rb').sort.each do |file|
  require_relative file
end

Dir.glob('migrations/*.rb').sort.each do |file|
  require_relative file
end

prepare_folders
# migrate_abilities
# migrate_types
# migrate_moves
migrate_dexes
