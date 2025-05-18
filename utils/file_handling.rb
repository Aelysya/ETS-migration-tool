# Create the directory hierarchy where new files are created
def prepare_folders
  FileUtils.rm_r('output') if Dir.exist?('output')

  FileUtils.mkdir('output')

  FileUtils.mkdir('output/audio')

  FileUtils.mkdir('output/graphics')
  FileUtils.mkdir('output/graphics/characters')
  FileUtils.mkdir('output/graphics/icons')

  FileUtils.mkdir('output/graphics/pokedex')
  FileUtils.mkdir('output/graphics/pokedex/footprints')
  FileUtils.mkdir('output/graphics/pokedex/pokeback')
  FileUtils.mkdir('output/graphics/pokedex/pokebackshiny')
  FileUtils.mkdir('output/graphics/pokedex/pokefront')
  FileUtils.mkdir('output/graphics/pokedex/pokefrontshiny')
  FileUtils.mkdir('output/graphics/pokedex/pokeicon')

  FileUtils.mkdir('output/Data')
  FileUtils.mkdir('output/Data/Text')
  FileUtils.mkdir('output/Data/Text/Dialogs')

  FileUtils.mkdir('output/Data/Studio')
  FileUtils.mkdir('output/Data/Studio/abilities')
  FileUtils.mkdir('output/Data/Studio/dex')
  FileUtils.mkdir('output/Data/Studio/items')
  FileUtils.mkdir('output/Data/Studio/moves')
  FileUtils.mkdir('output/Data/Studio/pokemon')
  FileUtils.mkdir('output/Data/Studio/types')
end

# Get the list of existing entities in a specified directory for comparison purposes
# @param directory [String] directory where to list the entities
def read_existing_entities(directory)
  full_path = File.join($datapacks_path, 'Data/Studio', directory)

  entities = []

  Dir.entries(full_path).each do |file|
    next unless File.file?(File.join(full_path, file))

    entities << File.basename(file, '.*')
  end

  return entities
end

# Save the JSON data into a new file
# @param file_name [String] the name of the file to save
# @param data [Hash] the data to save in the file
def save_json(file_name, data)
  json = JSON.pretty_generate(data)
  json.gsub!(/\[\s+\]/, '[]')

  File.write(File.join('output', file_name), json)
end
