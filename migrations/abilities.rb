# Migrate Essentials abilities into Studio format
def migrate_abilities
  File.open(File.join($essentials_path, 'Data/abilities.dat'), 'rb') do |f|
    data = Marshal.load(f)

    i = 0
    data.each_value do |ability|
      translate_text(ability.real_name, 'core', 10, 100_004)
      translate_text(ability.real_description, 'core', 11, 100_005)
      ability_name = ability.id.downcase.to_s

      # As One is a single ability in Studio, so we skip this one as its a duplicate
      next i += 1 if ability_name == 'asonegrimneigh'

      if ability_name == 'asonechillingneigh'
        db_symbol = 'as_one'
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

      i += 1
      save_json("Data/Studio/abilities/#{db_symbol}.json", json)
    end
  end
end
