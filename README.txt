/whom is similar to the built-in command /who, but with several enhancements:

1. It can handle results of more than 30 players.

2. The player list is sorted and color coded, to make it easier to read. The player names are player links, so you can click them to initiate tells or access the command menu. There are extensive options to control the sorting.

3. There are options to list players in your zone, in scenarios available to you, from your guild, from your alliance, from specific tiers, or to list everyone visible.

4. A table is presented showing player counts in each zone, and stats on tier and archetype breakdown for each zone. This is handy when you are trying to find where the action is. A summary is presented showing the population and archetype breakdown of each tier. Handy if you are trying to decide if you want to play an alt.

NOTE: due to the way the Warhammer handles search events, the searches /whom does to find its information will also show up in the chat window as if you were doing /who commands, and the add-on wizards tell me there is no way to suppress these. Those will be followed by /whom's results, also in the chat window, in whatever tabs that do not have System General filtered out.  If you end up using /whom more than occasionally, you'll probably be a lot happier if you filter System General out of your normal chat tabs, and make a separate tab that just shows System General for viewing /whom results.

If you can't remember the options to /whom, try "/whom help". I've appended the help text below, so you can use this page as a reference if you wish.

Here are some examples:

  /whom -w alliance

That will list who is online from your alliance, just showing the player list.

  /whom t4 -a -r

That will list tier 4 (rank 32-40), sorting the player list by archetype (tank, mdps, rdps, healer), and within each archetype sorting by rank. The location and tier stats will be included, along with the player list. Toss in a -w if you only want the player list.

  /whom sc -z -g

That will list the people in scenarios, sorting the list by zone, and within each zone sorting by guild. Only scenarios currently available in your scenario lobby are included.

Here is the in-game help text, for reference:

Usage: /whom [options]
  If you give no options, default is to list all visible players
  If you specify one or more of the five following options, then
    only people of the given ranks will be included:
     t1     show ranks 1-11
     t2     show ranks 12-21
     t3     show ranks 22-31
     t4     show ranks 32-40
     40     show rank 40
  You can limit the search to your guild or your alliance with one of:
     guild
     alliance
  You can limit the search to your current zone with:
     here
  You can limit the search to the scenarios currently available to you with:
     sc
  You can limit the seach to people flagged as advisors with:
     advisor
  You can ask for a detailed class breakdown by tier with:
     -d
  NOTE: in prior releases of /whom, this was -c.
  You can specify the sort order of the player list with:
     -c    sort by career
     -a    sort by archetype
     -r    sort by rank
     -z    sort by zone
     -g    sort by guild
  If you do not specify a sort option, players are sorted by name
  If you specify one or more sort options, they are applied in
    in order. For instance, -c -r would sort by career, and then
    sort by rank within each career group, and then finally by
    name when more than one person has the same career/rank
  Here is an example:
    /whom -g -a alliance sc 40
  That would show you rank 40 people in your allliance who are
    currently in a scenario available to you, sorted by guild
    and archetype.
  By default, whom prints a player list, a locations list, and
    statstics on archetypes and tiers. This can be changed:
      -w        (without -l) just show player list
      -l        (without -w) just show locations list
      -w -l     just show players list and locations list

