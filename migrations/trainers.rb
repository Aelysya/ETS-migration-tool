# Migrate Essentials trainers into Studio format
def migrate_trainers
  File.open(File.join($essentials_path, 'Data/trainers.dat'), 'rb') do |f|
    data = Marshal.load(f)
    # puts data.inspect

    i = 0
    data.each_value do |trainer|
      trainer_type = find_trainer_type(trainer)
      next i += 1 if trainer_type.nil?

      copy_trainer_resources(trainer_type)
      db_symbol = "trainer_#{i}"

      json = {
        klass: 'TrainerBattleSetup',
        id: i,
        dbSymbol: db_symbol,
        vsType: 1,
        isCouple: false,
        baseMoney: trainer_type.base_money,
        bagEntries: build_bag_entries(trainer),
        battleId: 0,
        ai: parse_ai_level(trainer_type.skill_level),
        party: build_party(trainer),
        resources: {
          sprite: trainer_type.id.to_s,
          artworkFull: '',
          artworkSmall: '',
          character: "trainer_#{trainer_type.id}",
          musics: {
            encounter: trainer_type.intro_BGM || '',
            victory: '',
            defeat: trainer_type.victory_BGM || '',
            bgm: trainer_type.battle_BGM || ''
          }
        },
        additionalDialogs: []
      }

      save_json("Data/Studio/trainers/#{db_symbol}.json", json)
    rescue => e
      $errors << "Error #{e} on #{db_symbol}"
    ensure
      i += 1
      translate_text(trainer_type.real_name, 'core', 13, $trainers_type_names)
      translate_text(trainer.real_name, 'game', 14, $trainers_names)
      translate_text(trainer.real_lose_text, 'game', 23, $trainers_lose_texts)
    end
  end
  $trainers_type_names.close
  $trainers_names.close
  $trainers_lose_texts.close
end

# Find the corresponding trainer type of a trainer
# @param trainer [Object] the trainer from Essentials
# @return [Object] the trainer type object
def find_trainer_type(trainer)
  File.open(File.join($essentials_path, 'Data/trainer_types.dat'), 'rb') do |f|
    data = Marshal.load(f)

    data.each_value do |type|
      return type if type.id.downcase.to_s == trainer.trainer_type.downcase.to_s
    end
    return nil
  end
end

# Build the bag of a trainer
# @param trainer [Object] the trainer from Essentials
# @return [Array] the bag of the trainer
def build_bag_entries(trainer)
  used_items = []
  bag_entries = []

  trainer.items.each do |item|
    item_name = item.downcase.to_s
    existing_item = find_existing_entity(item_name, $existing_items)
    item_exists = !existing_item.nil?
    db_symbol = item_exists ? existing_item['dbSymbol'] : item_name
    next if used_items.include?(item_name)

    used_items << item_name

    bag_entries << {
      dbSymbol: db_symbol,
      amount: trainer.items.count(item)
    }
  end
  return bag_entries
end

# Build the Pokémon party of a trainer
# @param trainer [Object] the trainer from Essentials
# @return [Array] the party of the trainer
def build_party(trainer)
  party = []

  trainer.pokemon.each do |pokemon|
    pokemon_name = pokemon[:species].downcase.to_s
    pokemon_name.chop! if %w[nidoranfe nidoranma].include?(pokemon_name) # Nidoran species are named differently in Essentials
    existing_pokemon = find_existing_entity(pokemon_name, $existing_species)
    pokemon_exists = !existing_pokemon.nil?
    db_symbol = pokemon_exists ? existing_pokemon['dbSymbol'] : pokemon_name

    expand_pokemon_setup = []
    if pokemon[:ev].nil?
      expand_pokemon_setup << { type: 'evs', value: { hp: 0, atk: 0, dfe: 0, spd: 0, ats: 0, dfs: 0 } }
    else
      expand_pokemon_setup << {
        type: 'evs',
        value: {
          hp: pokemon[:ev][:HP].nil? ? 0 : pokemon[:ev][:HP],
          atk: pokemon[:ev][:ATTACK].nil? ? 0 : pokemon[:ev][:ATTACK],
          dfe: pokemon[:ev][:DEFENSE].nil? ? 0 : pokemon[:ev][:DEFENSE],
          spd: pokemon[:ev][:SPECIAL_ATTACK].nil? ? 0 : pokemon[:ev][:SPECIAL_ATTACK],
          ats: pokemon[:ev][:SPECIAL_DEFENSE].nil? ? 0 : pokemon[:ev][:SPECIAL_DEFENSE],
          dfs: pokemon[:ev][:SPEED].nil? ? 0 : pokemon[:ev][:SPEED]
        }
      }
    end

    if pokemon[:iv].nil?
      expand_pokemon_setup << { type: 'ivs', value: { hp: 0, atk: 0, dfe: 0, spd: 0, ats: 0, dfs: 0 } }
    else
      expand_pokemon_setup << {
        type: 'ivs',
        value: {
          hp: pokemon[:iv][:HP].nil? ? 0 : pokemon[:iv][:HP],
          atk: pokemon[:iv][:ATTACK].nil? ? 0 : pokemon[:iv][:ATTACK],
          dfe: pokemon[:iv][:DEFENSE].nil? ? 0 : pokemon[:iv][:DEFENSE],
          spd: pokemon[:iv][:SPECIAL_ATTACK].nil? ? 0 : pokemon[:iv][:SPECIAL_ATTACK],
          ats: pokemon[:iv][:SPECIAL_DEFENSE].nil? ? 0 : pokemon[:iv][:SPECIAL_DEFENSE],
          dfs: pokemon[:iv][:SPEED].nil? ? 0 : pokemon[:iv][:SPEED]
        }
      }
    end

    expand_pokemon_setup << { type: 'loyalty', value: pokemon[:happiness].nil? ? 70 : pokemon[:happiness] }
    expand_pokemon_setup << { type: 'moves', value: build_pokemon_moveset(pokemon) }
    expand_pokemon_setup << { type: 'originalTrainerName', value: trainer.real_name }
    expand_pokemon_setup << { type: 'originalTrainerId', value: 0 }

    expand_pokemon_setup << { type: 'ability', value: parse_pokemon_ability(pokemon) } unless pokemon[:ability].nil? && pokemon[:ability_index].nil?
    expand_pokemon_setup << { type: 'givenName', value: pokemon[:real_name] } unless pokemon[:real_name].nil?
    expand_pokemon_setup << { type: 'itemHeld', value: parse_pokemon_item(pokemon) } unless pokemon[:item].nil?
    expand_pokemon_setup << { type: 'nature', value: pokemon[:nature].downcase } unless pokemon[:nature].nil?
    expand_pokemon_setup << { type: 'gender', value: pokemon[:gender] + 1 } unless pokemon[:gender].nil? || pokemon[:gender] > 1
    expand_pokemon_setup << { type: 'caughtWith', value: parse_pokemon_ball(pokemon) } unless pokemon[:poke_ball].nil?

    if pokemon[:shininess].nil?
      shiny_rate = 0
    else
      shiny_rate = pokemon[:shininess] ? 1 : 0
    end

    party << {
      specie: db_symbol,
      form: pokemon[:form].nil? ? 0 : pokemon[:form],
      shinySetup: {
        kind: 'rate',
        rate: shiny_rate
      },
      levelSetup: {
        kind: 'fixed',
        level: pokemon[:level]
      },
      randomEncounterChance: 1,
      expandPokemonSetup: expand_pokemon_setup
    }
  end
  return party
end

# Determine the AI level of a trainer based on their skill level in Essentials
# @param ai_level [Integer] the skill level of the trainer
# @return [Integer] the parsed AI level
def parse_ai_level(skill_level)
  case skill_level
  when 0
    return 1
  when 1..20
    return 2
  when 21..40
    return 3
  when 41..60
    return 4
  when 61..80
    return 5
  when 81..99
    return 6
  else
    return 7
  end
end

# Build the moveset of a Pokémon
# @param pokemon [Object] the Pokémon from Essentials
# @return [Array] the moveset of the Pokémon
def build_pokemon_moveset(pokemon)
  return %w[__undef__ __undef__ __undef__ __undef__] if pokemon[:moves].nil?

  moveset = []

  pokemon[:moves].each do |move|
    existing_move = find_existing_entity(move.downcase.to_s, $existing_moves)
    db_symbol = existing_move.nil? ? move.downcase.to_s : existing_move['dbSymbol']
    moveset << db_symbol
  end

  moveset << '__remove__' while moveset.size < 4
  return moveset
end

# Determine the ability of a Pokémon
# @param pokemon [Object] the Pokémon from Essentials
# @return [String] the symbol of the ability
def parse_pokemon_ability(pokemon)
  if pokemon[:ability_index].nil?
    ability_name = pokemon[:ability].downcase.to_s
    existing_ability = find_existing_entity(ability_name, $existing_abilities)
    return existing_ability.nil? ? ability_name : existing_ability['dbSymbol']
  else
    pokemon_name = pokemon[:species].downcase.to_s
    pokemon_name.chop! if %w[nidoranfe nidoranma].include?(pokemon_name) # Nidoran species are named differently in Essentials
    existing_pokemon = find_existing_entity(pokemon_name, $existing_species)
    db_symbol = existing_pokemon.nil? ? pokemon_name : existing_pokemon['dbSymbol']

    generated_pokemon = JSON.parse(File.read(File.join('output/Data/Studio/pokemon', "#{db_symbol}.json")))
    form = pokemon[:form].nil? ? 0 : pokemon[:form]
    return generated_pokemon['forms'][form]['abilities'][pokemon[:ability_index]]
  end
end

# Determine the item held by a Pokémon
# @param pokemon [Object] the Pokémon from Essentials
# @return [String] the symbol of the item
def parse_pokemon_item(pokemon)
  item_name = pokemon[:item].downcase.to_s
  existing_item = find_existing_entity(item_name, $existing_items)
  return existing_item.nil? ? item_name : existing_item['dbSymbol']
end

# Determine the ball in which a Pokémon was caught
# @param pokemon [Object] the Pokémon from Essentials
# @return [String] the symbol of the ball
def parse_pokemon_ball(pokemon)
  item_name = pokemon[:poke_ball].downcase.to_s
  existing_item = find_existing_entity(item_name, $existing_items)
  return existing_item.nil? ? item_name : existing_item['dbSymbol']
end

# Copy the Essentials resources of this trainer
# @param trainer_type [Object] the trainer type from Essentiasl containing information to find the related graphics
def copy_trainer_resources(trainer_type)
  graphics_source = File.join($essentials_path, 'Graphics')
  trainer_sprite = File.join(graphics_source, "Trainers/#{trainer_type.id}.png")
  FileUtils.cp(trainer_sprite, File.join('output/graphics/battlers')) if File.exist?(trainer_sprite)

  character_sprite = File.join(graphics_source, "Characters/trainer_#{trainer_type.id}.png")
  FileUtils.cp(character_sprite, File.join('output/graphics/characters')) if File.exist?(character_sprite)

  audio_source = File.join($essentials_path, 'Audio/BGM')
  audio_dest = File.join('output/audio/bgm')
  Dir.glob(File.join(audio_source, "#{trainer_type.intro_BGM}.*")) { |file| FileUtils.cp(file, audio_dest) } unless trainer_type.intro_BGM.nil?
  Dir.glob(File.join(audio_source, "#{trainer_type.battle_BGM}.*")) { |file| FileUtils.cp(file, audio_dest) } unless trainer_type.battle_BGM.nil?
  Dir.glob(File.join(audio_source, "#{trainer_type.victory_BGM}.*")) { |file| FileUtils.cp(file, audio_dest) } unless trainer_type.victory_BGM.nil?
end
