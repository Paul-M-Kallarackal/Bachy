# Bachy brand assets

- `bachy-counterpoint.png`: the current abstract fugue emblem, ultramarine blue on an opaque white background.
- `bachy-browser.png`: an actual Bachy browser capture using disposable sample files, not a generated UI.

## Concept

The emblem draws on the interweaving voices of Bach's music. Broad ribbons cross and rise into an open, flame-like arch: a visual expression of harmony, movement and possibility. The inspiration is musical and abstract, with no portrait or literal musical notation.

Created and refined with the built-in imagegen tool on 26 September 2026. The approved PNG is preserved without raster post-processing. Reviewed in [Bachy's Paper design file](https://app.paper.design/file/01M3DNAMX5PQERN25GEWE1PN05/p-1-0), on the “Bachy — abstract fugue emblem” and “Settings — About Bachy” boards.

The matching vector rendition is [packaging/local.bachy.FileManager.svg](../../packaging/local.bachy.FileManager.svg). The Arch package installs this as the desktop icon named `local.bachy.FileManager`, matching the desktop entry and Quickshell AppId. Linux associates that installed icon with the application; it is not embedded in the ELF binary. [ui/BachyMark.qml](../../ui/BachyMark.qml) uses the same path data for About, empty folders and Bachy menu marks, tinted by the current theme. Its fade respects reduced motion. Runtime rendering was checked at 16, 24, 32, 64 and 240 px, alongside the packaged SVG and the real empty-folder component.

## Similarity check — 26 September 2026

This was a limited keyword and image-search review, not a reverse-image database match or trademark clearance. Queries covered “Bachy logo”, “blue three ribbons flame logo abstract”, “blue intertwined ribbons flame logo”, and “abstract ribbon flame logo three interwoven ribbons blue arch logo”. No identical mark was found in the results inspected; this does not establish that the mark is globally unique or unused.

Related motifs already exist. The [Interactiv’ Technologies blue mark](https://www.interactiv-technologies.com/fr/base-de-donnees-produits-pim/intelligence-artificielle-ia-dans-le-pim-dam-database/) uses separate tapered ribbons, while [LogoFolder’s Interlocked Flame Logo](https://logopond.com/LogoFolder/showcase/detail/318706) uses nested outlined loops. Both were visually inspected and differ from Bachy’s broad crossing ribbons, three rising tips and open base. [VectorStock also lists a flame-ribbon design from 2016](https://www.vectorstock.com/royalty-free-vector/logo-ribon-vector-11613925), confirming that the general motif predates this work. None of those images was used as a generation reference; the generation and refinement prompts below document the actual process.

## Generation prompt

Use case: logo-brand. Create a single beautiful abstract emblem for Bachy, a file manager inspired by Johann Sebastian Bach. Convey the feeling of a fugue: independent melodic voices, rigorous harmony, unfolding possibility, and uplifting movement. Three broad calligraphic ribbons rise, cross once with crisp negative-space separations, and curve into a poised open arch. A compact, surprising and memorable silhouette, subtle baroque movement distilled into modern Swiss graphic restraint. A symbol that feels quietly inspirational and intellectually alive. One solid deep ultramarine-blue ink on a pure white square background. Flat vector-like artwork with immaculate edges, large generous curves, strong optical balance and enough negative space to read at small size. Center the emblem, occupying 70 percent of the square. No text, no letters, no person, no face, no portrait, no wig, no bust, no photographic rendering, no musical notes, no treble clef, no folder, no infinity loop, no generic AI knot, no ornate filigree, no shadows, no gradients, no 3D, no mockup. Deliver only the finished emblem.

## Refinement prompt

Refine this logo for production. Preserve the exact abstract rising-ribbon emblem, its composition and deep ultramarine-blue color. Make every ribbon a perfectly FLAT solid blue fill; remove all speckled pixels, pale edge outlines, texture, gradients and uneven color. Use crisp smooth antialiased edges. Place it on a completely OPAQUE pure white #FFFFFF background across the entire square, including all the gaps between the ribbons. Do not use transparency. Keep all shapes and positions unchanged. No text or additional elements.
