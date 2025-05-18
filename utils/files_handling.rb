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
# @return the list of existing entities
def read_existing_entities(directory)
  dir_path = File.join($datapacks_path, 'Data/Studio', directory)
  entities = []

  Dir.entries(dir_path).each do |file|
    full_path = File.join(dir_path, file)
    next unless File.file?(full_path)

    entities << JSON.parse(File.read(full_path))
  end
  return entities
end

# Find if an entity already exists in the Gen 9 pack
# @param essentials_entity [String] entity's name in Essentials
# @param existing_entities [String] list of existing entities of the same type
# @return the existing entity if it exists, nil otherwise
def find_existing_entity(essentials_entity, existing_entities)
  existing_entities.each do |a|
    return a if a['dbSymbol'].gsub(/_/, '') == essentials_entity
  end
  return nil
end

# Save the JSON data into a new file
# @param file_name [String] the name of the file to save
# @param data [Hash] the data to save in the file
def save_json(file_name, data)
  json = JSON.pretty_generate(data)
  json.gsub!(/\[\s+\]/, '[]')

  File.write(File.join('output', file_name), json)
end
