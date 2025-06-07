# Text IDs counters
$name_counter = 0
$description_counter = 1

# Migrate Essentials Pokemon into Studio format
def migrate_pokemon
  File.open(File.join($essentials_path, 'Data/species.dat'), 'rb') do |f|
    data = Marshal.load(f)

    processed_species = []
    i = 1
    data.each_value do |pokemon|
      pokemon_name = pokemon.species.downcase.to_s
      pokemon_name.chop! if %w[nidoranfe nidoranma].include?(pokemon_name) # Nidoran species are named differently in Essentials
      next if processed_species.include?(pokemon_name) # Skip already processed alt forms

      processed_species << pokemon_name

      existing_pokemon = find_existing_entity(pokemon_name, $existing_species)
      db_symbol = existing_pokemon.nil? ? pokemon_name : existing_pokemon['dbSymbol']

      json = {
        klass: 'Specie',
        id: i,
        dbSymbol: db_symbol,
        forms: build_forms(pokemon, i, data)
      }

      i += 1
      save_json("Data/Studio/pokemon/#{db_symbol}.json", json)
    end
  end
  $pokemon_names.close
  $pokemon_categories.close
  $pokemon_descriptions.close
  $pokemon_form_names.close
  $pokemon_form_descriptions.close
end

# Build the forms of a Pokémon
# @param pokemon [Object] the Pokémon from Essentials
# @param number [Integer] the number of the Pokémon in the Pokédex
# @param data [Hash] the data loaded from the species.dat file
# @return [Array] the forms of the Pokémon
def build_forms(pokemon, number, data)
  forms = []

  mega_form_counter = 30
  form_counter = 0
  i = 0
  data.each_value do |p|
    next unless p.species == pokemon.species
    next if p.species.downcase.to_s == 'alcremie' && p.form != 0

    form_number = p.mega_stone.nil? && p.mega_move.nil? ? form_counter : mega_form_counter
    if form_number >= 30 && !p.mega_stone.nil?
      item_name = p.mega_stone.downcase.to_s
      existing_item = find_existing_entity(item_name, $existing_items)
      stone_db_symbol = existing_item.nil? ? item_name : existing_item['dbSymbol']

      forms[p.unmega_form][:evolutions] << { form: mega_form_counter, conditions: [{ type: 'gemme', value: stone_db_symbol }] }
      mega_form_counter += 1
    end

    has_female = copy_pokemon_resources(p, form_number, number)

    first_egg_group = parse_egg_group(p.egg_groups[0])
    second_egg_group = p.egg_groups[1].nil? ? first_egg_group : parse_egg_group(p.egg_groups[1])

    baby_db_symbol = find_baby(p, data)
    baby_name_with_form = "#{baby_db_symbol.upcase.gsub(/_/, '')}_#{form_counter}"

    evolution_element = build_evolutions(p)

    forms << {
      form: form_number,
      height: p.height / 10.0,
      weight: p.weight / 10.0,
      type1: p.types[0].downcase.to_s,
      type2: p.types[1].nil? ? '__undef__' : p.types[1].downcase.to_s,
      baseHp: p.base_stats[:HP],
      baseAtk: p.base_stats[:ATTACK],
      baseDfe: p.base_stats[:DEFENSE],
      baseSpd: p.base_stats[:SPEED],
      baseAts: p.base_stats[:SPECIAL_ATTACK],
      baseDfs: p.base_stats[:SPECIAL_DEFENSE],
      evHp: p.evs[:HP],
      evAtk: p.evs[:ATTACK],
      evDfe: p.evs[:DEFENSE],
      evSpd: p.evs[:SPEED],
      evAts: p.evs[:SPECIAL_ATTACK],
      evDfs: p.evs[:SPECIAL_DEFENSE],
      evolutions: evolution_element,
      experienceType: parse_experience_type(p.growth_rate),
      baseExperience: p.base_exp,
      baseLoyalty: p.happiness,
      catchRate: p.catch_rate,
      femaleRate: parse_female_rate(p.gender_ratio),
      breedGroups: [
        first_egg_group,
        second_egg_group
      ],
      hatchSteps: p.hatch_steps,
      babyDbSymbol: baby_db_symbol,
      babyForm: data[baby_name_with_form.to_sym].nil? ? 0 : form_counter,
      itemHeld: parse_items(p),
      abilities: parse_abilities(p),
      frontOffsetY: 0,
      resources: build_resources_element(number, form_number, has_female || p.gender_ratio == :AlwaysFemale, p.id),
      moveSet: build_moveset_element(p),
      formTextId: {
        name: $name_counter,
        description: form_number == 0 ? 0 : $description_counter
      }
    }
    form_counter += 1
    $name_counter += 1
    $description_counter += 1 unless form_number == 0
    if form_number == 0
      translate_text(p.real_name, 'core', 1, $pokemon_names)
      translate_text(p.real_category, 'core', 2, $pokemon_categories, offset: true)
      translate_text(p.real_pokedex_entry, 'core', 3, $pokemon_descriptions, offset: true)
      translate_text(p.real_name, 'core', 4, $pokemon_form_names)
    else
      translate_text(p.real_form_name, 'core', 4, $pokemon_form_names)
      translate_text(p.real_pokedex_entry, 'core', 3, $pokemon_form_descriptions)
    end
  rescue => e
    $errors << "Error #{e} on #{p.species}"
  ensure
    i += 1
  end
  return forms
end

# Parse the experience type of a Pokémon
# @param growth_rate [Symbol] the growth rate of the Pokémon
# @return [Integer] the experience type of the Pokémon
def parse_experience_type(growth_rate)
  case growth_rate
  when :Medium
    return 1
  when :Slow
    return 2
  when :Parabolic
    return 3
  when :Erratic
    return 4
  when :Fluctuating
    return 5
  else # Fast
    return 0
  end
end

# Parse the female rate of a Pokémon
# @param female_rate [Symbol] the female rate of the Pokémon
# @return [Integer] the parsed female rate
def parse_female_rate(female_rate)
  case female_rate
  when :AlwaysMale
    return 0
  when :FemaleOneEighth
    return 12.5
  when :Female25Percent
    return 25
  when :Female50Percent
    return 50
  when :Female75Percent
    return 75
  when :FemaleSevenEighths
    return 87.5
  when :AlwaysFemale
    return 100
  else # Genderless
    return -1
  end
end

# Parse the egg group of a Pokémon
# @param egg_group [Symbol] the egg group of the Pokémon
# @return [Int] the parsed egg group
def parse_egg_group(egg_group)
  case egg_group
  when :Monster
    return 1
  when :Water1
    return 2
  when :Bug
    return 3
  when :Flying
    return 4
  when :Field
    return 5
  when :Fairy
    return 6
  when :Grass
    return 7
  when :HumanLike
    return 8
  when :Water3
    return 9
  when :Mineral
    return 10
  when :Amorphous
    return 11
  when :Water2
    return 12
  when :Ditto
    return 13
  when :Dragon
    return 14
  else # Undiscovered
    return 15
  end
end

def build_resources_element(number, form_number, has_female, pokemon_id)
  main_part = number.to_s.rjust(4, '0')
  form_part = form_number == 0 ? '' : "_#{form_number.to_s.rjust(2, '0')}"

  basic_resource = "#{main_part}#{form_part}"
  female_resource = "#{main_part}f#{form_part}"
  shiny_resource = "#{main_part}s#{form_part}"
  shiny_f_resource = "#{main_part}sf#{form_part}"

  cry_resource = File.exist?(File.join($essentials_path, "Audio/SE/Cries/#{pokemon_id}.ogg")) ? "#{basic_resource}.ogg" : "#{main_part}.ogg"

  resources = {}
  resources[:icon] = basic_resource
  resources[:iconF] = basic_resource if has_female
  resources[:iconShiny] = shiny_resource
  resources[:iconShinyF] = shiny_resource if has_female
  resources[:front] = basic_resource
  resources[:frontF] = female_resource if has_female
  resources[:frontShiny] = shiny_resource
  resources[:frontShinyF] = shiny_f_resource if has_female
  resources[:back] = basic_resource
  resources[:backF] = female_resource if has_female
  resources[:backShiny] = shiny_resource
  resources[:backShinyF] = shiny_f_resource if has_female
  resources[:footprint] = basic_resource
  resources[:character] = basic_resource
  resources[:characterF] = female_resource if has_female
  resources[:characterShiny] = shiny_resource
  resources[:characterShinyF] = shiny_f_resource if has_female
  resources[:cry] = cry_resource
  resources[:hasFemale] = has_female
  resources[:egg] = 'egg'
  resources[:iconEgg] = 'egg'

  return resources
end

# Determine the abilities of a Pokémon
# @param pokemon [Object] the Pokémon from Essentials
# @return [Array] the abilities of the Pokémon
def parse_abilities(pokemon)
  abilities = []

  first_ability_name = pokemon.abilities[0].downcase.to_s
  first_ability = find_existing_entity(first_ability_name, $existing_abilities)
  first_ability_symbol = first_ability.nil? ? first_ability_name : first_ability['dbSymbol']

  abilities << first_ability_symbol

  if pokemon.abilities[1].nil?
    abilities << first_ability_symbol
  else
    second_ability_name = pokemon.abilities[1].downcase.to_s
    second_ability = find_existing_entity(second_ability_name, $existing_abilities)
    abilities << (second_ability.nil? ? second_ability_name : second_ability['dbSymbol'])
  end

  if pokemon.hidden_abilities[0].nil?
    abilities << first_ability_symbol
  else
    hidden_ability_name = pokemon.hidden_abilities[0].downcase.to_s
    hidden_ability = find_existing_entity(hidden_ability_name, $existing_abilities)
    abilities << (hidden_ability.nil? ? hidden_ability_name : hidden_ability['dbSymbol'])
  end

  return abilities
end

# Determine the items held by a Pokémon
# @param pokemon [Object] the Pokémon from Essentials
# @return [Array] the items held by the Pokémon
def parse_items(pokemon)
  items = []
  nil_item_position = -1

  if pokemon.wild_item_common[0].nil?
    items << {
      dbSymbol: 'none',
      chance: 0
    }
    nil_item_position = 0
  else
    common_name = pokemon.wild_item_common[0].downcase.to_s
    existing_common_item = find_existing_entity(common_name, $existing_items)
    items << {
      dbSymbol: existing_common_item.nil? ? common_name : existing_common_item['dbSymbol'],
      chance: 50
    }
  end

  if pokemon.wild_item_uncommon[0].nil?
    items << {
      dbSymbol: 'none',
      chance: 0
    }
    nil_item_position = 1
  else
    uncommon_name = pokemon.wild_item_uncommon[0].downcase.to_s
    existing_uncommon_item = find_existing_entity(uncommon_name, $existing_items)
    items << {
      dbSymbol: existing_uncommon_item.nil? ? uncommon_name : existing_uncommon_item['dbSymbol'],
      chance: 5
    }
  end

  # If there are already two defined items, the rare item is ignored as Studio only allows editing two item slots
  unless pokemon.wild_item_rare[0].nil? || nil_item_position == -1
    rare_name = pokemon.wild_item_rare[0].downcase.to_s
    existing_rare_item = find_existing_entity(rare_name, $existing_items)
    items[nil_item_position] = {
      dbSymbol: existing_rare_item.nil? ? rare_name : existing_rare_item['dbSymbol'],
      chance: 1
    }
    puts "found rare item #{rare_name} for #{pokemon.species}"
  end
  return items
end

# Build the moveSet element of a Pokémon
# @param pokemon [Object] the Pokémon from Essentials
# @return [Array] the moveSet element of the Pokémon
def build_moveset_element(pokemon)
  move_set = []

  pokemon.moves.each do |move|
    move_name = move[1].downcase.to_s
    existing_move = find_existing_entity(move_name, $existing_moves)
    move_set << {
      move: existing_move.nil? ? move_name : existing_move['dbSymbol'],
      klass: 'LevelLearnableMove',
      level: move[0].clamp(1, 999)
    }

    next unless move[0] == 0

    move_set << {
      move: existing_move.nil? ? move_name : existing_move['dbSymbol'],
      klass: 'EvolutionLearnableMove'
    }
  end

  pokemon.tutor_moves.each do |move|
    move_name = move.downcase.to_s
    existing_move = find_existing_entity(move_name, $existing_moves)
    move_set << {
      move: existing_move.nil? ? move_name : existing_move['dbSymbol'],
      klass: 'TechLearnableMove'
    }
    move_set << {
      move: existing_move.nil? ? move_name : existing_move['dbSymbol'],
      klass: 'TutorLearnableMove'
    }
  end

  pokemon.egg_moves.each do |move|
    move_name = move.downcase.to_s
    existing_move = find_existing_entity(move_name, $existing_moves)
    move_set << {
      move: existing_move.nil? ? move_name : existing_move['dbSymbol'],
      klass: 'BreedLearnableMove'
    }
  end

  return move_set
end

# Find the baby of a Pokémon
# @param pokemon [Object] the Pokémon from Essentials
# @param data [Hash] the data loaded from the species.dat file
# @return [String] the baby Pokémon's dbSymbol
# @note This method recursively check for evolution with a fourth value at true, which indicates a prevolution
def find_baby(pokemon, data)
  pokemon_name = pokemon.species.downcase.to_s
  pokemon_name.chop! if %w[nidoranfe nidoranma].include?(pokemon_name) # Nidoran species are named differently in Essentials
  existing_pokemon = find_existing_entity(pokemon_name, $existing_species)
  db_symbol = existing_pokemon.nil? ? pokemon_name : existing_pokemon['dbSymbol']

  return db_symbol if %i[Undiscovered Ditto].include?(pokemon.egg_groups[0])
  return db_symbol if pokemon.evolutions.empty?
  return db_symbol if pokemon.evolutions.none? { |evolution| evolution[3] }

  prevolution = nil
  pokemon.evolutions.each do |evolution|
    next unless evolution[3]

    prevolution = find_baby(data[evolution[0]], data)
    prevolution = db_symbol unless data[evolution[0]].incense.nil?
  end

  return prevolution
end

# Build the evolutions of a Pokémon
# @param pokemon [Object] the Pokémon from Essentials
# @return [Array] the evolutions of the Pokémon
def build_evolutions(pokemon)
  pokemon_name = pokemon.species.downcase.to_s
  pokemon_name.chop! if %w[nidoranfe nidoranma].include?(pokemon_name) # Nidoran species are named differently in Essentials
  existing_pokemon = find_existing_entity(pokemon_name, $existing_species)
  db_symbol = existing_pokemon.nil? ? pokemon_name : existing_pokemon['dbSymbol']

  # These Pokémon have a function in one of their evolutions conditions, so we fetch their evolutions from the datapack
  if %w[basculin bisharp bramblin dunsparce eevee farfetch_d gimmighoul inkay mantyke milcery
        pancham pawmo primeape rellor tandemaus toxel tyrogue ursaring wurmple qwilfish primeape stantler].include?(db_symbol) &&
     !existing_pokemon['forms'][pokemon.form].nil?
    return existing_pokemon['forms'][pokemon.form]['evolutions']
  end

  evolutions_element = []
  pokemon.evolutions.each do |evolution|
    next if evolution[3] # Ignore prevolutions

    evolution_name = evolution[0].downcase.to_s
    existing_pokemon = find_existing_entity(evolution_name, $existing_species)
    evolution_db_symbol = existing_pokemon.nil? ? evolution_name : existing_pokemon['dbSymbol']

    evolutions_element << {
      dbSymbol: evolution_db_symbol,
      form: pokemon.form,
      conditions: parse_evolution_conditions(evolution[1], evolution[2]) || []
    }
  end
  return evolutions_element
end

# Parse the evolution conditions of a Pokémon
# @param method [Symbol] the method of evolution in Essentials
# @param parameter [Object] the parameter of the evolution method
# @return [Array] the parsed evolution conditions
def parse_evolution_conditions(method, parameter)
  conditions = []
  method_s = method.downcase.to_s

  conditions << { type: 'minLevel', value: parameter.to_i } if method_s.include?('level') && !method_s.include?('usemove')
  conditions << { type: 'minLoyalty', value: 220 } if method_s.include?('happiness')
  conditions << { type: 'trade', value: true } if method_s.include?('trade')
  conditions << { type: 'maps', value: [-1] } if method_s.include?('location') || method_s.include?('region')
  conditions << { type: 'gender', value: method_s.include?('male') ? 1 : 2 } if method_s.include?('male') || method_s.include?('female')

  if method_s.include?('item')
    item_name = parameter.downcase.to_s
    existing_item = find_existing_entity(item_name, $existing_items)
    db_symbol = existing_item.nil? ? item_name : existing_item['dbSymbol']

    conditions << { type: method_s.include?('holditem') || method_s.include?('trade') ? 'itemHold' : 'stone', value: db_symbol }
  end

  if method_s.include?('hasmove')
    move_name = parameter.downcase.to_s
    existing_move = find_existing_entity(move_name, $existing_moves)
    db_symbol = existing_move.nil? ? move_name : existing_move['dbSymbol']

    conditions << { type: 'skill1', value: db_symbol }
  end

  if %w[day night evening morning afternoon].any? { |time| method_s.include?(time) }
    time_of_day =
      case method_s
      when /night/
        0
      when /evening/
        1
      when /morning/
        2
      else # day, afternoon
        3
      end

    conditions << { type: 'dayNight', value: time_of_day }
  end

  if %w[sun rain snow sandstorm fog].any? { |time| method_s.include?(time) }
    weather =
      case method_s
      when /rain/
        'rain'
      when /sun/
        'sunny'
      when /snow/
        'hail'
      when /fog/
        'fog'
      else
        'sandstorm'
      end

    conditions << { type: 'weather', value: weather }
  end

  return conditions
end

# Copy the Essentials resources of this Pokémon
# @param pokemon [Object] the Pokémon from Essentiasl containing information to find the related graphics
# @param form [Int] the form of the Pokémon
# @param number [Int] the national number of the Pokémon
# @return [Boolean] if the Pokémon has female sprites
def copy_pokemon_resources(pokemon, form, number)
  has_female = false
  source_file_name = pokemon.id.to_s

  main_part = number.to_s.rjust(4, '0')
  form_part = form == 0 ? '' : "_#{form.to_s.rjust(2, '0')}"
  basic_resource = "#{main_part}#{form_part}"
  female_resource = "#{main_part}f#{form_part}"
  shiny_resource = "#{main_part}s#{form_part}"
  shiny_f_resource = "#{main_part}sf#{form_part}"

  graphics_source = File.join($essentials_path, 'Graphics/Pokemon')
  Dir.glob(File.join(graphics_source, "Back/#{source_file_name}{,_female}.png")) do |file|
    ext = File.extname(file).downcase
    has_female = true if file.downcase.include?('_female')
    dest = File.join('output/graphics/pokedex/pokeback', "#{file.downcase.include?('_female') ? female_resource : basic_resource}#{ext}")
    FileUtils.cp(file, dest)
  end

  Dir.glob(File.join(graphics_source, "Back shiny/#{source_file_name}{,_female}.png")) do |file|
    ext = File.extname(file).downcase
    has_female = true if file.downcase.include?('_female')
    dest = File.join('output/graphics/pokedex/pokebackshiny', "#{file.downcase.include?('_female') ? shiny_f_resource : shiny_resource}#{ext}")
    FileUtils.cp(file, dest)
  end

  Dir.glob(File.join(graphics_source, "Front/#{source_file_name}{,_female}.png")) do |file|
    ext = File.extname(file).downcase
    has_female = true if file.downcase.include?('_female')
    dest = File.join('output/graphics/pokedex/pokefront', "#{file.downcase.include?('_female') ? female_resource : basic_resource}#{ext}")
    FileUtils.cp(file, dest)
  end

  Dir.glob(File.join(graphics_source, "Front shiny/#{source_file_name}{,_female}.png")) do |file|
    ext = File.extname(file).downcase
    has_female = true if file.downcase.include?('_female')
    dest = File.join('output/graphics/pokedex/pokefrontshiny', "#{file.downcase.include?('_female') ? shiny_f_resource : shiny_resource}#{ext}")
    FileUtils.cp(file, dest)
  end

  Dir.glob(File.join(graphics_source, "Icons/#{source_file_name}{,_female}.png")) do |file|
    ext = File.extname(file).downcase
    has_female = true if file.downcase.include?('_female')
    dest = File.join('output/graphics/pokedex/pokeicon', "#{file.downcase.include?('_female') ? female_resource : basic_resource}#{ext}")
    FileUtils.cp(file, dest)
  end

  Dir.glob(File.join(graphics_source, "Icons shiny/#{source_file_name}{,_female}.png")) do |file|
    ext = File.extname(file).downcase
    has_female = true if file.downcase.include?('_female')
    dest = File.join('output/graphics/pokedex/pokeicon', "#{file.downcase.include?('_female') ? shiny_f_resource : shiny_resource}#{ext}")
    FileUtils.cp(file, dest)
  end

  Dir.glob(File.join(graphics_source, "Footprints/#{source_file_name}.png")) do |file|
    ext = File.extname(file).downcase
    dest = File.join('output/graphics/pokedex/footprints', "#{basic_resource}#{ext}")
    FileUtils.cp(file, dest)
  end

  Dir.glob(File.join($essentials_path, "Graphics/Characters/#{source_file_name}{,_female}.png")) do |file|
    ext = File.extname(file).downcase
    if file.include?('_s') || file.include?('s_') || file.include?('shiny')
      dest = File.join('output/graphics/characters', "#{shiny_resource}#{ext}")
    else
      dest = File.join('output/graphics/characters', "#{basic_resource}#{ext}")
    end
    FileUtils.cp(file, dest)
  end

  Dir.glob(File.join($essentials_path, "Audio/SE/Cries/#{source_file_name}*")) do |file|
    ext = File.extname(file).downcase
    dest = File.join('output/audio/se/cries', "#{basic_resource}#{ext}")
    FileUtils.cp(file, dest)
  end

  return has_female
end
