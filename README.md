
# Midi2SamplerDSP

A Swift Package providing **production-grade DSP primitives** for a **MIDI 2–native sampler**, building on
[`Fountain-Coach/midi2`](https://github.com/Fountain-Coach/midi2).

## Highlights
- **Loop seam discovery & stitching** (composite metric: amplitude + slope + spectrum)
- **Adjacent-zone crossfades** (key/velocity), equal-power windows, smoothstep mapping
- **Micro phase alignment** for seam minimization
- **DC removal, loudness matching**, slew-limited parameter changes
- **Windowed-sinc offline resampler** for pitch-matching before blending
- **Unit tests** for click-free loops and continuity

## Why this matters for MIDI 2
MIDI 2.0 (via UMP) increases resolution and enables per-note expression. This library ensures that **sample seams,
loops, and crossfades** are artifact-free so your instrument takes full advantage of MIDI 2 expressiveness without
audible clicks or comb filtering.

## Using with SwiftPM
```swift
dependencies: [
    .package(url: "https://github.com/Fountain-Coach/midi2", branch: "main"),
    .package(url: "https://example.com/your/Midi2SamplerDSP", branch: "main")
]
```

> If the `midi2` package product name is not `MIDI2`, adjust the dependency in `Package.swift` accordingly.


## Persistence (Fountain-Store)
This package integrates with [`Fountain-Store`](https://github.com/Fountain-Coach/Fountain-Store) via a thin adapter.
The repository reads/writes **Sampler Pack** JSON documents and defers storage backends to Fountain-Store
(local FS, cloud, or git—depending on its configuration).

```swift
import Midi2SamplerDSP

let repo = SamplerPackRepository() // uses Fountain-Store adapter by default
var pack = SamplerPack(
    instrument: Instrument(
        name: "GrandPiano",
        sampleRate: 48000,
        zones: [
            Zone(id: "zp_C4_vel64",
                 pitchCenter: 60,
                 pitchRange: [57,63],
                 velocityRange: [0.5,0.7],
                 file: "Audio/piano_C4_vel64.wav",
                 loop: Loop(start: 123456, end: 234567, overlap: 2048))
        ]
    )
)

try repo.save(pack, to: "Instruments/GrandPiano/Instrument.json")
let loaded = try repo.load(at: "Instruments/GrandPiano/Instrument.json")
```

> If the Fountain-Store SwiftPM **product name** is not `FountainStore`, adjust the `.product(name: "FountainStore", package: "Fountain-Store")`
in `Package.swift`, and the `import FountainStore` statements accordingly.


## FountainKit Integration (AI Reasoning)

This package exposes a **SamplerAgent** that can be wired into `FountainKit` as a Tool-capable agent.
The agent supports operations like **stitchLoop**, **savePack**, and **listPacks**. Extend it with
`renderNote`, `renderChord`, `evaluateSeam`, etc., as you formalize your tool schema.

### Wiring Example
```swift
import Midi2SamplerDSP
// import FountainKit  // depending on your app target

let agent = SamplerAgent()  // uses Fountain-Store by default
let req = StitchLoopRequest(audioPath: "Audio/mono.rawf32", searchStart: 48000, searchEnd: 240000, overlap: 2048)
let payload = try JSONEncoder().encode(req)
let invocation = SamplerToolInvocation(kind: .stitchLoop, payload: payload)
let resultData = try await agent.handle(invocation)
let result = try JSONDecoder().decode(StitchLoopResult.self, from: resultData)
print("Loop points:", result)
```

> Note: The included WAV loader is a stub for proof-of-concept. Replace with proper WAV I/O for production
> (e.g., `AVAudioFile` / `AudioToolbox`), or integrate your existing asset pipeline.


## OpenAPI-First (FountainKit-friendly)

This repository now ships an **OpenAPI 3.1** spec at `openapi/sampler.yaml`.
Planning/Reasoning systems (e.g., FountainKit) should **discover and invoke**
sampler capabilities by reading this spec — no direct code dependency needed.

**Primary endpoints**
- `POST /loops:stitch` — discover/write seamless loop points using the composite DSP metric
- `POST /packs:save` — persist `SamplerPack` documents (via Fountain-Store backends)
- `GET /packs?directory=...` — list packs
- `POST /render:note` — offline render for a single note (artifact URL)

**Models** are aligned with the Swift `SamplerPack` types to keep JSON and code in lockstep.


## Audio Corpus & Introspection

The package now includes an **AudioIntrospector** and corpus models to make audio files
first-class corpus citizens. Use it to compute summaries (RMS/peak/DC, spectral stats,
placeholder MFCC/chroma, optional loopability via `LoopStitcher`), generate embeddings
and simple fingerprints, then persist results via Fountain-Store.

**OpenAPI endpoints** for this flow are documented in `openapi/sampler.yaml`:
- `POST /corpus/audio:ingest`
- `POST /corpus/audio:analyze`
- `GET  /corpus/audio:search`
- `GET  /corpus/audio:dedupe`


## Validation

The package includes a **Validator** to enforce quality and consistency:

- `PackValidator` — checks SamplerPack structure and zone metadata (hard/soft/info).  
  Auto-corrects soft issues: fill `format/version`, set recommended crossfade time, suggest/raise loop overlap, set default RMS.
- `AudioValidator` — gates AudioSummary quality (DC/clipping/loopability thresholds).

```swift
let packReport = PackValidator().validate(pack)
let (corrected, fixes) = PackValidator().autoCorrect(pack)

let audioReport = AudioValidator().validate(summary)
```


## Validator Endpoints (OpenAPI)

The spec now exposes validator endpoints so planners and tools can gate changes before persisting:

- `POST /packs:validate` → returns a `ValidationReport` for a `SamplerPack`
- `POST /corpus/audio:validate` → returns a `ValidationReport` for an `AudioSummary`

Use `ValidationService` to wire these endpoints in your server quickly.


## Velocity-Timbre Morphing (Lean dynamics without many layers)
New DSP blocks:
- `VelocityTimbreModel` — maps MIDI 2 velocity to tilt/presence/transient/noise/saturation.
- `Biquad` — low-shelf & peak with smoothed coeffs.
- `TransientShaper` — attack emphasis.
- `SoftSaturator` — tanh-like soft clipper.
- `PositionEQ` — simple mic perspective EQ chain.
- `PedalResonance` — short IR convolution scaffold.
- `KeyOff` — micro-sample layer for releases.
- `TuningTables` — per-note detune/inharmonicity.
- `RealTimeNoteProcessor` — ties it all together per note.

**OpenAPI** additions for morphing:
- `POST /morph/preset:apply`
- `POST /morph/params:renderNote`
- `POST /morph/fitCurves`

Use a few velocity anchors and let DSP + MIDI 2 per-note expressivity smoothly cover the rest.


## Next Steps

- **Upgrade PedalResonance**: current IR convolution is naive FIR. Replace with partitioned FFT or GPU (Metal) for real-time efficiency.
- **Curve Fitting**: implement `/morph/fitCurves` with a small regression or ML fitter that learns velocity→timbre mapping from corpus embeddings & sparse anchors.
- **CLI Demo**: add `sampler morph-render --note 60 --vel2 12000` style command to render a WAV so developers can immediately hear the morphing results.
