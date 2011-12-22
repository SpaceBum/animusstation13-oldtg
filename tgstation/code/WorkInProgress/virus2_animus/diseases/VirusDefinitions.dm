/proc/infect_mob_special(var/mob/living/carbon/M, var/virusname = "random")
	if(!M.virus2)
		switch(virusname)
			if("gbs")
				M.virus2 = new /datum/disease2/disease
				M.virus2.makegbs()
			if("brain rot")
				M.virus2 = new /datum/disease2/disease
				M.virus2.makebrainrot()
			if("yuggoth venenation")
				M.virus2 = new /datum/disease2/disease
				M.virus2.makeyven()
			else
				M.virus2 = new /datum/disease2/disease
				M.virus2.makerandom()
				M.virus2.infectionchance = 10
/*
Premaded diseases
*/
/datum/disease2/disease

//IF YOU MADE NEW VIRUS, DON'T FORGET TO PLACE IT HERE
//THIS PROC USED BY ADMIN-ACTIVATED "Virual Outbreak" EVENT
	proc/makespecial(var/type = "random")
		switch(type)
			if("gbs")
				src.makegbs()
			if("brain rot")
				src.makebrainrot()
			if("yuggoth venenation")
				src.makeyven()
			else
				src.makerandom()

//GBS
	proc/makegbs()
		var/datum/disease2/effect/effect = null

		effect = new /datum/disease2/effect/invisible()
		effect.stage = 1
		effect.chance = 1
		effects += effect

		effect = new /datum/disease2/effect/cough()
		effect.stage = 2
		effect.chance = 45
		effects += effect

		effect = new /datum/disease2/effect/toxins()
		effect.stage = 3
		effect.chance = 30
		effects += effect

		effect = new /datum/disease2/effect/gibbingtons()
		effect.stage = 4
		effect.chance = 25
		effects += effect

		uniqueID = 24
		maxstage = 4
		infectionchance = 10
		spreadtype = "Airborne"

//Brainrot
	proc/makebrainrot()
		var/datum/disease2/effect/effect = null

		effect = new /datum/disease2/effect/invisible()
		effect.stage = 1
		effect.chance = 1
		effects += effect

		effect = new /datum/disease2/effect/brainrot2()
		effect.stage = 2
		effect.chance = 45
		effects += effect

		effect = new /datum/disease2/effect/brainrot3()
		effect.stage = 3
		effect.chance = 45
		effects += effect

		effect = new /datum/disease2/effect/brainrot4()
		effect.stage = 4
		effect.chance = 45
		effects += effect

		uniqueID = 56
		maxstage = 4
		infectionchance = 10
		spreadtype = "Airborne"


//Yuggoth venenation

	proc/makeyven()
		var/datum/disease2/effect/effect = null

		effect = new /datum/disease2/effect/asneeze()
		effect.stage = 1
		effect.chance = 10
		effects += effect

		effect = new /datum/disease2/effect/ahungry()
		effect.stage = 2
		effect.chance = 10
		effects += effect

		effect = new /datum/disease2/effect/plethal()
		effect.stage = 3
		effect.chance = 10
		effects += effect

		effect = new /datum/disease2/effect/rotflesh()
		effect.stage = 4
		effect.chance = 10
		effects += effect

		uniqueID = 11
		maxstage = 4
		infectionchance = 30
		spreadtype = "Airborne"

//Part from BAY12Station which don't work with /tg/
//
/*
	proc/makezombie()
		var/datum/disease2/effectholder/holder = new /datum/disease2/effectholder
		holder.stage = 1
		holder.chance = 10
		holder.effect = new/datum/disease2/effect/greater/gunck()
		effects += holder

		holder = new /datum/disease2/effectholder
		holder.stage = 2
		holder.chance = 10
		holder.effect = new/datum/disease2/effect/lesser/hungry()
		effects += holder

		holder = new /datum/disease2/effectholder
		holder.stage = 3
		holder.chance = 10
		holder.effect = new/datum/disease2/effect/lesser/groan()
		effects += holder

		holder = new /datum/disease2/effectholder
		holder.stage = 4
		holder.chance = 10
		holder.effect = new/datum/disease2/effect/zombie()
		effects += holder

		uniqueID = 1220 // all zombie diseases have the same ID
		infectionchance = 0
		spreadtype = "Airborne"
*/