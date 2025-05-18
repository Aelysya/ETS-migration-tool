# Migrate Pokemon Essentials types into Pokemon Studio format
def migrate_types
  # File.open("Data/messages_core.dat", "rb") do |f|
  File.open(File.join($essentials_path, 'Data/types.dat'), 'rb') do |f|
    data = Marshal.load(f)
    puts data.inspect

    data.each_value do |type|
      next if type.id == 'QMARKS'

      
    end
  end
end
