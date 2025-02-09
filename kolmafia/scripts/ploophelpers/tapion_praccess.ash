import <lowerstats.ash>

string CrabFight = "if hasskill sing along; skill sing along;endif;if hasskill furious wallop;skill furious wallop;endif;if hasskill saucegeyser;skill saucegeyser;endif;attack with your weapon;repeat";
string Windy = "if hascombatitem windicle;use windicle;endif;if hasskill sing along; skill sing along;endif;if hasskill furious wallop;skill furious wallop;endif;if hasskill saucegeyser;skill saucegeyser;endif;attack with your weapon;repeat";

boolean simpleStatCheck() {
	foreach st in $stats[] {
		if (my_buffedstat(st).to_int() > 100)
		{
			return false;
		}
	}
	return true;
}

void main() {
	print("Attempting to access PirateRealm Trash island", "teal");
	if (get_property("_questPirateRealm") == "step9") {
		print("Already at trash island", "teal");
		return;
	}
	if (my_adventures() < 40) {
		print("Less than 40 adventures, acquiring more for piraterealm", "red");
		if (item_amount($item[astral six-pack]) > 0) {
			cli_execute("use astral six-pack");
		}
		if (item_amount($item[astral pilsner]) > 0) {
			cli_execute("cast ode to booze");
			cli_execute("drink astral pilsner");
		}
	}
	#Start, works!
	if ((item_amount($item[PirateRealm eyepatch]) == 0 && have_equipped($item[PirateRealm eyepatch]) == false)
		&& (get_property("_pirateRealmSailingTurns").to_int() == 0 && ((get_property("prAlways") == "true") || (get_property("_prToday") == "true")) && (get_property("_lastPirateRealmIsland") != "Trash Island") && (get_property("pirateRealmUnlockedAnemometer") == "true"))) {
		print("Trying to acquire eyepatch");
		visit_url("/place.php?whichplace=realm_pirate&action=pr_port");
		cli_execute("equip acc1 PirateRealm eyepatch");
	} else {
		print("Skipping acquiring piraterealm eyepatch");
		if (item_amount($item[PirateRealm eyepatch]) > 0) {
			cli_execute("equip acc1 PirateRealm eyepatch");
		} 
	}

	if (have_equipped($item[PirateRealm eyepatch]) == false) {
		abort("ERROR: PirateRealm eyepatch not equipped");
	}
	
	if (item_amount($item[windicle]) == 0) {
		print("Buying windicle");
		if ((closet_amount($item[windicle]).to_int() > 0) && (get_property("_lastPirateRealmIsland") != "Trash Island")) {
			cli_execute("closet take windicle");
		}

		if ((get_property("_pirateRealmSailingTurns").to_int() == 0) && (get_property("_lastPirateRealmIsland") != "Trash Island" && (get_property("pirateRealmUnlockedAnemometer") == "true") && (available_amount($item[windicle]).to_int() < 1))) {
			int windicle_limit = get_property("valueOfAdventure").to_int() * 3;
			cli_execute("buy windicle @" + windicle_limit);
		}
	}

	if (item_amount($item[HOA zombie eyes]) > 0) {
		print("Equipping HOA zombie eyes");
		cli_execute("equip acc2 HOA zombie eyes");
	}
	print("Calling KeepStatsLow");
	keepStatsLow();
	foreach st in $stats[] {
		print("Checking Stats: " + st);
		if (my_buffedstat(st).to_int() >= 100)
		{
			abort("ERROR: PR script found Stats over 100");
		}
	}

	#Works
	if ((get_property("_pirateRealmShipSpeed").to_int() < 1) && (get_property("_lastPirateRealmIsland") != "Trash Island") && (get_property("pirateRealmUnlockedClipper") == "true") ) {
		print("Port access with Clipper");
		visit_url("place.php?whichplace=realm_pirate&action=pr_port");
		run_choice(1);
		run_choice(1);
		run_choice(4);
		run_choice(4);
		run_choice(1);
	} else if ((get_property("_pirateRealmShipSpeed").to_int() < 1) && (get_property("_lastPirateRealmIsland") != "Trash Island") && (get_property("pirateRealmUnlockedClipper") == "false") ) {
		print("Port access without Clipper");
		visit_url("place.php?whichplace=realm_pirate&action=pr_port");
		run_choice(1);
		run_choice(1);
		run_choice(4);
		run_choice(3);
		run_choice(1);
	}


	if ((available_amount($item[Red Roger's red right foot]).to_int() == 1) && (get_property("_lastPirateRealmIsland") != "Trash Island") && (get_property("_pirateRealmIslandMonstersDefeated").to_int() == 0 )) {
		cli_execute("equip acc2 Red Roger's red right foot"); 
	}

	#Sailing... Works!
	while ((get_property("lastEncounter") != "Land Ho!") && (get_property("_pirateRealmShipSpeed").to_int() > 1) && (get_property("_pirateRealmIslandMonstersDefeated").to_int() <= 0) && (get_property("_lastPirateRealmIsland") != "Trash Island")) {
		print("Sail leg 1");
		cli_execute("set choiceAdventure1365 = 1");
		cli_execute("set choiceAdventure1352 = 1");
		cli_execute("set choiceAdventure1364 = 2");
		cli_execute("set choiceAdventure1361 = 1");
		cli_execute("set choiceAdventure1357 = 3");
		cli_execute("set choiceAdventure1360 = 6");
		cli_execute("set choiceAdventure1356 = 1");
		cli_execute("set choiceAdventure1362 = 2");
		cli_execute("set choiceAdventure1363 = 1");
		cli_execute("set choiceAdventure1355 = 1");
		cli_execute("set choiceAdventure1353 = 5");
		cli_execute("set choiceAdventure1367 = 2");
		cli_execute("set choiceAdventure1368 = 1");
		cli_execute("set choiceAdventure1358 = 2");
		cli_execute("set choiceAdventure1359 = 2");
		adv1($location[Sailing the PirateRealm Seas], -1, CrabFight);
	}

	#Giant CrabFight Works!
	if (item_amount($item[windicle]) > 0 &&
		(get_property("_pirateRealmWindicleUsed").to_boolean() == false) && (get_property("_pirateRealmIslandMonstersDefeated").to_int() <= 4) && (get_property("lastEncounter") == "Land Ho!") && (get_property("_lastPirateRealmIsland") != "Trash Island")) {
		print("Crab Fight with Windicle");
		cli_execute("maximize meat");
		cli_execute("equip June Cleaver");
		cli_execute("equip acc1 PirateRealm eyepatch");
		if (item_amount($item[HOA zombie eyes]) > 0 && !have_equipped($item[HOA zombie eyes]) && !simpleStatCheck()) {
			cli_execute("equip acc2 HOA zombie eyes");
		}
		keepStatsLow();
		adv1($location[PirateRealm Island], -1, Windy);
	}

	#Giant Giant Crab Fight, works!
	while ((get_property("_pirateRealmIslandMonstersDefeated").to_int() != 5) && (get_property("_lastPirateRealmIsland") != "Trash Island")) {
		print("Rest of Crab Fight");
		cli_execute("maximize meat");
		cli_execute("equip acc1 PirateRealm eyepatch");
		cli_execute("equip June Cleaver");
		if (item_amount($item[HOA zombie eyes]) > 0 && !have_equipped($item[HOA zombie eyes]) && !simpleStatCheck()) {
			cli_execute("equip acc2 HOA zombie eyes");
		}
		#Use Meat Buffs
		keepStatsLow();
		adv1($location[PirateRealm Island], -1, CrabFight);
	}

	#Works!
	if ((get_property("_pirateRealmIslandMonstersDefeated").to_int() == 5) && (get_property("_lastPirateRealmIsland") != "Trash Island")) {
		print("Unclear original purpose 1");
		if (item_amount($item[HOA zombie eyes]) > 0 && !have_equipped($item[HOA zombie eyes]) && !simpleStatCheck()) {
			cli_execute("equip acc2 HOA zombie eyes");
		}
		keepStatsLow();
		adv1($location[Sailing the PirateRealm Seas], -1, CrabFight);
	}
	if ((get_property("_pirateRealmIslandMonstersDefeated").to_int() == 5) && (get_property("_lastPirateRealmIsland") != "Trash Island")) {
		print("Unclear original purpose 2");
		if (item_amount($item[HOA zombie eyes]) > 0 && !have_equipped($item[HOA zombie eyes]) && !simpleStatCheck()) {
			cli_execute("equip acc2 HOA zombie eyes");
		}
		keepStatsLow();
        adv1($location[Sailing the PirateRealm Seas], -1, CrabFight);
    }
	int limit_turns = 0;
	while ((get_property("_questPirateRealm") != "step9")) {
		print("Sailing leg 2 turn: " + limit_turns);
		if (item_amount($item[HOA zombie eyes]) > 0 && !have_equipped($item[HOA zombie eyes]) && !simpleStatCheck()) {
			cli_execute("equip acc2 HOA zombie eyes");
		}
		keepStatsLow();
		adv1($location[Sailing the PirateRealm Seas], -1, CrabFight);
		limit_turns = limit_turns + 1;
		if (limit_turns >= 10) {
			abort("ERROR: PirateRealm sailing not completed after 10 turns");
		}
	}
	cli_execute("unequip acc1");

	print("PirateRealm Trash Unlock Script Finished");
	
}
