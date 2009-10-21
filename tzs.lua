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
    tzs.classes = {}
    RegisterEventHandler( SystemData.Events.SOCIAL_SEARCH_UPDATED, "tzs.OnSearch" )
    tzs.Search()
end

function tzs.OnSearch()
    local data = GetSearchList()
    if ( data ~= nul )
    then
        if ( #data < 30 ) then
            tzs.count = tzs.count + #data
            local level = tzs.queue[tzs.readpos+2]
            if ( level <= 11 ) then
                tzs.countT1 = tzs.countT1 + #data
            elseif ( level <= 21 ) then
                tzs.countT2 = tzs.countT2 + #data
            elseif ( level <= 31 ) then
                tzs.countT3 = tzs.countT3 + #data
            else
                tzs.countT4 = tzs.countT4 + #data
                if ( level == 40 ) then
                    tzs.count40 = tzs.count40 + #data
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
        EA_ChatWindow.Print(towstring("tzs: T1 players found: "..tzs.countT1))
        EA_ChatWindow.Print(towstring("tzs: T2 players found: "..tzs.countT2))
        EA_ChatWindow.Print(towstring("tzs: T3 players found: "..tzs.countT3))
        EA_ChatWindow.Print(towstring("tzs: T4 players found: "..tzs.countT4))
        EA_ChatWindow.Print(towstring("tzs: Level 40 players found: "..tzs.count40))
        EA_ChatWindow.Print(towstring("tzs: total players found: "..tzs.count))
        EA_ChatWindow.Print(towstring("tzs: hit max: "..tzs.overflow))
    end
end
