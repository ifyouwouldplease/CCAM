# CCAM
**CCAM** (**C**an't **C**arry **A**ny **M**ore!) is an addon for *World of Warcraft: Classic* that provides slash commands ( **/ccam** or **/cca** ) to show an alert if the selected bags are full.

**CCAM** refers to the bags by their internal bag ID, with the backpack being 0 and the additional bags being 1-4:

|   |   |   |   |   |
| ------------ | ------------ | ------------ | ------------ | ------------ |
| 4 | 3 | 2 | 1 | 0 |



Let's try some examples...
### Examples:

Check if the backpack (the player's original 16 slot bag) is full:
```
/ccam 0
```
Check if all bags are full:
```
/ccam 0-4
```

Check if the backpack and first 2 bags, and the furthest left bag are full, ignoring bag 3:
```
/ccam 0-2,4
```

CCAM observes macro options, so if needed you can do things like:
```
/ccam [button:3] 0-4
```

...to only test on a middle mouse button click.



By default the alert message is simply "BAGS FULL", but you can add your own custom message following the bag IDs:
```
/ccam 0,2 Buy bigger bags!
```

### FAQ:
##### *Where would I use this?*

- By placing a CCAM command at the start of a macro, you can get an alert about the state of your bags and chose to cancel later actions before they complete.

##### *Why would I need that?*

- I made this addon for myself to create macros for the Warlock Create Soulstone and Create Healthstone spells. Both of those both fail AND consume a Soul Shard if your inventory is full.

##### *Why not just test all bags?*

- Special purpose bags like herb bags and enchanting bags can have space free, but still not permit you to pick up items if your "normal" bags are full. CCAM allows you to select which bags you want to test, allowing you to ignore special bags.
