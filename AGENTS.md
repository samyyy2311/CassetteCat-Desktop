# CassetteCat Desktop engineering rules

## Scope

- Read the complete existing flow before editing it. Trace every caller of a shared function before changing its behavior.
- Make the smallest coherent change. Do not refactor adjacent code, reformat unrelated files, or change public behavior outside the request.
- Preserve all unrelated working-tree changes.
- Do not add dependencies, frameworks, layers, factories, adapters, or configuration for a single use case.

## Ownership and state

- Each behavior has one owner. Controllers own library, playback, service, and persistence behavior. QML presents state and forwards user intent.
- Never create mirrored state in QML for controller-owned data. Never add a second queue, playlist, scanner, settings store, or network path.
- Reuse the existing queue, playlist, settings, library, and service APIs. Extend the owner when a shared rule changes.
- Keep local music and radio queues separate. Do not mix stream tracks into persisted local playlists or queues.

## QML and appearance

- Reuse an existing QML component before writing new UI. If the same UI structure or interaction appears twice, extract one shared component before merging.
- New UI must use the window palette: `recordRed`, `recordRedHover`, surface colors, text colors, and border colors. Do not introduce literal colors, fixed accent values, or one-off styling.
- Pass `paletteSource` to shared player controls where the component supports it. Do not copy a control to change its appearance.
- Use existing `Setting*`, `TransportButton`, `PressDepthIconButton`, `Cover`, and scrollbar components. Do not recreate their visuals locally.
- Keep layouts responsive at the minimum window size. Use existing compact controls or menus when a row cannot fit.
- Do not use anchors on an item managed by a `Layout`, `StackLayout`, or view delegate layout.

## Code quality

- Prefer deletion over addition. Do not leave dead paths, compatibility shims without a removal reason, placeholder behavior, or commented-out code.
- Comments explain non-obvious constraints or decisions only. Never add narration, AI-style headings, or comments that restate the code.
- Validate inputs at process, filesystem, and network boundaries. Return failure instead of inventing fallback data.
- Use names that expose intent. Keep functions short enough to have one responsibility; do not split coherent logic solely to create helpers.

## Verification

- Build once after a non-trivial change with the configured single-job CMake build. Do not overlap CMake, Ninja, compiler, or linker jobs.
- Run `CassetteCat.exe --self-check` after a successful build. Launch once and inspect fresh `debug.log` for new QML or runtime errors.
- Do not claim an interaction, visual result, memory result, external integration, CI run, or release package is verified unless it was actually exercised.
- Fix warnings introduced by the change before continuing. Report pre-existing warnings separately.
