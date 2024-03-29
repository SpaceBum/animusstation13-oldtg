/obj/machinery/door/Bumped(atom/AM)
	if(p_open || operating) return
	if(ismob(AM))
		var/mob/M = AM
		if(world.time - AM.last_bumped <= 60) return //NOTE do we really need that?
		if(M.client && !M:handcuffed)
			bumpopen(M)
	else if(istype(AM, /obj/machinery/bot))
		var/obj/machinery/bot/bot = AM
		if(src.check_access(bot.botcard))
			if(density)
				open()
	else if(istype(AM, /obj/livestock))
		var/obj/livestock/ani =AM
		if(src.check_access(ani.anicard))
			if(density)
				open()
	else if(istype(AM, /obj/alien/facehugger))
		if(src.check_access(null))
			if(density)
				open()
	else if(istype(AM, /obj/mecha))
		var/obj/mecha/mecha = AM
		if(density)
			if(mecha.occupant && src.allowed(mecha.occupant))
				open()
			else
				flick("door_deny", src)


/obj/machinery/door/proc/bumpopen(mob/user as mob)
	if (src.operating)
		return
	//if(world.timeofday-last_used <= 10)
	//	return
	src.add_fingerprint(user)
	if (!src.requiresID())
		//don't care who they are or what they have, act as if they're NOTHING
		user = null

	if (src.allowed(user))
		if (src.density)
			//last_used = world.timeofday
			open()
	else if (src.density)
		flick("door_deny", src)
	return


/obj/machinery/door/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group) return 0
	if(istype(mover) && mover.checkpass(PASSGLASS))
		return !opacity
	return !density

/obj/machinery/door/proc/update_nearby_tiles(need_rebuild)
	if(!air_master) return 0

	var/turf/simulated/source = loc
	var/turf/simulated/north = get_step(source,NORTH)
	var/turf/simulated/south = get_step(source,SOUTH)
	var/turf/simulated/east = get_step(source,EAST)
	var/turf/simulated/west = get_step(source,WEST)

	if(need_rebuild)
		if(istype(source)) //Rebuild/update nearby group geometry
			if(source.parent)
				air_master.groups_to_rebuild += source.parent
			else
				air_master.tiles_to_update += source
		if(istype(north))
			if(north.parent)
				air_master.groups_to_rebuild += north.parent
			else
				air_master.tiles_to_update += north
		if(istype(south))
			if(south.parent)
				air_master.groups_to_rebuild += south.parent
			else
				air_master.tiles_to_update += south
		if(istype(east))
			if(east.parent)
				air_master.groups_to_rebuild += east.parent
			else
				air_master.tiles_to_update += east
		if(istype(west))
			if(west.parent)
				air_master.groups_to_rebuild += west.parent
			else
				air_master.tiles_to_update += west
	else
		if(istype(source)) air_master.tiles_to_update += source
		if(istype(north)) air_master.tiles_to_update += north
		if(istype(south)) air_master.tiles_to_update += south
		if(istype(east)) air_master.tiles_to_update += east
		if(istype(west)) air_master.tiles_to_update += west

	return 1

/obj/machinery/door/New()
	..()
	if(density)
		layer = 3.1 //Above most items if closed
	else
		layer = 2.7 //Under all objects if opened. 2.7 due to tables being at 2.6
	update_nearby_tiles(need_rebuild=1)

/obj/machinery/door/Del()
	update_nearby_tiles()

	..()


/obj/machinery/door/meteorhit(obj/M as obj)
	src.open()
	return

/obj/machinery/door/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/door/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/door/attack_hand(mob/user as mob)
	return src.attackby(user, user)

/obj/machinery/door/proc/requiresID()
	return 1

/obj/machinery/door/attackby(obj/item/I as obj, mob/user as mob)
	if (src.operating)
		return
	src.add_fingerprint(user)
	if (!src.requiresID())
		//don't care who they are or what they have, act as if they're NOTHING
		user = null
	if (src.density && (istype(I, /obj/item/weapon/card/emag)||istype(I, /obj/item/weapon/melee/energy/blade)))
		src.operating = -1
		if(istype(I, /obj/item/weapon/melee/energy/blade))
			if(istype(src, /obj/machinery/door/airlock))
				var/datum/effects/system/spark_spread/spark_system = new /datum/effects/system/spark_spread()
				spark_system.set_up(5, 0, src.loc)
				spark_system.start()
				playsound(src.loc, 'blade1.ogg', 50, 1)
				playsound(src.loc, "sparks", 50, 1)
				for(var/mob/O in viewers(user, 3))
					O.show_message(text("\blue The door has been sliced open by [] with an energy blade!", user), 1, text("\red You hear metal being sliced and sparks flying."), 2)
				if((!src:arePowerSystemsOn()) || (stat & NOPOWER) || src:isWireCut(AIRLOCK_WIRE_DOOR_BOLTS))
					var/obj/door_assembly/temp
					var/failsafe=0
					switch(src:doortype)
						if(0) temp=new/obj/door_assembly/door_assembly_0(src.loc)
						if(1) temp=new/obj/door_assembly/door_assembly_com(src.loc)
						if(2) temp=new/obj/door_assembly/door_assembly_sec(src.loc)
						if(3) temp=new/obj/door_assembly/door_assembly_eng(src.loc)
						if(4) temp=new/obj/door_assembly/door_assembly_med(src.loc)
						if(5) temp=new/obj/door_assembly/door_assembly_mai(src.loc)
						if(6) temp=new/obj/door_assembly/door_assembly_ext(src.loc)
						if(7) temp=new/obj/door_assembly/door_assembly_g(src.loc)
						else	failsafe=1
					if(!failsafe)
						temp.anchored=0
						step_away(temp,usr,15)
					else	del(temp)
					del(src)
					return
				else
					src:welded = 0
					src:locked = 0
					update_icon()
		flick("door_spark", src)
		sleep(6)
		open()
		return 1
	if (src.allowed(user))
		if (src.density)
			open()
		else
			close()
	else if (src.density)
		flick("door_deny", src)
	return

/obj/machinery/door/airlock/proc/ion_act()
	if(src.z == 1 && src.density)
		if(length(req_access) > 0 && !(12 in req_access))
			if(prob(4))
				world << "\red Airlock emagged in [src.loc.loc]"
				src.operating = -1
				flick("door_spark", src)
				sleep(6)
				open()
		else
			if(prob(8))
				world << "\red non vital Airlock emagged in [src.loc.loc]"
				src.operating = -1
				flick("door_spark", src)
				sleep(6)
				open()
	return

/obj/machinery/door/firedoor/proc/ion_act()
	if(src.z == 1)
		if(prob(15))
			if(density)
				open()
			else
				close()
	return

/obj/machinery/door/blob_act()
	if(prob(40))
		del(src)

/obj/machinery/door/emp_act(severity)
	if(prob(20/severity) && (istype(src,/obj/machinery/door/airlock) || istype(src,/obj/machinery/door/window)) )
		open()
	if(prob(40/severity))
		if(secondsElectrified == 0)
			secondsElectrified = -1
			spawn(300)
				secondsElectrified = 0
	..()

/obj/machinery/door/ex_act(severity)
	switch(severity)
		if(1.0)
			del(src)
		if(2.0)
			if(prob(25))
				del(src)
		if(3.0)
			if(prob(80))
				var/datum/effects/system/spark_spread/s = new /datum/effects/system/spark_spread
				s.set_up(2, 1, src)
				s.start()

/obj/machinery/door/update_icon()
	if(density)
		icon_state = "door1"
	else
		icon_state = "door0"
	return

/obj/machinery/door/proc/animate(animation)
	switch(animation)
		if("opening")
			if(p_open)
				flick("o_doorc0", src)
			else
				flick("doorc0", src)
		if("closing")
			if(p_open)
				flick("o_doorc1", src)
			else
				flick("doorc1", src)
		if("deny")
			flick("door_deny", src)
	return

/obj/machinery/door/proc/open()
	if(!density)
		return 1
	if (src.operating == 1) //doors can still open when emag-disabled
		return
	if (!ticker)
		return 0
	if(!src.operating) //in case of emag
		src.operating = 1

	animate("opening")
	sleep(10)
	src.layer = 2.7
	src.density = 0
	update_icon()

	src.sd_SetOpacity(0)
	update_nearby_tiles()

	if(operating == 1) //emag again
		src.operating = 0

	if(autoclose)
		spawn(150)
			autoclose()
	return 1

/obj/machinery/door/proc/close()
	if(density)
		return 1
	if (src.operating)
		return
	src.operating = 1

	animate("closing")
	src.density = 1
	src.layer = 3.1
	sleep(10)
	update_icon()

	if (src.visible && (!istype(src, /obj/machinery/door/airlock/glass)))
		src.sd_SetOpacity(1)
	if(operating == 1)
		operating = 0
	update_nearby_tiles()

/obj/machinery/door/proc/autoclose()
	var/obj/machinery/door/airlock/A = src
	if ((!A.density) && !( A.operating ) && !(A.locked) && !( A.welded ))
		close()
	else return

/////////////////////////////////////////////////// Unpowered doors

/obj/machinery/door/unpowered/Bumped(atom/AM)
	if(p_open || operating) return
	if (src.locked)
		return
	if(ismob(AM))
		var/mob/M = AM
		if(world.time - AM.last_bumped <= 60) return
		if(M.client && !M:handcuffed)
			bumpopen(M)
	else if(istype(AM, /obj/machinery/bot))
		var/obj/machinery/bot/bot = AM
		if(src.check_access(bot.botcard))
			if(density)
				open()
	else if(istype(AM, /obj/livestock))
		var/obj/livestock/ani =AM
		if(src.check_access(ani.anicard))
			if(density)
				open()
	else if(istype(AM, /obj/alien/facehugger))
		if(src.check_access(null))
			if(density)
				open()

/obj/machinery/door/unpowered
	autoclose = 0
	var/locked = 0

/obj/machinery/door/unpowered/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/door/unpowered/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/door/unpowered/attack_hand(mob/user as mob)
	return src.attackby(null, user)

/obj/machinery/door/unpowered/attackby(obj/item/I as obj, mob/user as mob)
	if (src.operating)
		return
	if (src.locked)
		return
	src.add_fingerprint(user)
	if (src.allowed(user))
		if (src.density)
			open()
		else
			close()
	return

/obj/machinery/door/unpowered/shuttle
	icon = 'shuttle.dmi'
	name = "door"
	icon_state = "door1"
	opacity = 1
	density = 1