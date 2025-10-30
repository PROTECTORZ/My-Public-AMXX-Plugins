#if defined _vzbb_mod_included
	#endinput
#endif

#define _vzbb_mod_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib vzbb_mod
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib vzbb_mod
	#endif
#else
	#pragma library vzbb_mod
#endif

/* return ... (blocks the forward) */
#define FORWARD_CONTINUE 777

/* Unlimited number of item purchases */
#define NO_MAX_BUYS 0

/* When can the item be used? */
enum
{
	USE_BATTLE = 0,
	USE_BUILD,
	USE_BOTH
}

/* Who can use the item? */
enum
{
	TEAM_ZOMBIES = 1,
	TEAM_HUMANS,
	TEAM_BOTH
}

/* How does the block move? */
enum
{
	BLOCK_PULL = 1,
	BLOCK_PUSH
}

/* What mode is being played this round? */
enum
{
	MODE_NORMAL = 0,
	MODE_INFECTION
}

/* What type of grenade was thrown? */
enum
{
	NADE_HE = 1,
	NADE_SMOKE,
	NADE_FLASH
}

/* What type of fun block is this? */
enum
{
	BLOCKS_NORMAL = 0,
	BLOCKS_YELLOW,	// fast-moving block
	BLOCKS_BLACK,	// immovable block
	BLOCKS_BLUE,	// slowing block
	BLOCKS_RED		// burning block
}

/**
* Registers a new zombie class
*
* @param classname		The name of the zombie class (e.g. "Test Zombie")
* @param classinfo		Short info about the zombie class (e.g. "g+ s-")
* @param classmdl		Zombie model name (e.g. "zombie" – must exist in models/player/name/name.mdl)
* @param classclawmdl	Zombie hand/claw model (e.g. "claw" – must exist in models/name.mdl)
* @param health			Zombie class health (e.g. 2000)
* @param gravity		Zombie gravity (e.g. 0.5) (1.0 = 800 gravity, 0.5 = 400 gravity, etc.)
* @param speed			Zombie speed (e.g. 400.0) (0.0 = normal speed)
* @param access			Admin access required to choose the class (ADMIN_ALL – for everyone)
* @return 				Returns the index of the class. (int)
*/
native register_zombie_class(const classname[], const classinfo[], const classmdl[], const classclawmdl[], health, Float:gravity, Float:speed, access)

/**
* Registers a new shop item
*
* @param itemname		Item name (e.g. "Test Item")
* @param itemcost		Item price (e.g. 15)
* @param itemuse		When can the item be used? (USE_BATTLE – during battle phase, USE_BUILD – during build phase, USE_BOTH – in both)
* @param itemteam		Who can buy the item? (TEAM_ZOMBIES – zombies, TEAM_HUMANS – humans, TEAM_BOTH – everyone)
* @param access			Admin access required to buy the item (ADMIN_ALL – for everyone)
* @param maxbuys		How many times per round can the item be bought? (NO_MAX_BUYS – unlimited)
* @return 				Returns the index of the item. (int)
*/
native register_shop_item(const itemname[], itemcost, itemuse, itemteam, access, maxbuys)

/**
 * Returns the index of the player's zombie class. (int)
 *
 * @param id		Player index
 * @return			Returns the zombie class index (-1 if Classic Zombie)
 */
native get_user_zombie_class(id)

/**
 * Sets the player's zombie class index
 *
 * @param id		Player index
 * @param classid	Zombie class index (-1 = Classic Zombie)
 *
 * @noreturn
 */
native set_user_zombie_class(id, classid)

/**
 * Returns true if the player is a zombie
 *
 * @param id		Player index
 * @return			true if zombie, false otherwise (bool)
 */
native is_user_zombie(id)

/**
 * Returns true if the player is human
 *
 * @param id		Player index
 * @return			true if human, false otherwise (bool)
 */
native is_user_human(id)

/**
 * Returns the amount of credits a player has
 *
 * @param id		Player index
 * @return			Player credits. (int)
 */
native get_user_credits(id)

/**
 * Sets the amount of credits a player has
 *
 * @param id		Player index
 * @param credits	Value to set (use with get_user_credits if adding/removing credits)
 *
 * @noreturn
 */
native set_user_credits(id, credits)

/**
 * Returns total number of loaded zombie classes
 *
 * @return			Total zombie classes. (int)
 */
native get_total_zombie_classes()

/**
 * Returns total number of loaded shop items
 *
 * @return			Total shop items. (int)
 */
native get_total_shop_items()

/**
 * Returns true if the player can build during battle phase
 *
 * @param id		Player index
 * @return			true if can build during battle phase, false otherwise. (bool)
 */
native get_user_can_build_battle(id)

/**
 * Sets if the player can move blocks during battle phase
 * (effective until next battle phase starts)
 *
 * @param id		Player index
 * @param set		true = can build, false = cannot
 *
 * @noreturn
 */
native set_user_can_build_battle(id, set)

/**
 * Returns the entity index of the block the player is currently moving
 *
 * @param id		Player index
 * @return			Entity index of the block. (int)
 */
native get_user_block_ent(id)

/**
 * Sets the entity index of the block the player is currently moving
 *
 * @param id		Player index
 * @param ent		Entity index
 *
 * @noreturn
 */
native set_user_block_ent(id, ent)

/**
 * Returns true if it is currently freezetime
 *
 * @return			true if yes, false if not. (bool)
 */
native is_freezetime()

/**
 * Returns the remaining build phase time in seconds
 *
 * @return			Remaining time (seconds). (int)
 */
native get_build_phase_remaining_time()

/**
 * Returns true if players can currently build (if it's build phase)
 *
 * @return			true if they can, false otherwise. (bool)
 */
native user_can_build()

/**
 * Sets whether players can build (defines if it's build phase)
 *
 * @param build		true = can build, false = cannot
 *
 * @noreturn
 */
native set_user_can_build(build)

/**
 * Returns current round mode
 *
 * @return			MODE_NORMAL – normal mode, MODE_INFECTION – infection mode. (int)
 */
native get_roundmode()

/**
 * Returns true if the player was a zombie at spawn
 *
 * @param id		Player index
 * @return			true if was zombie, false otherwise. (bool)
 */
native was_user_zombie(id)

/**
 * Sets whether the player was a zombie at spawn (used for infection mode)
 *
 * @param id		Player index
 * @param true		1 = was zombie, 0 = not
 *
 * @noreturn
 */
native set_user_was_zombie(id, true)

/**
 * Returns true if the player is banned (from block movement)
 *
 * @param id		Player index
 * @return			true if banned, false otherwise. (bool)
 */
native is_user_banned(id)

/**
 * Returns remaining burn damage duration
 *
 * @param id		Player index
 * @return			Remaining burn damage amount. (int)
 */
native get_user_fire_duration(id)

/**
 * Sets remaining burn damage duration
 *
 * @param id		Player index
 * @param duration	Value to set (1 = stop burning)
 */
native set_user_fire_duration(id, duration)

/**
 * Returns true if the player is frozen
 *
 * @param id		Player index
 * @return			true if frozen, false otherwise. (bool)
 */
native is_user_frozen(id)

/**
 * Returns true if the player is frozen (and starts melting)
 *
 * @param id		Player index
 * @return			true if melting, false otherwise. (bool)
 */
native is_user_frozen_cool(id)

/**
 * Ignites a player
 *
 * @param attacker	Attacker index
 * @param victim	Victim index
 * @param duration	Max burn damage (0 = uses CVAR vzbb_grenade_fire_duration)
 *
 * @noreturn
 */
native user_burn(attacker, victim, duration)

/**
 * Freezes a player
 *
 * @param id		Player index
 *
 * @noreturn
 */
native user_freeze(id)

/**
 * Freezes a player (starts melting immediately)
 *
 * @param id		Player index
 *
 * @noreturn
 */
native user_freeze_cool(id)

/**
 * Unfreezes a player
 *
 * @param id		Player index
 *
 * @noreturn
 */
native user_unfreeze(id)

/**
 * Stops melting a player
 *
 * @param id		Player index
 *
 * @noreturn
 */
native user_unfreeze_cool(id)

/**
 * Infects a player
 *
 * @param victim	Victim index
 * @param infector	Infector index
 *
 * @noreturn
 */
native user_infect(victim, infector)

/**
 * De-infects a player
 *
 * @param id		Player index
 *
 * @noreturn
 */
native user_uninfect(id)

/**
 * Returns the fun type of a block
 *
 * @param ent		Block entity index
 * @return			Fun type of block (int)
 */
native get_block_fun_type(ent)

/**
 * Sets the fun type of a block
 *
 * @param ent		Block entity index
 * @param funtype	Fun type (BLOCKS_YELLOW – fast block, BLOCKS_BLACK – immovable, BLOCKS_BLUE – slow, BLOCKS_RED – burning)
 *
 * @noreturn
 */
native set_block_fun_type(ent, funtype)

/**
 * Resets the fun type of a block
 *
 * @param ent		Block entity index
 *
 * @noreturn
 */
native reset_block_fun_type(ent)

/**
 * Returns the current "Round Deal" discount value
 *
 * @return			Discount value. (int)
 */
native get_deal_discount()

/**
 * Returns true if the item is part of the current "Round Deal" offers
 *
 * @return			true if yes, false if not. (bool)
 */
native is_deal_offer(itemid)

/**
 * Removes the barrier (if any)
 *
 * @noreturn
 */
native hide_barrierent()

/**
 * Resets the barrier position (if any)
 *
 * @noreturn
 */
native reset_barrierent()

/**
 * Sets HUD text for players, replacing the default mode HUD (use inside update_user_hud_data forward)
 *
 * @param text		Text (max length 128 chars, must be preformatted)
 */
native set_hud_cache_text(text[])

/**
 * Sets HUD color (RGB) for players, replacing the default mode HUD (use inside update_user_hud_data forward)
 *
 * @param r		Red
 * @param g		Green
 * @param b		Blue
 *
 * @noreturn
 */
native set_hud_cache_colors(r, g, b)

/**
 * Sets condition for displaying HUD (use inside update_user_hud_data forward)
 *
 * @param condition		true = always display
 *
 * @noreturn
 */
native set_hud_cache_condition(bool:condition)

/**
 * Forces HUD display update for all players
 *
 * @noreturn
 */
native force_user_hud_data()

/**
 * Opens the weapon menu for a player
 *
 * @param id		Player index
 *
 * @noreturn
 */
native force_weapon_menu(id)

/**
 * Restores player rendering (useful for removing glow or restoring invisibility)
 *
 * @param id		Player index
 *
 * @noreturn
 */
native restore_user_rendering(id)

/**
 * Called when a zombie class is selected
 *
 * @param id		Player index
 * @param classid	Zombie class index
 */
forward zombie_class_selected(id, classid)

/**
 * Called when a shop item is selected
 *
 * @note Return FORWARD_CONTINUE to block the item purchase.
 *
 * @param id		Player index
 * @param itemid	Item index
 */
forward shop_item_selected(id, itemid)

/**
 * Called when a block is pulled or pushed
 *
 * @note Return FORWARD_CONTINUE to stop execution.
 *
 * @param id			Player index
 * @param pullpush_type	1 = pull, 2 = push
 */
forward block_pull_push(id, pullpush_type)

/**
 * Called after battle phase begins
 */
forward battle_phase_begin()

/**
 * Called after an admin forces battle phase start (/start)
 *
 * @param id		Admin index
 */
forward battle_phase_begin_admin(id)

/**
 * Called before throwing a grenade
 *
 * @note Return FORWARD_CONTINUE to stop execution.
 *
 * @param owner		Grenade owner index
 * @param ent		Grenade entity index
 * @param nade_type	1 = HE (FireNade), 2 = Smoke, 3 = Flashbang (FrostNade)
 */
forward nade_throw_pre(owner, ent, nade_type)

/**
 * Called after throwing a grenade
 *
 * @param owner		Grenade owner index
 * @param ent		Grenade entity index
 * @param nade_type	1 = HE (FireNade), 2 = Smoke, 3 = Flashbang (FrostNade)
 */
forward nade_throw_post(owner, ent, nade_type)

/**
 * Called before each burn damage tick
 *
 * @param id		Player index
 */
forward user_burn_pre(id)

/**
 * Called after each burn damage tick
 *
 * @param id		Player index
 */
forward user_burn_post(id)

/**
 * Called when burning is removed from player
 *
 * @param id		Player index
 */
forward user_remove_burn(id)

/**
 * Called before freezing a player
 *
 * @param id		Player index
 */
forward user_freeze_pre(id)

/**
 * Called after freezing a player
 *
 * @param id		Player index
 */
forward user_freeze_post(id)

/**
 * Called before unfreezing a player
 *
 * @param id		Player index
 */
forward user_unfreeze_pre(id)

/**
 * Called after unfreezing a player
 *
 * @param id		Player index
 */
forward user_unfreeze_post(id)

/**
 * Called before player starts melting
 *
 * @param id		Player index
 */
forward user_freeze_cool_pre(id)

/**
 * Called after player starts melting
 *
 * @param id		Player index
 */
forward user_freeze_cool_post(id)

/**
 * Called before player stops melting
 *
 * @param id		Player index
 */
forward user_unfreeze_cool_pre(id)

/**
 * Called after player stops melting
 *
 * @param id		Player index
 */
forward user_unfreeze_cool_post(id)

/**
 * Called before infecting a player
 *
 * @note Return FORWARD_CONTINUE to stop execution.
 *
 * @param victim	Victim index
 * @param infector	Infector index
 */
forward user_infect_pre(victim, infector)

/**
 * Called after infecting a player
 *
 * @param victim	Victim index
 */
forward user_infect_post(victim)

/**
 * Called before de-infecting a player
 *
 * @note Return FORWARD_CONTINUE to stop execution.
 *
 * @param id		Player index
 */
forward user_uninfect_pre(id)

/**
 * Called after de-infecting a player
 *
 * @param id		Player index
 */
forward user_uninfect_post(id)

/**
 * Called before grabbing a block
 *
 * @note Return FORWARD_CONTINUE to stop execution.
 *
 * @param id		Player index
 */
forward grab_block_pre(id)

/**
 * Called after grabbing a block
 *
 * @param id		Player index
 */
forward grab_block_post(id)

/**
 * Called before releasing a block
 *
 * @param id		Player index
 */
forward release_block_pre(id)

/**
 * Called after releasing a block
 *
 * @param id		Player index
 */
forward release_block_post(id)

/**
 * Called on every HUD update for players
 *
 * @note Return FORWARD_CONTINUE to only display HUD and skip other battle-phase functions.
 */
forward update_user_hud_data()

/**
 * Called before touching a fun block
 *
 * @note Return FORWARD_CONTINUE to block fun effect.
 *
 * @param id		Player index
 * @param ent		Block entity index
 * @param funtype	Block fun type (BLOCKS_YELLOW – fast, BLOCKS_BLACK – immovable, BLOCKS_BLUE – slow, BLOCKS_RED – burning)
 */
forward fun_block_touch_pre(id, ent, funtype)

/**
 * Called after touching a fun block
 *
 * @param id		Player index
 * @param ent		Block entity index
 * @param funtype	Block fun type (BLOCKS_YELLOW – fast, BLOCKS_BLACK – immovable, BLOCKS_BLUE – slow, BLOCKS_RED – burning)
 */
forward fun_block_touch_post(id, ent, funtype)
