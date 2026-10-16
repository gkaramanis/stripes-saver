// Warming stripes for Steam. A port of macos/StripesView.swift; SPEC.md describes every
// style. Canvas y points down, so Rise, Drop, Mosaic and the label flip their vertical
// positions. Everything is drawn in device pixels.

const HOLD = 15;
const FPS = 30;
const MOSAIC_ROWS = 12;
const BLIND_SLATS = 20;
const STYLES = ['sweep', 'rise', 'scatter', 'fade', 'drop', 'flip', 'blinds', 'iris', 'mosaic', 'warming'];
const PALETTE_KEYS = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

// The official colours from coldest to warmest. Grey marks a year without data and sits
// in the middle, with any colour missing from this list.
const COLD_TO_WARM = [
    '001944', '08306b', '08519c', '2171b5', '4292c6', '6baed6', '9ecae1', 'c6dbef', 'deebf7',
    '7f7f7f',
    'fee0d2', 'fcbba1', 'fc9272', 'fb6a4a', 'ef3b2c', 'cb181d', 'a50f15', '67000d', '440007',
];

const FONT_STACKS = {
    systemMono: "'SF Mono', 'DejaVu Sans Mono', 'Noto Sans Mono', 'Liberation Mono', monospace",
    system: "'SF Pro Text', 'Noto Sans', 'DejaVu Sans', sans-serif",
};

const clamp = v => Math.min(1, Math.max(0, v));
const smooth = v => v * v * (3 - 2 * v);

function shuffled(list)
{
    const a = list.slice();
    for ( let i = a.length - 1; i > 0; i-- )
    {
        const j = Math.floor( Math.random() * ( i + 1 ) );
        [ a[i], a[j] ] = [ a[j], a[i] ];
    }
    return a;
}

function range(n)
{
    return Array.from( { length: n }, ( _, i ) => i );
}

// Deals styles for Random: every style once in a new order, never the same twice in a row.
class StyleDeck
{
    constructor()
    {
        this.bag = [];
        this.current = 'sweep';
    }

    next(chosen)
    {
        if ( chosen !== 'random' )
            return this.current = chosen;
        if ( this.bag.length === 0 )
        {
            this.bag = shuffled( STYLES );
            const last = this.bag.length - 1;
            if ( this.bag[last] === this.current )
                [ this.bag[0], this.bag[last] ] = [ this.bag[last], this.bag[0] ];
        }
        return this.current = this.bag.pop();
    }
}

// Global first, then by name the way Finder sorts.
function loadLocations(file)
{
    const list = file.locations.map( e => ({
        name: e.country === '' ? e.region : e.place === '' ? e.country : `${e.place}, ${e.country}`,
        firstYear: e.firstYear,
        stripes: Array.from( e.stripes, c => Math.max( 0, PALETTE_KEYS.indexOf( c ) ) ),
    }) );
    const collator = new Intl.Collator( undefined, { numeric: true, sensitivity: 'base' } );
    list.sort( ( a, b ) =>
    {
        if ( ( a.name === 'Global' ) !== ( b.name === 'Global' ) )
            return a.name === 'Global' ? -1 : 1;
        return collator.compare( a.name, b.name );
    } );
    return list;
}

function rgb(hex)
{
    const v = parseInt( hex, 16 );
    return [ ( v >> 16 ) & 0xff, ( v >> 8 ) & 0xff, v & 0xff ];
}

// The options from config.js, checked and clamped. Query parameters override them, so a
// browser can preview any style: index.html?style=mosaic&drawIn=5&t=3 freezes at 3 s.
function readSettings(config, query)
{
    const c = Object.assign( {}, config );
    for ( const key of [ 'style', 'exitStyle', 'drawIn', 'labelFont', 'labelSize', 'showLabel' ] )
        if ( query.has( key ) )
            c[key] = query.get( key );
    if ( query.has( 'locations' ) )
        c.locations = query.get( 'locations' ).split( '|' );

    const style = ( s, fallback ) => ( s === 'random' || STYLES.includes( s ) ) ? s : fallback;
    const number = ( v, fallback, lo, hi ) => Number.isFinite( Number( v ) ) ? Math.round( Math.min( hi, Math.max( lo, Number( v ) ) ) ) : fallback;
    return {
        style: style( c.style, 'sweep' ),
        exitStyle: style( c.exitStyle, 'fade' ),
        drawIn: number( c.drawIn, 14, 5, 60 ),
        showLabel: c.showLabel !== false && c.showLabel !== 'false',
        labelFont: typeof c.labelFont === 'string' && c.labelFont !== '' ? c.labelFont : 'systemMono',
        labelSize: number( c.labelSize, 24, 12, 72 ),
        locations: Array.isArray( c.locations ) ? c.locations : [ 'Global' ],
        freezeAt: query.has( 't' ) ? Number( query.get( 't' ) ) : null,
    };
}

class Stripes
{
    constructor(canvas, file, settings)
    {
        this.canvas = canvas;
        this.ctx = canvas.getContext( '2d', { alpha: false } );
        this.settings = settings;
        this.palette = file.palette.map( rgb );
        this.warmth = file.palette.map( hex =>
        {
            const i = COLD_TO_WARM.indexOf( hex );
            return i >= 0 ? i : Math.floor( COLD_TO_WARM.length / 2 );
        } );

        // The chosen locations in list order, or Global if none of the names exist.
        const all = loadLocations( file );
        const chosen = new Set( settings.locations );
        this.locations = all.filter( l => chosen.has( l.name ) );
        if ( this.locations.length === 0 )
            this.locations = all.slice( 0, 1 );

        this.decks = { in: new StyleDeck(), out: new StyleDeck() };
        this.index = 0;

        // Which corner holds the label: 0 bottom-left, then clockwise. Moves with each
        // location so no pixels show the same text every cycle.
        this.corner = 0;

        this.resize();
        window.addEventListener( 'resize', () => this.resize() );
        this.show( 0, performance.now() );
    }

    resize()
    {
        const dpr = window.devicePixelRatio || 1;
        this.canvas.width = Math.round( window.innerWidth * dpr );
        this.canvas.height = Math.round( window.innerHeight * dpr );
        this.dpr = dpr;
        this.drewStill = false;
    }

    show(i, now)
    {
        this.index = i % this.locations.length;
        this.start = now;
        this.drewStill = false;
        const loc = this.locations[this.index];
        const n = loc.stripes.length;
        this.order = shuffled( range( n ) );
        this.warmOrder = this.warmthRanks( loc.stripes );
        this.tileOrder = shuffled( range( n * MOSAIC_ROWS ) );
        this.styleIn = this.decks.in.next( this.settings.style );
        this.styleOut = this.decks.out.next( this.settings.exitStyle );
        this.corner = ( this.corner + 1 ) % 4;
    }

    // Each year's rank from coldest to warmest; years of the same colour go left to right.
    warmthRanks(stripes)
    {
        const sorted = range( stripes.length ).sort( ( a, b ) =>
            ( this.warmth[stripes[a]] - this.warmth[stripes[b]] ) || ( a - b ) );
        const rank = new Array( stripes.length );
        sorted.forEach( ( i, r ) => { rank[i] = r; } );
        return rank;
    }

    frame(now)
    {
        const duration = this.settings.drawIn;
        let t = Math.max( 0, ( now - this.start ) / 1000 );
        if ( t > duration + HOLD + duration )
        {
            this.show( this.index + 1, now );
            t = 0;
        }

        // During the hold nothing moves, so draw its first frame and skip the rest.
        const still = t >= duration && t <= duration + HOLD;
        if ( still && this.drewStill )
            return;
        this.drewStill = still;
        this.draw( t );
    }

    draw(t)
    {
        const ctx = this.ctx;
        const W = this.canvas.width, H = this.canvas.height;
        const duration = this.settings.drawIn;
        ctx.globalAlpha = 1;
        ctx.fillStyle = '#000';
        ctx.fillRect( 0, 0, W, H );

        const loc = this.locations[this.index];
        const n = loc.stripes.length;
        const building = t < duration + HOLD;

        if ( building )
        {
            this.paint( loc, this.styleIn, Math.min( 1, t / duration ), false );
        }
        else
        {
            // The build out replays its style in black over the finished picture.
            const e = Math.min( 1, ( t - duration - HOLD ) / duration );
            this.paint( loc, 'fade', 1, false );
            this.paint( loc, this.styleOut, e, true );
        }

        if ( !this.settings.showLabel )
            return;
        if ( building )
        {
            const p = Math.min( 1, t / duration );
            let lead = n;
            if ( this.styleIn === 'sweep' )
                lead = p * n;
            else if ( [ 'rise', 'drop', 'flip' ].includes( this.styleIn ) )
                lead = p * ( n + this.wave( this.styleIn, n ) );
            this.drawLabel( loc, loc.firstYear + Math.max( 0, Math.min( n, Math.ceil( lead ) ) - 1 ), 1 );
        }
        else
        {
            const e = Math.min( 1, ( t - duration - HOLD ) / duration );
            this.drawLabel( loc, loc.firstYear + n - 1, 1 - smooth( e ) );
        }
    }

    // How many stripes are in motion at once, for the styles that move across the screen.
    wave(style, n)
    {
        switch ( style )
        {
            case 'rise': return Math.max( 1, n / 4 );
            case 'drop': return Math.max( 1, n / 14 );
            case 'flip': return Math.max( 1, n / 8 );
            default: return Math.max( 1, n / 20 );
        }
    }

    colour(index, erase, darken)
    {
        if ( erase )
            return 'rgb(0,0,0)';
        const k = 1 - darken;
        const [ r, g, b ] = this.palette[index];
        return `rgb(${r * k},${g * k},${b * k})`;
    }

    fill(x, y, w, h, colour, alpha)
    {
        if ( alpha <= 0 || w <= 0 || h <= 0 )
            return;
        this.ctx.globalAlpha = alpha;
        this.ctx.fillStyle = colour;
        this.ctx.fillRect( x, y, w, h );
    }

    // Draws a location at progress p through a style. When erasing, the same motion paints black.
    paint(loc, style, p, erase)
    {
        const ctx = this.ctx;
        const W = this.canvas.width, H = this.canvas.height;
        const n = loc.stripes.length;
        const width = W / n;
        const wave = this.wave( style, n );

        // Progress of stripe x through its own part of a left-to-right wave.
        const waveAt = x => clamp( ( p * ( n + wave ) - x ) / wave );

        if ( style === 'blinds' )
        {
            this.drawBlinds( loc, p, erase );
            ctx.globalAlpha = 1;
            return;
        }

        if ( style === 'iris' )
        {
            const r = smooth( p ) * Math.hypot( W, H ) / 2;
            ctx.save();
            ctx.beginPath();
            ctx.arc( W / 2, H / 2, Math.max( 0, r ), 0, 2 * Math.PI );
            ctx.clip();
        }

        for ( let i = 0; i < n; i++ )
        {
            const c = this.colour( loc.stripes[i], erase, 0 );

            // Round edges to whole pixels so neighbouring stripes don't leave seams.
            const x0 = Math.round( i * width );
            const x1 = Math.round( ( i + 1 ) * width );

            switch ( style )
            {
                case 'sweep':
                    this.fill( x0, 0, x1 - x0, H, c, clamp( p * n - i ) );
                    break;
                case 'rise':
                {
                    const h = Math.round( H * smooth( waveAt( i ) ) );
                    this.fill( x0, H - h, x1 - x0, h, c, 1 );
                    break;
                }
                case 'scatter':
                    this.fill( x0, 0, x1 - x0, H, c, clamp( ( p * ( n + wave ) - this.order[i] ) / wave ) );
                    break;
                case 'warming':
                    this.fill( x0, 0, x1 - x0, H, c, clamp( ( p * ( n + wave ) - this.warmOrder[i] ) / wave ) );
                    break;
                case 'fade':
                    this.fill( x0, 0, x1 - x0, H, c, smooth( p ) );
                    break;
                case 'iris':
                    this.fill( x0, 0, x1 - x0, H, c, p > 0 ? 1 : 0 );
                    break;
                case 'drop':
                {
                    const q = waveAt( i );
                    if ( q <= 0 )
                        break;
                    this.fill( x0, -Math.round( H * ( 1 - dropFall( q ) ) ), x1 - x0, H, c, 1 );
                    break;
                }
                case 'flip':
                {
                    // The stripe turns about its centre line, darker while it is edge-on.
                    const q = smooth( waveAt( i ) );
                    const w = ( x1 - x0 ) * q;
                    this.fill( ( x0 + x1 - w ) / 2, 0, w, H, this.colour( loc.stripes[i], erase, 0.6 * ( 1 - q ) ), 1 );
                    break;
                }
                case 'mosaic':
                {
                    const cells = n * MOSAIC_ROWS;
                    const tile = H / MOSAIC_ROWS;
                    for ( let row = 0; row < MOSAIC_ROWS; row++ )
                    {
                        const rank = this.tileOrder[i * MOSAIC_ROWS + row];
                        const a = clamp( ( p * ( cells + cells / 20 ) - rank ) / ( cells / 20 ) );
                        const y0 = Math.round( row * tile );
                        const y1 = Math.round( ( row + 1 ) * tile );
                        this.fill( x0, H - y1, x1 - x0, y1 - y0, c, a );
                    }
                    break;
                }
            }
        }

        if ( style === 'iris' )
            ctx.restore();
        ctx.globalAlpha = 1;
    }

    // Keynote's Blinds: vertical slats swing from edge-on to face the viewer, in perspective.
    // Rotation about a vertical axis keeps vertical lines vertical, so each stripe's part
    // of a slat projects to a quadrilateral with vertical sides.
    drawBlinds(loc, p, erase)
    {
        const ctx = this.ctx;
        const W = this.canvas.width, H = this.canvas.height;
        const n = loc.stripes.length;
        const slat = W / BLIND_SLATS;
        const stripe = W / n;
        const focal = H;
        ctx.globalAlpha = 1;

        for ( let k = 0; k < BLIND_SLATS; k++ )
        {
            // Each slat turns in 30% of the draw-in time; start times spread over the rest.
            const q = smooth( clamp( ( p - 0.7 * k / ( BLIND_SLATS - 1 ) ) / 0.3 ) );
            if ( q <= 0 )
                continue;
            const angle = ( 1 - q ) * Math.PI / 2;
            const cosA = Math.cos( angle ), sinA = Math.sin( angle );
            const left = k * slat;
            const centre = left + slat / 2;

            // Screen x and half-height of the slat's vertical line that sits at x when flat.
            const project = x =>
            {
                const u = x - centre;
                const scale = focal / ( focal + u * sinA );
                return { x: centre + u * cosA * scale, half: H / 2 * scale };
            };

            const first = Math.max( 0, Math.floor( left / stripe ) );
            const last = Math.min( n - 1, Math.floor( ( left + slat ) / stripe ) );
            for ( let i = first; i <= last; i++ )
            {
                const x0 = Math.max( left, i * stripe );
                const x1 = Math.min( left + slat, ( i + 1 ) * stripe );
                if ( x1 <= x0 )
                    continue;
                const a = project( x0 ), b = project( x1 );

                // Overlap the next quad by half a pixel so antialiasing leaves no seams.
                const bx = b.x + 0.5;
                ctx.beginPath();
                ctx.moveTo( a.x, H / 2 - a.half );
                ctx.lineTo( bx, H / 2 - b.half );
                ctx.lineTo( bx, H / 2 + b.half );
                ctx.lineTo( a.x, H / 2 + a.half );
                ctx.closePath();
                ctx.fillStyle = this.colour( loc.stripes[i], erase, 0.6 * ( 1 - q ) );
                ctx.fill();
            }
        }
    }

    drawLabel(loc, year, alpha)
    {
        const ctx = this.ctx;
        const W = this.canvas.width, H = this.canvas.height;
        const size = Math.max( 10, this.settings.labelSize * window.innerHeight / 900 ) * this.dpr;
        const family = this.settings.labelFont;
        const stack = FONT_STACKS[family] || `'${family.replace( /'/g, '' )}', ${FONT_STACKS.systemMono}`;

        ctx.save();
        ctx.font = `500 ${size}px ${stack}`;
        ctx.textBaseline = 'alphabetic';
        ctx.fillStyle = `rgba(255,255,255,${0.75 * alpha})`;
        ctx.shadowColor = 'rgba(0,0,0,0.5)';
        ctx.shadowBlur = size / 4;

        const text = `${loc.name}  ${loc.firstYear}–${year}`;
        const m = ctx.measureText( text );
        const ascent = m.fontBoundingBoxAscent ?? size * 0.95;
        const descent = m.fontBoundingBoxDescent ?? size * 0.25;
        const margin = size * 1.5;
        const left = margin, right = W - margin - m.width;
        const top = margin + ascent, bottom = H - margin - descent;
        const origins = [ [ left, bottom ], [ left, top ], [ right, top ], [ right, bottom ] ];
        const [ x, y ] = origins[this.corner];
        ctx.fillText( text, x, y );
        ctx.restore();
    }
}

// Position of a dropped stripe: a fall under gravity, then two quick, low bounces whose
// durations follow from their heights.
function dropFall(t)
{
    const h1 = 0.06, h2 = 0.015;
    const b1 = 2 * Math.sqrt( h1 ), b2 = 2 * Math.sqrt( h2 );
    let u = t * ( 1 + b1 + b2 );
    if ( u < 1 )
        return u * u;
    u -= 1;
    if ( u < b1 )
    {
        const v = u - b1 / 2;
        return 1 - ( h1 - v * v );
    }
    u -= b1;
    if ( u < b2 )
    {
        const v = u - b2 / 2;
        return 1 - ( h2 - v * v );
    }
    return 1;
}

function Init()
{
    const settings = readSettings( typeof STRIPES_CONFIG === 'object' ? STRIPES_CONFIG : {}, new URLSearchParams( window.location.search ) );
    const saver = new Stripes( document.getElementById( 'stripes' ), STRIPES, settings );

    if ( settings.freezeAt !== null )
    {
        saver.draw( settings.freezeAt );
        return;
    }

    let last = -Infinity;
    const run = now =>
    {
        requestAnimationFrame( run );
        if ( now - last < 1000 / FPS - 2 )
            return;
        last = now;
        saver.frame( now );
    };
    requestAnimationFrame( run );
}

Init();
