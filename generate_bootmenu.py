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

# Config menu
C_CFG_ACC   = (100, 160, 255)   # Bleu config
C_PROT_ACC  = (200, 100, 255)   # Violet protection
C_VIB_ACC   = (255, 200,  50)   # Jaune vibration
C_SAVE_ACC  = ( 80, 200, 100)   # Vert sauvegarder
C_CANCEL_ACC= (220,  80,  80)   # Rouge annuler

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
        "help": [("< >", "Choisir l'OS"), ("A", "Confirmer"), ("X", "Config")],
        "footer":      "Timeout : le dernier OS choisi relance automatiquement",
        "locked_title":  "ACCES PROTEGE",
        "locked_sub":    "Entrez le code secret",
        "locked_cancel": "SELECT = Annuler",
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
        "help": [("< >", "Choose OS"), ("A", "Confirm"), ("X", "Config")],
        "footer":      "Timeout: last chosen OS will auto-boot",
        "locked_title":  "PROTECTED ACCESS",
        "locked_sub":    "Enter the secret code",
        "locked_cancel": "SELECT = Cancel",
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
        "help": [("< >", "Elegir OS"), ("A", "Confirmar"), ("X", "Config")],
        "footer":      "Timeout: el ultimo OS elegido arrancara automaticamente",
        "locked_title":  "ACCESO PROTEGIDO",
        "locked_sub":    "Introduce el codigo secreto",
        "locked_cancel": "SELECT = Cancelar",
        "locked_hint":   "Introduce la combinacion de botones configurada",
    },
}


# ── Textes config menu ─────────────────────────────────────────

CONFIG_TEXTS = {
    "FR": {
        "title":          "CONFIGURATION BIFROST",
        "access_sub":     "Entrez le code administrateur",
        "access_hint":    "Sequence de boutons  +  A pour confirmer   |   SELECT = Annuler",
        "menu_items": [
            ("Verrouillage OS",        "Proteger un OS par code secret"),
            ("Code de verrouillage",   "Modifier la sequence de deverrouillage"),
            ("Code administrateur",    "Modifier le code de ce menu config"),
            ("Vibrations",             "Intensite des retours haptiques"),
            ("Sauvegarder et quitter", "Enregistrer toutes les modifications"),
            ("Annuler",                "Quitter sans sauvegarder"),
        ],
        "menu_nav":       "Haut / Bas = Naviguer   |   A = Selectionner   |   SELECT = Quitter",
        "protect_title":  "VERROUILLAGE OS",
        "protect_options": [
            ("Aucun",     "Demarrage libre, aucun code requis"),
            ("OnionOS",   "Code requis pour lancer OnionOS"),
            ("TelmiOS",   "Code requis pour lancer TelmiOS"),
            ("Les deux",  "Code requis pour chaque OS"),
        ],
        "vib_title":      "VIBRATIONS",
        "vib_options": [
            ("Desactivee", "Aucun retour haptique"),
            ("Faible",     "Vibrations discretes"),
            ("Moyenne",    "Vibrations standard  (defaut)"),
            ("Forte",      "Vibrations intenses"),
        ],
        "choice_nav":     "Gauche / Droite = Choisir   |   A = Confirmer   |   SELECT = Retour",
        "pw_title":       "CODE DE VERROUILLAGE",
        "pw_sub":         "Entrez la nouvelle sequence secrete",
        "cfg_title":      "CODE ADMINISTRATEUR",
        "cfg_sub":        "Entrez le nouveau code d'administration",
        "entry_hint1":    "Appuyez sur les boutons de votre sequence  (max 8 boutons)",
        "entry_hint2":    "A = Valider   |   SELECT = Annuler",
        "entry_btns":     "Boutons valides :  Haut  Bas  Gauche  Droite  X  Y  L  R  START  SELECT",
        "saved_title":    "CONFIGURATION SAUVEGARDEE !",
        "saved_sub":      "Les modifications ont ete enregistrees.",
    },
    "EN": {
        "title":          "BIFROST CONFIGURATION",
        "access_sub":     "Enter admin code",
        "access_hint":    "Button sequence  +  A to confirm   |   SELECT = Cancel",
        "menu_items": [
            ("OS Lock",             "Protect an OS with a secret code"),
            ("Lock code",           "Change the unlock sequence"),
            ("Admin code",          "Change this config menu's code"),
            ("Vibrations",          "Haptic feedback intensity"),
            ("Save and exit",       "Save all changes"),
            ("Cancel",              "Exit without saving"),
        ],
        "menu_nav":       "Up / Down = Navigate   |   A = Select   |   SELECT = Exit",
        "protect_title":  "OS LOCK MODE",
        "protect_options": [
            ("None",      "Free boot, no code required"),
            ("OnionOS",   "Code required to launch OnionOS"),
            ("TelmiOS",   "Code required to launch TelmiOS"),
            ("Both",      "Code required for each OS"),
        ],
        "vib_title":      "VIBRATIONS",
        "vib_options": [
            ("Disabled",  "No haptic feedback"),
            ("Light",     "Subtle vibrations"),
            ("Medium",    "Standard vibrations  (default)"),
            ("Strong",    "Intense vibrations"),
        ],
        "choice_nav":     "Left / Right = Choose   |   A = Confirm   |   SELECT = Back",
        "pw_title":       "LOCK CODE",
        "pw_sub":         "Enter the new secret sequence",
        "cfg_title":      "ADMIN CODE",
        "cfg_sub":        "Enter the new administration code",
        "entry_hint1":    "Press the buttons of your sequence  (max 8 buttons)",
        "entry_hint2":    "A = Validate   |   SELECT = Cancel",
        "entry_btns":     "Valid buttons :  Up  Down  Left  Right  X  Y  L  R  START  SELECT",
        "saved_title":    "CONFIGURATION SAVED !",
        "saved_sub":      "Your changes have been saved.",
    },
    "ES": {
        "title":          "CONFIGURACION BIFROST",
        "access_sub":     "Ingresa el codigo de administrador",
        "access_hint":    "Secuencia de botones  +  A para confirmar   |   SELECT = Cancelar",
        "menu_items": [
            ("Bloqueo OS",          "Proteger un OS con codigo secreto"),
            ("Codigo bloqueo",      "Cambiar la secuencia de desbloqueo"),
            ("Codigo admin",        "Cambiar el codigo de este menu"),
            ("Vibraciones",         "Intensidad de respuesta haptica"),
            ("Guardar y salir",     "Guardar todos los cambios"),
            ("Cancelar",            "Salir sin guardar"),
        ],
        "menu_nav":       "Arriba / Abajo = Navegar   |   A = Seleccionar   |   SELECT = Salir",
        "protect_title":  "MODO BLOQUEO OS",
        "protect_options": [
            ("Ninguno",   "Arranque libre, sin codigo"),
            ("OnionOS",   "Codigo requerido para OnionOS"),
            ("TelmiOS",   "Codigo requerido para TelmiOS"),
            ("Ambos",     "Codigo requerido para cada OS"),
        ],
        "vib_title":      "VIBRACIONES",
        "vib_options": [
            ("Desactivada", "Sin respuesta haptica"),
            ("Suave",       "Vibraciones discretas"),
            ("Media",       "Vibraciones estandar  (defecto)"),
            ("Fuerte",      "Vibraciones intensas"),
        ],
        "choice_nav":     "Izq / Der = Elegir   |   A = Confirmar   |   SELECT = Volver",
        "pw_title":       "CODIGO DE BLOQUEO",
        "pw_sub":         "Ingresa la nueva secuencia secreta",
        "cfg_title":      "CODIGO ADMINISTRADOR",
        "cfg_sub":        "Ingresa el nuevo codigo de administracion",
        "entry_hint1":    "Pulsa los botones de tu secuencia  (max 8 botones)",
        "entry_hint2":    "A = Validar   |   SELECT = Cancelar",
        "entry_btns":     "Botones validos :  Arriba  Abajo  Izq  Der  X  Y  L  R  START  SELECT",
        "saved_title":    "CONFIGURACION GUARDADA !",
        "saved_sub":      "Los cambios han sido guardados.",
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

def text_center(draw, text, y, font, color, width):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (width - tw) // 2
    draw.text((x, y), text, font=font, fill=color)
    return tw

# ── Createur menu principal ────────────────────────────────────

def create_bootmenu(selected_os: str, lang: str = "FR", w: int = 640, h: int = 480) -> Image.Image:
    ld = LANGUAGES.get(lang, LANGUAGES["FR"])

    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img, "RGBA")

    # Fond degrade global
    draw_gradient_rect(draw, 0, 0, w, h, C_BG_TOP, C_BG_BOT)

    # Barre titre
    TITLE_H = int(72 * h / 480)
    draw_gradient_rect(draw, 0, 0, w, TITLE_H, (15, 18, 32), (12, 15, 28))
    for i, alpha in enumerate([60, 120, 60, 30]):
        draw.line([(0, TITLE_H - 2 + i), (w, TITLE_H - 2 + i)],
                  fill=(80, 120, 200, alpha))

    font_title = get_font(28, bold=True)
    font_sub   = get_font(13)
    font_big   = get_font(32, bold=True)
    font_badge = get_font(11, bold=True)
    font_small = get_font(13)
    font_hint  = get_font(12)
    font_info  = get_font(10)

    text_center(draw, "MIYOO MINI+", 10, font_title, C_WHITE, w)
    text_center(draw, ld["subtitle"], 44, font_sub, C_GRAY, w)

    # Zone centrale
    PANEL_TOP  = TITLE_H + 18
    PANEL_BOT  = h - 68
    PANEL_MID  = w // 2
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
            "lines":  ld["panel_onion_lines"],
        },
        {
            "id":     "telmios",
            "x0":     PANEL_MID + PADDING // 2,
            "x1":     w - PADDING,
            "accent": C_TELMI_ACC,
            "title":  "TelmiOS",
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

        # Separateur (directement sous le titre, sans version)
        line_y = title_y + 34
        draw.line([(x0 + 20, line_y), (x1 - 20, line_y)],
                  fill=(*accent, 80 if is_sel else 40))

        # Lignes description (plus d'espace grâce à la suppression de la version)
        desc_y = line_y + 12
        desc_spacing = 28
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
            desc_y += desc_spacing

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
    HELP_Y = h - 56
    draw_gradient_rect(draw, 0, HELP_Y, w, h, (12, 15, 28), (8, 10, 20))
    draw.line([(0, HELP_Y), (w, HELP_Y)], fill=(*C_DIVIDER, 200))

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
    hx = (w - total_w) // 2
    hy = HELP_Y + 16

    for (key, desc), (wk, wt) in zip(helps, widths):
        badge_w = wk + 10
        draw_rounded_rect(draw, hx, hy - 2, hx + badge_w, hy + 18,
                          4, (45, 55, 85), (90, 110, 160), 1)
        draw.text((hx + 5, hy), key, font=font_help_key, fill=(200, 210, 255))
        hx += badge_w + 6
        draw.text((hx, hy), desc, font=font_help_txt, fill=C_GRAY)
        hx += wt + spacing

    text_center(draw, ld["footer"], h - 16, font_info, C_DIM, w)

    return img


# ── Createur ecran verrouille ──────────────────────────────────

def create_locked_screen(os_name: str, lang: str = "FR", w: int = 640, h: int = 480) -> Image.Image:
    ld = LANGUAGES.get(lang, LANGUAGES["FR"])
    accent = C_ONION_ACC if os_name == "onion" else C_TELMI_ACC
    os_display = "OnionOS" if os_name == "onion" else "TelmiOS"

    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img, "RGBA")

    # Fond plus sombre
    draw_gradient_rect(draw, 0, 0, w, h, (6, 8, 14), (12, 15, 26))

    # Barre titre
    TITLE_H = int(72 * h / 480)
    draw_gradient_rect(draw, 0, 0, w, TITLE_H, (15, 18, 32), (12, 15, 28))
    for i, alpha in enumerate([60, 120, 60, 30]):
        draw.line([(0, TITLE_H - 2 + i), (w, TITLE_H - 2 + i)],
                  fill=(200, 80, 80, alpha))

    font_title = get_font(28, bold=True)
    font_sub   = get_font(13)
    text_center(draw, "MIYOO MINI+", 10, font_title, C_WHITE, w)
    text_center(draw, "DUAL BOOT SELECTOR", 44, font_sub, C_GRAY, w)

    # Centre
    cx, cy = w // 2, h // 2 - 10

    # --- Dessin cadenas ---
    body_x0, body_y0 = cx - 44, cy - 4
    body_x1, body_y1 = cx + 44, cy + 56
    draw.rounded_rectangle([body_x0, body_y0, body_x1, body_y1],
                            radius=8, fill=(30, 35, 55),
                            outline=(*accent, 200), width=3)

    # Anneau du cadenas
    arc_r = 30
    arc_cx, arc_cy = cx, cy - 4
    draw.arc([arc_cx - arc_r, arc_cy - arc_r - 28,
              arc_cx + arc_r, arc_cy + arc_r - 4],
             start=0, end=180,
             fill=(*accent, 220), width=9)

    # Trou de serrure
    draw.ellipse([cx - 10, cy + 12, cx + 10, cy + 32],
                 fill=(12, 15, 26), outline=(*accent, 180), width=2)
    draw.rectangle([cx - 5, cy + 28, cx + 5, cy + 44],
                   fill=(12, 15, 26))
    draw.rectangle([cx - 4, cy + 28, cx + 4, cy + 44],
                   fill=(*accent, 120))

    # Nom de l'OS
    font_os = get_font(22, bold=True)
    os_color = lerp_color(C_WHITE, accent, 0.4)
    text_center(draw, os_display, cy - 90, font_os, os_color, w)

    # Filet decoratif
    line_y = cy - 70
    lc = (*lerp_color(accent, C_DIM, 0.5), 120)
    draw.line([(cx - 80, line_y), (cx + 80, line_y)], fill=lc)

    # Titre "ACCES PROTEGE"
    font_lock_big = get_font(26, bold=True)
    text_center(draw, ld["locked_title"], cy + 70, font_lock_big, C_WHITE, w)

    # Sous-titre
    font_lock_sub = get_font(15)
    text_center(draw, ld["locked_sub"], cy + 104, font_lock_sub, C_GRAY, w)

    # Hint
    font_lock_hint = get_font(11)
    text_center(draw, ld["locked_hint"], cy + 128, font_lock_hint,
                (*C_DIM, 200), w)

    # Barre bas
    HELP_Y = h - 56
    draw_gradient_rect(draw, 0, HELP_Y, w, h, (12, 15, 28), (8, 10, 20))
    draw.line([(0, HELP_Y), (w, HELP_Y)], fill=(*C_DIVIDER, 200))

    font_cancel = get_font(13, bold=True)
    text_center(draw, ld["locked_cancel"], HELP_Y + 18,
                font_cancel, (220, 100, 100), w)

    return img


# ── Helpers config menu ───────────────────────────────────────

def _cfg_base(lang, w, h):
    """Cree une image de base pour les ecrans config (fond + barre titre)"""
    ct = CONFIG_TEXTS.get(lang, CONFIG_TEXTS["EN"])
    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img, "RGBA")
    draw_gradient_rect(draw, 0, 0, w, h, (6, 8, 16), (14, 18, 32))
    TITLE_H = int(68 * h / 480)
    draw_gradient_rect(draw, 0, 0, w, TITLE_H, (14, 17, 30), (11, 14, 26))
    for i, alpha in enumerate([50, 110, 50, 25]):
        draw.line([(0, TITLE_H - 2 + i), (w, TITLE_H - 2 + i)],
                  fill=(*C_CFG_ACC, alpha))
    font_t = get_font(26, bold=True)
    font_s = get_font(12)
    text_center(draw, "MIYOO MINI+", 8, font_t, C_WHITE, w)
    text_center(draw, ct["title"], 42, font_s, (*C_CFG_ACC, 210), w)
    return img, draw, TITLE_H, ct


def _cfg_bottom(draw, nav_text, w, h, accent=None):
    """Barre de navigation en bas de l'ecran config"""
    if accent is None:
        accent = C_CFG_ACC
    HELP_Y = h - 46
    draw_gradient_rect(draw, 0, HELP_Y, w, h, (11, 14, 26), (7, 9, 18))
    draw.line([(0, HELP_Y), (w, HELP_Y)], fill=(*C_DIVIDER, 180))
    if nav_text:
        font_nav = get_font(11)
        text_center(draw, nav_text, HELP_Y + 14, font_nav, (*C_GRAY, 200), w)


def _draw_settings_icon(draw, cx, cy, size, accent):
    """Icone parametres (engrenage simplifie)"""
    ro, ri = size, size // 2
    draw.ellipse([cx - ro, cy - ro, cx + ro, cy + ro],
                 fill=(20, 28, 50), outline=(*accent, 210), width=3)
    draw.ellipse([cx - ri, cy - ri, cx + ri, cy + ri],
                 fill=(8, 12, 22), outline=(*accent, 140), width=2)
    t = 9
    draw.rectangle([cx - 4, cy - ro - t + 2, cx + 4, cy - ri - 2], fill=(*accent, 190))
    draw.rectangle([cx - 4, cy + ri + 2,     cx + 4, cy + ro + t - 2], fill=(*accent, 190))
    draw.rectangle([cx - ro - t + 2, cy - 4, cx - ri - 2, cy + 4], fill=(*accent, 190))
    draw.rectangle([cx + ri + 2, cy - 4,     cx + ro + t - 2, cy + 4], fill=(*accent, 190))


# ── Createurs ecrans config ────────────────────────────────────

def create_config_access(lang="FR", w=640, h=480) -> Image.Image:
    """Ecran d'entree du code administrateur"""
    img, draw, TH, ct = _cfg_base(lang, w, h)
    cx = w // 2
    icon_cy = TH + 80

    _draw_settings_icon(draw, cx, icon_cy, 36, C_CFG_ACC)

    font_main = get_font(20, bold=True)
    font_sub  = get_font(14)
    font_hint = get_font(11)

    text_center(draw, "Configuration", icon_cy + 52, font_main, C_WHITE, w)

    sub_y = icon_cy + 84
    bbox = draw.textbbox((0, 0), ct["access_sub"], font=font_sub)
    bw = bbox[2] - bbox[0] + 32
    bx0, bx1 = (w - bw) // 2, (w + bw) // 2
    draw.rounded_rectangle([bx0, sub_y - 6, bx1, sub_y + 22],
                           radius=8, fill=(28, 38, 62), outline=(*C_CFG_ACC, 160), width=1)
    text_center(draw, ct["access_sub"], sub_y + 2, font_sub, (*C_CFG_ACC, 230), w)

    text_center(draw, ct["access_hint"], sub_y + 42, font_hint, C_GRAY, w)

    _cfg_bottom(draw, "", w, h)
    return img


def create_config_main(item_idx: int, lang="FR", w=640, h=480) -> Image.Image:
    """Menu principal config — item_idx = item selectionne (0-5)"""
    img, draw, TH, ct = _cfg_base(lang, w, h)

    items    = ct["menu_items"]
    N        = len(items)
    TOP      = TH + 8
    BOT      = h - 50
    ITEM_H   = (BOT - TOP) // N
    MARGIN   = 18

    accents = [C_CFG_ACC, C_CFG_ACC, C_CFG_ACC, C_VIB_ACC, C_SAVE_ACC, C_CANCEL_ACC]

    for i, (name, desc) in enumerate(items):
        iy0     = TOP + i * ITEM_H
        iy1     = iy0 + ITEM_H - 3
        is_sel  = (i == item_idx)
        acc     = accents[i]

        if is_sel:
            draw.rounded_rectangle([MARGIN, iy0, w - MARGIN, iy1],
                                   radius=7, fill=(30, 40, 65),
                                   outline=(*acc, 230), width=2)
        else:
            draw.rounded_rectangle([MARGIN, iy0, w - MARGIN, iy1],
                                   radius=7, fill=(16, 20, 34),
                                   outline=(*C_DIM, 70), width=1)

        if is_sel:
            ax, ay = MARGIN + 13, (iy0 + iy1) // 2
            draw.polygon([(ax, ay - 5), (ax + 7, ay), (ax, ay + 5)], fill=acc)

        font_n = get_font(14, bold=is_sel)
        font_d = get_font(10)
        nc = C_WHITE if is_sel else lerp_color(C_WHITE, C_DIM, 0.55)
        dc = (*acc, 170) if is_sel else (*C_DIM, 120)

        draw.text((MARGIN + 26, iy0 + 5),  name, font=font_n, fill=nc)
        draw.text((MARGIN + 26, iy0 + ITEM_H // 2 + 2), desc, font=font_d, fill=dc)

    _cfg_bottom(draw, ct["menu_nav"], w, h)
    return img


def create_config_choice(screen_type: str, option_idx: int, lang="FR", w=640, h=480) -> Image.Image:
    """Ecran de choix en grille 2x2."""
    img, draw, TH, ct = _cfg_base(lang, w, h)

    if screen_type == "protect":
        title   = ct["protect_title"]
        options = ct["protect_options"]
        accent  = C_PROT_ACC
    else:
        title   = ct["vib_title"]
        options = ct["vib_options"]
        accent  = C_VIB_ACC

    font_title = get_font(16, bold=True)
    text_center(draw, title, TH + 10, font_title, (*accent, 220), w)

    GRID_TOP = TH + 38
    GRID_BOT = h - 50
    PAD      = 16
    CARD_W   = (w - 3 * PAD) // 2
    CARD_H   = (GRID_BOT - GRID_TOP - PAD) // 2

    positions = [
        (PAD,              GRID_TOP),
        (PAD * 2 + CARD_W, GRID_TOP),
        (PAD,              GRID_TOP + CARD_H + PAD),
        (PAD * 2 + CARD_W, GRID_TOP + CARD_H + PAD),
    ]

    for i, (opt_name, opt_desc) in enumerate(options):
        x0, y0 = positions[i]
        x1, y1 = x0 + CARD_W, y0 + CARD_H
        is_sel = (i == option_idx)
        cx_c   = (x0 + x1) // 2

        if is_sel:
            draw.rounded_rectangle([x0, y0, x1, y1], radius=10,
                                   fill=(30, 36, 58), outline=(*accent, 240), width=3)
            draw.rounded_rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2],
                                   radius=12, fill=None, outline=(*accent, 55), width=2)
        else:
            draw.rounded_rectangle([x0, y0, x1, y1], radius=10,
                                   fill=(16, 20, 34), outline=(*C_DIM, 90), width=1)

        dr = 5
        dot_y = y0 + 12
        if is_sel:
            draw.ellipse([cx_c - dr, dot_y, cx_c + dr, dot_y + 2 * dr],
                         fill=(*accent, 220))
        else:
            draw.ellipse([cx_c - dr, dot_y, cx_c + dr, dot_y + 2 * dr],
                         outline=(*C_DIM, 140), width=2)

        font_on = get_font(15, bold=is_sel)
        font_od = get_font(10)
        oc = C_WHITE if is_sel else lerp_color(C_WHITE, C_DIM, 0.55)
        dc = (*accent, 180) if is_sel else (*C_DIM, 110)

        bbox = draw.textbbox((0, 0), opt_name, font=font_on)
        tw = bbox[2] - bbox[0]
        draw.text((cx_c - tw // 2, y0 + CARD_H // 2 - 14), opt_name, font=font_on, fill=oc)

        bbox_d = draw.textbbox((0, 0), opt_desc, font=font_od)
        dw = bbox_d[2] - bbox_d[0]
        draw.text((cx_c - dw // 2, y0 + CARD_H // 2 + 8), opt_desc, font=font_od, fill=dc)

    _cfg_bottom(draw, ct["choice_nav"], w, h, accent)
    return img


def create_config_entry(entry_type: str, lang="FR", w=640, h=480) -> Image.Image:
    """Ecran de saisie d'une nouvelle sequence de boutons."""
    img, draw, TH, ct = _cfg_base(lang, w, h)
    cx = w // 2

    title  = ct["pw_title"]  if entry_type == "pw" else ct["cfg_title"]
    sub    = ct["pw_sub"]    if entry_type == "pw" else ct["cfg_sub"]
    accent = C_PROT_ACC if entry_type == "pw" else C_CFG_ACC

    font_t = get_font(16, bold=True)
    font_s = get_font(14)
    font_h = get_font(11)

    text_center(draw, title, TH + 12, font_t, (*accent, 220), w)
    text_center(draw, sub,   TH + 36, font_s, C_WHITE, w)

    # Slots de saisie (8 emplacements)
    SY      = TH + 72
    SLOT_W  = 52
    SLOT_H  = 46
    SLOT_G  = 10
    TOTAL   = 8 * SLOT_W + 7 * SLOT_G
    sx0     = (w - TOTAL) // 2

    for s in range(8):
        sx = sx0 + s * (SLOT_W + SLOT_G)
        draw.rounded_rectangle([sx, SY, sx + SLOT_W, SY + SLOT_H],
                               radius=6, fill=(20, 26, 44),
                               outline=(*C_DIM, 110), width=1)
        mid_y = SY + SLOT_H // 2
        draw.line([(sx + 14, mid_y), (sx + SLOT_W - 14, mid_y)],
                 fill=(*C_DIM, 90), width=2)

    IY = SY + SLOT_H + 20
    draw.rounded_rectangle([36, IY - 8, w - 36, IY + 56],
                           radius=8, fill=(18, 24, 42), outline=(*accent, 90), width=1)
    text_center(draw, ct["entry_hint1"], IY + 6,  font_h, C_GRAY, w)
    text_center(draw, ct["entry_hint2"], IY + 28, get_font(12, bold=True), (*accent, 200), w)

    text_center(draw, ct["entry_btns"], IY + 72, font_h, C_DIM, w)

    _cfg_bottom(draw, "", w, h, accent)
    return img


def create_config_saved(lang="FR", w=640, h=480) -> Image.Image:
    """Ecran de confirmation : configuration sauvegardee"""
    img, draw, TH, ct = _cfg_base(lang, w, h)
    cx = w // 2
    acc = C_SAVE_ACC

    icon_cy = TH + 95
    r = 44
    draw.ellipse([cx - r, icon_cy - r, cx + r, icon_cy + r],
                 fill=(16, 46, 26), outline=(*acc, 220), width=4)
    pts = [(cx - 18, icon_cy + 2), (cx - 4, icon_cy + 18), (cx + 20, icon_cy - 16)]
    for j in range(len(pts) - 1):
        draw.line([pts[j], pts[j + 1]], fill=(*acc, 255), width=5)

    font_s = get_font(20, bold=True)
    font_d = get_font(13)
    text_center(draw, ct["saved_title"], icon_cy + r + 20, font_s, C_WHITE, w)
    text_center(draw, ct["saved_sub"],   icon_cy + r + 52, font_d, C_GRAY, w)

    _cfg_bottom(draw, "", w, h, acc)
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


# ── Generateur d'images pour une resolution donnee ────────────

def _generate_all_images(suffix, sd_res, w, h):
    """
    Genere tous les fichiers RAW pour la resolution courante (w x h).
    suffix : "" pour 640x480, "_flip" pour 752x560 (Miyoo Mini Flip)
    Les PNG de preview ne sont generes que pour la resolution de base (suffix vide).
    """
    for lang in ("FR", "EN", "ES"):
        print(f"\n{'-'*30}")
        print(f"  Langue : {lang}  [{w}x{h}]")
        print(f"{'-'*30}")

        for os_name in ("onion", "telmios"):
            # Image menu principale
            print(f"  -> bootmenu_{os_name}_{lang}{suffix} ...")
            img = create_bootmenu(os_name, lang, w, h)

            if not suffix:
                png_path = os.path.join(OUTPUT_DIR, f"bootmenu_{os_name}_{lang}.png")
                img.save(png_path, "PNG", optimize=True)
                print(f"     PNG : {png_path}")

            raw_path = os.path.join(sd_res, f"bootmenu_{os_name}_{lang}{suffix}.raw")
            nb = save_raw(img, raw_path)
            print(f"     RAW : {raw_path} ({nb} octets)")

            # Ecran verrouille
            print(f"  -> bootmenu_locked_{os_name}_{lang}{suffix} ...")
            img_lock = create_locked_screen(os_name, lang, w, h)

            raw_lock = os.path.join(sd_res, f"bootmenu_locked_{os_name}_{lang}{suffix}.raw")
            nb_lock  = save_raw(img_lock, raw_lock)
            print(f"     RAW : {raw_lock} ({nb_lock} octets)")

            if not suffix:
                png_lock = os.path.join(OUTPUT_DIR, f"bootmenu_locked_{os_name}_{lang}.png")
                img_lock.save(png_lock, "PNG", optimize=True)

    # ── Images du menu de configuration ──────────────────────────
    print(f"\n{'-'*30}")
    print(f"  Images Menu Configuration  [{w}x{h}]")
    print(f"{'-'*30}")

    cfg_specs = []
    cfg_specs.append(("config_access", None, None))
    for i in range(6):
        cfg_specs.append((f"config_main_{i}", "main", i))
    for i in range(4):
        cfg_specs.append((f"config_protect_{i}", "protect", i))
    for i in range(4):
        cfg_specs.append((f"config_vib_{i}", "vib", i))
    cfg_specs.append(("config_pw_entry",  "entry_pw",  None))
    cfg_specs.append(("config_cfg_entry", "entry_cfg", None))
    cfg_specs.append(("config_saved", "saved", None))

    for lang in ("FR", "EN", "ES"):
        print(f"\n  Langue : {lang}")
        for name, kind, idx in cfg_specs:
            if kind is None and name == "config_access":
                img = create_config_access(lang, w, h)
            elif kind == "main":
                img = create_config_main(idx, lang, w, h)
            elif kind == "protect":
                img = create_config_choice("protect", idx, lang, w, h)
            elif kind == "vib":
                img = create_config_choice("vib", idx, lang, w, h)
            elif kind == "entry_pw":
                img = create_config_entry("pw", lang, w, h)
            elif kind == "entry_cfg":
                img = create_config_entry("cfg", lang, w, h)
            elif kind == "saved":
                img = create_config_saved(lang, w, h)
            else:
                continue

            raw_name = f"bootmenu_{name}_{lang}{suffix}.raw"
            raw_path = os.path.join(sd_res, raw_name)
            nb = save_raw(img, raw_path)
            print(f"     {raw_name} ({nb} octets)")

            # PNG de preview (FR uniquement, resolution de base uniquement)
            if lang == "FR" and not suffix:
                preview_dir = os.path.join(OUTPUT_DIR, "preview")
                os.makedirs(preview_dir, exist_ok=True)
                png_path = os.path.join(preview_dir, f"bootmenu_{name}_FR.png")
                img.save(png_path, "PNG", optimize=True)


# ── Point d'entree ────────────────────────────────────────────

def main():
    print("=" * 56)
    print("  Generateur Boot Menu Miyoo Mini / Mini+ / Mini Flip")
    print("  Langues : FR / EN / ES")
    print("=" * 56)

    # Chemin SD passe en argument (ex: depuis l'installateur PowerShell)
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

    # ── Resolution 640x480 : Miyoo Mini / Mini Plus ───────────────
    print(f"\n{'='*56}")
    print("  Resolution 640x480  (Miyoo Mini / Mini Plus)")
    print(f"{'='*56}")
    _generate_all_images("", SD_RES, 640, 480)

    # ── Resolution 752x560 : Miyoo Mini Flip ─────────────────────
    print(f"\n{'='*56}")
    print("  Resolution 752x560  (Miyoo Mini Flip) -> suffix _flip")
    print(f"{'='*56}")
    _generate_all_images("_flip", SD_RES, 752, 560)

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
