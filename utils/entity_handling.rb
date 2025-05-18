# Find if an entity already exists in the Gen 9 pack
# @param essentials_entity [String] entity's name in Pokemon Essentials
# @param existing_entities [String] list of existing entities of the same type
# @return the existing entity name in Pokemon Studio format if it exists, nil otherwise
def find_existing_entity(essentials_entity, existing_entities)
  existing_entities.each do |a|
    return a if a.gsub(/_/, '') == essentials_entity
  end

  return nil
end
