# bionic-nix

Nix flake packaging of [LM Studio Bionic](https://lmstudio.ai/) — LM Studio's
agent for work and code — for Linux.

Upstream only ships a ~1.3 GB self-contained Electron AppImage, so this flake
wraps that AppImage with `appimageTools`, runs it inside an FHS environment, and
adds desktop integration (icons, `.desktop` entry, `bionic` on `PATH`).

## Install

From a local checkout of this repo:

```sh
nix profile add ./bionic-nix
```

Or straight from GitHub once hosted:

```sh
nix profile add github.com/<user>/bionic-nix
```

Then run `bionic`, or launch "Bionic" from your app launcher.

To try it without installing:

```sh
nix run ./bionic-nix
```

## Build locally

```sh
nix build .#default
./result/bin/bionic
```

## Development

The package derivation lives in [`default.nix`](./default.nix). Supported
platforms are `x86_64-linux` and `aarch64-linux`; versions and hashes are pinned
per platform in the `sources` attribute.

Bionic is unfree, so the flake enables `allowUnfreePredicate` for `bionic` only —
no global `allowUnfree` setting is needed.

Note that the upstream AppImage is ~1.3 GB and unpacks to ~3.5 GB in the store,
so expect a fairly large first build.

Run the smoke test with:

```sh
nix flake check
```

## Updating

1. Find the current Linux AppImage version:

   ```sh
   curl -fsIL -o /dev/null -w '%{url_effective}\n' https://lmstudio.ai/download/bionic/latest/linux/x64
   ```

2. Compute the hash of the new AppImage:

   ```sh
   nix-prefetch-url --type sha256 <url>
   # or, with nix-command:
   nix hash convert --hash-algo sha256 --to sri "$(nix-prefetch-url <url>)"
   ```

3. Update `version`, `url` and `hash` for each system in `default.nix`, then
   rebuild.

## Notes

- The app auto-updater is disabled in practice because the store is read-only;
  upgrade by updating this flake instead.
- Model weights and engines are downloaded by the app at runtime into the user's
  home directory, not into the Nix store.
- Bionic can use a running LM Studio install for local inference; see the
  [Bionic docs](https://lmstudio.ai/docs/bionic).
