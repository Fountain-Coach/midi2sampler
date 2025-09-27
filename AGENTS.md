
# AGENTS — MIDI 2–Native Swift Sampler (Standardization Draft)

This document outlines an **agentic workflow** to establish a *de facto* standard for a MIDI 2–native sampler.
It pairs a **spec** (JSON-based sampler packs + WAV/FLAC assets), **DSP reference** (this package),
and **MIDI 2 interop** (via `Fountain-Coach/midi2`).

---

## Roles

- **Spec Agent**
  - Owns the open sampler **pack format** (Instrument.json schema + audio assets).
  - Aligns properties with **MIDI 2 Profiles** and **Property Exchange (PE)**.
  - Defines forward/backward compatibility (MIDI 1.0 fallback).

- **DSP Agent**
  - Maintains seam-finding, crossfades, resampling, loudness/DC toolchain.
  - Publishes thresholded **validation tests** (click budget, spectral continuity).

- **Interop Agent**
  - Implements UMP parsing/serialization and Profile/PE bindings.
  - Exposes capability descriptors and mappings to sampler parameters.
  - Ensures **per-note** control pathways are smooth (slew) and click-free.

- **Validator Agent**
  - Enforces **Hard rules** (bounds, file existence), **Soft rules** (defaults), and **Validation** gates (seam metrics).
  - Applies **Correction** strategies (repick loop, increase overlap, enable spectral morph) automatically.

- **Documentation Agent**
  - Reference guides, migration paths (SF2/SFZ → v0.1), examples, diagrams.
  - Maintains changelogs and versioning policies.

---

## Sampler Pack Format (Preview)

```json
{
  "format": "Midi2SamplerPack",
  "version": "0.1.0",
  "instrument": {
    "name": "GrandPiano",
    "sampleRate": 48000,
    "zones": [{
      "id": "zp_C4_vel64",
      "pitchCenter": 60,
      "pitchRange": [57, 63],
      "velocityRange": [0.50, 0.70],
      "file": "Audio/piano_C4_vel64.wav",
      "loop": { "start": 123456, "end": 234567, "overlap": 2048, "window": "equalPower" },
      "normRMS": -18.0,
      "phaseAlignHint": 2
    }],
    "xfade": { "timeMs": 30, "curve": "equalPower", "spectralMorph": false }
  },
  "controllers": {
    "perNote": { "pitchBend": true, "timbre": "CC74", "pressure": true },
    "global": { "sustain": 64, "pedalResonance": true }
  },
  "profiles": ["org.midi.profile.piano.v1"],
  "propertyExchange": { "uri": "profile/piano", "params": { "sympatheticResonance": true } }
}
```

---

## Validation Policy

- **Hard rules**
  - `loop.start < loop.end` and within file bounds
  - `overlap >=` 2–3 periods of lowest prominent partial
  - referenced audio files exist and match declared sampleRate/channels

- **Soft rules**
  - default `window = equalPower`, `dcRemoval = true`, `matchLoudness = true`
  - default `xfade.timeMs = 20–60`

- **Validation metrics**
  - `maxAbsStep` at seam below threshold
  - spectral continuity: log-mag L2 distance below threshold

- **Correction logic**
  - re-pick loop points minimizing composite score
  - extend overlap length
  - enable spectral morph for noisy/semi-periodic material

---

## Roadmap

1. Stabilize DSP reference (this package + tests) with public test corpus.
2. Publish Pack Schema v0.1 and JSON examples.
3. Bind MIDI 2 Profiles/PE via `midi2` interop layer.
4. Provide converters from SF2/SFZ → v0.1.
5. Draft proposal for community review / MMA consideration.


---
## OpenAPI-First Agent Flow

- **Discovery**: Orchestrator fetches `openapi/sampler.yaml` and registers tools from the `paths` section.
- **Validation**: The Validator Agent uses the schema components to check packs and request shapes before calls.
- **Execution**: Calls are made to HTTP endpoints; responses are checked against the schema and test thresholds.
- **Evolution**: Changes are introduced via **spec versions**; code is regenerated (clients/servers) from the spec.

### Suggested Server Choices
- **Swift**: Vapor, Hummingbird, or Kitura-compatible; map endpoints to this package’s DSP functions.
- **Python**: FastAPI (great for rapid prototyping); call into Swift DSP via FFI or service boundary.
- **Interop**: Keep the wire contract stable via OpenAPI; swap implementations freely.
