# Migrate Essentials zones into Studio format
def migrate_zones
  File.open(File.join($essentials_path, 'Data/map_metadata.dat'), 'rb') do |f|
    data = Marshal.load(f)

    i = 0
    data.each_value do |zone|
      position = { x: nil, y: nil }
      position = { x: zone.town_map_position[1], y: zone.town_map_position[2] } unless zone.town_map_position.nil?

      json = {
        klass: 'Zone',
        id: i,
        dbSymbol: "zone_#{i}",
        maps: [
          zone.id
        ],
        worldmaps: [],
        panelId: 0,
        warp: parse_warp_point(zone),
        position: position,
        isFlyAllowed: zone.outdoor_map.nil? ? false : zone.outdoor_map,
        isWarpDisallowed: position[:x].nil?,
        forcedWeather: zone.weather.nil? ? nil : parse_weather(zone.weather),
        wildGroups: find_wild_groups(zone)
      }

      save_json("Data/Studio/zones/zone_#{i}.json", json)
    rescue => e
      $errors << "Error #{e} on zone_#{i}"
    ensure
      translate_text(zone.real_name, 'game', 21, $zone_names)
      generate_dummy_csv("Zone #{i} description", $zone_description)
      i += 1
    end
  end
  $zone_names.close
  $zone_description.close
end

# Determine the weather linked to this zone
# @param zone [Object] the current zone
# @return [Int] the weather
def parse_weather(zone_weather)
  case zone_weather[0]
  when 'Rain', 'HeavyRain', 'Storm'
    return 1
  when 'Sun'
    return 2
  when 'Sandstorm'
    return 3
  when 'Snow', 'Blizzard'
    return 4
  else # Fog
    return 5
  end
end

# Parse the warping coordinates linked to this zone
# @param zone [Object] the current zone
# @return [Hash] the warping coordinates
def parse_warp_point(zone)
  File.open(File.join($essentials_path, 'Data/town_map.dat'), 'rb') do |f|
    data = Marshal.load(f)

    warp = {
      x: nil,
      y: nil
    }

    data.each_value do |map|
      map.point.each do |p|
        next unless p[2] == zone.real_name && !p[5].nil? && !p[6].nil?

        warp = {
          x: p[5],
          y: p[6]
        }
      end
    end
    return warp
  end
end

# Find the groups linked to this zone
# @param zone [Object] the current zone
# @return [Array] the list of groups
def find_wild_groups(zone)
  File.open(File.join($essentials_path, 'Data/encounters.dat'), 'rb') do |f|
    data = Marshal.load(f)
    groups = []

    i = 0
    data.each_value do |encounter_group|
      encounter_group.step_chances.each do |_|
        groups << "group_#{i}" if encounter_group.map == zone.id
        i += 1
      end
    end
    return groups
  end
end
