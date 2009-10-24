whom = {}

-- This is ugly code. I wanted this add-on, so just kind of started hacking, without
-- actually learning Lua. I am quite hazy on things like how to do data structures
-- in Lua. No need to suggest the dozens of obvious ways this code be made
-- non-braindead. I already know them--just haven't learned how to do them
-- in Lua yet! If only Mythic had picked Perl for their interface language...

function whom.Initialize()
    EA_ChatWindow.Print(towstring("Whom available. Type /whom for population report"))
    LibSlash.RegisterWSlashCmd("whom", function(args) whom.OnSlash(args) end)
    whom.head = nil
    whom.tail = nil
    whom.registered = false
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
        -- Female Sorcerer (player is, of course, actually male)
        L"Sorceress"
    }
end

function whom.Search()
    whom.item = whom.nextItem()
    if ( whom.item ~= nil ) then
        local zone = {}
        zone[1] = whom.item.zone
        SendPlayerSearchRequest( L"", L"", whom.item.career, zone, whom.item.level, whom.item.level, false )
    end
end

function whom.AddItem(career, zone, level)
   local item = {}
   item.next = nil
   item.career = career
   item.zone = zone
   item.level = level
   if ( whom.head == nil ) then
       whom.head = item
       whom.tail = item
   else
       whom.tail.next = item
       whom.tail = item
   end
end

function whom.nextItem()
    local item = whom.head
    if ( whom.head ~= nil ) then
        whom.head = whom.head.next 
    end
    return item
end

function whom.OnSlash(args)
    EA_ChatWindow.Print(L"Checking for players...this will take a while")
    whom.details = false
    if ( args == L"-v" ) then whom.details = true end
    whom.running = true
    whom.tcount = { {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}}
    whom.tdetails = { {}, {}, {}, {}, {} }
    whom.zones = {}
    whom.count = 0
    whom.overflow = 0
    for level = 1, 40 do
        whom.AddItem( L"", -1, level)
    end
    if ( whom.registered == false ) then
        RegisterEventHandler( SystemData.Events.SOCIAL_SEARCH_UPDATED, "whom.OnSearch" )
        whom.registered = true
    end
    whom.Search()
end

function whom.Tally(data)
    for key, value in ipairs( data ) do
        whom.count = whom.count + 1
        
        local tier = whom.rankToTier( value.rank )
        local classIndex = whom.careerNameToClassIndex( value.career )
        local archtypeIndex = whom.classIndexToArchtypeIndex( classIndex )
        whom.tcount[tier][archtypeIndex] = whom.tcount[tier][archtypeIndex] + 1
        whom.tcount[tier][5] = whom.tcount[tier][5] + 1        
        if ( tier == 5 ) then
            whom.tcount[4][archtypeIndex] = whom.tcount[4][archtypeIndex] + 1
            whom.tcount[4][5] = whom.tcount[4][5] + 1
        end
        
        if ( whom.zones[value.zoneID] == nil ) then
            whom.zones[value.zoneID] = {0,0,0,0,0,0,0,0,0,0}
        end
        whom.zones[value.zoneID][archtypeIndex] = whom.zones[value.zoneID][archtypeIndex] + 1
        whom.zones[value.zoneID][5] = whom.zones[value.zoneID][5] + 1
        whom.zones[value.zoneID][5+tier] = whom.zones[value.zoneID][5+tier] + 1
        if ( tier == 5 ) then
            whom.zones[value.zoneID][9] = whom.zones[value.zoneID][9] + 1
        end
        
        if ( whom.tdetails[tier][classIndex] == nil ) then
            whom.tdetails[tier][classIndex] = 0
        end
        whom.tdetails[tier][classIndex] = whom.tdetails[tier][classIndex] + 1
        if ( tier == 5 ) then
            if ( whom.tdetails[4][classIndex] == nil ) then
                whom.tdetails[4][classIndex] = 0
            end
            whom.tdetails[4][classIndex] = whom.tdetails[4][classIndex] + 1
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
            if ( whom.item.career == L"" )
            then
                local offset = 0
                if ( GameData.Player.realm == GameData.Realm.DESTRUCTION ) then
                    offset = 12
                end
                for i = 1, 12 do
                    whom.AddItem( whom.careers[i+offset], whom.item.zone, whom.item.level )
                end
            else
                whom.overflow = whom.overflow + 1
                whom.Tally(data)
            end
        end
    end
    if (whom.head ~= nil ) then
        whom.Search()
    else
        whom.running = false
        
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
                   if ( i < 5) then more = more - whom.zones[zid][5+i] end 
                   if ( more > 0 ) then out = out .. L"," end
               end 
            end
            EA_ChatWindow.Print(out)
        end
        
        EA_ChatWindow.Print(towstring("**** Total players found: "..whom.count.. " ****"))
        if ( whom.overflow > 0 ) then
            EA_ChatWindow.Print(L"whom: WARNING some level/class combinations were skipped due to overflow! Count is not accurate!")
        end
        
        for tier = 1, 5 do
            local tname = "Tier "..tier
            if ( tier == 5 ) then tname = "R40" end
            local tanks = whom.tcount[tier][1] 
            local mdps = whom.tcount[tier][2] 
            local rdps = whom.tcount[tier][3] 
            local healers = whom.tcount[tier][4] 
            local total = whom.tcount[tier][5]
            EA_ChatWindow.Print(towstring(  tname .. ": "
                                        ..  total .. " player. "
                                        ..  tanks .. " tanks, "
                                        ..  mdps .. " mdps, "
                                        ..  rdps .. " rdps, "
                                        ..  healers .. " healers"))
            if ( whom.details ) then
                local tierdata = whom.tdetails[tier]
                local classes = whom.keys(tierdata)
                table.sort(classes)
                for i, classIndex in pairs(classes) do
                    local count = tierdata[classIndex]
                    EA_ChatWindow.Print(towstring("  "..count.. " ")..whom.careers[classIndex])
                end
            end
        end
    end
end
    
function whom.keys(t)
    local k = {}
    for key, value in pairs(t) do
        table.insert(k, key)
    end
    return k
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
