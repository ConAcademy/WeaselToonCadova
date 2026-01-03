# WeaselToonCadova: Boat Model in Swift

I started exploring [Cadova](https://github.com/tomasf/Cadova), which lets one express CAD designs in [Swift](https://www.swift.org).

I built a pontoon boat with a kit from [TinyPontoonBoats.com](https://www.tinypontoonboats.com).   I have a [3D CAD model of it](#eye-candy).

I had recently iterated with Claude on engineering an upgrade to my pontoon design.  Then after reading about [Cadova on HackerNews](https://news.ycombinator.com/item?id=46442624), I decided to vibe-code a Swift version of my boat.

Here's the Claude converasation:<br> https://claude.ai/share/f0f02bcf-dbfe-4108-8c46-655177938eea

The first prompts are about materials selection and then about designing an upgrade for the bow.  But, the rest is vibe coding this project.

You can see the [Swift code here](./Sources/WeaselToonCadova/WeaselToonCadova.swift).

## Process

The setup was:

 * create the Cadova project per their [Getting Started](https://github.com/tomasf/Cadova/wiki/Getting-Started)

 * make CAD screenshots and some previous conversation context

I added the initial source CAD screenshots and prompted:<br>

    I just learned about this Cadova project that can create solid
    geometry in swift.    I just uploaded a screenshots of the CAD
    my boat.  Can you estimate its 3d CSG structure and express it
    in swift with Cadova?

Then entered an agentic loop:

* copy Swift code to VSCode
* fix any issues and execute `swift run`
* take resulting 3MF and load into [Cadova Viewer](https://github.com/tomasf/CadovaViewer) (a simple 3MF viewer)
* take screenshot of the new result
* human thinks about screenshot, pasing image into Claude and prompting for next revision's code

## Eye Candy

I've included the [final 3MF](./pontoon-boat.3mf) and some screenshots:

`Fusion 360 CAD` <br>
<img src="./pontoon_cad.jpg" alt="Fusion 360 CAD" width='100'/>

`First Swift-gen Model` <br>
<img src="./pontoon_swift_first.jpg" alt="First Swift-gen Model" width='100'/>

`Last Swift-gen Model` <br>
<img src="./pontoon_swift_final.jpg" alt="First Swift-gen Model" width='100'/>


## License

Released under the [MIT License](https://en.wikipedia.org/wiki/MIT_License), see [LICENSE.txt](./LICENSE.txt).

