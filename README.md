# WeaselToonCadova: Boat Model in Swift

I started exploring [Cadova](https://github.com/tomasf/Cadova), which lets one express CAD designs in [Swift](https://www.swift.org).

I built a pontoon boat with a kit from [TinyPontoonBoats.com](https://www.tinypontoonboats.com).   I have a 3D CAD model of it:

<p align="center"><a href="./pics/pontoon_cad.png"><img src="./pics/pontoon_cad.jpg" alt="Fusion 360 CAD" width='100'/></a></p>

I had recently iterated with Claude on engineering an upgrade to my pontoon design.  Then after reading about [Cadova on HackerNews](https://news.ycombinator.com/item?id=46442624), I decided to vibe-code a Swift version of my boat.

I by visually and textually iterating with Claude, having it write Swift code to express the Pontoon and then iterating via more screenshots and prompts.

## Take 1 - Claude Desktop

I started by launching Claude Desktop and referring to an earlier conversation I had about my bow upgrade.  When the idea sparked, I figured I had this context, so I would leverage that.  Then I just threw the CAD screenshots at it via paste.

Here's what the start of the conversation looked like:

<p align="center"><a href="./pics/prompt_1.png"><img src="./pics/prompt_1.png" alt="intial prompt to Claude and resulting thoughts" width='200'/></a></p>

After less than a minute, it produced the code in this [first commit](https://github.com/ConAcademy/WeaselToonCadova/commit/33ed0a0a32ab1c35739ae63ca98307d10ac30d91).  The code from it actually didn't work, but I pasted the error and asked Claude to fix it and after the next round it compiled and created a 3mf file. 

Here's the initial result in [Cadova Viewer](https://github.com/tomasf/CadovaViewer) (a simple 3MF viewer):

<p align="center"><a href="./pics/pontoon_swift_first.png"><img src="./pics/pontoon_swift_first.jpg" alt="Fusion 360 CAD" width='200'/></a></p>

First I set things up:

 1. Create the Cadova project per their [Getting Started](https://github.com/tomasf/Cadova/wiki/Getting-Started)

 1. Take CAD screenshots and include previous conversation context

 1. Open Claude Desktop to my pontoon conversation and paste the screenshots
 
 1. Start with this prompt:<br>

    `I just learned about this Cadova project that can create solid
    geometry in swift.    I just uploaded a screenshots of the CAD
    my boat.  Can you estimate its 3d CSG structure and express it
    in swift with Cadova?`

I entered the following agentic loop process:
1. Copy Swift code to VSCode
1. Fix any issues and execute `swift run`
1. Take resulting 3MF and load into [Cadova Viewer](https://github.com/tomasf/CadovaViewer)
1. Take screenshot of the new result
1. Human thinks about screenshot
1. Paste screenshot image into Claude and prompt for next revision's code
1. Jump to 1.

After iterating, I reached the following which was pretty decent, but certainly not even close to perfect for engineering:

<p align="center"><a href="./pics/pontoon_swift_final.jpg"><img src="./pics/pontoon_swift_final.jpg" alt="Final model from Claude Desktop exploration" width='200'/></a></p>

You can see the [final Swift code here](./Sources/WeaselToonCadova/WeaselToonCadova.swift) and also [follow the commits](https://github.com/ConAcademy/WeaselToonCadova/commits/main/).

Here's the [shared Claude conversation](https://claude.ai/share/f0f02bcf-dbfe-4108-8c46-655177938eea), although I find that too much information gets lost in the sharing (screenshots, code, etc.). The first prompts are about materials selection and then about designing an upgrade for the bow.  But, the rest is the vibe coding for this project.

## Take 2 - Claude Code

I started the Claude Desktop work mid-comment on the [Cadova HN post](https://news.ycombinator.com/item?id=46442624).  It was just so easy to ask it and then manually build a project and iterate.  When I have an idea, I like to bang on it and shake it quickly to get a feel.

I had been in a Claude Desktop agentic loop like that before, with both [`screentime-mcp`](https://github.com/AgentDank/screentime-mcp).  But the human (me) was really in the way, a copy-paster who can quickfix minor bugs.  The real deal is to empower by removing yourself.

Tools like Claude Code and [Crush](https://github.com/charmbracelet/crush) allow direct modification of your environment, so the LLM can edit the code itself and advance.  This is commonly done now and IMO this style of working really turned a corner in the last couple months (in November 2025).

Also, I was undisciplined above (still am here a bit too), and now prompted the LLM with more information about the pontoon.  I gave it links to find more information and told it to read and analyze them.

First, I just wanted a clean slate and used a new chat in Claude Desktop with a first prompt:

<p align="center"><a href="./pics/prompt_2.png"><img src="./pics/prompt_2.png" alt="intial prompt of Take 2" width='200'/></a></p><br>

I manually applied it like before but there were tons of syntax errors.  So, I started up Claude Code in the directory and pasted the previous prompt and dragged the screenshots onto the terminal.

It iterated to fix the syntax errors.  I then needed it to be able to work for itself, creating models in Swift and modifying based on its own discovery.

I used the 3D viewing [`f3d`](https://github.com/f3d-app/f3d) application (I Google-search-prompted for that) to render 3MF files to PNGs.  LLMs can't directly "see" 3MF files, but we use this tool to create pictures which their multi-modal models wiill understand.

With that, I could enter this agentic loop in Claude Code, which will evolve to the master prompt:
  1. Claude takes prompt and edits Swift file
  1. build and run code, if broken goto 1 with error messages.
  1. run code and generate 3MF
  1. render 3MF in desired position to PNG
  1. "look" at model PNG for issues
  1. generate prompt/thinking to resolve and goto 1.

Here's the prompt that kicks off one spin of the wheel:

    i have installed the f3d program which can render 3mf from the command line.  look at how to use it and iterate through the models and resultant images, identifying issues in the image.  you can use the pasted fusion3d images and tinypontoonboats.com images as reference.

Here's an example of a command it issued to generate a picture for itself:
```
f3d --output renders/boat-iso-v4.png --resolution 1200,900 --camera-position 200,200,150 --camera-focal-point 0,90,10 --up +Z pontoon-boat-complete.3mf 2>&1
```

Then this is the prompt that made it loop:

    i want you to iterate 5 times in the loop you just did , examining the resultant renders and modifying the code

It then did 5 loop iterations and summarized what it did:

```
Summary of all changes made:

  Iteration 1

  - Increased main beam flange width (2.5→3.0") and thickness
  - Enlarged C-brackets (thickness 0.125→0.25", width 2→3")

  Iteration 2

  - Changed main beams to aluminum silver color for contrast
  - Improved transom with vertical support posts and top crossbar

  Iteration 3

  - Made pontoon ribs more prominent (larger rings, darker orange)
  - Increased square tube size (2.0→2.5")

  Iteration 4

  - Changed pontoon color to bright orange (RGB 1.0, 0.45, 0.1)
  - Updated nose cone color to match
  - Increased main beam flange width/thickness (3.0→3.5", 0.375→0.5")

  Iteration 5

  - Added center longitudinal rails in the middle section of the frame
  - These connect across the area between aux pontoons

  Final model features:
  - ✓ 2 main 27" pontoons with nose cones on both ends
  - ✓ 4 aux 18" pontoons in 2x2 pattern
  - ✓ T-slot channels on pontoon tops
  - ✓ 4 main beams (2 per main pontoon) in aluminum
  - ✓ Hat channel crossmembers with correct profile
  - ✓ C-brackets at each crossmember
  - ✓ Center longitudinal rails
  - ✓ Transom with vertical supports
  - ✓ Front square tube crossmember
  - ✓ Pontoon reinforcement ribs
  ```

Here's a final picture, definitely not perfect.  Maybe if I turn it to 11.

<p align="center"><a href="./pics/vibe_final_bambu.png"><img src="./pics/vibe_final_bambu.png" alt="intial prompt of Take 2" width='200'/></a><p><br>


## Acknowledgements

Thanks to the [Cadova project](https://github.com/tomasf/Cadova)!

## License

Released under the [MIT License](https://en.wikipedia.org/wiki/MIT_License), see [LICENSE.txt](./LICENSE.txt).

Copyright (c) 2026 Evan Wies.