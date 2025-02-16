# PTCGPExtras
Additional functionality to Arturo's PTCGP bot

Update and FAQS:

Q. Can I have your code?
A. My code will be published on my github shortly (I'll edit this with a link here). I am just trying to get it to the first alpha testing. My code is not a simple replacement of 1.ahk, instead it is a library of functions that will be added in the "Include" directory. These new functions will then be called in an updated 1.ahk file. 

Q. What makes yours different / why would I use yours?
A. There are many things that set mine apart, but here are a few major notes:
1.  I don't use gdip_ImageSearch().
	1. I wrote my own function that instead dumps the bitmap data of a needle and screenshot of the window into RAM, where it then compares pixel blocks directly. Each needle block belongs specifically to an assigned card. There's no search variation, or inaccuracy. 
	2.  It's extremely fast, 100% accurate, and instead of results being a "God Pack" or a "Trainer Card", the results are simply what cards where opened in the pack.
	3. Here's an example result: (STS_ prefix is the pack type)
		1. Pack 1201: STS_FanRotom, STS_Kricketot, STS_Spiritomb, STS_Misdreavus, STS_WeavileEX_2Star
2.  Saving desired packs is based on a points system.
	1. My code creates a csv file called a Pokedex, which contains a list of all cards in the game. In the cell adjacent to the card name is a value column representing a cards desirability. If you want a card, assign it points accordingly. If you don't want it, make it worth 0 or less. This filters out the packs to be exactly what you're looking for.
	2. The SavePack() criteria is based on a minimum desired pack value points. You can say you only want to keep packs with a total value of 2 or higher, for example.
	3. By default, the values are like so:
		- Normal : 0 Points
		- 1 Star : 1 Points
		- EX : 1 Points
		- 2 Star : 2 Points
		- 2 Star Rainbow : 3 Points
	4. By setting minimum pack value to 5 for example, it will calculate the hand's value and if it's less than 5 points, it won't save the pack.
	5. There is a special "GodPack" value as an alternative, where it will ensure that each card in the hand is a 1 star or greater in order to keep it.

Q. Does this work on all packs / specific packs?
A. Currently I've only extracted needles for the Palkia pack, and so at release this will only work with that pack. Now that I am 100% finished with the Palkia pack though, I'm starting Dialga.
Future releases will definitely include all packs. However, the needle creation process is very specific to a tool I've created specifically for it, which requires it be ran and used in such a way to completely remove user error. Unfortunately, this means I have to manually create the needles for each card and name them myself, to ensure the accuracy I want to present to the community.

Q. Can I contribute? Screenshots or something?
A. See above to understand why I have to gather the screenshots myself unfortunately. This may change in the future if there's enough demand for users to create it themselves. Just know creating the needles is simple, not easy. And very tedious. 

Q. How does your needles get created, what makes it different than other ones I've seen here?
A. My needle is not created from a screenshot created by Arturo's Screenshot() function. It's a custom one I've created to dump the pixel value data directly into RAM. It uses an array of array's containing specific capture coordinates in the image to create a "fingerprint" of the card, which totals 60 pixels. The 60 pixels are unique not only to the card, but to the card's specific slot (1-5), and then is stitched together with the same card type for the remaining slots, ultimately creating one needle image file with the data in it representing that card type, in all card slots. (100x3 pixel needle image). Creating this file manually would suck arse. Do not recommend.

Q. How do I get/install your code?
A. My goal is to create an extension for the bot, so that updates are simple each time there's an update to Arturo's bot.
Better instructions will be in my github's ReadMe, however for now it will basically work like this:
- Add MooExtras.ahk to [Bot's Main Folder] --> [Scripts] --> [Include]
- Replace 1.ahk in [Bot's Main Folder] --> [Scripts]
In a future update, I'll be creating an install.ahk file that automatically updates 1.ahk's functionality and moves files accordingly for a simple installation, and will have checks to fetch the latest version.

Q. What about the instance monitor app?
A. It's a progressive web app (fancy website for mobile phones) that allows you to monitor your bot instances. It polls every 10 seconds (user set) to determine details like what cards were last opened, what instance/account opened it, how many packs have been opened, how long, etc etc, Search above for a video I made demonstrating it. This app requires quite a heavy tutorial on installing and will really be for advanced users only, at least until I can simplify it. Special thanks to RaenonX for creating the backend to host the files.
This program will not be available soon, it's more of a proof of concept for others to get creative with. Once the plugin above is at a state I'm happy with, I'll divert my attention to the monitor app and we'll go from there.


If you have any other questions please let me know, I'll be moving all of this to an official FAQ's on the github.
