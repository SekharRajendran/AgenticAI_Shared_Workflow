# Publish this folder to GitHub

## Before creating the remote

1. Read `DISTRIBUTION_NOTICE.md`.
2. Confirm that the Word specification, PDF, S-parameter data, EM data, and precomputed waveform files may be shared with the intended audience.
3. Create an empty **private** GitHub repository. Do not initialize it with a README, license, or `.gitignore`; this folder already supplies them.

## Initialize and publish

Run these commands from this folder after Git is installed:

```powershell
git init
git add .
git status
git commit -m "Initial Antenna-to-Bits workflow"
git branch -M main
git remote add origin https://github.com/<organization-or-user>/<repository>.git
git push -u origin main
```

Review `git status` before committing. The required specification, models, helper data, and result examples should appear; `slprj/`, `.slxc`, editor backups, and ZIP distributions should not.

## Large binary files

The included `.slx`, `.mat`, `.mlx`, PDF, and Word files are intentionally versioned as binary artifacts. GitHub rejects individual files larger than 100 MB. If a future asset approaches that limit or clone performance becomes poor, migrate only the large data assets to Git LFS:

```powershell
git lfs install
git lfs track "*.mat" "*.slx" "*.mlx"
git add .gitattributes
```

Do not enable LFS unless the repository owner accepts its storage and bandwidth policy.

## Contribution workflow

1. Create a branch for one focused change.
2. Run `StartHere` and the affected MATLAB workflow.
3. Include source-script changes alongside any changed model/data artifact.
4. Do not commit generated caches or distribution ZIP files.
5. Open a pull request using the supplied template.
