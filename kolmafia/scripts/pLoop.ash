script "pLooper";
notify Coolfood;

import <ProfitTracking.ash>
import <TimeTracking.ash>
import <ptrack.ash>

/*
Script dependencies
garbo (with user prompts off)
CONSUME.ash
ptrack.ash
combo
*/

/*
Supports perming skills + using big book of every skill if karma > 2000
Ensures 1 pizza of legend each (some Cs scripts pull)
uses glenn's golden dice for garbo
uses lodestone for garbo
asdon fuels
*/


/*
Hard requirements
- Clan VIP
- stooper
- All CBB recipes
- If own left-hand man, a lavaco lamp
*/

/*
prusias_ploop_homeClan - string
prusias_ploop_garboWorkshed - string
prusias_ploop_workshedItemAfterLoopScript - string
prusias_ploop_garboPostAscendWorkshed - string
prusias_ploop_ascendScript - string
prusias_ploop_loopScriptClan - string - clan to use only while the configured loop script runs. if empty, stays in the home clan
prusias_ploop_nightcapOutfit - string
prusias_ploop_preAscendGarden - string of packet of seeds name. if empty, skips
prusias_ploop_ascensionType - int
prusias_ploop_moonId - int
prusias_ploop_classId - string - class name, exact, lowercase
prusias_ploop_astralPet - string - item name, exact
prusias_ploop_astralDeli - string - item name, exact
prusias_ploop_ascendGender - int
prusias_ploop_yachtzeeOption = boolean

prusias_ploop_pathId = int
prusias_ploop_preAscendAcquireList = string,string...
prusias_ploop_preAscendClanStashAcquireList = string,string...

prusias_ploop_alwaysPvP = boolean
prusias_ploop_leg1PvP = boolean
prusias_ploop_disableOffhandRemarkable = boolean
prusias_ploop_neverPvpOverride = boolean

prusias_ploop_detectHalloween = boolean
prusias_ploop_tryDmtDupe = boolean
prusias_ploop_dmtDupeItemId = int
prusias_ploop_postRunMoonTune = int
prusias_ploop_optOutSmoking = boolean
prusias_ploop_smokeMessage = string - message for pre-ascension campfire smokes. if empty, uses the default
prusias_ploop_nightcapMPA = int
prusias_ploop_garboAdditionalArg = string - requested Garbo arguments; farmingMethod cowo is omitted for a run when The Coral Corral is unavailable
prusias_ploop_runBigPieAsdonPrefuel = boolean - opt in to post-run Asdon pie prefueling for all Garbo modes; defaults to false; pies must cost less than 2500 meat, with caps of 1100 fuel and 20000 meat in pie value per day/ascension; Garbo chooses the driving effect and tops off
prusias_ploop_breakfastAdditionalScript = string
prusias_ploop_preAscendSoybeanFutures = boolean - spend Interesting Coins on soybean futures before ascending, since the coins do not survive the Astral Gash
prusias_ploop_postDayScript = string
prusias_ploop_raffleTicketCount = int - raffle tickets to have bought by the end of the day, 0 or empty to buy none
prusias_ploop_alwaysSteelOrgan = boolean
prusias_ploop_openKnobTreasury = boolean

Smol specific
prusias_ploop_smolNoSaladFork = boolean
prusias_ploop_smolNoFrostyMug = boolean

11037 Leagues Under The Sea specific
prusias_ploop_utsCodpieceCheck = boolean - fill The Eternity Codpiece with five unblemished pearls before ascending into path 55, buying any that are missing at up to valueOfAdventure * 10 * 2 meat each
prusias_ploop_leg1Pearlo = boolean - opt in to profitable wineglass pearl farming before ascension

Script state tracking - must be skipped by save/load
_prusias_ploop_breakfastAugmented - completion flag for supplemental breakfast, reset on rollover and ascension
_prusias_ploop_leg1PearloStage - daily checkpoint for resuming Leg 1 pearl farming
_prusias_ploop_leg1PearloTurns - daily adventure budget from pearlo's profit report
prusias_ploop_leg1PearloFishyBackup - saved pipe count, retrieval settings, and Lutz flag; no leading underscore so interrupted cleanup can recover the pipe after rollover
_prusias_ploop_got_steel_organ - Only used on leg 2 and reset on ascension/day
_prusias_ploop_cowoAsdonPrefuel - date/ascension, accounted fuel, and reserved pie value shared by all Garbo modes; legacy name retained to preserve interrupted prefueling limits
prusias_ploop_takenFromClanStashItems - items that need to be returned to stash
prusias_ploop_clanStashTakenFrom - return to right clan
prusias_ploop_validSaves - list of valid save states
prusias_ploop_runNextCompletedChunk - last chunk completed by ploop run next
prusias_ploop_runNextDate - date the run next tracker was last updated
*/
boolean [string] skip_props = {
    "_prusias_ploop_breakfastAugmented": true,
    "_prusias_ploop_leg1PearloStage": true,
    "_prusias_ploop_leg1PearloTurns": true,
    "prusias_ploop_leg1PearloFishyBackup": true,
    "_prusias_ploop_got_steel_organ": true,
    "_prusias_ploop_cowoAsdonPrefuel": true,
    "prusias_ploop_takenFromClanStashItems": true,
    "prusias_ploop_clanStashTakenFrom": true,
    "prusias_ploop_validSaves": true,
    "prusias_ploop_runNextCompletedChunk": true,
    "prusias_ploop_runNextDate": true
};

// Path IDs that require steel organ pull
boolean[string] steel_organ_paths = {
    "49": true, //smol
    "41": true, //you, robot
    "51": true, //ih8u
    "55": true //11037 Leagues Under The Sea
};

record PloopChunk { string name; string description; };

PloopChunk[int] PLOOP_CHUNKS = {
    new PloopChunk("breakfast", "Sets up leg 1 and runs breakfast."),
    new PloopChunk("leg1garbo", "Runs Garbo before ascension."),
    new PloopChunk("preascend", "Prepares organs and spends remaining adventures and PvP fights before ascension."),
    new PloopChunk("ascend", "Enters Valhalla and starts the configured ascension."),
    new PloopChunk("loopscript", "Runs the configured loop script."),
    new PloopChunk("postscriptprep", "Finishes the run and sets up leg 2."),
    new PloopChunk("leg2garbo", "Pulls from storage and runs Garbo after ascension."),
    new PloopChunk("nightcap", "Nightcaps and records the end-of-day ptrack breakpoint.")
};

string filePrefix = "data/ploop/saves/";

string ploopHelpSectionHtml(string title) {
    return "<br><font color=teal><b>" + entity_encode(title) + "</b></font>";
}

void printPloopHelpSection(string title) {
    print_html(ploopHelpSectionHtml(title));
}

string ploopHelpValue(string propertyName) {
    string value = get_property(propertyName);
    if (value == "") return "<font color=teal><b>(empty)</b></font>";
    return "<b>" + entity_encode(value) + "</b>";
}

string ploopHelpEntryHtml(string label, string description) {
    string detail = description == "" ? "" : "<div style=\"margin-left: 16px; margin-top: 0; margin-bottom: 0;\">" + description + "</div>";
    return "<b>" + entity_encode(label) + "</b>" + detail;
}

string ploopHelpOptionHtml(string propertyName, string description) {
    string preference = "<code>" + entity_encode(propertyName) + "</code> = " + ploopHelpValue(propertyName);
    string detail = description == "" ? "" : "<div style=\"margin-left: 16px; margin-top: 0; margin-bottom: 0;\">" + description + "</div>";
    return preference + detail;
}

void listSaves() {
    printPloopHelpSection("Current saves");
    if (get_property("prusias_ploop_validSaves") == "") {
        print_html("<font color=teal><b>(empty)</b></font>");
        return;
    }
    foreach x, it in get_property("prusias_ploop_validSaves").split_string('(?<!\\\\)(, |,)') {
        print_html(ploopHelpEntryHtml(it, ""));
    }
}

void listInitArgs() {
    string [int] properties = {
        "prusias_ploop_pathId",
        "prusias_ploop_ascensionType",
        "prusias_ploop_moonId",
        "prusias_ploop_classId",
        "prusias_ploop_ascendGender",
        "prusias_ploop_astralPet",
        "prusias_ploop_astralDeli",
        "prusias_ploop_ascendScript",
        "prusias_ploop_homeClan",
        "prusias_ploop_loopScriptClan",
        "prusias_ploop_garboWorkshed",
        "prusias_ploop_workshedItemAfterLoopScript",
        "prusias_ploop_garboPostAscendWorkshed",
        "prusias_ploop_garboAdditionalArg",
        "prusias_ploop_preAscendGarden",
        "prusias_ploop_utsCodpieceCheck",
        "prusias_ploop_nightcapOutfit",
        "uts_postLoopFarmPearls",
        "uts_postLoopPrepCodpiece",
        "uts_postLoopRunOutEagleBanish",
        "uts_usePilsners"
    };
    print_html("<b>Current init preferences</b>");
    foreach index, propertyName in properties {
        if (propertyName == "prusias_ploop_pathId") printPloopHelpSection("Ascension");
        if (propertyName == "prusias_ploop_homeClan") printPloopHelpSection("Clans");
        if (propertyName == "prusias_ploop_garboWorkshed") printPloopHelpSection("Garbo and worksheds");
        if (propertyName == "prusias_ploop_preAscendGarden") printPloopHelpSection("Pre-ascension and nightcap");
        if (propertyName == "uts_postLoopFarmPearls") printPloopHelpSection("UnderTheSea");
        print_html(ploopHelpOptionHtml(propertyName, ""));
    }
}

void saveAllProperties(string fileName) {
    string [string] save_to_file;
    
    boolean [string] prop_map =  get_all_properties("prusias_ploop_", false);
    foreach prop, val in prop_map {
        if (skip_props contains prop) {
            continue;
        }
        string value = get_property(prop);
        save_to_file[prop] = value;
    }

    string realFileName = filePrefix + fileName + ".txt";
    if (map_to_file(save_to_file, realFileName)) {
        boolean alreadyExists = false;
        foreach x, it in get_property("prusias_ploop_validSaves").split_string('(?<!\\\\)(, |,)') {
            if (it == fileName) {
                if (!user_confirm("Save state of name " + fileName + " already exists. Are you sure you want to overwrite?") ) {
                    abort("State Save canceled by user.");
                }
                print("Overwriting the save state named " + fileName, "red");
                alreadyExists = true;
                break;
            }
        }
        if (!alreadyExists) {
            if (get_property("prusias_ploop_validSaves") == "") {
                set_property("prusias_ploop_validSaves", fileName);
            } else {
                set_property("prusias_ploop_validSaves", get_property("prusias_ploop_validSaves") + "," + fileName);
            }
        }
        print("Ploop save state successfully created in /" + realFileName, "teal");
    } else {
        print("Error, file was not saved.");
    }
    
}

void loadAllProperties(string fileName) {
    string realFileName = filePrefix + fileName + ".txt";
    string [string] prop_map;
    file_to_map(realFileName, prop_map);
    foreach prop, val in prop_map {
        if (skip_props contains prop) continue;
        print("Setting " + prop + " to " + val);
        set_property(prop, val);
    }
    print("Ploop save state successfully loaded.", "teal");
}

string ploopChunkHelpHtml() {
    buffer output;
    output.append(ploopHelpSectionHtml("Run individual phases") + "<br>");
    output.append("Run phases individually to pause for manual tasks between them.<br>");
    output.append(ploopHelpEntryHtml("ploop run next", "Runs today's next phase in order. <b>prusias_ploop_runNextCompletedChunk</b> stores the last phase completed by this command."));
    foreach index, chunk in PLOOP_CHUNKS {
        output.append(ploopHelpEntryHtml("ploop run " + chunk.name, chunk.description));
    }
    output.append(ploopHelpEntryHtml("ploop knob", "Opens Cobb's Knob Treasury on demand. Requires level 5 and the council's map. Farms the encryption key in the Outskirts if needed (about 11 turns)."));
    return output.to_string();
}

void printPloopChunkHelp() {
    print_html(ploopChunkHelpHtml());
}

boolean isPloopChunk(string name) {
    foreach index, chunk in PLOOP_CHUNKS
        if (chunk.name == name) return true;
    return false;
}

int getPloopChunkIndex(string name) {
    foreach index, chunk in PLOOP_CHUNKS
        if (chunk.name == name) return index;
    return -1;
}

void resetRunNextTrackerIfNeeded() {
    if (get_property("prusias_ploop_runNextDate") != today_to_string()) {
        set_property("prusias_ploop_runNextDate", today_to_string());
        set_property("prusias_ploop_runNextCompletedChunk", "");
    }
}

void ploopHelper() {
    buffer output;
    output.append("<b>pLooper</b>" + "<br>");
    output.append("pLooper runs Garbo, ascends, runs your ascension script, then runs Garbo again.<br>");
    output.append(ploopHelpSectionHtml("Setup - run one init first") + "<br>");
    output.append(ploopHelpEntryHtml("ploop init", "Prompts for a path ID and sets up paths without a dedicated init."));
    output.append(ploopHelpEntryHtml("ploop csinit", "Sets up Community Service (path 25)."));
    output.append(ploopHelpEntryHtml("ploop smolinit", "Sets up A Shrunken Adventurer am I (path 49)."));
    output.append(ploopHelpEntryHtml("ploop utsinit", "Sets up 11037 Leagues Under The Sea (path 55) with <b>underthesea</b>. Run <b>underthesea sim</b> first to check your setup."));
    output.append(ploopHelpEntryHtml("ploop roboinit", "Sets up You, Robot (path 41)."));
    output.append(ploopHelpEntryHtml("ploop listInitArgs", "Shows current values for preferences set by the init commands."));
    output.append(ploopHelpSectionHtml("Run a full day") + "<br>");
    output.append(ploopHelpEntryHtml("ploop fullday", "Runs the full loop from breakfast to nightcap."));
    output.append(ploopHelpSectionHtml("Run individual phases") + "<br>");
    output.append(ploopHelpEntryHtml("ploop run next", "Runs the next phase tracked for today."));
    output.append(ploopHelpEntryHtml("ploop run help", "Lists individual phases and what they do."));
    output.append(ploopHelpSectionHtml("Pre-ascension acquisition lists") + "<br>");
    output.append(ploopHelpEntryHtml("ploop clearacquirelist", "Clears the custom pre-ascension acquisition list."));
    output.append(ploopHelpEntryHtml("ploop addacquirelist (item name)", "Adds an item to acquire before ascension. Names can contain spaces."));
    output.append(ploopHelpEntryHtml("ploop clearclanstashlist", "Clears the pre-ascension clan stash list."));
    output.append(ploopHelpEntryHtml("ploop addclanstashlist (item name)", "Adds an item to pull before ascension if it's in the clan stash. Names can contain spaces."));
    output.append(ploopHelpSectionHtml("Save and load configurations") + "<br>");
    output.append(ploopHelpEntryHtml("ploop listSaves", "Lists saved configurations from <b>prusias_ploop_validSaves</b>. Manually deleted saves can still appear here."));
    output.append(ploopHelpEntryHtml("ploop save (name)", "Saves your current configuration under this name."));
    output.append(ploopHelpEntryHtml("ploop load (name)", "Loads the named configuration."));
    output.append(ploopHelpSectionHtml("Optional preferences") + "<br>");
    output.append(ploopHelpEntryHtml("ploop options", "Shows optional preferences and their current values."));
    print_html(output.to_string());
    cli_execute("pUpdates check ploop");
}

void optional_help_info() {
    // Print one HTML block: Mafia adds a line break after each print_html call,
    // which otherwise creates an empty line after each indented description.
    buffer output;
    output.append("<b>pLooper options</b><br>Each preference shows its current value. (empty) means no value is set.<br>");
    output.append(ploopHelpSectionHtml("Garbo and loop script") + "<br>");
    output.append(ploopHelpOptionHtml("prusias_ploop_garboAdditionalArg", "Extra Garbo arguments, separated by spaces. Init replaces them with your selections. All inits offer cockroach targeting, and <b>utsinit</b> also offers cowo farming."));
    output.append(ploopHelpOptionHtml("prusias_ploop_loopScriptClan", "Clan to use while the ascension script runs. pLoop returns to your home clan afterward. Leave empty to stay there. <b>utsinit</b> prompts for this and recommends <b>Bonus Adventures From Hell</b>."));
    output.append(ploopHelpSectionHtml("Custom scripts") + "<br>");
    output.append(ploopHelpOptionHtml("prusias_ploop_breakfastAdditionalScript", "CLI command to run after supplemental breakfast. Runs again after rollover or ascension."));
    output.append(ploopHelpOptionHtml("prusias_ploop_postDayScript", "CLI command to run before the end-of-day ptrack breakpoint."));
    output.append(ploopHelpSectionHtml("Ascension and nightcap") + "<br>");
    output.append(ploopHelpOptionHtml("prusias_ploop_preAscendSoybeanFutures", "Set to <b>true</b> to buy as many soybean futures as your Interesting Coins cover before ascension. The food carries over, and the Astral Gash takes any coins left over."));
    output.append(ploopHelpOptionHtml("prusias_ploop_alwaysSteelOrgan", "Set to <b>true</b> to try for a steel organ on any path."));
    output.append(ploopHelpOptionHtml("prusias_ploop_openKnobTreasury", "Set to <b>true</b> to open Cobb's Knob Treasury after the ascension script. Farms the encryption key if needed (about 11 turns)."));
    output.append(ploopHelpOptionHtml("prusias_ploop_postRunMoonTune", "Moon sign ID to tune to after the run if your hewn moon-rune spoon can still tune. Leave empty to skip."));
    output.append(ploopHelpOptionHtml("prusias_ploop_nightcapMPA", "Meat per adventure to pass to CONSUME for nightcap. Empty or <b>false</b> uses <b>valueOfAdventure</b>."));
    output.append(ploopHelpOptionHtml("prusias_ploop_leg1Pearlo", "Set to <b>true</b> to farm profitable pearls before ascending. Requires an equippable Drunkula's wineglass. pLoop saves Fishy and budgets turns for the expanded diet. Off by default. Once past the first Garbo pass, the route continues if disabled."));
    output.append(ploopHelpOptionHtml("prusias_ploop_smokeMessage", "Pre-ascension campfire message. Leave empty for the default. Limit 100 characters. <b>%n</b> becomes the smoke number and <b>&amp;</b> becomes <b>and</b>."));
    output.append(ploopHelpOptionHtml("prusias_ploop_optOutSmoking", "Set to <b>true</b> to skip the four pre-ascension campfire smokes at Getaway Campsite."));
    output.append(ploopHelpOptionHtml("prusias_ploop_disableOffhandRemarkable", "Set to <b>true</b> to skip casting Offhand Remarkable during nightcap setup."));
    output.append(ploopHelpSectionHtml("PvP") + "<br>");
    output.append(ploopHelpOptionHtml("prusias_ploop_alwaysPvP", "Set to <b>true</b> to break the Hippy Stone and run PvP at nightcap. Your items can be looted over rollover."));
    output.append(ploopHelpOptionHtml("prusias_ploop_leg1PvP", "Set to <b>true</b> to break the Hippy Stone before leg 1 Garbo, opening you to looting earlier in the day."));
    output.append(ploopHelpOptionHtml("prusias_ploop_neverPvpOverride", "Set to <b>true</b> to skip pLoop's PvP actions."));
    output.append(ploopHelpOptionHtml("prusias_ploop_useAdvForPvpAtBoxingDaycare", "Set to <b>true</b> to spend 1 adventure on PvP fights at Boxing Daycare."));
    output.append(ploopHelpSectionHtml("Other automation") + "<br>");
    output.append(ploopHelpOptionHtml("prusias_ploop_detectHalloween", "Set to <b>true</b> to run <b>freecandy</b> on Halloween. Install and configure it first."));
    output.append(ploopHelpOptionHtml("prusias_ploop_tryDmtDupe", "Set to <b>true</b> for Machine Elf duplication. Your ascension script can use up to 5 DMT free fights. pLoop finishes any remaining fights and takes the choice."));
    output.append(ploopHelpOptionHtml("prusias_ploop_dmtDupeItemId", "ID of the item to duplicate."));
    output.append(ploopHelpOptionHtml("prusias_ploop_raffleTicketCount", "Daily raffle ticket target, including tickets already bought today. Tickets cost 10,000 Meat each. <b>0</b> or empty skips buying."));
    output.append(ploopHelpSectionHtml("A Shrunken Adventurer am I") + "<br>");
    output.append(ploopHelpOptionHtml("prusias_ploop_smolNoSaladFork", "Set to <b>true</b> to skip preparing a salad fork before ascending."));
    output.append(ploopHelpOptionHtml("prusias_ploop_smolNoFrostyMug", "Set to <b>true</b> to skip preparing a frosty mug before ascending."));
    output.append(ploopHelpSectionHtml("11037 Leagues Under The Sea") + "<br>");
    output.append(ploopHelpOptionHtml("prusias_ploop_utsCodpieceCheck", "Set to <b>true</b> to fill The Eternity Codpiece with five unblemished pearls before each path 55 ascension. Mounted pearls carry into the run. Missing pearls can cost up to <b>20 × valueOfAdventure</b> Meat each."));
    print_html(output.to_string());
}

string homeClanPrompt = "What is your home clan? The script will ensure you are in this clan before running.";
string gardenPrompt = "What garden do you want to setup before ascending into valhalla? Provide exact name of seeds. Leave blank to ignore.";
string moonPrompt = "Provide the integer id of the moon you want to ascend into. 1-Mongoose;2-Wallaby;3-Vole;4-Platypus;5-Opossum;6-Marmot;7-Wombat;8-Blender;9-Packrat";
string classPrompt = "Provide the exact class name you want to ascend into. Ex: Seal Clubber";
string astralPetPrompt = "Provide the exact name of the astral pet you want to take from valhalla. https://kol.coldfront.net/thekolwiki/index.php/Pet_Heaven";
string astralDeliPrompt = "Provide the exact name of the astral deli item you want to take. astral hot dog dinner;astral six-pack;carton of astral energy drinks";
string genderPrompt = "Provide the integer corresponding to the gender you wish to be! 1 for male, 2 for female.";
string ascendScriptPrompt = "What script should be run after exiting valhalla to finish your run (ex: instantsccs, loopsmol, etc.)? Type just as you would type in the CLI to run the script.";
string loopScriptClanPrompt = "What clan should pLooper join while running your loop script? Bonus Adventures From Hell is recommended for underthesea. Sets prusias_ploop_loopScriptClan. Leave blank to stay in your home clan. Will return to home clan after loop script is done.";
string workshedPrompt = "Leg 1 workshed for Garbo (after rollover, before ascending). Enter the exact item name or leave blank for no swap. Setup asks for Leg 2 later.";
string leg2WorkshedPrompt = "Leg 2 workshed for Garbo (after ascending and finishing your loop script). Enter the exact item name or leave blank for no swap.";
string nightcapOutfitPrompt = "Provide the exact name of the nightcap outfit you will be using.";
string pathIdPrompt = "What path id should be used?";

void promptBasicInitProperties() {
    set_property("prusias_ploop_homeClan", user_prompt(homeClanPrompt));
    set_property("prusias_ploop_garboWorkshed", user_prompt(workshedPrompt));
    set_property("prusias_ploop_preAscendGarden", user_prompt(gardenPrompt));
}

void promptAscensionProperties(string moonQuestion) {
    set_property("prusias_ploop_moonId", user_prompt(moonQuestion));
    set_property("prusias_ploop_classId", user_prompt(classPrompt));
    set_property("prusias_ploop_astralPet", user_prompt(astralPetPrompt));
    set_property("prusias_ploop_astralDeli", user_prompt(astralDeliPrompt));
    set_property("prusias_ploop_ascendGender", user_prompt(genderPrompt));
}

void promptGarboInitProperties(boolean offerCowo) {
    print("This init replaces prusias_ploop_garboAdditionalArg with your selections below. Existing additional arguments will be cleared; declining all options leaves it empty.", "teal");
    string additionalArgs = "";
    if (offerCowo && user_confirm("Use Garbo's cowo farming method (farmingMethod cowo) to farm a higher base Meat Sea zone? If you are low shiny or don't know what cowo is, choose No to skip.")) {
        additionalArgs = "farmingMethod cowo";
    }
    if (user_confirm("Use cockroach as Garbo's copy target (target=\"cockroach\")? You need to own PirateRealm and have lots of copying IotMs. If you don't understand this option, choose No to skip.")) {
        if (additionalArgs != "") additionalArgs += " ";
        additionalArgs += `target="cockroach"`;
    }
    set_property("prusias_ploop_garboAdditionalArg", additionalArgs);
}

void promptPostAscensionProperties(boolean offerCowo) {
    set_property("prusias_ploop_garboPostAscendWorkshed", user_prompt(leg2WorkshedPrompt));
    set_property("prusias_ploop_nightcapOutfit", user_prompt(nightcapOutfitPrompt));
    promptGarboInitProperties(offerCowo);
}

void init() {
    set_property("prusias_ploop_pathId", user_prompt(pathIdPrompt));
    promptBasicInitProperties();
    set_property("prusias_ploop_ascensionType", user_prompt("What type of ascension are you doing? 1-Casual, 2-Normal (or Softcore), 3-Hardcore."));
    promptAscensionProperties(moonPrompt);
    set_property("prusias_ploop_ascendScript", user_prompt(ascendScriptPrompt));
    promptPostAscensionProperties(false);
}

void csInit() {
    promptBasicInitProperties();
    set_property("prusias_ploop_ascensionType", user_prompt("What type of ascension are you doing? 1-Casual, 2-Normal (or Softcore), 3-Hardcore."));
    promptAscensionProperties(moonPrompt);
    set_property("prusias_ploop_ascendScript", user_prompt(ascendScriptPrompt));
    promptPostAscensionProperties(false);
    set_property("prusias_ploop_pathId", "25");
}

void smolInit() {
    promptBasicInitProperties();
    promptAscensionProperties(moonPrompt);
    set_property("prusias_ploop_ascendScript", user_prompt(ascendScriptPrompt));
    promptPostAscensionProperties(false);
    set_property("prusias_ploop_pathId", "49");
    set_property("prusias_ploop_ascensionType", "2");
}

void utsInit() {
    promptBasicInitProperties();
    set_property("prusias_ploop_ascensionType", user_prompt("What type of ascension are you doing? 1-Casual, 2-Normal (or Softcore), 3-Hardcore."));
    promptAscensionProperties(moonPrompt);
    set_property("prusias_ploop_ascendScript", "underthesea");
    set_property("uts_postLoopFarmPearls", "true");
    set_property("uts_postLoopPrepCodpiece", "true");
    set_property("uts_postLoopRunOutEagleBanish", "true");
    set_property("uts_usePilsners", "true");
    set_property("prusias_ploop_loopScriptClan", user_prompt(loopScriptClanPrompt));
    set_property("prusias_ploop_utsCodpieceCheck", user_confirm("Should pLooper guarantee filling The Eternity Codpiece with five unblemished pearls before ascending? Missing pearls may be bought according to the configured price ceiling.") ? "true" : "false");
    promptPostAscensionProperties(true);
    set_property("prusias_ploop_pathId", "55");
}

void robotInit() {
    promptBasicInitProperties();
    promptAscensionProperties("Provide the integer id of the moon you want to ascend into (LoopRobot wants Vole). 1-Mongoose;2-Wallaby;3-Vole;4-Platypus;5-Opossum;6-Marmot;7-Wombat;8-Blender;9-Packrat");
    set_property("prusias_ploop_ascendScript", "looprobot");
    set_property("prusias_ploop_workshedItemAfterLoopScript", user_prompt("After LoopRobot, fill the empty workshed. Enter the exact item name or leave blank. The Leg 2 Garbo swap is a separate prompt."));
    promptPostAscensionProperties(false);
    set_property("prusias_ploop_pathId", "41");
    set_property("prusias_ploop_ascensionType", "2");
}

void shrugAT() {
    cli_execute("shrug Stevedave's Shanty of Superiority");
    cli_execute("shrug Power Ballad of the Arrowsmith");
    cli_execute("shrug The Moxious Madrigal");
    cli_execute("shrug The Magical Mojomuscular Melody");
    cli_execute("shrug Cletus's Canticle of Celerity");
    cli_execute("shrug Jackasses' Symphony of Destruction");
    cli_execute("shrug Brawnee's Anthem of Absorption");
}

boolean needToAcquireItem(item x) {
    print("Testing ownership of " + x);
    return (available_amount(x) + closet_amount(x) + storage_amount(x) == 0);
}

string saucegeyserAll(int round, monster opp, string text) {
    if (have_skill($skill[Saucegeyser]) && my_mp() >= 24) {
        return "skill Saucegeyser";
    } else {
        return "attack";
    }
}

boolean isHalloween() {
    return get_property("prusias_ploop_detectHalloween").to_boolean() && holiday() == "Halloween";
}

void restoreHalloweenMPA() {
    if (get_property("prusias_ploop_preHalloweenMPA") != "" && get_property("valueOfAdventure").to_int() == 9999) {
        set_property("valueOfAdventure", get_property("prusias_ploop_preHalloweenMPA"));
        set_property("prusias_ploop_preHalloweenMPA", "");
    }
}

void unequipFamiliarItem(familiar fam) {
    if (!have_familiar(fam)) {
        return;
    }

    familiar currentFamiliar = my_familiar();
    use_familiar(fam);
    equip($slot[familiar], $item[none]);
    use_familiar(currentFamiliar);
}

void returnClanStashItems() {
    if (get_property("prusias_ploop_takenFromClanStashItems") == "") {
        return;
    }

    cli_execute("/whitelist " + get_property("prusias_ploop_clanStashTakenFrom"));
    cli_execute("outfit Birthday Suit");
    unequipFamiliarItem($familiar[Left-Hand Man]);
    unequipFamiliarItem($familiar[Disembodied Hand]);
    unequipFamiliarItem($familiar[Fancypants Scarecrow]);

    foreach x, it in get_property("prusias_ploop_takenFromClanStashItems").split_string('(?<!\\\\)(, |,)') {
        it = replace_all(create_matcher(`\\\\`, it), "");
        item acquisitionItem = it.to_item();
        cli_execute("refresh stash");
        if (acquisitionItem != $item[none] && !needToAcquireItem(acquisitionItem)) {
            print("Returning " + acquisitionItem.to_string());
            cli_execute("stash put " + acquisitionItem.to_string());
        }
    }

    set_property("prusias_ploop_takenFromClanStashItems", "");
    set_property("prusias_ploop_clanStashTakenFrom", "");
    print("Clan stash items returned to stash");
}

void appendItemToProperty(item it, string propertyName) {
    string itemName = replace_all(create_matcher(",", it.to_string()), "\\\\,");
    string currentValue = get_property(propertyName);
    if (currentValue == "") {
        set_property(propertyName, itemName);
    } else {
        set_property(propertyName, currentValue + ", " + itemName);
    }
}

void addClanStashAcquiredTracking(string itemToAdd) {
    set_property("prusias_ploop_clanStashTakenFrom", get_clan_name());
    item it = itemToAdd.to_item();
    if (it == $item[none]) {
        print("Not a valid item. Double check spelling", "red");
    } else {
        cli_execute("stash take " + it);
        appendItemToProperty(it, "prusias_ploop_takenFromClanStashItems");
    }
}

void dmt_dupe() {
    //prusias_ploop_tryDmtDupe = boolean
    //prusias_ploop_dmtDupeItemId = int
    if (get_property("prusias_ploop_tryDmtDupe").to_boolean() != true || get_property("prusias_ploop_dmtDupeItemId") == "") {
        return;
    }
    print("PLOOP_DUPE: attempting to dmt dupe");
    item itemToDupe = get_property("prusias_ploop_dmtDupeItemId").to_int().to_item();
    cli_execute("acquire 1 " + itemToDupe.to_string());

    print(get_property("lastDMTDuplication"));
    print(get_property("encountersUntilDMTChoice"));
    if (get_property("lastDMTDuplication").to_int() != my_ascensions()) {
        // We can duplicate
        set_property('choiceAdventure1119', '4');
        string itemChoice = "1&iid=" + get_property("prusias_ploop_dmtDupeItemId");
        set_property('choiceAdventure1125', itemChoice);
        cli_execute("/fam machine elf");
        
        while (get_property("encountersUntilDMTChoice").to_int() != 0){
            adv1($location[The Deep Machine Tunnels], -1, "saucegeyserAll");
        }
        int juneCleaverEncounters = get_property("_juneCleaverEncounters").to_int();
        adv1($location[The Deep Machine Tunnels], -1, "");
        if (juneCleaverEncounters != get_property("_juneCleaverEncounters").to_int()) {
            print("PLOOP_DUPE: Cleaver adv likely overrode DMT NC. Rerunning DMT");
            cli_execute("uneffect beaten up");
            adv1($location[The Deep Machine Tunnels], -1, "");
        } 
        set_property('choiceAdventure1119', '1');
    } else
    {
        print("PLOOP_DUPE: Dupe already used");
    }
    if (get_property("lastDMTDuplication").to_int() != my_ascensions()) {
        print("PLOOP_DUPE: duplicate failed somehow","red");
    } else {
	print("PLOOP_DUPE: duplicate success");
	}
}

void prepPvp() {
    if (get_property("prusias_ploop_neverPvpOverride").to_boolean()) {
        print("PLOOP: PVP is disabled by user preference", "red");
        return;
    }
    //break stone
    if (!hippy_stone_broken())
        visit_url("peevpee.php?action=smashstone&pwd&confirm=on", true);
    //get fights
    if (item_amount($item[School of Hard Knocks Diploma]) > 0 && !get_property("_hardKnocksDiplomaUsed").to_boolean()) {
        cli_execute("use School of Hard Knocks Diploma");
    }
	
    item mirror = $item[punching mirror];
    if (available_amount(mirror) > 0 && !get_property("_punchingMirrorUsed").to_boolean()) {
        use(1, mirror);
    } else if (stash_amount(mirror) > 0 && !get_property("_punchingMirrorUsed").to_boolean()) {
	cli_execute("stash take punching mirror");
        use(1, mirror);
	cli_execute("stash put punching mirror");
    }
	
    item fire = $item[CSA fire-starting kit];
    if (item_amount(fire) > 0 && !get_property("_fireStartingKitUsed").to_boolean()) {
        set_property("choiceAdventure595", "1");
        use(1, fire);
    }
    //only do if haven't done yet today
    if (get_property("prusias_ploop_useAdvForPvpAtBoxingDaycare").to_boolean() && my_adventures() > 0 && !get_property("_daycareFights").to_boolean()) {
        visit_url("place.php?whichplace=town_wrong&action=townwrong_boxingdaycare");
        run_choice(3); // go to daycare
        if (get_property("_daycareRecruits").to_int() < 1) {
        run_choice(1); // recruit toddlers for 100 meat
        //run_choice(1); // recruit toddlers for 1000 meat
        }
        if (get_property("_daycareGymScavenges").to_int() < 1) {
        run_choice(2); // free scavenge
        }
        if (hippy_stone_broken()) {
            print("Getting fights", "teal");
        run_choice(4); // get PvP fights (costs an adventure)
        }
        run_choice(5); // exit daycare
        run_choice(4); // exit lobby
    }
}

void runPloopBreakfast(boolean forceMafiaBreakfast) {
    if (forceMafiaBreakfast || !get_property("breakfastCompleted").to_boolean()) {
        pBreakfast();
    }

    string completedProperty = "_prusias_ploop_breakfastAugmented";
    if (get_property(completedProperty).to_boolean()) {
        return;
    }

    //double ice
    if (!to_boolean(get_property("_aprilShower")))
        cli_execute("shower ice");

    //big book
    if (get_property("bankedKarma").to_int() > 2000 && available_amount($item[The Big Book of Every Skill]) > 0) 
        use(1, $item[The Big Book of Every Skill]);

    // mayam calendar
	if (item_amount($item[Mayam Calendar]) > 0) {
		if (get_property("_mayamSymbolsUsed") == "") {
			// yam battery
			cli_execute("mayam rings yam lightning yam clock");
			// stuffed yam stinkbomb
			cli_execute("mayam rings vessel yam cheese explosion");
			// remainder
			if (have_familiar($familiar[chest mimic])) {
				// xp for chest mimic
				use_familiar($familiar[chest mimic]);
				cli_execute("mayam rings fur meat eyepatch yam");
			} else {
				// free rests for cincho/mp
				cli_execute("mayam rings chair meat eyepatch yam");
			}
			
		}
	}

    //pirates bellow
    if (have_skill($skill[Pirate Bellow]) && !get_property("_pirateBellowUsed").to_boolean()) {
        use_skill(1, $skill[Pirate Bellow]);
    }

    // pref for custom script
    if (get_property("prusias_ploop_breakfastAdditionalScript") != "") {
        cli_execute(get_property("prusias_ploop_breakfastAdditionalScript"));
    }

    set_property(completedProperty, true);
}

boolean useCombo(boolean countFreeWalks) {
    if (my_adventures() <= 0) return false;

    if (available_amount($item[Beach Comb]) == 0 && available_amount($item[driftwood beach comb]) == 0) {
        int sandprice = mall_price($item[Grain of sand]) * 3;
        int combPrice = mall_price($item[Piece of driftwood]);
        if (sandprice > 0 && combPrice > 0 && my_adventures() > combPrice / sandprice) {
            cli_execute("buy 1 piece of driftwood");
            cli_execute("use piece of driftwood");
        }
    }
    if (available_amount($item[Beach Comb]) > 0 || available_amount($item[driftwood beach comb]) > 0) {
        // Combo counts free walks toward its requested combs.
        int freeWalks = countFreeWalks ? max(0, 11 - get_property("_freeBeachWalksUsed").to_int()) : 0;
        return cli_execute("combo " + (my_adventures() + freeWalks));
    }
    return false;
}

boolean tryInstallInductionOven() {
    item oven = $item[warbear induction oven];
    if (get_property("_workshedItemUsed").to_boolean() || get_workshed() == oven || available_amount(oven) == 0) {
        return false;
    }

    string errorMessage = catch {
        print("Installing warbear induction oven before cooking legend pizzas", "teal");
        use(1, oven);
    };
    if (errorMessage != "") {
        print("WARNING_PLOOP: Failed to install warbear induction oven: " + errorMessage, "yellow");
        return false;
    }

    return get_workshed() == oven;
}

boolean haveAllLegendFoods() {
    return available_amount($item[calzone of legend]) > 0
        && available_amount($item[deep dish of legend]) > 0
        && available_amount($item[pizza of legend]) > 0;
}

void makeLegendFoodIfNeeded(item food) {
    if (available_amount(food) == 0) {
        cli_execute("make " + food);
    }
}

void prepareLegendFoods() {
    int ingredientPrice = 2 * (
        mall_price($item[Yeast of Boris])
        + mall_price($item[Vegetable of Jarlsberg])
        + mall_price($item[St. Sneaky Pete's Whey])
    );

    if (ingredientPrice >= 50 * get_property("valueOfAdventure").to_int()) {
        if (!haveAllLegendFoods()) {
            print("ERROR_PLOOP: T4 CBB foods (pizza of legend, deep dish of legend, calzone of legend) are outside of safe price range. Maybe mall shenanigans?", "red");
            print("Acquire 1 of each and run ploop again to continue.", "red");
            abort();
        }
        return;
    }

    tryInstallInductionOven();
    makeLegendFoodIfNeeded($item[calzone of legend]);
    makeLegendFoodIfNeeded($item[deep dish of legend]);
    makeLegendFoodIfNeeded($item[pizza of legend]);
}

//Gems mounted in The Eternity Codpiece survive the Astral Gash, and 11037 Leagues Under
//The Sea (path 55) blocks pulling the quest items, so five unblemished pearls left in the
//codpiece is how a run starts with the pearls the Nautical Seaceress needs. Top the
//codpiece up before we ascend. Pearls are still farmable in run (one per day from each of
//the five Sea zones), so coming up short warns rather than stopping the loop.
void utsCodpieceCheck() {
    if (!get_property("prusias_ploop_utsCodpieceCheck").to_boolean()) return;
    if (get_property("prusias_ploop_pathId").to_int() != 55) return;

    item pearl = $item[unblemished pearl];
    item cod = $item[The Eternity Codpiece];
    //mafia opens the decorate page out of your inventory, so a codpiece sitting in the
    //closet, in storage or in the clan stash cannot be mounted into. Check what we can
    //actually reach, not what we merely own, or we spend the meat and mount nothing.
    if (item_amount(cod) == 0 && !have_equipped(cod) && closet_amount(cod) > 0)
        take_closet(1, cod);
    if (item_amount(cod) == 0 && !have_equipped(cod) && can_interact() && storage_amount(cod) > 0)
        take_storage(1, cod);
    if (item_amount(cod) == 0 && !have_equipped(cod)) {
        print("ERROR_PLOOP: prusias_ploop_utsCodpieceCheck is set but The Eternity Codpiece is not in your inventory.", "red");
        print_html("Set <b>prusias_ploop_utsCodpieceCheck</b> to false to skip this step");
        abort();
    }

    //mafia learns the codpiece slots from api.php, so resync before counting what is in them
    cli_execute("refresh status");
    int mounted = 0;
    foreach s in $slots[codpiece1, codpiece2, codpiece3, codpiece4, codpiece5] {
        if (equipped_item(s) == pearl)
            mounted = mounted + 1;
    }
    if (mounted >= 5) {
        print("Codpiece already holds five unblemished pearls.", "blue");
        return;
    }

    int needed = 5 - mounted;
    print(`Codpiece holds {mounted} unblemished pearl(s); filling the other {needed} slot(s).`, "blue");

    //never pay for a pearl we already own somewhere else
    if (item_amount(pearl) < needed && closet_amount(pearl) > 0)
        take_closet(min(needed - item_amount(pearl), closet_amount(pearl)), pearl);
    if (item_amount(pearl) < needed && can_interact() && storage_amount(pearl) > 0)
        take_storage(min(needed - item_amount(pearl), storage_amount(pearl)), pearl);

    if (item_amount(pearl) < needed) {
        int toBuy = needed - item_amount(pearl);
        //farming a pearl in run costs about ten turns, so a pearl is worth ten adventures.
        //Buy at up to twice that.
        int maxPrice = get_property("valueOfAdventure").to_int() * 10 * 2;
        //mall_price caches with no age limit, and this decides whether to spend six figures,
        //so insist on a price from within the last day
        int price = mall_price(pearl, 1.0);
        if (maxPrice <= 0) {
            print("ERROR_PLOOP: valueOfAdventure is 0 or less, so there is no ceiling to buy unblemished pearls under.", "red");
        } else if (price <= 0) {
            print("ERROR_PLOOP: no mall price for unblemished pearl, so none were bought.", "red");
        } else if (price >= maxPrice) {
            print(`Unblemished pearls are {price} meat, at or over the {maxPrice} meat ceiling (valueOfAdventure * 10 * 2), so none were bought.`, "red");
            //nothing can be listed for less than it autosells for, so a low valueOfAdventure
            //puts this ceiling out of reach no matter what the market is doing
            if (maxPrice <= autosell_price(pearl))
                print(`No unblemished pearl can be listed below the {autosell_price(pearl)} meat it autosells for, so that ceiling can never be met. Raise valueOfAdventure if you want this to buy.`, "red");
        } else {
            //buy gets the ceiling too, so a price that moves mid purchase cannot beat it.
            //Its limit is inclusive, hence the -1 to stay strictly under the ceiling.
            buy(toBuy, pearl, maxPrice - 1);
        }
    }

    foreach s in $slots[codpiece1, codpiece2, codpiece3, codpiece4, codpiece5] {
        if (equipped_item(s) == pearl)
            continue;
        //equip() acquires a missing gem itself, at mafia's autoBuyPriceLimit rather than
        //ours, so it must never be called without a pearl already in hand
        if (item_amount(pearl) == 0)
            break;
        //a displaced gem goes back to inventory, but an untradeable one that Hagnk's will
        //not hand back (baseball diamond) is out of reach for the whole run, so say so loudly
        if (equipped_item(s) != $item[none])
            print("Prying " + equipped_item(s).to_string() + " out of the codpiece to make room for a pearl.", "red");
        equip(s, pearl);
    }

    mounted = 0;
    foreach s in $slots[codpiece1, codpiece2, codpiece3, codpiece4, codpiece5] {
        if (equipped_item(s) == pearl)
            mounted = mounted + 1;
    }
    if (mounted < 5)
        print(`ERROR_PLOOP: only {mounted} of 5 codpiece slots hold an unblemished pearl. Ascending anyway; the rest have to be farmed in run.`, "red");
    else
        print("Codpiece loaded: five unblemished pearls will carry into the run.", "blue");
}

//Interesting Coins are quest items, so the Astral Gash takes every one still in inventory.
//Soybean futures are the sink: the food carries into the next run's storage. Spending the
//whole balance costs nothing, because a new run hands back 4 coins on its own and they earn
//interest at rollover, so leg 1 of a day is normally holding the 7 one purchase costs.
void preAscendSoybeanFutures() {
    if (!get_property("prusias_ploop_preAscendSoybeanFutures").to_boolean()) return;

    coinmaster shop = $coinmaster[Spend your Interesting Coins];
    item coin = $item[Interesting Coin];
    item futures = $item[soybean futures];

    int coins = item_amount(coin);
    if (coins == 0) return;

    if (!is_accessible(shop)) {
        print(`Holding {coins} Interesting Coin(s) but the coin shop is shut: {inaccessible_reason(shop)}`, "red");
        return;
    }

    //take the cost off the shop row rather than hardcoding 7, so a repricing cannot make us
    //ask for more soybean futures than the coins in hand actually pay for
    int cost = sell_price(shop, futures);
    if (cost <= 0) {
        print("ERROR_PLOOP: no Interesting Coin price for soybean futures, so none were bought.", "red");
        return;
    }

    int toBuy = coins / cost;
    if (toBuy == 0) {
        print(`Holding {coins} Interesting Coin(s), short of the {cost} one soybean futures costs, so they are lost at the Gash.`, "red");
        return;
    }

    int before = item_amount(futures);
    buy(shop, toBuy, futures);
    int bought = item_amount(futures) - before;
    if (bought < toBuy)
        print(`ERROR_PLOOP: bought {bought} of {toBuy} soybean futures; {item_amount(coin)} Interesting Coin(s) are still on hand and will be lost at the Gash.`, "red");
    else
        print(`Bought {bought} soybean futures for {bought * cost} Interesting Coins.`, "blue");
}

void pre_ascend_pulls() {
    //Acquire Potential CS Pulls
    if (get_property("prusias_ploop_ascensionType") == "" || get_property("prusias_ploop_ascensionType").to_int() < 3) {
        prepareLegendFoods();

        if (!have_skill($skill[summon clip art]) && needToAcquireItem($item[borrowed time]))
            cli_execute("acquire 1 borrowed time");
        if (needToAcquireItem($item[non-Euclidean angle]))
            cli_execute("acquire 1 non-Euclidean angle");
        if (needToAcquireItem($item[abstraction: category]))
            cli_execute("acquire 1 abstraction: category");
        if (needToAcquireItem($item[tobiko marble soda]))
            cli_execute("acquire 1 tobiko marble soda");
        if (needToAcquireItem($item[wasabi marble soda]))
            cli_execute("acquire 1 wasabi marble soda");
        if (!get_property("stenchAirportAlways").to_boolean() && needToAcquireItem($item[one-day ticket to Dinseylandfill]))
            cli_execute("acquire 1 one-day ticket to Dinseylandfill");
    }

    //potential smol pulls
    if (get_property("prusias_ploop_pathId") == "49") {
        prepareLegendFoods();

        if (!get_property("prusias_ploop_smolNoSaladFork").to_boolean()) {
            retrieve_item(1, $item[3323]);//salad fork
            if (available_amount($item[3323]) == 0) {
                print("ERROR_PLOOP: Failed to acquire salad fork", "red");
                print_html("You can also set <b>prusias_ploop_smolNoSaladFork</b> to true to skip this step");
                abort();
            }
                
        }
        if (!get_property("prusias_ploop_smolNoFrostyMug").to_boolean()) {
            retrieve_item(1, $item[3324]);//frosty mug
            if (available_amount($item[3324]) == 0) {
                print("ERROR_PLOOP: Failed to acquire frosty mug", "red");
                print_html("You can also set <b>prusias_ploop_smolNoFrostyMug</b> to true to skip this step");
                abort();
            }
                
        }
        
    }

    //Interesting Coins do not survive the Gash, so turn them into food that does
    preAscendSoybeanFutures();

    //pearls for 11037 Leagues Under The Sea, smuggled in via The Eternity Codpiece
    utsCodpieceCheck();

    //custom acquisition list
    foreach x, it in get_property("prusias_ploop_preAscendAcquireList").split_string('(?<!\\\\)(, |,)') {
        it = replace_all(create_matcher(`\\\\`, it), "");
        item acquisitionItem = it.to_item();
        if (acquisitionItem != $item[none] && needToAcquireItem(acquisitionItem)) {
            print("Acquiring " + acquisitionItem.to_string());
            cli_execute("acquire 1 " + acquisitionItem.to_string());
        }
    }
    //clan stash acquisition list prusias_ploop_preAscendClanStashAcquireList
    foreach x, it in get_property("prusias_ploop_preAscendClanStashAcquireList").split_string('(?<!\\\\)(, |,)') {
        it = replace_all(create_matcher(`\\\\`, it), "");
        item acquisitionItem = it.to_item();
        cli_execute("refresh stash");
        if (acquisitionItem != $item[none] && needToAcquireItem(acquisitionItem) && stash_amount(acquisitionItem) > 0) {
            print("Acquiring from stash " + acquisitionItem.to_string());
            addClanStashAcquiredTracking(acquisitionItem.to_string());
        }
    }
}

string defaultSmokeMessage = "Thanks Prusias for writing Ploop!";

//mafia splits the choiceAdventure1394 value on & to find the form fields, so an & in the
//message would break out of it. Everything else gets URL encoded for us and survives as typed.
//The game itself cuts the signal off at 100 characters. Warning here rather than in
//setSmokeMessage so a message set by hand or restored from a save gets flagged too.
string smokeMessage(int smokeNum) {
    string message = get_property("prusias_ploop_smokeMessage");
    if (message == "") {
        message = `{smokeNum} {defaultSmokeMessage}`;
    } else {
        message = message.replace_string("%n", `{smokeNum}`);
    }
    message = message.replace_string("&", "and");
    if (message.length() > 100) {
        print("Smoke signals are capped at 100 characters, so this message gets cut short.", "red");
        message = message.substring(0, 100);
    }
    return message;
}

void ascendToValhalla() {
    pre_ascend_pulls();

    useCombo(false);

    if (!get_property('thoth19_event_list').contains_text("wineglassDone") && !get_property('thoth19_event_list').contains_text("preAscend"))
        addBreakpoint("preAscend");

    if (get_property("getawayCampsiteUnlocked").to_boolean() && get_property("prusias_ploop_optOutSmoking").to_lower_case() != "true") {
        //smoke tax
        int tryNumSmokes = 4;
        if (item_amount($item[stick of firewood]) < tryNumSmokes) {
            cli_execute("buy " + tryNumSmokes + " stick of firewood @250");
        }

        int smoke = 0;
        tryNumSmokes = min(tryNumSmokes,item_amount($item[stick of firewood]));
        cli_execute("acquire " + tryNumSmokes + " stick of firewood");
        while(item_amount($item[stick of firewood]).to_boolean() && smoke < tryNumSmokes) {
		smoke = smoke + 1;
            catch {
                cli_execute("acquire campfire smoke");
                set_property("choiceAdventure1394", "1&message=" + smokeMessage(smoke));
                use(1,$item[campfire smoke]);
            } 
        }
    }


    int deli = get_property("prusias_ploop_astralDeli").to_item().to_int();
	int pet = get_property("prusias_ploop_astralPet").to_item().to_int();
    int type = 2;
    if (get_property("prusias_ploop_ascensionType") != "") {
        type = get_property("prusias_ploop_ascensionType").to_int();
    }
	int moonId = get_property("prusias_ploop_moonId").to_int();//wallaby
    int pathId = 25;//cs
    if (get_property("prusias_ploop_pathId") != "") {
        pathId = get_property("prusias_ploop_pathId").to_int();
    }
	
	int classId = get_property("prusias_ploop_classId").to_class().to_int();
    int gender = get_property("prusias_ploop_ascendGender").to_int(); //1 boy, 2 girl


	if (get_property("csServicesPerformed").split_string(",").count() == 11) {
		print("attempting to enter valhalla");
		visit_url("council.php",false,true);
		visit_url("ascend.php?pwd&action=ascend&confirm=on&confirm2=on",true,true);
	}
	else if (get_property("kingLiberated").to_boolean()) {
		print("attempting to enter valhalla");
		//abort("need url of non-CS ascension location");
		visit_url("",false,true);
		visit_url("ascend.php?pwd&action=ascend&confirm=on&confirm2=on",true,true);
	} else {
        print("attempt to ascend failed");
    }

	if (!visit_url("charpane.php").contains_text("Astral Spirit"))
		abort("failed to get to valhalla");

	//visit_url("afterlife.php?realworld=1",false,true);
	visit_url("afterlife.php?action=pearlygates",false,true);

	//buy things
	if (deli > 0)
		visit_url(`afterlife.php?action=buydeli&whichitem={deli}`,true,true);
	if (pet > 0)
		visit_url(`afterlife.php?action=buyarmory&whichitem={pet}`,true,true);
    //perm things
    //hc perm all the skills; assumes enough karma to cover costs
    string permAll = "sc";
    if (permAll == "hc" || permAll == "sc") {
        buffer buf = visit_url("afterlife.php?place=permery");
        string [int] hcsc = xpath(buf,'//form[@action="afterlife.php"]//input[@name="action"]/@value');
        string [int] perm = xpath(buf,'//form[@action="afterlife.php"]//input[@name="whichskill"]/@value');
        int size = perm.count();
        if (size > 0) {
            print (`Perming all {permAll.to_upper_case()} skills:`,"blue");
            for i from 0 to size-1
                if (hcsc[i] == `{permAll}perm`)
                    visit_url(`afterlife.php?action={permAll}perm&whichskill={perm[i]}`,true,true);
        }
    }
	//ascend
	visit_url(`afterlife.php?pwd&action=ascend&confirmascend=1&whichsign={moonId}&gender={gender}&whichclass={classId}&whichpath={pathId}&asctype={type}&nopetok=1&noskillsok=1&lamesignok=1&lamepatok=1`,true,true);
    if (pathId == 49 || pathId == 41 || pathId == 55) {
        //55 is 11037 Leagues Under The Sea; it opens on a NC that must be cleared
        //manually before the ascension script can start
        visit_url('main.php'); while (handling_choice()) {run_choice(1);}
    }

}

void preCSrun() {
    cli_execute("garden pick");
    if (get_property("prusias_ploop_preAscendGarden") != "")
	if (available_amount(get_property("prusias_ploop_preAscendGarden").to_item()) > 0)
            cli_execute("use " + get_property("prusias_ploop_preAscendGarden"));
    use_familiar($familiar[Stooper]);
    if (available_amount($item[tiny stillsuit]) > 0 || have_equipped($item[tiny stillsuit]))
        cli_execute("drink stillsuit distillate");
    else
        cli_execute("CONSUME ALL VALUE " + (get_property("valueOfAdventure").to_int()));

    

    print("Remember to spend your pvp fights", "fuchsia");
}

boolean yachtzeeAccess() {
    if (can_adventure($location[The Sunken Party Yacht])) return true;
    if (get_property("prusias_ploop_yachtzeeOption").to_boolean()
    && (item_amount($item[jurassic parka]) > 0 || have_equipped($item[jurassic parka]))
    && item_amount($item[Cincho de Mayo]) > 0
    && item_amount($item[Clara's bell]) > 0) {
        if (get_property("_spikolodonSpikeUses").to_int() == 0
        && get_property("_claraBellUsed").to_boolean() == false) {
            if (item_amount($item[one-day ticket to Spring Break Beach]) == 0) 
                cli_execute("buy 1 one-day ticket to Spring Break Beach @600000");
            if (item_amount($item[one-day ticket to Spring Break Beach]) == 0) 
                return false;
            cli_execute("use 1 one-day ticket to Spring Break Beach");
            return true;
        }
    }
    return false;
}

boolean garboDigitizeMismatch() {
    string macroError = get_property("lastMacroError").to_lower_case();
    return macroError.contains_text("expected a digitized ")
        && macroError.contains_text("but encountered something else");
}

void runGarboWithDigitizeRecovery(string command) {
    int maxRecoveries = 2;
    int recoveries = 0;

    while (true) {
        // Do not mistake an error from an earlier Garbo invocation for this failure.
        set_property("lastMacroError", "");
        boolean succeeded = false;
        string errorMessage = catch {
            succeeded = cli_execute(command);
        };
        boolean digitizeMismatch = garboDigitizeMismatch();
        if (succeeded && errorMessage == "" && !digitizeMismatch) return;

        if (!digitizeMismatch) {
            abort("ERROR_PLOOP: Garbo failed: " + (errorMessage != "" ? errorMessage : command));
        }
        if (recoveries >= maxRecoveries) {
            abort("ERROR_PLOOP: Garbo Digitize mismatch persisted after " + maxRecoveries + " recovery attempts.");
        }
        if (handling_choice()) {
            abort("ERROR_PLOOP: Garbo Digitize recovery stopped because a choice is open.");
        }

        recoveries = recoveries + 1;
        print("Recovering Garbo Digitize mismatch (" + recoveries + "/" + maxRecoveries + ").", "orange");
        // Finish only the interrupted fight; do not launch another adventure.
        string recoveryError = catch {
            if (current_round() > 0) run_combat("attack; repeat");
        };
        if (recoveryError != "") {
            abort("ERROR_PLOOP: Garbo recovery combat failed: " + recoveryError);
        }
        if (current_round() > 0 || in_multi_fight() || choice_follows_fight() || handling_choice()) {
            abort("ERROR_PLOOP: Garbo recovery left combat or a choice unfinished. Resolve it before rerunning pLoop.");
        }

        boolean refreshed = false;
        string refreshError = catch {
            refreshed = cli_execute("refresh all");
        };
        if (!refreshed || refreshError != "") {
            abort("ERROR_PLOOP: Could not refresh after Garbo Digitize recovery: " + refreshError);
        }
        print("Retrying Garbo: " + command, "orange");
    }
}

void garboUsage(string x, boolean allowYachtzee, boolean skipDiet) {
	print("trying to run garbo","teal");
    if (have_familiar($familiar[Patriotic Eagle])) {
        if (get_property("_citizenZone") != "Barf Mountain") {
            if (have_effect($effect[citizen of a zone]) > 0) {
                print("uneffecting eagle zone");
                cli_execute("uneffect citizen of a zone");
            }
            set_property("_citizenZone", "");
        }
    }
    shrugAT();
    if (!get_property("_essentialTofuUsed").to_boolean()) {
        if (item_amount($item[essential tofu]) == 0)
            cli_execute("buy 1 essential tofu @" + (get_property("valueOfAdventure").to_int() * 4));
        if (item_amount($item[essential tofu]) >= 1) {
            cli_execute("use essential tofu");
        }
    }
    if (!get_property("_glennGoldenDiceUsed").to_boolean() && available_amount($item[Glenn's golden dice]) > 0)
        cli_execute("use Glenn's golden dice");
    if (!get_property("_lodestoneUsed").to_boolean() && available_amount($item[lodestone]) > 0)
        cli_execute("use lodestone");
    // Let users opt in to candy dishes with the garbo_candydish preference.
    string garboString = "garbo";
    if (allowYachtzee && yachtzeeAccess())
        garboString += " yachtzeechain";
    if (x != "")
        garboString += " " + x;
    string additionalArgs = get_property("prusias_ploop_garboAdditionalArg");
    if (skipDiet) {
        // Replace any saved diet flag while preserving quoted argument values.
        matcher dietFlag = create_matcher("(\"[^\"]*\"|'[^']*')|(?<!\\S)!?nodiet(?:\\s+|$)", additionalArgs);
        additionalArgs = replace_all(dietFlag, "$1");
        additionalArgs = replace_all(create_matcher("^\\s+|\\s+$", additionalArgs), "");
        garboString += " nodiet";
    }
    if (additionalArgs != "") garboString += " " + additionalArgs;
    //Ploop's init sets this exact argument. Keep the saved setting for later legs.
    if (garboString.contains_text(" farmingMethod cowo")) {
        if (!get_property("corralUnlocked").to_boolean()) visit_url("seafloor.php");
        if (!can_adventure($location[The Coral Corral])) {
            garboString = garboString.replace_string(" farmingMethod cowo", "");
            print("PLOOP: The Coral Corral is unavailable; skipping cowo for this Garbo run and using Barf Mountain.", "blue");
        }
    }
    print("Running garbo with " + garboString);
    runGarboWithDigitizeRecovery(garboString);
}

void garboUsage(string x) {
    garboUsage(x, true, false);
}

void prefuelAsdonWithBigPies() {
    if (!get_property("prusias_ploop_runBigPieAsdonPrefuel").to_boolean()) return;
    if (get_workshed() != $item[Asdon Martin keyfob (on ring)] || !can_interact()) return;

    //262 dinner rolls average 1179 fuel. Stay below that, and value even owned
    //pies against the meat cap. Garbo chooses the driving effect and tops off.
    int fuelCap = 1100;
    int meatCap = 20000;
    int piePriceLimit = 2500; //Exclusive; applies to owned pies as well as purchases.
    int maxPieFuel = 200;
    item pie = $item[pie man was not meant to eat];
    //Keep the existing state key so switching modes does not reset the limits.
    string stateProperty = "_prusias_ploop_cowoAsdonPrefuel";
    string scope = today_to_string() + "-" + my_ascensions();
    int accountedFuel = max(0, get_fuel());
    int committedValue = 0;
    string [int] saved = get_property(stateProperty).split_string(":");
    if (count(saved) == 3 && saved[0] == scope) {
        //Previously supplied fuel still counts after Garbo spends it on a buff.
        accountedFuel = max(accountedFuel, saved[1].to_int());
        committedValue = max(0, saved[2].to_int());
    }
    set_property(stateProperty, scope + ":" + accountedFuel + ":" + committedValue);

    //Use the maximum yield, so even a lucky pie cannot exceed the fuel cap.
    while (accountedFuel + maxPieFuel <= fuelCap) {
        int price = mall_price(pie, 0.0);
        if (price >= piePriceLimit) {
            print("Asdon prefueling stopped: pie price is " + price
                + " meat; it must be below " + piePriceLimit + ". Leaving the rest to Garbo.", "blue");
            return;
        }
        if (price <= 0 || price > meatCap - committedValue) {
            print("Asdon prefueling stopped at the pie value limit or an unavailable price; leaving the rest to Garbo.", "blue");
            return;
        }

        int fuelBefore = get_fuel();
        int accountedBefore = accountedFuel;
        //Reserve both allowances BEFORE buying or converting. If execution is
        //interrupted, a rerun retains this reservation rather than paying twice.
        accountedFuel = accountedFuel + maxPieFuel;
        committedValue = committedValue + price;
        set_property(stateProperty, scope + ":" + accountedFuel + ":" + committedValue);

        if (item_amount(pie) == 0 && buy(1, pie, min(price, piePriceLimit - 1)) != 1) {
            print("Asdon prefueling could not buy a pie within its price limit; leaving the rest to Garbo.", "orange");
            return;
        }
        boolean fueled = cli_execute("asdonmartin fuel 1 pie man was not meant to eat");
        int fuelAdded = get_fuel() - fuelBefore;
        if (!fueled || fuelAdded <= 0) {
            print("Asdon prefueling did not confirm a fuel increase; keeping the reservation and leaving the rest to Garbo.", "orange");
            return;
        }

        //A confirmed conversion lets us replace its reservation with the actual
        //yield. Never release the pie value reservation on retries or failures.
        accountedFuel = accountedBefore + fuelAdded;
        set_property(stateProperty, scope + ":" + accountedFuel + ":" + committedValue);
    }
    print("Asdon prefueling finished: " + get_fuel() + " fuel in the tank; "
        + committedValue + " of " + meatCap + " meat in pie value committed. Garbo handles the effect and any top-off.", "blue");
}

void postRunNoGarbo() {
    shrugAT();
    cli_execute("hagnk all");
    cli_execute("refresh all");
    //ensure beach access
    if (!(available_amount($item[134]) > 0 || available_amount($item[4770]) > 0 || available_amount($item[4769]) > 0 || available_amount($item[6775]) > 0)) {
        retrieve_item(1,$item[bitchin' meatcar]);
    }
    // Rerun Mafia breakfast after pulling items from storage and opening beach access.
    runPloopBreakfast(true);

    if (my_mp() < 250 && item_amount($item[10058]) > 0 && get_property("prusias_ploop_pathId").to_int() != 49
        && (item_amount($item[magical sausage]) > 0 || item_amount($item[magical sausage casing]) > 0))
        cli_execute("eat magical sausage");
    dmt_dupe();
    //rain-doh
    if (item_amount($item[can of Rain-Doh]) > 0) {
        cli_execute("use can of Rain-Doh");
    }
    unequipFamiliarItem($familiar[Left-Hand Man]);
    

    //Cover paths that skip the steel organ or run leg 2 directly. The shared
    //prefuel ledger remembers any fuel supplied before the organ quest.
    prefuelAsdonWithBigPies();
    if (available_amount($item[5553]) > 0) {
        //rain-doh
        cli_execute("use can of rain-doh");
    }

    //shrug all AT songs that are not limited
    cli_execute('shrug stevedave');
}

void postRun(string x) {
    postRunNoGarbo();

    if (get_property("prusias_ploop_garboPostAscendWorkshed") == "")
        garboUsage(x);
    else
        garboUsage(`workshed="` + get_property("prusias_ploop_garboPostAscendWorkshed") + `" ` + x);
    
}

void equipLeftHandManForNightcap() {
    use_familiar($familiar[Left-Hand Man]);
    equip($slot[familiar], $item[none]);
    if (item_amount($item[8437]) > 0) //green
        equip($slot[familiar], $item[8437]);
    if (item_amount($item[8435]) > 0) //red
        equip($slot[familiar], $item[8435]);
    if (item_amount($item[8436]) > 0) //blue
        equip($slot[familiar], $item[8436]);
}

void nightcapFamiliar() {
    if (!get_property("prusias_ploop_disableOffhandRemarkable").to_boolean() 
            && have_skill($skill[7464]) && !get_property("_aug13Cast").to_boolean() && get_property("_augSkillsCast").to_int() < 5) {
        use_skill($skill[7464]);
    }
    if (have_effect($effect[Offhand Remarkable]) > 0
            && have_familiar($familiar[Left-Hand Man])) {
        equipLeftHandManForNightcap();
    } else if (have_familiar($familiar[Trick-or-Treating Tot])) {
        use_familiar($familiar[Trick-or-Treating Tot]);
        equip( $slot[familiar], $item[none]);
        cli_execute("acquire li'l unicorn costume");
        equip( $slot[familiar], $item[li'l unicorn costume]);
    } else if (have_familiar($familiar[Left-Hand Man])) {
        equipLeftHandManForNightcap();
    } else if (item_amount($item[solid shifting time weirdness]) > 0) {
        equip($slot[familiar], $item[solid shifting time weirdness]);
    }
}

void nightcap() {
    //Handle maids
    int profitOffset = 100;
    string page = visit_url("campground.php?action=inspectdwelling");
    if (!page.contains_text("Clockwork Maid") && !page.contains_text("Meat Butler") && !page.contains_text("Meat Maid")) {
        if (available_amount($item[Clockwork Maid]) > 0 || buy(1, $item[Clockwork Maid], (8 * get_property("valueOfAdventure").to_int()) - profitOffset) == 1) {
            use(1, $item[Clockwork Maid]);
            print("Installed Clockwork Maid", "green");
        } else if (available_amount($item[Meat Butler]) > 0 || buy(1, $item[Meat Butler], (4 * get_property("valueOfAdventure").to_int()) - profitOffset) == 1) {
            use(1, $item[Meat Butler]);
            print("Installed Meat Butler", "lime");
        } else if (available_amount($item[Meat Maid]) > 0 || buy(1, $item[Meat Maid], (4 * get_property("valueOfAdventure").to_int()) - profitOffset) == 1) {
            use(1, $item[Meat Maid]);
            print("Installed Meat Maid", "lime");
        } else {
            print("Clockwork Maid, Meat Butler, and Meat Maid both outside price range.", "red");
        }
    } else {
        print("We already have a Maid or Butler installed", "red");
    }
    //stooper
    use_familiar($familiar[Stooper]);
    if (my_inebriety() < inebriety_limit()) {
        if (available_amount($item[tiny stillsuit]) > 0 || have_equipped($item[tiny stillsuit]))
            cli_execute("drink stillsuit distillate");
        else
            cli_execute("CONSUME ALL VALUE " + (get_property("valueOfAdventure").to_int()));
    }
    if (get_property("prusias_ploop_alwaysPvP").to_boolean()) {
        prepPvp();
        if (get_property("prusias_ploop_neverPvpOverride").to_boolean()) {
            print("PLOOP: PVP is disabled by user preference. Skipping pvp script", "red");
        } else {
            cli_execute("pvp_mab");
        }
        use_familiar($familiar[Stooper]);
    }
	//burning cape
	if (available_amount($item[burning cape]) > 0) {
		cli_execute("equip burning cape");
    } else if (mall_price( $item[ Burning Newspaper ] ) < (get_property("valueOfAdventure").to_int())) {
        if (available_amount($item[burning newspaper]) == 0) {
            cli_execute("buy 1 burning newspaper @" + get_property("valueOfAdventure").to_int());
        }
        cli_execute("make burning cape");
        cli_execute("equip burning cape");
    }

    // Nightcap outfit
    foreach key,piece in outfit_pieces(get_property("prusias_ploop_nightcapOutfit")) {
        if (piece == $item[stinky cheese diaper] && available_amount($item[stinky cheese diaper]) == 0) {
            cli_execute("fold stinky cheese diaper");
        } else if (piece == $item[loathing legion knife] && available_amount($item[loathing legion knife]) == 0) {
            cli_execute("fold loathing legion knife");
        }
    }
    cli_execute("outfit " + get_property("prusias_ploop_nightcapOutfit"));
	if (available_amount($item[burning cape]) > 0) 
		cli_execute("equip burning cape");
    
    //nightcapping
    //cli_execute("CONSUME ALL NIGHTCAP VALUE " + get_property("valueOfAdventure").to_int());
    if (my_inebriety() <= inebriety_limit()) {
        if (get_property("prusias_ploop_nightcapMPA") == "" || get_property("prusias_ploop_nightcapMPA").to_string().to_lower_case() == "false") {
            cli_execute("CONSUME ALL NIGHTCAP VALUE " + (get_property("valueOfAdventure").to_int()));
        } else {
            cli_execute("CONSUME ALL NIGHTCAP VALUE " + get_property("prusias_ploop_nightcapMPA").to_int());
        }
    } else {
        nightcapFamiliar();
        print("ERROR_PLOOP: Nightcap started overdrunk at " + my_inebriety() + "/" + inebriety_limit());
        abort();
    }
    nightcapFamiliar();
    
    
    
}

void beforeScriptRuns() {
    if (!needToAcquireItem($item[S.I.T. Course Completion Certificate]) && !get_property("_sitCourseCompleted").to_boolean()) {
        if (get_property("choiceAdventure1494") == "" || get_property("choiceAdventure1494") == "0")
            set_property("choiceAdventure1494","2");
        cli_execute("use S.I.T. Course Completion Certificate");
    }
}

void postAscendScriptCleanup() {
    if (get_property("prusias_ploop_garboAdditionalArg").contains_text(`target="cockroach"`) && have_effect($effect[Cowrruption]) >= 15) {
        cli_execute("uneffect Cowrruption");
    }
}

void acquireSteelOrganIfNeeded() {
    if (get_property("_prusias_ploop_got_steel_organ") == "true"
            || (!get_property("prusias_ploop_alwaysSteelOrgan").to_boolean()
                && !(steel_organ_paths contains get_property("prusias_ploop_pathId")))) {
        return;
    }

    cli_execute("hagnk all");
    cli_execute("refresh all");
    cli_execute("uneffect beaten up");
    print("Trying to get steel organ");
    if (my_adventures() < 15) {
        if (item_amount($item[astral six-pack]) > 0) {
            cli_execute("use astral six-pack");
        }
        if (item_amount($item[astral pilsner]) > 0) {
            cli_execute("cast ode to booze");
            cli_execute("drink astral pilsner");
        }
    }
    //Storage is already emptied. Give the steel organ script fuel for its bumper banish.
    prefuelAsdonWithBigPies();
    set_property("_prusias_ploop_got_steel_organ", "true");
    cli_execute("ploopgoals goal organ");
}

//can_adventure is already true while holding the key and the map, before the map is used
boolean knobOpen() {
    string quest = get_property("questL05Goblin");
    return quest != "" && quest != "unstarted" && quest != "started";
}

//The Treasury opens with the Knob: the Outskirts' encryption key plus the council's map.
//A new ascension resets the level 5 quest, so this runs once per loop.
void openKnobTreasury() {
    if (knobOpen()) {
        print("The Knob Treasury is already open.", "teal");
        return;
    }

    if (my_level() < 5) {
        print("ERROR_PLOOP: Opening the Knob Treasury needs level 5 for the council's map, but you are level " + my_level() + ".", "red");
        return;
    }
    if (get_property("questL05Goblin") == "unstarted") {
        visit_url("council.php");
    }
    if (item_amount($item[Cobb's Knob map]) == 0) {
        print("ERROR_PLOOP: No Cobb's Knob map, so the Knob Treasury was not opened.", "red");
        return;
    }

    print("Opening the Knob Treasury", "teal");
    item key = $item[Knob Goblin encryption key];
    if (item_amount(key) == 0 && my_adventures() < 11) {
        if (item_amount($item[astral six-pack]) > 0 && !cli_execute("use astral six-pack"))
            print("Could not open the astral six-pack.", "teal");
        if (item_amount($item[astral pilsner]) > 0 && my_inebriety() < inebriety_limit()) {
            if (!cli_execute("cast ode to booze"))
                print("Could not cast The Ode to Booze; drinking without it.", "teal");
            //drinksilent skips mafia's Ode confirm dialog
            if (!cli_execute("drinksilent 1 astral pilsner"))
                print("Could not drink an astral pilsner.", "teal");
        }
    }

    string[int] choices = {111: "3", 113: "2", 118: "1"};
    string[int] savedChoices;
    foreach choice, option in choices {
        savedChoices[choice] = get_property("choiceAdventure" + choice);
        set_property("choiceAdventure" + choice, option);
    }
    try {
        //the key is a delayed noncombat, so this repeats up to the cap.
        //The macro replaces whatever combat script is active, which may only
        //handle another script's monsters.
        int tries = 0;
        while (item_amount(key) == 0 && my_adventures() > 0 && tries < 25) {
            tries += 1;
            if (!adv1($location[The Outskirts of Cobb's Knob], -1, "attack; repeat;")) {
                break;
            }
        }
    } finally {
        foreach choice, option in savedChoices {
            set_property("choiceAdventure" + choice, option);
        }
    }

    if (item_amount(key) == 0) {
        print("ERROR_PLOOP: No Knob Goblin encryption key from The Outskirts of Cobb's Knob, so the Knob Treasury was not opened.", "red");
        return;
    }
    if (!use(1, $item[Cobb's Knob map]) || !knobOpen()) {
        print("ERROR_PLOOP: Could not open the Knob Treasury with Cobb's Knob map.", "red");
    }
}

void tunePostRunMoonIfNeeded() {
    if (get_property('moonTuned').to_boolean() || get_property("prusias_ploop_postRunMoonTune") == "") {
        return;
    }

    cli_execute('unequip hewn moon-rune spoon');
    if (item_amount($item[hewn moon-rune spoon]) > 0) {
        int postrunTuneMoon = get_property("prusias_ploop_postRunMoonTune").to_int();
        visit_url('inv_use.php?whichitem=10254&doit=96&whichsign='+postrunTuneMoon);
    }
}

void installPostLoopWorkshedIfNeeded() {
    if (!get_property("_workshedItemUsed").to_boolean()
            && get_property("prusias_ploop_workshedItemAfterLoopScript") != ""
            && get_workshed() == $item[none]) {
        cli_execute("use " + get_property("prusias_ploop_workshedItemAfterLoopScript"));
    }
}

void prepareForPostRun() {
    acquireSteelOrganIfNeeded();
    if (get_property("prusias_ploop_openKnobTreasury").to_boolean() && !knobOpen()) {
        openKnobTreasury();
    }
    tunePostRunMoonIfNeeded();
    returnClanStashItems();
    installPostLoopWorkshedIfNeeded();
}

boolean shouldRunPostRun() {
    return get_property('kingLiberated').to_boolean()
        && (my_inebriety() < inebriety_limit()
            || my_fullness() < fullness_limit()
            || my_spleen_use() < spleen_limit()
            || (my_adventures() > 0 && my_inebriety() <= inebriety_limit()));
}

void enableHalloweenMode() {
    if (!isHalloween() || get_property("valueOfAdventure").to_int() == 9999) {
        return;
    }

    set_property("prusias_ploop_preHalloweenMPA", get_property("valueOfAdventure"));
    set_property("valueOfAdventure", "9999");
}

boolean smolReadyForPrism() {
    string finalQuest = get_property("questL13Final");
    return get_property("prusias_ploop_pathId") == "49"
        && (finalQuest == "step12" || finalQuest == "step13" || finalQuest == "finished");
}

void runBreakfastPhase(boolean halloween) {
    if (get_property("ascensionsToday").to_int() != 0) {
        return;
    }

    if (!halloween
            && !get_property("prusias_ploop_neverPvpOverride").to_boolean()
            && (get_property("prusias_ploop_leg1PvP").to_boolean()
                || get_property("prusias_ploop_alwaysPvP").to_boolean())
            && !hippy_stone_broken()) {
        visit_url("peevpee.php?action=smashstone&pwd&confirm=on", true);
    }

    use_familiar($familiar[none]);
    runPloopBreakfast(false);
}

string leg1PearloStage = "_prusias_ploop_leg1PearloStage";
string leg1PearloTurns = "_prusias_ploop_leg1PearloTurns";
// Unlike daily checkpoints, this backup must survive rollover to get the pipe back.
string leg1PearloFishyBackup = "prusias_ploop_leg1PearloFishyBackup";

boolean leg1WineglassReady() {
    item glass = $item[Drunkula's wineglass];
    return (item_amount(glass) > 0 || have_equipped(glass)) && can_equip(glass);
}

boolean bringLeg1WineglassToInventory() {
    item glass = $item[Drunkula's wineglass];
    if (leg1WineglassReady()) return true;
    if (!can_equip(glass)) return false;
    if (closet_amount(glass) > 0) return take_closet(1, glass) && leg1WineglassReady();
    if (can_interact() && storage_amount(glass) > 0) return take_storage(1, glass) && leg1WineglassReady();
    return false;
}

void restoreLeg1PearloFishy() {
    string backup = get_property(leg1PearloFishyBackup);
    if (backup == "") return;
    string [int] saved = backup.split_string(";");
    if (saved.count() != 5) abort("ERROR_PLOOP: Invalid Leg 1 Fishy backup: " + backup);
    set_property("autoSatisfyWithCloset", saved[2]);
    set_property("autoSatisfyWithStorage", saved[3]);
    // Lutz resets at rollover. Never copy yesterday's used flag into today.
    if (saved[0] == today_to_string()) set_property("_skateBuff1", saved[4]);
    int missing = saved[1].to_int() - item_amount($item[fishy pipe]);
    if (missing > 0 && (!take_closet(missing, $item[fishy pipe])
            || item_amount($item[fishy pipe]) < saved[1].to_int())) {
        abort("ERROR_PLOOP: Could not restore the fishy pipe. The backup is still saved; finish any combat or choice and rerun pLoop.");
    }
    set_property(leg1PearloFishyBackup, "");
}

void runGarboSavingLeg1Fishy(string args, string nextStage) {
    item pipe = $item[fishy pipe];
    int copies = item_amount(pipe);
    set_property(leg1PearloFishyBackup, today_to_string() + ";" + copies
        + ";" + get_property("autoSatisfyWithCloset")
        + ";" + get_property("autoSatisfyWithStorage") + ";" + get_property("_skateBuff1"));
    try {
        if (copies > 0 && !put_closet(copies, pipe)) abort("ERROR_PLOOP: Could not protect the fishy pipe.");
        if (item_amount(pipe) > 0) abort("ERROR_PLOOP: A fishy pipe remains accessible before Garbo.");
        set_property("autoSatisfyWithCloset", "false");
        set_property("autoSatisfyWithStorage", "false");
        set_property("_skateBuff1", "true");
        garboUsage(args, nextStage == "initialDone", false);
        set_property(leg1PearloStage, nextStage);
    } finally {
        restoreLeg1PearloFishy();
    }
}

int leg1PearloBudget(string report) {
    // Mafia's CLI capture wraps colored report lines in HTML.
    report = entity_decode(replace_all(create_matcher("(?i)</?font\\b[^>]*>", report), ""));
    if (report.contains_text("overcapped beyond owned extenders")) return 0;
    // Pair each zone's estimated turns with its own verdict. An obtained pearl
    // can still be marked GO in the report, but can't be farmed again.
    matcher zones = create_matcher("(?m)^[ \\t]*--- [a-z]+ \\(([^\\r\\n]+)\\) ---[ \\t]*\\R"
        + "(?:(?![ \\t]*---)[^\\r\\n]*\\R)*?[ \\t]*res [^\\r\\n]*?([0-9]+) turns [^\\r\\n]*\\R"
        + "[ \\t]*costs:[^\\r\\n]*\\R[ \\t]*expected profit: [1-9][0-9,]* meat [^\\r\\n]*\\bGO[ \\t]*\\r?$", report);
    int turns = 0;
    while (zones.find()) {
        location zone = zones.group(1).to_location();
        if (zone != $location[none] && can_adventure(zone)) turns += zones.group(2).to_int();
    }
    return turns > 0 ? turns + 5 : 0;
}

boolean prepareLeg1Pearlo(boolean halloween) {
    string stage = get_property(leg1PearloStage);
    if (stage != "" && stage != "planned") return true;
    if (halloween || !get_property("kingLiberated").to_boolean()
            || !get_property("prusias_ploop_leg1Pearlo").to_boolean()
            || !bringLeg1WineglassToInventory()) {
        if (stage == "planned") set_property(leg1PearloStage, "");
        return false;
    }
    if (stage == "planned") return true;
    // The second pass owns its diet and turn floor. Garbo rejects duplicate args.
    string additional = get_property("prusias_ploop_garboAdditionalArg");
    if (create_matcher("(?i)(?:^|\\s)(?:!?nodiet(?:\\s|$)|turns(?:[=\\s]|$)|-?[0-9]+(?:\\s|$))", additional).find()) {
        print("Leg 1 pearlo: remove custom Garbo turns/nodiet arguments to let pLoop manage its limited pass.", "orange");
        return false;
    }
    string report;
    string errorMessage = catch {
        report = cli_execute_output("pearlo profit drunk overcapped !force");
    };
    int turns = leg1PearloBudget(report);
    if (errorMessage != "" || turns == 0) {
        print("Leg 1 pearlo: no profitable unfinished pearl confirmed; running normal Garbo.", "blue");
        if (errorMessage != "") print(errorMessage, "orange");
        return false;
    }
    set_property(leg1PearloTurns, turns);
    set_property(leg1PearloStage, "planned");
    print("Leg 1 pearlo: profitable in the wineglass report; saving Fishy for an estimated " + turns + " adventures including buffer.", "teal");
    return true;
}

void runLeg1GarboPhase(boolean halloween) {
    if (get_property("ascensionsToday").to_int() != 0) {
        return;
    }

    if (my_inebriety() <= inebriety_limit()
            && ((my_adventures() > 0 && my_familiar() != $familiar[Stooper])
                || get_property(leg1PearloStage) == "planned")) {
        if (halloween) {
            cli_execute("CONSUME ALL VALUE 10000");
            if (get_property("prusias_ploop_garboWorkshed") == "") {
                garboUsage("nobarf ascend");
            } else {
                garboUsage(`nobarf ascend workshed="` + get_property("prusias_ploop_garboWorkshed") + `"`);
            }
            cli_execute("freecandy");

            if (my_inebriety() < inebriety_limit()) {
                print("WARNING_PLOOP: Somehow consume + freecandy left empty liver", "red");
            }
        } else {
            string args = "ascend";
            if (get_property("prusias_ploop_garboWorkshed") != "" && !get_property("_workshedItemUsed").to_boolean())
                args += ` workshed="` + get_property("prusias_ploop_garboWorkshed") + `"`;
            if (prepareLeg1Pearlo(halloween)) {
                if (get_property(leg1PearloStage) == "planned") runGarboSavingLeg1Fishy(args, "initialDone");
            } else {
                garboUsage(args);
            }

            if (my_inebriety() < inebriety_limit()) {
                print("WARNING_PLOOP: Somehow garbo left empty liver", "red");
            }
        }
    }

    string breakpoint = halloween ? "leg1halloween" : "leg1garbo";
    if (!get_property('thoth19_event_list').contains_text(breakpoint)) {
        addBreakpoint(breakpoint);
    }
}

void spendPvpFightsIfNeeded() {
    if (pvp_attacks_left() <= 0) {
        return;
    }

    if (get_property("prusias_ploop_neverPvpOverride").to_boolean()) {
        print("PLOOP: PVP is disabled by user preference", "red");
    } else {
        cli_execute("pvp_mab");
    }
}

// Use the same compatible extender set pearlo prefers in wineglass mode.
void equipLeg1PearloOrgans() {
    item glass = $item[Drunkula's wineglass];
    if (!leg1WineglassReady()) abort("ERROR_PLOOP: Put an equippable Drunkula's wineglass in inventory to resume Leg 1.");
    if (!have_equipped(glass)) {
        if (weapon_hands(equipped_item($slot[weapon])) > 1 && !equip($slot[weapon], $item[none]))
            abort("ERROR_PLOOP: Could not clear the weapon slot for the wineglass.");
        if (!equip($slot[off-hand], glass)) abort("ERROR_PLOOP: Could not equip the wineglass.");
    }
    foreach extender in $items[angelbone chopsticks, devilbone corset, devilbone greaves, angelbone totem] {
        if (have_equipped(extender) || item_amount(extender) == 0 || !can_equip(extender)) continue;
        if (!equip(extender)) abort("ERROR_PLOOP: Could not equip " + extender + ".");
    }
    if (my_fullness() > fullness_limit() || my_spleen_use() > spleen_limit())
        abort("ERROR_PLOOP: Equipped organ capacity is too low to adventure. Restore the required gear and rerun preascend.");
}

string leg1ExpandedDiet() {
    return "CONSUME ORGANS " + max(0, fullness_limit() - my_fullness()) + " 0 "
        + max(0, spleen_limit() - my_spleen_use());
}

int leg1ExpandedDietYield() {
    if (fullness_limit() <= my_fullness() && spleen_limit() <= my_spleen_use()) return 0;
    string report = cli_execute_output(leg1ExpandedDiet() + " SIM");
    matcher yield = create_matcher("Adventure yield should be roughly ([0-9,]+)-[0-9,]+", report);
    if (!yield.find()) abort("ERROR_PLOOP: Could not read the expanded CONSUME simulation. Rerun preascend after checking CONSUME.");
    return yield.group(1).replace_string(",", "").to_int();
}

void burnLeg1PearloLeftovers() {
    // Garbo's outfits forbid organ extenders. While over capacity, spend the
    // remaining turns with legal wineglass gear and an explicit attack macro.
    location farm = $location[Barf Mountain];
    if (!can_adventure(farm)) {
        print("Leg 1 pearlo: Barf Mountain is unavailable. Trying combo for the remaining adventures.", "teal");
        string comboError = catch {
            useCombo(true);
        };
        if (current_round() > 0 || handling_choice() || in_multi_fight() || choice_follows_fight()) {
            abort("ERROR_PLOOP: Finish the combat or choice left by combo, then rerun preascend.");
        }
        if (my_adventures() == 0) return;
        if (comboError != "") print("Leg 1 pearlo: combo stopped: " + comboError, "orange");

        // The Warren needs neither a charter nor underwater breathing gear.
        farm = $location[The Dire Warren];
        if (!can_adventure(farm)) {
            abort("ERROR_PLOOP: Combo left adventures unspent and The Dire Warren is unavailable. Spend the remaining turns with the organ gear and wineglass equipped, then rerun preascend.");
        }
    }
    print("Leg 1 pearlo: burning " + my_adventures() + " leftover adventures at " + farm + " with organ gear equipped.", "teal");
    while (my_adventures() > 0) {
        equipLeg1PearloOrgans();
        if (!can_adventure(farm) || have_effect($effect[Beaten Up]) > 0 || !restore_hp(my_maxhp()))
            abort("ERROR_PLOOP: Cannot burn expanded-organ turns safely at " + farm + ". Spend them with the organ gear and wineglass equipped, then rerun preascend.");
        int before = my_adventures();
        if (!adv1(farm, -1, "attack; repeat;") || current_round() > 0 || handling_choice()
                || have_effect($effect[Beaten Up]) > 0 || my_adventures() >= before
                || get_property("lastEncounter") == "Food Coma") {
            abort("ERROR_PLOOP: Leg 1 leftover turn burn stopped. Resolve the encounter before rerunning preascend.");
        }
    }
}

boolean leg1PearloNeedsOrganGear() {
    int stomachBonus = 0;
    int spleenBonus = 0;
    foreach extender in $items[angelbone chopsticks, devilbone corset, devilbone greaves, angelbone totem] {
        if (!have_equipped(extender)) continue;
        stomachBonus += numeric_modifier(extender, "Stomach Capacity").to_int();
        spleenBonus += numeric_modifier(extender, "Spleen Capacity").to_int();
    }
    return my_fullness() > fullness_limit() - stomachBonus || my_spleen_use() > spleen_limit() - spleenBonus;
}

void runLeg1PearloPreAscend() {
    string stage = get_property(leg1PearloStage);
    if (stage == "done") return;
    if (stage == "planned") abort("ERROR_PLOOP: Finish the first Garbo pass with ploop run leg1garbo before continuing to preascend.");
    if (current_round() > 0 || handling_choice() || in_multi_fight() || choice_follows_fight())
        abort("ERROR_PLOOP: Finish the current combat or choice before resuming Leg 1 pearlo.");
    if (!leg1WineglassReady()) abort("ERROR_PLOOP: Bring Drunkula's wineglass back to inventory before resuming Leg 1 pearlo.");

    if (stage == "initialDone") {
        // Record the start before CONSUME; the live liver check avoids a second
        // nightcap if the drink succeeded just before an interruption.
        set_property(leg1PearloStage, "nightcapping");
        if (my_inebriety() == inebriety_limit() && my_familiar() != $familiar[Stooper]) preCSrun();
        stage = "nightcapping";
    }
    if (stage == "nightcapping") {
        if (my_inebriety() <= inebriety_limit()) {
            // Match the normal pre-ascension nightcap valuation.
            int voa = get_property("valueOfAdventure").to_int() / 2;
            if (!cli_execute("CONSUME NIGHTCAP VALUE " + voa))
                abort("ERROR_PLOOP: Leg 1 nightcap failed; rerun preascend to resume.");
        }
        if (my_inebriety() <= inebriety_limit()) abort("ERROR_PLOOP: CONSUME did not leave you overdrunk.");
        set_property(leg1PearloStage, "nightcapped");
        stage = "nightcapped";
    }
    if (stage == "nightcapped") {
        equipLeg1PearloOrgans();
        int dietYield = leg1ExpandedDietYield();
        int needed = get_property(leg1PearloTurns).to_int();
        int reserve = max(0, needed - dietYield);
        print("Leg 1 pearlo: keeping " + reserve + " adventures before the expanded diet (estimated minimum yield " + dietYield + ").", "teal");
        if (my_adventures() > reserve && !leg1PearloNeedsOrganGear()) {
            // An absolute floor stays valid across Garbo's Digitize retries.
            string limit = reserve > 0 ? " turns=-" + reserve : "";
            runGarboSavingLeg1Fishy("ascend nodiet" + limit, "limitedDone");
        } else {
            set_property(leg1PearloStage, "limitedDone");
        }
        stage = "limitedDone";
    }
    if (stage == "limitedDone") {
        // A limited Garbo pass can change buffs, gear, or Fishy. Confirm the
        // economics again before committing extra organs.
        string report = cli_execute_output("pearlo profit drunk overcapped !force");
        if (leg1PearloBudget(report) == 0) {
            print("Leg 1 pearlo: no profitable zone confirmed after Garbo; skipping the expanded diet.", "blue");
            set_property(leg1PearloStage, "pearlsDone");
            stage = "pearlsDone";
        } else {
            set_property(leg1PearloStage, "expanding");
            stage = "expanding";
        }
    }
    if (stage == "expanding") {
        equipLeg1PearloOrgans();
        if (my_inebriety() <= inebriety_limit())
            abort("ERROR_PLOOP: Leg 1 is no longer overdrunk; check the wineglass setup before resuming.");
        if ((my_fullness() < fullness_limit() || my_spleen_use() < spleen_limit())
                && !cli_execute(leg1ExpandedDiet()))
            abort("ERROR_PLOOP: Expanded diet stopped. Rerun preascend to fill only the remaining capacity.");
        set_property(leg1PearloStage, "dietDone");
        stage = "dietDone";
    }
    if (stage == "dietDone") {
        equipLeg1PearloOrgans();
        if (my_inebriety() <= inebriety_limit())
            abort("ERROR_PLOOP: Leg 1 is no longer overdrunk; check the wineglass setup before resuming.");
        if (my_adventures() > 0 && !cli_execute("pearlo overcapped !force !strand halt=0"))
            abort("ERROR_PLOOP: Leg 1 pearlo stopped. Rerun preascend to resume with the unfinished pearls.");
        set_property(leg1PearloStage, "pearlsDone");
        stage = "pearlsDone";
    }
    if (stage != "pearlsDone") abort("ERROR_PLOOP: Unknown Leg 1 pearlo checkpoint: " + stage);
    if (my_adventures() > 0) {
        equipLeg1PearloOrgans();
        if (leg1PearloNeedsOrganGear()) burnLeg1PearloLeftovers();
        else garboUsage("ascend nodiet", false, false);
    }
    if (my_adventures() > 0) abort("ERROR_PLOOP: Leg 1 still has adventures left. Rerun preascend to finish.");
    set_property(leg1PearloStage, "done");
}

void runPreAscensionPhase(boolean halloween) {
    if (get_property("ascensionsToday").to_int() != 0) {
        return;
    }

    boolean pearlRoute = get_property(leg1PearloStage) != "";
    if (pearlRoute) {
        runLeg1PearloPreAscend();
    } else if (!halloween && my_familiar() != $familiar[Stooper] && my_inebriety() < inebriety_limit()) {
        print("Leg 1 preascend: liver has room. Running Garbo before Stooper prep.", "teal");
        garboUsage("ascend");
    }

    if (!pearlRoute && my_inebriety() == inebriety_limit() && my_familiar() != $familiar[Stooper]) {
        preCSrun();
    }
    if (!pearlRoute && my_inebriety() - inebriety_limit() == 1 && my_familiar() != $familiar[Stooper]) {
        use_familiar($familiar[Stooper]);
    }

    if (!needToAcquireItem($item[Drunkula's wineglass])) {
        print("Leg 1 preascend: wineglass available, drunkenness " + my_inebriety() + "/" + inebriety_limit() + ".", "teal");
        // Allow CONSUME to finish the nightcap if Stooper still has liver space after distillate.
        if (!pearlRoute && my_familiar() == $familiar[Stooper] && my_inebriety() <= inebriety_limit()) {
            string nightcapValue = halloween ? "9999" : (get_property("valueOfAdventure").to_int()/2).to_string();
            cli_execute("CONSUME ALL NIGHTCAP VALUE " + nightcapValue);
        }

        prepPvp();
        if (!pearlRoute && my_adventures() > 0) {
            if (my_inebriety() > inebriety_limit()) {
                if (halloween) {
                    cli_execute("freecandy");
                }
                garboUsage("ascend");
            } else {
                // Distillate can add adventures without putting us over Stooper's limit.
                print("Leg 1 preascend: running Garbo without a diet for " + my_adventures() + " remaining adventures.", "teal");
                garboUsage("ascend", false, true);
            }
        }

        string breakpoint = halloween ? "spookyWineglassDone" : "wineglassDone";
        if (!get_property('thoth19_event_list').contains_text(breakpoint)) {
            addBreakpoint(breakpoint);
        }
        spendPvpFightsIfNeeded();

        if (my_adventures() > 0) {
            if (halloween) {
                restoreHalloweenMPA();
            }
            abort("ERROR_PLOOP: " + my_adventures() + " adventures remain after leg 1 cleanup.");
        }
        if (!halloween) {
            prepPvp();
        }
        return;
    }

    print("Breakfast leg end of day, overdrunk WITHOUT wineglass", "teal");
    cli_execute("CONSUME ALL NIGHTCAP VALUE 100");
    useCombo(false);

    if (halloween) {
        if (pvp_attacks_left() > 0) {
            prepPvp();
            spendPvpFightsIfNeeded();
        }
    } else {
        prepPvp();
    }
}

void runAscensionPhase() {
    if (get_property("ascensionsToday").to_int() == 0) {
        if (get_property(leg1PearloStage) != "" && get_property(leg1PearloStage) != "done")
            abort("ERROR_PLOOP: Leg 1 pearlo is unfinished. Resume with ploop run preascend before ascending.");
        ascendToValhalla();
    }
}

void runLoopScriptPhase(boolean halloween) {
    if (get_property("ascensionsToday").to_int() != 1) {
        return;
    }

    print("In 2nd leg", "teal");
    beforeScriptRuns();
    if (!get_property('kingLiberated').to_boolean() && !smolReadyForPrism()) {
        if (!halloween && get_property("prusias_ploop_pathId") == "49") {
            print(florist_available());
        }
        string loopScriptClan = get_property("prusias_ploop_loopScriptClan");
        string homeClan = get_property("prusias_ploop_homeClan");
        boolean useLoopScriptClan = loopScriptClan != "";

        // Keep a path-specific clan dependency scoped to the loop script, including when
        // that script aborts, so post-run preparation and garbo resume in the home clan.
        if (useLoopScriptClan) {
            cli_execute("/whitelist " + loopScriptClan);
        }
        string errorMessage = catch {
            cli_execute(get_property("prusias_ploop_ascendScript"));
        };
        if (useLoopScriptClan) {
            cli_execute("/whitelist " + homeClan);
        }
        if (errorMessage != "") {
            abort(errorMessage);
        }
    }
}

void finishSmolRun(boolean halloween) {
    if (get_property('kingLiberated').to_boolean() || !smolReadyForPrism()) {
        return;
    }

    if (halloween) {
        if (available_amount($item[10058]) > 0) {
            int numToSauge = min(23,item_amount($item[magical sausage casing]));
            cli_execute("make " + numToSauge + " magical sausage");
            cli_execute("eat " + numToSauge + " magical sausage");
        }
        if (available_amount($item[10929]) > 0 && available_amount($item[astral pilsner]) >= 5) {
            cli_execute("cast ode to booze");
            cli_execute("drink astral pilsner");
        }
    } else if (available_amount($item[10929]) > 0 && available_amount($item[astral pilsner]) >= 5) {
        cli_execute("cast ode to booze");
        if (my_inebriety() < inebriety_limit()) {
            print("WARNING_PLOOP: Somehow empty liver after smol done??", "red");
            cli_execute("drink astral pilsner");
        }
        if (my_inebriety() == inebriety_limit()) {
            overdrink(1, $item[astral pilsner]);
        }
    }

    if (!get_property('kingLiberated').to_boolean()) {
        visit_url("place.php?whichplace=nstower&action=ns_11_prism");
    }
    cli_execute("hagnk all");
    postAscendScriptCleanup();
    cli_execute("refresh all");

    if (!halloween && my_fullness() > fullness_limit()) {
        use($item[spice melange]);
        use($item[distention pill]);
        use($item[cuppa voraci tea]);
    }
    if (available_amount($item[10929]) > 0 && my_inebriety() > inebriety_limit()) {
        while (get_property("_sweatOutSomeBoozeUsed").to_int() < 3) {
            equip($item[designer sweatpants]);
            use_skill(1, $skill[Sweat Out Some Booze]);
        }
        if (halloween) {
            cli_execute("use cuppa Sobrie tea");
            cli_execute("use synthetic dog hair pill");
        } else {
            if (my_inebriety() > inebriety_limit()) {
                cli_execute("use synthetic dog hair pill");
            }
            if (my_inebriety() > inebriety_limit()) {
                use($item[cuppa Sobrie tea]);
            }
            if (my_inebriety() > inebriety_limit()) {
                print("ERROR_PLOOP: Smol organ clearing failed. Please ping Prusais in ASS discord", "red");
            }
        }
    }
}

void runPostScriptPrepPhase(boolean halloween) {
    if (get_property("ascensionsToday").to_int() != 1) {
        return;
    }

    finishSmolRun(halloween);
    if (!get_property('kingLiberated').to_boolean()) {
        visit_url("place.php?whichplace=nstower&action=ns_11_prism");
    }
    prepareForPostRun();
}

void runLeg2GarboPhase(boolean halloween) {
    if (get_property("ascensionsToday").to_int() != 1) {
        return;
    }

    if (shouldRunPostRun()) {
        if (halloween) {
            cli_execute("CONSUME ALL VALUE 10000");
            postRun("nobarf");
            cli_execute("freecandy");
        } else {
            runPloopBreakfast(false);
            postRun("");
        }
    }
    runPloopBreakfast(false);
}

void runPostDayScript() {
    string script = get_property("prusias_ploop_postDayScript");
    if (script == "") {
        return;
    }

    print("Running post day script: " + script, "teal");
    // capture the result so a failing script does not stop the day before ptrack records it
    if (!cli_execute(script)) {
        print("ERROR_PLOOP: Post day script failed: " + script, "red");
    }
}

//Tickets vanish at rollover wherever they are, so any still held were bought today.
//Takes the higher of the raffle page's count and the tickets held.
int raffleTicketsBoughtToday() {
    item ticket = $item[raffle ticket];
    int held = item_amount(ticket) + closet_amount(ticket) + storage_amount(ticket);
    matcher purchased = create_matcher("You have purchased ([\\d,]+) ticket", visit_url("raffle.php"));
    int listed = purchased.find() ? purchased.group(1).to_int() : 0;
    return max(held, listed);
}

void buyRaffleTicketsIfWanted() {
    int wanted = get_property("prusias_ploop_raffleTicketCount").to_int();
    if (wanted <= 0 || !get_property("kingLiberated").to_boolean())
        return;
    int bought = raffleTicketsBoughtToday();
    if (bought >= wanted) {
        print("Already bought " + bought + " of " + wanted + " raffle tickets today.", "teal");
        return;
    }
    int missing = wanted - bought;
    print("Buying " + missing + " raffle tickets, with " + bought + " of " + wanted + " bought today.", "teal");
    //the raffle command returns true when it cannot reach the raffle house
    int heldBefore = item_amount($item[raffle ticket]);
    if (!cli_execute("raffle " + missing + " inventory") || item_amount($item[raffle ticket]) < heldBefore + missing)
        print("ERROR_PLOOP: Could not buy " + missing + " raffle tickets.", "red");
}

void runNightcapPhase(boolean halloween) {
    if (get_property("ascensionsToday").to_int() != 1) {
        return;
    }

    if (halloween) {
        if (get_property('kingLiberated').to_boolean() && my_inebriety() == inebriety_limit() && my_adventures() < 5) {
            nightcap();
            print("Consider using wineglass to burn the rest of your turns for halloween!", "red");
        }
    } else if (get_property('kingLiberated').to_boolean() && my_inebriety() == inebriety_limit() && my_adventures() == 0) {
        nightcap();
    }

    buyRaffleTicketsIfWanted();

    string breakpoint = halloween ? "halloweenEnd" : "end";
    if (!get_property('thoth19_event_list').contains_text(breakpoint)) {
        runPostDayScript();
        addBreakpoint(breakpoint);
        cli_execute("ptrack recap");
    }
    if (halloween) {
        restoreHalloweenMPA();
    }
}

void executePloopChunk(string chunk, boolean halloween) {
    restoreLeg1PearloFishy();
    switch (chunk) {
        case "breakfast": runBreakfastPhase(halloween); break;
        case "leg1garbo": runLeg1GarboPhase(halloween); break;
        case "preascend": runPreAscensionPhase(halloween); break;
        case "ascend": runAscensionPhase(); break;
        case "loopscript": runLoopScriptPhase(halloween); break;
        case "postscriptprep": runPostScriptPrepPhase(halloween); break;
        case "leg2garbo": runLeg2GarboPhase(halloween); break;
        case "nightcap": runNightcapPhase(halloween); break;
    }
}

void reentrantWrapper() {
    boolean halloween = isHalloween();
    cli_execute("/whitelist " + get_property("prusias_ploop_homeClan"));
    if (halloween) {
        enableHalloweenMode();
    }

    foreach index, chunk in PLOOP_CHUNKS {
        executePloopChunk(chunk.name, halloween);
    }

    if (!halloween) {
        print("Plooping Complete!", "teal");
        print_html("<i>You just plooped yourself</i>");
        cli_execute("pUpdates check ploop");
    }
}

void runPloopChunk(string chunk) {
    boolean halloween = isHalloween();
    cli_execute("/whitelist " + get_property("prusias_ploop_homeClan"));
    if (halloween) {
        enableHalloweenMode();
    }

    executePloopChunk(chunk, halloween);

    if (halloween) {
        restoreHalloweenMPA();
    }
}

void runNextPloopChunk() {
    resetRunNextTrackerIfNeeded();

    string completedChunk = get_property("prusias_ploop_runNextCompletedChunk");
    int nextIndex = 0;
    if (completedChunk != "") {
        int completedIndex = getPloopChunkIndex(completedChunk);
        if (completedIndex < 0) {
            print("ERROR_PLOOP: Invalid run next tracker value: " + completedChunk, "red");
            print("Clear prusias_ploop_runNextCompletedChunk before running again.", "red");
            return;
        }
        nextIndex = completedIndex + 1;
    }

    if (nextIndex >= PLOOP_CHUNKS.count()) {
        print("All pLoop chunks have been completed by run next today.", "teal");
        return;
    }

    string nextChunk = PLOOP_CHUNKS[nextIndex].name;
    print("Running next pLoop chunk: " + nextChunk, "teal");
    runPloopChunk(nextChunk);
    set_property("prusias_ploop_runNextCompletedChunk", nextChunk);
    print("Completed pLoop chunk: " + nextChunk, "teal");
}

void clearAcquisitionList() {
    set_property("prusias_ploop_preAscendAcquireList","");
    print("Acquisition List emptied. No additional items outside those specified in README will be acquired before ascension.");
}

void clearClanStashAcquireList() {
    set_property("prusias_ploop_preAscendClanStashAcquireList", "");
    print("Clan stash acquisition list emptied. No items will be attempted to be pulled from clan stash before ascension.");
}

void addAcquisitionListItem(string itemToAdd) {
    item it = itemToAdd.to_item();
    if (it == $item[none]) {
        print("Not a valid item. Double check spelling", "red");
    } else {
        appendItemToProperty(it, "prusias_ploop_preAscendAcquireList");
    }
}

void addClanStashAcquireItem(string itemToAdd) {
    item it = itemToAdd.to_item();
    if (it == $item[none]) {
        print("Not a valid item. Double check spelling", "red");
    } else {
        appendItemToProperty(it, "prusias_ploop_preAscendClanStashAcquireList");
    }
}

void main(string input) {
    // Keep reports read-only, before the usual Halloween and PvP setup.
    string reportInput = replace_all(create_matcher("^\\s+|\\s+$", input), "").to_lower_case();
    if (reportInput == "listinitargs") {
        listInitArgs();
        return;
    }
    if (create_matcher("^run\\s+help$", reportInput).find()) {
        printPloopChunkHelp();
        return;
    }
    restoreHalloweenMPA();

    //break hippy stone if always pvp
    if (!get_property("prusias_ploop_neverPvpOverride").to_boolean() && get_property("prusias_ploop_alwaysPvP").to_boolean()) {
        if (!hippy_stone_broken())
            visit_url("peevpee.php?action=smashstone&pwd&confirm=on", true);
    }
    string [int] commands = input.split_string("\\s+");
    for(int i = 0; i < commands.count(); ++i){
        switch(commands[i].to_lower_case()){
            case "fullday":
                if (get_property("prusias_ploop_ascendScript") == "") {
                    ploopHelper();
                    return;
                }
                reentrantWrapper();
                restoreHalloweenMPA();
                return;
            case "run":
                if (i + 1 >= commands.count()) {
                    printPloopChunkHelp();
                    return;
                }
                i = i + 1;
                string phase = commands[i].to_lower_case();
                if (phase == "next") {
                    runNextPloopChunk();
                    return;
                }
                if (!isPloopChunk(phase)) {
                    print("Unknown pLoop phase: " + phase, "red");
                    return;
                }
                runPloopChunk(phase);
                return;
            case "init":
                init();
                return;
            case "csinit":
                csInit();
                return;
            case "smolinit":
                smolInit();
                return;
            case "utsinit":
                utsInit();
                return;
            case "roboinit":
                robotInit();
                return;
            case "clearacquirelist":
                clearAcquisitionList();
                return;
            case "addacquirelist":
                if(i + 1 < commands.count())
                {
                    i = i+1;
                    string blacklistInput = "";
                    while (i < commands.count()) {
                        blacklistInput += commands[i] + " ";
                        i++;
                    }
                    addAcquisitionListItem(blacklistInput);
                } else {
                    print("Please provide an item name as an argument.", "red");
                }
                return;
            case "clearclanstashlist":
                clearClanStashAcquireList();
                return;
            case "addclanstashlist":
                if(i + 1 < commands.count())
                {
                    i = i+1;
                    string clanStashInput = "";
                    while (i < commands.count()) {
                        clanStashInput += commands[i] + " ";
                        i++;
                    }
                    print(clanStashInput);
                    addClanStashAcquireItem(clanStashInput);
                } else {
                    print("Please provide an item name as an argument.", "red");
                }
                return;
            case "save":
                if(i + 1 < commands.count()) {
                    i = i+1;
                    string saveName = commands[i];
                    saveAllProperties(saveName);
                } else {
                    print("Please provide a save name as an argument.", "red");
                }
                return;
            case "load":
                if(i + 1 < commands.count()) {
                    i = i+1;
                    string saveName = commands[i];
                    loadAllProperties(saveName);
                } else {
                    print("Please provide a save name as an argument.", "red");
                }
                return;
            case "listsaves":
                listSaves();
                return;
            case "knob":
                openKnobTreasury();
                return;
            case "options":
            case "option":
                optional_help_info();
                return;
            default:
                ploopHelper();
                return;
        }
    }
}
