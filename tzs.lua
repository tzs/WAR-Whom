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
        else
            if ( tzs.queue[tzs.readpos] == L"" )
            then
                for i = 1, 24 do
                    tzs.AddItem( tzs.careers[i], tzs.queue[tzs.readpos+1], tzs.queue[tzs.readpos+2] )
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
        EA_ChatWindow.Print(towstring("tzs: total players found: "..tzs.count))
        EA_ChatWindow.Print(towstring("tzs: hit max: "..tzs.overflow))
    end
end
