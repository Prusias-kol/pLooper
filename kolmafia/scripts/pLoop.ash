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
prusias_ploop_garboPostAscendWorkshed - string
prusias_ploop_ascendScript - string
prusias_ploop_nightcapOutfit - string
prusias_ploop_preAscendGarden - string of packet of seeds name. if empty, skips
prusias_ploop_moonId - int
prusias_ploop_classId - string - class name, exact, lowercase
prusias_ploop_astralPet - string - item name, exact
prusias_ploop_astralDeli - string - item name, exact
prusias_ploop_ascendGender - int
*/

void ploopHelper() {
    print_html("<font color=eda800><b>Welcome to pLooper!</b></font>");
    print("pLooper is a Re-Entrant daily looping wrapper that handles running garbo, ascending, running your ascending script, and garboing again along with other small optimizations.");
    print("To use the script, please run ploop init before you run ploop fullday");
    print("Commands","teal");
    print_html("<b>init</b> - Initializes pLooper. Mandatory for the script to work");
    print_html("<b>fullday</b> - Fullday wrapper");
}

void init() {
    set_property("prusias_ploop_homeClan", user_prompt("What is your home clan? The script will ensure you are in this clan before running."));
    set_property("prusias_ploop_garboWorkshed", user_prompt("After RO, what workshed should garbo switch to? Provide an exact name of the workshed item to install. Leave blank to ignore"));
    set_property("prusias_ploop_preAscendGarden", user_prompt("What garden do you want to setup before ascending? Provide exact name of seeds. Leave blank to ignore."));
    set_property("prusias_ploop_moonId", user_prompt("Provide the integer id of the moon you want to ascend into. 1-Mongoose;2-Wallaby;3-Vole;4-Platypus;5-Opossum;6-Marmot;7-Wombat;8-Blender;9-Packrat"));
    set_property("prusias_ploop_classId", user_prompt("Provide the exact class name you want to ascend into."));
    set_property("prusias_ploop_astralPet", user_prompt("Provide the exact name of the astral pet you want to take from valhalla. https://kol.coldfront.net/thekolwiki/index.php/Pet_Heaven"));
    set_property("prusias_ploop_astralDeli", user_prompt("Provide the exact name of the astral deli item you want to take. astral hot dog dinner;astral six-pack;carton of astral energy drinks"));
    set_property("prusias_ploop_ascendGender", user_prompt("Provide the integer corresponding to the gender you wish to be! 1 for male, 2 for female."));
    set_property("prusias_ploop_ascendScript", user_prompt("What script should be run after ascending? Type just as you would type in the CLI to run the script."));
    set_property("prusias_ploop_garboPostAscendWorkshed", user_prompt("After ascending and running your ascension script, what workshed should garbo switch to? Provide an exact name of the workshed item to install. Leave blank to ignore"));
    set_property("prusias_ploop_nightcapOutfit", user_prompt("Provide the exact name of the nightcap outfit you will be using."));




}   

void augmentBreakfast() {
    pBreakfast();

    //double ice
    if (!to_boolean(get_property("_aprilShower")))
        cli_execute("shower ice");

    //big book
    if (get_property("bankedKarma").to_int() > 2000 && available_amount($item[The Big Book of Every Skill]) > 0) 
        use(1, $item[The Big Book of Every Skill]);
    

}

boolean useCombo() {
    if (available_amount($item[Beach Comb]) > 0) {
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


    int deli = get_property("prusias_ploop_astralDeli").to_item().to_int();
	int pet = get_property("prusias_ploop_astralPet").to_item().to_int();
	int type = 2;//normal difficulty
	int moonId = get_property("prusias_ploop_moonId").to_int();//wallaby
	int pathId = 25;//cs
	int classId = get_property("prusias_ploop_classId").to_class().to_int();
    int gender = get_property("prusias_ploop_ascendGender").to_int(); //1 boy, 2 girl


	if (get_property("csServicesPerformed").split_string(",").count() == 11) {
		print("attempting to enter valhalla");
		visit_url("council.php",false,true);
		visit_url("ascend.php?pwd&action=ascend&confirm=on&confirm2=on",true,true);
	}
	else if (get_property("kingLiberated").to_boolean() && in_casual()) {
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
	visit_url(`afterlife.php?pwd&action=ascend&confirmascend=1&whichsign={moonId}&gender={gender}&whichclass={classId}&whichpath={pathId}&asctype={type}&nopetok=1&noskillsok=1`,true,true);

}

void preCSrun() {
    int yeastPrice = mall_price($item[Yeast of Boris]);
    int vegetablePrice = mall_price($item[Vegetable of Jarlsberg]);
    int wheyPrice = mall_price($item[St. Sneaky Pete's Whey]);
    if ((2*yeastPrice + 2*vegetablePrice + 2*wheyPrice < 10*get_property("valueOfAdventure").to_int())) {
        if (available_amount($item[calzone of legend])  < 1)
            cli_execute("make calzone of legend");
        if (available_amount($item[deep dish of legend])  < 1)
            cli_execute("make deep dish of legend");
        if (available_amount($item[pizza of legend])  < 1)
            cli_execute("make pizza of legend");
    }
    cli_execute("garden pick");
    if (get_property("prusias_ploop_preAscendGarden") != "")
	if (available_amount(get_property("prusias_ploop_preAscendGarden").to_item()) > 0)
            cli_execute("use " + get_property("prusias_ploop_preAscendGarden"));
    use_familiar($familiar[Stooper]);
    if (available_amount($item[tiny stillsuit]) > 0 || have_equipped($item[tiny stillsuit]))
        cli_execute("drink stillsuit distillate");
    else
        cli_execute("CONSUME VALUE " + (get_property("valueOfAdventure").to_int()));

    if (available_amount($item[borrowed time]) + closet_amount($item[borrowed time]) + storage_amount($item[borrowed time]) == 0)
        cli_execute("acquire 1 borrowed time");

    print("Remember to spend your pvp fights", "fuchsia");

}

void garboUsage(string x) {
	print("trying to run garbo","teal");
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
    cli_execute("garbo " + x);
}

void postRunNoGarbo() {
    cli_execute("hagnk all");
    cli_execute("refresh all");
    augmentBreakfast();

    if (my_mp() < 250)
        cli_execute("eat magical sausage");
    //insert asdon buffing
    if (get_workshed() == $item[Asdon Martin keyfob]) {
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

void nightcap() {
    //Handle maids
    int profitOffset = 100;
    string page = visit_url("campground.php?action=inspectdwelling");
    if (!page.contains_text("Clockwork Maid") && !page.contains_text("Meat Maid")) {
        if (buy(1, $item[Clockwork Maid], (8 * get_property("valueOfAdventure").to_int()) - profitOffset) == 1) {
            use(1, $item[Clockwork Maid]);
            print("Installed Clockwork Maid", "green");
        } else if (buy(1, $item[Meat Maid], (4 * get_property("valueOfAdventure").to_int()) - profitOffset) == 1) {
            use(1, $item[Meat Maid]);
            print("Installed Meat Maid", "lime");
        } else {
            print("Clockwork Maid and Meat Maid both outside price range.", "red");
        }
    } else {
        print("We already have a Clockwork Maid installed", "red");
    }
    //stooper
    use_familiar($familiar[Stooper]);
    if (my_inebriety() < inebriety_limit()) {
        if (available_amount($item[tiny stillsuit]) > 0 || have_equipped($item[tiny stillsuit]))
            cli_execute("drink stillsuit distillate");
        else
            cli_execute("CONSUME VALUE " + (get_property("valueOfAdventure").to_int()));
    }
	//burning cape
	if (have_equipped($item[burning cape]) || available_amount($item[burning cape]) > 0) {
		cli_execute("equip burning cape");
    } else if (mall_price( $item[ Burning Newspaper ] ) < (get_property("valueOfAdventure").to_int())) {
        if (available_amount($item[burning newspaper]) == 0) {
            cli_execute("buy 1 burning newspaper @" + get_property("valueOfAdventure").to_int());
        }
        cli_execute("make burning cape");
        cli_execute("equip burning cape");
    }
    cli_execute("outfit " + get_property("prusias_ploop_nightcapOutfit"));
	if (available_amount($item[burning cape]) > 0) 
		cli_execute("equip burning cape");
    

    //nightcapping
    //cli_execute("CONSUME NIGHTCAP VALUE " + get_property("valueOfAdventure").to_int());
    if (my_inebriety() == inebriety_limit()) {
        cli_execute("CONSUME NIGHTCAP VALUE " + (get_property("valueOfAdventure").to_int()));
    }
    if (have_familiar($familiar[Left-Hand Man])) {
        use_familiar($familiar[Left-Hand Man]);
        equip( $slot[familiar], $item[none]);
        if (available_amount($item[8437]) > 0) //green
            equip( $slot[familiar], $item[8437]);
        if (available_amount($item[8435]) > 0) //red
            equip( $slot[familiar], $item[8435]);
        if (available_amount($item[8436]) > 0) //blue
            equip( $slot[familiar], $item[8436]);
    }
    
}

void reentrantWrapper() {
    cli_execute("/whitelist " + get_property("prusias_ploop_homeClan"));
    if (get_property("ascensionsToday").to_int() == 0) {
	use_familiar($familiar[none]);
        if (!get_property("breakfastCompleted").to_boolean())
            augmentBreakfast();
        if (my_inebriety() <= inebriety_limit() && my_adventures() > 0 && my_familiar() != $familiar[Stooper]) {
            if (get_property("prusias_ploop_garboWorkshed") == "")
                garboUsage("ascend");
            else
                garboUsage(`ascend workshed="` + get_property("prusias_ploop_garboWorkshed") + `"`);
        }

        if (!get_property('thoth19_event_list').contains_text("leg1garbo"))
            addBreakpoint("leg1garbo");
        if (my_inebriety() == inebriety_limit() && my_familiar() != $familiar[Stooper])
            preCSrun();
        if (available_amount($item[Drunkula's wineglass]) > 0 || have_equipped($item[Drunkula's wineglass])) {
            if (my_inebriety() == inebriety_limit() && my_familiar() == $familiar[Stooper])
                cli_execute("CONSUME NIGHTCAP VALUE " + (get_property("valueOfAdventure").to_int()/2));
            // if (!hippy_stone_broken())
            //     runPvP();
            if (my_inebriety() > inebriety_limit() && my_adventures() > 0) {
                garboUsage("ascend");
            }
            if (!get_property('thoth19_event_list').contains_text("wineglassDone"))
                addBreakpoint("wineglassDone");
            if (my_adventures() == 0) {
                CS_Ascension();
            } else {
                print("Still adventures left over after", "red");
                abort();
            }
        } else {
            garboUsage("ascend");
            cli_execute("CONSUME NIGHTCAP VALUE 100");
            if (!useCombo()) {
                garboUsage("ascend");
            }
            CS_Ascension();
        }
    }
    if (get_property("ascensionsToday").to_int() == 1) {
        print("In 2nd leg", "teal");
        //kingLiberated = true leg1 before ascending. false after ascending
        if (!get_property('kingLiberated').to_boolean()) {
            cli_execute(get_property("prusias_ploop_ascendScript"));
        }
        if (get_property('kingLiberated').to_boolean() &&
        (my_inebriety() < inebriety_limit() ||
        my_fullness() < fullness_limit() ||
        my_spleen_use() < spleen_limit() ||
        (my_adventures() > 0 && my_inebriety() <= inebriety_limit()))) {
            postRun("");
        }
        if (!get_property("breakfastCompleted").to_boolean())
            augmentBreakfast();
        if (get_property('kingLiberated').to_boolean() && my_inebriety() == inebriety_limit() && my_adventures() == 0) {
            nightcap();
            if (!get_property('thoth19_event_list').contains_text("end"))
                addBreakpoint("end");
        }

    }

}

void main(string input) {
    string [int] commands = input.split_string("\\s+");
    for(int i = 0; i < commands.count(); ++i){
        switch(commands[i]){
            case "fullday":
                if (get_property("prusias_ploop_ascendScript") == "") {
                    ploopHelper();
                    return;
                }
                reentrantWrapper();
                return;
            case "init":
                init();
                return;
            default:
                ploopHelper();
                return;
        }
    }
}
