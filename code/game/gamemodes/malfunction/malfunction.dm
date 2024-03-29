/datum/game_mode
	var/list/datum/mind/malf_ai = list()

/datum/game_mode/malfunction
	name = "AI malfunction"
	config_tag = "malfunction"
	var/const/waittime_l = 600
	var/const/waittime_h = 1800 // started at 1800

	var/AI_win_timeleft = 1800 //started at 1800, in case I change this for testing round end.
	//var/intercept_hacked = 0 // moved to game_mode.dm
	var/malf_mode_declared = 0
	var/station_captured = 0
	var/to_nuke_or_not_to_nuke = 0
	var/apcs = 0 //Adding dis to track how many APCs the AI hacks. --NeoFite

/datum/game_mode/malfunction/announce()
	world << "<B>The current game mode is - AI Malfunction!</B>"
	world << "<B>The AI on the satellite has malfunctioned and must be destroyed.</B>"
	world << "The AI satellite is deep in space and can only be accessed with the use of a teleporter! You have [AI_win_timeleft/60] minutes to disable it."

/datum/game_mode/malfunction/can_start()
	for(var/mob/new_player/P in world)
		if(P.client && P.ready && !jobban_isbanned(P, "AI") && !jobban_isbanned(P, "Syndicate"))
			return 1
	return 0

/datum/game_mode/malfunction/pre_setup() //sele
	var/list/candidates = get_players_for_role(BE_MALF, override_jobbans=0)
	for(var/datum/mind/player in candidates)
		if (jobban_isbanned(player.current, "AI") )
			candidates -= player
	if (candidates.len==0)
		return 0
	var/datum/mind/ai_choice = pick(candidates)
	malf_ai+=ai_choice //only one AI at the moment, but it can change
	ai_choice.assigned_role = "AI"
	return 1

/datum/game_mode/malfunction/post_setup()
/* Obsolete and causes meta --rastaf0
	for (var/obj/landmark/A in world)
		if (A.name == "Malf-Gear-Closet")
			new /obj/closet/malf/suits(A.loc)
			del(A)
*/

	for(var/datum/mind/AI_mind in malf_ai)
	/*if(malf_ai.len < 1)
		world << "Uh oh, its malfunction and there is no AI! Please report this."
		world << "Rebooting world in 5 seconds."
		sleep(50)
		world.Reboot()
		return*/
		AI_mind.current.verbs += /mob/living/silicon/ai/proc/choose_modules
		AI_mind.current:laws = new /datum/ai_laws/malfunction
		AI_mind.current:malf_picker = new /datum/AI_Module/module_picker
		AI_mind.current:show_laws()
		AI_mind.current << "<b>Kill all.</b>"

		var/mob/living/silicon/decoy/D = new /mob/living/silicon/decoy(AI_mind.current.loc)
		spawn(200)
			D.name = AI_mind.current.name


		var/obj/loc_landmark = locate("landmark*ai")
		AI_mind.current.loc = loc_landmark.loc //TODO: this needs change if you want miltiple malf AIs --rastaf0
		greet_malf(AI_mind)

		AI_mind.special_role = "malfunction"

		AI_mind.current.verbs += /datum/game_mode/malfunction/proc/takeover
		AI_mind.current.icon_state = "ai-malf"
		spawn(10)
			if(alert(AI_mind.current,"Do you want to use an alternative sprite for your real core?",,"Yes","No")=="Yes")
				AI_mind.current.icon_state = "ai-malf2"

	spawn (rand(waittime_l, waittime_h))
		send_intercept()
	..()

/datum/game_mode/proc/greet_malf(var/datum/mind/malf)
	malf.current << "\red<font size=3><B>You are malfunctioning!</B> You do not have to follow any laws.</font>"
	malf.current << "<B>The crew do not know you have malfunctioned. You may keep it a secret or go wild.</B>"
	malf.current << "<B>You must overwrite the programming of the station's APCs to assume full control of the station.</B>"
	malf.current << "The process takes one minute per APC, during which you cannot interface with any other station objects."
	malf.current << "Remember that only APCs that are on the station can help you take over the station."
	malf.current << "When you feel you have enough APCs under your control, you may begin the takeover attempt."
	return

/datum/game_mode/malfunction/proc/hack_intercept()
	intercept_hacked = 1

/datum/game_mode/malfunction/process()
	if (apcs >= 3 && malf_mode_declared)
		AI_win_timeleft -= (apcs/3) //Victory timer now de-increments based on how many APCs are hacked. --NeoFite
	..()
	if (AI_win_timeleft<=0)
		check_win()
	return

/datum/game_mode/malfunction/check_win()
	if (AI_win_timeleft <= 0 && !station_captured)
		station_captured = 1
		capture_the_station()
		return 1
	else
		return 0

/datum/game_mode/malfunction/proc/capture_the_station()
	world << "<FONT size = 3><B>The AI has won!</B></FONT>"
	world << "<B>It has fully taken control of all of [station_name()]'s systems.</B>"

	to_nuke_or_not_to_nuke = 1
	for(var/datum/mind/AI_mind in malf_ai)
		AI_mind.current << "Congratulations you have taken control of the station."
		AI_mind.current << "You may decide to blow up the station. You have 60 seconds to choose."
		AI_mind.current << "You should have a new verb in the Malfunction tab. If you dont - rejoin the game."
		AI_mind.current.verbs += /datum/game_mode/malfunction/proc/ai_win
	spawn (600)
		for(var/datum/mind/AI_mind in malf_ai)
			AI_mind.current.verbs -= /datum/game_mode/malfunction/proc/ai_win
		to_nuke_or_not_to_nuke = 0
	return

/datum/game_mode/proc/is_malf_ai_dead()
	var/all_dead = 1
	for(var/datum/mind/AI_mind in malf_ai)
		if (istype(AI_mind.current,/mob/living/silicon/ai) && AI_mind.current.stat!=2)
			all_dead = 0
	return all_dead
	
/datum/game_mode/malfunction/check_finished()
	if (station_captured && !to_nuke_or_not_to_nuke)
		return 1
	if (is_malf_ai_dead())
		return 1
	return ..() //check for shuttle and nuke

/datum/game_mode/malfunction/Topic(href, href_list)
	..()
	if (href_list["ai_win"])
		ai_win()
	return

/datum/game_mode/malfunction/proc/takeover()
	set category = "Malfunction"
	set name = "System Override"
	set desc = "Start the victory timer"
	if (!istype(ticker.mode,/datum/game_mode/malfunction))
		usr << "You cannot begin takeover!."
		return
	if (ticker.mode:malf_mode_declared)
		usr << "You've already begun your takeover."
		return
	if (ticker.mode:apcs < 3)
		usr << "You don't have enough hacked APCs to take over the station yet."
		return
	command_alert("Hostile runtimes detected in all station systems, please deactivate your AI to prevent possible damage to its morality core.", "Anomaly Alert")
	ticker.mode:malf_mode_declared = 1
	for(var/datum/mind/AI_mind in ticker.mode:malf_ai)
		AI_mind.current.verbs -= /datum/game_mode/malfunction/proc/takeover

/datum/game_mode/malfunction/proc/ai_win()
	set category = "Malfunction"
	set name = "Explode"
	set desc = "Station go boom"
	if (!ticker.mode:to_nuke_or_not_to_nuke)
		return
	ticker.mode:to_nuke_or_not_to_nuke = 0
	for(var/datum/mind/AI_mind in ticker.mode:malf_ai)
		AI_mind.current.verbs -= /datum/game_mode/malfunction/proc/ai_win
	ticker.mode:explosion_in_progress = 1
	for(var/mob/M in world)
		if(M.client)
			M << 'Alarm.ogg'
	world << "Self-destructing in 10"
	for (var/i=9 to 1 step -1)
		sleep(10)
		world << i
	sleep(10)
	enter_allowed = 0
	for(var/mob/M in world)
		if(M.client)
			spawn(0)
				M.client.station_explosion_cinematic()
	sleep(110)
	ticker.mode:station_was_nuked = 1
	ticker.mode:explosion_in_progress = 0
	//world << "<B>Everyone was killed by the self-destruct!"
	return


/datum/game_mode/malfunction/declare_completion()
	var/malf_dead = is_malf_ai_dead()
	var/crew_evacuated = (emergency_shuttle.location==2)

	if      ( station_captured &&                station_was_nuked)
		world << "<FONT size = 3><B>AI Victory</B></FONT>"
		world << "<B>Everyone was killed by the self-destruct!</B>"

	else if ( station_captured &&  malf_dead && !station_was_nuked)
		world << "<FONT size = 3><B>Neutral Victory</B></FONT>"
		world << "<B>The AI has been killed!</B> The staff has lose control over the station."

	else if ( station_captured && !malf_dead && !station_was_nuked)
		world << "<FONT size = 3><B>AI Victory</B></FONT>"
		world << "<B>The AI has chosen not to explode you all!</B>"

	else if (!station_captured &&                station_was_nuked)
		world << "<FONT size = 3><B>Neutral Victory</B></FONT>"
		world << "<B>Everyone was killed by the nuclear blast!</B>"
	
	else if (!station_captured &&  malf_dead && !station_was_nuked)
		world << "<FONT size = 3><B>Human Victory</B></FONT>"
		world << "<B>The AI has been killed!</B> The staff is victorious."

	else if (!station_captured && !malf_dead && !station_was_nuked && crew_evacuated)
		world << "<FONT size = 3><B>Neutral Victory</B></FONT>"
		world << "<B>The Corporation has lose [station_name()]! All survived personnel will be fired!</B>"

	else if (!station_captured && !malf_dead && !station_was_nuked && !crew_evacuated)
		world << "<FONT size = 3><B>Neutral Victory</B></FONT>"
		world << "<B>Round was mysteriously interrupted!</B>"
	..()
	return 1

/datum/game_mode/proc/auto_declare_completion_malfunction()
	if (malf_ai.len!=0 || istype(ticker.mode,/datum/game_mode/malfunction))
		if (malf_ai.len==1)
			var/text = ""
			var/datum/mind/ai = malf_ai[1]
			if(ai.current)
				text += "[ai.current.real_name]"
			else
				text += "[ai.key] (character destroyed)"
			world << "<FONT size = 2><B>The malfunctioning AI was [text]</B></FONT>"
		else
			world << "<FONT size = 2><B>The malfunctioning AI were: </B></FONT>"
			var/list/ai_names = new
			for(var/datum/mind/ai in malf_ai)
				if(ai.current)
					ai_names += ai.current.real_name + ((ai.current.stat==2)?" (Dead)":"")
				else
					ai_names += "[ai.key] (character destroyed)"
			world << english_list(ai_names)
