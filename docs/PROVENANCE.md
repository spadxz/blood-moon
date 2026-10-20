# Project provenance and licensing

The product is named **Scarlett**. This repository is a public fork of the
original [Swiftify project](https://github.com/shredos67/swiftify), and GitHub
retains that fork relationship after the repository rename. Scarlett-specific
changes are maintained here; the upstream project remains separately
maintained by its author.

## License status

As checked on 2026-10-20, neither this fork nor its upstream repository contains
a `LICENSE` file, and GitHub reports no detected license for the upstream
repository. Public visibility and GitHub's ability to view or fork a repository
do not grant a general license to reuse, redistribute, or relicense its code.
For that reason this fork does not add a license on behalf of the upstream
author and cannot currently be described as legally open source. A license from
the upstream copyright holder, or a clean reimplementation of the unlicensed
parts, is needed before the whole application can be distributed as an
open-source project.

This note is a project-status disclosure, not legal advice. Do not assume that
the absence of a license grants reuse rights.

## Rename and existing data

The executable, QML module URI, build targets, and packaged resources use
Scarlett identifiers. On first launch, Scarlett copies settings, migrates the
existing data and cache folders, and transfers saved Spotify credentials to
the new app identity. The original settings and credential records are kept.
