// Stripes options. Steam has no options screen for custom screensavers, so edit this file
// and pick the screensaver again, or restart Steam.
//
// Warming stripes by Ed Hawkins, University of Reading, under CC BY 4.0.
// Colors sampled from showyourstripes.info and animated.

const STRIPES_CONFIG = {
    // Build in and build out: sweep, rise, scatter, fade, drop, flip, blinds, iris, mosaic,
    // warming or random. Random deals all ten styles before it repeats one.
    style: "sweep",
    exitStyle: "fade",

    // Seconds for the build in, and again for the build out, from 5 to 60.
    drawIn: 14,

    showLabel: true,

    // "systemMono", "system", or the name of any installed font family.
    labelFont: "systemMono",

    // From 12 to 72. The label is this many pixels tall on a 900-pixel-tall screen and
    // scales with the screen height.
    labelSize: 24,

    // Names as showyourstripes.info gives them: "Global", "Sweden", "Stockholm, Sweden".
    // Every name is listed at
    // https://github.com/gkaramanis/stripes-saver/blob/main/steam/LOCATIONS.md
    // The saver plays them Global first, then alphabetically, and loops.
    locations: ["Global"],
};
