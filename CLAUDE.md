# Project Overview

This project is intended to run a simulation of the Lorenz atttractor and displays the 2D plots on a TSkPaintBox. The basic framework has been created with a TSkPaintbox and a timer as well as the OnDraw event is ready to be worked on.

A Win64 version will be created.
 
# Project Conventions

## Language & Toolchain
- Delphi Object Pascal, Delphi version 13 (Embarcadero RAD Studio).
- Tailor all code suggestions, syntax, and library references to Delphi/Object Pascal idioms.

## GUI Stack
- GUI applications use **FireMonkey (FMX)** — not VCL — for cross-platform targets.
- For canvas/2D graphics, use **Skia** (Skia4Delphi), not the native FMX TCanvas.
- Default to FMX namespaces (`FMX.*`) and Skia units (`System.Skia`, `FMX.Skia`) for all canvas drawing.

## Author

- Herbert M Sauro

## License: 

Apache 2.0

## Build

Call rsvars.bat to set up the paths to the compiler. The compiler is located at 

- C:\Program Files (x86)\Embarcadero\Studio\37.0

This correspond to Delphi 13

From PowerShell in the project root:

- msbuild /p:Configuration=Release /p:Platform=Win64 <ProjectName>.dproj
- Debug build: `/p:Configuration=Debug`. 

Output goes to `.\Win64\Release\` (configured in the .dproj, not on the command line).

`rsvars.bat` is loaded via `$PROFILE`, so `msbuild` is on PATH in every PowerShell session. If `msbuild` isn't found, the profile didn't run — check `Get-ExecutionPolicy -Scope CurrentUser` is `RemoteSigned`.


## Project structure

- Pascal units (`.pas` and `.fmx`) live in the **project root** (no `src/` subdirectory).
- `<ProjectName>.dpr` — program entry point
- `<ProjectName>.dproj` — MSBuild project file (managed by IDE; edit with care)

## Editing rules

- **Never edit `.dproj` to add platforms or change build configurations.** Open in IDE, change Project Options, save, close. Then commit the resulting XML diff.
- **`.fmx` files are editable as text** but prefer the IDE form designer for non-trivial layout changes. Hand-edits are fine for renaming components, tweaking properties, reordering.
- **Don't run the IDE and edit files in Claude Code at the same time.** Close the project in the IDE before letting Claude modify `.pas`/`.fmx`/`.dproj`.
- Unit filenames are lowercase with `u` prefix by convention here: `uModelState.pas`, `uPlotSeries.pas`.
- Form unit files names are lower case `uf` prefix by convention here: `ufForm.oas`

- Two-space indent, `begin`/`end` on their own lines.
- Exceptions propagate — don't swallow with bare `try..except`.
- Prefer structural fixes over timer-based throttles or workarounds.
- macOS-specific quirks: use `TThread.ForceQueue` for deferred destruction;

## What Claude should not do without asking

- Add or remove target platforms (use IDE).
- Change `DCC_*` paths in `.dproj` (use IDE Project Options).
- Bulk-rename units (touches `.dpr`, `.dproj`, every `uses` clause — easy to break).
- Modify the `.dpr` beyond adding/removing units from the `uses` clause.

