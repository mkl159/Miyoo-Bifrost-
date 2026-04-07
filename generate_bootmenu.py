#!/usr/bin/env python3
"""
Generateur d'images de boot menu pour Miyoo Mini Plus Dual Boot
Cree pour chaque langue (FR/EN/ES) :
  - bootmenu_onion_{LANG}.raw    : OnionOS selectionne
  - bootmenu_telmios_{LANG}.raw  : TelmiOS selectionne
  - bootmenu_locked_onion_{LANG}.raw   : ecran protege (OnionOS)
  - bootmenu_locked_telmios_{LANG}.raw : ecran protege (TelmiOS)

Prerequis : pip install Pillow
"""

import sys
import os

try:
    from PIL import Image, ImageDraw, ImageFont
    print("OK Pillow detecte")
except ImportError:
    print("ERREUR: Pillow n'est pas installe.")
    print("Installez-le avec : pip install Pillow")
    sys.exit(1)

# ── Constantes ────────────────────────────────────────────────
W, H = 640, 480
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# Palette couleurs
C_BG_TOP    = (10,  12,  20)
C_BG_BOT    = (20,  25,  40)
C_ONION_ACC = (100, 220, 100)
C_TELMI_ACC = (255, 165,  50)
C_WHITE     = (240, 242, 255)
C_GRAY      = (130, 140, 165)
C_DIM       = ( 60,  70,  95)
C_DIVIDER   = ( 40,  50,  75)

# ── Textes multilingues ────────────────────────────────────────
LANGUAGES = {
    "FR": {
        "subtitle":           "DUAL BOOT SELECTOR",
        "selected_badge":     "◀  SELECTIONNE  ▶",
        "panel_onion_lines": [
            "Retrogaming & Emulation",
            "Emulateurs multi-systemes",
            "Themes & personnalisation",
            "Wi-Fi & netplay",
        ],
        "panel_telmios_lines": [
            "Histoires & Contes",
            "Contenu pour enfants",
            "Lecteur de recits",
            "Interface simplifiee",
        ],
        "icon_sel":    "> Appuyer A pour lancer",
        "icon_nosel":  "< D-pad pour choisir",
        "help": [("< >", "Choisir l'OS"), ("A", "Confirmer"), ("B", "Dernier choix")],
        "footer":      "Dernier OS choisi relance automatiquement si B est presse",
        "locked_title":  "ACCES PROTEGE",
        "locked_sub":    "Entrez le code secret",
        "locked_cancel": "B = Annuler",
        "locked_hint":   "Entrez la combinaison de touches configuree",
    },
    "EN": {
        "subtitle":           "DUAL BOOT SELECTOR",
        "selected_badge":     "◀  SELECTED  ▶",
        "panel_onion_lines": [
            "Retrogaming & Emulation",
            "Multi-system Emulators",
            "Themes & Customization",
            "Wi-Fi & Netplay",
        ],
        "panel_telmios_lines": [
            "Stories & Tales",
            "Child-friendly Content",
            "Story Reader",
            "Simple Interface",
        ],
        "icon_sel":    "> Press A to launch",
        "icon_nosel":  "< D-pad to choose",
        "help": [("< >", "Choose OS"), ("A", "Confirm"), ("B", "Last choice")],
        "footer":      "Last chosen OS will auto-boot if B is pressed",
        "locked_title":  "PROTECTED ACCESS",
        "locked_sub":    "Enter the secret code",
        "locked_cancel": "B = Cancel",
        "locked_hint":   "Enter the configured button combination",
    },
    "ES": {
        "subtitle":           "DUAL BOOT SELECTOR",
        "selected_badge":     "◀  SELECCIONADO  ▶",
        "panel_onion_lines": [
            "Retrogaming & Emulacion",
            "Emuladores multi-sistema",
            "Temas & personalizacion",
            "Wi-Fi & netplay",
        ],
        "panel_telmios_lines": [
            "Historias & Cuentos",
            "Contenido para ninos",
            "Lector de relatos",
            "Interfaz simplificada",
        ],
        "icon_sel":    "> Pulsar A para iniciar",
        "icon_nosel":  "< D-pad para elegir",
        "help": [("< >", "Elegir OS"), ("A", "Confirmar"), ("B", "Ultima eleccion")],
        "footer":      "El ultimo OS elegido arrancara automaticamente si se pulsa B",
        "locked_title":  "ACCESO PROTEGIDO",
        "locked_sub":    "Introduce el codigo secreto",
        "locked_cancel": "B = Cancelar",
        "locked_hint":   "Introduce la combinacion de botones configurada",
    },
}

# ── Helpers dessin ────────────────────────────────────────────

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def draw_gradient_rect(draw, x0, y0, x1, y1, c_top, c_bot):
    height = y1 - y0
    for y in range(height):
        t = y / max(height - 1, 1)
        color = lerp_color(c_top, c_bot, t)
        draw.line([(x0, y0 + y), (x1, y0 + y)], fill=color)

def draw_rounded_rect(draw, x0, y0, x1, y1, radius, fill, outline=None, outline_width=2):
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill,
                            outline=outline, width=outline_width)

def get_font(size, bold=False):
    font_paths = []
    if sys.platform == "win32":
        win_fonts = os.path.join(os.environ.get("WINDIR", "C:/Windows"), "Fonts")
        if bold:
            font_paths = [
                os.path.join(win_fonts, "arialbd.ttf"),
                os.path.join(win_fonts, "calibrib.ttf"),
                os.path.join(win_fonts, "segoeuib.ttf"),
            ]
        else:
            font_paths = [
                os.path.join(win_fonts, "arial.ttf"),
                os.path.join(win_fonts, "calibri.ttf"),
                os.path.join(win_fonts, "segoeui.ttf"),
            ]
    for path in font_paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()

def text_center(draw, text, y, font, color, width=W):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (width - tw) // 2
    draw.text((x, y), text, font=font, fill=color)
    return tw

# ── Createur menu principal ────────────────────────────────────

def create_bootmenu(selected_os: str, lang: str = "FR") -> Image.Image:
    ld = LANGUAGES.get(lang, LANGUAGES["FR"])

    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img, "RGBA")

    # Fond degrade global
    draw_gradient_rect(draw, 0, 0, W, H, C_BG_TOP, C_BG_BOT)

    # Barre titre
    TITLE_H = 72
    draw_gradient_rect(draw, 0, 0, W, TITLE_H, (15, 18, 32), (12, 15, 28))
    for i, alpha in enumerate([60, 120, 60, 30]):
        draw.line([(0, TITLE_H - 2 + i), (W, TITLE_H - 2 + i)],
                  fill=(80, 120, 200, alpha))

    font_title = get_font(28, bold=True)
    font_sub   = get_font(13)
    font_big   = get_font(32, bold=True)
    font_badge = get_font(11, bold=True)
    font_small = get_font(13)
    font_hint  = get_font(12)
    font_info  = get_font(10)

    text_center(draw, "MIYOO MINI+", 10, font_title, C_WHITE)
    text_center(draw, ld["subtitle"], 44, font_sub, C_GRAY)

    # Zone centrale
    PANEL_TOP  = TITLE_H + 18
    PANEL_BOT  = H - 68
    PANEL_MID  = W // 2
    PADDING    = 16
    RADIUS     = 14

    # Divider
    for xi in range(PANEL_MID - 1, PANEL_MID + 2):
        draw.line([(xi, PANEL_TOP), (xi, PANEL_BOT)], fill=C_DIVIDER)

    panels = [
        {
            "id":     "onion",
            "x0":     PADDING,
            "x1":     PANEL_MID - PADDING // 2,
            "accent": C_ONION_ACC,
            "title":  "OnionOS",
            "ver":    "v4.3.1",
            "lines":  ld["panel_onion_lines"],
        },
        {
            "id":     "telmios",
            "x0":     PANEL_MID + PADDING // 2,
            "x1":     W - PADDING,
            "accent": C_TELMI_ACC,
            "title":  "TelmiOS",
            "ver":    "v1.10.1",
            "lines":  ld["panel_telmios_lines"],
        },
    ]

    for panel in panels:
        x0, x1 = panel["x0"], panel["x1"]
        accent  = panel["accent"]
        is_sel  = (panel["id"] == selected_os)

        panel_fill = (28, 35, 55) if is_sel else (18, 22, 38)
        draw_rounded_rect(draw, x0, PANEL_TOP, x1, PANEL_BOT, RADIUS, panel_fill)

        if is_sel:
            for bw in range(3, 0, -1):
                alpha = 220 if bw == 1 else (120 if bw == 2 else 50)
                draw.rounded_rectangle(
                    [x0 + (3 - bw), PANEL_TOP + (3 - bw),
                     x1 - (3 - bw), PANEL_BOT - (3 - bw)],
                    radius=RADIUS, outline=(*accent, alpha), width=bw)
        else:
            draw.rounded_rectangle([x0, PANEL_TOP, x1, PANEL_BOT],
                radius=RADIUS, outline=(*C_DIM, 180), width=1)

        cx = (x0 + x1) // 2

        # Bandeau accent haut
        draw.rounded_rectangle(
            [x0 + 4, PANEL_TOP + 4, x1 - 4, PANEL_TOP + 10],
            radius=3, fill=(*accent, 200 if is_sel else 100))

        # Badge "SELECTIONNE"
        if is_sel:
            sel_y = PANEL_TOP + 14
            badge_text = ld["selected_badge"]
            bbox_b = draw.textbbox((0, 0), badge_text, font=font_badge)
            bw_half = (bbox_b[2] - bbox_b[0]) // 2 + 12
            draw_rounded_rect(draw, cx - bw_half, sel_y, cx + bw_half, sel_y + 20,
                              6, (*accent, 40), (*accent, 200), 1)
            bw_txt = bbox_b[2] - bbox_b[0]
            draw.text((cx - bw_txt // 2, sel_y + 4), badge_text,
                      font=font_badge, fill=accent)

        # Nom OS
        title_y  = PANEL_TOP + 40
        font_os  = get_font(26, bold=True)
        bbox_t   = draw.textbbox((0, 0), panel["title"], font=font_os)
        tw       = bbox_t[2] - bbox_t[0]
        title_color = C_WHITE if is_sel else lerp_color(C_WHITE, C_DIM, 0.4)
        draw.text((cx - tw // 2, title_y), panel["title"], font=font_os, fill=title_color)

        # Version
        ver_y   = title_y + 34
        font_ver = get_font(12)
        bbox_v  = draw.textbbox((0, 0), panel["ver"], font=font_ver)
        vw      = bbox_v[2] - bbox_v[0]
        draw.text((cx - vw // 2, ver_y), panel["ver"],
                  font=font_ver, fill=(*accent, 200 if is_sel else 100))

        # Separateur
        line_y = ver_y + 20
        draw.line([(x0 + 20, line_y), (x1 - 20, line_y)],
                  fill=(*accent, 80 if is_sel else 40))

        # Lignes description
        desc_y = line_y + 10
        for i, line in enumerate(panel["lines"]):
            line_color = C_WHITE if is_sel else C_DIM
            alpha_mult = 1.0 if is_sel else 0.6
            dot_color  = accent if is_sel else lerp_color(accent, C_DIM, 0.6)
            font_line  = get_font(13, bold=(i == 0))
            dot_x = x0 + 28
            draw.ellipse([dot_x - 3, desc_y + 5, dot_x + 3, desc_y + 11],
                         fill=(*dot_color, int(200 * alpha_mult)))
            draw.text((dot_x + 10, desc_y), line, font=font_line,
                      fill=(*line_color, int(220 * alpha_mult)))
            desc_y += 24

        # Indicateur bas
        status_y  = PANEL_BOT - 36
        draw.line([(x0 + 20, status_y - 5), (x1 - 20, status_y - 5)],
                  fill=(*accent, 40 if is_sel else 20))
        icon_text = ld["icon_sel"] if is_sel else ld["icon_nosel"]
        font_icon = get_font(11)
        bbox_i    = draw.textbbox((0, 0), icon_text, font=font_icon)
        iw        = bbox_i[2] - bbox_i[0]
        draw.text((cx - iw // 2, status_y), icon_text, font=font_icon,
                  fill=(*accent, 200) if is_sel else (*C_DIM, 160))

    # Barre aide bas
    HELP_Y = H - 56
    draw_gradient_rect(draw, 0, HELP_Y, W, H, (12, 15, 28), (8, 10, 20))
    draw.line([(0, HELP_Y), (W, HELP_Y)], fill=(*C_DIVIDER, 200))

    font_help_key = get_font(13, bold=True)
    font_help_txt = get_font(13)
    spacing = 36
    helps = ld["help"]
    widths = []
    for key, desc in helps:
        bk = draw.textbbox((0, 0), key, font=font_help_key)
        bt = draw.textbbox((0, 0), desc, font=font_help_txt)
        widths.append((bk[2] - bk[0], bt[2] - bt[0]))
    total_w = sum(wk + 8 + wt for wk, wt in widths) + spacing * (len(helps) - 1)
    hx = (W - total_w) // 2
    hy = HELP_Y + 16

    for (key, desc), (wk, wt) in zip(helps, widths):
        badge_w = wk + 10
        draw_rounded_rect(draw, hx, hy - 2, hx + badge_w, hy + 18,
                          4, (45, 55, 85), (90, 110, 160), 1)
        draw.text((hx + 5, hy), key, font=font_help_key, fill=(200, 210, 255))
        hx += badge_w + 6
        draw.text((hx, hy), desc, font=font_help_txt, fill=C_GRAY)
        hx += wt + spacing

    text_center(draw, ld["footer"], H - 16, font_info, C_DIM)

    return img


# ── Createur ecran verrouille ──────────────────────────────────

def create_locked_screen(os_name: str, lang: str = "FR") -> Image.Image:
    ld = LANGUAGES.get(lang, LANGUAGES["FR"])
    accent = C_ONION_ACC if os_name == "onion" else C_TELMI_ACC
    os_display = "OnionOS" if os_name == "onion" else "TelmiOS"

    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img, "RGBA")

    # Fond plus sombre
    draw_gradient_rect(draw, 0, 0, W, H, (6, 8, 14), (12, 15, 26))

    # Barre titre
    TITLE_H = 72
    draw_gradient_rect(draw, 0, 0, W, TITLE_H, (15, 18, 32), (12, 15, 28))
    for i, alpha in enumerate([60, 120, 60, 30]):
        draw.line([(0, TITLE_H - 2 + i), (W, TITLE_H - 2 + i)],
                  fill=(200, 80, 80, alpha))

    font_title = get_font(28, bold=True)
    font_sub   = get_font(13)
    text_center(draw, "MIYOO MINI+", 10, font_title, C_WHITE)
    text_center(draw, "DUAL BOOT SELECTOR", 44, font_sub, C_GRAY)

    # Centre
    cx, cy = W // 2, H // 2 - 10

    # --- Dessin cadenas ---
    # Corps du cadenas
    body_x0, body_y0 = cx - 44, cy - 4
    body_x1, body_y1 = cx + 44, cy + 56
    draw.rounded_rectangle([body_x0, body_y0, body_x1, body_y1],
                            radius=8, fill=(30, 35, 55),
                            outline=(*accent, 200), width=3)

    # Anneau du cadenas (arc semi-circulaire)
    arc_r = 30
    arc_cx, arc_cy = cx, cy - 4
    draw.arc([arc_cx - arc_r, arc_cy - arc_r - 28,
              arc_cx + arc_r, arc_cy + arc_r - 4],
             start=0, end=180,
             fill=(*accent, 220), width=9)

    # Trou de serrure - cercle
    draw.ellipse([cx - 10, cy + 12, cx + 10, cy + 32],
                 fill=(12, 15, 26), outline=(*accent, 180), width=2)
    # Trou de serrure - rectangle bas
    draw.rectangle([cx - 5, cy + 28, cx + 5, cy + 44],
                   fill=(12, 15, 26))
    draw.rectangle([cx - 4, cy + 28, cx + 4, cy + 44],
                   fill=(*accent, 120))

    # Nom de l'OS en haut du cadenas
    font_os = get_font(22, bold=True)
    os_color = lerp_color(C_WHITE, accent, 0.4)
    text_center(draw, os_display, cy - 90, font_os, os_color)

    # Filet decoratif
    line_y = cy - 70
    lc = (*lerp_color(accent, C_DIM, 0.5), 120)
    draw.line([(cx - 80, line_y), (cx + 80, line_y)], fill=lc)

    # Titre "ACCES PROTEGE"
    font_lock_big = get_font(26, bold=True)
    text_center(draw, ld["locked_title"], cy + 70, font_lock_big, C_WHITE)

    # Sous-titre
    font_lock_sub = get_font(15)
    text_center(draw, ld["locked_sub"], cy + 104, font_lock_sub, C_GRAY)

    # Hint
    font_lock_hint = get_font(11)
    text_center(draw, ld["locked_hint"], cy + 128, font_lock_hint,
                (*C_DIM, 200))

    # Barre bas
    HELP_Y = H - 56
    draw_gradient_rect(draw, 0, HELP_Y, W, H, (12, 15, 28), (8, 10, 20))
    draw.line([(0, HELP_Y), (W, HELP_Y)], fill=(*C_DIVIDER, 200))

    font_cancel = get_font(13, bold=True)
    text_center(draw, ld["locked_cancel"], HELP_Y + 18,
                font_cancel, (220, 100, 100))

    return img


# ── Conversion PNG -> RAW BGRA ─────────────────────────────────

def save_raw(img: Image.Image, path: str):
    img_rgba    = img.convert("RGBA")
    img_rotated = img_rgba.rotate(180)
    r, g, b, a  = img_rotated.split()
    img_bgra    = Image.merge("RGBA", (b, g, r, a))
    raw_bytes   = img_bgra.tobytes()
    with open(path, "wb") as f:
        f.write(raw_bytes)
    return len(raw_bytes)


# ── Point d'entree ────────────────────────────────────────────

def main():
    print("=" * 56)
    print("  Generateur Boot Menu Miyoo Mini+ Dual Boot")
    print("  Langues : FR / EN / ES")
    print("=" * 56)

    # Chemin SD passé en argument (ex: depuis l'installateur PowerShell)
    if len(sys.argv) > 1:
        sd_root = sys.argv[1].rstrip("\\").rstrip("/")
        SD_RES = os.path.join(sd_root, ".tmp_update", "res")
        if os.path.isdir(SD_RES):
            print(f"\n[OK] Carte SD -> RAW direct sur {SD_RES}")
        else:
            os.makedirs(SD_RES, exist_ok=True)
            print(f"\n[OK] Dossier cree -> {SD_RES}")
    else:
        # Auto-detection : essaie toutes les lettres de lecteur
        SD_RES = None
        for letter in "DEFGHIJKLMNOPQRSTUVWXYZ":
            candidate = os.path.join(f"{letter}:\\", ".tmp_update", "res")
            if os.path.isdir(candidate):
                SD_RES = candidate
                print(f"\n[OK] Carte SD trouvee -> RAW direct sur {SD_RES}")
                break
        if SD_RES is None:
            SD_RES = OUTPUT_DIR
            print(f"\n[!] Carte SD introuvable -> RAW dans {SD_RES}")

    for lang in ("FR", "EN", "ES"):
        print(f"\n{'-'*30}")
        print(f"  Langue : {lang}")
        print(f"{'-'*30}")

        for os_name in ("onion", "telmios"):
            # Image menu principale
            print(f"  -> bootmenu_{os_name}_{lang} ...")
            img = create_bootmenu(os_name, lang)

            png_path = os.path.join(OUTPUT_DIR, f"bootmenu_{os_name}_{lang}.png")
            img.save(png_path, "PNG", optimize=True)

            raw_path = os.path.join(SD_RES, f"bootmenu_{os_name}_{lang}.raw")
            nb = save_raw(img, raw_path)
            print(f"     PNG : {png_path}")
            print(f"     RAW : {raw_path} ({nb} octets)")

            # Ecran verrouille
            print(f"  -> bootmenu_locked_{os_name}_{lang} ...")
            img_lock = create_locked_screen(os_name, lang)

            raw_lock = os.path.join(SD_RES, f"bootmenu_locked_{os_name}_{lang}.raw")
            nb_lock  = save_raw(img_lock, raw_lock)

            png_lock = os.path.join(OUTPUT_DIR, f"bootmenu_locked_{os_name}_{lang}.png")
            img_lock.save(png_lock, "PNG", optimize=True)
            print(f"     RAW : {raw_lock} ({nb_lock} octets)")

    print(f"\n{'='*56}")
    print("TERMINE !")
    if SD_RES != OUTPUT_DIR:
        print("  Fichiers RAW copies directement sur la SD.")
        print("  Ejection propre recommandee avant insertion Miyoo.")
    else:
        print("  Copiez les .raw vers SD:\\.tmp_update\\res\\")
    print("=" * 56)


if __name__ == "__main__":
    main()
