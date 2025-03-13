# PTCGPExtras
Additional functionality to [Arturo's PTCGP bot](https://github.com/Arturo-1212/PTCGPB)

> [!WARNING]
> I've uploaded files to start testing this and to get helpers going, but please note:  
> **This is not ready for public release and will not work yet.**

## Todo:
[Instances]
- ~~Main Instance~~
- ~~Number of Instances~~
- ~~Number of Columns~~
- ~~No Speed Mod - Failed. It's Art's original code and it didn't work, so this feature will be disabled.~~
- ~~Arrange Windows~~  
[Packs]
- Minimum Pack Value
- Pokedex
- Pack To Open
- ~~Number of Packs to Open~~
- ~~Use Threshold - Disabled, will be implemented into new bot~~
- ~~One Pack Mode. This feature will be on by default. There is no functionality to not open packs one at a time with this version.~~
- Injection Mode
- ~~Menu Delete Account. This feature will be off by default. There is no functionality to menu delete accounts with this version.~~
[Discord]
- Does it post to discord correctly
- ~~Does heart beat work. Untested. Did not alter original code.~~
- ~~Does discord list work. Untested. Did not alter original code.~~  
[Displays]
- ~~125% scale available only. All card images are captured at 125% scale, will no work with other scales with this version.~~
[Moo]
- ~~Skip Adding Main~~
- Fingerprint Mode
- ~~Trade Mode - Update listing that this feature will not be released anymore~~
- ~~Show Status Window~~
- ~~Select Pack Per Instance - Update that this feature will no longer be released.~~  
[About]
- ~~Check for updates needs to be updated to say this project is EoL~~

## Update and FAQS:

### What is this / what does it do?
- Personalized Wonderpicks
- Enables up to 13 packs to be opened
- Injection accounts have account names
- Uses custom multi-tabbed GUI for organization
- Identifies what each card is after a pack opening
- Uses a points system to determine if a pack is valuable and should be saved (Values based on user settings)

### How do I use this?
Unlike many other alternate solutions, this project is not a simple replacement of 1.ahk.  
Instead, it is a library of functions that will be added in the "Include" directory. These new functions will then be called in an updated 1.ahk file. 

### Why aren't you forking Arturo's bot?
I believe the functionality I'm contributing doesn't align with the majority of the user base demand nor Arturo's direction / intended use. It's for a niche subset of users that want specific cards from their wonderpick.

### What makes yours different / why would I use yours?
Here's the major reasons:
1.  I don't use gdip_ImageSearch().
    - There's no search variation, it's 100% accurate.
    - It's extremely fast
    - Instead of results being a "God Pack" or a "Trainer Card", the results are simply what cards were opened in the pack.  
	Example pack opening: 
	>	```Pack 1201: STS_FanRotom, STS_Kricketot, STS_Spiritomb, STS_Misdreavus, STS_WeavileEX_2Star```
2.  Saving desired packs is based on a points system.
    - A standard csv file is created called Pokedex, which contains a list of all cards in the game.  
      In the cell adjacent to the card's name is a value column representing the cards desirability.  
      If you want a card, assign it positive points accordingly.
      If you don't want it, make it worth 0 or less.  
      The points system is used to filter packs to be exactly what you're searching for.  <br/><br/>
      The SavePack() criteria is based on a minimum desired pack value points.  
      You can say you only want to keep packs with a minimum pack value of 2 points, for example.  <br/><br/>
      These are the default values:
      - 1 Star : 1 Points
      - EX : 1 Points
      - 2 Star : 2 Points
      - 2 Star Rainbow : 2 Points
      - Immsersive/Crown Rares: -99 Points (If Skip is enabled in GUI)
      - Everything else: 0 Points  <br/><br/>
    - Opening a pack with a defined minimum pack value of 5, for example, with a pack whose total pack value is 4, will not save the pack, but instead continue rerolling.

> [!TIP]
> There is a special "GodPack" value as an alternative to the points system, where it will ensure that each card in the pack is 1 star or greater

### How do I get a specific card?
Open and edit Pokedex.csv (locationed in [Bot folder] --> [Scripts]  
Excel: Go through the list or search for your desired specific card (Ctrl+f). On the cell beside it in column B, put the desirability value to something high like 7, for example.  
Notepad: Find the specific card in the list and add a comma after it, then a high desirability value such as 7.  
Save the file.  
In the PTCGP GUI, change the Minimum Pack Value to 7.  

### Does this work on all packs? Specific packs?
Currently this will only support the Palkia pack. <br><br> 
  
> [!NOTE]    
> Future releases will definitely include all packs.  
> However, the needle creation process is very specific to a tool I've created specially for it, which requires it be ran and used in such a way to completely remove user error.  
> Unfortunately, this means I have to manually create the needles for each card and name them myself, to ensure the accuracy I want to present to the community.

### Can I contribute? Screenshots or something?
See above to understand why I have to gather the screenshots myself unfortunately.  
This may change in the future if there's enough demand for users to create needles themselves. Just understand creating the needles is simple, not easy. _And very tedious_. 

### How do needles get created? What makes it different than Arturo's or other ones I've seen?
The needle image I use is created by dumping the raw pixel value data directly into RAM. It uses a multidimensional array containing specific capture coordinates to create a "fingerprint" of a card.  
The fingerprint is unique not only to the card, but to the card's specific slot (1-5).  
The fingerprint is then stitched together with 4 more fingerprints, creating a single hand print. _(The same card type for the remaining slots, ultimately creating one needle image file with the data in it representing that card type, in all card slots.)_  

### How do I install?
The goal of this project is to create a plugin for the bot, so that updates are simple (and syncs easily with updates to Arturo's bot).  <br><br>
For now, installation works like this:  
- Download and extract the repo. Copy entire Scripts folder into the main PTCGPB's main folder, overwriting all files.  
- Run 1.ahk (Program can't be called from PTCGPB.ahk, otherwise the update will overwrite the 1.ahk file). Stay tuned for a patcher program.

> [!IMPORTANT]  
> I'll be creating a separate file called Install.ahk that automatically updates 1.ahk's functionality and moves files accordingly, for a simple installation. Later it will have checks to fetch the latest version.

### What about that instance monitor app I saw?
It's a progressive web app (fancy website for mobile phones) that allows you to monitor your bot instances.  
It polls every 10 seconds (user set) to determine details like what cards were last opened, what instance/account opened it, how many packs have been opened, how long, etc etc.  <br><br>
This app requires quite a heavy tutorial and indepth installation, and will really be for advanced users only.  
This program will not be available soon, it's more of a personal project and proof of concept for others to get creative with.  
Once this plugin is at a state I'm happy with, I'll divert my attention to the monitor app and we'll go from there. It will be a separate plugin from this one.
