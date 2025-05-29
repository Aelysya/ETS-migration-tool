# Migrate Essentials dexes into Studio format
def migrate_dexes
  migrate_national_dex
  migrate_regional_dexes
end

# Migrate the National Pokédex
# @note The National Pokedex is a special case because it's not contained in the usual regional_dexes.dat file,
#   it instead is defined automatically by the Pokémon list in the order they are defined
def migrate_national_dex
  File.open(File.join($essentials_path, 'Data/species.dat'), 'rb') do |f|
    data = Marshal.load(f)
    creatures = []

    data.each_value do |pokemon|
      pokemon_name = pokemon.id.downcase.to_s
      pokemon_name.chop! if %w[nidoranfe nidoranma].include?(pokemon_name) # Nidoran species are named differently in Essentials
      next if pokemon.form != 0

      existing_pokemon = find_existing_entity(pokemon_name, $existing_species)
      db_symbol = existing_pokemon.nil? ? pokemon_name : existing_pokemon['dbSymbol']

      creatures << {
        dbSymbol: db_symbol,
        form: 0
      }
    end

    json = {
      klass: 'Dex',
      id: 0,
      dbSymbol: 'national',
      startId: 1,
      csv: {
        csvFileId: 100_063,
        csvTextIndex: 0
      },
      creatures: creatures
    }
    save_json('Data/Studio/dex/national.json', json)
  end
end

# Migrate the regional Pokédexes
def migrate_regional_dexes
  File.open(File.join($essentials_path, 'Data/regional_dexes.dat'), 'rb') do |f|
    data = Marshal.load(f)

    data.each_with_index do |dex, i|
      dex_name = find_dex_name(i)
      creatures = []

      dex.each do |pokemon|
        pokemon_name = pokemon.downcase.to_s
        pokemon_name.chop! if %w[nidoranfe nidoranma].include?(pokemon_name) # Nidoran species are named differently in Essentials
        existing_pokemon = find_existing_entity(pokemon_name, $existing_species)
        db_symbol = existing_pokemon.nil? ? pokemon_name : existing_pokemon['dbSymbol']

        creatures << {
          dbSymbol: db_symbol,
          form: 0
        }
      end

      json = {
        klass: 'Dex',
        id: i + 1,
        dbSymbol: dex_name,
        startId: 1,
        csv: {
          csvFileId: 100_063,
          csvTextIndex: i + 1
        },
        creatures: creatures
      }
      save_json("Data/Studio/dex/#{dex_name}.json", json)
    end
  end
end

# Find the name of the dex by its index
# @param dex_index [Integer] index of the dex
# @return [String] name of the dex
def find_dex_name(dex_index)
  File.open(File.join($essentials_path, 'Data/town_map.dat'), 'rb') do |f|
    data = Marshal.load(f)
    name = data[dex_index].real_name
    translate_text(name, 'game', 18, 100_063)
    return name.downcase
  end
end
