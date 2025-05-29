# Migrate Essentials items into Studio format
def migrate_items
  File.open(File.join($essentials_path, 'Data/items.dat'), 'rb') do |f|
    data = Marshal.load(f)

    i = 0
    data.each_value do |item|
      item_name = item.id.downcase.to_s
      existing_item = find_existing_entity(item_name, $existing_items)
      item_exists = !existing_item.nil?
      db_symbol = item_exists ? existing_item['dbSymbol'] : item_name
      klass = parse_klass(item, existing_item)

      json = {
        klass: klass,
        id: i,
        dbSymbol: db_symbol,
        icon: i,
        price: item.price,
        socket: parse_item_socket(item.pocket),
        position: 0,
        isBattleUsable: item_exists ? existing_item['isBattleUsable'] : item.battle_use != 0,
        isMapUsable: item_exists ? existing_item['isMapUsable'] : item.field_use != 0,
        isLimited: item.consumable,
        isHoldable: item_exists ? existing_item['isHoldable'] : klass != 'KeyItem',
        flingPower: parse_fling_power(item)
      }

      json['repelCount'] = item_exists ? existing_item['repelCount'] : 100 if klass == 'RepelItem'
      json['catchRate'] = item_exists ? existing_item['catchRate'] : 1.0 if klass == 'BallItem'
      json['color'] = item_exists ? existing_item['color'] : { red: 255, geen: 0, blue: 0, alpha: 255 } if klass == 'BallItem'
      json['spriteFilename'] = item_exists ? existing_item['spriteFilename'] : 'ball_1' if klass == 'BallItem'

      if klass == 'TechItem'
        move_name = item.move.downcase.to_s
        existing_move = find_existing_entity(move_name, $existing_moves)
        move_exists = !existing_move.nil?
        json['move'] = move_exists ? existing_move['dbSymbol'] : move_name
        json['isHm'] = item_exists ? existing_item['isHm'] : false
      end

      if %w[StatusHealItem AllPPHealItem PPHealItem StatusRateHealItem RateHealItem StatusConstantHealItem
            LevelIncreaseItem ExpGiveItem EVBoostItem ConstantHealItem StatBoostItem PPIncreaseItem HealingItem].include?(klass)
        fields = %w[loyaltyMalus statusList ppCount hpRate hpCount levelCount expCount stat count isMax]
        fields.each do |field|
          json[field] = existing_item[field] unless existing_item[field].nil?
        end
      end

      copy_item_resources(item, i, json['move'])

      i += 1
      save_json("Data/Studio/items/#{db_symbol}.json", json)
      translate_text(item.real_name, 'core', 7, 100_012)
      translate_text(item.real_name_plural, 'core', 8, 900_1)
      translate_text(item.real_description, 'core', 9, 100_013)
    end
  end
end

# Determine the klass of an item
# @param item [Object] the item from Essentials
# @param existing_item [Object | nil] the existing item from Studio
# @return [String] the klass of the item
def parse_klass(item, existing_item)
  return 'KeyItem' if check_for_flag(item, 'KeyItem')
  return 'RepelItem' if check_for_flag(item, 'Repel')
  return 'StoneItem' if check_for_flag(item, 'EvolutionStone')
  return 'BallItem' if check_for_flag(item, 'PokeBall')
  return 'TechItem' unless item.move.nil?

  return existing_item.nil? ? 'Item' : existing_item['klass']
end

# Determine an item's socket based on a number
# @param item [Int] int-coded pocket of the item
# @return [Int] the socket of the item
def parse_item_socket(item_pocket)
  case item_pocket
  when 2
    return 6
  when 3
    return 2
  when 4
    return 3
  when 5
    return 4
  when 8
    return 5
  else # 1, 6, 7, default
    return 1
  end
end

# Determine an item's fling power
# @param item [Object] the item from Essentials
# @return [Int] the fling power of the item
def parse_fling_power(item)
  return 0 unless item.flags.any? { |f| f =~ /Fling/ }

  item.flags.each { |flag| return $1.to_i if flag =~ /Fling_(\d+)/ }
end

# Copy the Essentials resources of this item
# @param item [Object] the item from Essentiasl containing information to find the related graphics
# @param id [Int] the item's ID
# @param move [String | nil] the move taught by this item
def copy_item_resources(item, id, move = nil)
  graphics_source = File.join($essentials_path, 'Graphics/Items')
  if move.nil?
    Dir.glob(File.join(graphics_source, "#{item.id}*")) do |file|
      ext = File.extname(file)
      dest = File.join('output/graphics/icons', "#{id}#{ext}")
      FileUtils.cp(file, dest)
    end
  else
    existing_move = find_existing_entity(move, $existing_moves)
    db_symbol = existing_move.nil? ? move : existing_move['dbSymbol']

    generated_move = JSON.parse(File.read(File.join('output/Data/Studio/moves', "#{db_symbol}.json")))
    type = generated_move['type'].upcase

    Dir.glob(File.join(graphics_source, "machine_#{type}*")) do |file|
      ext = File.extname(file)
      dest = File.join('output/graphics/icons', "#{id}#{ext}")
      FileUtils.cp(file, dest)
    end
  end
end
