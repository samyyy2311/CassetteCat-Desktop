# CI and releasing

## Workflows

| Workflow | Runs on | What it does |
| :--- | :--- | :--- |
| `ci.yml` | Pull requests and pushes to `main` | Builds on Windows (`build`), Linux on x86_64 and ARM64 (`linux`), macOS (`macos`) and with Clang (`clang`), runs the self-checks and tests, and runs them again under AddressSanitizer and UndefinedBehaviorSanitizer (`sanitizers`) |
| `static-analysis.yml` | Pull requests and pushes | clang-format and clang-tidy |
| `codeql.yml` | Pull requests, pushes and weekly | CodeQL security analysis of the C++ |
| `dependency-review.yml` | Pull requests | Flags vulnerable or badly licensed dependency changes |
| `flatpak-validation.yml` | Changes to the Flatpak or Linux packaging | Builds the Flatpak and validates the metainfo |
| `workflow-lint.yml` | Changes to workflows | actionlint and zizmor |
| `scorecard.yml` | Weekly | OpenSSF Scorecard |
| `labeler.yml` | Pull requests | Labels pull requests by the files they change |
| `nightly.yml` | Daily at 03:00 UTC | Builds `main` for Windows and Linux and keeps the builds as workflow artifacts |
| `release.yml` | A `v*` tag | Builds, checks and publishes a release |

`main` needs the `build`, `linux`, `macos`, `clang` and `sanitizers` checks to pass, and every review conversation resolved, before a pull request can merge. Actions are pinned to full commit SHAs.

## Publishing a release

1. In a pull request:
   - set the version in `CMakeLists.txt` (`project(CassetteCat VERSION x.y.z ...)`) and `installer/CassetteCat.iss` (`AppVersion`);
   - give the version's section in `CHANGELOG.md` its date, as `## [x.y.z] - YYYY-MM-DD`. The app's What's New sheet shows this section;
   - add a `<release>` entry at the top of `<releases>` in `packaging/linux/io.github.samyyy2311.CassetteCat.metainfo.xml`.
2. Merge it.
3. Tag the merge commit and push the tag:

   ```bash
   git switch main && git pull
   git tag vx.y.z
   git push origin vx.y.z
   ```

The tag starts `release.yml`, which:

- builds the Windows installer, portable zip and Microsoft Store package; the Linux AppImage, `.deb`, `.rpm`, `.tar.gz` and Flatpak for x86_64 and ARM64; and the universal macOS disk image;
- checks every package, writes an SPDX SBOM and `SHA256SUMS.txt`, and creates the GitHub release with all of them;
- updates the Windows Package Manager manifest using the `WINGET_TOKEN` secret in the `release` environment.

The workflow refuses to publish over a release that already exists. To publish an existing tag again, for example after fixing the workflow, delete the release on GitHub first, then run **Actions > Release > Run workflow** with the tag.

### After the workflow finishes

- Replace the generated release notes with the version's changelog section, so they read as a list of changes.
- Submit the `-store.msix` from the release to the Microsoft Store in Partner Center. The Store signs it on submission.
- The Flathub manifest lives in `packaging/flatpak`; update its source tag when a Flathub submission is open.
