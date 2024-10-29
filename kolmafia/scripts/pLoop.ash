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
prusias_ploop_detectHalloween = boolean
prusias_ploop_tryDmtDupe = boolean
prusias_ploop_dmtDupeItemId = int
prusias_ploop_postRunMoonTune = int
prusias_ploop_optOutSmoking = boolean
prusias_ploop_nightcapMPA = int
prusias_ploop_garboAdditionalArg = string
prusias_ploop_breakfastAdditionalScript = string

Script state tracking
_prusias_ploop_got_steel_organ - Only used on leg 2 and reset on ascension/day
prusias_ploop_takenFromClanStashItems - items that need to be returned to stash
prusias_ploop_clanStashTakenFrom - return to right clan
*/

void ploopHelper() {
    print_html("<font color=eda800><b>Welcome to pLooper!</b></font>");
    print("pLooper is a Re-Entrant daily looping wrapper that handles running garbo, ascending, running your ascending script, and garboing again along with other small optimizations.");
    print("To use the script, please run ploop init before you run ploop fullday");
    print("Setup Commands","teal");
    print_html("<b>init</b> - Initializes pLooper CS. Mandatory for the script to work");
    //smolinit
    print_html("<b>smolinit</b> - Initializes pLooper for smol. Mandatory for the script to work");
    //you, robot
    print_html("<b>roboinit</b> - Initializes pLooper for You,Robot. Mandatory for the script to work");
    print("Daily Commands", "teal");
    print_html("<b>fullday</b> - Fullday wrapper");
    print_html("<b>clearacquirelist</b> - Empties Acquisition List so no additiional items outside README are acquired before ascension.");
    print_html("<b>addacquirelist (item name)</b> - Adds an item to the Acquisition List. Give the item name as parameter (spaces ok). Will be acquired right before ascension.");
    print_html("<b>clearclanstashlist</b> - Empties pre-ascend clan stash acquisition list.");
    print_html("<b>addclanstashlist (item name)</b> - Adds an item to the pre-ascend clan stash acquisition list. Give the item name as parameter (spaces ok). Will be pulled if exists in stash before ascension, otherwise skipped.");
    print_html("<b>pirateRealmEnable</b> - Enables fishing for Trash Island and garbo targetting cockroaches. <b>Requires PirateRealm Membership Packet!</b>");
    print_html("<b>pirateRealmDisable</b> - Disables fishing for Trash Island and garbo targetting cockroaches.");
    print("Ploop's Configurable Settings", "teal");
    print_html("<b>options</b> - See optional preferences you can set and configure");
    cli_execute("pUpdates check ploop");
}

void optional_help_info() {
    print("Optional Preferences", "teal");
    print_html("<b>prusias_ploop_alwaysPvP</b> - Set to true to always break stone and maximize PvP fights (probably only worth if you have robort or want RO pvp fights). Will leave you to being exposed for pvp looting over RO.");
    print_html("<b>prusias_ploop_leg1PvP</b> - Set to true to break stone and maximize PvP fights only on leg 1 (probably only worth if you have robort). Will leave you to being exposed for pvp looting only during leg 1 garbo.");
    print_html("<b>prusias_ploop_detectHalloween</b> - Set to true for ploop to run freecandy on halloweens. You should have downloaded and configured freecandy yourself");
    print_html("<b>prusias_ploop_tryDmtDupe</b> - Set to <b>true</b> for ploop to try to dupe with Machine Elf. Your CS script must use exactly 5 DMT free fights and nothing more for this to work.");
    print_html("<b>prusias_ploop_dmtDupeItemId</b> - Set to <b>item id</b> you would like to dupe");
    print_html("<b>prusias_ploop_useAdvForPvpAtBoxingDaycare</b> - Set to <b>true</b> if you want to spend 1 adv getting pvp fights from boxing daycare.");
    print_html("<b>prusias_ploop_postRunMoonTune</b> - Set to integer corresponding to moon id. If you have tunes available after the run, will try to tune to this moon sign.");
    print_html("<b>prusias_ploop_nightcapMPA</b> - False or empty string will disable. Manually set MPA for nightcapping for those who have an MPA so high, CONSUME will overcap.");
    print_html("<b>prusias_ploop_garboAdditionalArg</b> - Additional argument to pass to garbo.");
    print_html("<b>prusias_ploop_breakfastAdditionalScript</b> - Will cli_execute whatever this property is set to after breakfast.");
    print("Disables", "teal");
    print_html("<b>prusias_ploop_optOutSmoking</b> - Set to <b>true</b> to disable spending 1k meat on maintaining kingdom smoke supply for loop leveling");

}

void init() {
    set_property("prusias_ploop_homeClan", user_prompt("What is your home clan? The script will ensure you are in this clan before running."));
    set_property("prusias_ploop_garboWorkshed", user_prompt("After RO (start of day), what workshed should garbo switch to? Provide an exact name of the workshed item to install. Leave blank to ignore"));
    set_property("prusias_ploop_preAscendGarden", user_prompt("What garden do you want to setup before ascending? Provide exact name of seeds. Leave blank to ignore."));
    set_property("prusias_ploop_ascensionType", user_prompt("What type of ascension are you doing? 1-Casual, 2-Normal (or Softcore), 3-Hardcore."));
    set_property("prusias_ploop_moonId", user_prompt("Provide the integer id of the moon you want to ascend into. 1-Mongoose;2-Wallaby;3-Vole;4-Platypus;5-Opossum;6-Marmot;7-Wombat;8-Blender;9-Packrat"));
    set_property("prusias_ploop_classId", user_prompt("Provide the exact class name you want to ascend into."));
    set_property("prusias_ploop_astralPet", user_prompt("Provide the exact name of the astral pet you want to take from valhalla. https://kol.coldfront.net/thekolwiki/index.php/Pet_Heaven"));
    set_property("prusias_ploop_astralDeli", user_prompt("Provide the exact name of the astral deli item you want to take. astral hot dog dinner;astral six-pack;carton of astral energy drinks"));
    set_property("prusias_ploop_ascendGender", user_prompt("Provide the integer corresponding to the gender you wish to be! 1 for male, 2 for female."));
    set_property("prusias_ploop_ascendScript", user_prompt("What script should be run after ascending (to complete your path)? Type just as you would type in the CLI to run the script."));
    set_property("prusias_ploop_garboPostAscendWorkshed", user_prompt("After ascending and running your ascension script, what workshed should garbo switch to? Provide an exact name of the workshed item to install. Leave blank to ignore"));
    set_property("prusias_ploop_nightcapOutfit", user_prompt("Provide the exact name of the nightcap outfit you will be using."));
    set_property("prusias_ploop_pathId", "25");
}   
void smolInit() {
    set_property("prusias_ploop_homeClan", user_prompt("What is your home clan? The script will ensure you are in this clan before running."));
    set_property("prusias_ploop_garboWorkshed", user_prompt("After RO (start of day), what workshed should garbo switch to? Provide an exact name of the workshed item to install. Leave blank to ignore"));
    set_property("prusias_ploop_preAscendGarden", user_prompt("What garden do you want to setup before ascending? Provide exact name of seeds. Leave blank to ignore."));
    set_property("prusias_ploop_moonId", user_prompt("Provide the integer id of the moon you want to ascend into. 1-Mongoose;2-Wallaby;3-Vole;4-Platypus;5-Opossum;6-Marmot;7-Wombat;8-Blender;9-Packrat"));
    set_property("prusias_ploop_classId", user_prompt("Provide the exact class name you want to ascend into."));
    set_property("prusias_ploop_astralPet", user_prompt("Provide the exact name of the astral pet you want to take from valhalla. https://kol.coldfront.net/thekolwiki/index.php/Pet_Heaven"));
    set_property("prusias_ploop_astralDeli", user_prompt("Provide the exact name of the astral deli item you want to take. astral hot dog dinner;astral six-pack;carton of astral energy drinks"));
    set_property("prusias_ploop_ascendGender", user_prompt("Provide the integer corresponding to the gender you wish to be! 1 for male, 2 for female."));
    set_property("prusias_ploop_ascendScript", user_prompt("What script should be run after ascending (to complete your path)? Type just as you would type in the CLI to run the script."));
    set_property("prusias_ploop_garboPostAscendWorkshed", user_prompt("After ascending and running your ascension script (leg 2), what workshed should garbo switch to? Provide an exact name of the workshed item to install. Leave blank to ignore"));
    set_property("prusias_ploop_nightcapOutfit", user_prompt("Provide the exact name of the nightcap outfit you will be using."));
    set_property("prusias_ploop_pathId", "49");
    set_property("prusias_ploop_ascensionType", "2");
}

void robotInit() {
    set_property("prusias_ploop_homeClan", user_prompt("What is your home clan? The script will ensure you are in this clan before running."));
    set_property("prusias_ploop_garboWorkshed", user_prompt("After RO (start of day), what workshed should garbo switch to? Provide an exact name of the workshed item to install. Leave blank to ignore"));
    set_property("prusias_ploop_preAscendGarden", user_prompt("What garden do you want to setup before ascending? Provide exact name of seeds. Leave blank to ignore."));
    set_property("prusias_ploop_moonId", user_prompt("Provide the integer id of the moon you want to ascend into (LoopRobot wants Vole). 1-Mongoose;2-Wallaby;3-Vole;4-Platypus;5-Opossum;6-Marmot;7-Wombat;8-Blender;9-Packrat"));
    set_property("prusias_ploop_classId", user_prompt("Provide the exact class name you want to ascend into. LoopRobot wants Pastamancer"));
    set_property("prusias_ploop_astralPet", user_prompt("Provide the exact name of the astral pet you want to take from valhalla. https://kol.coldfront.net/thekolwiki/index.php/Pet_Heaven"));
    set_property("prusias_ploop_astralDeli", user_prompt("Provide the exact name of the astral deli item you want to take. astral hot dog dinner;astral six-pack;carton of astral energy drinks"));
    set_property("prusias_ploop_ascendGender", user_prompt("Provide the integer corresponding to the gender you wish to be! 1 for male, 2 for female."));
    set_property("prusias_ploop_ascendScript", "looprobot");
    set_property("prusias_ploop_workshedItemAfterLoopScript", user_prompt("Looprobot doesn't use a workshed. What workshed would you like to use after looprobot finishes? You will be prompted for a 2nd workshed for garbo to swap to after this."));
    set_property("prusias_ploop_garboPostAscendWorkshed", user_prompt("After ascending and running your ascension script, what workshed should garbo switch to? Provide an exact name of the workshed item to install. Leave blank to ignore"));
    set_property("prusias_ploop_nightcapOutfit", user_prompt("Provide the exact name of the nightcap outfit you will be using."));
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
    if (have_skill($skill[Saucegeyser])) {
        return "skill Saucegeyser";
    } else {
        return get_ccs_action(round);
    }
}

void returnClanStashItems() {
    if (get_property("prusias_ploop_takenFromClanStashItems") == "") {
        return;
    }
    string currClan = get_clan_name();
    cli_execute("/whitelist " + get_property("prusias_ploop_clanStashTakenFrom"));
    cli_execute("outfit Birthday Suit");
    //left hand man
    if (have_familiar($familiar[Left-Hand Man])) {
        familiar currFam = my_familiar();
        use_familiar($familiar[Left-Hand Man]);
        equip($slot[familiar],$item[none]);
        use_familiar(currFam);
    }
    //disembodied hand
    if (have_familiar($familiar[Disembodied Hand])) {
        familiar currFam = my_familiar();
        use_familiar($familiar[Disembodied Hand]);
        equip($slot[familiar],$item[none]);
        use_familiar(currFam);
    }
    //Fancypants Scarecrow
    if (have_familiar($familiar[Fancypants Scarecrow])) {
        familiar currFam = my_familiar();
        use_familiar($familiar[Fancypants Scarecrow]);
        equip($slot[familiar],$item[none]);
        use_familiar(currFam);
    }
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

//helper func for tracking
void addClanStashAcquiredTracking(string itemToAdd) {
    set_property("prusias_ploop_clanStashTakenFrom", get_clan_name());
    item it = itemToAdd.to_item();
    if (it == $item[none]) {
        print("Not a valid item. Double check spelling", "red");
    } else {
        string itemName = it.to_string();
        cli_execute("stash take " + itemName);
        itemName = replace_all(create_matcher(",",itemName),"\\\\,");
        if (get_property("prusias_ploop_takenFromClanStashItems") == "") {
            set_property("prusias_ploop_takenFromClanStashItems", itemName);
        } else {
            set_property("prusias_ploop_takenFromClanStashItems", get_property("prusias_ploop_takenFromClanStashItems") + ", " + itemName);
        }
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
        adv1($location[The Deep Machine Tunnels], -1, "");
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

void augmentBreakfast() {
    pBreakfast();

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
    

}

boolean useCombo() {
    if (available_amount($item[Beach Comb]) == 0 && available_amount($item[driftwood beach comb]) == 0) {
        int sandprice = mall_price($item[Grain of sand]) * 3;
        int combPrice = mall_price($item[Piece of driftwood]);
        int advLimit = combPrice/sandprice;
        if (my_adventures() > advLimit) {
            cli_execute("buy 1 piece of driftwood");
            cli_execute("use piece of driftwood");
        }

    }
    if (available_amount($item[Beach Comb]) > 0 || available_amount($item[driftwood beach comb]) > 0) {
        if (my_adventures() > 0) {
            cli_execute("combo " + my_adventures());
            return true;
        }
    }
    return false;
}

void CS_Ascension() {

    useCombo();

    if (!get_property('thoth19_event_list').contains_text("wineglassDone") && !get_property('thoth19_event_list').contains_text("preAscend"))
        addBreakpoint("preAscend");

    if (get_property("getawayCampsiteUnlocked").to_boolean() && get_property("prusias_ploop_optOutSmoking").to_lower_case() != "true") {
        //smoke tax
        int tryNumSmokes = 10;
        if (item_amount($item[stick of firewood]) < tryNumSmokes) {
            cli_execute("buy " + tryNumSmokes + " stick of firewood @100");
        }

        int smoke = 0;
        tryNumSmokes = min(tryNumSmokes,item_amount($item[stick of firewood]));
        cli_execute("acquire " + tryNumSmokes + " stick of firewood");
        while(item_amount($item[stick of firewood]).to_boolean() && smoke < tryNumSmokes) {
		smoke = smoke + 1;
            catch {
                cli_execute("acquire campfire smoke");
                set_property("choiceAdventure1394", "1&message=" + smoke + " Thanks Prusias for writing Ploop!");
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
    if (pathId == 49 || pathId == 41) {
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

    //Acquire Potential CS Pulls
    if (get_property("prusias_ploop_ascensionType") == "" || get_property("prusias_ploop_ascensionType").to_int() < 3) {
        int yeastPrice = mall_price($item[Yeast of Boris]);
        int vegetablePrice = mall_price($item[Vegetable of Jarlsberg]);
        int wheyPrice = mall_price($item[St. Sneaky Pete's Whey]);

        int pizzaPrice = (2 * yeastPrice) + (2 * vegetablePrice) + (2 * wheyPrice);
        
        if (pizzaPrice < 50 * get_property("valueOfAdventure").to_int()) {
            if (available_amount($item[calzone of legend])  == 0)
                cli_execute("make calzone of legend");

            if (available_amount($item[deep dish of legend])  == 0)
                cli_execute("make deep dish of legend");

            if (available_amount($item[pizza of legend])  == 0)
                cli_execute("make pizza of legend");
        } else {
            if (available_amount($item[calzone of legend]) == 0 || available_amount($item[pizza of legend]) == 0 || available_amount($item[deep dish of legend]) == 0) {
                print("T4 CBB foods are outside of safe price range. Maybe mall shenanigans?", "red");
                print("Acquire 1 of each and run ploop again to continue.", "red");
                abort();
            }
        }

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
        if (needToAcquireItem($item[one-day ticket to Dinseylandfill]))
            cli_execute("acquire 1 one-day ticket to Dinseylandfill");
        
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

    //potential smol pulls
    if (get_property("prusias_ploop_pathId") == "49") {
        if (available_amount($item[pizza of legend])  == 0)
            cli_execute("make pizza of legend");
        retrieve_item(1, $item[3323]);//salad fork
        retrieve_item(1, $item[3324]);//frosty mug
    }

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

void garboUsage(string x) {
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
        cli_execute("buy 1 essential tofu @" + (get_property("valueOfAdventure").to_int() * 4));
        if (item_amount($item[essential tofu]) >= 1) {
            cli_execute("use essential tofu");
        }
    }
    if (!get_property("_glennGoldenDiceUsed").to_boolean() && available_amount($item[Glenn's golden dice]) > 0)
        cli_execute("use Glenn's golden dice");
    if (!get_property("_lodestoneUsed").to_boolean() && available_amount($item[lodestone]) > 0)
        cli_execute("use lodestone");
    string garboString = "garbo candydish";
    if (yachtzeeAccess())
        garboString += " yachtzeechain";
    if (x != "")
        garboString += " " + x;
    if (get_property("prusias_ploop_garboAdditionalArg") != "")
        garboString += " " + get_property("prusias_ploop_garboAdditionalArg");
    cli_execute(garboString);
}

void postRunNoGarbo() {
    shrugAT();
    cli_execute("hagnk all");
    cli_execute("refresh all");
    //ensure beach access
    if (!(available_amount($item[134]) > 0 || available_amount($item[4770]) > 0 || available_amount($item[4769]) > 0 || available_amount($item[6775]) > 0)) {
        retrieve_item(1,$item[bitchin' meatcar]);
    }
    augmentBreakfast();

    if (my_mp() < 250 && item_amount($item[10058]) > 0 && get_property("prusias_ploop_pathId").to_int() != 49)
        cli_execute("eat magical sausage");
    dmt_dupe();
    //rain-doh
    if (item_amount($item[can of Rain-Doh]) > 0) {
        cli_execute("use can of Rain-Doh");
    }
    if (have_familiar($familiar[Left-Hand Man])) {
        familiar currFam = my_familiar();
        use_familiar($familiar[Left-Hand Man]);
        equip($slot[familiar],$item[none]);
        use_familiar(currFam);
    }
    

    //insert asdon buffing
    if (get_workshed() == $item[Asdon Martin keyfob (on ring)]) {
        int numTurns = 1260; //set this value manually
        int numBuffs = numTurns/30 + 1;
        int numPies = (numBuffs * 37)/150 + 1;
        int numSodaBreads = (numBuffs * 37)/6 + 1;
        if (available_amount($item[pie man was not meant to eat]) < numPies) {
            cli_execute("buy " + numPies + " pie man was not meant to eat @3000");
        } else {
            cli_execute("acquire " + numPies + " pie man was not meant to eat");
        }
        if (available_amount($item[pie man was not meant to eat]) < numPies) {
            cli_execute("make " + numSodaBreads + " loaf of soda bread");
            cli_execute("asdonmartin fuel " + numSodaBreads + " loaf of soda bread");
        } else {
            cli_execute("asdonmartin fuel " + numPies + " pie man was not meant to eat");
        }

        while (get_fuel() >= 37) {
            cli_execute("asdonmartin drive observantly");
        }
    }
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

void nightcapFamiliar() {
    if (have_skill($skill[7464]) && !get_property("_aug13Cast").to_boolean() && get_property("_augSkillsCast").to_int() < 5) {
        use_skill($skill[7464]);
    }
    if (have_effect($effect[Offhand Remarkable]) > 0
            && have_familiar($familiar[Left-Hand Man])) {
        use_familiar($familiar[Left-Hand Man]);
        equip( $slot[familiar], $item[none]);
        if (item_amount($item[8437]) > 0) //green
            equip( $slot[familiar], $item[8437]);
        if (item_amount($item[8435]) > 0) //red
            equip( $slot[familiar], $item[8435]);
        if (item_amount($item[8436]) > 0) //blue
            equip( $slot[familiar], $item[8436]);
    } else if (have_familiar($familiar[Trick-or-Treating Tot])) {
        use_familiar($familiar[Trick-or-Treating Tot]);
        equip( $slot[familiar], $item[none]);
        cli_execute("acquire li'l unicorn costume");
        equip( $slot[familiar], $item[li'l unicorn costume]);
    } else if (have_familiar($familiar[Left-Hand Man])) {
        use_familiar($familiar[Left-Hand Man]);
        equip( $slot[familiar], $item[none]);
        if (item_amount($item[8437]) > 0) //green
            equip( $slot[familiar], $item[8437]);
        if (item_amount($item[8435]) > 0) //red
            equip( $slot[familiar], $item[8435]);
        if (item_amount($item[8436]) > 0) //blue
            equip( $slot[familiar], $item[8436]);
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
        cli_execute("PVP_MAB");
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
    if (my_inebriety() == inebriety_limit()) {
        if (get_property("prusias_ploop_nightcapMPA") == "" || get_property("prusias_ploop_nightcapMPA").to_string().to_lower_case() == "false") {
            cli_execute("CONSUME ALL NIGHTCAP VALUE " + (get_property("valueOfAdventure").to_int()));
        } else {
            cli_execute("CONSUME ALL NIGHTCAP VALUE " + get_property("prusias_ploop_nightcapMPA").to_int());
        }
    } else {
        nightcapFamiliar();
        print("Nightcap was overdrunk when it shouldn't have been");
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

void reentrantWrapper() {
    cli_execute("/whitelist " + get_property("prusias_ploop_homeClan"));
    if (get_property("ascensionsToday").to_int() == 0) {
        //break hippy stone if leg 1
        if (get_property("prusias_ploop_leg1PvP").to_boolean()
                || get_property("prusias_ploop_alwaysPvP").to_boolean()) {
            if (!hippy_stone_broken())
                visit_url("peevpee.php?action=smashstone&pwd&confirm=on", true);
        }
	    use_familiar($familiar[none]);
        if (!get_property("breakfastCompleted").to_boolean())
            augmentBreakfast();
        if (my_inebriety() <= inebriety_limit() && my_adventures() > 0 && my_familiar() != $familiar[Stooper]) {
            if (get_property("prusias_ploop_garboWorkshed") == "" || get_property("_workshedItemUsed").to_boolean())
                garboUsage("ascend");
            else
                garboUsage(`ascend workshed="` + get_property("prusias_ploop_garboWorkshed") + `"`);
        }

        if (!get_property('thoth19_event_list').contains_text("leg1garbo"))
            addBreakpoint("leg1garbo");
        if (my_inebriety() == inebriety_limit() && my_familiar() != $familiar[Stooper])
            preCSrun();
        if (!needToAcquireItem($item[Drunkula's wineglass])) {
            print("Breakfast leg end of day, overdrunk with wineglass", "teal");
            if (my_inebriety() == inebriety_limit() && my_familiar() == $familiar[Stooper])
                cli_execute("CONSUME ALL NIGHTCAP VALUE " + (get_property("valueOfAdventure").to_int()/2));
                 prepPvp();
            if (my_inebriety() > inebriety_limit() && my_adventures() > 0) {
                garboUsage("ascend");
            }
            if (!get_property('thoth19_event_list').contains_text("wineglassDone"))
                addBreakpoint("wineglassDone");
            if (pvp_attacks_left() > 0) {
                cli_execute("PVP_MAB");
            }
            if (my_adventures() == 0) {
                prepPvp();
                CS_Ascension();
            } else {
                print("Still adventures left over after", "red");
                abort();
            }
        } else {
            print("Breakfast leg end of day, overdrunk WITHOUT wineglass", "teal");
            //garboUsage("ascend"); //Garbo doesn't know how to run with stooper
            cli_execute("CONSUME ALL NIGHTCAP VALUE 100");
            if (!useCombo()) {
                //dunno what to do here, garbo ascend fails when overdrunk without wineglass
            }
            prepPvp();
            CS_Ascension();
        }
    }
    if (get_property("ascensionsToday").to_int() == 1) {
        print("In 2nd leg", "teal");
        beforeScriptRuns();
        //kingLiberated = true leg1 before ascending. false after ascending
        if (!get_property('kingLiberated').to_boolean() && (get_property("prusias_ploop_pathId") != "49" || (get_property("questL13Final") != "step12" && get_property("questL13Final") != "step13" && get_property("questL13Final") != "finished")) ) {
            cli_execute(get_property("prusias_ploop_ascendScript"));
        }
        if (!get_property('kingLiberated').to_boolean() && get_property("prusias_ploop_pathId") == "49" && (get_property("questL13Final") == "step12" || get_property("questL13Final") == "step13" || get_property("questL13Final") == "finished")) {
            //still king not liberated
            if (available_amount($item[10058]) > 0) {
                int numToSauge = min(23,item_amount($item[magical sausage casing]));
                cli_execute("make " + numToSauge + " magical sausage");
                cli_execute("eat " + numToSauge + " magical sausage");
            }  
            if (available_amount($item[10929]) > 0 && available_amount($item[astral pilsner]) >= 5) {
                cli_execute("cast ode to booze");
                cli_execute("drink astral pilsner");
            }
            if (!get_property('kingLiberated').to_boolean()) {
                visit_url("place.php?whichplace=nstower&action=ns_11_prism");
            }
            cli_execute("hagnk all");
            cli_execute("refresh all");
            if (available_amount($item[10929]) > 0 && my_inebriety() > inebriety_limit()) {
                while (get_property("_sweatOutSomeBoozeUsed").to_int() < 3) {
                    equip($item[designer sweatpants]);
                    use_skill(1, $skill[Sweat Out Some Booze]);
                }
                cli_execute("use cuppa Sobrie tea");
                cli_execute("use synthetic dog hair pill");
            }
        }
        if (!get_property('kingLiberated').to_boolean()) {
            visit_url("place.php?whichplace=nstower&action=ns_11_prism");
        }
        if (get_property("_prusias_ploop_got_steel_organ") != "true" && (get_property("prusias_ploop_pathId") == "49" || get_property("prusias_ploop_pathId") == "41")) {
            cli_execute("hagnk all");
            cli_execute("refresh all");
            //steel liver
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
            set_property("_prusias_ploop_got_steel_organ", "true");
            cli_execute("ploopgoals goal organ");
        }
        if (!get_property('moonTuned').to_boolean() && get_property("prusias_ploop_postRunMoonTune") != "") {
            //tune moon maybe
            cli_execute('unequip hewn moon-rune spoon');
            if (item_amount($item[hewn moon-rune spoon]) > 0) {
                int postrunTuneMoon =  get_property("prusias_ploop_postRunMoonTune").to_int();
                visit_url('inv_use.php?whichitem=10254&doit=96&whichsign='+postrunTuneMoon);
            }
        }
        returnClanStashItems();
        if (!get_property("_workshedItemUsed").to_boolean() 
            && get_property("prusias_ploop_workshedItemAfterLoopScript") != ""
            && get_workshed() == $item[none]) {
            cli_execute("use " + get_property("prusias_ploop_workshedItemAfterLoopScript"));
        }
        if (get_property('kingLiberated').to_boolean() &&
        (my_inebriety() < inebriety_limit() ||
        my_fullness() < fullness_limit() ||
        my_spleen_use() < spleen_limit() ||
        (my_adventures() > 0 && my_inebriety() <= inebriety_limit()))) {
            if (!get_property("breakfastCompleted").to_boolean())
                augmentBreakfast();
            postRun("");
        }
        if (!get_property("breakfastCompleted").to_boolean())
            augmentBreakfast();
        if (get_property('kingLiberated').to_boolean() && my_inebriety() == inebriety_limit() && my_adventures() == 0) {
            nightcap();
        }
        if (!get_property('thoth19_event_list').contains_text("end")) {
                    addBreakpoint("end");
            cli_execute("ptrack recap");
        }

    }
    print("Plooping Complete!", "teal");

    cli_execute("pUpdates check ploop");
}

void reentrantHalloweenWrapper() {
    cli_execute("/whitelist " + get_property("prusias_ploop_homeClan"));
    if (get_property("ascensionsToday").to_int() == 0) {
	    use_familiar($familiar[none]);
        if (!get_property("breakfastCompleted").to_boolean())
            augmentBreakfast();
        if (my_inebriety() <= inebriety_limit() && my_adventures() > 0 && my_familiar() != $familiar[Stooper]) {
            cli_execute("CONSUME ALL VALUE 10000");
            if (get_property("prusias_ploop_garboWorkshed") == "")
                garboUsage("nobarf ascend");
            else
                garboUsage(`nobarf ascend workshed="` + get_property("prusias_ploop_garboWorkshed") + `"`);
            cli_execute("freecandy");
        }

        if (!get_property('thoth19_event_list').contains_text("leg1halloween"))
            addBreakpoint("leg1halloween");
        if (my_inebriety() == inebriety_limit() && my_familiar() != $familiar[Stooper])
            preCSrun();
        if (!needToAcquireItem($item[Drunkula's wineglass])) {
            print("Breakfast leg end of day, overdrunk with wineglass", "teal");
            if (my_inebriety() == inebriety_limit() && my_familiar() == $familiar[Stooper])
                cli_execute("CONSUME ALL NIGHTCAP VALUE 9999");
                prepPvp();
            if (my_inebriety() > inebriety_limit() && my_adventures() > 0) {
                cli_execute("freecandy");
                garboUsage("ascend");
            }
            if (!get_property('thoth19_event_list').contains_text("spookyWineglassDone"))
                addBreakpoint("spookyWineglassDone");
            if (pvp_attacks_left() > 0) {
                cli_execute("PVP_MAB");
            }
            if (my_adventures() == 0) {
                CS_Ascension();
            } else {
                print("Still adventures left over after", "red");
                set_property("valueOfAdventure", get_property("prusias_ploop_preHalloweenMPA"));
                set_property("prusias_ploop_preHalloweenMPA", "");
                abort();
            }
        } else {
            print("Breakfast leg end of day, overdrunk WITHOUT wineglass", "teal");
            //garboUsage("ascend"); //Garbo doesn't know how to run with stooper
            cli_execute("CONSUME ALL NIGHTCAP VALUE 100");
            if (!useCombo()) {
                //dunno what to do here, garbo ascend fails when overdrunk without wineglass
            }
            if (pvp_attacks_left() > 0) {
                prepPvp();
                cli_execute("PVP_MAB");
            }
            CS_Ascension();
        }
    }
    if (get_property("ascensionsToday").to_int() == 1) {
        print("In 2nd leg", "teal");
        beforeScriptRuns();
        //kingLiberated = true leg1 before ascending. false after ascending
        if (!get_property('kingLiberated').to_boolean()) {
            cli_execute(get_property("prusias_ploop_ascendScript"));
        }
        if (get_property('kingLiberated').to_boolean() &&
        (my_inebriety() < inebriety_limit() ||
        my_fullness() < fullness_limit() ||
        my_spleen_use() < spleen_limit() ||
        (my_adventures() > 0 && my_inebriety() <= inebriety_limit()))) {
            cli_execute("CONSUME ALL VALUE 10000");
            postRun("nobarf");
            cli_execute("freecandy");
        }
        if (!get_property("breakfastCompleted").to_boolean())
            augmentBreakfast();
        if (get_property('kingLiberated').to_boolean() && my_inebriety() == inebriety_limit() && my_adventures() < 5) {
            nightcap();
            print("Consider using wineglass to burn the rest of your turns for halloween!", "red");
        }
	if (!get_property('thoth19_event_list').contains_text("halloweenEnd")) {
        addBreakpoint("halloweenEnd");
		cli_execute("ptrack recap");
	}
    set_property("valueOfAdventure", get_property("prusias_ploop_preHalloweenMPA"));
    set_property("prusias_ploop_preHalloweenMPA", "");
    }
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
        string itemName = it.to_string();
        itemName = replace_all(create_matcher(",",itemName),"\\\\,");
        if (get_property("prusias_ploop_preAscendAcquireList") == "") {
            set_property("prusias_ploop_preAscendAcquireList", itemName);
        } else {
            set_property("prusias_ploop_preAscendAcquireList", get_property("prusias_ploop_preAscendAcquireList") + ", " + itemName);
        }
    }
}

void addClanStashAcquireItem(string itemToAdd) {
    item it = itemToAdd.to_item();
    if (it == $item[none]) {
        print("Not a valid item. Double check spelling", "red");
    } else {
        string itemName = it.to_string();
        itemName = replace_all(create_matcher(",",itemName),"\\\\,");
        if (get_property("prusias_ploop_preAscendClanStashAcquireList") == "") {
            set_property("prusias_ploop_preAscendClanStashAcquireList", itemName);
        } else {
            set_property("prusias_ploop_preAscendClanStashAcquireList", get_property("prusias_ploop_preAscendClanStashAcquireList") + ", " + itemName);
        }
    }
}

void main(string input) {
    if (get_property("prusias_ploop_preHalloweenMPA") != "" && get_property("valueOfAdventure").to_int() == 9999) {
        set_property("valueOfAdventure", get_property("prusias_ploop_preHalloweenMPA"));
        set_property("prusias_ploop_preHalloweenMPA", "");
    }
    //break hippy stone if always pvp
    if (get_property("prusias_ploop_alwaysPvP").to_boolean()) {
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
                if (get_property("prusias_ploop_detectHalloween").to_boolean() == true) {
                    if (holiday() == "Halloween") {
                        set_property("prusias_ploop_preHalloweenMPA", get_property("valueOfAdventure"));
                        set_property("valueOfAdventure", "9999");
                        reentrantHalloweenWrapper();
                        set_property("valueOfAdventure", get_property("prusias_ploop_preHalloweenMPA"));
                        set_property("prusias_ploop_preHalloweenMPA", "");
                    } else {
                        reentrantWrapper();
                    }
                } else {
                    reentrantWrapper();
                }
                return;
            case "init":
                init();
                return;
            case "smolinit":
                smolInit();
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
            case "piraterealmenable":
                set_property("prusias_ploop_garboAdditionalArg", `target="cockroach"`);
                set_property("prusias_ploop_breakfastAdditionalScript", "tapion_praccess");
                return;
            case "piraterealmdisable":
                set_property("prusias_ploop_garboAdditionalArg", ``);
                set_property("prusias_ploop_breakfastAdditionalScript", "");
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
