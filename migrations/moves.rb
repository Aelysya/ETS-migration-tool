# Migrate Essentials moves into Studio format
def migrate_moves
  File.open(File.join($essentials_path, 'Data/moves.dat'), 'rb') do |f|
    data = Marshal.load(f)

    i = 0
    data.each_value do |move|
      move_name = move.id.downcase.to_s
      existing_move = find_existing_entity(move_name, $existing_moves)
      move_exists = !existing_move.nil?
      db_symbol = move_exists ? existing_move['dbSymbol'] : move_name
      be_method = parse_be_method(move.function_code)

      json = {
        klass: 'Move',
        id: i,
        dbSymbol: db_symbol,
        mapUse: move_exists ? existing_move['mapUse'] : 0,
        battleEngineMethod: move_exists ? existing_move['battleEngineMethod'] : be_method,
        type: move.type.downcase,
        power: move.power == 1 ? 0 : move.power,
        accuracy: move.accuracy.clamp(0, 100),
        pp: move.total_pp.clamp(1, 100),
        category: parse_category(move.category),
        movecriticalRate: check_for_flag(move, 'HighCriticalHitRate') ? 2 : 1,
        priority: move.priority,
        isAuthentic: move_exists ? existing_move['isAuthentic'] : false,
        isBallistics: check_for_flag(move, 'Bomb'),
        isBite: check_for_flag(move, 'Biting'),
        isBlocable: check_for_flag(move, 'CanProtect'),
        isCharge: move_exists ? existing_move['isCharge'] : false,
        isDance: check_for_flag(move, 'Dance'),
        isDirect: check_for_flag(move, 'Contact'),
        isDistance: move_exists ? existing_move['isDistance'] : false,
        isEffectChance: false,
        isGravity: move_exists ? existing_move['isGravity'] : false,
        isHeal: move.function_code.downcase.include?('heal'),
        isKingRockUtility: move_exists ? existing_move['isKingRockUtility'] : [0, 1].include?(move.category),
        isMagicCoatAffected: move_exists ? existing_move['isMagicCoatAffected'] : false,
        isMental: move_exists ? existing_move['isMental'] : false,
        isMirrorMove: check_for_flag(move, 'CanMirrorMove'),
        isNonSkyBattle: move_exists ? existing_move['isNonSkyBattle'] : false,
        isPowder: check_for_flag(move, 'Powder'),
        isPulse: check_for_flag(move, 'Pulse'),
        isPunch: check_for_flag(move, 'Punching'),
        isRecharge: be_method == 's_reload',
        isSnatchable: move_exists ? existing_move['isSnatchable'] : move.category == 2,
        isSoundAttack: check_for_flag(move, 'Sound'),
        isSlicingAttack: check_for_flag(move, 'Slicing'),
        isUnfreeze: check_for_flag(move, 'ThawsUser'),
        isWind: check_for_flag(move, 'Wind'),
        battleEngineAimedTarget: parse_move_target_mode(move.target.to_s),
        battleStageMod: parse_move_stats(move.function_code),
        moveStatus: parse_move_statuses(move.function_code),
        effectChance: move.effect_chance.clamp(0, 100)
      }

      i += 1
      save_json("Data/Studio/moves/#{db_symbol}.json", json)
    end
  end
end

# Determine a move's category based on a number
# @param move_category [Int] int-coded category of the move
# @return [String] the determined category
def parse_category(move_category)
  case move_category
  when 0
    return 'physical'
  when 1
    return 'special'
  else
    return 'status'
  end
end

# Determine a move's targetting mode
# @param move_category [Int] int-coded category of the move
# @return [String] the determined targetting mode
def parse_move_target_mode(move_target_mode)
  case move_target_mode
  when 'NearAlly'
    return 'adjacent_ally'
  when 'UserOrNearAlly'
    return 'user_or_adjacent_ally'
  when 'AllAllies', 'UserSide'
    return 'all_ally'
  when 'NearFoe', 'Foe'
    return 'adjacent_foe'
  when 'RandomNearFoe'
    return 'random_foe'
  when 'AllNearFoes'
    return 'adjacent_all_foe'
  when 'AllFoes', 'FoeSide'
    return 'all_foe'
  when 'NearOther'
    return 'adjacent_pokemon'
  when 'AllNearOthers'
    return 'adjacent_all_pokemon'
  when 'Other'
    return 'any_other_pokemon'
  when 'AllBattlers', 'BothSides'
    return 'all_pokemon'
  else # 'None', 'User', default
    return 'user'
  end
end

# Determine a move's BE method
# @param move_function [String] move's function
# @return [String] the determined BE method
def parse_be_method(move_function)
  case move_function
  when 'HitTwoToFiveTimes'
    return 's_multi_hit'
  when 'AttackAndSkipNextTurn'
    return 's_reload'
  when 'HitTwoTimes'
    return 's_2hits'
  when 'HealUserHalfOfTotalHP'
    return 's_heal'
  when 'HealUserByHalfOfDamageDone'
    return 's_absorb'
  else
    return 's_bind' if move_function.include?('BindTarget')
    return 's_recoil' if move_function.include?('Recoil')

    return 's_basic'
  end
end

# Determine the statuses a move can inflict by parsing its function name
# @param move_function [String] move's function
# @return [Array] the determined inflicted statuses
def parse_move_statuses(move_function)
  statuses = move_function.scan(Regexp.union(%w[Sleep Poison BadPoison Paralyze Burn Freeze Flinch Confuse]))
  statuses.delete('Flinch') if statuses.size > 1 # Flinch when paired with other statuses behaves differently and is managed by BE method
  move_status_element = []

  statuses.each do |status|
    move_status_element << {
      status: parse_status(status),
      luckRate: (100 / statuses.size).floor
    }
  end
  return move_status_element
end

# Determine a Studio status based on Essentials status
# @param status [String] the original status
# @return [String] the converted status
def parse_status(status)
  case status
  when 'Sleep'
    return 'ASLEEP'
  when 'Poison'
    return 'POISONED'
  when 'BadPoison'
    return 'TOXIC'
  when 'Paralyze'
    return 'PARALYZED'
  when 'Burn'
    return 'BURN'
  when 'Freeze'
    return 'FROZEN'
  when 'Flinch'
    return 'FLINCH'
  when 'Confuse'
    return 'CONFUSED'
  end
end

# Determine the stats a move can affect by parsing its function name
# @param move_function [String] move's function
# @return [Array] the determined affected stats
def parse_move_stats(move_function)
  regex = /(Raise|Lower)(User|Target)((?:Atk|Attack|Def|Defense|SpAtk|SpDef|Spd|Speed|Acc|Accuracy|Eva|Evasion|MainStats)+)(\d)/

  stats = move_function.scan(regex).map do |direction, _, battle_stages, value|
    {
      direction: direction,
      battle_stages: battle_stages.scan(/Atk|Attack|Def|Defense|SpAtk|SpDef|Spd|Speed|Acc|Accuracy|Eva|Evasion|MainStats/),
      value: value.to_i
    }
  end

  move_stats_element = []
  stats.each do |stat|
    if stat[:battle_stages].include?('MainStats')
      move_stats_element << {
        battleStage: 'ATK_STAGE',
        modificator: stat[:direction] == 'Raise' ? stat[:value] : -stat[:value]
      }
      move_stats_element << {
        battleStage: 'DEF_STAGE',
        modificator: stat[:direction] == 'Raise' ? stat[:value] : -stat[:value]
      }
      move_stats_element << {
        battleStage: 'ATS_STAGE',
        modificator: stat[:direction] == 'Raise' ? stat[:value] : -stat[:value]
      }
      move_stats_element << {
        battleStage: 'DFS_STAGE',
        modificator: stat[:direction] == 'Raise' ? stat[:value] : -stat[:value]
      }
      move_stats_element << {
        battleStage: 'SPD_STAGE',
        modificator: stat[:direction] == 'Raise' ? stat[:value] : -stat[:value]
      }
    else
      stat[:battle_stages].each do |s|
        move_stats_element << {
          battleStage: parse_stat(s),
          modificator: stat[:direction] == 'Raise' ? stat[:value] : -stat[:value]
        }
      end
    end
  end

  return move_stats_element
end

# Determine a Studio stat based on Essentials stat
# @param status [String] the original stat
# @return [String] the converted stat
def parse_stat(stat)
  case stat
  when 'Atk', 'Attack'
    return 'ATK_STAGE'
  when 'Def', 'Defense'
    return 'DEF_STAGE'
  when 'SpAtk'
    return 'ATS_STAGE'
  when 'SpDef'
    return 'DFS_STAGE'
  when 'Spd', 'Speed'
    return 'SPD_STAGE'
  when 'Acc', 'Accuracy'
    return 'ACC_STAGE'
  when 'Eva', 'Evasion'
    return 'EVA_STAGE'
  end
end
