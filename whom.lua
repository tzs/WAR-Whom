whom = {}

-- This is ugly code. I wanted this add-on, so just kind of started hacking, without
-- actually learning Lua. I am quite hazy on things like how to do data structures
-- in Lua. No need to suggest the dozens of obvious ways this code be made
-- non-braindead. I already know them--just haven't learned how to do them
-- in Lua yet! If only Mythic had picked Perl for their interface language...

function whom.initialize()
    whom.registered = false
    whom.reset()
    whom.mode = 1
    whom.careers = {
        -- Tank
        L"Ironbreaker", L"Swordmaster", L"Knight of the Blazing Sun",
        -- MDPS
        L"Slayer", L"Witch Hunter", L"White Lion",
        -- RDPS
        L"Engineer", L"Bright Wizard", L"Shadow Warrior",
        -- Healer
        L"Warrior Priest", L"Archmage", L"Runepriest",
        -- Tank
        L"Black Orc", L"Chosen", L"Blackguard",
        -- MDPS
        L"Witch Elf", L"Choppa", L"Marauder",
        -- RDPS
        L"Squig Herder", L"Magus", L"Sorcerer",
        -- Healer
        L"Shaman", L"Zealot", L"Disciple of Khaine",
        -- Female Sorcerer (player is, of course, actually male)
        L"Sorceress"
    }
    LibSlash.RegisterWSlashCmd("whom", function(args) whom.onSlashCmd(args) end)
    whom.p("Whom available. Type /whom for population report")
end

function whom.reset()
    whom.running = false
    whom.finishing = false
    whom.tcount = { {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}}
    whom.tdetails = { {}, {}, {}, {}, {} }
    whom.zones = {}
    whom.count = 0
    whom.overflow = {}
    whom.details = false
    whom.head = nil
    whom.tail = nil
    whom.advisor = false
    whom.players = {}
    whom.sort_order = {}
    whom.who_no_stats = false
    whom.locations_no_stats = false
    whom.probe_count = 0
end

function whom.onSlashCmd(args)
    local wasrunning = whom.running
    whom.reset()
    if ( wasrunning == true ) then
        whom.p("whom: stopped")
        return
    end
    
    local guilds = {}
    local zones = {}
    local ranges = {}
    local want40 = false
    local did_t1 = false
    local did_t2 = false
    local did_t3 = false
    local did_t4 = false
    local want_sc = false
    
    -- letters still available for options:
    -- b e f h i j k m n o p q s t u v x y
    for i, arg in ipairs(whom.words(WStringToString(args))) do
        if ( arg == "-d" ) then
            whom.details = true
        elseif ( arg == "-l" ) then
            whom.locations_no_stats = true
        elseif ( arg == "-w" ) then
            whom.who_no_stats = true
        elseif ( arg == "-r" ) then
            table.insert(whom.sort_order, 1)
        elseif ( arg == "-c" ) then
            table.insert(whom.sort_order, 2)
        elseif ( arg == "-g" ) then
            table.insert(whom.sort_order, 3)
        elseif ( arg == "-z" ) then
            table.insert(whom.sort_order, 4)
        elseif ( arg == "-a" ) then
            table.insert(whom.sort_order, 5)
        elseif ( arg == "t1" and did_t1 == false ) then
            table.insert(ranges, {1,11})
            did_t1 = true
        elseif ( arg == "t2" and did_t2 == false ) then
            table.insert(ranges, {12,21})
            did_t2 = true
        elseif ( arg == "t3" and did_t3 == false ) then
            table.insert(ranges, {22,31})
            did_t3 = true
        elseif ( arg == "t4" and did_t4 == false ) then
            table.insert(ranges, {32,40});
            did_t4 = true
        elseif ( arg == "40" ) then
            want40 = true
        elseif ( arg == "here" ) then
            zones = {GameData.Player.zone}
        elseif ( arg == "sc" ) then
            want_sc = true
            zones = {}
            for i, data in ipairs (GameData.ScenarioQueueData) do
                if ( data.id ~= 0 ) then
                    table.insert(zones, data.zone)
                end
            end
            if ( zones[1] == nil ) then
                whom.p("No scenarios are available to you at this time and location.")
                return
            end
        elseif ( arg == "alliance" ) then
            guilds = {}
            for u, guild in ipairs( GetAllianceMemberData() ) do
                table.insert(guilds, guild.name)
            end
            if ( guilds[1] == nil ) then
                whom.p("You don't seem to be in an alliance.")
                return
            end
        elseif ( arg == "guild" ) then
            guilds = {GameData.Guild.m_GuildName}
            if ( guilds[1] == L"" ) then
                whom.p("You don't seem to be in a guild.")
                return
            end
        elseif ( arg == "advisor" ) then
            whom.advisor = true
        elseif ( arg == "trinity" ) then
            guilds = {L"gaiscioch", L"gaiscioch na nuada", L"gaiscioch na anu"}
        elseif ( arg == "help" ) then
            whom.p("Usage: /whom [options]")
            whom.p("  If you give no options, default is to list all visible players")
            whom.p("  If you specify one or more of the five following options, then")
            whom.p("    only people of the given ranks will be included:")
            whom.p("     t1     show ranks 1-11")
            whom.p("     t2     show ranks 12-21")
            whom.p("     t3     show ranks 22-31")
            whom.p("     t4     show ranks 32-40")
            whom.p("     40     show rank 40")
            whom.p("  You can limit the search to your guild or your alliance with one of:")
            whom.p("     guild")
            whom.p("     alliance")
            whom.p("  You can limit the search to your current zone with:")
            whom.p("     here")
            whom.p("  You can limit the search to the scenarios currently available to you with:")
            whom.p("     sc")
            whom.p("  You can limit the seach to people flagged as advisors with:")
            whom.p("     advisor")
            whom.p("  You can ask for a detailed class breakdown by tier with:")
            whom.p("     -d")
            whom.p("  NOTE: in prior releases of /whom, this was -c.")
            whom.p("  You can specify the sort order of the player list with:")
            whom.p("     -c    sort by career")
            whom.p("     -a    sort by archetype")
            whom.p("     -r    sort by rank")
            whom.p("     -z    sort by zone")
            whom.p("     -g    sort by guild")
            whom.p("  If you do not specify a sort option, players are sorted by name")
            whom.p("  If you specify one or more sort options, they are applied in")
            whom.p("    in order. For instance, -c -r would sort by career, and then")
            whom.p("    sort by rank within each career group, and then finally by")
            whom.p("    name when more than one person has the same career/rank")
            whom.p("  Here is an example:")
            whom.p("    /whom -g -a alliance sc 40")
            whom.p("  That would show you rank 40 people in your allliance who are")
            whom.p("    currently in a scenario available to you, sorted by guild")
            whom.p("    and archetype.")
            whom.p("  By default, whom prints a player list, a locations list, and")
            whom.p("    statstics on archetypes and tiers. This can be changed:")
            whom.p("      -w        (without -l) just show player list")
            whom.p("      -l        (without -w) just show locations list")
            whom.p("      -w -l     just show players list and locations list")
            return
        else
            whom.p("whom: unrecognized option: ", arg)
            whom.p("For help, try: /whom help")
            return
        end
    end
    
    --table.insert(whom.sort_order, 1)
    
    if ( guilds[1] == nil ) then
        guilds = {L""}
    end
    
    if ( zones[1] == nil ) then
        zones = {-1}
    end
    
    if ( want40 == true  and did_t4 == false ) then
        table.insert(ranges, {40, 40})
    end
    if ( ranges[1] == nil) then
        if ( want_sc == true ) then
            local level = GameData.Player.level
            if ( level < 12 ) then ranges = {{1,11}}
            elseif ( level < 22 ) then ranges = {{12,21}}
            elseif ( level < 32 ) then ranges = {{22,31}}
            else ranges = {{32,40}} end
        else
            ranges = {{1,40}}
        end
    end
    
    for i, g in ipairs (guilds) do
        for j, r in ipairs (ranges)
        do
            if ( zones[1] == -1 and whom.mode == 1 )
            then
                local t1, t2 = whom.splitList( GetZoneIDList() )
                whom.queueSearch( g, L"", t1, r[1], r[2])
                whom.queueSearch( g, L"", t2, r[1], r[2])
            else
                whom.queueSearch( g, L"", zones, r[1], r[2])
            end
        end
    end

    if ( whom.registered == false ) then
        RegisterEventHandler( SystemData.Events.SOCIAL_SEARCH_UPDATED, "whom.onSearchUpdated" )
        whom.registered = true
    end
    
    whom.running = true
    whom.dp("/whom beginning search")
    whom.search()
end

function whom.search()
    whom.item = whom.head
    if ( whom.item ~= nil ) then
        whom.head = whom.item.next
        -- player name, guild name, career name, zone ID array, low rank, high rank, advisor-only flag
        -- names are L"" for wildcard, zone ID array of {-1} for all zones
        
        SendPlayerSearchRequest( L"", whom.item.guild, whom.item.career, whom.item.zone, whom.item.low, whom.item.high, whom.advisor )
    end
end

function whom.queueSearch(guild, career, zone, low, high)
    local item = {}
    item.next = nil
    item.guild = guild
    item.career = career
    item.zone = zone
    item.low = low
    item.high = high
    if ( whom.head == nil ) then
        whom.head = item
    else
        whom.tail.next = item
    end
    whom.tail = item
end


function whom.queueCareerSearch( guild, zones, low, high)
    local offset = 0
    if ( GameData.Player.realm == GameData.Realm.DESTRUCTION ) then
        offset = 12
    end
    for i = 1, 12 do
        whom.queueSearch( guild, whom.careers[i+offset], zones, low, high )
    end
end   

function whom.record_overflow()
    local level = L"" .. whom.item.low
    if ( whom.item.low ~= whom.item.high ) then
        level = whom.item.low .. L"-" .. whom.item.high
    end
    table.insert(whom.overflow, L"*** Too many to count, only first 30 counted of level " .. level
                                .. L" " .. whom.item.career
                                .. L" in " .. GetZoneName(whom.item.zone[1]) )
end

function whom.tally(data)
    for key, value in ipairs( data ) do
        if ( whom.players[value.name] ~= nil ) then return end
        
        whom.count = whom.count + 1

        local tier = whom.rankToTier( value.rank )
        local classIndex = whom.careerNameToClassIndex( value.career )
        local archtypeIndex = whom.classIndexToArchtypeIndex( classIndex )

        local zone = L"Unknown location"
        if ( value.zoneID ~= 0) then
            zone = GetZoneName( value.zoneID )
        end

        whom.players[value.name] = {value.rank, value.career, value.guildName, zone, archtypeIndex}

        whom.tcount[tier][archtypeIndex] = whom.tcount[tier][archtypeIndex] + 1
        whom.tcount[tier][5] = whom.tcount[tier][5] + 1        
    
        if ( whom.zones[value.zoneID] == nil ) then
            whom.zones[value.zoneID] = {0,0,0,0,0,0,0,0,0,0}
        end
        whom.zones[value.zoneID][archtypeIndex] = whom.zones[value.zoneID][archtypeIndex] + 1
        whom.zones[value.zoneID][5] = whom.zones[value.zoneID][5] + 1
        whom.zones[value.zoneID][5+tier] = whom.zones[value.zoneID][5+tier] + 1
    
        if ( whom.tdetails[tier][classIndex] == nil ) then
            whom.tdetails[tier][classIndex] = 0
        end
        whom.tdetails[tier][classIndex] = whom.tdetails[tier][classIndex] + 1

    end
end

function whom.onSearchUpdated()
    if ( whom.running == false )
    then
        return
    end
    if ( whom.finishing == true )
    then
        whom.running = false
        whom.finishing = false
        whom.displayResults()
        whom.reset()
    else
        whom.probe_count = whom.probe_count + 1
        local data = GetSearchList()
        if ( data ~= nil and whom.finishing == false )
        then
            local zone_count = #whom.item.zone
            if ( zone_count == 1 and whom.item.zone[1] == -1 ) then zone_count = "all" end
            local advisor_only = "false"
            if ( whom.advisor ) then advisor_only = "true" end
            local count = #data
            if ( count >= 30 ) then count = "overflow" end
            whom.dp("got ", count, " guild=", whom.item.guild, " career=", whom.item.career, " #zones=", zone_count, " ranks [",
                whom.item.low, ",", whom.item.high, "] advisor_only=", advisor_only)

            if ( #data < 30 ) then
                -- whom.p(#data," found for [",whom.item.career,"], ranks ",whom.item.low,"-",whom.item.high,". zone list:",#whom.item.zone," zones starting with ",GetZoneName(whom.item.zone[1]))
                whom.tally(data)
            else
                -- whom.p("Overflow for [",whom.item.career,"], ranks ",whom.item.low,"-",whom.item.high,". zone list:",#whom.item.zone," zones starting with ",GetZoneName(whom.item.zone[1]))
                if ( whom.item.career == L"" )
                then
                    whom.queueCareerSearch( whom.item.guild, whom.item.zone, whom.item.low, whom.item.high )
                elseif ( whom.item.low ~= whom.item.high )
                then
                    local mid = math.floor((whom.item.low + whom.item.high) / 2)
                    whom.queueSearch( whom.item.guild, whom.item.career, whom.item.zone, whom.item.low, mid )
                    whom.queueSearch( whom.item.guild, whom.item.career, whom.item.zone, mid+1, whom.item.high )
                elseif ( whom.item.zone[1] == -1 )
                then
                    local t1, t2 = whom.splitList( GetZoneIDList() )
                    whom.queueSearch( whom.item.guild, whom.item.career, t1, whom.item.low, whom.item.high )
                    whom.queueSearch( whom.item.guild, whom.item.career, t2, whom.item.low, whom.item.high )
                elseif ( #whom.item.zone > 1 )
                then
                    local t1, t2 = whom.splitList( whom.item.zone );
                    whom.queueSearch( whom.item.guild, whom.item.career, t1, whom.item.low, whom.item.high )
                    whom.queueSearch( whom.item.guild, whom.item.career, t2, whom.item.low, whom.item.high )
                else
                    whom.record_overflow()
                    whom.tally(data)
                end
            end
        end
        if (whom.head ~= nil ) then
            whom.search()
        else
            whom.finishing = true
            local career = whom.careers[13]
            if ( GameData.Player.realm == GameData.Realm.DESTRUCTION ) then
                career = whom.careers[1]
            end
            whom.queueSearch( L"", career, {-1}, 1, 1 )
            whom.search()
        end
    end
end


--whom.players[value.name] = {value.rank, value.career, value.guildName, zone, archtypeIndex}

function whom.displayResults()
    local show_stats = true;
    local show_who = true;
    local show_locations = true;
    
    if ( whom.who_no_stats == true or whom.locations_no_stats == true ) then
        show_stats = false
        show_who = false
        show_locations = false
    end
    if ( whom.who_no_stats == true ) then
        show_who = true
    end
    if ( whom.locations_no_stats == true )then
        show_locations = true
    end
    
    if ( show_who == true ) then
        local names = whom.keys(whom.players)
        table.sort( names, function(a,b)
                for i, f in ipairs(whom.sort_order) do
                    if ( whom.players[a][f] < whom.players[b][f] ) then return true
                    elseif ( whom.players[a][f] > whom.players[b][f] ) then return false end
                end
                return a < b
            end)
        for i, name in ipairs (names) do
            local data = whom.players[name]
            local player_link = CreateHyperLink(L"PLAYER:"..name, name, {0,255,0}, {})
            local career_link = CreateHyperLink(L"", data[2], {128,128,255}, {})
            local zone_link = CreateHyperLink(L"", data[4], {255,255,0}, {})
            if ( data[3] ~= L"" ) then
                local guild_link = CreateHyperLink(L"", data[3], {0,255,255}, {})
                player_link = player_link .. L" (" .. guild_link .. L")"
            end
            whom.p(i, ": ", player_link, ", ", data[1], " ", career_link, " in ", zone_link)
        end
    end

    if ( show_locations == true ) then
        local zones = whom.keys(whom.zones)
        table.sort(zones, function(a,b) return whom.zones[a][5] < whom.zones[b][5] end)
        for i, zid in ipairs(zones) do
            local name = GetZoneName(zid)
            local out = L"  "..whom.zones[zid][5]..L" in "..name..L".  "
            local more = whom.zones[zid][5]
            local label = {L"tank", L"mdps", L"rdps", L"healer"}
            for i = 1, 4 do
               if ( whom.zones[zid][i] > 0 ) then
                    out = out .. L" " .. whom.zones[zid][i] .. L" " .. label[i]
                    more = more - whom.zones[zid][i]
                    if ( more > 0 ) then out = out .. L"," end
                end 
            end
            out = out .. L" / "
            label = {L"T1", L"T2", L"T3", L"T4", L"R40"}
            more = whom.zones[zid][5]
            for i = 5, 1, -1 do
               if ( whom.zones[zid][5+i] > 0 ) then
                   out = out .. L" " .. whom.zones[zid][5+i] .. L" " .. label[i]
                   more = more - whom.zones[zid][5+i] 
                   if ( more > 0 ) then out = out .. L"," end
               end 
            end
            whom.p(out)
        end
    end

    if ( show_stats == true ) then
        whom.p("**** Total players found: ", whom.count, " ****")

        for tier = 1, 5 do
            local tname = "Tier "..tier
            if ( tier == 5 ) then tname = "R40" end
            whom.p( tname, ": ",
                    whom.tcount[tier][5], " players. ",
                    whom.tcount[tier][1], " tank, ",
                    whom.tcount[tier][2], " mdps, ",
                    whom.tcount[tier][3], " rdps, ",
                    whom.tcount[tier][4], " healer")
            if ( whom.details ) then
                local tierdata = whom.tdetails[tier]
                local classes = whom.keys(tierdata)
                table.sort(classes)
                for i, classIndex in pairs(classes) do
                    local count = tierdata[classIndex]
                    whom.p("  ", count, " ", whom.careers[classIndex])
                end
            end
        end
    end
    
    for i, m in pairs(whom.overflow) do
        whom.p(m)
    end
    whom.dp("probe count = ", whom.probe_count)
end

function whom.p(...)
    local out = L""
    for i, part in ipairs(arg) do
        if ( type(part) == "wstring" ) then
            out = out .. part
        else
            out = out .. towstring(""..part)
        end
    end
    EA_ChatWindow.Print(out, ChatSettings.Channels[SystemData.ChatLogFilters.SAY].id)
end

function whom.dp(...)
    local out = L""
    for i, part in ipairs(arg) do
        if ( type(part) == "wstring" ) then
            out = out .. part
        else
            out = out .. towstring(""..part)
        end
    end
    d(out)
end
    
function whom.keys(t)
    local k = {}
    for key, value in pairs(t) do
        table.insert(k, key)
    end
    return k
end

function whom.splitList(t)
    local t1 = {}
    local t2 = {}
    local s = 0
    for i, v in ipairs(t) do
        if ( s == 0 ) then table.insert(t1, v)
        else                table.insert(t2,v)
        end
        s = 1 - s
    end
    return t1, t2
end

function whom.rankToTier(rank)
    if ( rank == 40 ) then      return 5
    elseif ( rank >= 32 ) then  return 4
    elseif ( rank >= 22 ) then  return 3
    elseif ( rank >= 12 ) then  return 2 
    else return 1 end
end

function whom.careerNameToClassIndex(career)
    local classindex = 0
    for i = 1, 25 do
        if ( WStringsCompareIgnoreGrammer(career, whom.careers[i]) == 0 ) then
            classindex = i
            break
        end
    end
    if ( classindex == 25 ) then classindex = 21 end
    return classindex
end

function whom.classIndexToArchtypeIndex(classindex)
    if ( classindex > 12 ) then classindex = classindex - 12 end
    if ( classindex <= 3 ) then
        return 1
    elseif ( classindex <= 6 ) then
        return 2
    elseif ( classindex <= 9 ) then
        return 3
    else
        return 4
    end
end

function whom.words(str)
  local t = {}
  local function helper(word) table.insert(t, word) return "" end
  if not str:gsub("[^%s]+", helper):find"%S" then return t end
end

