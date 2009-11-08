whom = {}

-- This is ugly code. I wanted this add-on, so just kind of started hacking, without
-- actually learning Lua. I am quite hazy on things like how to do data structures
-- in Lua. No need to suggest the dozens of obvious ways this code be made
-- non-braindead. I already know them--just haven't learned how to do them
-- in Lua yet! If only Mythic had picked Perl for their interface language...

function whom.initialize()
    whom.registered = false
    whom.reset()
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
    LibSlash.RegisterWSlashCmd("whom", function(args) whom.onSlashCmd(args) end)
    EA_ChatWindow.Print(towstring("Whom available. Type /whom for population report"))
end

function whom.reset()
    whom.running = false
    whom.finishing = false
    whom.tcount = { {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}}
    whom.tdetails = { {}, {}, {}, {}, {} }
    whom.zones = {}
    whom.count = 0
    whom.overflow = 0
    whom.details = false
    whom.head = nil
    whom.tail = nil
    whom.here = false  
    whom.sc = false  
end

function whom.onSlashCmd(args)
    local wasrunning = whom.running
    whom.reset()
    if ( wasrunning == true ) then
        EA_ChatWindow.Print(L"whom: stopped")
        return
    end
    
    local levels = {}
    for i, arg in ipairs(whom.words(WStringToString(args))) do
        if ( arg == "-c" ) then     whom.details = true
        elseif ( arg == "t1" ) then for j=1,11 do levels[j]=1 end
        elseif ( arg == "t2" ) then for j=12,21 do levels[j]=1 end
        elseif ( arg == "t3" ) then for j=22,31 do levels[j]=1 end
        elseif ( arg == "t4" ) then for j=32,40,1 do levels[j]=1 end
        elseif ( arg == "40" ) then levels[40]=1
        elseif ( arg == "here" ) then whom.here = true; whom.sc = false
        elseif ( arg == "sc" ) then whom.here = true; whom.sc = true
        else
            EA_ChatWindow.Print(towstring("whom: unrecognized option: "..arg))
        end
    end
    EA_ChatWindow.Print(L"Checking for players...this might take a while...")
    
    if ( whom.here == true )
    then
        if ( whom.sc ) then
            for i, data in ipairs (GameData.ScenarioQueueData) do
                if ( data.id ~= 0 ) then
                    whom.queueSearch( L"", {data.zone}, 1, 40 )
                end
            end
        else
            whom.queueCareerSearch( {GameData.Player.zone}, 1, 40 )
        end
    else
        local to_search = whom.keys(levels)
        table.sort(to_search, function(a,b) return a<b end)
        for i, level in ipairs(to_search) do
            whom.queueSearch( L"", {-1}, level, level )
        end

        if ( whom.head == nil ) then
            for level = 1,40 do
                whom.queueSearch( L"", {-1}, level, level )
            end
        end
    end
    if ( whom.registered == false ) then
        RegisterEventHandler( SystemData.Events.SOCIAL_SEARCH_UPDATED, "whom.onSearchUpdated" )
        whom.registered = true
    end
    whom.running = true
    whom.search()
end

function whom.search()
    whom.item = whom.head
    if ( whom.item ~= nil ) then
        whom.head = whom.item.next
        SendPlayerSearchRequest( L"", L"", whom.item.career, whom.item.zone, whom.item.low, whom.item.high, false )
    end
end

function whom.queueSearch(career, zone, low, high)
    local item = {}
    item.next = nil
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

function whom.tally(data)
    for key, value in ipairs( data ) do
        whom.count = whom.count + 1
        
        local tier = whom.rankToTier( value.rank )
        local classIndex = whom.careerNameToClassIndex( value.career )
        local archtypeIndex = whom.classIndexToArchtypeIndex( classIndex )
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

function whom.queueCareerSearch( zones, low, high)
    local offset = 0
    if ( GameData.Player.realm == GameData.Realm.DESTRUCTION ) then
        offset = 12
    end
    for i = 1, 12 do
        whom.queueSearch( whom.careers[i+offset], zones, low, high )
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
    else
        local data = GetSearchList()
        if ( data ~= nil and whom.finishing == false )
        then
            if ( #data < 30  ) then
                whom.tally(data)
            else
                if ( whom.item.career == L"" )
                then
                    whom.queueCareerSearch( whom.item.zone, whom.item.low, whom.item.high )
                else
                    if ( whom.here == true )
                    then
                        whom.overflow = whom.overflow + 1
                        whom.tally(data)
                    elseif ( whom.item.zone[1] == -1 )
                    then
                        local zids = GetZoneIDList()
                        local t1, t2 = whom.splitList( GetZoneIDList() )
                        whom.queueSearch( whom.item.career, t1, whom.item.low, whom.item.high )
                        whom.queueSearch( whom.item.career, t2, whom.item.low, whom.item.high )
                    else
                        if ( #whom.item.zone == 1 )
                        then
                            whom.overflow = whom.overflow + 1
                            whom.tally(data)
                        else
                            local t1, t2 = whom.splitList( whom.item.zone );
                            whom.queueSearch( whom.item.career, t1, whom.item.low, whom.item.high )
                            whom.queueSearch( whom.item.career, t2, whom.item.low, whom.item.high )
                        end
                    end
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
            whom.queueSearch( career, {-1}, 1, 1 )
            whom.search()
        end
    end
end

function whom.displayResults()
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
        EA_ChatWindow.Print(out)
    end

    EA_ChatWindow.Print(towstring("**** Total players found: "..whom.count.. " ****"))
    if ( whom.overflow > 0 ) then
        EA_ChatWindow.Print(L"whom: WARNING some level/class combinations were skipped due to overflow! Count is not accurate!")
    end

    for tier = 1, 5 do
        local tname = "Tier "..tier
        if ( tier == 5 ) then tname = "R40" end
        EA_ChatWindow.Print(towstring(  tname .. ": "
                                    ..  whom.tcount[tier][5] .. " players. "
                                    ..  whom.tcount[tier][1] .. " tank, "
                                    ..  whom.tcount[tier][2] .. " mdps, "
                                    ..  whom.tcount[tier][3] .. " rdps, "
                                    ..  whom.tcount[tier][4] .. " healer"))
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

function whom.p(...)
    local out = L""
    for i, part in ipairs(arg) do
        if ( type(part) == "wstring" ) then
            out = out .. part
        else
            out = out .. towstring(""..part)
        end
    end
    EA_ChatWindow.Print(out)
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

