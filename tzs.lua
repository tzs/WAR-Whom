tzs = {}

function tzs.Initialize()
    EA_ChatWindow.Print(towstring("Hello! tzs add-on is available"))
    LibSlash.RegisterWSlashCmd("tzs", function(args) tzs.OnSlash(args) end)
    tzs.queue = {}
    tzs.writepos = 0
    tzs.readpos = 1
    tzs.careers = { 
        L"Ironbreaker",
        L"Rune Priest",
        L"Engineer",
        L"Slayer",
        L"Bright Wizard",
        L"Warrior Priest",
        L"Witch Hunter",
        L"Knight of the Blazing Sun",
        L"Archmage",
        L"Swordmaster",
        L"Shadow Warrior",
        L"White Lion",
    
        L"Black Orc",
        L"Shaman",
        L"Squig Herder",
        L"Choppa",
        L"Chosen",
        L"Magus",
        L"Zealot",
        L"Marauder",
        L"Witch Elf",
        L"Blackguard",
        L"Sorcerer",
        L"Disciple of Khaine",
    }
end

function tzs.Search()
    local zone = {}
    zone[1] = tzs.queue[tzs.readpos+1]
    SendPlayerSearchRequest( L"",
                             L"",
                             tzs.queue[tzs.readpos],
                             zone,
                             tzs.queue[tzs.readpos+2],
                             tzs.queue[tzs.readpos+2],
                             false )
end

function tzs.AddItem(career, zone, level)
    tzs.queue[tzs.writepos+1] = career
    tzs.queue[tzs.writepos+2] = zone
    tzs.queue[tzs.writepos+3] = level
    tzs.writepos = tzs.writepos + 3
end

function tzs.OnSlash(args)
    EA_ChatWindow.Print(towstring("You issued the /tzs command! [")..args..towstring("]"))
    for level = 1, 40 do
        tzs.AddItem( L"", -1, level)
    end
    tzs.count = 0
    tzs.countT1 = 0
    tzs.countT2 = 0
    tzs.countT3 = 0
    tzs.countT4 = 0
    tzs.count40 = 0
    tzs.overflow = 0
    tzs.classesT1 = {}
    tzs.classesT2 = {}
    tzs.classesT3 = {}
    tzs.classesT4 = {}
    tzs.classes40 = {}
    RegisterEventHandler( SystemData.Events.SOCIAL_SEARCH_UPDATED, "tzs.OnSearch" )
    tzs.Search()
end

function tzs.CountClass(counter, career)
    local classindex = 0
    local searchcareer = tostring(career)
    local slen = string.len(searchcareer)
    searchcareer = string.sub(searchcareer,1,slen-2)
    for i = 1, 24 do
        if ( searchcareer == tostring(tzs.careers[i]) ) then
            classindex = i
            break
        end
    end
    if ( classindex == 0 ) then
        EA_ChatWindow.Print(L"ERROR: class "..career..L" not found in career table")
        return
    end
    if ( counter[classindex] == nul ) then
        counter[classindex] = 0
    end
    counter[classindex] = counter[classindex] + 1
end

function tzs.ShowCount(counter, name, total)
    for key, value in pairs( counter ) do
        EA_ChatWindow.Print(towstring(value.." "..name.." ")..tzs.careers[key])
    end
    EA_ChatWindow.Print(towstring("tzs: "..name.." players found: "..total))
end

function tzs.OnSearch()
    local data = GetSearchList()
    if ( data ~= nul )
    then
        if ( #data < 30 ) then
            for key, value in ipairs( data ) do
                tzs.count = tzs.count + 1
                --EA_ChatWindow.Print(value.career..towstring(", rank "..value.rank.." in "..value.zoneID))
                if ( value.rank <= 11 ) then
                    tzs.countT1 = tzs.countT1 + 1
                    tzs.CountClass( tzs.classesT1, value.career )
                elseif ( value.rank <= 21 ) then
                    tzs.countT2 = tzs.countT2 + 1
                    tzs.CountClass( tzs.classesT2, value.career )
                elseif ( value.rank <= 31 ) then
                    tzs.countT3 = tzs.countT3 + 1
                    tzs.CountClass( tzs.classesT3, value.career )
                else
                    tzs.countT4 = tzs.countT4 + 1
                    tzs.CountClass( tzs.classesT4, value.career )
                    if ( value.rank == 40 ) then
                        tzs.count40 = tzs.count40 + 1
                        tzs.CountClass( tzs.classes40, value.career )
                    end
                end
            end
        else
            if ( tzs.queue[tzs.readpos] == L"" )
            then
                local offset = 0
                if ( GameData.Player.realm == GameData.Realm.DESTRUCTION ) then
                    offset = 12
                end
                for i = 1, 12 do
                    tzs.AddItem( tzs.careers[i+offset], tzs.queue[tzs.readpos+1], tzs.queue[tzs.readpos+2] )
                end
            else
                tzs.overflow = tzs.overflow + 1
            end
        end
    end
    tzs.readpos = tzs.readpos + 3
    if ( tzs.writepos > tzs.readpos ) then
        tzs.Search()
    else
        tzs.ShowCount( tzs.classesT1, "T1", tzs.countT1)
        tzs.ShowCount( tzs.classesT2, "T2", tzs.countT2)
        tzs.ShowCount( tzs.classesT3, "T3", tzs.countT3)
        tzs.ShowCount( tzs.classesT4, "T4", tzs.countT4)
        tzs.ShowCount( tzs.classes40, "level 40", tzs.count40)

        EA_ChatWindow.Print(towstring("tzs: total players found: "..tzs.count))
        EA_ChatWindow.Print(towstring("tzs: hit max: "..tzs.overflow))
    end
end
