ConRO.Warlock = {};
ConRO.Warlock.CheckTalents = function()
end
ConRO.Warlock.CheckPvPTalents = function()
end
local ConRO_Warlock, ids = ...;

function ConRO:EnableRotationModule(mode)
	mode = mode or 0;
	self.ModuleOnEnable = ConRO.Warlock.CheckTalents;
	self.ModuleOnEnable = ConRO.Warlock.CheckPvPTalents;
	if mode == 0 then
		self.Description = "Warlock [No Specialization Under 10]";
		self.NextSpell = ConRO.Warlock.Under10;
		self.ToggleHealer();
	end;
	if mode == 1 then
		self.Description = 'Warlock [Affliction - Caster]';
		if ConRO.db.profile._Spec_1_Enabled then
			self.NextSpell = ConRO.Warlock.Affliction;
			self.ToggleDamage();
			ConROWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
			ConRODefenseWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
		else
			self.NextSpell = ConRO.Warlock.Disabled;
			self.ToggleHealer();
			ConROWindow:SetAlpha(0);
			ConRODefenseWindow:SetAlpha(0);
		end
	end;
	if mode == 2 then
		self.Description = 'Warlock [Demonology - Caster]';
		if ConRO.db.profile._Spec_2_Enabled then
			self.NextSpell = ConRO.Warlock.Demonology;
			self.ToggleDamage();
			ConROWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
			ConRODefenseWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
		else
			self.NextSpell = ConRO.Warlock.Disabled;
			self.ToggleHealer();
			ConROWindow:SetAlpha(0);
			ConRODefenseWindow:SetAlpha(0);
		end
	end;
	if mode == 3 then
		self.Description = 'Warlock [Destruction - Caster]';
		if ConRO.db.profile._Spec_3_Enabled then
			self.NextSpell = ConRO.Warlock.Destruction;
			self.ToggleDamage();
			self.BlockAoE();
			ConROWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
			ConRODefenseWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
		else
			self.NextSpell = ConRO.Warlock.Disabled;
			self.ToggleHealer();
			ConROWindow:SetAlpha(0);
			ConRODefenseWindow:SetAlpha(0);
		end
	end;
	self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED');
	self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED');
	self.lastSpellId = 0;
end

function ConRO:EnableDefenseModule(mode)
	mode = mode or 0;
	if mode == 0 then
		self.NextDef = ConRO.Warlock.Under10Def;
	end;
	if mode == 1 then
		if ConRO.db.profile._Spec_1_Enabled then
			self.NextDef = ConRO.Warlock.AfflictionDef;
		else
			self.NextDef = ConRO.Warlock.Disabled;
		end
	end;
	if mode == 2 then
		if ConRO.db.profile._Spec_2_Enabled then
			self.NextDef = ConRO.Warlock.DemonologyDef;
		else
			self.NextDef = ConRO.Warlock.Disabled;
		end
	end;
	if mode == 3 then
		if ConRO.db.profile._Spec_3_Enabled then
			self.NextDef = ConRO.Warlock.DestructionDef;
		else
			self.NextDef = ConRO.Warlock.Disabled;
		end
	end;
end

function ConRO:UNIT_SPELLCAST_SUCCEEDED(event, unitID, lineID, spellID)
	if unitID == 'player' then
		self.lastSpellId = spellID;
	end
end

function ConRO.Warlock.Disabled(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	return nil;
end

function ConRO.Warlock.Under10(_, timeShift, currentSpell, gcd)
	wipe(ConRO.SuggestedSpells)
	local Racial, Ability, Passive, Form, Buff, Debuff, PetAbility, PvPTalent, Glyph = ids.Racial, ids.Warlock_Ability, ids.Warlock_Passive, ids.Warlock_Form, ids.Warlock_Buff, ids.Warlock_Debuff, ids.Warlock_PetAbility, ids.Warlock_PvPTalent, ids.Glyph;
--Info
	local _Player_Level																					= UnitLevel("player");
	local _Player_Percent_Health 																		= ConRO:PercentHealth('player');
	local _is_PvP																						= ConRO:IsPvP();
	local _in_combat 																					= UnitAffectingCombat('player');
	local _party_size																					= GetNumGroupMembers();

	local _is_PC																						= UnitPlayerControlled("target");
	local _is_Enemy 																					= ConRO:TarHostile();
	local _Target_Health 																				= UnitHealth('target');
	local _Target_Percent_Health 																		= ConRO:PercentHealth('target');

--Resources
	local _Mana, _Mana_Max, _Mana_Percent																= ConRO:PlayerPower('Mana');
	local _SoulShards																					= ConRO:PlayerPower('SoulShards');

--Racials
	local _ArcanePulse, _ArcanePulse_RDY																= ConRO:AbilityReady(Racial.ArcanePulse, timeShift);
	local _ArcaneTorrent, _ArcaneTorrent_RDY															= ConRO:AbilityReady(Racial.ArcaneTorrent, timeShift);
	local _Berserking, _Berserking_RDY																	= ConRO:AbilityReady(Racial.Berserking, timeShift);

--Abilities
	local _Corruption, _Corruption_RDY																	= ConRO:AbilityReady(Ability.Corruption, timeShift);
		local _Corruption_DEBUFF, _, _Corruption_DUR														= ConRO:TargetAura(Debuff.Corruption, timeShift);
	local _ShadowBolt, _ShadowBolt_RDY																	= ConRO:AbilityReady(Ability.ShadowBolt, timeShift);
	local _SummonImp, _SummonImp_RDY																	= ConRO:AbilityReady(Ability.SummonImp, timeShift);

--Conditions
	local _is_moving 																					= ConRO:PlayerSpeed();
	local _enemies_in_melee, _target_in_melee															= ConRO:Targets("Melee");
	local _target_in_10yrds 																			= CheckInteractDistance("target", 3);

	local _Pet_summoned 																				= ConRO:CallPet();
	local _Pet_assist 																					= ConRO:PetAssist();
	local _Pet_Percent_Health																			= ConRO:PercentHealth('pet');
	local _Void_out																						= IsSpellKnown(ids.Demo_PetAbility.ThreateningPresence, true);

--Warnings
	ConRO:Warnings("Summon your demon!", _SummonImp_RDY and not _Pet_summoned);

--Rotations	
	if _Corruption_RDY and not _Corruption_DEBUFF and currentSpell ~= _Corruption then
		tinsert(ConRO.SuggestedSpells, _Corruption);
	end

	if _ShadowBolt_RDY then
		tinsert(ConRO.SuggestedSpells, _ShadowBolt);
	end
return nil;
end

function ConRO.Warlock.Under10Def(_, timeShift, currentSpell, gcd)
	wipe(ConRO.SuggestedDefSpells)
	local Racial, Ability, Passive, Form, Buff, Debuff, PetAbility, PvPTalent, Glyph = ids.Racial, ids.Warlock_Ability, ids.Warlock_Passive, ids.Warlock_Form, ids.Warlock_Buff, ids.Warlock_Debuff, ids.Warlock_PetAbility, ids.Warlock_PvPTalent, ids.Glyph;
--Info
	local _Player_Level																					= UnitLevel("player");
	local _Player_Percent_Health 																		= ConRO:PercentHealth('player');
	local _is_PvP																						= ConRO:IsPvP();
	local _in_combat 																					= UnitAffectingCombat('player');
	local _party_size																					= GetNumGroupMembers();

	local _is_PC																						= UnitPlayerControlled("target");
	local _is_Enemy 																					= ConRO:TarHostile();
	local _Target_Health 																				= UnitHealth('target');
	local _Target_Percent_Health 																		= ConRO:PercentHealth('target');

--Resources
	local _Mana, _Mana_Max, _Mana_Percent																= ConRO:PlayerPower('Mana');
	local _SoulShards																					= ConRO:PlayerPower('SoulShards');

--Racials
	local _Cannibalize, _Cannibalize_RDY																= ConRO:AbilityReady(Racial.Cannibalize, timeShift);

--Abilities
	local _CreateHealthstone, _CreateHealthstone_RDY													= ConRO:AbilityReady(Ability.CreateHealthstone, timeShift);
		local _Healthstone, _Healthstone_RDY, _, _, _Healthstone_COUNT										= ConRO:ItemReady(Ability.Healthstone, timeShift);
	local _DrainLife, _DrainLife_RDY																	= ConRO:AbilityReady(Ability.DrainLife, timeShift);
	local _HealthFunnel, _HealthFunnel_RDY																= ConRO:AbilityReady(Ability.HealthFunnel, timeShift);
	local _UnendingResolve, _UnendingResolve_RDY 														= ConRO:AbilityReady(Ability.UnendingResolve, timeShift);

--Conditions
	local _is_moving 																					= ConRO:PlayerSpeed();
	local _enemies_in_melee, _target_in_melee															= ConRO:Targets("Melee");
	local _target_in_10yrds 																			= CheckInteractDistance("target", 3);

	local _Pet_summoned 																				= ConRO:CallPet();
	local _Pet_assist 																					= ConRO:PetAssist();
	local _Pet_Percent_Health																			= ConRO:PercentHealth('pet');

--Rotations	
	if _CreateHealthstone_RDY and not _in_combat and _Healthstone_COUNT <= 0 then
		tinsert(ConRO.SuggestedSpells, _CreateHealthstone);
	end

	if _DrainLife_RDY and _Player_Percent_Health <= 80 then
		tinsert(ConRO.SuggestedSpells, _DrainLife);
	end

	if _HealthFunnel_RDY and _Pet_summoned and _Pet_Percent_Health <= 50 then
		tinsert(ConRO.SuggestedSpells, _HealthFunnel);
	end

	if _Healthstone_RDY and _Player_Percent_Health <= 50 then
		tinsert(ConRO.SuggestedSpells, _Healthstone);
	end

	if _UnendingResolve_RDY then
		tinsert(ConRO.SuggestedSpells, _UnendingResolve);
	end
return nil;
end

function ConRO.Warlock.Affliction(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedSpells)
	local Racial, Ability, Passive, Form, Buff, Debuff, PetAbility, PvPTalent, Glyph = ids.Racial, ids.Aff_Ability, ids.Aff_Passive, ids.Aff_Form, ids.Aff_Buff, ids.Aff_Debuff, ids.Aff_PetAbility, ids.Aff_PvPTalent, ids.Glyph;
--Info
	local _Player_Level																					= UnitLevel("player");
	local _Player_Percent_Health 																		= ConRO:PercentHealth('player');
	local _is_PvP																						= ConRO:IsPvP();
	local _in_combat 																					= UnitAffectingCombat('player');
	local _party_size																					= GetNumGroupMembers();

	local _is_PC																						= UnitPlayerControlled("target");
	local _is_Enemy 																					= ConRO:TarHostile();
	local _Target_Health 																				= UnitHealth('target');
	local _Target_Percent_Health 																		= ConRO:PercentHealth('target');

--Resources
	local _Mana, _Mana_Max, _Mana_Percent																= ConRO:PlayerPower('Mana');
	local _SoulShards																					= ConRO:PlayerPower('SoulShards');

--Racials
	local _ArcanePulse, _ArcanePulse_RDY																= ConRO:AbilityReady(Racial.ArcanePulse, timeShift);
	local _Berserking, _Berserking_RDY																	= ConRO:AbilityReady(Racial.Berserking, timeShift);
	local _ArcaneTorrent, _ArcaneTorrent_RDY															= ConRO:AbilityReady(Racial.ArcaneTorrent, timeShift);

--Abilities
	local _Agony, _Agony_RDY																			= ConRO:AbilityReady(Ability.Agony, timeShift);
		local _Agony_DEBUFF, _, _Agony_DUR																	= ConRO:TargetAura(Debuff.Agony, timeShift);
		local _InevitableDemise_BUFF, _InevitableDemise_COUNT, _InevitableDemise_DUR 						= ConRO:Aura(Buff.InevitableDemise, timeShift);
	local _Corruption, _Corruption_RDY																	= ConRO:AbilityReady(Ability.Corruption, timeShift);
		local _Corruption_DEBUFF, _, _Corruption_DUR														= ConRO:TargetAura(Debuff.Corruption, timeShift);
	local _CommandDemon_SpellLock																		= ConRO:AbilityReady(Ability.CommandDemon.SpellLock, timeShift);
	local _DrainLife, _DrainLife_RDY																	= ConRO:AbilityReady(Ability.DrainLife, timeShift);
	local _MaleficRapture, _MaleficRapture_RDY															= ConRO:AbilityReady(Ability.MaleficRapture, timeShift);
	local _SeedofCorruption, _SeedofCorruption_RDY														= ConRO:AbilityReady(Ability.SeedofCorruption, timeShift);
		local _SeedofCorruption_DEBUFF																		= ConRO:TargetAura(Debuff.SeedofCorruption, timeShift);
	local _ShadowBolt, _ShadowBolt_RDY																	= ConRO:AbilityReady(Ability.ShadowBolt, timeShift);
		local _ShadowEmbrace_DEBUFF, _ShadowEmbrace_COUNT, _ShadowEmbrace_DUR								= ConRO:TargetAura(Debuff.ShadowEmbrace, timeShift);
	local _SummonDarkglare, _SummonDarkglare_RDY, _SummonDarkglare_CD									= ConRO:AbilityReady(Ability.SummonDarkglare, timeShift);
	local _SummonFelhunter, _SummonFelhunter_RDY														= ConRO:AbilityReady(Ability.SummonDemon.Felhunter, timeShift);
	local _UnstableAffliction, _UnstableAffliction_RDY													= ConRO:AbilityReady(Ability.UnstableAffliction, timeShift);
		local _UnstableAffliction_DEBUFF, _, _UnstableAffliction_DUR										= ConRO:TargetAura(Debuff.UnstableAffliction, timeShift);

	local _SpellLock, _SpellLock_RDY																	= ConRO:AbilityReady(PetAbility.SpellLock, timeShift, 'pet');
	local _DevourMagic, _DevourMagic_RDY																= ConRO:AbilityReady(PetAbility.DevourMagic, timeShift, 'pet');
	local _DrainSoul, _DrainSoul_RDY																	= ConRO:AbilityReady(Ability.DrainSoul, timeShift);
		local _DrainSoul_DEBUFF																				= ConRO:TargetAura(Debuff.DrainSoul, timeShift);
	local _GrimoireofSacrifice, _GrimoireofSacrifice_RDY 												= ConRO:AbilityReady(Ability.GrimoireofSacrifice, timeShift);
		local _GrimoireofSacrifice_BUFF																	= ConRO:Aura(Buff.GrimoireofSacrifice, timeShift);
	local _Haunt, _Haunt_RDY																			= ConRO:AbilityReady(Ability.Haunt, timeShift);
	local _PhantomSingularity, _PhantomSingularity_RDY 													= ConRO:AbilityReady(Ability.PhantomSingularity, timeShift);
		local _PhantomSingularity_DEBUFF, _, _PhantomSingularity_DUR										= ConRO:TargetAura(Debuff.PhantomSingularity, timeShift);
	local _SiphonLife, _SiphonLife_RDY																	= ConRO:AbilityReady(Ability.SiphonLife, timeShift);
		local _SiphonLife_DEBUFF, _, _SiphonLife_DUR														= ConRO:TargetAura(Debuff.SiphonLife, timeShift);
	local _VileTaint, _VileTaint_RDY																	= ConRO:AbilityReady(Ability.VileTaint, timeShift);
		local _VileTaint_DEBUFF, _, _VileTaint_DUR															= ConRO:TargetAura(Debuff.VileTaint, timeShift);

	local _SoulRot, _SoulRot_RDY																		= ConRO:AbilityReady(Ability.SoulRot, timeShift);

--Conditions
	local _is_moving 																					= ConRO:PlayerSpeed();
	local _enemies_in_melee, _target_in_melee															= ConRO:Targets("Melee");
	local _target_in_10yrds 																			= CheckInteractDistance("target", 3);

	local _Pet_summoned 																				= ConRO:CallPet();
	local _Pet_assist 																					= ConRO:PetAssist();
	local _Pet_Percent_Health																			= ConRO:PercentHealth('pet');
	local _Void_out																						= IsSpellKnown(PetAbility.ThreateningPresence.spellID, true);

	if tChosen[Passive.AbsoluteCorruption.talentID] then
		_Corruption_DEBUFF = ConRO:PersistentDebuff(Debuff.Corruption);
		_Corruption_DUR = 10000;
	end

	if currentSpell == _MaleficRapture then
		_SoulShards = _SoulShards - 1;
	elseif currentSpell == _SeedofCorruption then
		_SoulShards = _SoulShards - 1;
	elseif currentSpell == _VileTaint then
		_SoulShards = _SoulShards - 1;
	end

	if _Player_Level >= 27 and ConRO_AoEButton:IsVisible() then
		_Corruption = _SeedofCorruption;
		_Corruption_RDY = _SeedofCorruption_RDY and _SoulShards >= 1;
	end

	if currentSpell == _Haunt then
		_ShadowEmbrace_COUNT = _ShadowEmbrace_COUNT + 1;
	elseif currentSpell == _ShadowBolt then
		_ShadowEmbrace_COUNT = _ShadowEmbrace_COUNT + 1;
	end

--Indicators
	ConRO:AbilityInterrupt(_CommandDemon_SpellLock, _SpellLock_RDY and ConRO:Interrupt());
	ConRO:AbilityInterrupt(_SpellLock, _SpellLock_RDY and ConRO:Interrupt());
	ConRO:AbilityPurge(_DevourMagic, _DevourMagic_RDY and ConRO:Purgable());
	ConRO:AbilityPurge(_ArcaneTorrent, _ArcaneTorrent_RDY and _target_in_melee and ConRO:Purgable());

	ConRO:AbilityBurst(_SummonDarkglare, _SummonDarkglare_RDY and _Agony_DEBUFF and _Corruption_DEBUFF and _UnstableAffliction_DEBUFF and (not tChosen[Ability.SiphonLife.talentID] or (tChosen[Ability.SiphonLife.talentID] and _SiphonLife_DEBUFF)) and (not tChosen[Ability.PhantomSingularity.talentID] or (tChosen[Ability.PhantomSingularity.talentID] and _PhantomSingularity_DEBUFF)) and (not tChosen[Ability.VileTaint.talentID] or (tChosen[Ability.VileTaint.talentID] and _VileTaint_DEBUFF)) and ConRO:BurstMode(_SummonDarkglare));
	ConRO:AbilityBurst(_PhantomSingularity, _PhantomSingularity_RDY and _Agony_DEBUFF and _Corruption_DEBUFF and _UnstableAffliction_DEBUFF and (not tChosen[Ability.SiphonLife.talentID] or (tChosen[Ability.SiphonLife.talentID] and _SiphonLife_DEBUFF)) and ConRO:BurstMode(_PhantomSingularity));
	ConRO:AbilityBurst(_SoulRot, _SoulRot_RDY and currentSpell ~= _SoulRot and _Agony_DEBUFF and _Corruption_DEBUFF and _UnstableAffliction_DEBUFF and (not tChosen[Ability.SiphonLife.talentID] or (tChosen[Ability.SiphonLife.talentID] and _SiphonLife_DEBUFF)) and ConRO:BurstMode(_SoulRot));

--Warnings
	ConRO:Warnings("Summon your demon!", not tChosen[Ability.GrimoireofSacrifice.talentID] and not _Pet_summoned);
	ConRO:Warnings("Call your pet to sacrifice!", tChosen[Ability.GrimoireofSacrifice.talentID] and not _GrimoireofSacrifice_BUFF and not _Pet_summoned);

	if _GrimoireofSacrifice_RDY and not _GrimoireofSacrifice_BUFF and not _Void_out then
		tinsert(ConRO.SuggestedSpells, _GrimoireofSacrifice);
	end

--Rotations	
	if _DrainLife_RDY and _InevitableDemise_COUNT == 50 and _InevitableDemise_DUR <= 3 then
		tinsert(ConRO.SuggestedSpells, _DrainLife);
	end

	if not _in_combat then
		if _Haunt_RDY and currentSpell ~= _Haunt and currentSpell ~= _UnstableAffliction then
			tinsert(ConRO.SuggestedSpells, _Haunt);
		end

		if _UnstableAffliction_RDY and not _UnstableAffliction_DEBUFF and currentSpell ~= _Haunt and currentSpell ~= _UnstableAffliction then
			tinsert(ConRO.SuggestedSpells, _UnstableAffliction);
		end

		if _Corruption_RDY and not (_Corruption_DEBUFF or _SeedofCorruption_DEBUFF) and currentSpell ~= _Corruption then
			tinsert(ConRO.SuggestedSpells, _Corruption);
		end
	else
		if _Agony_RDY and (not _Agony_DEBUFF or _Agony_DUR <= 3) then
			tinsert(ConRO.SuggestedSpells, _Agony);
		elseif _UnstableAffliction_RDY and (not _UnstableAffliction_DEBUFF or _UnstableAffliction_DUR <= 3) and currentSpell ~= _UnstableAffliction then
			tinsert(ConRO.SuggestedSpells, _UnstableAffliction);
		elseif _Corruption_RDY and (not _Corruption_DEBUFF or _Corruption_DUR <= 3) then
			tinsert(ConRO.SuggestedSpells, _Corruption);
		elseif _SiphonLife_RDY and (not _SiphonLife_DEBUFF or _SiphonLife_DUR <= 3) then
			tinsert(ConRO.SuggestedSpells, _SiphonLife);
		end

		if _Player_Level >= 58 and (_ShadowEmbrace_COUNT <= 0 or _ShadowEmbrace_DUR <= 2) then
			if _DrainSoul_RDY and tChosen[Ability.DrainSoul.talentID] then
				tinsert(ConRO.SuggestedSpells, _DrainSoul);
			elseif _ShadowBolt_RDY and not tChosen[Ability.DrainSoul.talentID] and currentSpell ~= _ShadowBolt then
				tinsert(ConRO.SuggestedSpells, _ShadowBolt);
			end
		end

		if _Haunt_RDY and currentSpell ~= _Haunt then
			tinsert(ConRO.SuggestedSpells, _Haunt);
		end

		if _VileTaint_RDY and _SoulShards >= 1 and currentSpell ~= _VileTaint then
			tinsert(ConRO.SuggestedSpells, _VileTaint);
		end

		if _PhantomSingularity_RDY and ConRO:FullMode(_PhantomSingularity) then
			tinsert(ConRO.SuggestedSpells, _PhantomSingularity);
		end

		if _MaleficRapture_RDY and (_SoulShards == 5 or (_SoulShards >= 1 and (_SummonDarkglare_CD >= 160))) then
			tinsert(ConRO.SuggestedSpells, _MaleficRapture);
		end

		if _SoulRot_RDY and currentSpell ~= _SoulRot and ConRO:FullMode(_SoulRot) then
			tinsert(ConRO.SuggestedSpells, _SoulRot);
		end

		if _SummonDarkglare_RDY and _Agony_DEBUFF and _Corruption_DEBUFF and _UnstableAffliction_DEBUFF and (not tChosen[Ability.SiphonLife.talentID] or (tChosen[Ability.SiphonLife.talentID] and _SiphonLife_DEBUFF)) and (not tChosen[Ability.PhantomSingularity.talentID] or (tChosen[Ability.PhantomSingularity.talentID] and _PhantomSingularity_DEBUFF)) and (not tChosen[Ability.VileTaint.talentID] or (tChosen[Ability.VileTaint.talentID] and _VileTaint_DEBUFF)) and ConRO:FullMode(_SummonDarkglare) then
			tinsert(ConRO.SuggestedSpells, _SummonDarkglare);
		end

		if _MaleficRapture_RDY and _SoulShards >= 1 and _SummonDarkglare_CD >= 15 then
			tinsert(ConRO.SuggestedSpells, _MaleficRapture);
		end

		if _DrainLife_RDY and _InevitableDemise_COUNT == 50 then
			tinsert(ConRO.SuggestedSpells, _DrainLife);
		end

		if _DrainSoul_RDY and tChosen[Ability.DrainSoul.talentID] then
			tinsert(ConRO.SuggestedSpells, _DrainSoul);
		elseif _ShadowBolt_RDY and not tChosen[Ability.DrainSoul.talentID] then
			tinsert(ConRO.SuggestedSpells, _ShadowBolt);
		end
	end
	return nil;
end

function ConRO.Warlock.AfflictionDef(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedDefSpells)
	local Racial, Ability, Passive, Form, Buff, Debuff, PetAbility, PvPTalent, Glyph = ids.Racial, ids.Aff_Ability, ids.Aff_Passive, ids.Aff_Form, ids.Aff_Buff, ids.Aff_Debuff, ids.Aff_PetAbility, ids.Aff_PvPTalent, ids.Glyph;
--Info
	local _Player_Level																					= UnitLevel("player");
	local _Player_Percent_Health 																		= ConRO:PercentHealth('player');
	local _is_PvP																						= ConRO:IsPvP();
	local _in_combat 																					= UnitAffectingCombat('player');
	local _party_size																					= GetNumGroupMembers();

	local _is_PC																						= UnitPlayerControlled("target");
	local _is_Enemy 																					= ConRO:TarHostile();
	local _Target_Health 																				= UnitHealth('target');
	local _Target_Percent_Health 																		= ConRO:PercentHealth('target');

--Resources
	local _Mana, _Mana_Max, _Mana_Percent																= ConRO:PlayerPower('Mana');
	local _SoulShards																					= ConRO:PlayerPower('SoulShards');

--Racials
	local _Cannibalize, _Cannibalize_RDY																= ConRO:AbilityReady(Racial.Cannibalize, timeShift);

--Abilities
	local _CreateHealthstone, _CreateHealthstone_RDY													= ConRO:AbilityReady(Ability.Healthstone.Create, timeShift);
		local _Healthstone, _Healthstone_RDY, _, _, _Healthstone_COUNT										= ConRO:ItemReady(Ability.Healthstone.Use, timeShift);
	local _DrainLife, _DrainLife_RDY																	= ConRO:AbilityReady(Ability.DrainLife, timeShift);
	local _HealthFunnel, _HealthFunnel_RDY																= ConRO:AbilityReady(Ability.HealthFunnel, timeShift);
	local _UnendingResolve, _UnendingResolve_RDY 														= ConRO:AbilityReady(Ability.UnendingResolve, timeShift);

	local _DarkPact, _DarkPact_RDY																		= ConRO:AbilityReady(Ability.DarkPact, timeShift);
	local _MortalCoil, _MortalCoil_RDY																	= ConRO:AbilityReady(Ability.MortalCoil, timeShift);

--Conditions
	local _is_moving 																					= ConRO:PlayerSpeed();
	local _enemies_in_melee, _target_in_melee															= ConRO:Targets("Melee");
	local _target_in_10yrds 																			= CheckInteractDistance("target", 3);

	local _Pet_summoned 																				= ConRO:CallPet();
	local _Pet_assist 																					= ConRO:PetAssist();
	local _Pet_Percent_Health																			= ConRO:PercentHealth('pet');
	local _Void_out																						= IsSpellKnown(PetAbility.ThreateningPresence.spellID, true);

--Rotations
	if _CreateHealthstone_RDY and not _in_combat and _Healthstone_COUNT <= 0 then
		tinsert(ConRO.SuggestedSpells, _CreateHealthstone);
	end

	if _DrainLife_RDY and _Player_Percent_Health <= 60 or (_Player_Percent_Health <= 80 and (_InevitableDemise_COUNT >= 50 or _InevitableDemise_DUR <= 3)) then
		tinsert(ConRO.SuggestedSpells, _DrainLife);
	end

	if _MortalCoil_RDY and _Player_Percent_Health <= 80 then
		tinsert(ConRO.SuggestedSpells, _MortalCoil);
	end

	if _HealthFunnel_RDY and _Pet_summoned and _Pet_Percent_Health <= 50 then
		tinsert(ConRO.SuggestedSpells, _HealthFunnel);
	end

	if _Healthstone_RDY and _Player_Percent_Health <= 50 then
		tinsert(ConRO.SuggestedSpells, _Healthstone);
	end

	if _DarkPact_RDY then
		tinsert(ConRO.SuggestedSpells, _DarkPact);
	end

	if _UnendingResolve_RDY then
		tinsert(ConRO.SuggestedSpells, _UnendingResolve);
	end
	return nil;
end

function ConRO.Warlock.Demonology(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedSpells)
	local Racial, Ability, Passive, Form, Buff, Debuff, PetAbility, PvPTalent, Glyph = ids.Racial, ids.Demo_Ability, ids.Demo_Passive, ids.Demo_Form, ids.Demo_Buff, ids.Demo_Debuff, ids.Demo_PetAbility, ids.Demo_PvPTalent, ids.Glyph;
--Info
	local _Player_Level																					= UnitLevel("player");
	local _Player_Percent_Health 																		= ConRO:PercentHealth('player');
	local _is_PvP																						= ConRO:IsPvP();
	local _in_combat 																					= UnitAffectingCombat('player');
	local _party_size																					= GetNumGroupMembers();

	local _is_PC																						= UnitPlayerControlled("target");
	local _is_Enemy 																					= ConRO:TarHostile();
	local _Target_Health 																				= UnitHealth('target');
	local _Target_Percent_Health 																		= ConRO:PercentHealth('target');

--Resources
	local _Mana, _Mana_Max, _Mana_Percent																= ConRO:PlayerPower('Mana');
	local _SoulShards																					= ConRO:PlayerPower('SoulShards');

--Racials
	local _ArcanePulse, _ArcanePulse_RDY																= ConRO:AbilityReady(Racial.ArcanePulse, timeShift);
	local _Berserking, _Berserking_RDY																	= ConRO:AbilityReady(Racial.Berserking, timeShift);
	local _ArcaneTorrent, _ArcaneTorrent_RDY															= ConRO:AbilityReady(Racial.ArcaneTorrent, timeShift);

--Abilities
	local _CallDreadstalkers, _CallDreadstalkers_RDY, _CallDreadstalkers_CD 							= ConRO:AbilityReady(Ability.CallDreadstalkers, timeShift);
	local _Demonbolt, _Demonbolt_RDY, _, _, _Demonbolt_CastTime											= ConRO:AbilityReady(Ability.Demonbolt, timeShift);
		local _DemonicCore_BUFF, _DemonicCore_COUNT, _DemonicCore_DUR										= ConRO:Aura(Buff.DemonicCore, timeShift);
	local _HandofGuldan, _HandofGuldan_RDY 																= ConRO:AbilityReady(Ability.HandofGuldan, timeShift);
	local _Implosion, _Implosion_RDY																	= ConRO:AbilityReady(Ability.Implosion, timeShift);
	local _ShadowBolt, _ShadowBolt_RDY					 												= ConRO:AbilityReady(Ability.ShadowBolt, timeShift);
		local _DemonicCalling_BUFF				 															= ConRO:Aura(Buff.DemonicCalling, timeShift);
	local _SummonDemonicTyrant, _SummonDemonicTyrant_RDY, _SummonDemonicTyrant_CD						= ConRO:AbilityReady(Ability.SummonDemonicTyrant, timeShift);
	local _SummonFelguard, _SummonFelguard_RDY															= ConRO:AbilityReady(Ability.SummonDemon.Felguard, timeShift);

	local _AxeToss, _AxeToss_RDY																		= ConRO:AbilityReady(PetAbility.AxeToss, timeShift, 'pet');
	local _DevourMagic, _DevourMagic_RDY																= ConRO:AbilityReady(PetAbility.DevourMagic, timeShift, 'pet');
	local _Felstorm, _Felstorm_RDY, _Felstorm_CD														= ConRO:AbilityReady(PetAbility.Felstorm, timeShift, 'pet');
	local _SpellLock, _SpellLock_RDY					 												= ConRO:AbilityReady(Ability.CommandDemon.SpellLock, timeShift, 'pet');

	local _BilescourgeBombers, _BilescourgeBombers_RDY													= ConRO:AbilityReady(Ability.BilescourgeBombers, timeShift);
	local _DemonicStrength, _DemonicStrength_RDY														= ConRO:AbilityReady(Ability.DemonicStrength, timeShift);
	local _Doom, _Doom_RDY 																				= ConRO:AbilityReady(Ability.Doom, timeShift);
		local _Doom_DEBUFF																					= ConRO:TargetAura(Debuff.Doom, timeShift + 4);
	local _GrimoireFelguard, _GrimoireFelguard_RDY				 										= ConRO:AbilityReady(Ability.GrimoireFelguard, timeShift);
	local _NetherPortal, _NetherPortal_RDY, _NetherPortal_CD											= ConRO:AbilityReady(Ability.NetherPortal, timeShift);
		local _NetherPortal_BUFF 																			= ConRO:Aura(Buff.NetherPortal, timeShift);
	local _PowerSiphon, _PowerSiphon_RDY																= ConRO:AbilityReady(Ability.PowerSiphon, timeShift);
	local _SoulStrike, _SoulStrike_RDY																	= ConRO:AbilityReady(Ability.SoulStrike, timeShift);
	local _SummonVilefiend, _SummonVilefiend_RDY, _SummonVilefiend_CD									= ConRO:AbilityReady(Ability.SummonVilefiend, timeShift);

--Conditions
	local _is_moving 																					= ConRO:PlayerSpeed();
	local _enemies_in_melee, _target_in_melee															= ConRO:Targets("Melee");
	local _target_in_10yrds 																			= CheckInteractDistance("target", 3);

	local _Pet_summoned 																				= ConRO:CallPet();
	local _Pet_assist 																					= ConRO:PetAssist();
	local _Pet_Percent_Health																			= ConRO:PercentHealth('pet');
	local _Void_out																						= IsSpellKnown(ids.Demo_PetAbility.ThreateningPresence.spellID, true);
	local _Felhunter_out																				= IsSpellKnown(ids.Demo_PetAbility.ShadowBite.spellID, true);


	if currentSpell == _HandofGuldan then
		_SoulShards = _SoulShards - 3;
	elseif currentSpell == _NetherPortal then
		_SoulShards = _SoulShards - 1;
	elseif currentSpell == _CallDreadstalkers then
		_SoulShards = _SoulShards - 2;
	elseif currentSpell == _SummonVilefiend then
		_SoulShards = _SoulShards - 1;
	elseif currentSpell == _Demonbolt then
		_SoulShards = _SoulShards + 2;
	elseif currentSpell == _ShadowBolt then
		_SoulShards = _SoulShards + 1;
	end

--Indicators
	ConRO:AbilityInterrupt(_SpellLock, _SpellLock_RDY and ConRO:Interrupt());
	ConRO:AbilityPurge(_DevourMagic, _DevourMagic_RDY and ConRO:Purgable());
	ConRO:AbilityPurge(_ArcaneTorrent, _ArcaneTorrent_RDY and _target_in_melee and ConRO:Purgable());

	ConRO:AbilityBurst(_DemonicStrength, _DemonicStrength_RDY and _Felstorm_CD <= 25 and ConRO:BurstMode(_DemonicStrength));
	ConRO:AbilityBurst(_GrimoireFelguard, _GrimoireFelguard_RDY and _SoulShards >= 1 and ConRO:BurstMode(_GrimoireFelguard));
	ConRO:AbilityBurst(_NetherPortal, _NetherPortal_RDY and _SummonDemonicTyrant_RDY and _CallDreadstalkers_RDY and (svilefiend or not tChosen[ids.Demo_Talent.SummonVilefiend]) and _SoulShards >= 1 and currentSpell ~= ids.Demo_Talent.NetherPortal and ConRO:BurstMode(_NetherPortal));
	ConRO:AbilityBurst(_SummonDemonicTyrant, _SummonDemonicTyrant_RDY and currentSpell ~= _SummonDemonicTyrant and _CallDreadstalkers_CD >= 10 and ConRO:ImpsOut() >= 6 and ConRO:BurstMode(_SummonDemonicTyrant));
	ConRO:AbilityBurst(_SummonVilefiend, _SummonVilefiend_RDY and _SoulShards >= 1 and ((_SummonDemonicTyrant_RDY and (_CallDreadstalkers_RDY or _CallDreadstalkers_CD >= 16)) or _SummonDemonicTyrant_CD >= 40) and currentSpell ~= _SummonVilefiend and (not tChosen[ids.Demo_Talent.NetherPortal] or (tChosen[ids.Demo_Talent.NetherPortal] and _NetherPortal_CD > 40)) and ConRO:BurstMode(_SummonVilefiend));

--Warnings
	ConRO:Warnings("Summon your Felguard!", not _Pet_summoned);

--Rotations
	if not _in_combat then
		if _Demonbolt_RDY and currentSpell ~= _Demonbolt then
			tinsert(ConRO.SuggestedSpells, _Demonbolt);
		end

		if _Doom_RDY and not _Doom_DEBUFF then
			tinsert(ConRO.SuggestedSpells, _Doom);
		end

		if _HandofGuldan_RDY and _SoulShards >= 1 and currentSpell ~= _HandofGuldan then
			tinsert(ConRO.SuggestedSpells, _HandofGuldan);
		end
	end

	if _is_moving then
		if _Demonbolt_RDY and _DemonicCore_COUNT >= 1 then
			tinsert(ConRO.SuggestedSpells, _Demonbolt);
		end

		if _Doom_RDY and not _Doom_DEBUFF then
			tinsert(ConRO.SuggestedSpells, _Doom);
		end

		if _DemonicStrength_RDY and _Felstorm_CD <= 25 and ConRO:FullMode(_DemonicStrength) then
			tinsert(ConRO.SuggestedSpells, _DemonicStrength);
		end

		if _SoulStrike_RDY and _SoulShards <= 4 then
			tinsert(ConRO.SuggestedSpells, _SoulStrike);
		end

		if _PowerSiphon_RDY and _DemonicCore_COUNT <= 1 and ConRO:ImpsOut() >= 2 then
			tinsert(ConRO.SuggestedSpells, _PowerSiphon);
		end
	end

	if _Demonbolt_RDY and _DemonicCore_DUR <= 2 and _DemonicCore_COUNT >= 1 then
		tinsert(ConRO.SuggestedSpells, _Demonbolt);
	end

	if _Doom_RDY and not _Doom_DEBUFF then
		tinsert(ConRO.SuggestedSpells, _Doom);
	end

	if _NetherPortal_RDY and (_SummonDemonicTyrant_RDY or _SummonDemonicTyrant_CD <= 9) and currentSpell ~= _NetherPortal and ConRO:FullMode(_NetherPortal) then
		if _NetherPortal_RDY and (_SummonDemonicTyrant_RDY or _SummonDemonicTyrant_CD <= 9) and _CallDreadstalkers_RDY and (not tChosen[ids.Demo_Talent.SummonVilefiend] or _SummonVilefiend_RDY) and _SoulShards >= 5 and currentSpell ~= _NetherPortal then
			tinsert(ConRO.SuggestedSpells, _NetherPortal);
		end

		if _Demonbolt_RDY and _DemonicCore_COUNT >= 2 and _SoulShards <= 3 then
			tinsert(ConRO.SuggestedSpells, _Demonbolt);
		end

		if _DemonicStrength_RDY and _Felstorm_CD <= 25 and ConRO:FullMode(_DemonicStrength) then
			tinsert(ConRO.SuggestedSpells, _DemonicStrength);
		end

		if _SoulStrike_RDY and _SoulShards <= 4 then
			tinsert(ConRO.SuggestedSpells, _SoulStrike);
		end

		if _ShadowBolt_RDY then
			tinsert(ConRO.SuggestedSpells, _ShadowBolt);
		end
	elseif _NetherPortal_BUFF or currentSpell == _NetherPortal then
		if _SummonDemonicTyrant_RDY and (ConRO.lastSpellId == _HandofGuldan or currentSpell == _HandofGuldan) then
			tinsert(ConRO.SuggestedSpells, _SummonDemonicTyrant);
		end

		if _BilescourgeBombers_RDY and _SoulShards >= 2 then
			tinsert(ConRO.SuggestedSpells, _BilescourgeBombers);
		end

		if _GrimoireFelguard_RDY and _SoulShards >= 1 then
			tinsert(ConRO.SuggestedSpells, _GrimoireFelguard);
		end

		if _SummonVilefiend_RDY and _SoulShards >= 1 and (_SummonDemonicTyrant_RDY or _SummonDemonicTyrant_CD >= 40) and currentSpell ~= _SummonVilefiend and ConRO:FullMode(_SummonVilefiend) then
			tinsert(ConRO.SuggestedSpells, _SummonVilefiend);
		end

		if _CallDreadstalkers_RDY and (_SoulShards >= 2 or (_SoulShards >= 1 and _DemonicCalling_BUFF)) and currentSpell ~= _CallDreadstalkers then
			tinsert(ConRO.SuggestedSpells, _CallDreadstalkers);
		end

		if _HandofGuldan_RDY and _SoulShards >= 1 and currentSpell ~= _HandofGuldan then
			tinsert(ConRO.SuggestedSpells, _HandofGuldan);
		end

		if _Demonbolt_RDY and _DemonicCore_COUNT >= 1 then
			tinsert(ConRO.SuggestedSpells, _Demonbolt);
		end

		if _ShadowBolt_RDY and _SoulShards <= 4 and currentSpell ~= _ShadowBolt then
			tinsert(ConRO.SuggestedSpells, _ShadowBolt);
		end
	else
		if _SummonDemonicTyrant_RDY and currentSpell ~= _SummonDemonicTyrant and _CallDreadstalkers_CD >= 8 and ConRO:ImpsOut() >= 3 and (ConRO.lastSpellId == _HandofGuldan or currentSpell == _HandofGuldan) and ConRO:FullMode(_SummonDemonicTyrant) then
			tinsert(ConRO.SuggestedSpells, _SummonDemonicTyrant);
		end

		if _GrimoireFelguard_RDY and _SoulShards >= 1 and ConRO:FullMode(_GrimoireFelguard) then
			tinsert(ConRO.SuggestedSpells, _GrimoireFelguard);
		end

		if _DemonicStrength_RDY and _Felstorm_CD <= 25 and ConRO:FullMode(_DemonicStrength) then
			tinsert(ConRO.SuggestedSpells, _DemonicStrength);
		end

		if _BilescourgeBombers_RDY and _SoulShards >= 2 then
			tinsert(ConRO.SuggestedSpells, _BilescourgeBombers);
		end

		if _SoulStrike_RDY and _SoulShards <= 4 then
			tinsert(ConRO.SuggestedSpells, _SoulStrike);
		end

		if _Implosion_RDY and ConRO:ImpsOut() >= 6 and ConRO_AoEButton:IsVisible() then
			tinsert(ConRO.SuggestedSpells, _Implosion);
		end

		if _SummonVilefiend_RDY and _SoulShards >= 1 and ((_SummonDemonicTyrant_RDY and (_CallDreadstalkers_RDY or _CallDreadstalkers_CD >= 16)) or _SummonDemonicTyrant_CD >= 40) and currentSpell ~= _SummonVilefiend and (not tChosen[ids.Demo_Talent.NetherPortal] or (tChosen[ids.Demo_Talent.NetherPortal] and (_NetherPortal_CD > 40 or ConRO:BurstMode(_NetherPortal)))) and ConRO:FullMode(_SummonVilefiend) then
			tinsert(ConRO.SuggestedSpells, _SummonVilefiend);
		end

		if _CallDreadstalkers_RDY and (_SoulShards >= 2 or _DemonicCalling_BUFF) and (_SummonDemonicTyrant_RDY or _SummonDemonicTyrant_CD >= 10) and currentSpell ~= ids.Demo_Ability.CallDreadstalkers and (not tChosen[ids.Demo_Talent.NetherPortal] or (tChosen[ids.Demo_Talent.NetherPortal] and (_NetherPortal_CD > 15 or ConRO:BurstMode(_NetherPortal)))) then
			tinsert(ConRO.SuggestedSpells, _CallDreadstalkers);
		end

		if _HandofGuldan_RDY and _SoulShards >= 3 and currentSpell ~= ids.Demo_Ability.HandofGuldan then
			tinsert(ConRO.SuggestedSpells, _HandofGuldan);
		end

		if _Demonbolt_RDY and (_DemonicCore_COUNT >= 2 or (_DemonicCore_COUNT >= 1 and _SummonDemonicTyrant_RDY and ConRO:FullMode(_SummonDemonicTyrant))) and _SoulShards <= 3 then
			tinsert(ConRO.SuggestedSpells, _Demonbolt);
		end

		if _PowerSiphon_RDY and _DemonicCore_COUNT <= 1 and ConRO:ImpsOut() >= 2 then
			tinsert(ConRO.SuggestedSpells, _PowerSiphon);
		end

		if _ShadowBolt_RDY and _SoulShards <= 4 then
			tinsert(ConRO.SuggestedSpells, _ShadowBolt);
		end
	end
return nil;
end

function ConRO.Warlock.DemonologyDef(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedDefSpells)
	local Racial, Ability, Passive, Form, Buff, Debuff, PetAbility, PvPTalent, Glyph = ids.Racial, ids.Demo_Ability, ids.Demo_Passive, ids.Demo_Form, ids.Demo_Buff, ids.Demo_Debuff, ids.Demo_PetAbility, ids.Demo_PvPTalent, ids.Glyph;
--Info
	local _Player_Level																					= UnitLevel("player");
	local _Player_Percent_Health 																		= ConRO:PercentHealth('player');
	local _is_PvP																						= ConRO:IsPvP();
	local _in_combat 																					= UnitAffectingCombat('player');
	local _party_size																					= GetNumGroupMembers();

	local _is_PC																						= UnitPlayerControlled("target");
	local _is_Enemy 																					= ConRO:TarHostile();
	local _Target_Health 																				= UnitHealth('target');
	local _Target_Percent_Health 																		= ConRO:PercentHealth('target');

--Resources
	local _Mana, _Mana_Max, _Mana_Percent																= ConRO:PlayerPower('Mana');
	local _SoulShards																					= ConRO:PlayerPower('SoulShards');

--Racials
	local _Cannibalize, _Cannibalize_RDY																= ConRO:AbilityReady(Racial.Cannibalize, timeShift);

--Abilities
	local _CreateHealthstone, _CreateHealthstone_RDY													= ConRO:AbilityReady(Ability.Healthstone.Create, timeShift);
		local _Healthstone, _Healthstone_RDY, _, _, _Healthstone_COUNT										= ConRO:ItemReady(Ability.Healthstone.Use, timeShift);
	local _DrainLife, _DrainLife_RDY																	= ConRO:AbilityReady(Ability.DrainLife, timeShift);
	local _HealthFunnel, _HealthFunnel_RDY																= ConRO:AbilityReady(Ability.HealthFunnel, timeShift);
	local _UnendingResolve, _UnendingResolve_RDY 														= ConRO:AbilityReady(Ability.UnendingResolve, timeShift);

	local _DarkPact, _DarkPact_RDY																		= ConRO:AbilityReady(Ability.DarkPact, timeShift);
	local _MortalCoil, _MortalCoil_RDY																	= ConRO:AbilityReady(Ability.MortalCoil, timeShift);

--Conditions
	local _is_moving 																					= ConRO:PlayerSpeed();
	local _enemies_in_melee, _target_in_melee															= ConRO:Targets("Melee");
	local _target_in_10yrds 																			= CheckInteractDistance("target", 3);

	local _Pet_summoned 																				= ConRO:CallPet();
	local _Pet_assist 																					= ConRO:PetAssist();
	local _Pet_Percent_Health																			= ConRO:PercentHealth('pet');
	local _Void_out																						= IsSpellKnown(PetAbility.ThreateningPresence.spellID, true);

--Rotations	
	if _CreateHealthstone_RDY and not _in_combat and _Healthstone_COUNT <= 0 then
		tinsert(ConRO.SuggestedSpells, _CreateHealthstone);
	end

	if _DrainLife_RDY and _Player_Percent_Health <= 60 then
		tinsert(ConRO.SuggestedSpells, _DrainLife);
	end

	if _MortalCoil_RDY and _Player_Percent_Health <= 80 then
		tinsert(ConRO.SuggestedSpells, _MortalCoil);
	end

	if _HealthFunnel_RDY and _Pet_summoned and _Pet_Percent_Health <= 50 then
		tinsert(ConRO.SuggestedSpells, _HealthFunnel);
	end

	if _Healthstone_RDY and _Player_Percent_Health <= 50 then
		tinsert(ConRO.SuggestedSpells, _Healthstone);
	end

	if _DarkPact_RDY then
		tinsert(ConRO.SuggestedSpells, _DarkPact);
	end

	if _UnendingResolve_RDY then
		tinsert(ConRO.SuggestedSpells, _UnendingResolve);
	end
	return nil;
end

function ConRO.Warlock.Destruction(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedSpells)
	local Racial, Ability, Passive, Form, Buff, Debuff, PetAbility, PvPTalent, Glyph = ids.Racial, ids.Dest_Ability, ids.Dest_Passive, ids.Dest_Form, ids.Dest_Buff, ids.Dest_Debuff, ids.Dest_PetAbility, ids.Dest_PvPTalent, ids.Glyph;
--Info
	local _Player_Level																					= UnitLevel("player");
	local _Player_Percent_Health 																		= ConRO:PercentHealth('player');
	local _is_PvP																						= ConRO:IsPvP();
	local _in_combat 																					= UnitAffectingCombat('player');
	local _party_size																					= GetNumGroupMembers();

	local _is_PC																						= UnitPlayerControlled("target");
	local _is_Enemy 																					= ConRO:TarHostile();
	local _Target_Health 																				= UnitHealth('target');
	local _Target_Percent_Health 																		= ConRO:PercentHealth('target');

--Resources
	local _Mana, _Mana_Max, _Mana_Percent																= ConRO:PlayerPower('Mana');
	local _SoulShards																					= ConRO:PlayerPower('SoulShards');

--Racials
	local _ArcanePulse, _ArcanePulse_RDY																= ConRO:AbilityReady(Racial.ArcanePulse, timeShift);
	local _Berserking, _Berserking_RDY																	= ConRO:AbilityReady(Racial.Berserking, timeShift);
	local _ArcaneTorrent, _ArcaneTorrent_RDY															= ConRO:AbilityReady(Racial.ArcaneTorrent, timeShift);

--Abilities	
	local _ChaosBolt, _ChaosBolt_RDY					 												= ConRO:AbilityReady(Ability.ChaosBolt, timeShift);
		local _Eradication_DEBUFF																			=ConRO:TargetAura(Debuff.Eradication, timeShift);
	local _Conflagrate, _Conflagrate_RDY								 								= ConRO:AbilityReady(Ability.Conflagrate, timeShift);
		local _Conflagrate_CHARGES																			= ConRO:SpellCharges(Ability.Conflagrate);
		local _Conflagrate_BUFF																				= ConRO:Aura(Buff.Conflagrate, timeShift);
		local _BackDraft_BUFF, _BackDraft_COUNT																= ConRO:Aura(Buff.BackDraft, timeShift);
	local _Havoc, _Havoc_RDY, _Havoc_CD																	= ConRO:AbilityReady(Ability.Havoc, timeShift);
		local _Havoc_DEBUFF																					=ConRO:TargetAura(Debuff.Havoc, timeShift);
	local _Immolate, _Immolate_RDY						 												= ConRO:AbilityReady(Ability.Immolate, timeShift);
		local _Immolate_DEBUFF				 																= ConRO:TargetAura(Debuff.Immolate, timeShift + 3);
	local _Incinerate, _Incinerate_RDY				 													= ConRO:AbilityReady(Ability.Incinerate, timeShift);
	local _RainofFire, _RainofFire_RDY																	= ConRO:AbilityReady(Ability.RainofFire, timeShift);
	local _SummonInfernal, _SummonInfernal_RDY, _SummonInfernal_CD										= ConRO:AbilityReady(Ability.SummonInfernal, timeShift);
	local _SummonImp, _SummonImp_RDY				 													= ConRO:AbilityReady(Ability.SummonDemon.Imp, timeShift);

	local _SpellLock, _SpellLock_RDY 																	= ConRO:AbilityReady(Ability.CommandDemon.SpellLock, timeShift, 'pet');
	local _DevourMagic, _DevourMagic_RDY																= ConRO:AbilityReady(PetAbility.DevourMagic, timeShift, 'pet');

	local _Cataclysm, _Cataclysm_RDY																	= ConRO:AbilityReady(Ability.Cataclysm, timeShift);
	local _ChannelDemonfire, _ChannelDemonfire_RDY									 					= ConRO:AbilityReady(Ability.ChannelDemonfire, timeShift);
	local _GrimoireofSacrifice, _GrimoireofSacrifice_RDY 												= ConRO:AbilityReady(Ability.GrimoireofSacrifice, timeShift);
		local _GrimoireofSacrifice_BUFF 																	= ConRO:Aura(Buff.GrimoireofSacrifice, timeShift);
	local _Shadowburn, _Shadowburn_RDY						 											= ConRO:AbilityReady(Ability.Shadowburn, timeShift);
	local _SoulFire, _SoulFire_RDY							 											= ConRO:AbilityReady(Ability.SoulFire, timeShift);

--Conditions
	local _is_moving 																					= ConRO:PlayerSpeed();
	local _enemies_in_melee, _target_in_melee															= ConRO:Targets("Melee");
	local _target_in_10yrds 																			= CheckInteractDistance("target", 3);
	local _enemies_in_range, _target_in_range															= ConRO:Targets(ids.Dest_Ability.Immolate);

	local _Pet_summoned 																				= ConRO:CallPet();
	local _Pet_assist 																					= ConRO:PetAssist();
	local _Pet_Percent_Health																			= ConRO:PercentHealth('pet');
	local _Void_out																						= IsSpellKnown(PetAbility.ThreateningPresence.spellID, true);

	if currentSpell == _ChaosBolt then
		_SoulShards = _SoulShards - 2;
	elseif currentSpell == _Incinerate then
		if ConRO:ItemEquipped(ids.Legendary.EmbersoftheDiabolicRaiment_Back) or ConRO:ItemEquipped(ids.Legendary.EmbersoftheDiabolicRaiment_Chest) then
			_SoulShards = _SoulShards + 0.4;
		else
			_SoulShards = _SoulShards + 0.2;
		end
	elseif currentSpell == _SoulFire then
		_SoulShards = _SoulShards + 1;
	end

--Indicators
	ConRO:AbilityInterrupt(_SpellLock, _SpellLock_RDY and ConRO:Interrupt());
	ConRO:AbilityPurge(_DevourMagic, _DevourMagic_RDY and ConRO:Purgable());
	ConRO:AbilityPurge(_ArcaneTorrent, _ArcaneTorrent_RDY and _target_in_melee and ConRO:Purgable());

	ConRO:AbilityBurst(_RainofFire, _RainofFire_RDY and _SoulShards >= 3 and _enemies_in_range >= 3);
	ConRO:AbilityBurst(_Havoc, _Havoc_RDY and not _Havoc_DEBUFF and _SoulShards >= 2 and _enemies_in_range >= 2);
	ConRO:AbilityBurst(_SoulFire, _SoulFire_RDY and _SoulShards <= 4 and currentSpell ~= _SoulFire and ConRO:FullMode(_SoulFire));
	ConRO:AbilityBurst(_SummonInfernal, _SummonInfernal_RDY and ConRO:BurstMode(_SummonInfernal));

--Warnings
	ConRO:Warnings("Attack Non-Havoced target!", _Havoc_DEBUFF);
	ConRO:Warnings("Summon your demon!", not tChosen[Ability.GrimoireofSacrifice.talentID] and not _Pet_summoned);
	ConRO:Warnings("Call your pet to sacrifice!", tChosen[Ability.GrimoireofSacrifice.talentID] and not _GrimoireofSacrifice_BUFF and not _Pet_summoned);

	if _GrimoireofSacrifice_RDY and not _GrimoireofSacrifice_BUFF and not _Void_out then
		tinsert(ConRO.SuggestedSpells, _GrimoireofSacrifice);
	end

--Rotations
	if not _in_combat then
		if _SoulFire_RDY and currentSpell ~= _SoulFire and ConRO:FullMode(_SoulFire) then
			tinsert(ConRO.SuggestedSpells, _SoulFire);
		end

		if _Incinerate_RDY and currentSpell ~= _Incinerate and currentSpell ~= _SoulFire then
			tinsert(ConRO.SuggestedSpells, _Incinerate);
		end

		if _Conflagrate_RDY and tChosen[Passive.RoaringBlaze.talentID] and not _Conflagrate_BUFF then
			tinsert(ConRO.SuggestedSpells, _Conflagrate);
		end

		if _Cataclysm_RDY and not _Immolate_DEBUFF and currentSpell ~= _Cataclysm and currentSpell ~= _Immolate and currentSpell ~= _SoulFire then
			tinsert(ConRO.SuggestedSpells, _Cataclysm);
		end

		if _Immolate_RDY and not _Immolate_DEBUFF and currentSpell ~= _Cataclysm and currentSpell ~= _Immolate and currentSpell ~= _SoulFire then
			tinsert(ConRO.SuggestedSpells, _Immolate);
		end

		if _Conflagrate_RDY and _SoulShards <= 4 then
			tinsert(ConRO.SuggestedSpells, _Conflagrate);
		end
	else
		if _Cataclysm_RDY and not _Immolate_DEBUFF and currentSpell ~= _Cataclysm and currentSpell ~= _Immolate then
			tinsert(ConRO.SuggestedSpells, _Cataclysm);
		end

		if _Immolate_RDY and not _Immolate_DEBUFF and currentSpell ~= _Cataclysm and currentSpell ~= _Immolate then
			tinsert(ConRO.SuggestedSpells, _Immolate);
		end

		if _SummonInfernal_RDY and ConRO:FullMode(_SummonInfernal) then
			tinsert(ConRO.SuggestedSpells, _SummonInfernal);
		end

		if _Berserking_RDY and _SummonInfernal_CD <= 170 then
			tinsert(ConRO.SuggestedSpells, _Berserking);
		end

		if _ChaosBolt_RDY and (_SoulShards == 5 or (_SoulShards >= 2 and (_DarkSoulInstability_BUFF or _SummonInfernal_CD >= 150 or _Havoc_CD > 20))) then
			tinsert(ConRO.SuggestedSpells, _ChaosBolt);
		end

		if _Cataclysm_RDY and currentSpell ~= _Cataclysm then
			tinsert(ConRO.SuggestedSpells, _Cataclysm);
		end

		if _SoulFire_RDY and currentSpell ~= _SoulFire and ConRO:FullMode(_SoulFire) then
			tinsert(ConRO.SuggestedSpells, _SoulFire);
		end

		if _ChannelDemonfire_RDY then
			tinsert(ConRO.SuggestedSpells, _ChannelDemonfire);
		end

		if _Conflagrate_RDY and _Conflagrate_CHARGES == 2 or (_Conflagrate_CHARGES >= 1 and ((_SoulShards <= 4 or _BackDraft_COUNT <= 2) or (tChosen[Passive.RoaringBlaze.talentID] and not _Conflagrate_BUFF))) then
			tinsert(ConRO.SuggestedSpells, _Conflagrate);
		end

		if _ChaosBolt_RDY and _SoulShards >= 2 and (_BackDraft_BUFF or (tChosen[Passive.Eradication.talentID] and not _Eradication_DEBUFF)) then
			tinsert(ConRO.SuggestedSpells, _ChaosBolt);
		end

		if _Shadowburn_RDY then
			tinsert(ConRO.SuggestedSpells, _Shadowburn);
		end

		if _Incinerate_RDY then
			tinsert(ConRO.SuggestedSpells, _Incinerate);
		end
	end
return nil;
end

function ConRO.Warlock.DestructionDef(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedDefSpells)
	local Racial, Ability, Passive, Form, Buff, Debuff, PetAbility, PvPTalent, Glyph = ids.Racial, ids.Dest_Ability, ids.Dest_Passive, ids.Dest_Form, ids.Dest_Buff, ids.Dest_Debuff, ids.Dest_PetAbility, ids.Dest_PvPTalent, ids.Glyph;
--Info
	local _Player_Level																					= UnitLevel("player");
	local _Player_Percent_Health 																		= ConRO:PercentHealth('player');
	local _is_PvP																						= ConRO:IsPvP();
	local _in_combat 																					= UnitAffectingCombat('player');
	local _party_size																					= GetNumGroupMembers();

	local _is_PC																						= UnitPlayerControlled("target");
	local _is_Enemy 																					= ConRO:TarHostile();
	local _Target_Health 																				= UnitHealth('target');
	local _Target_Percent_Health 																		= ConRO:PercentHealth('target');

--Resources
	local _Mana, _Mana_Max, _Mana_Percent																= ConRO:PlayerPower('Mana');
	local _SoulShards																					= ConRO:PlayerPower('SoulShards');

--Racials
	local _Cannibalize, _Cannibalize_RDY																= ConRO:AbilityReady(Racial.Cannibalize, timeShift);

--Abilities
	local _CreateHealthstone, _CreateHealthstone_RDY													= ConRO:AbilityReady(Ability.Healthstone.Create, timeShift);
		local _Healthstone, _Healthstone_RDY, _, _, _Healthstone_COUNT										= ConRO:ItemReady(Ability.Healthstone.Use, timeShift);
	local _DrainLife, _DrainLife_RDY																	= ConRO:AbilityReady(Ability.DrainLife, timeShift);
	local _HealthFunnel, _HealthFunnel_RDY					 											= ConRO:AbilityReady(Ability.HealthFunnel, timeShift);
	local _UnendingResolve, _UnendingResolve_RDY 														= ConRO:AbilityReady(Ability.UnendingResolve, timeShift);

	local _DarkPact, _DarkPact_RDY																		= ConRO:AbilityReady(Ability.DarkPact, timeShift);
	local _MortalCoil, _MortalCoil_RDY																	= ConRO:AbilityReady(Ability.MortalCoil, timeShift);

--Conditions
	local _is_moving 																					= ConRO:PlayerSpeed();
	local _enemies_in_melee, _target_in_melee															= ConRO:Targets("Melee");
	local _target_in_10yrds 																			= CheckInteractDistance("target", 3);

	local _Pet_summoned 																				= ConRO:CallPet();
	local _Pet_assist 																					= ConRO:PetAssist();
	local _Pet_Percent_Health																			= ConRO:PercentHealth('pet');
	local _Void_out																						= IsSpellKnown(PetAbility.ThreateningPresence.spellID, true);

--Rotations	
	if _CreateHealthstone_RDY and not _in_combat and _Healthstone_COUNT <= 0 then
		tinsert(ConRO.SuggestedSpells, _CreateHealthstone);
	end

	if _DrainLife_RDY and _Player_Percent_Health <= 60 then
		tinsert(ConRO.SuggestedSpells, _DrainLife);
	end

	if _MortalCoil_RDY and _Player_Percent_Health <= 80 then
		tinsert(ConRO.SuggestedSpells, _MortalCoil);
	end

	if _HealthFunnel_RDY and _Pet_summoned and _Pet_Percent_Health <= 50 then
		tinsert(ConRO.SuggestedSpells, _HealthFunnel);
	end

	if _Healthstone_RDY and _Player_Percent_Health <= 50 then
		tinsert(ConRO.SuggestedSpells, _Healthstone);
	end

	if _DarkPact_RDY then
		tinsert(ConRO.SuggestedSpells, _DarkPact);
	end

	if _UnendingResolve_RDY then
		tinsert(ConRO.SuggestedSpells, _UnendingResolve);
	end
	return nil;
end

ConRO.DemonCount = {};
ConRO.ImpCount = {};
ConRO.BasicDemons = { --[demon] = duration (0 to blacklist)
							[688] = 0,     --Imp
							[697] = 0,     --Voidwalker
							[691] = 0,     --Felhunter
							[712] = 0,     --Succubus
							[30146] = 0,   --Felguard
							[112866] = 0,  --Fel Imp
							[112867] = 0,  --Voidlord
							[112869] = 0,  --Observer
							[112868] = 0,  --Shivarra
							[112870] = 0,  --Wrathguard
							[240263] = 0,  --Fel Succubus
							[240266] = 0,  --Shadow Succubus
							[104317] = 0,  --Wild Imps, counted by other means
							[111898] = 15, --Grimoire: Felguard
							[193331] = 12, --Dreadstalker 1
							[193332] = 12, --Dreadstalker 2
							[265187] = 15, --Demonic Tyrant
							[264119] = 15  --Vilefiend
						};

function ConRO:COMBAT_LOG_EVENT_UNFILTERED()
	local _, subevent, _, sourceGUID, _, _, _, destGUID, destName, _, _, spellID = CombatLogGetCurrentEventInfo();
	local myGUID = UnitGUID("player");

	local ImpMaxCasts = 5;
	local ImpMaxTime = 20; --seconds
	local randomDemonsDuration = 15; --seconds
	local TyrantDuration = 15; --seconds
	local TyrantStart = 0;
	local TyrantActive = false;


		--Imps are summoned
		if subevent == "SPELL_SUMMON" and sourceGUID == myGUID and (spellID == 104317 or spellID == 279910) then

			local tyrantExtra = TyrantActive and TyrantDuration - (GetTime() - TyrantStart) or 0

			ConRO.ImpCount[destGUID] = {ImpMaxCasts, GetTime() + ImpMaxTime + tyrantExtra - 0.1}
			C_Timer.After(ImpMaxTime + tyrantExtra, function()

					for k in pairs(ConRO.ImpCount) do
						if GetTime() > ConRO.ImpCount[k][2] then
							ConRO.ImpCount[k] = nil
						end
					end
			end)

			--Other demons are summoned
		elseif subevent == "SPELL_SUMMON" and sourceGUID == myGUID and not (spellID == 104317 or spellID == 279910) then

			if ConRO.BasicDemons[spellID] and ConRO.BasicDemons[spellID] > 0 then
				ConRO.DemonCount[destGUID] = GetTime() + ConRO.BasicDemons[spellID] - 0.1

				C_Timer.After(ConRO.BasicDemons[spellID], function()
						for k, v in pairs(ConRO.DemonCount) do
							if GetTime() > v then
								ConRO.DemonCount[k] = nil
							end
						end
				end)

			elseif not ConRO.BasicDemons[spellID] then
				ConRO.DemonCount[destGUID] = GetTime() + randomDemonsDuration - 0.1

				C_Timer.After(randomDemonsDuration, function()
						for k, v in pairs(ConRO.DemonCount) do
							if GetTime() > v then
								ConRO.DemonCount[k] = nil
							end
						end
				end)
			end
		end

		--Imps succesfully consume energy
		if subevent == "SPELL_CAST_SUCCESS" and ConRO.ImpCount[sourceGUID] and not TyrantActive then
			if ConRO.ImpCount[sourceGUID][1] == 1 then
				ConRO.ImpCount[sourceGUID] = nil
			else
				ConRO.ImpCount[sourceGUID][1] = ConRO.ImpCount[sourceGUID][1] - 1
			end
		end

		--Summon Demonic Tyrant
		if subevent == "SPELL_CAST_SUCCESS" and sourceGUID == myGUID and spellID == 265187 then
			local remains

			TyrantActive = true
			TyrantStart = GetTime()

			if IsPlayerSpell(267215) then
				wipe(ConRO.ImpCount)
			end

			C_Timer.After(TyrantDuration, function()
					TyrantActive = false

					for k in pairs(ConRO.ImpCount) do
						if GetTime() > ConRO.ImpCount[k][2] then
							ConRO.ImpCount[k] = nil
						end
					end

					for k, v in pairs(ConRO.DemonCount) do
						if GetTime() > v then
							ConRO.DemonCount[k] = nil
						end
					end
			end)

			for k in pairs(ConRO.ImpCount) do
				remains = ConRO.ImpCount[k][2] - GetTime()
				ConRO.ImpCount[k][2] = ConRO.ImpCount[k][2] + TyrantDuration - 0.1

				C_Timer.After(TyrantDuration + remains, function()
						for k in pairs(ConRO.ImpCount) do
							if GetTime() > ConRO.ImpCount[k][2] then
								ConRO.ImpCount[k] = nil
							end
						end
				end)
			end

			for k in pairs(ConRO.DemonCount) do
				remains = ConRO.DemonCount[k] - GetTime()
				ConRO.DemonCount[k] = ConRO.DemonCount[k] + TyrantDuration - 0.1

				C_Timer.After(TyrantDuration + remains, function()
						for k, v in pairs(ConRO.DemonCount) do
							if GetTime() > v then
								ConRO.DemonCount[k] = nil
							end
						end
				end)
			end
		end

		--Implosion
		if subevent == "SPELL_CAST_SUCCESS" and sourceGUID == myGUID and spellID == 196277 then
			wipe(ConRO.ImpCount)
		end

		--Power Siphon
		if subevent == "SPELL_CAST_SUCCESS" and sourceGUID == myGUID and spellID == 264130 then
			local oldest, oldestTime = "", 2*GetTime()

			for i = 1, 2 do
				for name, imp in pairs(ConRO.ImpCount) do
					oldestTime = math.min(imp[2], oldestTime)

					if imp[2] == oldestTime then
						oldest = name
					end
				end

				oldestTime = oldestTime*2

				ConRO.ImpCount[oldest] = nil
			end
		end

		--Death
		if subevent == "UNIT_DIED" or subevent == "SPELL_INSTAKILL" or subevent == "UNIT_DESTROYED" then
			if ConRO.ImpCount[destGUID] then
				ConRO.ImpCount[destGUID] = nil

			elseif ConRO.DemonCount[destGUID] then
				ConRO.DemonCount[destGUID] = nil

			elseif destGUID == myGUID then
				wipe(ConRO.ImpCount)
				wipe(ConRO.DemonCount)
			end
		end
	return true;
end

function ConRO:ImpsOut()
  local count = 0
	for k in pairs(ConRO.ImpCount) do
		if k then
			count = count + 1;
		end
	end
--	print("Imp Count: " .. count);
	return count;
end

function ConRO:DemonsOut()
  local count = ConRO:ImpsOut();
	if IsPetActive() then
		count = count + 1;
	end
	for k in pairs(ConRO.DemonCount) do
		if k then
			count = count + 1;
		end
	end
--	print("Demon Count: " .. count);
	return count;
end