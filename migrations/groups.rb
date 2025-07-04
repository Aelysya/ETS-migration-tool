# Migrate Essentials groups into Studio format
def migrate_groups
  File.open(File.join($essentials_path, 'Data/encounters.dat'), 'rb') do |f|
    data = Marshal.load(f)

    i = 0
    data.each_value do |encounter_group|
      encounter_group.step_chances.each do |type, chance|
        json = {
          klass: 'Group',
          id: i,
          dbSymbol: "group_#{i}",
          systemTag: parse_system_tag(type.to_s),
          terrainTag: 0,
          tool: %i[OldRod GoodRod SuperRod RockSmash].include?(type) ? type.to_s : nil,
          isDoubleBattle: false,
          isHordeBattle: false,
          customConditions: parse_condition(type.to_s),
          encounters: build_encounters_element(encounter_group.types[type]),
          stepsAverage: chance
        }

        save_json("Data/Studio/groups/group_#{i}.json", json)
      rescue => e
        $errors << "Error #{e} on group_#{i}"
      ensure
        generate_dummy_csv("Group #{i}", $group_names)
        i += 1
      end
    end
  end
  $group_names.close
end

# Determine the systemTag linked to this group
# @param type [String] the type of the current group
# @return [String] the systemTag
def parse_system_tag(type)
  return 'Grass' if type.include?('Land') || type.include?('BugContest')
  return 'Cave' if type.include?('Cave')
  return 'Pond' if type.include?('Water') || type.include?('Rod')
  return 'HeadButt' if type.include?('Headbutt')

  return 'RegularGround'
end

# Determine the condition linked to this group
# @param type [String] the type of the current group
# @return [Hash] the condition
def parse_condition(type)
  switch_value = nil

  switch_value = 11 if type.include?('Day') || type.include?('Afternoon')
  switch_value = 12 if type.include?('Night')
  switch_value = 13 if type.include?('Morning')
  switch_value = 14 if type.include?('Evening')

  return [] if switch_value.nil?

  return [
    {
      type: 'enabledSwitch',
      value: switch_value,
      relationWithPreviousCondition: 'AND'
    }
  ]
end

# Build the encounters of a group
# @param encounters [Array] the encounters from Essentials
# @return [Array] the encounters of the group
def build_encounters_element(encounters)
  encounters_element = []
  encounters.each do |pokemon|
    pokemon_name = pokemon[1].downcase.to_s
    form = 0
    if pokemon_name =~ /^([a-z]+)_(\d+)$/
      pokemon_name = $1
      form = $2.to_i
    end
    pokemon_name.chop! if %w[nidoranfe nidoranma].include?(pokemon_name) # Nidoran species are named differently in Essentials
    existing_pokemon = find_existing_entity(pokemon_name, $existing_species)
    db_symbol = existing_pokemon.nil? ? pokemon_name : existing_pokemon['dbSymbol']

    encounters_element << {
      specie: db_symbol,
      form: form,
      shinySetup: {
        kind: 'automatic',
        rate: -1
      },
      levelSetup: {
        kind: 'minmax',
        level: {
          minimumLevel: pokemon[2],
          maximumLevel: pokemon[3]
        }
      },
      randomEncounterChance: pokemon[0],
      expandPokemonSetup: [
        {
          type: 'evs',
          value: { hp: 0, atk: 0, dfe: 0, spd: 0, ats: 0, dfs: 0 }
        },
        {
          type: 'loyalty',
          value: 70
        },
        {
          type: 'moves',
          value: %w[__undef__ __undef__ __undef__ __undef__]
        }
      ]
    }
  end
  return encounters_element
end
