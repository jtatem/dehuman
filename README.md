# Dehuman

## An Atari 2600 Interactive Demo

### Building / Running

Build with [dasm](https://sourceforge.net/projects/dasm-dillon/)...

`dasm dehuman.asm -f3 -o out.bin`

...or use a pre-built binary from the builds directory in the repo.

Later I'll add some Python scripts for changing the fore/background images, as well as some howto's for changing the music.

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

