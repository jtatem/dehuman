# Dehuman

## An Atari 2600 Interactive Demo

### Building / Running

Build with [dasm](https://sourceforge.net/projects/dasm-dillon/)...

`dasm dehuman.asm -f3 -o out.bin`

...or use a pre-built binary from the builds directory in the repo.

Later I'll add some Python scripts for changing the fore/background images [we have that now, see below!], as well as some howto's for changing the music.

Run the binary in your favorite Atari 2600 emulator.  I like [Stella](https://sourceforge.net/projects/stella/).

### Demo Controls

P1 Up:  Change melodic sequence

P1 Down:  Change beat sequence

P1 Left:  Bend instrument down

P1 Right:  Bend instrument up

P1 Fire:  Change instrument

P2 Up/Down/Left/Right:  Continuous fire for Open Hat / Closed Hat / Kick / Snare drums

P2 Fire:  Intentionally blows the scanline CPU cycle budget to produce video and audio distortion effects

The controls allow the demo to be a sort of glitchy chiptune playground. Play around, send lots of inputs at once, hold things down, make some noise ;-D

### Using Python tools to change the images

You can use create_asm.py in the tools subdirectory to generate a custom ASM file using your own supplied images for the foreground and background.

These require the wand library to be installed:

```
pip install wand
```

To use create_asm.py:

```
python create_asm.py <path to foreground image> <path to background image> [--template <path to template asm file>] [--out_file <path to write output>]
```

The foreground and background images will be automatically scaled and stretched to the 40x192 resolution of the Atari 2600 playfield.  For best results
do your own conversion to monochrome prior to running the tool.
