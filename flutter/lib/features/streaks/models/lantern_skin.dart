// A cosmetic "skin" for the lantern companion — a swappable material palette fed
// into the ONE code-drawn `LanternPainter`. Because the painter draws the whole
// fānūs from parameters (metal gradient, glow, flame, khatam light, embers), a
// skin is just a set of colors: the animation, glow physics, and the iOS-widget
// PNG export all come along for free. No new assets, ~0 KB per skin.
//
// What a skin changes: the housing metal gradient, the trim/highlight, the light
// (glow/flame/rays/khatam), the ember sparks, and the glass tint. What it does
// NOT change: the flame's white-hot core + cool wick-base (kept constant so fire
// still reads as fire), and the cold "dormant" lapse styling (a snuffed lamp is
// snuffed regardless of skin).
//
// PROTOTYPE NOTE (2026-07-25): introduced to evaluate premium skins. `classicGold`
// reproduces the exact production palette, so `LanternPainter` with no `skin`
// argument renders identically to before.

import 'package:flutter/material.dart';

/// The dome silhouette.
enum DomeShape { onion, ogee, tiered }

/// The crowning ornament above the dome.
enum FinialType { ring, crescent, star, crescentStar }

/// The *sculpted* part of a skin — geometry + ornament, distinct from the color
/// palette. Defaults reproduce the original lantern, so recolor-only skins leave
/// this untouched.
@immutable
class LanternForm {
  const LanternForm({
    this.dome = DomeShape.onion,
    this.finial = FinialType.ring,
    this.archedWindow = false,
    this.lattice = false,
    this.tassel = false,
  });

  final DomeShape dome;
  final FinialType finial;

  /// Carve a pointed (keel/mihrab) arch above the glass panel.
  final bool archedWindow;

  /// Overlay a faint mashrabiya lattice across the glass.
  final bool lattice;

  /// Hang a decorative tassel beneath the base.
  final bool tassel;

  static const classic = LanternForm();
}

@immutable
class LanternSkin {
  const LanternSkin({
    required this.id,
    required this.name,
    required this.blurb,
    required this.metalTop,
    required this.metalMid,
    required this.metalBot,
    required this.metalDark,
    required this.highlight,
    required this.glow,
    required this.ember,
    required this.glass,
    required this.dustyTop,
    required this.dustyBot,
    this.form = LanternForm.classic,
  });

  /// Stable identifier (store SKU / inventory key).
  final String id;

  /// Display name shown in the wardrobe/store.
  final String name;

  /// One-line flavor text.
  final String blurb;

  // Housing metal gradient (top → mid → bottom of the body/dome/base).
  final Color metalTop;
  final Color metalMid;
  final Color metalBot;

  /// Deep shadow / facet lines on the metal.
  final Color metalDark;

  /// Rim light + specular highlight (also tints the flame's inner body).
  final Color highlight;

  /// The emitted warm light — glow pool, halo, god-rays, khatam light, flame body.
  final Color glow;

  /// Rising ember sparks on a strong streak.
  final Color ember;

  /// The dark glass panel tint behind the khatam.
  final Color glass;

  // The tarnished/worn version of the metal (low streak). Kept per-skin so a
  // silver lamp tarnishes to grey pewter, a jade lamp to muddy green, etc.
  final Color dustyTop;
  final Color dustyBot;

  /// Geometry + ornament. Recolor skins keep the classic form.
  final LanternForm form;

  /// The production default — identical to the original hardcoded gold palette.
  static const classicGold = LanternSkin(
    id: 'classic_gold',
    name: 'Classic Brass',
    blurb: 'The lantern you know — warm hand-beaten brass.',
    metalTop: Color(0xFFF0D8A0),
    metalMid: Color(0xFFD9A968),
    metalBot: Color(0xFFB07E45),
    metalDark: Color(0xFF6E4F28),
    highlight: Color(0xFFFBE7BE),
    glow: Color(0xFFE8A154),
    ember: Color(0xFFFFD089),
    glass: Color(0xFF0C3120),
    dustyTop: Color(0xFFAFA07C),
    dustyBot: Color(0xFF6B5F44),
  );

  /// Cool pewter-silver housing, icy moonlight glow.
  static const moonlitSilver = LanternSkin(
    id: 'moonlit_silver',
    name: 'Moonlit Silver',
    blurb: 'Brushed silver that catches a cool night light.',
    metalTop: Color(0xFFEAF0F6),
    metalMid: Color(0xFFB6C3D1),
    metalBot: Color(0xFF83909F),
    metalDark: Color(0xFF45505B),
    highlight: Color(0xFFF4F9FD),
    glow: Color(0xFF9DC6EC),
    ember: Color(0xFFD4E8FF),
    glass: Color(0xFF141F2B),
    dustyTop: Color(0xFF9AA4AF),
    dustyBot: Color(0xFF5C6570),
  );

  /// Deep jade housing (the brand emerald) with a warm gold light within.
  static const emeraldJade = LanternSkin(
    id: 'emerald_jade',
    name: 'Emerald Jade',
    blurb: 'Carved jade cradling a warm golden flame.',
    metalTop: Color(0xFF43A57E),
    metalMid: Color(0xFF1B6B4A),
    metalBot: Color(0xFF0F4A32),
    metalDark: Color(0xFF072F1E),
    highlight: Color(0xFFCFF3E2),
    glow: Color(0xFFEBC97A),
    ember: Color(0xFFFFE3A6),
    glass: Color(0xFF06271A),
    dustyTop: Color(0xFF6E8A78),
    dustyBot: Color(0xFF3A5044),
  );

  /// Near-black lacquer with gold trim — dramatic, night-premium.
  static const obsidianGold = LanternSkin(
    id: 'obsidian_gold',
    name: 'Obsidian & Gold',
    blurb: 'Black lacquer edged in gold — light against the dark.',
    metalTop: Color(0xFF41414A),
    metalMid: Color(0xFF26262D),
    metalBot: Color(0xFF16161B),
    metalDark: Color(0xFF070709),
    highlight: Color(0xFFEBC87E),
    glow: Color(0xFFE8A154),
    ember: Color(0xFFFFD089),
    glass: Color(0xFF090A0D),
    dustyTop: Color(0xFF3A3A42),
    dustyBot: Color(0xFF1E1E23),
  );

  /// Soft blush metal with a rose-gold glow — gentle and warm.
  static const roseQuartz = LanternSkin(
    id: 'rose_quartz',
    name: 'Rose Quartz',
    blurb: 'Blush-pink metal and a soft rose-gold light.',
    metalTop: Color(0xFFF7DAD2),
    metalMid: Color(0xFFE1A89E),
    metalBot: Color(0xFFC17F77),
    metalDark: Color(0xFF7E4E48),
    highlight: Color(0xFFFEEDE7),
    glow: Color(0xFFF0A98C),
    ember: Color(0xFFFFCBB0),
    glass: Color(0xFF2A1317),
    dustyTop: Color(0xFFC7ABA5),
    dustyBot: Color(0xFF7A5D57),
  );

  /// Richer royal gold + deep emerald glass — the seasonal Ramadan skin.
  static const ramadanGold = LanternSkin(
    id: 'ramadan_gold',
    name: 'Ramadan Gold',
    blurb: 'Royal gold and deep emerald for the blessed month.',
    metalTop: Color(0xFFFCE9A8),
    metalMid: Color(0xFFE8B84E),
    metalBot: Color(0xFFB8862E),
    metalDark: Color(0xFF6E4A16),
    highlight: Color(0xFFFFF6D8),
    glow: Color(0xFFFFC24D),
    ember: Color(0xFFFFE08A),
    glass: Color(0xFF06301E),
    dustyTop: Color(0xFFC9B27A),
    dustyBot: Color(0xFF7A6234),
  );

  // ── Sculpted "hero" skins — geometry + ornament, not just recolor ──────────

  /// Ogee dome, crescent-and-star finial, mihrab-arched window, mashrabiya screen.
  static const masjidBrass = LanternSkin(
    id: 'masjid_brass',
    name: 'Masjid Lantern',
    blurb: 'Ogee dome, crescent-and-star, a mashrabiya screen.',
    metalTop: Color(0xFFF3DCA2),
    metalMid: Color(0xFFD8A55E),
    metalBot: Color(0xFFA9762F),
    metalDark: Color(0xFF5F4118),
    highlight: Color(0xFFFDEFC6),
    glow: Color(0xFFEEB65C),
    ember: Color(0xFFFFDD97),
    glass: Color(0xFF0A2A1B),
    dustyTop: Color(0xFFB0A078),
    dustyBot: Color(0xFF6A5A3A),
    form: LanternForm(
      dome: DomeShape.ogee,
      finial: FinialType.crescentStar,
      archedWindow: true,
      lattice: true,
    ),
  );

  /// Pointed dome + star finial, translucent crystal glass — cool and faceted.
  static const crystalStar = LanternSkin(
    id: 'crystal_star',
    name: 'Crystal Star',
    blurb: 'A pointed crown and a single guiding star.',
    metalTop: Color(0xFFE7EEF5),
    metalMid: Color(0xFFAFC0D2),
    metalBot: Color(0xFF7C8DA0),
    metalDark: Color(0xFF414D5A),
    highlight: Color(0xFFF6FAFE),
    glow: Color(0xFFAFD2F2),
    ember: Color(0xFFDCEEFF),
    glass: Color(0xFF1C2E3E),
    dustyTop: Color(0xFF9FA9B4),
    dustyBot: Color(0xFF5E6772),
    form: LanternForm(
      dome: DomeShape.ogee,
      finial: FinialType.star,
    ),
  );

  /// Tiered minaret dome, crescent finial, arched screen + hanging tassel.
  static const ramadanRoyal = LanternSkin(
    id: 'ramadan_royal',
    name: 'Ramadan Royal',
    blurb: 'A tiered minaret crown, crescent, and a hanging tassel.',
    metalTop: Color(0xFFFDEBAC),
    metalMid: Color(0xFFE9BA50),
    metalBot: Color(0xFFB5842C),
    metalDark: Color(0xFF6B4814),
    highlight: Color(0xFFFFF7DC),
    glow: Color(0xFFFFC24D),
    ember: Color(0xFFFFE28E),
    glass: Color(0xFF06301E),
    dustyTop: Color(0xFFC9B27A),
    dustyBot: Color(0xFF7A6234),
    form: LanternForm(
      dome: DomeShape.tiered,
      finial: FinialType.crescent,
      archedWindow: true,
      lattice: true,
      tassel: true,
    ),
  );

  /// All recolor skins in showcase order.
  static const all = <LanternSkin>[
    classicGold,
    moonlitSilver,
    emeraldJade,
    obsidianGold,
    roseQuartz,
    ramadanGold,
  ];

  /// The sculpted hero skins (geometry + ornament).
  static const sculpted = <LanternSkin>[
    masjidBrass,
    crystalStar,
    ramadanRoyal,
  ];
}
