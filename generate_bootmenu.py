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
        "selected_badge":     "SELECTIONNE",
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
        "selected_badge":     "SELECTED",
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
        "selected_badge":     "SELECCIONADO",
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
            ("Mode de demarrage",      "Menu visible ou demarrage furtif"),
            ("Code Konami",            "Sequence secrete pour reveler le menu"),
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
        "bootmode_title":  "MODE DE DEMARRAGE",
        "bootmode_options": [
            ("Menu visible",     "Affichage classique du menu de boot"),
            ("Furtif TelmiOS",   "Boot direct sur TelmiOS, menu via Konami"),
            ("Furtif OnionOS",   "Boot direct sur OnionOS, menu via Konami"),
        ],
        "choice_nav":     "Gauche / Droite = Choisir   |   A = Confirmer   |   SELECT = Retour",
        "pw_title":       "CODE DE VERROUILLAGE",
        "pw_sub":         "Entrez la nouvelle sequence secrete",
        "cfg_title":      "CODE ADMINISTRATEUR",
        "cfg_sub":        "Entrez le nouveau code d'administration",
        "konami_title":   "CODE KONAMI",
        "konami_sub":     "Sequence pour reveler le menu en mode furtif",
        "entry_hint1":    "Appuyez sur les boutons de votre sequence",
        "entry_hint2":    "A = Valider   |   SELECT = Annuler",
        "entry_btns":     "Boutons valides :  Haut  Bas  Gauche  Droite  B  X  Y  L  R",
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
            ("Boot Mode",           "Visible menu or stealth boot"),
            ("Konami Code",         "Secret sequence to reveal the menu"),
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
        "bootmode_title":  "BOOT MODE",
        "bootmode_options": [
            ("Visible Menu",   "Classic boot menu display"),
            ("Stealth TelmiOS","Boot directly to TelmiOS, Konami for menu"),
            ("Stealth OnionOS","Boot directly to OnionOS, Konami for menu"),
        ],
        "choice_nav":     "Left / Right = Choose   |   A = Confirm   |   SELECT = Back",
        "pw_title":       "LOCK CODE",
        "pw_sub":         "Enter the new secret sequence",
        "cfg_title":      "ADMIN CODE",
        "cfg_sub":        "Enter the new administration code",
        "konami_title":   "KONAMI CODE",
        "konami_sub":     "Secret sequence to reveal the menu in stealth mode",
        "entry_hint1":    "Press the buttons of your sequence",
        "entry_hint2":    "A = Validate   |   SELECT = Cancel",
        "entry_btns":     "Valid buttons :  Up  Down  Left  Right  B  X  Y  L  R",
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
            ("Modo de arranque",    "Menu visible o arranque furtivo"),
            ("Codigo Konami",       "Secuencia secreta para revelar el menu"),
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
        "bootmode_title":  "MODO DE ARRANQUE",
        "bootmode_options": [
            ("Menu visible",    "Visualizacion clasica del menu"),
            ("Furtivo TelmiOS", "Arranque directo, menu via Konami"),
            ("Furtivo OnionOS", "Arranque directo, menu via Konami"),
        ],
        "choice_nav":     "Izq / Der = Elegir   |   A = Confirmar   |   SELECT = Volver",
        "pw_title":       "CODIGO DE BLOQUEO",
        "pw_sub":         "Ingresa la nueva secuencia secreta",
        "cfg_title":      "CODIGO ADMINISTRADOR",
        "cfg_sub":        "Ingresa el nuevo codigo de administracion",
        "konami_title":   "CODIGO KONAMI",
        "konami_sub":     "Secuencia para revelar el menu en modo furtivo",
        "entry_hint1":    "Pulsa los botones de tu secuencia",
        "entry_hint2":    "A = Validar   |   SELECT = Cancelar",
        "entry_btns":     "Botones validos :  Arriba  Abajo  Izq  Der  B  X  Y  L  R",
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

# Agrandissement global du texte.
# Les tailles passees a get_font() sont les tailles "de reference" historiques ;
# elles sont multipliees par ce facteur au moment du rendu.
FONT_SCALE = 1.18

# Familles de polices, par plateforme, de la plus souhaitable a la moins.
# Liberation Sans (Linux) est metriquement compatible avec Arial (Windows) :
# les images generees sous Linux et sous Windows sont donc quasi identiques.
_FONT_CANDIDATES = {
    "regular": [
        # Windows
        "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/calibri.ttf",
        "C:/Windows/Fonts/segoeui.ttf",
        # Linux
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf",
        "/usr/share/fonts/liberation/LiberationSans-Regular.ttf",
        "/usr/share/fonts/TTF/LiberationSans-Regular.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSans.ttf",
        # macOS
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ],
    "bold": [
        # Windows
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/calibrib.ttf",
        "C:/Windows/Fonts/segoeuib.ttf",
        # Linux
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf",
        "/usr/share/fonts/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/TTF/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
        # macOS
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/Library/Fonts/Arial Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ],
}

# Chemin de police retenu, resolu une seule fois par style.
_FONT_FILE = {}
_FONT_CACHE = {}


def _resolve_font_file(bold):
    """Trouve un fichier de police vectorielle utilisable pour le style demande."""
    style = "bold" if bold else "regular"
    if style in _FONT_FILE:
        return _FONT_FILE[style]

    for path in _FONT_CANDIDATES[style]:
        if not os.path.exists(path):
            continue
        try:
            ImageFont.truetype(path, 20)
        except Exception:
            continue
        _FONT_FILE[style] = path
        return path

    # Dernier recours : demander la police par defaut a fontconfig (Linux/macOS).
    try:
        import subprocess
        query = "Arial:bold" if bold else "Arial"
        out = subprocess.run(["fc-match", "-f", "%{file}", query],
                             capture_output=True, text=True, timeout=5)
        cand = out.stdout.strip()
        if cand and os.path.exists(cand):
            ImageFont.truetype(cand, 20)
            _FONT_FILE[style] = cand
            return cand
    except Exception:
        pass

    _FONT_FILE[style] = None
    return None


def check_fonts():
    """Verifie qu'une police vectorielle est disponible.

    Sans police vectorielle, Pillow retombe sur une police bitmap de taille
    fixe : toutes les tailles rendraient identiquement et les images seraient
    illisibles sur la console. On prefere echouer franchement.
    """
    regular = _resolve_font_file(False)
    bold = _resolve_font_file(True)
    if regular is None:
        print("ERREUR: aucune police vectorielle (.ttf) trouvee sur ce systeme.")
        print("  Les images seraient generees avec une police bitmap de taille fixe.")
        print("  Installez une police, par exemple :")
        print("    Debian/Ubuntu : sudo apt install fonts-liberation")
        print("    Fedora        : sudo dnf install liberation-sans-fonts")
        print("    macOS/Windows : Arial est normalement deja present")
        sys.exit(2)
    print("OK Police reguliere : " + regular)
    print("OK Police grasse    : " + (bold or regular))
    print("OK Echelle du texte : x%.2f" % FONT_SCALE)


def get_font(size, bold=False):
    """Police a la taille demandee, multipliee par FONT_SCALE."""
    scaled = max(7, int(round(size * FONT_SCALE)))
    key = (scaled, bool(bold))
    if key in _FONT_CACHE:
        return _FONT_CACHE[key]

    path = _resolve_font_file(bold)
    if path is None:
        path = _resolve_font_file(False)
    if path is None:
        font = ImageFont.load_default()
    else:
        try:
            font = ImageFont.truetype(path, scaled)
        except Exception:
            font = ImageFont.load_default()
    _FONT_CACHE[key] = font
    return font


def text_width(draw, text, font):
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0]


def fit_font(draw, text, max_w, size, bold=False, min_size=7):
    """Plus grande police <= `size` dont `text` tient dans `max_w` pixels.

    Garantit qu'agrandir le texte ne le fait jamais deborder de son cadre.
    """
    if max_w <= 0 or not text:
        return get_font(size, bold)
    current = size
    while current > min_size:
        font = get_font(current, bold)
        if text_width(draw, text, font) <= max_w:
            return font
        current -= 1
    return get_font(min_size, bold)


def text_center(draw, text, y, font, color, width):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (width - tw) // 2
    draw.text((x, y), text, font=font, fill=color)
    return tw


def text_center_fit(draw, text, y, size, color, width, max_w=None, bold=False):
    """Texte centre, retreci automatiquement pour tenir dans `max_w`."""
    if max_w is None:
        max_w = width - 24
    font = fit_font(draw, text, max_w, size, bold)
    return text_center(draw, text, y, font, color, width)


def draw_title_bar_text(draw, w, bar_h, line1, line2, size1, size2, c1, c2):
    """Ecrit les deux lignes d'entete, centrees verticalement dans la barre.

    Les positions sont derivees des metriques reelles des polices : la barre
    reste correcte quelle que soit la valeur de FONT_SCALE.
    """
    f1 = fit_font(draw, line1, w - 40, size1, bold=True)
    f2 = fit_font(draw, line2, w - 32, size2, bold=False)

    b1 = draw.textbbox((0, 0), line1, font=f1)
    b2 = draw.textbbox((0, 0), line2, font=f2)
    h1, h2 = b1[3] - b1[1], b2[3] - b2[1]
    gap = max(4, int(bar_h * 0.06))

    total = h1 + gap + h2
    top = (bar_h - total) // 2

    # textbbox inclut le decalage interne du glyphe : on le compense.
    text_center(draw, line1, top - b1[1], f1, c1, w)
    text_center(draw, line2, top + h1 + gap - b2[1], f2, c2, w)

# ── Emblemes des OS ───────────────────────────────────────────
# Dessines en vectoriel plutot qu'importes : aucune dependance a une
# image externe, et ils suivent la couleur d'accent de chaque panneau.

def _draw_gamepad_emblem(draw, cx, cy, r, accent, active=True):
    """Manette de jeu stylisee : croix directionnelle et boutons.

    L'embleme designe l'usage du systeme, pas son nom : une manette se
    reconnait instantanement a cette taille, la ou un bulbe d'oignon
    devient illisible en dessous de 80 pixels.
    """
    col = accent if active else lerp_color(accent, C_DIM, 0.6)
    a_main = 235 if active else 130
    a_soft = 165 if active else 90

    bw = r                      # demi-largeur du corps
    bh = int(r * 0.62)          # demi-hauteur du corps

    # Corps de la manette, avec les poignees suggerees par les coins bas.
    draw.rounded_rectangle([cx - bw, cy - bh, cx + bw, cy + bh],
                           radius=int(bh * 0.85),
                           outline=(*col, a_main), width=3)

    # Croix directionnelle, a gauche.
    dx = cx - int(bw * 0.52)
    arm = int(r * 0.26)
    th = max(2, int(r * 0.09))
    draw.rectangle([dx - arm, cy - th, dx + arm, cy + th], fill=(*col, a_soft))
    draw.rectangle([dx - th, cy - arm, dx + th, cy + arm], fill=(*col, a_soft))

    # Deux boutons, a droite.
    bx = cx + int(bw * 0.50)
    br = max(2, int(r * 0.13))
    off = int(r * 0.21)
    draw.ellipse([bx - off - br, cy - br, bx - off + br, cy + br],
                 fill=(*col, a_soft))
    draw.ellipse([bx + off - br, cy - br, bx + off + br, cy + br],
                 fill=(*col, a_soft))


def _draw_book_emblem(draw, cx, cy, r, accent, active=True):
    """Livre ouvert stylise : deux pages et une reliure centrale."""
    col = accent if active else lerp_color(accent, C_DIM, 0.6)
    a_main = 235 if active else 130
    a_soft = 165 if active else 90

    w = r
    h = int(r * 0.72)
    lift = int(r * 0.18)          # les pages remontent vers l'exterieur

    # Contours traces au trait : draw.polygon n'accepte pas d'epaisseur,
    # et un contour d'un pixel serait plus fin que celui de la manette.
    def outline(points, width=3):
        for i in range(len(points)):
            draw.line([points[i], points[(i + 1) % len(points)]],
                      fill=(*col, a_main), width=width)

    outline([(cx - 2, cy - h + lift), (cx - w, cy - h),
             (cx - w, cy + h - lift), (cx - 2, cy + h)])
    outline([(cx + 2, cy - h + lift), (cx + w, cy - h),
             (cx + w, cy + h - lift), (cx + 2, cy + h)])

    # Reliure.
    draw.line([(cx, cy - h + lift), (cx, cy + h)], fill=(*col, a_main), width=3)

    # Lignes de texte suggerees sur chaque page.
    for i in range(3):
        yy = cy - int(h * 0.30) + i * int(h * 0.32)
        inset = int(w * 0.24) + i * 2
        draw.line([(cx - w + inset, yy), (cx - int(w * 0.26), yy)],
                  fill=(*col, a_soft), width=2)
        draw.line([(cx + int(w * 0.26), yy), (cx + w - inset, yy)],
                  fill=(*col, a_soft), width=2)


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

    draw_title_bar_text(draw, w, TITLE_H, "MIYOO MINI+", ld["subtitle"],
                        28, 13, C_WHITE, C_GRAY)

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

        # Badge "SELECTIONNE" : les chevrons sont traces, pas ecrits, car les
        # triangles Unicode manquent dans beaucoup de polices systeme.
        if is_sel:
            sel_y = PANEL_TOP + 14
            badge_text = ld["selected_badge"]
            ARROW_W, ARROW_GAP = 7, 9
            reserved = 2 * (ARROW_W + ARROW_GAP) + 24
            font_badge = fit_font(draw, badge_text,
                                  (x1 - x0) - reserved, 11, bold=True)
            bbox_b = draw.textbbox((0, 0), badge_text, font=font_badge)
            bw_txt = bbox_b[2] - bbox_b[0]
            bh_txt = bbox_b[3] - bbox_b[1]
            badge_h = bh_txt + 10
            bw_half = bw_txt // 2 + ARROW_W + ARROW_GAP + 10
            draw_rounded_rect(draw, cx - bw_half, sel_y,
                              cx + bw_half, sel_y + badge_h,
                              6, (*accent, 40), (*accent, 200), 1)
            draw.text((cx - bw_txt // 2, sel_y + 5 - bbox_b[1]), badge_text,
                      font=font_badge, fill=accent)

            ay = sel_y + badge_h // 2
            ah = max(4, bh_txt // 2)
            # Bord interieur des fleches : ARROW_GAP pixels avant le texte.
            inner_l = cx - bw_txt // 2 - ARROW_GAP
            inner_r = cx + bw_txt // 2 + ARROW_GAP
            draw.polygon([(inner_l - ARROW_W, ay), (inner_l, ay - ah),
                          (inner_l, ay + ah)], fill=accent)
            draw.polygon([(inner_r + ARROW_W, ay), (inner_r, ay - ah),
                          (inner_r, ay + ah)], fill=accent)

        # Embleme de l'OS, dans l'espace laisse libre sous le badge.
        # Il occupe une zone qui restait vide et rend les deux choix
        # identifiables d'un coup d'oeil, sans lire le texte.
        emblem_r  = max(18, min(34, (PANEL_BOT - PANEL_TOP) // 9))
        emblem_cy = PANEL_TOP + 44 + emblem_r
        if panel["id"] == "onion":
            _draw_gamepad_emblem(draw, cx, emblem_cy, emblem_r, accent, is_sel)
        else:
            _draw_book_emblem(draw, cx, emblem_cy, emblem_r, accent, is_sel)

        # Nom OS
        title_y  = emblem_cy + emblem_r + 14
        font_os  = fit_font(draw, panel["title"], (x1 - x0) - 20, 26, bold=True)
        bbox_t   = draw.textbbox((0, 0), panel["title"], font=font_os)
        tw       = bbox_t[2] - bbox_t[0]
        title_color = C_WHITE if is_sel else lerp_color(C_WHITE, C_DIM, 0.4)
        draw.text((cx - tw // 2, title_y), panel["title"], font=font_os, fill=title_color)

        # Separateur, place sous le titre d'apres sa hauteur reelle.
        line_y = title_y + (bbox_t[3] - bbox_t[1]) + 12
        draw.line([(x0 + 20, line_y), (x1 - 20, line_y)],
                  fill=(*accent, 80 if is_sel else 40))

        # Lignes description : reparties dans l'espace reellement disponible
        # entre le filet et l'indicateur du bas, plutot qu'a pas fixe.
        desc_y = line_y + 14
        lines_n = max(1, len(panel["lines"]))
        avail_h = (PANEL_BOT - 46) - desc_y
        desc_spacing = max(24, min(38, avail_h // lines_n))
        for i, line in enumerate(panel["lines"]):
            line_color = C_WHITE if is_sel else C_DIM
            alpha_mult = 1.0 if is_sel else 0.6
            dot_color  = accent if is_sel else lerp_color(accent, C_DIM, 0.6)
            dot_x = x0 + 24
            text_x = dot_x + 12
            font_line  = fit_font(draw, line, (x1 - 12) - text_x, 13,
                                  bold=(i == 0))
            draw.ellipse([dot_x - 3, desc_y + 5, dot_x + 3, desc_y + 11],
                         fill=(*dot_color, int(200 * alpha_mult)))
            draw.text((text_x, desc_y), line, font=font_line,
                      fill=(*line_color, int(220 * alpha_mult)))
            desc_y += desc_spacing

        # Indicateur bas
        status_y  = PANEL_BOT - 36
        draw.line([(x0 + 20, status_y - 5), (x1 - 20, status_y - 5)],
                  fill=(*accent, 40 if is_sel else 20))
        icon_text = ld["icon_sel"] if is_sel else ld["icon_nosel"]
        font_icon = fit_font(draw, icon_text, (x1 - x0) - 16, 11)
        bbox_i    = draw.textbbox((0, 0), icon_text, font=font_icon)
        iw        = bbox_i[2] - bbox_i[0]
        draw.text((cx - iw // 2, status_y), icon_text, font=font_icon,
                  fill=(*accent, 200) if is_sel else (*C_DIM, 160))

    # Barre aide bas
    HELP_Y = h - 56
    draw_gradient_rect(draw, 0, HELP_Y, w, h, (12, 15, 28), (8, 10, 20))
    draw.line([(0, HELP_Y), (w, HELP_Y)], fill=(*C_DIVIDER, 200))

    helps = ld["help"]

    # La barre d'aide est composee de plusieurs blocs : on reduit d'un cran la
    # taille de police (et l'espacement) tant que l'ensemble deborde.
    help_size = 13
    while True:
        font_help_key = get_font(help_size, bold=True)
        font_help_txt = get_font(help_size)
        spacing = max(14, int(36 * help_size / 13))
        widths = []
        for key, desc in helps:
            bk = draw.textbbox((0, 0), key, font=font_help_key)
            bt = draw.textbbox((0, 0), desc, font=font_help_txt)
            widths.append((bk[2] - bk[0], bt[2] - bt[0]))
        total_w = (sum(wk + 10 + 6 + wt for wk, wt in widths)
                   + spacing * (len(helps) - 1))
        if total_w <= w - 16 or help_size <= 8:
            break
        help_size -= 1

    hx = max(6, (w - total_w) // 2)
    hy = HELP_Y + 16

    for (key, desc), (wk, wt) in zip(helps, widths):
        badge_w = wk + 10
        draw_rounded_rect(draw, hx, hy - 2, hx + badge_w, hy + 18,
                          4, (45, 55, 85), (90, 110, 160), 1)
        draw.text((hx + 5, hy), key, font=font_help_key, fill=(200, 210, 255))
        hx += badge_w + 6
        draw.text((hx, hy), desc, font=font_help_txt, fill=C_GRAY)
        hx += wt + spacing

    text_center_fit(draw, ld["footer"], h - 18, 10, C_DIM, w, w - 16)

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

    draw_title_bar_text(draw, w, TITLE_H, "MIYOO MINI+", "DUAL BOOT SELECTOR",
                        28, 13, C_WHITE, C_GRAY)

    # Centre
    cx, cy = w // 2, h // 2 - 10

    # --- Dessin cadenas ---
    body_x0, body_y0 = cx - 44, cy - 4
    body_x1, body_y1 = cx + 44, cy + 56

    # Anse : demi-ellipse SUPERIEURE (PIL : 0 deg = 3 h, sens horaire, donc la
    # moitie haute va de 180 a 360 deg). Tracee avant le corps pour que ses
    # extremites disparaissent proprement derriere lui.
    arc_rx, arc_ry = 27, 34
    draw.arc([cx - arc_rx, body_y0 - arc_ry,
              cx + arc_rx, body_y0 + arc_ry],
             start=180, end=360,
             fill=(*accent, 220), width=9)

    draw.rounded_rectangle([body_x0, body_y0, body_x1, body_y1],
                            radius=8, fill=(30, 35, 55),
                            outline=(*accent, 200), width=3)

    # Trou de serrure
    draw.ellipse([cx - 10, cy + 12, cx + 10, cy + 32],
                 fill=(12, 15, 26), outline=(*accent, 180), width=2)
    draw.rectangle([cx - 5, cy + 28, cx + 5, cy + 44],
                   fill=(12, 15, 26))
    draw.rectangle([cx - 4, cy + 28, cx + 4, cy + 44],
                   fill=(*accent, 120))

    # Nom de l'OS
    os_color = lerp_color(C_WHITE, accent, 0.4)
    os_y = cy - 100
    font_os = fit_font(draw, os_display, w - 60, 22, bold=True)
    os_bbox = draw.textbbox((0, 0), os_display, font=font_os)
    text_center(draw, os_display, os_y - os_bbox[1], font_os, os_color, w)

    # Filet decoratif, place sous le texte et non au travers.
    line_y = os_y + (os_bbox[3] - os_bbox[1]) + 9
    lc = (*lerp_color(accent, C_DIM, 0.5), 120)
    draw.line([(cx - 80, line_y), (cx + 80, line_y)], fill=lc)

    # Titre "ACCES PROTEGE"
    text_center_fit(draw, ld["locked_title"], cy + 70, 26, C_WHITE, w,
                    w - 40, bold=True)

    # Sous-titre
    text_center_fit(draw, ld["locked_sub"], cy + 106, 15, C_GRAY, w, w - 40)

    # Hint
    text_center_fit(draw, ld["locked_hint"], cy + 132, 11, (*C_DIM, 200), w,
                    w - 24)

    # Barre bas
    HELP_Y = h - 56
    draw_gradient_rect(draw, 0, HELP_Y, w, h, (12, 15, 28), (8, 10, 20))
    draw.line([(0, HELP_Y), (w, HELP_Y)], fill=(*C_DIVIDER, 200))

    text_center_fit(draw, ld["locked_cancel"], HELP_Y + 17, 13,
                    (220, 100, 100), w, w - 24, bold=True)

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
    draw_title_bar_text(draw, w, TITLE_H, "MIYOO MINI+", ct["title"],
                        26, 12, C_WHITE, (*C_CFG_ACC, 210))
    return img, draw, TITLE_H, ct


def _cfg_bottom(draw, nav_text, w, h, accent=None):
    """Barre de navigation en bas de l'ecran config"""
    if accent is None:
        accent = C_CFG_ACC
    HELP_Y = h - 46
    draw_gradient_rect(draw, 0, HELP_Y, w, h, (11, 14, 26), (7, 9, 18))
    draw.line([(0, HELP_Y), (w, HELP_Y)], fill=(*C_DIVIDER, 180))
    if nav_text:
        text_center_fit(draw, nav_text, HELP_Y + 13, 11, (*C_GRAY, 200), w,
                        w - 12)


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

    # Bloc icone + titre + champ, centre entre les deux barres.
    ICON_R = 36
    f_main = fit_font(draw, "Configuration", w - 40, 20, bold=True)
    f_sub  = fit_font(draw, ct["access_sub"], w - 80, 14)
    main_h = draw.textbbox((0, 0), "Configuration", font=f_main)[3]
    sub_bbox = draw.textbbox((0, 0), ct["access_sub"], font=f_sub)
    sub_h = sub_bbox[3] - sub_bbox[1]

    block_h = ICON_R * 2 + 26 + main_h + 26 + sub_h + 18
    avail_top, avail_bot = TH + 8, h - 54
    top = avail_top + max(0, ((avail_bot - avail_top) - block_h) // 2)

    icon_cy = top + ICON_R
    _draw_settings_icon(draw, cx, icon_cy, ICON_R, C_CFG_ACC)

    text_center(draw, "Configuration", icon_cy + ICON_R + 26, f_main, C_WHITE, w)

    sub_y = icon_cy + ICON_R + 26 + main_h + 26
    bw = sub_bbox[2] - sub_bbox[0] + 32
    bx0, bx1 = (w - bw) // 2, (w + bw) // 2
    draw.rounded_rectangle([bx0, sub_y - 7, bx1, sub_y + sub_h + 11],
                           radius=8, fill=(28, 38, 62), outline=(*C_CFG_ACC, 160), width=1)
    text_center(draw, ct["access_sub"], sub_y - sub_bbox[1] + 2, f_sub,
                (*C_CFG_ACC, 230), w)

    # La consigne rejoint la barre du bas, restee vide jusqu'ici.
    _cfg_bottom(draw, ct["access_hint"], w, h)
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

    accents = [C_CFG_ACC, C_CFG_ACC, C_CFG_ACC, C_VIB_ACC, C_PROT_ACC, C_VIB_ACC, C_SAVE_ACC, C_CANCEL_ACC]

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

        text_x  = MARGIN + 26
        avail_w = (w - MARGIN) - text_x - 10
        font_n = fit_font(draw, name, avail_w, 14, bold=is_sel)
        font_d = fit_font(draw, desc, avail_w, 10)
        nc = C_WHITE if is_sel else lerp_color(C_WHITE, C_DIM, 0.55)
        dc = (*acc, 170) if is_sel else (*C_DIM, 120)

        # Les deux lignes sont reparties dans la hauteur reelle de l'item.
        nb = draw.textbbox((0, 0), name, font=font_n)
        db = draw.textbbox((0, 0), desc, font=font_d)
        nh, dh = nb[3] - nb[1], db[3] - db[1]
        gap = max(2, (ITEM_H - 6 - nh - dh) // 3)
        ny  = iy0 + gap
        dy  = ny + nh + gap

        draw.text((text_x, ny - nb[1]), name, font=font_n, fill=nc)
        draw.text((text_x, dy - db[1]), desc, font=font_d, fill=dc)

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

    text_center_fit(draw, title, TH + 8, 16, (*accent, 220), w, w - 40, bold=True)

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

        inner_w = CARD_W - 16
        font_on = fit_font(draw, opt_name, inner_w, 15, bold=is_sel)
        font_od = fit_font(draw, opt_desc, inner_w, 10)
        oc = C_WHITE if is_sel else lerp_color(C_WHITE, C_DIM, 0.55)
        dc = (*accent, 180) if is_sel else (*C_DIM, 110)

        bbox = draw.textbbox((0, 0), opt_name, font=font_on)
        bbox_d = draw.textbbox((0, 0), opt_desc, font=font_od)
        nh, dh = bbox[3] - bbox[1], bbox_d[3] - bbox_d[1]
        block_top = y0 + CARD_H // 2 - (nh + 8 + dh) // 2

        tw = bbox[2] - bbox[0]
        draw.text((cx_c - tw // 2, block_top - bbox[1]), opt_name,
                  font=font_on, fill=oc)

        dw = bbox_d[2] - bbox_d[0]
        draw.text((cx_c - dw // 2, block_top + nh + 8 - bbox_d[1]), opt_desc,
                  font=font_od, fill=dc)

    _cfg_bottom(draw, ct["choice_nav"], w, h, accent)
    return img


def create_config_entry(entry_type: str, lang="FR", w=640, h=480) -> Image.Image:
    """Ecran de saisie d'une nouvelle sequence de boutons.
    entry_type : "pw" (8 slots) / "cfg" (8 slots) / "konami" (10 slots)
    """
    img, draw, TH, ct = _cfg_base(lang, w, h)
    cx = w // 2

    if entry_type == "konami":
        title, sub, accent = ct["konami_title"], ct["konami_sub"], C_VIB_ACC
        slot_count = 10
    elif entry_type == "pw":
        title, sub, accent = ct["pw_title"], ct["pw_sub"], C_PROT_ACC
        slot_count = 8
    else:
        title, sub, accent = ct["cfg_title"], ct["cfg_sub"], C_CFG_ACC
        slot_count = 8

    # Le contenu est centre entre la barre de titre et la barre du bas :
    # il restait auparavant tasse dans la moitie haute de l'ecran.
    if lang == "FR":
        unit = "boutons"
    elif lang == "ES":
        unit = "botones"
    else:
        unit = "buttons"
    hint1 = "%s  (max %d %s)" % (ct["entry_hint1"], slot_count, unit)

    f_title = fit_font(draw, title, w - 40, 16, bold=True)
    f_sub   = fit_font(draw, sub, w - 32, 14)
    f_h1    = fit_font(draw, hint1, w - 96, 11)
    f_btns  = fit_font(draw, ct["entry_btns"], w - 16, 11)

    title_h = draw.textbbox((0, 0), title, font=f_title)[3]
    sub_h   = draw.textbbox((0, 0), sub, font=f_sub)[3]
    h1h     = draw.textbbox((0, 0), hint1, font=f_h1)[3]
    btns_h  = draw.textbbox((0, 0), ct["entry_btns"], font=f_btns)[3]

    SLOT_H  = 46
    box_h   = h1h + 22
    block_h = title_h + 14 + sub_h + 26 + SLOT_H + 24 + box_h + 18 + btns_h

    avail_top = TH + 8
    avail_bot = h - 54
    top = avail_top + max(0, ((avail_bot - avail_top) - block_h) // 2)

    text_center(draw, title, top, f_title, (*accent, 220), w)
    text_center(draw, sub, top + title_h + 14, f_sub, C_WHITE, w)

    # Slots de saisie (largeur adaptee au nombre)
    SY      = top + title_h + 14 + sub_h + 26
    SLOT_G  = 8 if slot_count >= 10 else 10
    AVAIL   = w - 2 * 36
    SLOT_W  = (AVAIL - (slot_count - 1) * SLOT_G) // slot_count
    if SLOT_W > 52: SLOT_W = 52
    TOTAL   = slot_count * SLOT_W + (slot_count - 1) * SLOT_G
    sx0     = (w - TOTAL) // 2

    for s in range(slot_count):
        sx = sx0 + s * (SLOT_W + SLOT_G)
        draw.rounded_rectangle([sx, SY, sx + SLOT_W, SY + SLOT_H],
                               radius=6, fill=(20, 26, 44),
                               outline=(*C_DIM, 110), width=1)
        mid_y = SY + SLOT_H // 2
        line_pad = max(10, SLOT_W // 4)
        draw.line([(sx + line_pad, mid_y), (sx + SLOT_W - line_pad, mid_y)],
                 fill=(*C_DIM, 90), width=2)

    # Encadre de la consigne principale.
    IY = SY + SLOT_H + 24
    draw.rounded_rectangle([36, IY - 8, w - 36, IY + box_h],
                           radius=8, fill=(18, 24, 42), outline=(*accent, 90), width=1)
    text_center(draw, hint1, IY + 4, f_h1, C_GRAY, w)

    # Liste des boutons valides : longue ligne, retrecie pour tenir en largeur.
    text_center(draw, ct["entry_btns"], IY + box_h + 18, f_btns, C_DIM, w)

    # La consigne de validation rejoint la barre du bas, comme sur les
    # autres ecrans : cette barre restait vide.
    _cfg_bottom(draw, ct["entry_hint2"], w, h, accent)
    return img


def create_config_bootmode(option_idx: int, lang="FR", w=640, h=480) -> Image.Image:
    """Ecran de choix du mode de demarrage (3 cartes horizontales)."""
    img, draw, TH, ct = _cfg_base(lang, w, h)

    title   = ct["bootmode_title"]
    options = ct["bootmode_options"]
    accent  = C_PROT_ACC

    text_center_fit(draw, title, TH + 8, 16, (*accent, 220), w, w - 40, bold=True)

    GRID_TOP = TH + 40
    GRID_BOT = h - 50
    PAD      = 12
    CARD_W   = (w - 4 * PAD) // 3
    # Hauteur plafonnee et rangee centree : occuper toute la hauteur
    # disponible donnait des cartes tres elancees pour un contenu court,
    # surtout en 752x560.
    CARD_H   = min(GRID_BOT - GRID_TOP - PAD, int(CARD_W * 1.15))
    ROW_TOP  = GRID_TOP + max(0, ((GRID_BOT - GRID_TOP) - CARD_H) // 2)

    positions = [
        (PAD,                          ROW_TOP),
        (PAD * 2 + CARD_W,             ROW_TOP),
        (PAD * 3 + CARD_W * 2,         ROW_TOP),
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

        # Le contenu (icone, nom, description) est centre verticalement :
        # il restait auparavant colle en haut d'une carte tres allongee.
        inner_w_pre = CARD_W - 12
        font_on_pre = fit_font(draw, opt_name, inner_w_pre, 13, bold=is_sel)
        font_od_pre = get_font(9)
        name_h = draw.textbbox((0, 0), opt_name, font=font_on_pre)[3]
        line_h_pre = draw.textbbox((0, 0), "Ag", font=font_od_pre)[3] + 3

        # Nombre de lignes qu'occupera la description une fois repliee.
        _line, _n_lines = "", 0
        for _word in opt_desc.split():
            _try = (_line + " " + _word).strip()
            if draw.textbbox((0, 0), _try, font=font_od_pre)[2] > inner_w_pre and _line:
                _n_lines += 1
                _line = _word
            else:
                _line = _try
        if _line:
            _n_lines += 1
        _n_lines = min(3, _n_lines)

        ICON_H = 30
        block_h = ICON_H + 18 + name_h + 12 + _n_lines * line_h_pre
        block_top = y0 + max(10, (CARD_H - block_h) // 2)

        # Icone : carre pour menu, oeil pour stealth
        icon_cy = block_top + ICON_H // 2
        if i == 0:
            # Menu : grille 2x2
            for ix in range(2):
                for iy in range(2):
                    rx = cx_c - 14 + ix * 16
                    ry = icon_cy - 8 + iy * 8
                    draw.rectangle([rx, ry, rx + 12, ry + 5],
                                   fill=(*accent, 230 if is_sel else 130))
        else:
            # Stealth : oeil ferme stylise
            draw.arc([cx_c - 22, icon_cy - 12, cx_c + 22, icon_cy + 12],
                     start=190, end=350,
                     fill=(*accent, 230 if is_sel else 130), width=3)
            draw.ellipse([cx_c - 5, icon_cy - 2, cx_c + 5, icon_cy + 8],
                         fill=(*accent, 200 if is_sel else 100))

        inner_w = inner_w_pre
        font_on = font_on_pre
        font_od = font_od_pre
        oc = C_WHITE if is_sel else lerp_color(C_WHITE, C_DIM, 0.55)
        dc = (*accent, 180) if is_sel else (*C_DIM, 110)

        bbox = draw.textbbox((0, 0), opt_name, font=font_on)
        tw = bbox[2] - bbox[0]
        text_y = block_top + ICON_H + 18
        draw.text((cx_c - tw // 2, text_y), opt_name, font=font_on, fill=oc)

        # Description multi-lignes si trop long
        desc_y = text_y + (bbox[3] - bbox[1]) + 12
        desc_words = opt_desc.split()
        line, lines = "", []
        for word in desc_words:
            tentative = (line + " " + word).strip()
            bb = draw.textbbox((0, 0), tentative, font=font_od)
            if bb[2] - bb[0] > inner_w and line:
                lines.append(line)
                line = word
            else:
                line = tentative
        if line:
            lines.append(line)
        line_h = draw.textbbox((0, 0), "Ag", font=font_od)[3] + 3
        max_lines = max(1, (y1 - 6 - desc_y) // line_h)
        for li, ltext in enumerate(lines[:min(3, max_lines)]):
            bb = draw.textbbox((0, 0), ltext, font=font_od)
            lw = bb[2] - bb[0]
            draw.text((cx_c - lw // 2, desc_y + li * line_h), ltext,
                      font=font_od, fill=dc)

    _cfg_bottom(draw, ct["choice_nav"], w, h, accent)
    return img


def create_config_saved(lang="FR", w=640, h=480) -> Image.Image:
    """Ecran de confirmation : configuration sauvegardee"""
    img, draw, TH, ct = _cfg_base(lang, w, h)
    cx = w // 2
    acc = C_SAVE_ACC

    r = 44
    f_title = fit_font(draw, ct["saved_title"], w - 32, 20, bold=True)
    f_sub   = fit_font(draw, ct["saved_sub"], w - 32, 13)
    title_h = draw.textbbox((0, 0), ct["saved_title"], font=f_title)[3]
    sub_h   = draw.textbbox((0, 0), ct["saved_sub"], font=f_sub)[3]

    block_h = r * 2 + 24 + title_h + 16 + sub_h
    avail_top, avail_bot = TH + 8, h - 54
    icon_cy = avail_top + max(0, ((avail_bot - avail_top) - block_h) // 2) + r

    draw.ellipse([cx - r, icon_cy - r, cx + r, icon_cy + r],
                 fill=(16, 46, 26), outline=(*acc, 220), width=4)
    pts = [(cx - 18, icon_cy + 2), (cx - 4, icon_cy + 18), (cx + 20, icon_cy - 16)]
    for j in range(len(pts) - 1):
        draw.line([pts[j], pts[j + 1]], fill=(*acc, 255), width=5)

    text_center(draw, ct["saved_title"], icon_cy + r + 24, f_title, C_WHITE, w)
    text_center(draw, ct["saved_sub"], icon_cy + r + 24 + title_h + 16, f_sub,
                C_GRAY, w)

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


def _save_preview(img, filename):
    """Ecrit un apercu PNG dans preview/, a cote du script.

    Les apercus etaient auparavant deposes a la racine du depot, ou ils
    etaient ignores par git et ne servaient a rien.
    """
    preview_dir = os.path.join(OUTPUT_DIR, "preview")
    os.makedirs(preview_dir, exist_ok=True)
    img.save(os.path.join(preview_dir, filename), "PNG", optimize=True)


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

            raw_path = os.path.join(sd_res, f"bootmenu_{os_name}_{lang}{suffix}.raw")
            nb = save_raw(img, raw_path)
            print(f"     RAW : {raw_path} ({nb} octets)")

            # Ecran verrouille
            print(f"  -> bootmenu_locked_{os_name}_{lang}{suffix} ...")
            img_lock = create_locked_screen(os_name, lang, w, h)

            raw_lock = os.path.join(sd_res, f"bootmenu_locked_{os_name}_{lang}{suffix}.raw")
            nb_lock  = save_raw(img_lock, raw_lock)
            print(f"     RAW : {raw_lock} ({nb_lock} octets)")

            # Apercus : uniquement en francais et en resolution de base, ecrits
            # directement dans preview/ (ceux du depot et ceux du README).
            if lang == "FR" and not suffix:
                _save_preview(img, f"bootmenu_{os_name}_FR.png")
                _save_preview(img_lock, f"bootmenu_locked_{os_name}_FR.png")

    # ── Images du menu de configuration ──────────────────────────
    print(f"\n{'-'*30}")
    print(f"  Images Menu Configuration  [{w}x{h}]")
    print(f"{'-'*30}")

    cfg_specs = []
    cfg_specs.append(("config_access", None, None))
    for i in range(8):
        cfg_specs.append((f"config_main_{i}", "main", i))
    for i in range(4):
        cfg_specs.append((f"config_protect_{i}", "protect", i))
    for i in range(4):
        cfg_specs.append((f"config_vib_{i}", "vib", i))
    for i in range(3):
        cfg_specs.append((f"config_bootmode_{i}", "bootmode", i))
    cfg_specs.append(("config_pw_entry",     "entry_pw",     None))
    cfg_specs.append(("config_cfg_entry",    "entry_cfg",    None))
    cfg_specs.append(("config_konami_entry", "entry_konami", None))
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
            elif kind == "bootmode":
                img = create_config_bootmode(idx, lang, w, h)
            elif kind == "entry_pw":
                img = create_config_entry("pw", lang, w, h)
            elif kind == "entry_cfg":
                img = create_config_entry("cfg", lang, w, h)
            elif kind == "entry_konami":
                img = create_config_entry("konami", lang, w, h)
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
                _save_preview(img, f"bootmenu_{name}_FR.png")


# ── Point d'entree ────────────────────────────────────────────

def main():
    print("=" * 56)
    print("  Generateur Boot Menu Miyoo Mini / Mini+ / Mini Flip")
    print("  Langues : FR / EN / ES")
    print("=" * 56)

    # Sans police vectorielle, toutes les tailles rendraient identiquement.
    check_fonts()

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
