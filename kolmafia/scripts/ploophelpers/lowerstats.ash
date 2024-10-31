boolean check_effect(effect e) {
    return have_effect(e) > 0;
}

boolean have(item i) {
    return item_amount(i) > 0;
}

void keepStatsLow() {
  // Loop through each stat
  foreach st in $stats[] {
      // While the buffed stat is greater than 100
      while (my_buffedstat(st) > 100) {
          if (!check_effect($effect[Mush-Mouth]) && mall_price($item[Fun-Guy spore]) < 5000) {
              retrieve_item(1, $item[Fun-Guy spore]);
              use(1, $item[Fun-Guy spore]);
          }

          // Special handling for Muscle stat
          if (st == $stat[Muscle]) {
              if (!have($item[decorative fountain]) && !check_effect($effect[Sleepy]) && mall_price($item[decorative fountain]) < 2000) {
                  retrieve_item(1, $item[decorative fountain]);
              }
              if (!check_effect($effect[Sleepy])) {
                  use(1, $item[decorative fountain]);
              }
          }

          // Special handling for Moxie stat
          if (st == $stat[Moxie]) {
              if (!have($item[patchouli incense stick]) && !check_effect($effect[Far Out]) && mall_price($item[patchouli incense stick]) < 2000) {
                  retrieve_item(1, $item[patchouli incense stick]);
              }
              use(1, $item[patchouli incense stick]);

              if (check_effect($effect[Endless Drool])) {
                  cli_execute("shrug " + $effect[Endless Drool]);
              }
          }

          // General item and effect management
          if (mall_price($item[Mr. Mediocrebar]) < 2000 && !check_effect($effect[Apathy])) {
              retrieve_item(1, $item[Mr. Mediocrebar]);
              use(1, $item[Mr. Mediocrebar]);
          }

          if (check_effect($effect[Feeling Excited])) {
                cli_execute("shrug " + $effect[Feeling Excited]);
          }

          // Remove effects that affect the stat negatively
          foreach ef in my_effects() {
              if (numeric_modifier(ef, st.to_string()) > 0 &&
                  numeric_modifier(ef, "meat drop") <= 0 &&
                  numeric_modifier(ef, "familiar weight") == 0 &&
                  numeric_modifier(ef, "smithsness") == 0 
                  // && numeric_modifier(ef, "item drop") == 0
                  ) {
                  cli_execute("shrug " + ef);
              }
          }
      }
  }
}

void main() {
    keepStatsLow();
}
