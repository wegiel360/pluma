---
name: Liquid Glass
colors:
  surface: '#061700'
  surface-dim: '#061700'
  surface-bright: '#2b3e1d'
  surface-container-lowest: '#041100'
  surface-container-low: '#0e2003'
  surface-container: '#122406'
  surface-container-high: '#1c2f0f'
  surface-container-highest: '#273a19'
  on-surface: '#d2eabb'
  on-surface-variant: '#d9c2b0'
  inverse-surface: '#d2eabb'
  inverse-on-surface: '#223515'
  outline: '#a18d7c'
  outline-variant: '#534436'
  surface-tint: '#ffb870'
  primary: '#ffb870'
  on-primary: '#4a2800'
  primary-container: '#c28341'
  on-primary-container: '#402300'
  inverse-primary: '#875212'
  secondary: '#67dac2'
  on-secondary: '#00382f'
  secondary-container: '#20a28c'
  on-secondary-container: '#003028'
  tertiary: '#92cfea'
  on-tertiary: '#003545'
  tertiary-container: '#5b99b2'
  on-tertiary-container: '#002e3c'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdcbe'
  primary-fixed-dim: '#ffb870'
  on-primary-fixed: '#2c1600'
  on-primary-fixed-variant: '#693c00'
  secondary-fixed: '#84f6dd'
  secondary-fixed-dim: '#67dac2'
  on-secondary-fixed: '#00201a'
  on-secondary-fixed-variant: '#005144'
  tertiary-fixed: '#bbe9ff'
  tertiary-fixed-dim: '#92cfea'
  on-tertiary-fixed: '#001f29'
  on-tertiary-fixed-variant: '#004d63'
  background: '#061700'
  on-background: '#d2eabb'
  surface-variant: '#273a19'
  neon-active: '#98FF98'
  surface-glass: rgba(6, 23, 0, 0.45)
  border-glass: rgba(255, 184, 112, 0.15)
  iridescent-gradient: linear-gradient(135deg, rgba(255,184,112,0.2) 0%, rgba(103,218,194,0.2)
    50%, rgba(146,207,234,0.2) 100%)
typography:
  headline-lg:
    fontFamily: Ubuntu
    fontSize: 24px
    fontWeight: '500'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Ubuntu
    fontSize: 16px
    fontWeight: '500'
    lineHeight: '1.4'
  body-md:
    fontFamily: Ubuntu
    fontSize: 14px
    fontWeight: '300'
    lineHeight: '1.6'
  body-sm:
    fontFamily: Ubuntu
    fontSize: 12px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Ubuntu
    fontSize: 10px
    fontWeight: '700'
    lineHeight: '1'
    letterSpacing: 0.15em
  label-mono:
    fontFamily: Ubuntu Mono
    fontSize: 9px
    fontWeight: '400'
    lineHeight: '1'
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  sidebar-width: 72px
  conversation-list-width: 320px
  margin-desktop: 32px
  gutter: 16px
  padding-card: 24px
  padding-input: 14px 24px
---

## Brand & Style

Liquid Glass is a premium, immersive design system that blends futuristic high-tech aesthetics with organic, ethereal elements. It evokes a sense of depth, clarity, and "digital luxury" by utilizing layered translucency and light-refracting surfaces.

The visual style is a hybrid of **Glassmorphism** and **Retro-Futurism**. It relies heavily on ultra-blurred backdrops, iridescent borders, and subtle neon accents. The goal is to provide a focused, calm workspace that feels like a physical piece of illuminated glass hovering over a natural landscape.

## Colors

The palette is built on a deep, mossy-green neutral base (`#061700`) which provides the high-contrast foundation for "glowing" elements. 

- **Primary (Amber/Gold):** Used for active states, key actions, and branding highlights. It represents warmth and energy.
- **Secondary & Tertiary (Teal/Sky):** Used for iridescent effects and supporting accents to create a multi-chromatic "liquid" feel.
- **Neon-Active (Mint):** A specialized status color used exclusively for online indicators and high-priority focus rings.
- **Glass Surfaces:** Colors are rarely opaque; they are derived from the surface-dim base with varying levels of alpha transparency (45-60%) to allow background textures to bleed through.

## Typography

The system uses **Ubuntu** for its soft, rounded geometry which complements the pill-shaped UI elements. 

- **Headlines:** Use Medium weights with tight tracking for a modern, tech-centric look.
- **Body:** Primarily utilizes the Light (300) weight to maintain the "airy" feel of the glass interface, ensuring the text doesn't feel too heavy on translucent backgrounds.
- **Micro-copy:** Employs **Ubuntu Mono** for timestamps and technical metadata to inject a subtle "coded" aesthetic. 
- **Navigation:** Vertical navigation and section headers use an uppercase, high-tracking label style for maximum structural clarity.

## Layout & Spacing

The layout follows a **Hybrid Modular Rail** system. 
- **Primary Nav:** A fixed 72px rail on the far left.
- **Main Canvas:** A generous 32px padding surrounds the primary application container, creating a "frame" effect that shows the blurred background.
- **Inner Content:** The main application container uses a multi-pane layout (sidebar + chat) with internal 24px-40px padding to maintain an open, uncluttered feel.
- **Mobile Adaption:** On mobile, the navigation rail moves to a bottom bar, and the 32px outer margin is reduced to 16px or removed entirely to maximize screen real estate, while maintaining the ultra-glass effect.

## Elevation & Depth

Depth is conveyed through **Backdrop Blur** and **Light Injection** rather than traditional shadows.

- **Level 1 (Background):** A high-saturation, high-detail image with a 4px blur and a 30% dark overlay.
- **Level 2 (Glass Rails):** 32px backdrop blur with a 1px solid border at 15% opacity.
- **Level 3 (Main Container):** 40px backdrop blur with an **iridescent border** (multi-color gradient mask). This is the highest level of hierarchy.
- **Level 4 (Popovers/Tooltips):** Solid background or high-opacity glass with `shadow-lg` to create a physical lift above the glass canvas.

## Shapes

The system is defined by extreme roundedness. 
- **Containers:** Large main containers use a 2.5rem (`40px`) radius.
- **Standard Elements:** Buttons and message bubbles use "Pill-shaped" logic (fully rounded ends) or a minimum of 1rem (`16px`) radius.
- **Interactive States:** Hovering over square-ish icons (like in the nav rail) should transition them toward rounded-xl (`12px`) shapes.
- **Avatars:** Strictly circular, often featuring a 2px "neon glow" ring when active.

## Components

- **Buttons:** 
    - *Primary:* Fully opaque primary color with dark text. 
    - *Ghost:* Transparent with primary/secondary border.
    - *FAB:* Large circular buttons with high-intensity colored shadows (`shadow-primary/30`).
- **Input Fields:** Search and chat inputs are fully pill-shaped with a 20% surface-container fill and 20% border opacity. On focus, they gain a subtle 1px ring.
- **Message Bubbles:** 
    - *Incoming:* Low-opacity white/surface-high glass with 1px border. 
    - *Outgoing:* 20% Primary color tint with 20% Primary border. Both use asymmetric rounding (one corner sharp).
- **Navigation Rail:** Icons use a transition from `on-surface-variant` to `primary`. Active states are marked with a thick 4px vertical bar on the left edge.
- **Scrollbars:** Custom ultra-thin (4px) tracks with 30% primary color thumbs to remain unobtrusive.