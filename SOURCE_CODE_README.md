# Marbles Squared for the ZX Spectrum Next

Although the source code is commented throughout there's no real narrative through routines, so this file serves as a way finder and an overview of how the code is structured.

## Language and tools used

The bulk of this game is written using NextBASIC, however there are core logic parts and features of the game that required getting closer to the "metal" as it were, so I wrote these in Z80 assembly (though the code definitely targets the Spectrum Next features).

The bulk of the code you'll find in this project, however the dependency called `.http` is how part of the official Spectrum Next repository and documentation and the source code can be [found there](https://gitlab.com/thesmog358/tbblue/-/tree/master/src/asm/http/src).

Software authoring was written using VS Code. For the NextBASIC side, I used my own [NextBASIC extension](https://marketplace.visualstudio.com/items?itemName=remysharp.nextbasic) and for assembly I used a number of extensions to help me debug, most valuable of all way the [DeZog extension](https://marketplace.visualstudio.com/items?itemName=maziac.dezog).

Included in this project is my `.vscode` directory which can be used to compile the assembly source code if you wish to do so.

Development testing was almost exclusively done in Cspect (running on mac), though there are some minor differences, I had to add some code to specific run on Cpsect (to prevent it from crashing) and obviously regularly checked in with the hardware for testing.

## Key project aspects

I consider the project a hybrid NextBASIC and assembly project. The game user interface and rendered output live in `marbles.bas`.

The logic for managing how the blocks are held in memory and importantly the selection and clearing of blocks (in memory only) happens in `marbles.bin` which is the compiled output of the assembly source code. I added this as the cost of running this code purely in NextBASIC was just too expensive and was affecting the game play performance.

Finally the game also allows for a "world leader board". These scores are hosted on the web, and when you, the player, gets a high score this is also posted to a web server. For this, originally I started in NextBASIC ran into edge case bugs and inconsistent behaviours so I wrote and released the `.http` dot command.

The `.http` handles communicating with the web, posting your high score and collecting the public high scores and sharing them in your game.

## Project structure

The key directories are:

- `src` - which holds the NextBASIC source code, mostly living in `src/marbles.bas.txt` as plain text before being exported to NextBASIC tokenised file format
- `src/assets` - containing game assets, such as fonts, graphics, sounds, drivers and dependencies such as `.http`
- `lib` - containing the assembly source code, where `marbles-grid.asm` is the main entry point for generating `/src/assets/marbles.bin`

```
├── Makefile  ..................... generates NextBASIC bundle
├── lib  .......................... the assembly code
│   ├── Makefile
│   ├── README.md
│   ├── attr_address.asm
│   ├── marbles-grid-index.inc.asm
│   ├── marbles-grid-memory.inc.asm
│   ├── marbles-grid.asm  ........ entry point for asm
│   ├── rom.inc.asm
│   └── sysvars.inc.asm
└── src  .......................... all the NextBASIC code
    ├── marbles.bas.txt  .......... main game mechanics
    ├── marbles-extra.bnk.txt  .... game UI routines
    └── assets  ................... game assets, fonts, etc
        ├── alert.nxi
        ├── ayfx.drv
        ├── controls-alt.nxi
        ├── controls.nxi
        ├── font-area51.bin
        └── ...and more
```

## Assembly logic

The assembly based code is used exclusively for the logic that works out which blocks are loaded and cleared. It also includes a very specific PRNG (random number) routine. Using this coded logic for a random number allows me to ensure that replay of a specific "seed" (a 16bit value) is always the same sequence.

Using this routine has also allowed me to port the game to other platform and allow for exactly the same board layouts and sequences.

If the assembly project is compiled with the `testing` flag enabled, it produces a simple `.sna` spectrum file that can actually be loaded into a 48K spectrum to test the game logic. There's a decent amount of test code that lets me select a marble and clear it and it might lead the way for a possible 48K version of the game.

The assembly compiles into location `$C000` as this is where banked code in NextBASIC is loaded and called from. during the compile the "API" is logged out so that I know where the entry points for NextBASIC to call the assembly are:

```
> Public API:
>
>   #define M_CANMOVE=432
>   #define M_RANDOMSEED=434
>   #define M_FN_POPULATEGRID=454
>   #define M_TAGINDEX=499
>   #define M_FN_TAG=498
>   #define M_FN_MIXMAX=924
>
> Size:                 1285 bytes
```

So for instance the `M_FN_TAG` location points to the `NBTag` routine in assembly and can be called with `BANK 20 USR 498`, though in reality this is coded as `%t=% BANK #BANKLIB USR #M_FN_TAG` (see the Define Statements below).

The memory map holds the game grid in two states. One is the user represented state, as in columns of marbles. The other is the internal state which is _rows of columns_. This internal state allows for easier navigation through memory to find how to clear columns letting the marbles "fall".

To help simplify the process of switching between the user representation and the internal representation I generated two include files: `marbles-grid-index.inc.asm` and `marbles-grid-memory.inc.asm`.

There's also a lot of use of sjasmplus2's `ALIGN` feature so that memory is sitting specifically on the edge of memory so that I can specifically work in the lower 8 bytes of a 16 bit address.

The assembly might not be the best out there as it was only my second project written in assembly, but it does do exactly what I need and it relieved a lot of performance pressure off of the NextBASIC game play.

## NextBASIC code style

If you're used to reading BASIC or even NextBASIC there might be some parts of my code that might look odd, specifically the lack of line numbers, the different comment styles and the `#define` keywords.

### Line numbers

I'm not a fan of managing line numbers so where possible I use `#autoline n` which generates line numbers during the tokenisation process. The side effect is that nearly all my code relies on `PROC` routine calls instead of `GOTO` (which in coming versions of NextBASIC should out perform `GOTO` anyway).

However, there are certain times that I need to be able fork over code using a `GOTO` jump. You'll see this towards the end of `marbles.bas.txt`. Using the `#autoline` statement on it's own _turns off_ the autoline generating and then I'm in control of line numbers again.

I use line numbers where I have to be very precise around installing drivers and where I'm selecting a random line number for the game over message.

### Comment styles

I very rarely use the `REM` keyword for comments, though you'll find it in exactly one location in my code. I'll return to why in a moment.

Otherwise I'll use the semi-colon `;` token, either on a line by itself or trailing the code. When the comment is on it's own line, this is actually stripped out at build time to reduce the file size and to reduce what the Next has to parse.

I also use the hash `#` token for comments. I tend to use this as a convention that says "this is for someone wanting to understand my source code" rather than comments that explain a specific bit of logic. These are also automatically stripped during the tokenisation process.

The single `REM` statement is a special case that I don't want to remove (which happens inside my custom `Makefile`) as it's used by the input driver I use - which I'll explain further in this document.

### Define statements

I wrote a `txt2bas` program that nearly mirrors the Next's own `.txt2bas` dot command. However there is one feature I added to my own, and that's the ability to define constants that get swapped out during tokenisation.

The main driver for this is that it's much easier to read `%p(#SCORE)` than it is to read `%p(4)`. Although I could use a variable in NextBASIC to represent the value `4` this is just more work for NextBASIC to do and it also keeps my variable count down.

So I define my "constants" at the top of my code and then I use them throughout. This makes my code, to me, much more readable.

## Code ordering

During development the order of routines doesn't really matter, but it does matter when it comes to releasing and so I used [Simon Goodwin's NextBASIC profile driver](https://simon.mooli.org.uk/nextech/profile/index.html).

Using this tool I was able to identify, during game play, which routines were being called often and how they were performing. Using this information, and Simon's article on how the internals work, I can _move_ specific routines higher up in the order of code which then has a huge impact on performance.

## Use of drivers

Speaking of the Profile driver, there are three other drivers that are used in the production mode of the game. The Profile driver isn't included in the default release of the game (as it's a debugging tool and shouldn't be enabled).

### Joystick and keyboard

Joystick and keyboard input is handled by [Paulo Silva's Input.drv](https://github.com/paulossilva/gameinput/).

This driver quite literally drops into the code and uses a callback method to call NextBASIC routines allowing me to move the user's cursor. This is also the place that I have to use the `REM` statement as this block is replaced at runtime by Paulo's driver to decide which routine to call.

### Mouse

If the user selects to use the mouse, a natural choice for this type of game, the Next's own mouse.drv (from `/nextzxos`) is installed and used.

One trick I did have to employ to get the mouse pointer to sit _above_ the block sprites (the "marbles" are sprites), is to ensure that the sprite id was `127`.

This is because the higher the sprite id the higher order in the layering and I needed the pointer to sit in the highest layer.

### Sound

Sound is minimal in this game, but uses a few small effects to compliment the selection of blocks, undoing, level up and the game over.

These use my [ayfx.drv](https://github.com/remy/next-ayfx), and I selected some appropriate sounds from Shiru's FX library which I created a [web interface for](https://zx.remysharp.com/audio/).

## Graphics

The tiles or "marbles" were designed using my own web tool for Spectrum Next sprites at [zx.remysharp.com](https://zx.remysharp.com/sprites/) where I can customise the palette and craft the designs for the tiles.

The larger drawn areas were done using [Aseprite](https://www.aseprite.org/), then exported to png, and then re-encoded to the Spectum Next layer memory format called NXI, again, using one of [my own tools](https://zx.remysharp.com/tools/).

My personal two favourite themes are the "Old Spec" and "New Grey".

## Bundled single marbles.bas

You might have noticed that the distribution file is a single file. This uses a bundling method where all the dependencies are appended to the end of the file and then extracted using the `.extract` dot command (that's part of the OS).

I [documented this process in detail](https://remysharp.com/2021/05/31/file-hacking-fully-self-contained-nextbasic) on my blog so you can see how it works.

The short version is that I'm able to develop and test using the unbundled code and then when it comes to releasing, I run `make` and release the bundled code.

## Fonts

Damien Guard has an [excellent collection of ZX fonts](https://damieng.com/typography/zx-origins/) and for this project I used [Area51](https://damieng.com/typography/zx-origins/area51) for the small font and customised (just on the capital i character) version of [Computing 60s](https://damieng.com/typography/zx-origins/computing-60s) for all other text.

The font is hot swapped into memory as I need it using the `font` routine which also shifts the font width on the fly to allow for better horizontal space use.

## Web - how the leader board works

When viewing the high scores, by default you see the web hosted high scores.

If you don't have Wifi on board the Next you'll see a failure message but you can still participate in the world leader board as your high score and the validation data is stored in the `marbles.dat` file.

If and when you the player gets a high score (the bar being set at 1,000 points), your initials are requested and the data is sent to the web (and saved locally).

The payload that's sent to the web is structured as so:

- seed - 16 bit number
- move_length - 16 bit number
- moves - 8 bit number representing each marble selected
- name - the 3 characters

This raw binary is sent to [data.remysharp.com](http://data.remysharp.com/) a bespoke service I created for anyone to freely use to capture and share data back to a Spectrum. The service itself is dumb in the respect that it can't run any logic, so this data is then automatically forwarded to my own server that accepts the data _and_ includes the current high score table.

That web service then creates a new game based on the given seed and plays the moves that you sent. Then, if the score from this sequence earns a place in the high score leader board, then the _new_ high score table is sent back to the data.remysharp.com service and the leader board is updated.

Since the score isn't sent and only the moves are sent, it's impossible to fake a score - as every entry is validated and played back.

All the communication with the web is done using the `.http` dot command that I wrote specifically to solve this problem but the project is now (proudly) part of the Spectrum Next distribution.

## FAQ

This project doesn't currently have an FAQ as you're one of the first to read this document. However, if you find you have a question about the code or how some part of this project was pulled off, please feel free to email me at remy@remysharp.com and I'll be more than happy to help.
