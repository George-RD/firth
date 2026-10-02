import compiler.Firth.Lowering

/-!
What `compileWords` guarantees about the image it emits, stated so a proof
about the lowering can be carried to the dictionary the VM runs.

* `nameMapOf_ok`: the name map lists the source names in order, each with its
  mangled target name, and no two source words share a target name.
* `compileWords_ok`: every emitted entry is, in order, one source word lowered
  by `lowerProgram` under that same name map, published under the target name
  the map gives it.

So a `CALL_WORD` that `lowerAtom` emits for a source word resolves, in the
emitted dictionary, to exactly the lowering of that word's body.
-/

namespace Firth.Compiler.Lowering

/-- Two lists of equal length related element by element, in order. -/
inductive ListRel {α β : Type} (R : α → β → Prop) : List α → List β → Prop where
  | nil : ListRel R [] []
  | cons {a b as bs} : R a b → ListRel R as bs → ListRel R (a :: as) (b :: bs)

theorem nameMapFrom_ok :
    ∀ (names : List String) (acc mapping : List (String × String)),
      (acc.map Prod.snd).Nodup → (∀ p ∈ acc, mangle p.1 = .ok p.2) →
      nameMapFrom acc names = .ok mapping →
      mapping.map Prod.fst = acc.map Prod.fst ++ names ∧ (mapping.map Prod.snd).Nodup ∧
        ∀ p ∈ mapping, mangle p.1 = .ok p.2
  | [], acc, mapping, hnodup, hmangle, h => by
      simp only [nameMapFrom, Except.ok.injEq] at h
      subst h
      exact ⟨by simp, hnodup, hmangle⟩
  | name :: rest, acc, mapping, hnodup, hmangle, h => by
      simp only [nameMapFrom] at h
      split at h
      · cases h
      · rename_i mangled hm
        split at h
        · cases h
        · rename_i hfresh
          have hnodup' : ((acc ++ [(name, mangled)]).map Prod.snd).Nodup := by
            rw [List.map_append, List.nodup_append]
            refine ⟨hnodup, by simp, ?_⟩
            intro a ha b hb
            simp only [List.map_cons, List.map_nil, List.mem_singleton] at hb
            subst hb
            intro hab
            subst hab
            apply hfresh
            simp only [List.any_eq_true, beq_iff_eq]
            obtain ⟨p, hp, rfl⟩ := List.mem_map.mp ha
            exact ⟨p, hp, rfl⟩
          have hmangle' : ∀ p ∈ acc ++ [(name, mangled)], mangle p.1 = .ok p.2 := by
            intro p hp
            rcases List.mem_append.mp hp with hp | hp
            · exact hmangle p hp
            · simp only [List.mem_singleton] at hp
              subst hp
              exact hm
          obtain ⟨hnames, hnd, hall⟩ := nameMapFrom_ok rest _ mapping hnodup' hmangle' h
          refine ⟨?_, hnd, hall⟩
          rw [hnames]
          simp

/-- The name map lists the source names in order, each paired with its
mangled name, and the mangled names are distinct. -/
theorem nameMapOf_ok {names : List String} {mapping : List (String × String)}
    (h : nameMapOf names = .ok mapping) :
    mapping.map Prod.fst = names ∧ (mapping.map Prod.snd).Nodup ∧
      ∀ p ∈ mapping, mangle p.1 = .ok p.2 := by
  obtain ⟨hnames, hnd, hall⟩ :=
    nameMapFrom_ok names [] mapping (by simp) (by simp) h
  exact ⟨by simpa using hnames, hnd, hall⟩

/-- The source names of a name map are distinct too, since equal names mangle
to equal targets. -/
theorem nameMapOf_names_nodup {names : List String} {mapping : List (String × String)}
    (h : nameMapOf names = .ok mapping) : names.Nodup := by
  obtain ⟨hnames, hnd, hall⟩ := nameMapOf_ok h
  have hsnd : mapping.map Prod.snd =
      (mapping.map Prod.fst).map (fun name => match mangle name with
        | .ok mangled => mangled
        | .error _ => "") := by
    rw [List.map_map]
    apply List.map_congr_left
    intro p hp
    simp [hall p hp]
  rw [hsnd] at hnd
  rw [← hnames]
  exact List.Pairwise.of_map _ (fun _ _ hne heq => hne (by rw [heq])) hnd

/-- In a map whose source names are distinct, looking a member's name up
finds that member. -/
theorem find_of_mem {mapping : List (String × String)} (hnodup : (mapping.map Prod.fst).Nodup)
    {p : String × String} (hp : p ∈ mapping) :
    mapping.find? (fun entry => entry.1 == p.1) = some p := by
  induction mapping with
  | nil => cases hp
  | cons q rest ih =>
      rw [List.map_cons, List.nodup_cons] at hnodup
      rcases List.mem_cons.mp hp with rfl | hp
      · simp
      · have hne : q.1 ≠ p.1 := by
          intro heq
          exact hnodup.1 (heq ▸ List.mem_map_of_mem hp)
        simp [hne, ih hnodup.2 hp]

theorem mapM_except_ok {α β ε : Type} {f : α → Except ε β} :
    ∀ {xs : List α} {ys : List β}, xs.mapM f = .ok ys → ListRel (fun x y => f x = .ok y) xs ys
  | [], ys, h => by
      simp only [List.mapM_nil] at h
      cases h
      exact .nil
  | x :: xs, ys, h => by
      simp only [List.mapM_cons, bind, Except.bind] at h
      split at h
      · cases h
      · rename_i y hy
        split at h
        · cases h
        · rename_i ys' hys
          simp only [pure, Except.pure, Except.ok.injEq] at h
          subst h
          exact .cons hy (mapM_except_ok hys)

theorem prepareWord_ok {mapping : List (String × String)} {word : CheckedWord}
    {prepared : CheckedWord × String × List Target.Instruction}
    (h : prepareWord mapping word = .ok prepared) :
    prepared.1 = word ∧
      lowerProgram { word := word.name, words := mapping } word.program = .ok prepared.2.2 := by
  unfold prepareWord at h
  cases hc : lowerProgram { word := word.name, words := mapping } word.program with
  | error e => simp [hc, bind, Except.bind] at h
  | ok code =>
      cases hw : Target.wellFormedCode code <;> cases hb : Target.boundViolation code <;>
        cases hr : WordType.render word.scheme <;>
        simp_all [bind, Except.bind, pure, Except.pure]
      all_goals (subst h; exact ⟨rfl, rfl⟩)

theorem wordEntry_ok {mapping : List (String × String)}
    {prepared : CheckedWord × String × List Target.Instruction} {entry : Target.WordEntry}
    (h : wordEntry mapping prepared = .ok entry) :
    entry.code = prepared.2.2 ∧
      ∃ source, mapping.find? (fun e => e.1 == prepared.1.name) = some (source, entry.name) := by
  obtain ⟨word, erased, code⟩ := prepared
  cases hfind : mapping.find? (fun e => e.1 == word.name) with
  | none => simp [wordEntry, hfind, bind, Except.bind] at h
  | some found =>
      simp only [wordEntry, hfind, bind, Except.bind, pure, Except.pure, Except.ok.injEq] at h
      subst h
      exact ⟨rfl, found.1, by simp⟩

theorem entries_of_prepared {mapping : List (String × String)} :
    ∀ {words : List CheckedWord} {prepared : List (CheckedWord × String × List Target.Instruction)}
      {entries : List Target.WordEntry},
      ListRel (fun word p => prepareWord mapping word = .ok p) words prepared →
      ListRel (fun p entry => wordEntry mapping p = .ok entry) prepared entries →
      ListRel (fun word entry =>
        mapping.find? (fun e => e.1 == word.name) = some (word.name, entry.name) ∧
        lowerProgram { word := word.name, words := mapping } word.program = .ok entry.code)
        words entries
  | _, _, _, .nil, .nil => .nil
  | _, _, _, .cons hw hp, .cons he hrest => by
      obtain ⟨hword, hlower⟩ := prepareWord_ok hw
      obtain ⟨hcode, source, hfind⟩ := wordEntry_ok he
      refine .cons ⟨?_, ?_⟩ (entries_of_prepared hp hrest)
      · rw [hword] at hfind
        have hsrc := List.find?_some hfind
        simp only [beq_iff_eq] at hsrc
        rw [hsrc] at hfind
        exact hfind
      · rw [hcode, hlower]

/-- Every emitted entry is one source word, in order, lowered by
`lowerProgram` under the dictionary's name map and published under the target
name that map gives it. -/
theorem compileWords_ok {words : List CheckedWord} {entries : List Target.WordEntry}
    (h : compileWords words = .ok entries) :
    ∃ mapping, nameMap words = .ok mapping ∧
      ListRel (fun word entry =>
        mapping.find? (fun e => e.1 == word.name) = some (word.name, entry.name) ∧
        lowerProgram { word := word.name, words := mapping } word.program = .ok entry.code)
        words entries := by
  simp only [compileWords, bind, Except.bind] at h
  split at h
  · cases h
  · rename_i mapping hmapping
    refine ⟨mapping, hmapping, ?_⟩
    split at h
    · cases h
    · rename_i prepared hprepared
      split at h
      · cases h
      · exact entries_of_prepared (mapM_except_ok hprepared) (mapM_except_ok h)

end Firth.Compiler.Lowering
