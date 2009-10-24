whom = {}

-- This is ugly code. I wanted this add-on, so just kind of started hacking, without
-- actually learning Lua. I am quite hazy on things like how to do data structures
-- in Lua. No need to suggest the dozens of obvious ways this code be made
-- non-braindead. I already know them--just haven't learned how to do them
-- in Lua yet! If only Mythic had picked Perl for their interface language...

function whom.Initialize()
    EA_ChatWindow.Print(towstring("Whom available. Type /whom for population report"))
    LibSlash.RegisterWSlashCmd("whom", function(args) whom.OnSlash(args) end)
    whom.queue = {}
    whom.writepos = 0
    whom.readpos = 1
    whom.careers = {
        -- Tank
        L"Ironbreaker", L"Swordmaster", L"Knight of the Blazing Sun",
        -- MDPS
        L"Slayer", L"Witch Hunter", L"White Lion",
        -- RDPS
        L"Engineer", L"Bright Wizard", L"Shadow Warrior",
        -- Healer
        L"Warrior Priest", L"Archmage", L"Rune Priest",
        -- Tank
        L"Black Orc", L"Chosen", L"Blackguard",
        -- MDPS
        L"Witch Elf", L"Choppa", L"Marauder",
        -- RDPS
        L"Squig Herder", L"Magus", L"Sorcerer",
        -- Healer
        L"Shaman", L"Zealot", L"Disciple of Khaine",
        -- Female Sorcerer (player is, of course, actually malewhom)
        L"Sorceress"
    }
end

function whom.Search()
    local zone = {}
    zone[1] = whom.queue[whom.readpos+1]
    SendPlayerSearchRequest( L"",
                             L"",
                             whom.queue[whom.readpos],
                             zone,
                             whom.queue[whom.readpos+2],
                             whom.queue[whom.readpos+2],
                             false )
end

function whom.AddItem(career, zone, level)
    whom.queue[whom.writepos+1] = career
    whom.queue[whom.writepos+2] = zone
    whom.queue[whom.writepos+3] = level
    whom.writepos = whom.writepos + 3
end

function whom.OnSlash(args)
    EA_ChatWindow.Print(L"Checking for players...this will take a while")
    whom.details = false
    if ( args == L"-v" ) then whom.details = true end
    whom.running = true
    whom.zones = {}
    whom.count = 0
    whom.countT1 = 0
    whom.countT2 = 0
    whom.countT3 = 0
    whom.countT4 = 0
    whom.count40 = 0
    whom.overflow = 0
    whom.classesT1 = {}
    whom.classesT2 = {}
    whom.classesT3 = {}
    whom.classesT4 = {}
    whom.classes40 = {}
    whom.tanks = {0,0,0,0,0}
    whom.rdps = {0,0,0,0,0}
    whom.mdps = {0,0,0,0,0}
    whom.healers = {0,0,0,0,0}
    whom.all = {0,0,0,0,0}
    for level = 1, 40 do
        whom.AddItem( L"", -1, level)
    end
    RegisterEventHandler( SystemData.Events.SOCIAL_SEARCH_UPDATED, "whom.OnSearch" )
    whom.Search()
end

function whom.CountClass(counter, career, rank)
    local classindex = 0
    for i = 1, 25 do
        if ( WStringsCompareIgnoreGrammer(career, whom.careers[i]) == 0 ) then
            classindex = i
            break
        end
    end
    if ( classindex == 25 ) then classindex = 21 end
    if ( classindex == 0 ) then
        EA_ChatWindow.Print(L"whom: ERROR: class "..career..L" not found in career table")
        return
    end
    if ( counter[classindex] == nul ) then
        counter[classindex] = 0
    end
    counter[classindex] = counter[classindex] + 1
    if ( rank == 40 ) then
        whom.count40 = whom.count40 + 1
        if ( whom.classes40[classindex] == nul ) then
            whom.classes40[classindex] = 0
        end
        whom.classes40[classindex] = whom.classes40[classindex] + 1
    end
    local tier = 1
    if ( rank >= 12 ) then tier = 2 end
    if ( rank >= 22 ) then tier = 3 end
    if ( rank >= 32 ) then tier = 4 end
    if ( classindex > 12 ) then classindex = classindex - 12 end
    whom.all[tier] = whom.all[tier] + 1
    if ( rank == 40 ) then whom.all[5] = whom.all[5] + 1 end
    if ( classindex <= 3 ) then
        whom.tanks[tier] = whom.tanks[tier] + 1
        if ( rank == 40 ) then whom.tanks[5] = whom.tanks[5] + 1 end
    elseif ( classindex <= 6 ) then
        whom.mdps[tier] = whom.mdps[tier] + 1
        if ( rank == 40 ) then whom.mdps[5] = whom.mdps[5] + 1 end
    elseif ( classindex <= 9 ) then
        whom.rdps[tier] = whom.rdps[tier] + 1
        if ( rank == 40 ) then whom.rdps[5] = whom.rdps[5] + 1 end
    else
        whom.healers[tier] = whom.healers[tier] + 1
        if ( rank == 40 ) then whom.healers[5] = whom.healers[5] + 1 end
    end
end

function whom.ShowCount(counter, name, total)
    EA_ChatWindow.Print(towstring("**** " .. name .. " players: " .. total .. " ****"))
    for key, value in pairs( counter ) do
        EA_ChatWindow.Print(towstring("   " .. value .. " ")..whom.careers[key])
    end
end

function whom.Tally(data)
    for key, value in ipairs( data ) do
        whom.count = whom.count + 1
        if ( whom.zones[value.zoneID] == nil ) then
            whom.zones[value.zoneID] = 0
        end
        whom.zones[value.zoneID] = whom.zones[value.zoneID] + 1
        if ( value.rank <= 11 ) then
            whom.countT1 = whom.countT1 + 1
            whom.CountClass( whom.classesT1, value.career, value.rank )
        elseif ( value.rank <= 21 ) then
            whom.countT2 = whom.countT2 + 1
            whom.CountClass( whom.classesT2, value.career, value.rank )
        elseif ( value.rank <= 31 ) then
            whom.countT3 = whom.countT3 + 1
            whom.CountClass( whom.classesT3, value.career, value.rank )
        else
            whom.countT4 = whom.countT4 + 1
            whom.CountClass( whom.classesT4, value.career, value.rank )
        end
    end
end

function whom.OnSearch()
    if ( whom.running == false ) then return end
    local data = GetSearchList()
    if ( data ~= nil )
    then
        if ( #data < 30 ) then
            whom.Tally(data)
        else
            if ( whom.queue[whom.readpos] == L"" )
            then
                local offset = 0
                if ( GameData.Player.realm == GameData.Realm.DESTRUCTION ) then
                    offset = 12
                end
                for i = 1, 12 do
                    whom.AddItem( whom.careers[i+offset], whom.queue[whom.readpos+1], whom.queue[whom.readpos+2] )
                end
            else
                whom.overflow = whom.overflow + 1
                whom.Tally(data)
            end
        end
    end
    whom.readpos = whom.readpos + 3
    if ( whom.writepos > whom.readpos ) then
        whom.Search()
    else
        whom.running = false
        if ( whom.details == true ) then
            whom.ShowCount( whom.classesT1, "Tier 1", whom.countT1)
            whom.ShowCount( whom.classesT2, "Tier 2", whom.countT2)
            whom.ShowCount( whom.classesT3, "Tier 3", whom.countT3)
            whom.ShowCount( whom.classesT4, "Tier 4", whom.countT4)
            whom.ShowCount( whom.classes40, "R40", whom.count40)
        end
        local zt = {}
        for zid, count in pairs(whom.zones) do
           table.insert(zt,zid) 
        end
        table.sort(zt, function(a,b) return whom.zones[a] < whom.zones[b] end)
        for i, zid in ipairs(zt) do
            local name = GetZoneName(zid)
            local count = whom.zones[zid]
            EA_ChatWindow.Print(towstring("  "..count)..L" players in "..name)
        end
        EA_ChatWindow.Print(towstring("**** Total players found: "..whom.count.. " ****"))
        if ( whom.overflow > 0 ) then
            EA_ChatWindow.Print(L"whom: WARNING some level/class combinations were skipped due to overflow! Count is not accurate!")
        end
        for i = 1, 5 do
            local tname = "Tier "..i
            if ( i == 5) then tname = "R40" end
            EA_ChatWindow.Print(towstring(  tname .. ", "
                                            .. whom.all[i] .. " players: "
                                            .. whom.tanks[i] .. " tank, "
                                            .. whom.mdps[i] .. " melee, "
                                            .. whom.rdps[i] .. " ranged, "
                                            .. whom.healers[i] .. " healer"))
        end
    end
end
