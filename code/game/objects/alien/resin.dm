// Resin walls improved. /N

/obj/alien/resin/proc/healthcheck()
	if(health <=0)
		density = 0
		if(affecting)
			var/mob/living/carbon/M = affecting
			contents.Remove(affecting)
			if(ishuman(M))
				M.verbs += /mob/living/carbon/human/verb/suicide
			else
				M.verbs += /mob/living/carbon/monkey/verb/suicide
			M.loc = loc
			M.paralysis += 10
			for(var/mob/O in viewers(src, 3))
				O.show_message(text("A body appeared from the dead resin!"), 1, text("You hear faint moaning somewhere about you."), 2)
		del(src)
	return

/obj/alien/resin/bullet_act(flag)
	switch(flag)
		if (PROJECTILE_BULLET)
			health -= 35
		if (PROJECTILE_BULLETBURST)
			health -= 13
		if (PROJECTILE_PULSE)
			health -= 50
		if (PROJECTILE_LASER)
			health -= 10
		if (PROJECTILE_SHOCK)
			health -= 15
	healthcheck()
	return

/obj/alien/resin/ex_act(severity)
	switch(severity)
		if(1.0)
			health-=50
		if(2.0)
			health-=50
		if(3.0)
			if (prob(50))
				health-=50
			else
				health-=25
	healthcheck()
	return

/obj/alien/resin/blob_act()
	health-=50
	healthcheck()
	return

/obj/alien/resin/meteorhit()
	health-=50
	healthcheck()
	return

/obj/alien/resin/hitby(AM as mob|obj)
	..()
	for(var/mob/O in viewers(src, null))
		O.show_message(text("\red <B>[src] was hit by [AM].</B>"), 1)
	var/tforce = 0
	if(ismob(AM))
		tforce = 10
	else
		tforce = AM:throwforce
	playsound(loc, 'attackblob.ogg', 100, 1)
	health = max(0, health - tforce)
	healthcheck()
	..()
	return

/obj/alien/resin/attack_hand()
	if ((usr.mutations & HULK))
		usr << text("\blue You easily destroy the resin wall.")
		for(var/mob/O in oviewers(src))
			O.show_message(text("\red [] destroys the resin wall!", usr), 1)
		health-=50
	healthcheck()
	return

/obj/alien/resin/attack_paw()
	return attack_hand()

/obj/alien/resin/attack_alien()
	if (islarva(usr))//Safety check for larva. /N
		return
	usr << text("\green You claw at the resin wall.")
	for(var/mob/O in oviewers(src))
		O.show_message(text("\red [] claws at the resin!", usr), 1)
	playsound(loc, 'attackblob.ogg', 100, 1)
	health -= rand(10, 20)
	if(health <= 0)
		usr << text("\green You slice the resin wall to pieces.")
		for(var/mob/O in oviewers(src))
			O.show_message(text("\red [] slices the resin wall apart!", usr), 1)
	healthcheck()
	return

/obj/alien/resin/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (istype(W, /obj/item/weapon/grab) && get_dist(src,user)<2)
		var/obj/item/weapon/grab/G = W
		if(isalien(user)&&(ishuman(G.affecting)||ismonkey(G.affecting)))
		//Only aliens can stick humans and monkeys into resin walls. Also, the wall must not have a person inside already.
			if(!affecting)
				if(G.state<2)
					user << "\red You need a better grip to do that!"
					return
				G.affecting.loc = src
				G.affecting.paralysis = 10
				for(var/mob/O in viewers(world.view, src))
					if (O.client)
						O << text("\green [] places [] in the resin wall!", G.assailant, G.affecting)
				affecting=G.affecting
				del(W)
				spawn(0)
					process()
			else
				user << "\red This wall is already occupied."
		return

	var/aforce = W.force
	health = max(0, health - aforce)
	playsound(loc, 'attackblob.ogg', 100, 1)
	healthcheck()
	..()
	return

/obj/alien/resin/proc/process()
	if(affecting)
		var/mob/living/carbon/M = affecting
		var/check = 0
		if(ishuman(affecting))//So they do not suicide and kill the babby.
			M.verbs -= /mob/living/carbon/human/verb/suicide
		else
			check = 1
			M.verbs -= /mob/living/carbon/monkey/verb/suicide

		contents.Add(affecting)

		while(!isnull(M)&&!isnull(src))//While M and wall exist
			if(prob(90)&& M.mutations & HULK)//If they're the Hulk, they're getting out.
				M << "You smash your way to freedom!"
				break
			if(prob(30))//Let's people know that someone is trapped in the resin wall.
				M << "\green You feel a strange sense of calm as a flesh-like substance seems to completely envelop you."
				for(var/mob/O in viewers(src, 3))
					O.show_message(text("There appears to be a person stuck inside a resin wall nearby."), 1, text("You hear faint moaning somewhere about you."), 2)
			if(prob(5))//MAYBE they are able to crawl out on their own. Not likely...
				M << "You are able to crawl your way through the sticky mass, and out to freedom. But for how long?"
				break
			M.paralysis = 10//Set theis paralysis to 10 so they cannot act.
			sleep(50)//To cut down on processing time

		if(!isnull(src))
			affecting = null

		if(!isnull(M))//As long as they still exist.
			if(!check)//And now they can suicide again, even if they are already dead in case they get revived.
				M.verbs += /mob/living/carbon/human/verb/suicide
			else
				M.verbs += /mob/living/carbon/monkey/verb/suicide
			for(var/mob/O in viewers(src, 3))
				O.show_message(text("A body appeared from the dead resin!"), 1, text("You hear faint moaning somewhere about you."), 2)
		else
			for(var/mob/O in viewers(src, 3))
				O.show_message(text("\red An alien larva bursts from the resin wall!"), 1, text("\red You hear a high, alien screech nearby!"), 2)
	return
