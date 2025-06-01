# Migrate Essentials abilities into Studio format
def migrate_abilities
  File.open(File.join($essentials_path, 'Data/abilities.dat'), 'rb') do |f|
    data = Marshal.load(f)

    i = 0
    data.each_value do |ability|
      translate_text(ability.real_name, 'core', 10, $abilities_names)
      translate_text(ability.real_description, 'core', 11, $abilities_descriptions)
      ability_name = ability.id.downcase.to_s

      # As One and Embody Aspect are a single abilities in Studio, so we skip these ones as they are duplicates
      next i += 1 if %w[asonegrimneigh embodyaspect_1 embodyaspect_2 embodyaspect_3].include?(ability_name)

      if ability_name == 'asonechillingneigh'
        db_symbol = 'as_one'
      elsif %w[embodyaspect_1 embodyaspect_2 embodyaspect_3].include?(ability_name)
        db_symbol = 'embody_aspect'
      else
        existing_ability = find_existing_entity(ability_name, $existing_abilities)
        db_symbol = existing_ability.nil? ? ability_name : existing_ability['dbSymbol']
      end

      json = {
        klass: 'Ability',
        id: i,
        dbSymbol: db_symbol,
        textId: i
      }

      save_json("Data/Studio/abilities/#{db_symbol}.json", json)
    rescue => e
      $errors << "Error #{e} on #{db_symbol}"
    ensure
      i += 1
    end
  end
  $abilities_names.close
  $abilities_descriptions.close
end
