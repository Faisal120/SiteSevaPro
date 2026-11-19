# SiteSeva Pro UI/UX Direction

## Product character

SiteSeva Pro should feel like a focused construction workspace: calm, technical,
and dependable. The application must make operational complexity feel ordered,
with the active task always obvious and secondary information kept quiet.

The visual direction is informed by the supplied dashboard references: a dark
application shell, subtle bordered surfaces, muted secondary text, concise
controls, and clear progress guidance. It is not a copy of another product's
identity, layout, assets, or branding.

## Colour system

| Token | Value | Use |
| --- | --- | --- |
| Workspace | `#090A0C` | Page and navigation shell |
| Surface | `#111214` | Cards, panels, dialogs |
| Surface raised | `#17191D` | Hover/active controls |
| Border | `#25272C` | Quiet panel separation |
| Primary text | `#F5F7FA` | Headings and key values |
| Secondary text | `#98A1AF` | Supporting copy and labels |
| Brand orange | `#F97316` | Primary action and credit emphasis |
| Success | `#22C55E` | Completed/ready state |
| Warning | `#F59E0B` | Attention-required state |

## Layout rules

- Keep the persistent sidebar visually quiet; the selected item is a soft,
  raised pill rather than a strong block of colour.
- Use a narrow top utility bar for search, account, help, and plan actions.
- Content starts with a concise title, one-sentence purpose, and one primary
  action. Do not repeat page titles in multiple cards.
- Use 16–20 px card radii, 1 px low-contrast borders, and minimal shadows.
- Use responsive grids: three columns on desktop, two on tablet, one on mobile.

## Design Studio workflow

1. **Brief** — user enters plot details, room requirements, and optional spaces.
2. **Generate** — show exactly what will be charged before submitting.
3. **Review** — show the responsive SVG plan, available credits, and a clear
   “another rough option” action. Each new 2D option consumes 10 credits.
4. **Technical drawings** — Electrical, Plumbing, Column, and Structural
   drawings unlock only after a base plan exists; each consumes 5 credits.
5. **Export** — users can download the active drawing as a scalable SVG.

## 2D drawing standard

- Base drawings are deterministic SVGs with one canonical layout model.
- Walls are unique physical segments; doors/windows create actual openings.
- Include plot dimensions, north marker, entrance gate, title block, and scale.
- When parking is included, show simple CAD-style car and bike symbols.
- Technical plans are overlays on the exact same floor-plan geometry.

## CAD PDF sheet standard

- Export drawings as A3 landscape PDF sheets with a 12 mm sheet border.
- Every sheet includes grid bubbles, plot dimensions, drawing title, revision,
  site/project details, notes and a title block.
- Floor sheets include entrance-gate and parking vehicle symbols when relevant.
- Electrical, plumbing, column, structural and foundation sheets use a legend
  and discipline-specific colour/symbol overlay on the base plan.
- Door/window sheets include a dedicated second-page schedule table.
- All generated PDFs must say `CONCEPTUAL DESIGN` and `NOT FOR CONSTRUCTION`
  until engineer-verified structural/member data is supplied.

## Copy style

- Be direct and transparent: “Another rough option · 10 credits”.
- Use sentence case and construction language users already know.
- Explain unavailable steps before users encounter an error.
- Never imply structural or statutory approval; generated plans are conceptual
  and need professional verification before construction.
