> [!CAUTION]
> This bot has been deprecated. It will no longer recieve updates and will no longer be maintained.  
> Please see "Project End" at the bottom for more details.

# PTCGPExtras
Additional functionality to [Arturo's PTCGP bot](https://github.com/Arturo-1212/PTCGPB)

## Update and FAQS:

### What is this / what does it do?
- Allows you to create personalized Wonderpicks
- Enables up to 13 packs to be opened
- Injection accounts have account names
- Uses custom multi-tabbed GUI for organization
- Identifies what each card is after a pack opening
- Uses a points system to determine if a pack is valuable (Values based on user settings)
- Creates a "Packs.txt" file in the logs folder, which contains a list designed to be imported into excel, to view every card in every pack you've opened. (Useful for analytics and more)

### Why aren't you forking Arturo's bot?
I believe the functionality I'm contributing doesn't align with the majority of the user base demand nor Arturo's direction / intended use. It's for a niche subset of users that want specific cards from their wonderpick.

> [!NOTE]
> To align with my own direction / goals, this project has ended so I can focus development on my own bot. See "Project End" below for more details.

### What makes yours different / why would I use yours?
Here's the major reasons:
1.  Instead of results being a "God Pack" or a "Trainer Card", the results are simply what cards were opened in the pack.  
	Example pack opening: 
	>	```User|stantler|Pack Value|4|TL_Gastly|TL_Noctowl|TL_Croagunk|TL_Marill|TL_Irida_2Star|Instance|4```
2.  Saving desired packs is based on a points system.
    - A standard csv file is created called Pokedex, which contains a list of all cards in the game.  
      In the cell adjacent to the card's name is a value column representing the cards desirability.  
      If you want a card, assign it positive points accordingly.
      If you don't want it, make it worth 0 or less.  
      The points system is used to filter packs to be exactly what you're searching for.  <br/><br/>
      The SavePack() criteria is based on a minimum desired pack value points.  
      You can say you only want to keep packs with a minimum pack value of 2 points, for example.  <br/><br/>
      These are the default values:
      - 1 through 3 Diamond: 1 Point
      - 1 Star : 2 Points
      - EX : 3 Points
      - 2 Star : 4 Points
      - 2 Star Rainbow : 4 Points
      - Immsersive/Crown Rares: -99 Points (If Skip is enabled in GUI)
      - Everything else: 0 Points  <br/><br/>
    - Opening a pack with a defined minimum pack value of 5, for example, with a pack whose total pack value is 4, will not save the pack, but instead continue rerolling.

> [!TIP]
> Arturo's original FindGodPack() function is still enabled, so all godpacks will be saved by default.

### How do I get a specific card?
Click the "Open Pokdex" button under the Instances tab.  
If Using Excel: Go through the list or search for your desired specific card. On the cell to the right of it (column B), enter a desirability value that matches your Minimum Pack Value.  
If Using Notepad: Find the specific card in the list and add a comma after it, then a matching desirability value of your Minimum Pack Value.  
Save the file.  
Now when a pack is opened and that specific card is identified, it will be saved for a chance in a wonderpick.

### How do I create a custom Wonderpick?
Update all the desirability values to reflect cards you're interested in, in the Pokdex file (See above "How do I get a specific card" for instructions).  
Once you have updated the values of cards you're intersted in, set you Minimum Pack Value to align with your target goal.  <br><br>
For example, if you're missing a couple of 2 diamond cards, EX cards, and a lot of 2 Star cards, then if you assign the 2 diamond cards a value of 1, the EX cards a value of 3, and the 2 Star cards a value of 4, and set your Minimum Pack Value to be 5, then your wonderpicks will consist of a collection of your needed cards, increasing your odds to 40%+, because for the pack to be saved, it will have to contain some combination of cards to hit your target goal.

### Does this work on all packs? Specific packs?
Currently this works will all existing packs. However, moving forward the community will have to find a solution of exchanging and collecting needle images for new pack releases. <br> 

### What are needles? How are the card images created?
- A needle is made from a collection of pixels extracted from an image of a card.  
- The needle images I use were created by dumping the raw pixel values data into RAM. It uses a multidimensional array containing specific capture coordinates to create a "fingerprint" of a card, which is typically called a needle (because you search for needles in a haystack).    
- The fingerprint is unique not only to the card, but also to the card's specific slot (1-5).  
- The fingerprint is then stitched together with 4 more fingerprints, creating a single hand print. _(The same card type for the remaining slots, ultimately creating one needle image file with the data in it representing that card type, in all card slots.)_  <br><br>

In order to get card images/needles, in the UI settings click on the "Moo" tab, and check "Fingerprinting Mode".  
When the bot instance encounters an unidentified card in a specific slot, it will prompt you to name it.  
Using the prompt, enter the name of the card according to the naming convention below this.  
Finally, open the pokedex by clicking on the "Instance" tab and then click "Open Pokedex".  
Append the new card name and desirability value to the csv file and save it.  
Now the bot will be able to correctly identify the card in the future.  

### Card Naming Convention:
- Do not use any spaces in a file name, just remove them.
- Underscores "_" designate special rarity types (see below)
- It is case sensitive. All words have the first letter capitalized
- Every card is prefixed with the abbreviation of the set name, followed by the first letter of the pack name. If there's only one pack for the set, no pack name abbreviation is used. If a card is found in more than one pack, it's considered a "mutual card" and just uses the set name as a prefix.

Prefix Examples:  
Dialga Pack: STSD_  
Pikachu Pack: GAP_  
Mutual Card in Genetic Apex: GA_  

Basic Cards (1 Diamond to 3 Diamond): Just the card name  
Example(s): STSP_Chimchar, STS_Magcargo, STSD_Mamoswine

EX Cards (4 Diamond): Base card name and EX  
Example(s): STSP_InfernapeEX, STSP_PalkiaEX, STSP_MismagiusEX

1 Star Card: Base card name, underscore, and then 1Star  
Example(s): STSP_Spiritomb_1Star, STSP_Giratina_1Star, STSP_Staraptor_1Star

2 Star Card: Base card name, EX if applicable, underscore, and then 2Star  
Example(s): STSP_Mars_2Star, STSP_MismagiusEX_2Star, STSP_InfernapeEX_2Star

2 Star Rainbow Bordered Card: Base card name, EX if applicable, underscore, then RR, then underscore, and then 2Star  
Example(s): STSP_LickilickyEX_RR_2Star, STSP_WeavileEX_RR_2Star, STSP_InfernapeEX_RR_2Star

Immsersive Card: Base card name, EX if applicable, underscore, then Immersive  
Example(s): STSP_PalkiaEX_Immersive

Crown Rare Card: Base card name, EX if applicable, underscore, then CrownRare  
Example(s): STS_PalkiaEX_CrownRare, STS_DialgaEX_CrownRare

Card with multiple words with have spaces removed  
Example(s):  
"Armor Fossil" becomes "ArmorFossil"  
"Lum Berry" becomes "LumBerry"  
"Team Galactic Grunt" 2 Star becomes "TeamGalacticGrunt_2Star  

### How do I install? 
- Download and extract from releases. Copy entire Scripts folder into the main PTCGPB's main folder, overwriting all files.  
- Launch PTCGPB.ahk and configure appropriately.

### Some functionality is disabled, Why? Can I enable it?
See "Project End" below for details. TLDR: I'm starting my own project, separate from using/modifying Arturo's bot. As a result, my efforts are going into that new development, not into this project. So some functionality that was suppose to be a part of this bot have been paused indefinitely. 
Here's some particular notes though:  
- Speed Mod is disabled. It's Arturo's original code but it didn't work in my testing, so this feature has been disabled.
- Threshold exists in the code but is not implemented because of the challenges of explaining how to use the system.
- One Pack Mode. This feature will be on by default. This version is designed to open packs one at a time. OpenPacks() would need additional functionality development.
- Menu Delete Account. This feature will be off by default. There is no functionality to menu delete accounts with this version.
- Discord Heartbeat. Untested. Did not alter original code.
- Discord.txt list. Untested. Did not alter original code.
- 125% scale available only. All card images are captured at 125% scale. 100% will not work with this version.

## Project End (EoL)
There is enough difference between my own personal goals with this project and Arturo's bot, that I decided to start from scratch designing my own project.  
Not only that, but the AHK language (both v1 and v2) has limitations that became obstacles to my goals, so I'm switching to python, a language I'm more comfortable wtih developing in and fits my needs better.  
My new bot is a radically different program, targeted towards a different audience, as it caters more to solo re-rollers with many different and unique features.  

I apologize that this project is being superseded before it's even released, but it was all the discoveries and headaches along the way that really made this decision.

If you're interested in following my new project, view it [here] on Github.

### Special Thanks
I want to give credit to m4ttstodon. Super awesome guy. He helped with card collection and beta testing. He's also had some really great ideas (check out the fork on this project for potential online database functionality using googleSS as a backend). He's also helping me with my new bot.

I also want to credit Balum. This dude is full of creative ideas and inspiration. He helped with the majority of card collection and has acted as support in communicating to the community about this project, and also kindly decided to help me with the creation of my new bot.

Thanks guys!

