#!/usr/bin/env python3
# ─────────────────────────────────────────────────────────────
#  NOLAM Adagio — Assistant d'adaptation (wizard)
#
#  « C'est à la machine de s'adapter à vous, pas l'inverse. »
#
#  Adapte le bureau Cinnamon à l'utilisateur, avec APERÇU EN DIRECT.
#  Mode rapide (3 portes) + réglage fin. Écrit un profil réutilisable.
#  Multilingue (gettext) : FR (base) + DE ; suit la langue du système.
#
#  Copyright (C) 2026 dpan-Bug / NOLAM
#  SPDX-License-Identifier: GPL-3.0-or-later
# ─────────────────────────────────────────────────────────────
import os
import gettext
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gio, Gdk

# ── i18n (gettext) ───────────────────────────────────────────
# Les chaînes du code sont en français (langue de base = msgid).
# Une langue = un fichier locale/<lg>/LC_MESSAGES/nolam-adagio.mo
# Le wizard suit la langue du système (LANG/LANGUAGE), override possible.
APP = "nolam-adagio"
LOCALE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "locale")
try:
    gettext.bindtextdomain(APP, LOCALE_DIR)
    gettext.textdomain(APP)
except Exception:
    pass
_ = gettext.gettext

# ── Moteur de réglages (live via Gio.Settings) ───────────────
def _settings(schema):
    """Retourne un Gio.Settings si le schéma existe, sinon None."""
    try:
        src = Gio.SettingsSchemaSource.get_default()
        if src and src.lookup(schema, True):
            return Gio.Settings.new(schema)
    except Exception:
        pass
    return None

IFACE   = _settings("org.cinnamon.desktop.interface")
GIFACE  = _settings("org.gnome.desktop.interface")
WM      = _settings("org.cinnamon.desktop.wm.preferences")
CTHEME  = _settings("org.cinnamon.theme")
NEMO    = _settings("org.nemo.preferences")
SCR     = _settings("org.cinnamon.desktop.screensaver")
SESS    = _settings("org.cinnamon.desktop.session")

def set_text_scale(v):
    for s in (IFACE, GIFACE):
        if s: s.set_double("text-scaling-factor", round(float(v), 2))

def get_text_scale():
    return IFACE.get_double("text-scaling-factor") if IFACE else 1.0

def set_cursor(v):
    for s in (IFACE, GIFACE):
        if s: s.set_int("cursor-size", int(v))

def get_cursor():
    return IFACE.get_int("cursor-size") if IFACE else 24

def set_theme(name):
    if IFACE:
        IFACE.set_string("gtk-theme", name)
        IFACE.set_string("icon-theme", name)
    if GIFACE: GIFACE.set_string("gtk-theme", name)
    if CTHEME: CTHEME.set_string("name", name)
    if WM:     WM.set_string("theme", name)

def set_click(policy):           # 'single' | 'double'
    if NEMO: NEMO.set_string("click-policy", policy)

def set_no_lock():
    if SCR:
        SCR.set_boolean("lock-enabled", False)
        SCR.set_boolean("idle-activation-enabled", False)
    if SESS: SESS.set_uint("idle-delay", 0)

THEME_CLAIR    = "Mint-Y"
THEME_SOMBRE   = "Mint-Y-Dark"
THEME_CONTRAST = "Mint-Y-Dark"

def profil_vois_mal():
    set_text_scale(1.7); set_cursor(48); set_theme(THEME_CONTRAST)
    set_click("single"); set_no_lock()

def profil_gestes():
    set_text_scale(1.3); set_cursor(48); set_theme(THEME_CLAIR)
    set_click("single"); set_no_lock()

def profil_debute():
    set_text_scale(1.4); set_cursor(36); set_theme(THEME_CLAIR)
    set_click("single"); set_no_lock()

# ── Écriture du profil (.conf réutilisable) ──────────────────
def ecrire_profil():
    d = os.path.expanduser("~/.config/nolam-adagio")
    os.makedirs(d, exist_ok=True)
    path = os.path.join(d, "mon-profil.conf")
    lignes = [
        "# Profil genere par l'assistant NOLAM Adagio",
        "[org.cinnamon.desktop.interface]",
        f"text-scaling-factor = {get_text_scale():.2f}",
        f"cursor-size = {get_cursor()}",
        f"gtk-theme = {IFACE.get_string('gtk-theme') if IFACE else 'Mint-Y'}",
        f"icon-theme = {IFACE.get_string('icon-theme') if IFACE else 'Mint-Y'}",
        "",
        "[org.cinnamon.theme]",
        f"name = {CTHEME.get_string('name') if CTHEME else 'Mint-Y'}",
        "",
        "[org.nemo.preferences]",
        f"click-policy = {NEMO.get_string('click-policy') if NEMO else 'single'}",
        "",
        "[org.cinnamon.desktop.screensaver]",
        "lock-enabled = false",
        "",
    ]
    with open(path, "w") as f:
        f.write("\n".join(lignes))
    return path

# ── Interface ────────────────────────────────────────────────
CSS = b"""
* { font-size: 15pt; }
.titre   { font-size: 28pt; font-weight: bold; }
.manifeste { font-size: 17pt; font-style: italic; }
.porte   { font-size: 19pt; padding: 26px; margin: 8px; }
.gros    { font-size: 22pt; font-weight: bold; padding: 10px 26px; }
.echantillon { font-size: 16pt; padding: 14px; border: 2px solid #888; border-radius: 8px; }
button   { padding: 12px 20px; }
"""

class Wizard(Gtk.Window):
    def __init__(self):
        super().__init__(title=_("NOLAM Adagio — Adapter mon écran"))
        self.set_default_size(820, 600)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_border_width(24)

        prov = Gtk.CssProvider(); prov.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), prov,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.add(self.stack)

        self.stack.add_named(self._accueil(), "accueil")
        self.stack.add_named(self._portes(), "portes")
        self.stack.add_named(self._reglage_fin(), "fin")
        self.stack.add_named(self._fini(), "fini")
        self.stack.set_visible_child_name("accueil")

    def _nav(self, retour=None, suite=None, suite_label=None):
        if suite_label is None:
            suite_label = _("Continuer  ▶")
        box = Gtk.Box(spacing=12)
        if retour:
            b = Gtk.Button(label=_("◀  Retour"))
            b.connect("clicked", lambda *_a: self.stack.set_visible_child_name(retour))
            box.pack_start(b, False, False, 0)
        box.pack_start(Gtk.Box(), True, True, 0)
        if suite:
            b = Gtk.Button(label=suite_label); b.get_style_context().add_class("gros")
            b.connect("clicked", lambda *_a: suite())
            box.pack_end(b, False, False, 0)
        return box

    def _accueil(self):
        v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=22)
        t = Gtk.Label(label=_("Bienvenue 👋")); t.get_style_context().add_class("titre")
        m = Gtk.Label(label=_("« C'est à la machine de s'adapter à vous,\npas à vous de vous adapter à la machine. »"))
        m.get_style_context().add_class("manifeste"); m.set_justify(Gtk.Justification.CENTER)
        d = Gtk.Label(label=_("Nous allons régler votre écran ensemble,\nà votre confort. À chaque étape, vous voyez le résultat tout de suite."))
        d.set_justify(Gtk.Justification.CENTER)
        v.pack_start(Gtk.Box(), True, True, 0)
        v.pack_start(t, False, False, 0)
        v.pack_start(m, False, False, 0)
        v.pack_start(d, False, False, 0)
        v.pack_start(Gtk.Box(), True, True, 0)
        v.pack_end(self._nav(suite=lambda: self.stack.set_visible_child_name("portes"),
                             suite_label=_("Commencer  ▶")), False, False, 0)
        return v

    def _portes(self):
        v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        t = Gtk.Label(label=_("Qu'est-ce qui vous ressemble le plus ?"))
        t.get_style_context().add_class("titre")
        v.pack_start(t, False, False, 0)
        v.pack_start(Gtk.Label(label=_("(on pourra tout ajuster ensuite)")), False, False, 0)

        def porte(txt, sous, fn):
            b = Gtk.Button()
            inner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            l1 = Gtk.Label(label=txt); l1.get_style_context().add_class("porte")
            l2 = Gtk.Label(label=sous)
            inner.pack_start(l1, False, False, 0); inner.pack_start(l2, False, False, 0)
            b.add(inner)
            def go(*_a):
                fn(); self.stack.set_visible_child_name("fin")
            b.connect("clicked", go)
            return b

        v.pack_start(porte(_("👁  Je vois mal"), _("Texte très grand, fort contraste, gros curseur"), profil_vois_mal), False, False, 0)
        v.pack_start(porte(_("✋  Mes gestes sont difficiles"), _("Un seul clic, grand curseur, grandes cibles"), profil_gestes), False, False, 0)
        v.pack_start(porte(_("🌱  Je débute / je veux simple"), _("Plus grand, plus clair, plus calme"), profil_debute), False, False, 0)
        v.pack_end(self._nav(retour="accueil"), False, False, 0)
        return v

    def _reglage_fin(self):
        v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        t = Gtk.Label(label=_("À votre main")); t.get_style_context().add_class("titre")
        v.pack_start(t, False, False, 0)

        self.echantillon = Gtk.Label(label=_("Voici un exemple de texte. Est-il agréable à lire ?"))
        self.echantillon.get_style_context().add_class("echantillon")
        self.echantillon.set_line_wrap(True)
        v.pack_start(self.echantillon, False, False, 0)

        v.pack_start(self._ligne_pm(_("Taille du texte"),
            lambda: set_text_scale(min(2.5, get_text_scale()+0.1)),
            lambda: set_text_scale(max(1.0, get_text_scale()-0.1))), False, False, 0)
        v.pack_start(self._ligne_pm(_("Taille du curseur"),
            lambda: set_cursor(min(96, get_cursor()+8)),
            lambda: set_cursor(max(16, get_cursor()-8))), False, False, 0)

        amb = Gtk.Box(spacing=10)
        amb.pack_start(Gtk.Label(label=_("Ambiance :")), False, False, 0)
        for lbl, name in ((_("☀ Clair"), THEME_CLAIR), (_("🌙 Sombre"), THEME_SOMBRE), (_("◐ Contraste"), THEME_CONTRAST)):
            b = Gtk.Button(label=lbl)
            b.connect("clicked", lambda _w, n=name: set_theme(n))
            amb.pack_start(b, True, True, 0)
        v.pack_start(amb, False, False, 0)

        clic = Gtk.Box(spacing=10)
        clic.pack_start(Gtk.Label(label=_("Pour ouvrir :")), False, False, 0)
        b1 = Gtk.Button(label=_("Un seul clic")); b1.connect("clicked", lambda *_a: set_click("single"))
        b2 = Gtk.Button(label=_("Double clic")); b2.connect("clicked", lambda *_a: set_click("double"))
        clic.pack_start(b1, True, True, 0); clic.pack_start(b2, True, True, 0)
        v.pack_start(clic, False, False, 0)

        v.pack_end(self._nav(retour="portes",
            suite=lambda: (ecrire_profil(), self.stack.set_visible_child_name("fini")),
            suite_label=_("C'est parfait  ▶")), False, False, 0)
        return v

    def _ligne_pm(self, titre, plus, moins):
        h = Gtk.Box(spacing=12)
        h.pack_start(Gtk.Label(label=titre), False, False, 0)
        h.pack_start(Gtk.Box(), True, True, 0)
        bm = Gtk.Button(label="A −"); bm.get_style_context().add_class("gros")
        bp = Gtk.Button(label="A +"); bp.get_style_context().add_class("gros")
        bm.connect("clicked", lambda *_a: moins())
        bp.connect("clicked", lambda *_a: plus())
        h.pack_start(bm, False, False, 0); h.pack_start(bp, False, False, 0)
        return h

    def _fini(self):
        v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=22)
        v.pack_start(Gtk.Box(), True, True, 0)
        t = Gtk.Label(label=_("Voilà, c'est à vous ✨")); t.get_style_context().add_class("titre")
        d = Gtk.Label(label=_("Votre réglage est enregistré.\nVous pourrez le retrouver à tout moment :\n« Adapter mon écran »."))
        d.set_justify(Gtk.Justification.CENTER)
        v.pack_start(t, False, False, 0); v.pack_start(d, False, False, 0)
        v.pack_start(Gtk.Box(), True, True, 0)
        b = Gtk.Button(label=_("Terminer")); b.get_style_context().add_class("gros")
        b.connect("clicked", lambda *_a: Gtk.main_quit())
        box = Gtk.Box(); box.pack_start(Gtk.Box(), True, True, 0); box.pack_end(b, False, False, 0)
        v.pack_end(box, False, False, 0)
        return v


def main():
    w = Wizard()
    w.connect("destroy", Gtk.main_quit)
    w.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
