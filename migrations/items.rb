# Migrate Essentials items into Studio format
def migrate_items
  File.open(File.join($essentials_path, 'Data/items.dat'), 'rb') do |f|
    data = Marshal.load(f)
    existing_items = read_existing_entities('items')

    i = 0
    data.each_value do |item|
      item_name = item.id.downcase.to_s
      existing_item = find_existing_entity(item_name, existing_items)
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
        existing_moves = read_existing_entities('moves')
        move_name = item.move.downcase.to_s
        existing_move = find_existing_entity(move_name, existing_moves)
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

      i += 1
      save_json("Data/Studio/items/#{db_symbol}.json", json)
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
