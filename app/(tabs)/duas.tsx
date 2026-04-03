import React, { useState, useRef, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  Animated,
} from 'react-native';
import { Colors } from '@/constants/colors';
import { DUAS, DUA_CATEGORIES, type DuaCategory } from '@/constants/duas';
import { DuaCard } from '@/components/DuaCard';
import { getSavedDuas, toggleSavedDua } from '@/lib/supabase';
import { findDuas, buildDua, type FindDuasResponse, type BuiltDua } from '@/lib/claude';
import { saveBuiltDua } from '@/lib/savedDuas';
import { getDuaSuggestions, markDuaRead, type DuaSuggestion } from '@/lib/duaSuggestions';
import { awardXP, type XPState } from '@/lib/xp';
import { XPCelebration } from '@/components/XPCelebration';

type Tab = 'browse' | 'find' | 'build';

// ─── Reusable expandable row ──────────────────────────────────────────────────
function ExpandRow({ label, children }: { label: string; children: React.ReactNode }) {
  const [open, setOpen] = useState(false);
  return (
    <View>
      <TouchableOpacity
        style={styles.expandRow}
        onPress={() => setOpen(v => !v)}
        activeOpacity={0.7}
      >
        <Text style={styles.expandRowLabel}>{label}</Text>
        <Text style={styles.expandRowChevron}>{open ? '▲' : '▽'}</Text>
      </TouchableOpacity>
      {open && <View style={styles.expandRowBody}>{children}</View>}
    </View>
  );
}

// ─── Find dua card ────────────────────────────────────────────────────────────
function FindDuaCard({ dua }: {
  dua: { title: string; arabic: string; transliteration: string; translation: string; source: string };
}) {
  return (
    <View style={styles.findDuaCard}>
      <Text style={styles.findDuaTitle}>{dua.title}</Text>
      <Text style={styles.findDuaArabic}>{dua.arabic}</Text>
      <View style={styles.findDuaDivider} />
      <ExpandRow label="Transliteration">
        <Text style={styles.expandTextItalic}>{dua.transliteration}</Text>
      </ExpandRow>
      <ExpandRow label="Translation">
        <Text style={styles.expandText}>{dua.translation}</Text>
        {dua.source ? <Text style={styles.findDuaSource}>{dua.source}</Text> : null}
      </ExpandRow>
    </View>
  );
}

// ─── Browse tab ───────────────────────────────────────────────────────────────
function BrowseTab() {
  const [activeCategory, setActiveCategory] = useState<DuaCategory>('morning');
  const [savedIds, setSavedIds] = useState<string[]>([]);

  useEffect(() => {
    getSavedDuas().then(setSavedIds);
  }, []);

  const handleToggleSave = async (id: string) => {
    const updated = await toggleSavedDua(id);
    setSavedIds(updated);
  };

  const filtered = DUAS.filter((d) => d.category === activeCategory);

  return (
    <>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.categories}
        style={styles.categoriesScroll}
      >
        {DUA_CATEGORIES.map((cat) => (
          <TouchableOpacity
            key={cat.key}
            style={[styles.categoryPill, activeCategory === cat.key && styles.categoryPillActive]}
            onPress={() => setActiveCategory(cat.key)}
            activeOpacity={0.7}
          >
            <Text style={styles.categoryEmoji}>{cat.emoji}</Text>
            <Text style={[styles.categoryLabel, activeCategory === cat.key && styles.categoryLabelActive]}>
              {cat.label}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      <ScrollView style={styles.flex} contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {filtered.map((dua) => (
          <DuaCard
            key={dua.id}
            dua={dua}
            saved={savedIds.includes(dua.id)}
            onToggleSave={handleToggleSave}
          />
        ))}
        <View style={{ height: 32 }} />
      </ScrollView>
    </>
  );
}

// ─── Ripple loader (shared) ───────────────────────────────────────────────────
function useRipple(active: boolean) {
  const r1 = useRef(new Animated.Value(0)).current;
  const r2 = useRef(new Animated.Value(0)).current;
  const r3 = useRef(new Animated.Value(0)).current;
  const isActive = useRef(false);

  useEffect(() => {
    if (active) {
      isActive.current = true;
      const run = (a: Animated.Value, delay: number) => {
        const cycle = () => {
          if (!isActive.current) return;
          a.setValue(0);
          Animated.timing(a, { toValue: 1, duration: 1600, useNativeDriver: true })
            .start(({ finished }) => { if (finished && isActive.current) cycle(); });
        };
        setTimeout(cycle, delay);
      };
      run(r1, 0); run(r2, 530); run(r3, 1060);
    } else {
      isActive.current = false;
      r1.setValue(0); r2.setValue(0); r3.setValue(0);
    }
  }, [active]);

  const style = (a: Animated.Value) => ({
    opacity: a.interpolate({ inputRange: [0, 0.3, 1], outputRange: [0.6, 0.3, 0] }),
    transform: [{ scale: a.interpolate({ inputRange: [0, 1], outputRange: [0.3, 2.2] }) }],
  });

  return { r1, r2, r3, style };
}

function RippleLoader({ label, sub }: { label: string; sub?: string }) {
  const r1 = useRef(new Animated.Value(0)).current;
  const r2 = useRef(new Animated.Value(0)).current;
  const r3 = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    let active = true;
    const run = (a: Animated.Value, delay: number) => {
      const cycle = () => {
        if (!active) return;
        a.setValue(0);
        Animated.timing(a, { toValue: 1, duration: 1600, useNativeDriver: true })
          .start(({ finished }) => { if (finished && active) cycle(); });
      };
      setTimeout(cycle, delay);
    };
    run(r1, 0); run(r2, 530); run(r3, 1060);
    return () => { active = false; };
  }, []);

  const rs = (a: Animated.Value) => ({
    opacity: a.interpolate({ inputRange: [0, 0.3, 1], outputRange: [0.6, 0.3, 0] }),
    transform: [{ scale: a.interpolate({ inputRange: [0, 1], outputRange: [0.3, 2.2] }) }],
  });

  return (
    <View style={styles.loadingScreen}>
      <View style={styles.rippleContainer}>
        <Animated.View style={[styles.rippleRing, rs(r1)]} />
        <Animated.View style={[styles.rippleRing, rs(r2)]} />
        <Animated.View style={[styles.rippleRing, rs(r3)]} />
        <View style={styles.rippleCore} />
      </View>
      <Text style={styles.loadingText}>{label}</Text>
      {sub ? <Text style={styles.loadingSubtext}>{sub}</Text> : null}
    </View>
  );
}

// ─── Find Duas tab ────────────────────────────────────────────────────────────
function FindTab() {
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<FindDuasResponse | null>(null);
  const [error, setError] = useState('');
  const fadeAnim = useRef(new Animated.Value(0)).current;

  const handleFind = useCallback(async () => {
    if (!text.trim()) return;
    setError('');
    setLoading(true);
    setResult(null);
    fadeAnim.setValue(0);
    try {
      const res = await findDuas(text.trim());
      setResult(res);
      Animated.timing(fadeAnim, { toValue: 1, duration: 400, useNativeDriver: true }).start();
    } catch {
      setError('Something went wrong — please try again');
    } finally {
      setLoading(false);
    }
  }, [text, fadeAnim]);

  if (loading) return <RippleLoader label="Finding duas..." />;

  return (
    <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
      <ScrollView
        contentContainerStyle={styles.tabContent}
        keyboardDismissMode="interactive"
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        <Text style={styles.tabDesc}>
          Describe what you want to make dua for. We'll find the Names to call upon and duas to recite.
        </Text>

        <View style={styles.inputWrapper}>
          <TextInput
            style={styles.input}
            multiline
            placeholder="e.g. I'm worried about my job, I need guidance on a decision, I want relief from anxiety..."
            placeholderTextColor={Colors.textMuted}
            value={text}
            onChangeText={setText}
            textAlignVertical="top"
            scrollEnabled={false}
          />
        </View>

        {error ? <Text style={styles.errorText}>{error}</Text> : null}

        <TouchableOpacity
          style={[styles.actionBtn, !text.trim() && styles.actionBtnDisabled]}
          onPress={handleFind}
          disabled={!text.trim()}
          activeOpacity={0.85}
        >
          <Text style={styles.actionBtnText}>Find Duas</Text>
        </TouchableOpacity>

        {result && (
          <Animated.View style={[styles.resultBlock, { opacity: fadeAnim }]}>
            <Text style={styles.sectionLabel}>Names to Call Upon</Text>
            {result.names.map((n, i) => (
              <View key={i} style={styles.nameCard}>
                <View style={styles.nameCardTop}>
                  <Text style={styles.nameCardEnglish}>{n.name}</Text>
                  <Text style={styles.nameCardArabic}>{n.nameArabic}</Text>
                </View>
                <Text style={styles.nameCardWhy}>{n.why}</Text>
              </View>
            ))}

            <Text style={[styles.sectionLabel, { marginTop: 4 }]}>Duas to Recite</Text>
            {result.duas.map((d, i) => (
              <FindDuaCard key={i} dua={d} />
            ))}

            <TouchableOpacity style={styles.resetBtn} onPress={() => { setResult(null); setText(''); }}>
              <Text style={styles.resetBtnText}>Search again</Text>
            </TouchableOpacity>
          </Animated.View>
        )}
        <View style={{ height: 40 }} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

// ─── Built dua paginated viewer ───────────────────────────────────────────────
function BuiltDuaViewer({ result, onReset, onDoneChange, need }: {
  result: BuiltDua; onReset: () => void;
  onDoneChange: (done: boolean) => void;
  need: string;
}) {
  const sections = result.breakdown.length > 0 ? result.breakdown : [
    { label: 'Your Dua', arabic: result.arabic, transliteration: result.transliteration, translation: result.translation },
  ];
  const [index, setIndex] = useState(0);
  const fadeAnim = useRef(new Animated.Value(1)).current;
  const [done, setDone] = useState(false);
  const [duaSaved, setDuaSaved] = useState(false);
  const [savedRelatedIds, setSavedRelatedIds] = useState<Set<number>>(new Set());

  const fadeTo = useCallback((val: number, duration: number, cb?: () => void) => {
    Animated.timing(fadeAnim, { toValue: val, duration, useNativeDriver: true }).start(() => cb?.());
  }, [fadeAnim]);

  const advance = useCallback(() => {
    if (index < sections.length - 1) {
      fadeTo(0, 200, () => {
        setIndex(i => i + 1);
        fadeTo(1, 300);
      });
    } else {
      fadeTo(0, 200, () => {
        setDone(true);
        onDoneChange(true);
        fadeTo(1, 300);
      });
    }
  }, [index, sections.length, fadeTo, onDoneChange]);

  if (done) {
    return (
      <Animated.View style={[styles.doneContainer, { opacity: fadeAnim }]}>
        <ScrollView contentContainerStyle={styles.doneScroll} showsVerticalScrollIndicator={false}>
          {/* Ameen header */}
          <View style={styles.doneHeader}>
            <Text style={styles.doneArabic}>آمِين</Text>
            <Text style={styles.doneLabel}>Ameen</Text>
            <Text style={styles.doneNote}>
              This is a constructed personal dua following the prophetic structure. Recite it with full presence of heart.
            </Text>
          </View>

          {/* Save the built dua */}
          <TouchableOpacity
            style={[styles.doneSaveBtn, duaSaved && styles.doneSaveBtnSaved]}
            onPress={async () => {
              if (duaSaved) return;
              await saveBuiltDua({ need, arabic: result.arabic, transliteration: result.transliteration, translation: result.translation });
              setDuaSaved(true);
            }}
            activeOpacity={0.8}
          >
            <Text style={styles.doneSaveBtnText}>{duaSaved ? '♥  Saved' : '🤍  Save this dua'}</Text>
          </TouchableOpacity>

          {/* Names used */}
          {result.namesUsed.length > 0 && (
            <View style={styles.doneSection}>
              <Text style={styles.doneSectionTitle}>Names Called Upon</Text>
              {result.namesUsed.map((n, i) => (
                <View key={i} style={styles.doneNameCard}>
                  <View style={styles.doneNameCardTop}>
                    <Text style={styles.doneNameEnglish}>{n.name}</Text>
                    <Text style={styles.doneNameArabic}>{n.nameArabic}</Text>
                  </View>
                  {n.why ? <Text style={styles.doneNameWhy}>{n.why}</Text> : null}
                </View>
              ))}
            </View>
          )}

          {/* Related duas */}
          {result.relatedDuas.length > 0 && (
            <View style={styles.doneSection}>
              <Text style={styles.doneSectionTitle}>Related Duas from Quran & Sunnah</Text>
              {result.relatedDuas.map((d, i) => (
                <View key={i} style={styles.doneRelatedCard}>
                  <View style={styles.doneRelatedHeader}>
                    <Text style={styles.doneRelatedTitle}>{d.title}</Text>
                    <TouchableOpacity
                      onPress={() => setSavedRelatedIds(prev => {
                        const next = new Set(prev);
                        next.has(i) ? next.delete(i) : next.add(i);
                        return next;
                      })}
                      hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                    >
                      <Text style={styles.doneRelatedSaveIcon}>{savedRelatedIds.has(i) ? '♥' : '♡'}</Text>
                    </TouchableOpacity>
                  </View>
                  <Text style={styles.doneRelatedArabic}>{d.arabic}</Text>
                  <View style={styles.doneRelatedDivider} />
                  <Text style={styles.doneRelatedTranslit}>{d.transliteration}</Text>
                  <Text style={styles.doneRelatedTranslation}>{d.translation}</Text>
                  {d.source ? <Text style={styles.doneRelatedSource}>{d.source}</Text> : null}
                </View>
              ))}
            </View>
          )}

          <TouchableOpacity style={styles.doneBuildBtn} onPress={onReset} activeOpacity={0.85}>
            <Text style={styles.doneBuildBtnText}>Build another dua</Text>
          </TouchableOpacity>

          <View style={{ height: 40 }} />
        </ScrollView>
      </Animated.View>
    );
  }

  const section = sections[index];
  const isLast = index === sections.length - 1;

  return (
    <View style={styles.flex}>
      {/* Progress dots */}
      <View style={styles.sectionDots}>
        {sections.map((_, i) => (
          <View key={i} style={[styles.sectionDot, i === index && styles.sectionDotActive]} />
        ))}
      </View>

      <Animated.View style={[styles.flex, { opacity: fadeAnim }]}>
        <ScrollView
          contentContainerStyle={styles.sectionContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Section label */}
          <Text style={styles.sectionStepLabel}>{section.label}</Text>

          {/* Arabic */}
          <View style={styles.builtDuaCard}>
            <Text style={styles.builtDuaArabic}>{section.arabic}</Text>
          </View>

          {/* Transliteration dropdown */}
          <View style={styles.dropdownCard}>
            <ExpandRow label="Transliteration">
              <Text style={styles.expandTextItalic}>{section.transliteration}</Text>
            </ExpandRow>
          </View>

          {/* Translation dropdown */}
          <View style={styles.dropdownCard}>
            <ExpandRow label="Translation">
              <Text style={styles.expandText}>{section.translation}</Text>
            </ExpandRow>
          </View>

          <TouchableOpacity style={styles.actionBtn} onPress={advance} activeOpacity={0.85}>
            <Text style={styles.actionBtnText}>{isLast ? 'Complete' : 'Next'}</Text>
          </TouchableOpacity>
        </ScrollView>
      </Animated.View>
    </View>
  );
}

// ─── Build a Dua tab ──────────────────────────────────────────────────────────
function BuildTab({ onDoneChange }: { onDoneChange: (done: boolean) => void }) {
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<BuiltDua | null>(null);
  const [error, setError] = useState('');
  const fadeAnim = useRef(new Animated.Value(1)).current;

  const handleBuild = useCallback(async () => {
    if (!text.trim()) return;
    setError('');
    setLoading(true);
    setResult(null);
    try {
      const res = await buildDua(text.trim());
      Animated.timing(fadeAnim, { toValue: 0, duration: 200, useNativeDriver: true }).start(() => {
        setResult(res);
        Animated.timing(fadeAnim, { toValue: 1, duration: 350, useNativeDriver: true }).start();
      });
    } catch {
      setError('Something went wrong — please try again');
    } finally {
      setLoading(false);
    }
  }, [text, fadeAnim]);

  const handleReset = useCallback(() => {
    onDoneChange(false);
    Animated.timing(fadeAnim, { toValue: 0, duration: 200, useNativeDriver: true }).start(() => {
      setResult(null);
      setText('');
      Animated.timing(fadeAnim, { toValue: 1, duration: 300, useNativeDriver: true }).start();
    });
  }, [fadeAnim, onDoneChange]);

  if (loading) return <RippleLoader label="Constructing your dua..." sub="Praise · Salawat · Your ask · Closing" />;

  if (result) return <BuiltDuaViewer result={result} onReset={handleReset} onDoneChange={onDoneChange} need={text} />;

  return (
    <Animated.View style={[styles.flex, { opacity: fadeAnim }]}>
      <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
        <ScrollView
          contentContainerStyle={styles.tabContent}
          keyboardDismissMode="interactive"
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <Text style={styles.tabDesc}>
            Tell us what you need. We'll construct a personal dua in Arabic following the prophetic structure.
          </Text>

          {/* Structure preview */}
          <View style={styles.structureRow}>
            {['Praise Allah', 'Salawat', 'Your Ask', 'Closing'].map((s, i, arr) => (
              <React.Fragment key={s}>
                <View style={styles.structureStep}>
                  <Text style={styles.structureNum}>{i + 1}</Text>
                  <Text style={styles.structureLabel}>{s}</Text>
                </View>
                {i < arr.length - 1 && <Text style={styles.structureArrow}>›</Text>}
              </React.Fragment>
            ))}
          </View>

          <View style={styles.inputWrapper}>
            <TextInput
              style={styles.input}
              multiline
              placeholder="e.g. I need to find the right spouse, I'm struggling with debt, I want to be a better parent..."
              placeholderTextColor={Colors.textMuted}
              value={text}
              onChangeText={setText}
              textAlignVertical="top"
              scrollEnabled={false}
            />
          </View>

          {error ? <Text style={styles.errorText}>{error}</Text> : null}

          <TouchableOpacity
            style={[styles.actionBtn, !text.trim() && styles.actionBtnDisabled]}
            onPress={handleBuild}
            disabled={!text.trim()}
            activeOpacity={0.85}
          >
            <Text style={styles.actionBtnText}>Build My Dua</Text>
          </TouchableOpacity>

          <View style={{ height: 40 }} />
        </ScrollView>
      </KeyboardAvoidingView>
    </Animated.View>
  );
}

const SECTIONS: { key: Tab; label: string; icon: string; desc: string; accent: string }[] = [
  { key: 'browse', label: 'Browse Duas',  icon: '📖', desc: 'Morning, evening, anxiety, grief, and more', accent: Colors.primary },
  { key: 'find',   label: 'Find Duas',    icon: '🔍', desc: 'Describe your need — get the right Names and duas to recite', accent: Colors.primaryDark },
  { key: 'build',  label: 'Build a Dua', icon: '🤲', desc: 'Construct a personal dua in Arabic with the prophetic structure', accent: Colors.primary },
];

// ─── Main screen ──────────────────────────────────────────────────────────────
export default function DuasScreen() {
  const [activeTab, setActiveTab] = useState<Tab | null>(null);
  const [isAmeen, setIsAmeen] = useState(false);
  const fadeAnim = useRef(new Animated.Value(1)).current;
  const [suggestions, setSuggestions] = useState<DuaSuggestion[]>([]);
  const [expandedSuggestion, setExpandedSuggestion] = useState<DuaSuggestion | null>(null);
  const modalFadeAnim = useRef(new Animated.Value(0)).current;
  const [celebration, setCelebration] = useState<{ gained: number; xpState: XPState; message: string } | null>(null);

  useEffect(() => {
    getDuaSuggestions().then(setSuggestions);
  }, []);

  const openSuggestion = useCallback((s: DuaSuggestion) => {
    modalFadeAnim.setValue(0);
    setExpandedSuggestion(s);
    Animated.timing(modalFadeAnim, { toValue: 1, duration: 350, useNativeDriver: true }).start();
  }, [modalFadeAnim]);

  const closeSuggestion = useCallback(() => {
    Animated.timing(modalFadeAnim, { toValue: 0, duration: 200, useNativeDriver: true }).start(() => {
      setExpandedSuggestion(null);
    });
  }, [modalFadeAnim]);

  const handleAmeen = useCallback(async () => {
    if (!expandedSuggestion) return;
    const id = expandedSuggestion.type === 'built'
      ? `built:${expandedSuggestion.builtDua?.id}`
      : `browse:${expandedSuggestion.dua?.id}`;
    await markDuaRead(id);
    const { gained, xpState } = await awardXP('duaRead');
    const duaTitle = expandedSuggestion.type === 'built'
      ? (expandedSuggestion.builtDua?.need ?? 'Dua')
      : (expandedSuggestion.dua?.title ?? 'Dua');
    setSuggestions(prev => prev.filter(p =>
      p.type === 'built' ? `built:${p.builtDua?.id}` !== id : `browse:${p.dua?.id}` !== id
    ));
    closeSuggestion();
    // small delay so modal fades out before celebration pops
    setTimeout(() => setCelebration({ gained, xpState, message: `Dua recited\n${duaTitle}` }), 250);
  }, [expandedSuggestion, closeSuggestion]);

  const navigateTo = useCallback((tab: Tab) => {
    modalFadeAnim.setValue(0);
    setExpandedSuggestion(null);
    Animated.timing(fadeAnim, { toValue: 0, duration: 220, useNativeDriver: true }).start(() => {
      setActiveTab(tab);
      Animated.timing(fadeAnim, { toValue: 1, duration: 300, useNativeDriver: true }).start();
    });
  }, [fadeAnim]);

  const goBack = useCallback(() => {
    setIsAmeen(false);
    Animated.timing(fadeAnim, { toValue: 0, duration: 200, useNativeDriver: true }).start(() => {
      setActiveTab(null);
      Animated.timing(fadeAnim, { toValue: 1, duration: 300, useNativeDriver: true }).start();
    });
  }, [fadeAnim]);

  const safeStyle = isAmeen
    ? [styles.safe, { backgroundColor: Colors.primaryDark }]
    : styles.safe;

  return (
    <SafeAreaView style={safeStyle}>
      <Animated.View style={[styles.flex, { opacity: fadeAnim }]}>
        {/* Header — hidden on Ameen screen */}
        {!isAmeen && (
          <View style={styles.header}>
            {activeTab ? (
              <TouchableOpacity style={styles.backRow} onPress={goBack} activeOpacity={0.7}>
                <Text style={styles.backArrow}>‹</Text>
                <Text style={styles.backLabel}>Duas</Text>
              </TouchableOpacity>
            ) : (
              <Text style={styles.title}>Duas</Text>
            )}
          </View>
        )}

        {/* Ameen back button — white, sits on green */}
        {isAmeen && (
          <TouchableOpacity style={styles.ameenBackRow} onPress={goBack} activeOpacity={0.7}>
            <Text style={styles.ameenBackArrow}>‹</Text>
            <Text style={styles.ameenBackLabel}>Duas</Text>
          </TouchableOpacity>
        )}

        {/* Landing */}
        {!activeTab && (
          <ScrollView contentContainerStyle={styles.landingContent} showsVerticalScrollIndicator={false}>
            {/* For You suggestions */}
            {suggestions.length > 0 && (
              <View style={styles.forYouSection}>
                <Text style={styles.forYouTitle}>For You</Text>
                {suggestions.map((s, i) => (
                  <TouchableOpacity
                    key={i}
                    style={styles.suggestionCard}
                    onPress={() => openSuggestion(s)}
                    activeOpacity={0.82}
                  >
                    <View style={styles.suggestionLeft}>
                      <Text style={styles.suggestionReason}>{s.reason}</Text>
                      <Text style={styles.suggestionName} numberOfLines={1}>
                        {s.type === 'built' ? (s.builtDua?.need ?? 'Saved dua') : (s.dua?.title ?? '')}
                      </Text>
                    </View>
                    <View style={styles.suggestionRight}>
                      <Text style={styles.suggestionArabicPreview} numberOfLines={2}>
                        {s.type === 'built'
                          ? (s.builtDua?.arabic?.split('\n')[0] ?? '')
                          : (s.dua?.arabic ?? '')}
                      </Text>
                      <Text style={styles.suggestionXp}>+10 XP</Text>
                    </View>
                  </TouchableOpacity>
                ))}
              </View>
            )}

            <Text style={styles.landingSubtitle}>What would you like to do?</Text>
            {SECTIONS.map(s => (
              <TouchableOpacity
                key={s.key}
                style={[styles.sectionCard, { borderLeftColor: s.accent }]}
                onPress={() => navigateTo(s.key)}
                activeOpacity={0.82}
              >
                <View style={[styles.sectionCardIcon, { backgroundColor: s.accent + '18' }]}>
                  <Text style={styles.sectionCardIconText}>{s.icon}</Text>
                </View>
                <View style={styles.sectionCardLeft}>
                  <Text style={styles.sectionCardLabel}>{s.label}</Text>
                  <Text style={styles.sectionCardDesc}>{s.desc}</Text>
                </View>
                <Text style={[styles.sectionCardArrow, { color: s.accent }]}>›</Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        )}

        {/* Expanded suggestion dua modal */}
        {expandedSuggestion && (
          <Animated.View style={[styles.suggestionModal, { opacity: modalFadeAnim }]}>
            {/* Header */}
            <View style={styles.suggestionModalHeader}>
              <View style={styles.suggestionModalHeaderLeft}>
                <Text style={styles.suggestionModalReason}>{expandedSuggestion.reason}</Text>
                <Text style={styles.suggestionModalTitle} numberOfLines={2}>
                  {expandedSuggestion.type === 'built'
                    ? (expandedSuggestion.builtDua?.need ?? '')
                    : (expandedSuggestion.dua?.title ?? '')}
                </Text>
              </View>
              <TouchableOpacity style={styles.suggestionModalClose} onPress={closeSuggestion} activeOpacity={0.7}>
                <Text style={styles.suggestionModalCloseText}>✕</Text>
              </TouchableOpacity>
            </View>

            <ScrollView contentContainerStyle={styles.suggestionModalContent} showsVerticalScrollIndicator={false}>
              {/* Arabic */}
              <View style={styles.suggestionModalArabicCard}>
                <Text style={styles.suggestionModalArabic}>
                  {expandedSuggestion.type === 'built'
                    ? (expandedSuggestion.builtDua?.arabic ?? '')
                    : (expandedSuggestion.dua?.arabic ?? '')}
                </Text>
              </View>

              {/* Transliteration & Translation */}
              <View style={styles.suggestionModalDropdowns}>
                <ExpandRow label="Transliteration">
                  <Text style={styles.expandTextItalic}>
                    {expandedSuggestion.type === 'built'
                      ? expandedSuggestion.builtDua?.transliteration
                      : expandedSuggestion.dua?.transliteration}
                  </Text>
                </ExpandRow>
                <View style={styles.suggestionModalDivider} />
                <ExpandRow label="Translation">
                  <Text style={styles.expandText}>
                    {expandedSuggestion.type === 'built'
                      ? expandedSuggestion.builtDua?.translation
                      : expandedSuggestion.dua?.translation}
                  </Text>
                  {expandedSuggestion.type === 'browse' && expandedSuggestion.dua?.source ? (
                    <Text style={styles.findDuaSource}>{expandedSuggestion.dua.source}</Text>
                  ) : null}
                </ExpandRow>
              </View>

              {expandedSuggestion.type === 'browse' && expandedSuggestion.dua?.whenToRecite ? (
                <Text style={styles.suggestionModalWhen}>🕐 {expandedSuggestion.dua.whenToRecite}</Text>
              ) : null}
            </ScrollView>

            {/* Ameen — anchored at bottom */}
            <View style={styles.ameenFooter}>
              <TouchableOpacity style={styles.ameenBtn} onPress={handleAmeen} activeOpacity={0.85}>
                <Text style={styles.ameenBtnArabic}>آمِين</Text>
                <Text style={styles.ameenBtnLabel}>Ameen · +10 XP</Text>
              </TouchableOpacity>
            </View>
          </Animated.View>
        )}

        {activeTab === 'browse' && <BrowseTab />}
        {activeTab === 'find' && <FindTab />}
        {activeTab === 'build' && <BuildTab onDoneChange={setIsAmeen} />}
      </Animated.View>

      <XPCelebration
        visible={!!celebration}
        gained={celebration?.gained ?? 0}
        xpState={celebration?.xpState ?? { total: 0, level: 1, title: 'Seeker', titleArabic: 'طَالِب', xpForNextLevel: 50, xpIntoCurrentLevel: 0 }}
        message={celebration?.message ?? ''}
        onDismiss={() => setCelebration(null)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  flex: { flex: 1 },

  header: { paddingHorizontal: 24, paddingTop: 20, paddingBottom: 10 },
  title: { fontSize: 28, fontWeight: '800', color: Colors.primaryDark, letterSpacing: -0.5 },

  // Back navigation
  backRow: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  backArrow: { fontSize: 26, color: Colors.primary, lineHeight: 32, fontWeight: '300' },
  backLabel: { fontSize: 17, color: Colors.primary, fontWeight: '600' },

  // Ameen back (white on green)
  ameenBackRow: { flexDirection: 'row', alignItems: 'center', gap: 4, paddingHorizontal: 20, paddingVertical: 8 },
  ameenBackArrow: { fontSize: 26, color: Colors.white, lineHeight: 32, fontWeight: '300' },
  ameenBackLabel: { fontSize: 17, color: Colors.white, fontWeight: '600' },

  // Landing
  landingContent: { paddingHorizontal: 20, paddingTop: 4, gap: 12, paddingBottom: 40 },
  landingSubtitle: { fontSize: 14, color: Colors.textMuted, marginBottom: 4 },
  sectionCard: {
    backgroundColor: Colors.white, borderRadius: 18, padding: 18,
    flexDirection: 'row', alignItems: 'center', gap: 14,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1, shadowRadius: 12, elevation: 3,
    borderWidth: 1, borderColor: Colors.border,
    borderLeftWidth: 4,
  },
  sectionCardIcon: {
    width: 48, height: 48, borderRadius: 14,
    alignItems: 'center', justifyContent: 'center',
  },
  sectionCardIconText: { fontSize: 22 },
  sectionCardLeft: { flex: 1, gap: 3 },
  sectionCardLabel: { fontSize: 17, fontWeight: '700', color: Colors.textPrimary },
  sectionCardDesc: { fontSize: 13, color: Colors.textSecondary, lineHeight: 19 },
  sectionCardArrow: { fontSize: 24, fontWeight: '300' },

  // Browse
  categoriesScroll: { flexGrow: 0 },
  categories: { paddingHorizontal: 20, gap: 8, paddingBottom: 12 },
  categoryPill: {
    flexDirection: 'row', alignItems: 'center', gap: 5,
    paddingHorizontal: 14, paddingVertical: 8, borderRadius: 100,
    backgroundColor: Colors.white, borderWidth: 1, borderColor: Colors.border,
  },
  categoryPillActive: { backgroundColor: Colors.primary, borderColor: Colors.primary },
  categoryEmoji: { fontSize: 14 },
  categoryLabel: { fontSize: 13, fontWeight: '500', color: Colors.textSecondary },
  categoryLabelActive: { color: Colors.white, fontWeight: '600' },
  scrollContent: { paddingHorizontal: 20, paddingTop: 4 },

  // Find / Build shared
  tabContent: { paddingHorizontal: 20, paddingTop: 4, gap: 14 },
  tabDesc: { fontSize: 14, color: Colors.textSecondary, lineHeight: 22 },
  inputWrapper: {
    backgroundColor: Colors.white, borderRadius: 18, padding: 18,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1, shadowRadius: 12, elevation: 3,
  },
  input: { minHeight: 80, fontSize: 16, color: Colors.textPrimary, lineHeight: 26, fontStyle: 'italic' },
  errorText: { fontSize: 13, color: '#C0392B' },
  actionBtn: { backgroundColor: Colors.primary, borderRadius: 16, paddingVertical: 17, alignItems: 'center' },
  actionBtnDisabled: { opacity: 0.45 },
  actionBtnText: { color: Colors.white, fontSize: 16, fontWeight: '700', letterSpacing: 0.3 },

  // Loading
  loadingScreen: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 20 },
  rippleContainer: { width: 120, height: 120, alignItems: 'center', justifyContent: 'center' },
  rippleRing: {
    position: 'absolute', width: 120, height: 120, borderRadius: 60,
    borderWidth: 2, borderColor: Colors.primary, backgroundColor: 'transparent',
  },
  rippleCore: { width: 20, height: 20, borderRadius: 10, backgroundColor: Colors.primary },
  loadingText: { fontSize: 18, fontWeight: '700', color: Colors.primary },
  loadingSubtext: { fontSize: 13, color: Colors.textMuted, textAlign: 'center' },

  // Results
  resultBlock: { gap: 12 },
  sectionLabel: { fontSize: 10, fontWeight: '700', color: Colors.primary, letterSpacing: 1.5, textTransform: 'uppercase' },
  resetBtn: { alignItems: 'center', paddingVertical: 12 },
  resetBtnText: { fontSize: 13, color: Colors.textMuted },

  // Expandable row
  expandRow: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingVertical: 10,
  },
  expandRowLabel: { fontSize: 13, fontWeight: '600', color: Colors.textSecondary },
  expandRowChevron: { fontSize: 10, color: Colors.textMuted },
  expandRowBody: { paddingBottom: 10 },
  expandText: { fontSize: 14, color: Colors.textPrimary, lineHeight: 22 },
  expandTextItalic: { fontSize: 13, color: Colors.textSecondary, fontStyle: 'italic', lineHeight: 22 },

  // Find — name cards
  nameCard: {
    backgroundColor: Colors.white, borderRadius: 16, padding: 16,
    borderLeftWidth: 3, borderLeftColor: Colors.primary,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1, shadowRadius: 8, elevation: 2, gap: 6,
  },
  nameCardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  nameCardEnglish: { fontSize: 16, fontWeight: '700', color: Colors.primaryDark },
  nameCardArabic: { fontSize: 20, color: Colors.primary },
  nameCardWhy: { fontSize: 13, color: Colors.textSecondary, lineHeight: 20 },

  // Find — dua cards
  findDuaCard: {
    backgroundColor: Colors.duaCard, borderRadius: 16, paddingHorizontal: 16, paddingTop: 16, paddingBottom: 4,
    borderWidth: 1, borderColor: Colors.duaCardBorder,
  },
  findDuaTitle: { fontSize: 14, fontWeight: '700', color: Colors.textPrimary, marginBottom: 10 },
  findDuaArabic: { fontSize: 21, color: Colors.primaryDark, textAlign: 'right', lineHeight: 36, marginBottom: 8 },
  findDuaDivider: { height: 1, backgroundColor: Colors.duaCardBorder, marginBottom: 2 },
  findDuaSource: { fontSize: 11, color: Colors.textMuted, marginTop: 4 },

  // Build — paginated section viewer
  sectionDots: { flexDirection: 'row', justifyContent: 'center', gap: 6, paddingVertical: 10 },
  sectionDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: Colors.border },
  sectionDotActive: { width: 20, backgroundColor: Colors.primary },
  sectionContent: { paddingHorizontal: 20, paddingTop: 4, paddingBottom: 40, gap: 12 },
  sectionStepLabel: { fontSize: 11, fontWeight: '700', color: Colors.primary, letterSpacing: 1.5, textTransform: 'uppercase', textAlign: 'center' },

  // Build — arabic card per section
  builtDuaCard: {
    backgroundColor: Colors.primaryDark, borderRadius: 20, padding: 24,
  },
  builtDuaArabic: { fontSize: 24, color: Colors.white, lineHeight: 44, textAlign: 'right' },

  // Build — dropdown cards
  dropdownCard: {
    backgroundColor: Colors.white, borderRadius: 14, paddingHorizontal: 16,
    borderWidth: 1, borderColor: Colors.border,
  },

  // Build — done (Ameen) screen
  doneContainer: { flex: 1, backgroundColor: Colors.primaryDark },
  doneScroll: { paddingHorizontal: 24, paddingTop: 12, gap: 20 },
  doneHeader: { alignItems: 'center', gap: 8, paddingBottom: 4 },
  doneArabic: { fontSize: 56, color: Colors.white, lineHeight: 72, textAlign: 'center' },
  doneLabel: { fontSize: 22, fontWeight: '800', color: Colors.white, textAlign: 'center', letterSpacing: -0.3 },
  doneNote: { fontSize: 13, color: 'rgba(255,255,255,0.55)', lineHeight: 20, textAlign: 'center', fontStyle: 'italic', paddingHorizontal: 8 },

  doneSaveBtn: {
    borderWidth: 1.5, borderColor: 'rgba(255,255,255,0.4)',
    borderRadius: 14, paddingVertical: 14, alignItems: 'center',
  },
  doneSaveBtnSaved: { borderColor: 'rgba(255,255,255,0.2)', backgroundColor: 'rgba(255,255,255,0.08)' },
  doneSaveBtnText: { color: Colors.white, fontSize: 15, fontWeight: '600' },

  doneSection: { gap: 10 },
  doneSectionTitle: {
    fontSize: 10, fontWeight: '700', color: 'rgba(255,255,255,0.5)',
    letterSpacing: 1.5, textTransform: 'uppercase',
  },

  doneNameCard: {
    backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: 14, padding: 14, gap: 4,
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.15)',
  },
  doneNameCardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  doneNameEnglish: { fontSize: 15, fontWeight: '700', color: Colors.white },
  doneNameArabic: { fontSize: 18, color: 'rgba(255,255,255,0.75)' },
  doneNameWhy: { fontSize: 12, color: 'rgba(255,255,255,0.6)', lineHeight: 18 },

  doneRelatedCard: {
    backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: 14, padding: 16, gap: 8,
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.15)',
  },
  doneRelatedHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  doneRelatedTitle: { fontSize: 13, fontWeight: '700', color: Colors.white, flex: 1 },
  doneRelatedSaveIcon: { fontSize: 18, color: 'rgba(255,255,255,0.7)', paddingLeft: 8 },
  doneRelatedArabic: { fontSize: 19, color: Colors.white, textAlign: 'right', lineHeight: 34 },
  doneRelatedDivider: { height: 1, backgroundColor: 'rgba(255,255,255,0.15)' },
  doneRelatedTranslit: { fontSize: 12, color: 'rgba(255,255,255,0.6)', fontStyle: 'italic', lineHeight: 20 },
  doneRelatedTranslation: { fontSize: 13, color: 'rgba(255,255,255,0.85)', lineHeight: 20 },
  doneRelatedSource: { fontSize: 11, color: 'rgba(255,255,255,0.4)' },

  doneBuildBtn: {
    backgroundColor: 'rgba(255,255,255,0.15)', borderRadius: 14,
    paddingVertical: 16, alignItems: 'center',
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.2)',
  },
  doneBuildBtnText: { color: Colors.white, fontSize: 15, fontWeight: '600' },

  // For You suggestions
  forYouSection: { gap: 10, marginBottom: 4 },
  forYouTitle: { fontSize: 12, fontWeight: '800', color: Colors.textMuted, letterSpacing: 1.2, textTransform: 'uppercase' },
  suggestionCard: {
    backgroundColor: Colors.white, borderRadius: 16, padding: 14,
    flexDirection: 'row', alignItems: 'center', gap: 12,
    borderLeftWidth: 3, borderLeftColor: Colors.primary,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1, shadowRadius: 8, elevation: 2,
  },
  suggestionLeft: { flex: 1, gap: 3 },
  suggestionReason: { fontSize: 10, color: Colors.primary, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 0.8 },
  suggestionName: { fontSize: 14, fontWeight: '600', color: Colors.textPrimary },
  suggestionRight: { alignItems: 'flex-end', gap: 4 },
  suggestionArabicPreview: { fontSize: 15, color: Colors.primaryDark, textAlign: 'right', maxWidth: 130, lineHeight: 24 },
  suggestionXp: { fontSize: 10, fontWeight: '700', color: Colors.primary, backgroundColor: Colors.primary + '15', paddingHorizontal: 6, paddingVertical: 2, borderRadius: 6 },

  // Expanded suggestion modal
  suggestionModal: {
    position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
    backgroundColor: Colors.background, zIndex: 100, flex: 1,
  },
  suggestionModalHeader: {
    flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between',
    paddingHorizontal: 24, paddingTop: 20, paddingBottom: 16,
    borderBottomWidth: 1, borderBottomColor: Colors.border,
    backgroundColor: Colors.white,
    gap: 12,
  },
  suggestionModalHeaderLeft: { flex: 1, gap: 4 },
  suggestionModalClose: { padding: 4 },
  suggestionModalCloseText: { fontSize: 16, color: Colors.textMuted, fontWeight: '600' },
  suggestionModalReason: { fontSize: 10, color: Colors.primary, fontWeight: '700', letterSpacing: 1.4, textTransform: 'uppercase' },
  suggestionModalTitle: { fontSize: 20, fontWeight: '800', color: Colors.primaryDark, lineHeight: 26 },
  suggestionModalContent: { paddingHorizontal: 24, paddingTop: 20, paddingBottom: 24, gap: 16 },
  suggestionModalArabicCard: {
    backgroundColor: Colors.primaryDark, borderRadius: 20, padding: 28,
    alignItems: 'center',
  },
  suggestionModalArabic: { fontSize: 24, color: Colors.white, textAlign: 'center', lineHeight: 46 },
  suggestionModalDropdowns: {
    backgroundColor: Colors.white, borderRadius: 16,
    paddingHorizontal: 16,
    borderWidth: 1, borderColor: Colors.border,
  },
  suggestionModalDivider: { height: 1, backgroundColor: Colors.border },
  suggestionModalWhen: { fontSize: 12, color: Colors.textMuted, lineHeight: 18, textAlign: 'center' },
  ameenFooter: {
    paddingHorizontal: 24, paddingBottom: 32, paddingTop: 12,
    borderTopWidth: 1, borderTopColor: Colors.border,
    backgroundColor: Colors.background,
  },
  ameenBtn: {
    backgroundColor: Colors.primaryDark, borderRadius: 18,
    paddingVertical: 18, alignItems: 'center', gap: 2,
  },
  ameenBtnArabic: { fontSize: 24, color: Colors.white },
  ameenBtnLabel: { fontSize: 12, color: 'rgba(255,255,255,0.65)', fontWeight: '600', letterSpacing: 0.5 },

  // XP toast
  xpToast: {
    position: 'absolute', bottom: 32, alignSelf: 'center',
    backgroundColor: Colors.primaryDark, borderRadius: 20,
    paddingHorizontal: 20, paddingVertical: 10,
  },
  xpToastText: { color: Colors.white, fontSize: 14, fontWeight: '700' },

  // Build — structure preview (input screen)
  structureRow: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: Colors.white, borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: Colors.border,
  },
  structureStep: { alignItems: 'center', gap: 4, flex: 1 },
  structureNum: { fontSize: 18, fontWeight: '800', color: Colors.primary },
  structureLabel: { fontSize: 9, fontWeight: '600', color: Colors.textMuted, textAlign: 'center', textTransform: 'uppercase', letterSpacing: 0.5 },
  structureArrow: { fontSize: 16, color: Colors.border },
});
