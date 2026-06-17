# Sketch Steps: AI Loomis Draw

An interactive, premium-grade portrait drawing application utilizing Andrew Loomis's famous head construction method, powered by Gemini-based AI Reference Generation and custom interactive tracing overlays.

## Key Features Built-In:
1. **Interactive Step-by-Step Loomis Stepper**:
   - 6 detailed structural steps representing the full Loomis method.
   - Dual-layer Canvas: practice drawing directly over the guide lines on a digital sketch-pad.
2. **AI Reference Generation**:
   - Powered by Gemini's high-fidelity `imagen-4.0-generate-001` model.
   - Generates bespoke portrait reference sketches according to user-defined art prompts.
   - Features built-in exponential backoff (retries up to 5 times) to ensure zero API network failures.
3. **Trace & Workspace Engine**:
   - Load any reference photo (from AI generator or your device gallery).
   - Dynamic, customizable **Loomis Overlays** (Front, 3/4 View, Profile).
   - Gestural Manipulation: Move, scale, and rotate the Loomis construction grid directly on top of the reference photo using intuitive double-finger gestures.
   - Professional Drawing Canvas with color pickers, opacity controls, brush sizes, and undo/redo buffers.

## Codemagic CI/CD Compatibility
This project uses stable, reliable libraries (`http` and `image_picker`) ensuring compilation on Codemagic without build-script failures or dependency conflicts.