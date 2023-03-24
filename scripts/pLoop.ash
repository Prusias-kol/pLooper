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
asdon fuels
*/


/*
Hard requirements
- Clan VIP
- stooper
- CBB recipes
- If own left-hand man, green lavaco lamp
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

void augmentBreakfast() {
    pBreakfast();

    //double ice
    if (!to_boolean(get_property("_aprilShower")))
        cli_execute("shower ice");

    //big book
    if (get_property("bankedKarma").to_int() > 2000 && available_amount($item[The Big Book of Every Skill])) 
        use(1, $item[The Big Book of Every Skill]);
    

}

void useCombo() {
    if (available_amount($item[Beach Comb])) {
        if (my_adventures() > 0) {
            cli_execute("combo " + my_adventures());
        }
    }
}

void CS_Ascension() {

    useCombo();


    int deli = get_property("prusias_ploop_astralDeli").to_item().to_int();
	int pet = get_property("prusias_ploop_astralPet").to_item().to_int();
	int type = 2;//normal difficulty
	int moonId = get_property("prusias_ploop_moonId").to_int();//wallaby
	int pathId = 25;//cs
	int classId = get_property("prusias_ploop_moonId").to_class().to_int();
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
        cli_execute("use " + get_property("prusias_ploop_preAscendGarden"));
    use_familiar($familiar[Stooper]);
    if (available_amount($item[tiny stillsuit]) > 0 || have_equipped($item[tiny stillsuit]))
        cli_execute("drink stillsuit distillate");
    else
        cli_execute("CONSUME VALUE " + (get_property("valueOfAdventure").to_int()));


    print("Remember to spend your pvp fights", "fuchsia");

}

void garboUsage(string x) {
    if (!get_property("_essentialTofuUsed").to_boolean()) {
        cli_execute("buy 1 essential tofu @" + (get_property("valueOfAdventure").to_int() * 4));
        if (item_amount($item[essential tofu]) >= 1) {
            cli_execute("use essential tofu");
        }
    }
    if (available_amount($item[Glenn's golden dice]) > 0)
        cli_execute("use Glenn's golden dice");
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

    garboUsage("workshed=" + get_property("prusias_ploop_garboPostAscendWorkshed") + " " + x);
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
    cli_execute("outfit " + get_property("prusias_ploop_nightcapOutfit"));
    

    //nightcapping
    //cli_execute("CONSUME NIGHTCAP VALUE " + get_property("valueOfAdventure").to_int());
    if (my_inebriety() == inebriety_limit()) {
        cli_execute("CONSUME NIGHTCAP VALUE " + (get_property("valueOfAdventure").to_int()));
    }
    if (have_familiar($familiar[Left-Hand Man])) {
        use_familiar($familiar[Left-Hand Man]);
        equip( $slot[familiar], $item[8437]);
    }
    
}

void reentrantWrapper() {
    cli_execute("/whitelist " + get_property("prusias_ploop_homeClan"));
    if (get_property("ascensionsToday").to_int() == 0) {
        if (!get_property("breakfastCompleted").to_boolean())
            augmentBreakfast();
        if (my_inebriety() <= inebriety_limit() && my_adventures() > 0 && my_familiar() != $familiar[Stooper]) {
            if (get_property("prusias_ploop_garboWorkshed") == "")
                garboUsage("ascend");
            else
                garboUsage("ascend workshed=" + get_property("prusias_ploop_garboWorkshed"));
        }

        if (!get_property('thoth19_event_list').contains_text("leg1garbo"))
            addBreakpoint("leg1garbo");
        if (my_inebriety() == inebriety_limit() && my_familiar() != $familiar[Stooper])
            preCSrun();
        if (available_amount($item[Drunkula's wineglass]) > 0 || have_equipped($item[Drunkula's wineglass]) > 0) {
            if (my_inebriety() == inebriety_limit() && my_familiar() == $familiar[Stooper])
                cli_execute("CONSUME NIGHTCAP VALUE " + (get_property("valueOfAdventure").to_int()/2));
            // if (!hippy_stone_broken())
            //     runPvP();
            if (my_inebriety() > inebriety_limit() && my_adventures() > 0) {
                cli_execute("garbo ascend");
            }
            if (!get_property('thoth19_event_list').contains_text("wineglassDone"))
                addBreakpoint("wineglassDone");
            if (my_adventures() == 0) {
                CS_Ascension();
            } else {
                print("Something went wrong", "red");
                abort();
            }
        } else {
            cli_execute("garbo ascend");
            cli_execute("CONSUME NIGHTCAP VALUE 100");
            useCombo();
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

void main() {
    reentrantWrapper();
}
