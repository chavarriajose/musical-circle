# Musical Circle

by Jose Chavarría. 2021

A generative music sketch made in [Processing](https://processing.org). Particles move around a circle, and every time one crosses it, it plays a note. The notes go out as MIDI to any music software.

## How it works

There is one particle for each piano key, from A0 to B7 (MIDI notes 21 to 107). Each one sits at its own angle around the circle, going up in pitch as you go around.

Every particle moves back and forth along a straight line from the center, and they all cover the same distance. The only difference between them is where each one is in its sine wave. The phase moves at a rate set by the note number, so higher notes go faster. They start together, drift apart, and slowly come back together.

When a particle crosses the base circle, it plays its note. Most of the time the notes are scattered into rhythms. Every so often groups of them line up and play together as evenly spaced chords: whole-tone scales, diminished and augmented chords, octaves. Eventually every note lines up again into one big cluster, and the cycle starts over.

It works a lot like a [Whitney Music Box](https://en.wikipedia.org/wiki/John_Whitney_(animator)).

## The versions

Each version is its own sketch. They're kept side by side so you can see how the project changed.

| Sketch | What changed |
| --- | --- |
| `musicalCircle_001` | The original sketch from 2021. All 87 notes, chromatic, no controls. |
| `musicalCircle_002` | Scale modes. Only the notes in the selected scale get a moving particle. The fixed markers for all 87 keys stay. Chromatic or one of the seven modes (Ionian to Locrian), in any root. Controlled from the keyboard. |
| `musicalCircle_003` | A GUI made with controlP5: SCALE and ROOT buttons, a SPEED knob, and an OCTAVES range slider to choose which octaves play. |
| `musicalCircle_004_1` | Octave experiment: a row of 8 cells. Click one octave or drag across several. |
| `musicalCircle_004_2` | Octave experiment: a ring around the circle, split into the octaves. Drag the ends of the selected arc. |
| `musicalCircle_004_3` | Octave experiment: two knobs, OCT LOW and OCT HIGH, that click between octaves. |
| `musicalCircle_004_4` | Octave experiment: 8 toggles, any combination of octaves on or off. |
| `musicalCircle_005` | The ring from 4.2 with the on/off toggles from 4.4: click a piece of the ring to turn that octave on or off, or drag across pieces. Turning octaves on or off, or changing the root, doesn't restart the motion. New particles appear where they would have been all along. Changing the scale still starts the cycle again. The circle is bigger, in its own square. |

`musicalCircle_005` is the latest version.

### Controls

From `musicalCircle_002` on:

- **0–7**: pick the scale (0 is chromatic, 1–7 are the modes)
- **LEFT / RIGHT**: move the root down or up a semitone

From `musicalCircle_003` on, the same things can be done with the GUI. The SPEED knob goes from 10 times slower to 10 times faster, and the middle is the original speed.

## Setup

### 1. Processing

Install [Processing](https://processing.org/download) 3 or 4. Then go to *Sketch → Import Library → Manage Libraries* and add:

- The MidiBus
- controlP5 (from `musicalCircle_003` on)

### 2. A virtual MIDI port

The sketch sends MIDI to a virtual port, and your music software listens to it.

- **Windows:** [loopMIDI](https://www.tobias-erichsen.de/software/loopmidi.html). Create a port named `loopMIDI Port`. This is the setup I used.
- **macOS:** the built-in IAC Driver. Open *Audio MIDI Setup → Window → Show MIDI Studio*, double-click **IAC Driver**, and tick *Device is online*.
- **Linux:** the ALSA virtual MIDI module (`sudo modprobe snd-virmidi`).

On macOS and Linux the port has a different name. The sketch prints the available ports when it starts (`MidiBus.list()`). Copy the name you want into the `new MidiBus(...)` line in `setup()`.

### 3. Music software

I used Ableton Live. Open *Preferences → Link, Tempo & MIDI* and turn on **Track** input for the virtual port. Then set a MIDI track's input to the port and its monitor to **In**. A piano or any sound with a short release works well.

Because the output is plain MIDI, any DAW or synth that accepts MIDI input works too.

### 4. Run

Open a sketch folder in Processing and press Run.

The sketch sends a note-off whenever a particle moves away from the circle. If you stop it while notes are playing, those notes can stay on in your music software. Turn the track's input off and on again to clear them.

## Notes

The original sketch is from 2021. The later versions and the comments were made in 2026 with the help of AI.

The pixel font *standard 07_58* in the `data` folders belongs to its author and isn't covered by this project's license.

## License

Open source under the [MIT License](LICENSE).
