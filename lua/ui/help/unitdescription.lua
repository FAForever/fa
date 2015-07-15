﻿##****************************************************************************
#**  File     :  lua/modules/ui/help/unitdescriptions.lua
#**  Author(s):  Ted Snook
#**
#**  Summary  :  Strings and images for the unit rollover System
#**
#**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
 
Description = {
##UEF Units


   ##Commanders  
     ['uel0001'] = "<LOC Unit_Description_0303> Houses Commander. Combination barracks and command center. Contains all the blueprints necessary to build a basic army from scratch.",
     ['uel0001-tm'] = "<LOC Unit_Description_0004>Mounts a tactical cruise missile launcher onto the back of the ACU.",
     ['uel0001-aes'] = "<LOC Unit_Description_0005>Expands the number of available schematics and increases the ACU's build speed and maximum health.",
     ['uel0001-dsu'] = "<LOC Unit_Description_0006>Greatly increases the speed at which the ACU repairs itself.",
     ['uel0001-ees'] = "<LOC Unit_Description_0007>Replaces the Tech 2 Engineering Suite. Expands the number of available schematics and further increases the ACU's build speed and maximum health.",
     ['uel0001-hamc'] = "<LOC Unit_Description_0008>Increases main cannon's damage output by several factors. Also increases range of main cannon and Overcharge.",
     ['uel0001-srtn'] = "<LOC Unit_Description_0009>Adds a short-range tactical nuke.",
     ['uel0001-pqt'] = "<LOC Unit_Description_0010>Adds teleporter. Requires considerable Energy to activate.",
     ['uel0001-sgf'] = "<LOC Unit_Description_0011>Expands the radius of the ACU's personal shield. Requires Energy to run.",
     ['uel0001-isb'] = "<LOC Unit_Description_0012>Increases ACU's resource generation.",
     ['uel0001-psg'] = "<LOC Unit_Description_0013>Creates a protective shield around the ACU. Requires Energy to run.",
     ['uel0001-led'] = "<LOC Unit_Description_0014>Engineering Drone acts as a secondary Engineer. Assists the ACU where applicable.",
     ['uel0001-red'] = "<LOC Unit_Description_0015>Adds a second Engineering Drone. Requires an initial Engineering Drone.",
     
     
    ##Support Commanders 
   
   ['uel0301'] = "<LOC Unit_Description_0016> A multi-purpose construction, repair, capture and reclamation unit. Equivalent to a Tech 3 Engineer. ",
   ['uel0301-ed'] = "<LOC Unit_Description_0017> Engineering Drone acts as a secondary Engineer. Assists the SACU where applicable.",
   ['uel0301-psg'] = "<LOC Unit_Description_0018> Creates a protective shield around the SACU. Requires Energy to run.",
   ['uel0301-sgf'] = "<LOC Unit_Description_0019> Expands the radius of the SACU's personal shield. Requires Energy to run.",
   ['uel0301-rj'] = "<LOC Unit_Description_0020>Radar Jammer creates false radar images. Countered by Omni sensors.",
   ['uel0301-isb'] = "<LOC Unit_Description_0021> Increases SACU's resource generation.",
   ['uel0301-sre'] = "<LOC Unit_Description_0022>Greatly expands the range of the standard onboard SACU sensor systems.",
   ['uel0301-acu'] = "<LOC Unit_Description_0023>Rapidly cools any weapon mounted onto the SACU. Increases rate of fire.",
   ['uel0301-heo'] = "<LOC Unit_Description_0024>Equips the standard SACU Heavy plasma cannon with area-of-effect damage.",

   ## Support ACU presets
   ['uel0301_BubbleShield'] = "<LOC uel0301_BubbleShield_help>Support Armored Command Unit. Enhanced during construction with the bubble shield generator enhancement.",
   ['uel0301_Combat'] = "<LOC uel0301_Combat_help>Support Armored Command Unit. Enhanced during construction with the energy accelerator and heavy plasma refractor enhancements.",
   ['uel0301_Engineer'] = "<LOC uel0301_Engineer_help>Support Armored Command Unit. Enhanced during construction with the engineering drone enhancement.",
   ['uel0301_IntelJammer'] = "<LOC uel0301_IntelJammer_help>Support Armored Command Unit. Enhanced during construction with the radar jammer and enhanced sensor system enhancements.",
   ['uel0301_Rambo'] = "<LOC uel0301_Rambo_help>Support Armored Command Unit. Enhanced during construction with a personal shield, energy accelerator and heavy plasma refractor enhancements.",
   ['uel0301_RAS'] = "<LOC uel0301_RAS_help>Support Armored Command Unit. Enhanced during construction with a Resource Allocation System.",

    
    ##Land
    
    
   ['uel0101'] = "<LOC Unit_Description_0025>Fast, lightly armored reconnaissance vehicle. Armed with a machine gun and a state-of-the-art sensor suite.",
   ['uel0106'] = "<LOC Unit_Description_0026>Lightly armored mech. Provides direct-fire support against low-end units.",
   ['uel0103'] = "<LOC Unit_Description_0027>Versatile mobile artillery unit. Designed to engage enemy units at long range.",
   ['uel0104'] = "<LOC Unit_Description_0028>Mobile anti-air defense. Effective against low-end enemy air units.",
   ['uel0201'] = "<LOC Unit_Description_0029>Lightly armored tank. Armed with a single cannon.",
   ['uel0202'] = "<LOC Unit_Description_0030>Heavy tank. Equipped with reinforced armor and dual cannons.",
   ['uel0203'] = "<LOC Unit_Description_0031>Amphibious tank. Provides direct-fire support with two riot guns.", 
   ['uel0111'] = "<LOC Unit_Description_0032>Heavily armored, mobile tactical missile launcher. Designed to attack at long range.",
   ['uel0205'] = "<LOC Unit_Description_0033>Mobile AA unit. Armed with flak artillery.",
   ['uel0307'] = "<LOC Unit_Description_0034>Mobile shield generator.",
   ['uel0303'] = "<LOC Unit_Description_0035>Shielded heavy assault bot. Armed with two cannons and tactical rocket launcher.",
   ['uel0304'] = "<LOC Unit_Description_0036>Slow-moving heavy artillery. Must be stationary to fire.",
   ['uel0401'] = "<LOC Unit_Description_0037>Experimental, amphibious mobile factory. Equipped with battleship-level weapons and armor. Its shield consumes Energy.",
   ['xel0305'] = "<LOC Unit_Description_0307> Slow-moving, heavily armored assault bot. Designed to engage base defenses and structures.",
   ['xel0306'] = "<LOC Unit_Description_0308> Mobile missile launcher. Long reload time. Designed to overwhelm enemy shields and tactical missile defenses with large salvos.",

   
   ##AIR
   
   
   ['uea0101'] = "<LOC Unit_Description_0038>Standard air scout.",
   ['uea0102'] = "<LOC Unit_Description_0039>Quick, maneuverable fighter. Armed with linked AA railguns.",
   ['uea0103'] = "<LOC Unit_Description_0040>Lightly armored area-of-effect bomber.",
   ['uea0107'] = "<LOC Unit_Description_0041>Low-end air transport. Can carry up to 6 units.",
   ['uea0203'] = "<LOC Unit_Description_0042>Light gunship. Equipped with one riot gun and a single transportation clamp.",
   ['uea0204'] = "<LOC Unit_Description_0043>Torpedo bomber. Armed with a payload of Angler torpedoes.",
   ['uea0302'] = "<LOC Unit_Description_0044>Extremely fast spy plane. Equipped with mid-level surveillance equipment.",
   ['uea0104'] = "<LOC Unit_Description_0045>Heavily armed, mid-level air transport. Equipped with riot guns and AA weapons. Can carry up to 12 units.",
   ['uea0303'] = "<LOC Unit_Description_0046>High-end air fighter. Designed to engage air units of any type.",
   ['uea0304'] = "<LOC Unit_Description_0047>High-end strategic bomber. Armed with a small yield nuclear bomb and light AA gun.",
   ['uea0305'] = "<LOC Unit_Description_0048>Heavy gunship. Armed with two tactical rocket launchers and an AA railgun.", 
   ['xea0306'] = "<LOC Unit_Description_0309> Heavy air transport. Features 28 transportation clamps, heavy cannons, missile launchers and a shield generator. Can carry up to 28 units.",
      
      
    ##SEA
    
      
   ['ues0103'] = "<LOC Unit_Description_0049>Naval support unit. Equipped with a single cannon, AA railgun, radar, sonar and radar jammer.",
   ['ues0203'] = "<LOC Unit_Description_0050>Low-end attack submarine.",
   ['ues0202'] = "<LOC Unit_Description_0051>Anti-aircraft naval vessel. Armed with AA missile system, SAM system and tactical missile launcher.", 
   ['ues0201'] = "<LOC Unit_Description_0052>Mid-level naval unit. Equipped with a torpedo bay, anti-torpedo defense, dual cannons and a single AA weapon.",
   ['ues0302'] = "<LOC Unit_Description_0053>Shore bombardment and anti-ship vessel. Armed with three heavy cannons, four AA railguns and two anti-missile guns.",
   ['ues0304'] = "<LOC Unit_Description_0054>Strategic missile submarine. Armed with long-range tactical missiles and a strategic missile launcher.",
   ['ues0401'] = "<LOC Unit_Description_0055>Submersible aircraft carrier. Can store, transport and repair aircraft. Armed with torpedo launchers and AA weapons.",
   ['xes0102'] = "<LOC Unit_Description_0310> Dedicated sub-killer. Armed with a torpedo tube and anti-torpedo charges.",
   ['xes0205'] = "<LOC Unit_Description_0311> Naval shield generator. Provides protection for all nearby vessels.",
   ['xes0307'] = "<LOC Unit_Description_0312> High-end anti-naval vessel. Armed with plasma beams, torpedo systems, anti-missile defenses and anti-torpedo charges.",

  
  
   ##['ues0001'] = "<LOC Unit_Description_0056>The UEF Supreme commander Description",

   
   
   ##Buildings 
   
   
   ['ueb2101'] = "<LOC Unit_Description_0057> Low-end defensive tower that attacks land- and sea-based units. Does not engage aircraft or submerged units.",
   ['ueb2104'] = "<LOC Unit_Description_0058> Anti-air tower. Designed to engage low-end aircraft.",
	 ['ueb2109'] = "<LOC Unit_Description_0059>Basic anti-naval defense system.",
   ['ueb5101'] = "<LOC Unit_Description_0060> Restricts the movement of enemy units. Offers minimal protection from enemy fire.",
   ['ueb2301'] = "<LOC Unit_Description_0061> Heavily armored defensive tower that attacks land- and sea-based units. Does not engage aircraft or submerged units.",
   ['ueb2204'] = "<LOC Unit_Description_0062> Anti-air tower. Designed to engage mid-level aircraft.",
   ['ueb4201'] = "<LOC Unit_Description_0063> Tactical missile defense. Protection is limited to the structure's operational area.",
	 ['ueb2205'] = "<LOC Unit_Description_0064> Anti-naval defense system. Designed to engage all naval units.",
	 ['ueb4202'] = "<LOC Unit_Description_0065> Generates a protective shield around units and structures within its radius.",

   ['ueb2304'] = "<LOC Unit_Description_0066> High-end anti-air tower. Designed to engage all levels of aircraft.",
   ['ueb4302'] = "<LOC Unit_Description_0067> Strategic missile defense. Protection is limited to the structure's operational area.",
   ['ueb4301'] = "<LOC Unit_Description_0068> Generates a heavy shield around units and structures within its radius.",
   ['ueb2303'] = "<LOC Unit_Description_0069>Stationary artillery. Designed to engage slow-moving units and fixed structures.",
   ['ueb2108'] = "<LOC Unit_Description_0070> Tactical missile launcher. Must be ordered to construct missiles.",
   ['ueb5202'] = "<LOC Unit_Description_0071> Refuels and repairs aircraft. Air patrols will automatically use facility.",
   ['ueb2302'] = "<LOC Unit_Description_0072> Stationary heavy artillery with excellent range, accuracy and damage potential. ",
   ['ueb2305'] = "<LOC Unit_Description_0073> Strategic missile launcher. Constructing missiles costs resources. Must be ordered to construct missiles.",
   ['ueb0304'] = "<LOC Unit_Description_0074> Summons Support Commander(s).",
   ['ueb2401'] = "<LOC Unit_Description_0075> Extremely advanced strategic artillery. Unlimited range, pin-point accuracy and devastating ordinance.",
   ['xeb2306'] = "<LOC Unit_Description_0313> Heavy defensive tower. Attacks land- and sea-based units. Does not engage aircraft or submerged units.",
   ['xeb2402'] = "<LOC Unit_Description_0314> Satellite-based weapon system. Attacks enemy units and structures. If its control center is destroyed, the weapon is immediately disabled.",

   
   
   ##Engineers
   
   ['uel0105'] = "<LOC Unit_Description_0076> Tech 1 amphibious construction, repair, capture and reclamation unit.",
   ['uel0208'] = "<LOC Unit_Description_0077> Tech 2 amphibious construction, repair, capture and reclamation unit.",
   ['uel0309'] = "<LOC Unit_Description_0078> Tech 3 amphibious construction, repair, capture and reclamation unit.",
   ['xel0209'] = "<LOC Unit_Description_0315> Tech 2 amphibious construction, repair, capture and reclamation unit. Armed with a Riot Gun and internal radar and jammer.",
   ['xeb0104'] = "<LOC Unit_Description_0446> Automatically repairs, reclaims, assists or captures any unit within its operational radius.",   
   ['xeb0204'] = "<LOC Unit_Description_0453> Automatically repairs, reclaims, assists or captures any unit within its operational radius.",
            
   ##Factories
    
    
   ['ueb0101'] = "<LOC Unit_Description_0079> Constructs Tech 1 land units. Upgradeable.",
   ['ueb0102'] = "<LOC Unit_Description_0080> Constructs Tech 1 air units. Upgradeable.",
   ['ueb0103'] = "<LOC Unit_Description_0081> Constructs Tech 1 naval units. Upgradeable.",
   
   
   ['ueb0201'] = "<LOC Unit_Description_0082> Constructs Tech 2 land units. Upgradeable.",
   ['ueb0202'] = "<LOC Unit_Description_0083> Constructs Tech 2 air units. Upgradeable.",
   ['ueb0203'] = "<LOC Unit_Description_0084> Constructs Tech 2 naval units. Upgradeable.",
 
 
   ['ueb0301'] = "<LOC Unit_Description_0085> Constructs Tech 3 land units. Highest tech level available.",
   ['ueb0302'] = "<LOC Unit_Description_0086> Constructs Tech 3 air units. Highest tech level available.",
   ['ueb0303'] = "<LOC Unit_Description_0087> Constructs Tech 3 naval units. Highest tech level available.",
   
   
   #Buildings
   
   ['ueb1101'] = "<LOC Unit_Description_0088> Generates Energy. Construct next to other structures for adjacency bonus.",
   ['ueb1102'] = "<LOC Unit_Description_0089> Generates Energy. Must be constructed on hydrocarbon deposits. Construct structures next to Hydrocarbon power plant for adjacency bonus.",
   ['ueb1105'] = "<LOC Unit_Description_0090> Stores Energy. Construct next to power generators for adjacency bonus.",
   ['ueb1103'] = "<LOC Unit_Description_0091> Extracts Mass. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
   ['ueb1104'] = "<LOC Unit_Description_0092> Creates Mass. Requires large amounts of Energy. Construct next to other structures for adjacency bonus.",
   ['ueb1106'] = "<LOC Unit_Description_0093> Stores Mass. Construct next to extractors or fabricators for adjacency bonus.",
   ['ueb1201'] = "<LOC Unit_Description_0094> Mid-level power generator. Construct next to other structures for adjacency bonus.",
   ['ueb1202'] = "<LOC Unit_Description_0095> Mid-level Mass extractor. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
   ['ueb1301'] = "<LOC Unit_Description_0096> High-end power generator. Construct next to other structures for adjacency bonus.",
   ['ueb1302'] = "<LOC Unit_Description_0097> High-end Mass extractor. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
   ['ueb1303'] = "<LOC Unit_Description_0098> High-end Mass fabricator. Requires large amounts of Energy. Construct next to other structures for adjacency bonus.",
   ['ueb3101'] = "<LOC Unit_Description_0099> Radar system with minimal range. Detects and tracks surface and air units.",
   ['ueb3102'] = "<LOC Unit_Description_0100> Sonar system with minimal range. Detects and tracks naval units.",
   ['ueb3201'] = "<LOC Unit_Description_0101> Radar system with moderate range. Detects and tracks surface and air units.",
   ['ueb3202'] = "<LOC Unit_Description_0102> Sonar system with moderate range. Detects and tracks naval units.",
   ['ueb4203'] = "<LOC Unit_Description_0103> Generates stealth field. Hides units and structures within its operational range. Countered by optical and Omni sensors.",
   ['ues0305'] = "<LOC Unit_Description_0104> Sonar system with exceptional range. Detects and tracks naval units. Armed with a bottom-mounted torpedo turret.",
   ['ueb3104'] = "<LOC Unit_Description_0105> High-end intelligence system. Provides maximum radar and sonar coverage. Counters enemy intelligence systems.",
   
   
   
   
   
   
   
   ##CYBRAN UNITS
   
   
   #Commanders  
   
   ['url0001'] = "<LOC Unit_Description_0304> Houses Commander. Combination barracks and command center. Contains all the blueprints necessary to build a basic army from scratch.",   
   ['url0001-ras'] = "<LOC Unit_Description_0106> Increases ACU's resource generation.",
   ['url0001-pcg'] = "<LOC Unit_Description_0107> Cloaks the ACU from optical sensors and increases maximum health. Can be detected by Omni Sensors. Requires Energy to run.",
   ['url0001-psg'] = "<LOC Unit_Description_0108> Hides the ACU from radar. Requires Energy to run.",
   ['url0001-pqt'] = "<LOC Unit_Description_0109> Adds teleporter. Requires considerable Energy to activate.",
   ['url0001-aes'] = "<LOC Unit_Description_0110> Expands the number of available schematics and increases the ACU's build speed and maximum health.",
   ['url0001-ees'] = "<LOC Unit_Description_0111> Replaces the Tech 2 Engineering Suite. Expands the number of available schematics and further increases the ACU's build speed and maximum health.",
   ['url0001-acu'] = "<LOC Unit_Description_0112> Increases main cannon's rate of fire and range. Also increases range of the Molecular Ripper and Overcharge.",
   ['url0001-mlg'] = "<LOC Unit_Description_0113>ACU can generate a beam laser that sweeps over enemy units.",
   ['url0001-ntt'] = "<LOC Unit_Description_0114>Equips the ACU with a standard Cybran Nanite torpedo tube and sonar.",
  
    
     
    ##Support Commanders 
   
   ['url0301'] = "<LOC Unit_Description_0115> A multi-purpose construction, repair, capture and reclamation unit. Equivalent to a Tech 3 Engineer.",
   ['url0301-cfs'] = "<LOC Unit_Description_0116> Cloaks the SACU from optical sensors. Can be detected by Omni Sensors. Requires Energy to run.",
   ['url0301-emp'] = "<LOC Unit_Description_0117>EMP burst effectively disables enemy units for a few seconds.",
   ['url0301-fc'] = "<LOC Unit_Description_0118> Greatly enhances the pulse laser's cohesion, almost doubling its damage output.",
   ['url0301-nms'] = "<LOC Unit_Description_0119>Adds AA defensive system.",
   ['url0301-ras'] = "<LOC Unit_Description_0120> Increases SACU's resource generation.",
   ['url0301-ses'] = "<LOC Unit_Description_0121>Speeds up all engineering-related functions.",
   ['url0301-srs'] = "<LOC Unit_Description_0122> Greatly increases the speed at which the SACU repairs itself.",
   ['url0301-sfs'] = "<LOC Unit_Description_0123> Hides the SACU from radar. Requires Energy to run.",
  
   ## Support ACU presets
   ['url0301_AntiAir'] = "<LOC url0301_AntiAir_help>Support Armored Command Unit. Enhanced during construction with the nanite missile system enhancement.",
   ['url0301_Cloak'] = "<LOC url0301_Cloak_help>Support Armored Command Unit. Enhanced during construction with the personal cloaking generator and disintegrator amplifier enhancements.",
   ['url0301_Combat'] = "<LOC url0301_Combat_help>Support Armored Command Unit. Enhanced during construction with the EMP burst and disintegrator amplifier enhancements.",
   ['url0301_Engineer'] = "<LOC url0301_Engineer_help>Support Armored Command Unit. Enhanced during construction with the rapid fabricator enhancement.",
   ['url0301_Rambo'] = "<LOC url0301_Rambo_help>Support Armored Command Unit. Enhanced during construction with the EMP burst, disintegrator amplifier and nano-repair system enhancements.",
   ['url0301_RAS'] = "<LOC url0301_RAS_help>Support Armored Command Unit. Enhanced during construction with a Resource Allocation System.",
   ['url0301_Stealth'] = "<LOC url0301_Stealth_help>Support Armored Command Unit. Enhanced during construction with the personal stealth generator enhancement.",

   ##Land units
   
   ['url0101'] = "<LOC Unit_Description_0124> Fast, lightly armored reconnaissance vehicle. Equipped with a cloaking field.",
   ['url0106'] = "<LOC Unit_Description_0125>Lightly armored strike bot. Provides direct-fire support against low-end units.",
   ['url0107'] = "<LOC Unit_Description_0126>Assault bot. Equipped with two heavy laser autoguns and can self-repair itself.", 
   ['url0103'] = "<LOC Unit_Description_0127> Versatile mobile artillery unit. Designed to engage enemy units at long range and disable them with an EMP blast.",
   ['url0104'] = "<LOC Unit_Description_0128> Primary function is anti-air defense. Can be configured to attack land units.",
   ['url0202'] = "<LOC Unit_Description_0129>Heavy tank. Armed with two cannons.",
   ['url0203'] = "<LOC Unit_Description_0130>Submersible, amphibious tank. Armed with a heavy bolter and torpedo launcher.",
   ['url0111'] = "<LOC Unit_Description_0131>Mobile missile launcher. Designed to attack at long range.",
   ['url0205'] = "<LOC Unit_Description_0132> Mobile AA unit. Armed with flak artillery.",
   ['url0306'] = "<LOC Unit_Description_0133>Mobile stealth generator.",
   ['url0303'] = "<LOC Unit_Description_0134>Siege assault bot. Armed with a Disintegrator Pulse laser and heavy bolter.",
   ['url0304'] = "<LOC Unit_Description_0135> Slow-moving heavy artillery. Must be stationary to fire.",
   ['url0402'] = "<LOC Unit_Description_0136>Experimental bot. Consumes massive amounts of Energy. Its main laser sweeps across any enemy to its front. Also armed with AA defenses.",
   ['url0401'] = "<LOC Unit_Description_0137>Experimental, rapid-fire artillery. Consumes massive amounts of Energy with each shot. Must be stationary to fire. ",
   ['xrl0302'] = "<LOC Unit_Description_0317> Mobile bomb. Must be moved into position and manually detonated.",
   ['xrl0305'] = "<LOC Unit_Description_0318> Amphibious assault bot. Capable of attacking land and naval units.",
   ['xrl0403'] = "<LOC Unit_Description_0319> Massive experimental bot. Equipped with Dual-Proton cannons, AA defenses, torpedo launchers and anti-torpedo flares. Drops 'eggs' that can be transformed into a single unit.",
   
   
   ##Crab Egg Units
   
   ['xrl0002'] = "<LOC Unit_Description_0447> Tech 3 amphibious construction, repair, capture and reclamation unit.",
   ['xrl0003'] = "<LOC Unit_Description_0448> Amphibious assault bot. Capable of attacking land and naval units.",
   ['xrl0004'] = "<LOC Unit_Description_0449> Mobile AA unit. Armed with flak artillery.",
   ['xrl0005'] = "<LOC Unit_Description_0450> Slow-moving heavy artillery. Must be stationary to fire.",
   
   ##Air units
   ['ura0101'] = "<LOC Unit_Description_0138> Standard air scout.",
   ['ura0102'] = "<LOC Unit_Description_0139> Quick, maneuverable fighter. Armed with an auto-cannon.",
   ['ura0103'] = "<LOC Unit_Description_0140> Lightly armored area-of-effect bomber.",
   ['ura0107'] = "<LOC Unit_Description_0141> Low-end air transport. Can carry up to 6 units.",
   ['ura0203'] = "<LOC Unit_Description_0142>Fast-attack copter. Armed with twin rocket tubes.",
   ['ura0204'] = "<LOC Unit_Description_0143> Mid-level torpedo bomber.",
   ['ura0302'] = "<LOC Unit_Description_0144> Extremely fast spy plane with free, permanent stealth.",
   ['ura0104'] = "<LOC Unit_Description_0145> Mid-level air transport. Armed with an auto-cannon and AA defense system. Can carry up to 10 units.",
   ['ura0303'] = "<LOC Unit_Description_0146> High-end air fighter. Designed to engage air units of any type.",
   ['ura0304'] = "<LOC Unit_Description_0147> High-end strategic bomber. Armed with a Proton bomb, stealth field generator and AA flak cannon.",
   ['ura0401'] = "<LOC Unit_Description_0148>Experimental gunship. Delivers extreme firepower via rocket racks, electron bolters and missile system.",
   ['xra0105'] = "<LOC Unit_Description_0320> Light gunship. Primary role is base defense. Effective against low-level ground units.",
   ['xra0305'] = "<LOC Unit_Description_0321> Heavy gunship armed with Nanite missiles, Disintegration Pulse lasers and a radar jamming suite. Offers direct fire support.",
   
   
   ##Naval Units
   ['urs0103'] = "<LOC Unit_Description_0149> Naval radar and sonar platform. Armed with a Proton cannon and an AA auto-cannon.",
   ['urs0203'] = "<LOC Unit_Description_0150>Attack submarine. Armed with a Nanite torpedo launcher and a deck-mounted heavy laser.",
   ['urs0202'] = "<LOC Unit_Description_0151>Anti-air naval vessel. Equipped with AA turrets and short-range rocket platform.",
   ['urs0201'] = "<LOC Unit_Description_0152>Amphibious destroyer. Armed with a single Dual-Proton cannon, AA auto-cannon and torpedo tubes.",
   ['urs0302'] = "<LOC Unit_Description_0153>Direct fire and bombardment naval vessel. Armed with six Proton cannons, dual AA auto-cannons, anti-missile turrets and torpedo tubes.",
   ['urs0303'] = "<LOC Unit_Description_0154>Aircraft carrier. Can store, transport and repair aircraft. Armed with light AA auto-cannons and an anti-missile turret.",
   ['urs0304'] = "<LOC Unit_Description_0155>Strategic missile submarine. Armed with a strategic missile launcher, tactical missile launcher and torpedo tubes.",
   ['xrs0204'] = "<LOC Unit_Description_0322> Mid-level anti-naval unit. Equipped with mobile sonar stealth. Effective against surface vessels and submerged units.", 
   ['xrs0205'] = "<LOC Unit_Description_0323> Unarmed counter-intelligence vessel. Equipped with stealth field that counters enemy sonar and radar.",

   
  
   ['urb2101'] = "<LOC Unit_Description_0176> Low-end defensive tower that attacks land- and sea-based units. Does not engage aircraft or submerged units.",
   ['urb2104'] = "<LOC Unit_Description_0177> Anti-air tower. Designed to engage low-end aircraft.",
   ['urb2109'] = "<LOC Unit_Description_0178> Anti-naval defense system.",
   ['urb5101'] = "<LOC Unit_Description_0179> Restricts the movement of enemy units. Offers minimal protection from enemy fire.",
   ['urb2301'] = "<LOC Unit_Description_0180> Heavily armored defensive tower that attacks land- and sea-based units. Does not engage aircraft or submerged units.",
   ['urb2204'] = "<LOC Unit_Description_0181> Anti-air tower. Designed to engage mid-level aircraft.",
   ['urb4201'] = "<LOC Unit_Description_0182> Tactical missile defense. Protection is limited to the structure's operational area.",
   ['urb2205'] = "<LOC Unit_Description_0183> Anti-naval defense system. Designed to engage all naval units.",
   ['urb4202'] = "<LOC Unit_Description_0184> Generates a protective shield around units and structures within its radius. Shield can be upgraded four times.",
   ['urb4202-ch'] = "<LOC Unit_Description_0306>Upgrade increases shield's size, strength and operating costs.",
   ['xrb0104'] = "<LOC Unit_Description_0451> Automatically repairs, reclaims, assists or captures any unit within its operational radius.",
   ['xrb0204'] = "<LOC Unit_Description_0324> Automatically repairs, reclaims, assists or captures any unit within its operational radius.",
   ['xrb0304'] = "<LOC Unit_Description_0452> Automatically repairs, reclaims, assists or captures any unit within its operational radius.",
   ['xrb2308'] = "<LOC Unit_Description_0325> Submerged torpedo launcher. Capable of destroying the largest of enemy vessels.",
   ['xrb3301'] = "<LOC Unit_Description_0326> Offers complete line-of-sight within its operational area.",
   
   ['urb2304'] = "<LOC Unit_Description_0185> High-end anti-air tower. Designed to engage all levels of aircraft.",
   ['urb4302'] = "<LOC Unit_Description_0186> Strategic missile defense. Protection is limited to the structure's operational area.",
   ['urb2303'] = "<LOC Unit_Description_0187>Heavy artillery. Designed to engage slow-moving units and fixed structures.",
   ['urb2108'] = "<LOC Unit_Description_0188>Tactical missile launcher. Must be ordered to construct missiles.",
   ['urb5202'] = "<LOC Unit_Description_0189> Refuels and repairs aircraft. Air patrols will automatically use facility.",
   ['urb2302'] = "<LOC Unit_Description_0190> Heavy artillery with excellent range, accuracy and damage potential.",
   ['urb2305'] = "<LOC Unit_Description_0191> Strategic missile launcher. Constructing missiles costs resources. Must be ordered to construct missiles.",
   ['urb0304'] = "<LOC Unit_Description_0192> Summons Support Commander(s).",
   
   ##engineers
   ['url0105'] = "<LOC Unit_Description_0193> Tech 1 amphibious construction, repair, capture and reclamation unit.",
   ['url0208'] = "<LOC Unit_Description_0194> Tech 2 amphibious construction, repair, capture and reclamation unit.",
   ['url0309'] = "<LOC Unit_Description_0195> Tech 3 amphibious construction, repair, capture and reclamation unit.",
   
   ##Factories etc
   ['urb0101'] = "<LOC Unit_Description_0196> Constructs Tech 1 land units. Upgradeable.",
   ['urb0102'] = "<LOC Unit_Description_0197> Constructs Tech 1 air units. Upgradeable.",
   ['urb0103'] = "<LOC Unit_Description_0198> Constructs Tech 1 naval units. Upgradeable.",
   ['urb0201'] = "<LOC Unit_Description_0199> Constructs Tech 2 land units. Upgradeable.",
   ['urb0202'] = "<LOC Unit_Description_0200> Constructs Tech 2 air units. Upgradeable.",
   ['urb0203'] = "<LOC Unit_Description_0201> Constructs Tech 2 naval units. Upgradeable.",
   ['urb0301'] = "<LOC Unit_Description_0202> Constructs Tech 3 land units. Highest tech level available.",
   ['urb0302'] = "<LOC Unit_Description_0203> Constructs Tech 3 air units. Highest tech level available.",
   ['urb0303'] = "<LOC Unit_Description_0204> Constructs Tech 3 naval units. Highest tech level available.",
   
   
   ##Base stuff
   ['urb1101'] = "<LOC Unit_Description_0205> Generates Energy. Construct next to other structures for adjacency bonus.",
   ['urb1102'] = "<LOC Unit_Description_0206> Generates Energy. Must be constructed on hydrocarbon deposits. Construct structures next to Hydrocarbon power plant for adjacency bonus.",
   ['urb1103'] = "<LOC Unit_Description_0207> Extracts Mass. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
   ['urb1104'] = "<LOC Unit_Description_0208> Creates Mass. Requires large amounts of Energy. Construct next to other structures for adjacency bonus.",
   ['urb1106'] = "<LOC Unit_Description_0209> Stores Mass. Construct next to extractors or fabricators for adjacency bonus.",
   ['urb1105'] = "<LOC Unit_Description_0210> Stores Energy. Construct next to power generators for adjacency bonus.",
   ['urb1201'] = "<LOC Unit_Description_0211> Mid-level power generator. Construct next to other structures for adjacency bonus.",
   ['urb1202'] = "<LOC Unit_Description_0212> Mid-level Mass extractor. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
   ['urb1301'] = "<LOC Unit_Description_0213> High-end power generator. Construct next to other structures for adjacency bonus.",
   ['urb1302'] = "<LOC Unit_Description_0214> High-end Mass extractor. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
   ['urb1303'] = "<LOC Unit_Description_0215> High-end Mass fabricator. Requires large amounts of Energy. Construct next to other structures for adjacency bonus.",
   ['urb3101'] = "<LOC Unit_Description_0216> Radar system with minimal range. Detects and tracks surface and air units.",
   ['urb3102'] = "<LOC Unit_Description_0217> Sonar system with minimal range. Detects and tracks naval units.",
   ['urb3201'] = "<LOC Unit_Description_0218> Radar system with moderate range. Detects and tracks surface and air units.",
   ['urb3202'] = "<LOC Unit_Description_0219> Sonar system with moderate range. Detects and tracks naval units.",
   ['urb4203'] = "<LOC Unit_Description_0220> Generates stealth field. Hides units and structures within its operational range. Countered by optical and Omni sensors.",
   ['urs0305'] = "<LOC Unit_Description_0221> Sonar system with exceptional range. Detects and tracks naval units. Equipped with a stealth field generator.",
   ['urb3104'] = "<LOC Unit_Description_0222> High-end intelligence system. Provides maximum radar and sonar coverage. Counters enemy intelligence systems.",

   
   
   
   
   
   ##AEON UNITS
   
   
   #Commanders  
   
   ['ual0001'] = "<LOC Unit_Description_0305> Houses Commander. Combination barracks and command center. Contains all the blueprints necessary to build a basic army from scratch.",
   ['ual0001-aes'] = "<LOC Unit_Description_0156> Expands the number of available schematics and increases the ACU's build speed and maximum health.",
   ['ual0001-cd'] = "<LOC Unit_Description_0157>Creates a Quantum Stasis Field around the ACU. Immobilizes enemy units within its radius. High Energy Consumption.",
   ['ual0001-cba'] = "<LOC Unit_Description_0158>Enhances the ACU's Quantum Disrupter beam. Nearly doubles its range.",
   ['ual0001-ess'] = "<LOC Unit_Description_0159> Greatly expands the range of the standard onboard ACU sensor systems.",
   ['ual0001-ees'] = "<LOC Unit_Description_0160> Replaces the Tech 2 Engineering Suite. Expands the number of available schematics and further increases the ACU's build speed and maximum health.",
   ['ual0001-hsa'] = "<LOC Unit_Description_0161> Rapidly cools the Quantum Disruptor beam. Increases rate of fire.",
   ['ual0001-ras'] = "<LOC Unit_Description_0162> Increases ACU's resource generation.",
   ['ual0001-eras'] = "<LOC Unit_Description_0163> Requires Resource Allocation System. Further increases ACU's resource generation.",
   ['ual0001-ptsg'] = "<LOC Unit_Description_0164> Creates a protective shield around the ACU. Requires Energy to run.",
   ['ual0001-phtsg'] = "<LOC Unit_Description_0165> Enhances the protective shield around the ACU. Requires Energy to run.",
   ['ual0001-pqt'] = "<LOC Unit_Description_0166> Adds teleporter. Requires considerable Energy to activate.",
  
   
   
   ## Support Commanders 
   
   ['ual0301'] = "<LOC Unit_Description_0167> A multi-purpose construction, repair, capture and reclamation unit. Equivalent to a Tech 3 Engineer.",
   ['ual0301-efm'] = "<LOC Unit_Description_0168>Speeds up all engineering-related functions.",
   ['ual0301-ras'] = "<LOC Unit_Description_0169> Increases SACU's resource generation.",
   ['ual0301-sp'] = "<LOC Unit_Description_0170>SACU is sacrificed and its Mass is added to a structure. This destroys the SACU.",
   ['ual0301-tsg'] = "<LOC Unit_Description_0171> Creates a protective shield around the SACU.",
   ['ual0301-htsg'] = "<LOC Unit_Description_0172> Upgrades the SACU's protective shield. Requires Energy to run.",
   ['ual0301-ss'] = "<LOC Unit_Description_0173> Equips the standard SACU's Reacton cannon with area-of-effect damage.",
   ['ual0301-sic'] = "<LOC Unit_Description_0174> Greatly increases the speed at which the SACU repairs itself.",
   ['ual0301-pqt'] = "<LOC Unit_Description_0175> Adds teleporter. Requires considerable Energy to activate.",

   ## Support ACU presets
   ['ual0301_Engineer'] = "<LOC ual0301_Engineer_help>SACU upgraded with Rapid Fabricator.",
   ['ual0301_NanoCombat'] = "<LOC ual0301_NanoCombat_help>Support Armored Command Unit. Enhanced during construction with the reacton refractor and nano-repair system enhancements.",
   ['ual0301_Rambo'] = "<LOC ual0301_Rambo_help>Support Armored Command Unit. Enhanced during construction with a heavy personal shield and the reacton refractor enhancements.",
   ['ual0301_RAS'] = "<LOC ual0301_RAS_help>Support Armored Command Unit. Enhanced during construction with a Resource Allocation System.",
   ['ual0301_ShieldCombat'] = "<LOC ual0301_ShieldCombat_help>Support Armored Command Unit. Enhanced during construction with a personal shield and the reacton refractor enhancements.",
   ['ual0301_SimpleCombat'] = "<LOC ual0301_SimpleCombat_help>Support Armored Command Unit. Enhanced during construction with the reacton refractor enhancement.",
   
   ##Land
   ['ual0101'] = "<LOC Unit_Description_0223> Fast, lightly armored reconnaissance vehicle. Armed with a laser and a state-of-the-art sensor suite.",
   ['ual0106'] = "<LOC Unit_Description_0224> Fast, lightly armored assault bot. Fires a short-range sonic weapon.",
   ['ual0201'] = "<LOC Unit_Description_0225> Amphibious light tank. Armed with a single cannon.",
   ['ual0103'] = "<LOC Unit_Description_0226> Mobile light artillery. Designed to engage enemy units at long range.",
   ['ual0104'] = "<LOC Unit_Description_0227> Mobile anti-air unit. Effective against low-end enemy air units.",
   ['ual0202'] = "<LOC Unit_Description_0228> Heavy tank. Equipped with a single cannon and a shield generator.",
   ['ual0111'] = "<LOC Unit_Description_0229> Mobile tactical missile launcher. Missile has medium range and inflicts light damage.",
   ['ual0205'] = "<LOC Unit_Description_0230> Mobile AA unit. Armed with a temporal AA Fizz launcher.",
   ['ual0307'] = "<LOC Unit_Description_0231> Mobile shield generator.",
   ['ual0303'] = "<LOC Unit_Description_0232> Shielded Siege assault bot. Armed with a high-intensity laser. Can repair and reclaim Mass.",
   ['ual0304'] = "<LOC Unit_Description_0233> Slow-moving heavy artillery. Must be stationary to fire.",
   ['ual0401'] = "<LOC Unit_Description_0234>Sacred assault bot. Incinerates enemy units and structures with Phason laser. Also equipped with tractor beam. Pulls in and crushes mobile enemy units.",
   ['xal0203'] = "<LOC Unit_Description_0327> Fast, lightly armored tank. Armed with dual, rapid-fire autoguns.",
   ['xal0305'] = "<LOC Unit_Description_0328> Fast-moving sniper bot. Designed to strike high-value targets from a distance.", 

   
   ##Air
   ['uaa0101'] = "<LOC Unit_Description_0235> Standard air scout.",
   ['uaa0102'] = "<LOC Unit_Description_0236> Quick, maneuverable fighter. Armed with sonic pulse battery.",
   ['uaa0103'] = "<LOC Unit_Description_0237> Lightly armored bomber. Armed with a Chrono bomb that destroys and disables targeted units.",
   ['uaa0107'] = "<LOC Unit_Description_0238> Low-end air transport. Can carry up to 6 units.",
   ['uaa0203'] = "<LOC Unit_Description_0239> Armored gunship. Quad-barreled light laser mounted on its underside.",
   ['uaa0204'] = "<LOC Unit_Description_0240> Torpedo bomber. Armed a payload of Harmonic depth charges.",
   ['uaa0302'] = "<LOC Unit_Description_0241> Extremely fast spy plane. Equipped with mid-level radar system.",
   ['uaa0104'] = "<LOC Unit_Description_0242> Mid-level air transport. Armed with sonic pulse batteries. Can carry up to 12 units.",
   ['uaa0303'] = "<LOC Unit_Description_0243> High-end air fighter. Designed to engage air units of any type.",
   ['uaa0304'] = "<LOC Unit_Description_0244> High-end strategic bomber. Armed with a Quark bomb and decoy flares.",
   ['uaa0310'] = "<LOC Unit_Description_0245> Flying fortress. Armed with Quantum beam generator, AA systems and depth charges. Can store, transport and repair aircraft.",
   ['xaa0202'] = "<LOC Unit_Description_0329> Mid-level air fighter.  Excellent AA capabilities. Effective against enemy gunships and bombers.",
   ['xaa0305'] = "<LOC Unit_Description_0330> Heavily armored gunship. Armed with quad-light laser and Zealot missiles.",
   ['xaa0306'] = "<LOC Unit_Description_0331> Torpedo bomber. Designed to engage high-level naval units.",
  
   
   ##Naval
   ['uas0103'] = "<LOC Unit_Description_0246> Naval support unit. Equipped with a radar, sonar and anti-torpedo charges.",
   ['uas0203'] = "<LOC Unit_Description_0247> Low-end attack submarine.",
   ['uas0102'] = "<LOC Unit_Description_0248> Anti-aircraft naval vessel. Armed with AA sonic pulse battery.",
   ['uas0202'] = "<LOC Unit_Description_0249> Mid-level anti-aircraft naval vessel. Armed with two AA missile launchers, dual-barreled Quantum cannon and tactical missile flares.", 
   ['uas0201'] = "<LOC Unit_Description_0250> Sub-killer. Equipped with an Oblivion cannon, torpedo tubes, Harmonic depth charges and anti-torpedo charges.",
   ['uas0302'] = "<LOC Unit_Description_0251> High-end anti-naval vessel. Equipped with three Oblivion cannons and anti-missile flares.",
   ['uas0303'] = "<LOC Unit_Description_0252> Aircraft carrier. Can store, transport and repair aircraft. Armed with surface-to-air missile launchers.",
   ['uas0304'] = "<LOC Unit_Description_0253> Strategic missile submarine. Armed with Serpentine tactical missiles and a strategic missile launcher.",
   ['uas0401'] = "<LOC Unit_Description_0254> Submersible battleship. Armed with heavy torpedo launchers and a single Oblivion cannon. Can construct light support naval units.",
   ['xas0204'] = "<LOC Unit_Description_0332> Submerged anti-naval unit. Effective against both surface vessels and submerged units.",
   ['xas0306'] = "<LOC Unit_Description_0333> High-end missile ship. Armed with two racks of highly accurate Serpentine tactical missiles.",
   
   ##Buildings
   ['uab2101'] = "<LOC Unit_Description_0255> Low-end defensive tower that attacks land- and sea-based units. Does not engage aircraft or submerged units.",
   ['uab2104'] = "<LOC Unit_Description_0256> Anti-air tower. Designed to engage low-end aircraft.",
   ['uab2109'] = "<LOC Unit_Description_0257> Anti-naval defense system.",
   ['uab5101'] = "<LOC Unit_Description_0258> Restricts the movement of enemy units. Offers minimal protection from enemy fire.",
   ['uab2301'] = "<LOC Unit_Description_0259> Heavily armored defensive tower that attacks land- and sea-based units. Does not engage aircraft or submerged units.",
   ['uab2204'] = "<LOC Unit_Description_0260> Anti-air tower. Designed to engage mid-level aircraft.",
   ['uab4201'] = "<LOC Unit_Description_0261> Tactical missile defense. Protection is limited to the structure's operational area.",
   ['uab2205'] = "<LOC Unit_Description_0262> Heavy anti-naval defense system. Designed to engage all naval units.",
   ['uab4202'] = "<LOC Unit_Description_0263> Generates a protective shield around units and structures within its radius.",
   ['uab2304'] = "<LOC Unit_Description_0264> High-end anti-air tower. Designed to engage all levels of aircraft.",
   ['uab4302'] = "<LOC Unit_Description_0265> Strategic missile defense. Protection is limited to the structure's operational area.",
   ['uab4301'] = "<LOC Unit_Description_0266> Generates a protective shield around units and structures within its radius.",
   ['uab2303'] = "<LOC Unit_Description_0267> Mid-level artillery. Designed to engage slow-moving units and fixed structures.",
   ['uab2108'] = "<LOC Unit_Description_0268> Tactical missile launcher. Must be ordered to construct missiles.",
   ['uab5202'] = "<LOC Unit_Description_0269> Refuels and repairs aircraft. Air patrols will automatically use facility.",
   ['uab2302'] = "<LOC Unit_Description_0270> Heavy artillery with excellent range, accuracy and damage potential. ",
   ['uab2305'] = "<LOC Unit_Description_0271> Strategic missile launcher. Constructing missiles costs resources. Must be ordered to construct missiles.",
   ['uab0304'] = "<LOC Unit_Description_0272> Summons Support Commander(s).",
   ['xab2307'] = "<LOC Unit_Description_0334> Rapid-fire artillery system. Provides indirect fire support. Ordinance inflicts light damage across a large area.",
   ['xab3301'] = "<LOC Unit_Description_0335> Offers line-of-sight to a fixed location on the battlefield.",

   
   ##Engineers
   ['ual0105'] = "<LOC Unit_Description_0273> Tech 1 amphibious construction, repair, capture and reclamation unit.",
   ['ual0208'] = "<LOC Unit_Description_0274> Tech 2 amphibious construction, repair, capture and reclamation unit.",
   ['ual0309'] = "<LOC Unit_Description_0275> Tech 3 amphibious construction, repair, capture and reclamation unit.",
   
   
   
   ['uab0101'] = "<LOC Unit_Description_0276> Constructs Tech 1 land units. Upgradeable.",
   ['uab0102'] = "<LOC Unit_Description_0277> Constructs Tech 1 air units. Upgradeable.",
   ['uab0103'] = "<LOC Unit_Description_0278> Constructs Tech 1 naval units. Upgradeable.",
   ['uab0201'] = "<LOC Unit_Description_0279> Constructs Tech 2 land units. Upgradeable.",
   ['uab0202'] = "<LOC Unit_Description_0280> Constructs Tech 2 air units. Upgradeable.",
   ['uab0203'] = "<LOC Unit_Description_0281> Constructs Tech 2 naval units. Upgradeable.",
   ['uab0301'] = "<LOC Unit_Description_0282> Constructs Tech 3 land units. Highest tech level available.",
   ['uab0302'] = "<LOC Unit_Description_0283> Constructs Tech 3 air units. Highest tech level available.",
   ['uab0303'] = "<LOC Unit_Description_0284> Constructs Tech 3 naval units. Highest tech level available.",
   ['uab1101'] = "<LOC Unit_Description_0285> Generates Energy. Construct next to other structures for adjacency bonus.",
   ['uab1102'] = "<LOC Unit_Description_0286> Generates Energy. Must be constructed on hydrocarbon deposits. Construct structures next to Hydrocarbon power plant for adjacency bonus.",
   ['uab1105'] = "<LOC Unit_Description_0287> Stores Energy. Construct next to power generators for adjacency bonus.",
   ['uab1103'] = "<LOC Unit_Description_0288> Extracts Mass. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
   ['uab1104'] = "<LOC Unit_Description_0289> Creates Mass. Requires large amounts of Energy. Construct next to other structures for adjacency bonus.",
   ['uab1106'] = "<LOC Unit_Description_0290> Stores Mass. Construct next to extractors or fabricators for adjacency bonus.",
   ['uab1201'] = "<LOC Unit_Description_0291> Mid-level power generator. Construct next to other structures for adjacency bonus.",
   ['uab1202'] = "<LOC Unit_Description_0292> Mid-level Mass extractor. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
   ['uab1301'] = "<LOC Unit_Description_0293> High-end power generator. Construct next to other structures for adjacency bonus.",
   ['uab1302'] = "<LOC Unit_Description_0294> High-end Mass extractor. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
   ['uab1303'] = "<LOC Unit_Description_0295> High-end Mass fabricator. Requires large amounts of Energy. Construct next to other structures for adjacency bonus.",
   ['uab3101'] = "<LOC Unit_Description_0296> Radar system with minimal range. Detects and tracks surface and air units.",
   ['uab3102'] = "<LOC Unit_Description_0297> Sonar system with minimal range. Detects and tracks naval units.", 
   ['uab3201'] = "<LOC Unit_Description_0298> Radar system with moderate range. Detects and tracks surface and air units.",
   ['uab3202'] = "<LOC Unit_Description_0299> Sonar system with moderate range. Detects and tracks naval units.",
   ['uab4203'] = "<LOC Unit_Description_0300> Generates stealth field. Hides units and structures within its operational range. Countered by optical and Omni sensors.",
   ['uas0305'] = "<LOC Unit_Description_0301> Sonar system with exceptional range. Detects and tracks naval units. Equipped with anti-torpedo launchers.",
   ['uab3104'] = "<LOC Unit_Description_0302> High-end intelligence system. Provides maximum radar and sonar coverage. Counters enemy intelligence systems.", 
   ['xab1401'] = "<LOC Unit_Description_0336> Generates nearly limitless Energy and Mass. Toggles output to match production demands. If destroyed, resulting explosion is equivalent to the detonation of a strategic weapon.",


    ##Seraphim Units

    ##Seraphim Commanders
    ['xsl0001'] = "<LOC Unit_Description_0420> Houses Commander. Combination barracks and command center. Contains all the blueprints necessary to build a basic army from scratch.",
    ['xsl0001-pqt'] = "<LOC Unit_Description_0421> Adds teleporter. Requires considerable Energy to activate.",
    ['xsl0001-dss'] = "<LOC Unit_Description_0422> Increases the speed at which the ACU repairs itself. Also increases hit points.",
    ['xsl0001-adss'] = "<LOC Unit_Description_0454> Further increases the speed at which the ACU repairs itself. Also increases hitpoints.",
    ['xsl0001-ras'] = "<LOC Unit_Description_0424> Increases ACU's resource generation.",
    ['xsl0001-eras'] = "<LOC Unit_Description_0425> Requires Resource Allocation System. Further increases ACU's resource generation.",
    ['xsl0001-aes'] = "<LOC Unit_Description_0426> Expands the number of available schematics and increases the ACU's build speed and maximum health.",
    ['xsl0001-ees'] = "<LOC Unit_Description_0427> Replaces the Tech 2 Engineering Suite. Expands the number of available schematics and further increases the ACU's build speed and maximum health.",
    ['xsl0001-cba'] = "<LOC Unit_Description_0428> Increases the damage inflicted by ACU's primary weapon. Adds area-of-effect damage.",
    ['xsl0001-nrf'] = "<LOC Unit_Description_0429> Automatically speeds up the repair speed of nearby units.",
    ['xsl0001-anrf'] = "<LOC Unit_Description_0430> Further speeds up the repair speed of nearby units. Increases maximum health of nearby units.",
    ['xsl0001-hsa'] = "<LOC Unit_Description_0431> Increases main cannon's rate of fire and range. Also increases range of Overcharge.",
    ['xsl0001-tml'] = "<LOC Unit_Description_0432> Mounts a tactical cruise missile launcher onto the back of the ACU.",
	
    ['xsl0301'] = "<LOC Unit_Description_0433> A multi-purpose construction, repair, capture and reclamation unit. Equivalent to a Tech 3 Engineer.",
    ['xsl0301-tmu'] = "<LOC Unit_Description_0434> Mounts a tactical cruise missile launcher onto the back of the SACU.",
    ['xsl0301-dss'] = "<LOC Unit_Description_0435> Increases the speed at which the SACU repairs itself. Also increases hit points.",
    ['xsl0301-sre'] = "<LOC Unit_Description_0436> Greatly expands the range of the standard onboard SACU sensor systems, including Omni.",
    ['xsl0301-efm'] = "<LOC Unit_Description_0437> Speeds up all engineering-related functions.",
    ['xsl0301-sp'] = "<LOC Unit_Description_0438> Adds a personal shield generator to the SACU.",
    ['xsl0301-pqt'] = "<LOC Unit_Description_0439> Adds teleporter. Requires considerable Energy to activate.",
    ['xsl0301-oc'] = "<LOC Unit_Description_0440> Single shot destroys most units. Consumes large amount of Energy.",

    ## Support ACU presets
    ['xsl0301_AdvancedCombat'] = "<LOC xsl0301_AdvancedCombat_help>Support Armored Command Unit. Enhanced during construction with the enhanced sensor system, nano-repair system and overcharge enhancements.",
    ['xsl0301_Combat'] = "<LOC xsl0301_Combat_help>Support Armored Command Unit. Enhanced during construction with the enhanced sensor system enhancement.",
    ['xsl0301_Engineer'] = "<LOC xsl0301_Engineer_help>Support Armored Command Unit. Enhanced during construction with the rapid fabricator enhancement.",
    ['xsl0301_Missile'] = "<LOC xsl0301_Missile_help>Support Armored Command Unit. Enhanced during construction with the tactical missile launcher and rapid fabricator enhancements.",
    ['xsl0301_NanoCombat'] = "<LOC xsl0301_NanoCombat_help>Support Armored Command Unit. Enhanced during construction with the enhanced sensor system and nano-repair system enhancements.",
    ['xsl0301_Rambo'] = "<LOC xsl0301_Rambo_help>Support Armored Command Unit. Enhanced during construction with the personal shield generator, nano-repair system and overcharge enhancements.",

    ##Land Units
    ['xsl0101'] = "<LOC Unit_Description_0337> Light, fast mobile reconnaissance unit. When stationary, deploys cloaking and stealth fields.",
    ['xsl0201'] = "<LOC Unit_Description_0338> Lightly armored tank. Armed with a single cannon.",
    ['xsl0103'] = "<LOC Unit_Description_0339> Amphibious mobile light artillery. Provides indirect fire support.",
    ['xsl0104'] = "<LOC Unit_Description_0340> Mobile anti-air defense. Effective against low-end enemy air units.",
	['xsl0202'] = "<LOC Unit_Description_0341> Lightly armored assault bot. Effective against equivalent enemy units.",
	['xsl0203'] = "<LOC Unit_Description_0342> Amphibious tank. Armed with a single cannon.",
	['xsl0111'] = "<LOC Unit_Description_0343> Relatively fast-moving mobile tactical missile launcher.",
	['xsl0205'] = "<LOC Unit_Description_0344> Mobile AA unit that uses flak artillery.",
	['xsl0303'] = "<LOC Unit_Description_0345> Amphibious siege tank that is armed with a slow-firing Thau cannon. Also armed with bolters and a single torpedo launcher.",
	['xsl0305'] = "<LOC Unit_Description_0346> Lightly armored, fast sniper bot. Armed with an extremely powerful energy rifle.",
	['xsl0304'] = "<LOC Unit_Description_0347> Mobile heavy artillery. Ordinance inflicts moderate damage upon impact.",
	['xsl0307'] = "<LOC Unit_Description_0348> High-end mobile shield generator.",
	['xsl0401'] = "<LOC Unit_Description_0349> A two-stage weapon. In its initial form, it fires an extremely destructive Phason laser. When the primary unit is destroyed, it unleashes a ferocious Quantum energy being.",
	
	##Air Units
	['xsa0101'] = "<LOC Unit_Description_0350> Standard air scout",
	['xsa0102'] = "<LOC Unit_Description_0351> Quick, agile air fighter. Armed with a Gatling-style weapon.",
	['xsa0103'] = "<LOC Unit_Description_0352> Fast-moving tactical bomber. Lightly armored.",
	['xsa0107'] = "<LOC Unit_Description_0353> Low-end air transport. Can carry up to 8 units.",
	['xsa0202'] = "<LOC Unit_Description_0354> Combined fighter/bomber. Armed with two AA weapons and a tactical bomb.",
	['xsa0203'] = "<LOC Unit_Description_0355> Heavily armored gunship. Armed with four heavy Phasic autoguns.",
	['xsa0204'] = "<LOC Unit_Description_0356> Torpedo bomber. Fires three heavy Cavitation torpedoes at its target.",
	['xsa0104'] = "<LOC Unit_Description_0357> Mid-level air transport. Can carry up to 16 units.",
	['xsa0302'] = "<LOC Unit_Description_0358> Fast, agile spy plane. Equipped with on-board radar and sonar.",
	['xsa0303'] = "<LOC Unit_Description_0359> High-end air fighter. Designed to engage air units of any type.",
	['xsa0304'] = "<LOC Unit_Description_0360> High-end strategic bomber. Inflicts excellent single target and area-of-effect damage.",
	['xsa0402'] = "<LOC Unit_Description_0361> Massive bomber capable of devastating entire bases. Armed with an experimental strategic bomb and three AA auto-cannons.",
	
	##Naval Units
	['xss0103'] = "<LOC Unit_Description_0362> Low-end naval unit. Armed with an auto-cannon and AA Gatling gun.",
	['xss0203'] = "<LOC Unit_Description_0363> Low-end attack submarine.",
	['xss0202'] = "<LOC Unit_Description_0364> Mid-level naval unit. Equipped with AA artillery cannons, tactical missile launcher and tactical missile defense.",
	['xss0201'] = "<LOC Unit_Description_0365> Dedicated sub-killer. Equipped with a torpedo launcher, anti-vessel beam weapons and torpedo defense.",
	['xss0302'] = "<LOC Unit_Description_0366> High-end naval vessel. Armed with three heavy Quarnon cannons, two AA cannons, two tactical missile defenses and a strategic missile launcher.",
	['xss0304'] = "<LOC Unit_Description_0367> Dedicated sub-killer. Armed with three torpedo tubes, pair of torpedo defense systems and AA auto-cannon for use when surfaced.",
	['xss0303'] = "<LOC Unit_Description_0368> Can store, transport and repair aircraft. Armed with two pairs of AA auto-cannons.",
	
	##Base Structures
	['xsb2101'] = "<LOC Unit_Description_0369> Low-end defensive tower that attacks land- and sea-based units. Does not engage aircraft or submerged units.",
	['xsb2104'] = "<LOC Unit_Description_0370> Anti-air tower. Designed to engage low-end aircraft.",
	['xsb2109'] = "<LOC Unit_Description_0371> Anti-naval defense system.",
	['xsb5101'] = "<LOC Unit_Description_0372> Restricts the movement of enemy units. Offers minimal protection from enemy fire.",
	['xsb2301'] = "<LOC Unit_Description_0373> Heavily armored, defensive tower that attacks land- and sea-based units. Does not engage aircraft or submerged units.",
	['xsb2204'] = "<LOC Unit_Description_0374> Anti-air tower. Designed to engage mid-level aircraft.",
	['xsb4201'] = "<LOC Unit_Description_0375> Tactical missile defense. Protection is limited to the structure's operational area.",
	['xsb4202'] = "<LOC Unit_Description_0376> Generates a protective shield around units and structures within its radius.",
	['xsb2205'] = "<LOC Unit_Description_0377> Anti-naval defense system. Employs torpedo defense system.",
	['xsb2304'] = "<LOC Unit_Description_0378> High-end anti-air tower. Designed to engage all levels of aircraft.",
	['xsb4302'] = "<LOC Unit_Description_0379> Strategic missile defense. Protection is limited to the structure's operational area.",
	['xsb4301'] = "<LOC Unit_Description_0380> Generates a heavy shield around units and structures within its radius.",
	['xsb2303'] = "<LOC Unit_Description_0381> Stationary, rapid-fire artillery. Provides decent impact damage across a small area.",
	['xsb2108'] = "<LOC Unit_Description_0382> Tactical missile launcher. Firing missiles requires resources.",
	['xsb5202'] = "<LOC Unit_Description_0383> Refuels and repairs most small aircraft. Air patrols will automatically use facility.",
	['xsb2302'] = "<LOC Unit_Description_0384> Stationary heavy artillery with excellent range, accuracy and damage potential. Requires resources to fire.",
	['xsb2305'] = "<LOC Unit_Description_0385> Strategic missile launcher. Constructing missiles costs resources.",
	['xsb2401'] = "<LOC Unit_Description_0386> Strategic missile launcher. Fired missile is so large, two strategic missile defenses are required to neutralize it.",
	
	##Engineer/Factories
	['xsl0105'] = "<LOC Unit_Description_0387> Tech 1 amphibious construction, repair, capture and reclamation unit.",
	['xsl0208'] = "<LOC Unit_Description_0388> Tech 2 amphibious construction, repair, capture and reclamation unit.",
	['xsl0309'] = "<LOC Unit_Description_0389> Tech 3 amphibious construction, repair, capture and reclamation unit.",
	
	['xsb0101'] = "<LOC Unit_Description_0390> Constructs Tech 1 land units. Upgradeable.",
	['xsb0102'] = "<LOC Unit_Description_0391> Constructs Tech 1 air units. Upgradeable.",
	['xsb0103'] = "<LOC Unit_Description_0392> Constructs Tech 1 naval units. Upgradeable.",
	['xsb0201'] = "<LOC Unit_Description_0393> Constructs Tech 2 land units. Upgradeable.",
	['xsb0202'] = "<LOC Unit_Description_0394> Constructs Tech 2 air units. Upgradeable.",
	['xsb0203'] = "<LOC Unit_Description_0395> Constructs Tech 2 naval units. Upgradeable.",
	['xsb0301'] = "<LOC Unit_Description_0396> Constructs Tech 3 land units. Highest tech level available.",
	['xsb0302'] = "<LOC Unit_Description_0397> Constructs Tech 3 air units. Highest tech level available.",
	['xsb0303'] = "<LOC Unit_Description_0398> Constructs Tech 3 naval units. Highest tech level available.",
	['xsb0304'] = "<LOC Unit_Description_0399> Summons Support Commander(s).",
	
	##Resource Structures
	['xsb1101'] = "<LOC Unit_Description_0400> Generates Energy. Construct next to other structures for adjacency bonus.",
	['xsb1102'] = "<LOC Unit_Description_0401> Generates Energy. Must be constructed on hydrocarbon deposits. Construct structures next to Hydrocarbon power plant for adjacency bonus.",
	['xsb1105'] = "<LOC Unit_Description_0402> Stores Energy. Construct next to power generators for adjacency bonus.",
	['xsb1103'] = "<LOC Unit_Description_0403> Extracts Mass. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
	['xsb1104'] = "<LOC Unit_Description_0404> Mid-level Mass fabricator. Requires large amounts of Energy. Construct next to other structures for adjacency bonus.",
	['xsb1106'] = "<LOC Unit_Description_0405> Stores Mass. Construct next to extractors or fabricators for adjacency bonus.",
	['xsb1201'] = "<LOC Unit_Description_0406> Mid-level power generator. Construct next to other structures for adjacency bonus.",
	['xsb1202'] = "<LOC Unit_Description_0407> Mid-level Mass extractor. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
	['xsb1301'] = "<LOC Unit_Description_0408> High-end power generator. Construct next to other structures for adjacency bonus.",
	['xsb1302'] = "<LOC Unit_Description_0409> High-end Mass extractor. Must be constructed on Mass deposits. Construct structures next to Mass extractor for adjacency bonus.",
	['xsb1303'] = "<LOC Unit_Description_0410> High-end Mass fabricator. Requires large amounts of Energy. Construct next to other structures for adjacency bonus.",
	
	##Intelligence Structures
	['xsb3101'] = "<LOC Unit_Description_0411> Radar system with minimal range. Detects and tracks surface and air units.",
	['xsb3102'] = "<LOC Unit_Description_0412> Sonar system with minimal range. Detects and tracks naval units.",
	['xsb3202'] = "<LOC Unit_Description_0413> Sonar system with moderate range. Detects and tracks naval units.",
	['xsb3201'] = "<LOC Unit_Description_0414> Radar system with moderate range. Detects and tracks surface and air units.",
	['xsb4203'] = "<LOC Unit_Description_0415> Generates stealth field. Hides units and structures within its operational range. Countered by optical and Omni sensors.",
	['xsb3104'] = "<LOC Unit_Description_0416> High-end intelligence system. Provides maximum radar and sonar coverage. Counters enemy intelligence systems.",
           

   # Patch Units
   ['dea0202'] = "<LOC Unit_Description_0417> Combination fighter/bomber designed to engage both land and aerial units. Armed with linked AA railguns and heavy napalm carpet bombs.",
   ['dra0202'] = "<LOC Unit_Description_0418> Combination fighter/bomber designed to engage both land and aerial units. Armed with Nano Dart launcher and separate missile launcher.",
   ['daa0206'] = "<LOC Unit_Description_0419> The volatile and destructive nature of the Mercy's weapon system forced Aeon scientists to create a simple, expendable delivery system. As a result, the payload is attached to what is little more than a guided missile.",
   ['del0204'] = "<LOC Unit_Description_0441> Fast moving, heavily armed assault bot. Armed with both a gatling plasma cannon and a heavy fragmentation grenade launcher.",
   ['dal0310'] = "<LOC Unit_Description_0442> Mobile support unit. Designed to attack and destroy enemy shields. Weapon system is largely ineffective against enemy units.",
   ['dab2102'] = "<LOC Unit_Description_0443> Gatling-style mortar launcher that fires high-explosive ordinance with a good degree of accuracy.",
   ['drl0204'] = "<LOC Unit_Description_0444> Heavily armored rocket bot. Designed to engage and destroy heavily armored units.",
   ['drs0102'] = "<LOC Unit_Description_0445> Unarmed stealth sub designed for reconnaissance missions. Equipped with anti-torpedo flares.",
   
}
