# ETS-migration-tool

This tool allows you to migrate your Pokémon Essentials data to the Pokémon Studio format.

This tool **does** migrate the following things:
- Abilities
- Types
- Pokédexes
- Items
- Moves
- Pokémon
- Trainers
- Map metadata (in the form of "Zones")
- Map encounters (in the form of "Groups")
- Audio resources linked to the Pokémon and trainers
- Graphic resources linked to Pokémon, items and trainers

This tool **does not** migrate the following things:
- Maps
- Events
- Scripts (You'll need to "translate" them because PSDK's code base is very different from Essentials')
- Hardcoded data

## Use cases

This tool **will be useful** to you if you have a lot of custom data added in your PBS files and you don't want to re-add them into Pokémon Studio when you switch to it.
This tool **will not be useful** to you if **do not have** custom data, or a very limited amount. If you have something like 10-15 Fakemons and a couple custom items, then you'll take less time manually re-adding them to Studio than verifying them after the migration. In that case, the best course of action is to download a datapack to have up to date data in your project and then add your custom data.

## How to use the tool

- You need Ruby installed on your computer to make the program work, if you don't have it you can get it [here](https://rubyinstaller.org/).
- Download the datapacks from [here](https://github.com/PokemonWorkshop/GameDataPacks/tree/gen-packs)
- Make a copy of the file named `settings.json` and rename it `settings.local.json`
- Open the new file you created and replace the paths inside by the relevant ones. The path to your project should end by its name. The path to the datapacks should end by `GameDataPacks`
- Double click on the `launch.bat` file to begin the migration
- Wait, the console should inform you of the migration's progress (depending on your project's size, it can take several minutes)
- Once the migration is complete, open the newly created `output` folder, there should be 3 folders inside
- Copy the 3 folders and paste them in a newly created Pokémon Studio project
- If you are asked about it, select 'replace all'
- See next part for the last steps of the migration

## After the migration

Keep in mind that this tool is not perfect, and given the many differences between Essentials and Studio, it will most likely never be 100% accurate. So, while it may save you a lot of time migrating your data into Studio, you still have some work to do after the migration is complete. Some data cannot be migrated because it is hardcoded in Essentials but customizable directly into Studio, in such cases, they have been set to default values. The data you will need to double check are:
- Move functions
- Move flags
- Move Status effects when you have flinch and aleast another status (this kind of effect combo is managed differently in Studio because the flinch can happen at the same time as another status, in this case there needs to be a specific move function written to allow applying the flinch effect)
- Pokémon evolutions (only if they rely on a quite specific method, if its a level based evolution or other widely spread evolution method they are most likely migrated correctly)
- Type colors
- Items effects (listing them would be quite long, but look for things like repel steps, hp healing amounts or status healing as can all be customized in Studio instead of needing to add their effect in a script)
- Trainers' Pokémon (There is a lot more options of customization in Studio, you may want to look back at your trainers and tweak them)
- Zones and Groups (Studio doesn't work the same way as Essentials in terms of map encounters, look at your migrated zones and groups to adapt them to your needs)