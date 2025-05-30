# Migrate Essentials types into Studio format
def migrate_types
  # File.open("Data/messages_core.dat", "rb") do |f|
  File.open(File.join($essentials_path, 'Data/types.dat'), 'rb') do |f|
    data = Marshal.load(f)

    i = 0
    data.each_value do |type|
      type_name = type.id.downcase.to_s
      next if type_name == 'qmarks'

      existing_type = find_existing_entity(type_name, $existing_types)
      type_exists = !existing_type.nil?
      db_symbol = type_exists ? existing_type['dbSymbol'] : type_name

      json = {
        textId: type_exists ? existing_type['textId'] : i,
        klass: 'Type',
        id: type_exists ? existing_type['id'] : i + 1,
        dbSymbol: db_symbol,
        color: type_exists ? existing_type['color'] : '#c3b5b2',
        damageTo: build_damage_to(data, type_name)
      }

      save_json("Data/Studio/types/#{db_symbol}.json", json)
    rescue => e
      $errors << "Error #{e} on #{db_symbol}"
    ensure
      i += 1
      translate_text(type.real_name, 'core', 12, 100_003)
    end
  end
end

# Build the type effectivenesses element of the type JSON
# @param data [Hash] list of types defined in the Essentials project
# @param current_type [String] name of the current type being migrated
def build_damage_to(data, current_type)
  damage_to = []
  i = 0
  data.each_value do |type|
    db_symbol = type.id.downcase.to_s
    next if db_symbol == 'qmarks'

    type.resistances.each do |t|
      next unless t.downcase.to_s == current_type

      damage_to << {
        defensiveType: db_symbol,
        factor: 0.5
      }
    end

    type.weaknesses.each do |t|
      next unless t.downcase.to_s == current_type

      damage_to << {
        defensiveType: db_symbol,
        factor: 2
      }
    end

    type.immunities.each do |t|
      next unless t.downcase.to_s == current_type

      damage_to << {
        defensiveType: db_symbol,
        factor: 0
      }
    end

    i += 1
  end

  return damage_to
end
