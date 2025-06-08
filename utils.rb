# Purge the output directory and create the directory hierarchy where new files will be created
def prepare_folders
  FileUtils.rm_r('output') if Dir.exist?('output')

  FileUtils.mkdir_p('output/audio/bgm')
  FileUtils.mkdir_p('output/audio/se/cries')

  FileUtils.mkdir_p('output/Data/Text/Dialogs')

  FileUtils.mkdir_p('output/graphics/characters')
  FileUtils.mkdir_p('output/graphics/icons')
  FileUtils.mkdir_p('output/graphics/battlers')
  FileUtils.mkdir_p('output/graphics/pokedex/footprints')
  FileUtils.mkdir_p('output/graphics/pokedex/pokeback')
  FileUtils.mkdir_p('output/graphics/pokedex/pokebackshiny')
  FileUtils.mkdir_p('output/graphics/pokedex/pokefront')
  FileUtils.mkdir_p('output/graphics/pokedex/pokefrontshiny')
  FileUtils.mkdir_p('output/graphics/pokedex/pokeicon')

  FileUtils.mkdir_p('output/Data/Studio/abilities')
  FileUtils.mkdir_p('output/Data/Studio/dex')
  FileUtils.mkdir_p('output/Data/Studio/items')
  FileUtils.mkdir_p('output/Data/Studio/moves')
  FileUtils.mkdir_p('output/Data/Studio/pokemon')
  FileUtils.mkdir_p('output/Data/Studio/types')
  FileUtils.mkdir_p('output/Data/Studio/trainers')
  FileUtils.mkdir_p('output/Data/Studio/zones')
  FileUtils.mkdir_p('output/Data/Studio/groups')
end

# Preload text .dat files for translations and create CSV files
def prepare_text_files
  Dir.glob(File.join($essentials_path, 'Data/messages*core.dat')) do |file|
    File.open(file, 'rb') do |f|
      data = Marshal.load(f)
      file_path = file.downcase
      if file_path.include?('messages_core.dat') # English has no language code
        $core_text_files[0] = data
      else
        $core_text_files[1] = data if file_path.include?('_fr')
        $core_text_files[2] = data if file_path.include?('_it')
        $core_text_files[3] = data if file_path.include?('_de') || file_path.include?('_ge')
        $core_text_files[4] = data if file_path.include?('_es')
        $core_text_files[5] = data if file_path.include?('_ko')
        $core_text_files[6] = data if file_path.include?('_ja') || file_path.include?('_jp')
      end
    end
  end

  Dir.glob(File.join($essentials_path, 'Data/messages*game.dat')) do |file|
    File.open(file, 'rb') do |f|
      data = Marshal.load(f)
      file_path = file.downcase
      if file_path.include?('messages_game.dat') # English has no language code
        $game_text_files[0] = data
      else
        $game_text_files[1] = data if file_path.include?('_fr')
        $game_text_files[2] = data if file_path.include?('_it')
        $game_text_files[3] = data if file_path.include?('_de') || file_path.include?('_ge')
        $game_text_files[4] = data if file_path.include?('_es')
        $game_text_files[5] = data if file_path.include?('_ko')
        $game_text_files[6] = data if file_path.include?('_ja') || file_path.include?('_jp')
      end
    end
  end

  $abilities_names = CSV.open('output/Data/Text/Dialogs/100004.csv', 'a')
  $abilities_descriptions = CSV.open('output/Data/Text/Dialogs/100005.csv', 'a')
  $types_names = CSV.open('output/Data/Text/Dialogs/100003.csv', 'a')
  $dexes_names = CSV.open('output/Data/Text/Dialogs/100063.csv', 'a')
  $moves_names = CSV.open('output/Data/Text/Dialogs/100006.csv', 'a')
  $moves_descriptions = CSV.open('output/Data/Text/Dialogs/100007.csv', 'a')
  $items_names = CSV.open('output/Data/Text/Dialogs/100012.csv', 'a')
  $items_plural_names = CSV.open('output/Data/Text/Dialogs/9001.csv', 'a')
  $items_descriptions = CSV.open('output/Data/Text/Dialogs/100013.csv', 'a')
  $pokemon_names = CSV.open('output/Data/Text/Dialogs/100000.csv', 'a')
  $pokemon_categories = CSV.open('output/Data/Text/Dialogs/100001.csv', 'a')
  $pokemon_descriptions = CSV.open('output/Data/Text/Dialogs/100002.csv', 'a')
  $pokemon_form_names = CSV.open('output/Data/Text/Dialogs/100067.csv', 'a')
  $pokemon_form_descriptions = CSV.open('output/Data/Text/Dialogs/100068.csv', 'a')
  $trainers_type_names = CSV.open('output/Data/Text/Dialogs/100029.csv', 'a')
  $trainers_names = CSV.open('output/Data/Text/Dialogs/100062.csv', 'a')
  $trainers_win_texts = CSV.open('output/Data/Text/Dialogs/100047.csv', 'a')
  $trainers_lose_texts = CSV.open('output/Data/Text/Dialogs/100048.csv', 'a')
  $zone_names = CSV.open('output/Data/Text/Dialogs/100010.csv', 'a')
  $zone_description = CSV.open('output/Data/Text/Dialogs/100064.csv', 'a')
  $group_names = CSV.open('output/Data/Text/Dialogs/100061.csv', 'a')
end

# Check if an entity contains a specific flag
# @param entity [Object] the entity to check
# @param flag [String] the flag to look for
# @return [Boolean] whether the flag was found or not
def check_for_flag(entity, flag)
  entity.flags.each do |f|
    next unless f == flag

    return true
  end
  return false
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

CSV_HEADER = %w[en fr it de es ko kana]
# Find all translations of a text and write them in the Studio CSV
# @param text [String] the text to translate
# @param file [String] the file in which the text translations are contained, 'core' or 'game'
# @param section [Int] the section of the file in which the text translations are contained
# @param csv_file [File] the CSV file
def translate_text(text, file_type, section, csv_file, offset: false)
  line = []
  files = file_type == 'core' ? $core_text_files : $game_text_files
  files.each do |data|
    next if data[section].nil?

    line << (data[section][text].nil? ? text : data[section][text])
  end

  if File.zero?(csv_file) || !File.exist?(csv_file)
    csv_file << CSV_HEADER
    csv_file << %w[National National National National National National National] if csv_file == $dexes_names
    csv_file << %w[Egg Œuf Uovo Ei Huevo 알 タマゴ] if csv_file == $pokemon_names
    csv_file << %w[[~0] [~0] [~0] [~0] [~0] [~0] [~0]] if csv_file == $pokemon_form_descriptions
    csv_file << %w[- - - - - - -] if offset
  end
  (7 - line.length).times { line << line[0] }
  csv_file << line
  csv_file.flush
end

# Generate a dummy CSV
# @param text [String] the dummy text
# @param csv_file [File] the CSV file
def generate_dummy_csv(text, csv_file)
  csv_file << CSV_HEADER if File.zero?(csv_file) || !File.exist?(csv_file)
  csv_file << [text, text, text, text, text, text, text]
  csv_file.flush
end
