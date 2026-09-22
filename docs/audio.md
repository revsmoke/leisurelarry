# Original lounge music

`assets/audio/last_call.wav` is an original, instrumental 32-second loop composed and synthesized for this game on 2026-09-21. It contains no recordings, sampled instruments, quoted melodies, vocals, or material from the Leisure Suit Larry soundtracks.

The arrangement uses a 90 BPM swing pulse, twelve bars of electric-piano chord voicings, a gently plucked synthesized bass, quiet noise brushes, low kick pulses, and occasional vibraphone-like answers. All sound is calculated from oscillators and seeded noise by `tools/generate_music.py`. The seed is `19810921`; the generated ornament choices are deterministic. Circular note tails and room reflections continue across the loop boundary.

Format: stereo, 44,100 Hz, 16-bit PCM WAV. The rendered music peaks at approximately -6.4 dBFS and is intended to sit quietly beneath the adventure UI. The game applies a further volume reduction and exposes a music toggle. Reverb is baked into the recording so Web playback does not rely on unsupported real-time audio effects.

Regenerate with a Python environment containing NumPy:

```sh
python3 tools/generate_music.py
```

On the development Mac, the verified bundled interpreter is:

```sh
/Users/twoedge/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tools/generate_music.py
```

The generator prints duration, peak/RMS levels, sample count, loop boundary delta, and SHA-256. Its entire composition and synthesis implementation is included for inspection and modification. Music is original project material and may be used and modified with this game.

The checked-in WAV import configuration selects forward looping over the full sample. Initial render verification: 1,411,200 stereo frames; peak -6.38 dBFS; RMS -22.62 dBFS; boundary difference 12 PCM units out of 32,767; SHA-256 `4f9bb56f927c7ad98fc5901637f7268973ac162a2747cac2416300e48a4e1ee3`.

Godot 4.7.2 loaded the imported stream successfully and reported length 32.00 seconds, `AudioStreamWAV.LOOP_FORWARD`, 44,100 Hz, stereo. The import uses QOA compression to reduce packaged audio size while keeping the source WAV available in the repository.
