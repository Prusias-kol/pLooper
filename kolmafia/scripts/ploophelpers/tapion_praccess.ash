string CrabFight = "if hasskill sing along; skill sing along;endif;if hasskill furious wallop;skill furious wallop;endif;if hasskill saucegeyser;skill saucegeyser;endif;attack with your weapon;repeat";
string Windy = "if hascombatitem windicle;use windicle;endif;if hasskill sing along; skill sing along;endif;if hasskill furious wallop;skill furious wallop;endif;if hasskill saucegeyser;skill saucegeyser;endif;attack with your weapon;repeat";

void main() {
	if (get_property("_lastPirateRealmIsland") == "Trash Island") {
		print("Already at trash island", "teal");
		return;
	}
	if (my_adventures() < 40) {
		if (item_amount($item[astral six-pack]) > 0) {
			cli_execute("use astral six-pack");
		}
		if (item_amount($item[astral pilsner]) > 0) {
			cli_execute("cast ode to booze");
			cli_execute("drink astral pilsner");
		}
	}
	#Start, works!
	if ((get_property("_pirateRealmSailingTurns").to_int() == 0 && ((get_property("prAlways") == "true") || (get_property("_prToday") == "true")) && (get_property("_lastPirateRealmIsland") != "Trash Island") && (get_property("pirateRealmUnlockedAnemometer") == "true"))) {
		visit_url("/place.php?whichplace=realm_pirate&action=pr_port");
		cli_execute("equip acc1 PirateRealm eyepatch");
	}
	
	if (item_amount($item[windicle]) == 0) {
		if ((closet_amount($item[windicle]).to_int() > 0) && (get_property("_lastPirateRealmIsland") != "Trash Island")) {
			cli_execute("closet take windicle");
		}

		if ((get_property("_pirateRealmSailingTurns").to_int() == 0) && (get_property("_lastPirateRealmIsland") != "Trash Island" && (get_property("pirateRealmUnlockedAnemometer") == "true") && (available_amount($item[windicle]).to_int() < 1))) {
			int windicle_limit = get_property("valueOfAdventure").to_int() * 3;
			cli_execute("buy windicle @" + windicle_limit);
		}
	}

	#Not working as intended: Always triggering despite stats meeting threshold, aria always uses support cumber to benefit stat boost... probably not viable to reduce stats
	foreach st in $stats[] {
		if ((my_buffedstat(st).to_int() >= 100) && (available_amount($item[HOA zombie eyes]).to_int() == 1)) {
			cli_execute("equip acc2 HOA zombie eyes");
		}
	}
	foreach eff in $effects[
        Spit Upon,
        Triple-Sized, 
		Feeling Excited,
		In the 'zone zone!,
		Confidence of the Votive,
		Pomp & Circumsands,
		Uncucumbered,
		Gummiheart,
		For Your Brain Only,
		Okee-Dokee Computer,
		Punch Another Day,
		License to Punch
	]
	{
		foreach st in $stats[] {
			if ((my_buffedstat(st).to_int() >= 100) && (have_effect(eff) != 0))
			{
				cli_execute("shrug " + eff);
			}
		}
	}
	foreach st in $stats[] {
		if (my_buffedstat(st).to_int() >= 100)
		{
			abort("Stats over 100");
		}
	}

	#Works
	if ((get_property("_pirateRealmShipSpeed").to_int() < 1) && (get_property("_lastPirateRealmIsland") != "Trash Island") && (get_property("pirateRealmUnlockedClipper") == "true") ) {
		visit_url("place.php?whichplace=realm_pirate&action=pr_port");
		run_choice(1);
		run_choice(1);
		run_choice(4);
		run_choice(4);
		run_choice(1);
		}
	
	if ((get_property("_pirateRealmShipSpeed").to_int() < 1) && (get_property("_lastPirateRealmIsland") != "Trash Island") && (get_property("pirateRealmUnlockedClipper") == "false") ) {
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
	if ((get_property("_pirateRealmIslandMonstersDefeated").to_int() <= 4) && (get_property("lastEncounter") == "Land Ho!") && (get_property("_lastPirateRealmIsland") != "Trash Island")) {
		cli_execute("maximize meat");
		cli_execute("equip June Cleaver");
		cli_execute("equip acc1 PirateRealm eyepatch");
		adv1($location[PirateRealm Island], -1, Windy);
		cli_execute("set WindicleUsed = true");
	}

	#Giant Giant Crab Fight, works!
	while ((get_property("_pirateRealmIslandMonstersDefeated").to_int() != 5) && (get_property("WindicleUsed") == "true") && (get_property("_lastPirateRealmIsland") != "Trash Island")) {
		cli_execute("maximize meat");
		cli_execute("equip acc1 PirateRealm eyepatch");
		cli_execute("equip June Cleaver");
		#Use Meat Buffs
		adv1($location[PirateRealm Island], -1, CrabFight);
	}

	#Works!
	if ((get_property("_pirateRealmIslandMonstersDefeated").to_int() == 5) && (get_property("_lastPirateRealmIsland") != "Trash Island")) {
		adv1($location[Sailing the PirateRealm Seas], -1, CrabFight);
		cli_execute("set WindicleUsed = false");
	}
	if ((get_property("_pirateRealmIslandMonstersDefeated").to_int() == 5) && (get_property("_lastPirateRealmIsland") != "Trash Island")) {
        adv1($location[Sailing the PirateRealm Seas], -1, CrabFight);
        cli_execute("set WindicleUsed = false");
        cli_execute("set WindicleSet = false");
    }
	int limit_turns = 0;
	while ((get_property("_lastPirateRealmIsland") != "Trash Island") && limit_turns < 5) {
		adv1($location[Sailing the PirateRealm Seas], -1, CrabFight);
	}
	cli_execute("unequip acc1");
	
}
