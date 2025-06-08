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
- Texts and translations linked to everything above
- Audio resources linked to the Pokémon and trainers
- Graphic resources linked to Pokémon, items and trainers

This tool **does not** migrate the following things:
- Maps
- Events
- Scripts (You'll need to "translate" them because PSDK's code base is very different from Essentials')
- Hardcoded data

## Use cases

This tool **will be useful** to you if you have a lot of custom data added in your PBS files and you don't want to re-add them into Pokémon Studio when you switch to it.
This tool **will not be useful** to you if **do not have** custom data, or a very limited amount. If you have something in the range of 10-15 Fakemons and maybe a couple custom items, then you'll take less time manually re-adding them to Studio than verifying them after the migration. In that case, the best course of action is to download a datapack to have up to date data in your project and then add your custom data.

## How to use the tool
### Before the migration
You will need Ruby installed on your computer to make the program work, if you don't have it you can get it [here](https://rubyinstaller.org/).

You will also need a copy of the datapacks made for Pokémon Studio, the Gen 9 pack will be used as a default source when data cannot reliably be migrated from your project. You can download the datapacks from [here](https://github.com/PokemonWorkshop/GameDataPacks/tree/gen-packs).

Create a new Pokémon Studio project, the instructions on how to clean it up are explained in the next part, to give you something to do during the migration. (Keep in mind that you should also create another project and try out the demo with the default available data, it'll give you an excellent starting point in using PSDK, lots of the stuff related to RPGMXP is similar to what you're used to in Essentials)

To use the tool, you need to setup some parameters, to do that, open the tool's folder, make a copy of the file named `settings.json` and rename it `settings.local.json`. Open the new file you created and replace the paths inside by the relevant ones. The path to your project should end by its name. The path to the datapacks should end by `GameDataPacks`

### Starting the migration
- Double click on the `launch.bat` file to begin the migration
- Wait for the process to take its course, the console should inform you of the progress (depending on your project's size, it can take a couple of minutes)
- While waiting for the migration to complete, you can clean up your Studio project to remove the original data. For that go in the `Data/Studio` folder and delete the following folders:
  - abilities
  - dex
  - group
  - items
  - moves
  - pokemon
  - trainers
  - types
  - zones
- Once the migration is complete, open the newly created `output` folder, there should be 3 folders inside
- Go to root of the Studio project where you see the `Data`, `graphics` and `audio` folders, copy the 3 same folders from the migration and paste them in your project
- When you are asked about it, select 'replace all'

### After the migration
Keep in mind that this tool is not perfect, and given the many differences between Essentials and Studio, it will most likely never be 100% accurate. So, while it may save you a lot of time migrating your data into Studio, you still have some work to do after the migration is complete. Some data cannot be migrated because it is hardcoded in Essentials but customizable directly into Studio, in such cases, they have been set to default values. The data you will need to double check are:
- Move functions
- Move flags
- Move additional effects
- Pokémon evolutions (particularly if they rely on a quite specific method, if its a level based evolution or other widely spread evolution method they were most likely migrated correctly)
- Pokémon babies forms
- Type colors
- Items effects (listing them would be quite long, but look for things like repel steps, hp healing amounts or status healing as can all be customized in Studio instead of needing to add their effects in a script)
- Trainers' Pokémon (There is a lot more customization options in Studio, you may want to look back at your trainers and tweak them)
- Zones and Groups (Studio doesn't work the same way as Essentials in terms of map encounters, look at your migrated zones and groups to adapt them to your needs)

These are the main data that can potentially be set to a value you do not want, but to be sure, you should probably check the other data. If you have any question or you are not sure if something is normal or a bug, feel free to contact the dev in the resource post on the [Pokémon workshop discord server](https://discord.gg/0noB0gBDd91B8pMk)

# Credits
Developer:
- Aelysya

Beta testing projects:
- Felicity (project Repudiation)
- Appletun's Apples (project Hibernation)
