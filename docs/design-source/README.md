# Sumber reka bentuk

Salinan fail sumber daripada claude.ai pada 26 Nov 2026. Salinan hidup di claude.ai ialah rujukan utama; folder ini hanya sandaran untuk sesiapa yang tiada akses.

## `slides/`

- `deck.json`: susunan 10 slaid. `deck.css`: gaya dikongsi. `slides/*.html`: satu fail bagi setiap slaid (1920×1080).
- Gambar dalam slaid merujuk storan dek (`/_blob/...`). Padanannya:

| Rujukan dalam slaid | Fail |
| --- | --- |
| `/_blob/f5924f6db8c871249ae155232c1b2a68` | `screens/skrin-peta-daerah.png` |
| `/_blob/298f326ac573499b545120b7dd44cee8` | `screens/skrin-butiran-lot.png` |
| `/_blob/10fced2c92d20c508a8ee0eba4195c1e` | `screens/skrin-kerja-saya.png` |
| `/_blob/95ac1246a6835bd727b4c520aed4e858` | `screens/skrin-amaran-penyelia.png` |

## `ui/`

Tujuh skrin 390×844 dalam format kanvas reka bentuk (`*.dc.html`). `canvas.json` menyenaraikan susunan: Peta daerah, Butiran lot, Kerja saya, Peta lot dan geofencing, Gambar di pos tetap, Semak dan hantar, Amaran kepada penyelia. Markup di dalam `<x-dc>` ialah HTML biasa dengan gaya sebaris.
