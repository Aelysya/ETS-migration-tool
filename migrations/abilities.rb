# Migrate Pokemon Essentials abilities into Pokemon Studio format
def migrate_abilities
  File.open(File.join($essentials_path, 'Data/abilities.dat'), 'rb') do |f|
    data = Marshal.load(f)
    existing_abilities = read_existing_entities('abilities')

    i = 1
    data.each_value do |ability|
      ability_name = ability.id.downcase.to_s

      # As One is a single ability in Studio, so we skip this one as its a duplicate
      next i += 1 if ability_name == 'asonegrimneigh'

      if ability_name == 'asonechillingneigh'
        final_name = 'as_one'
      else
        existing_name = find_existing_entity(ability_name, existing_abilities)
        final_name = existing_name.nil? ? ability_name : existing_name
      end

      json = {
        klass: 'Ability',
        id: i,
        dbSymbol: final_name,
        textId: i
      }

      i += 1
      save_json("Data/Studio/abilities/#{final_name}.json", json)
    end
  end
end
