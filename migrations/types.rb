# Migrate Essentials types into Studio format
def migrate_types
  File.open(File.join($essentials_path, 'Data/types.dat'), 'rb') do |f|
    data = Marshal.load(f)
    puts data.inspect

    # Double loop to process custom type after the existing ones
    data.each_value do |type|
      type_name = type.id.downcase.to_s
      existing_type = find_existing_entity(type_name, $existing_types)
      type_exists = !existing_type.nil?
      next unless type_exists

      db_symbol = existing_type['dbSymbol']

      json = {
        textId: existing_type['textId'],
        klass: 'Type',
        id: existing_type['id'],
        dbSymbol: db_symbol,
        color: existing_type['color'],
        damageTo: build_damage_to(data, type_name)
      }

      save_json("Data/Studio/types/#{db_symbol}.json", json)
    rescue => e
      $errors << "Error #{e} on #{db_symbol}"
    ensure
      translate_text(type.real_name, 'core', 12, $types_names) if type_exists
    end

    custom_type_counter = 18
    data.each_value do |type|
      type_name = type.id.downcase.to_s
      existing_type = find_existing_entity(type_name, $existing_types)
      type_exists = !existing_type.nil?
      next if type_name == 'qmarks' || type_exists

      db_symbol = type_name

      json = {
        textId: custom_type_counter,
        klass: 'Type',
        id: custom_type_counter + 1,
        dbSymbol: db_symbol,
        color: '#c3b5b2',
        damageTo: build_damage_to(data, type_name)
      }

      save_json("Data/Studio/types/#{db_symbol}.json", json)
    rescue => e
      $errors << "Error #{e} on #{db_symbol}"
    ensure
      custom_type_counter += 1
      translate_text(type.real_name, 'core', 12, $types_names) unless type_exists || type_name == 'qmarks'
    end
  end
  $types_names.close
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
