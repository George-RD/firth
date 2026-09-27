import elaborator.Firth.Parser
import Firth.Interpreter

namespace Firth.Elaborator

open Firth.Interpreter

structure LocatedKernel where
  span : Span
  atom : Atom
  childSpans : List Span := []
  children : List LocatedKernel := []
  deriving Repr, BEq

abbrev KernelProgram := List LocatedKernel

structure Signature where
  input : List Usage := []
  output : List Usage := []
  deriving Repr, BEq

structure EffectEnv where
  word : String → Option Signature := fun _ => none
  primitive : String → Option Signature := fun _ => none

inductive ErasureError where
  | duplicateLocal (name : String) (span : Span)
  | unboundLocal (name : String) (span : Span)
  | unsupportedCapture (name : String) (span : Span)
  | missingStackValue (span : Span)
  | linearCopy (name : String) (span : Span)
  | linearUnused (name : String) (span : Span)
  | unresolvedEffect (name : String) (span : Span)
  | effectUnderflow (name : String) (span : Span)
  | usageMismatch (name : String) (span : Span)
  | unsupportedLiteral (span : Span)
  | unsupportedAtom (name : String) (span : Span)
  deriving Repr, BEq

structure LintWarning where
  code : String
  span : Span
  deriving Repr, BEq

structure ErasureResult where
  program : KernelProgram
  warnings : List LintWarning := []
  deriving Repr, BEq

structure Slot where
  id : Nat
  name : String
  usage : Usage
  origin : Span
  restoredId : Option Nat := none
  family : Nat := 0
  available : Bool := true
  expanded : Bool := false
  deriving Repr, BEq

structure StackEntry where
  slot : Option Slot := none
  usage : Usage
  /-- For a quotation built in this body: how many values it consumes and
  produces, as inferred when it was erased. -/
  effect : Option (Nat × Nat) := none
  deriving Repr, BEq

structure State where
  stack : List StackEntry
  nextId : Nat := 0
  deriving Repr, BEq

private def located (span : Span) (atom : Atom) : LocatedKernel := { span, atom }

private def emptySpan : Span :=
  { start := { offset := 0, line := 1, column := 1 }, stop := { offset := 0, line := 1, column := 1 } }

private instance : Inhabited ErasureError := ⟨.missingStackValue emptySpan⟩

private def toProgram : KernelProgram → Program
  | [] => .empty
  | x :: xs => .cons x.atom (toProgram xs)

private def locatedQuotation (span : Span) (program : KernelProgram) : LocatedKernel :=
  { span, atom := .quotation (toProgram program), childSpans := program.map (·.span), children := program }

private def atomList (atom : Atom) (span : Span) : KernelProgram := [located span atom]

private def structural : Atom → Bool
  | .dup | .drop | .swap | .dip => true
  | _ => false

private def longestStructuralRun (program : KernelProgram) : Nat :=
  let rec go (items : KernelProgram) (run best : Nat) : Nat :=
    match items with
    | [] => max run best
    | item :: rest => if structural item.atom then go rest (run + 1) best else go rest 0 (max run best)
  go program 0 0

private def duplicateName : List LocatedName → Option LocatedName
  | [] => none
  | x :: xs => match xs.find? (fun y => y.name == x.name) with
    | some duplicate => some duplicate
    | none => duplicateName xs

private def firstNamedSlot (name : String) : List StackEntry → Option Slot
  | [] => none
  | x :: xs => match x.slot with
    | some slot => if slot.name == name then some slot else firstNamedSlot name xs
    | none => firstNamedSlot name xs

private def availableFamily (name : String) (family : Nat) : List StackEntry → Option Slot
  | [] => none
  | x :: xs => match x.slot with
    | some slot => if slot.name == name && slot.family == family && slot.available then some slot
      else availableFamily name family xs
    | none => availableFamily name family xs

private def findSlotFrom (name : String) (span : Span) (stack : List StackEntry) : Except ErasureError Slot :=
  match firstNamedSlot name stack with
  | none => .error (.unboundLocal name span)
  | some first => match availableFamily name first.family stack with
    | some slot => .ok slot
    | none => if first.usage == .linear then .error (.linearUnused name span)
      else .error (.unboundLocal name span)

private def findSlot (name : String) (span : Span) (stack : List StackEntry) : Except ErasureError Slot :=
  findSlotFrom name span stack

private def markUnavailable (id : Nat) : List StackEntry → List StackEntry
  | [] => []
  | x :: xs => match x.slot with
    | some slot => if slot.id == id then { x with slot := some { slot with available := false } } :: xs
                   else x :: markUnavailable id xs
    | none => x :: markUnavailable id xs

private def markExpanded (id : Nat) : List StackEntry → List StackEntry
  | [] => []
  | x :: xs => match x.slot with
    | some slot => if slot.id == id then { x with slot := some { slot with expanded := true } } :: xs
                   else x :: markExpanded id xs
    | none => x :: markExpanded id xs

private def isFocusTarget (id : Nat) (entry : StackEntry) : Bool :=
  match entry.slot with
  | some slot => slot.id == id
  | none => false

/-! Higher-order atoms move the tracked stack by the effect of the quotation
they run. A quotation whose effect is unknown (it came from the input or a
word) leaves the tracked stack as it was; the type checker still decides. -/

private def applyEffect (effect : Nat × Nat) (stack : List StackEntry) : List StackEntry :=
  List.replicate effect.2 { usage := .many } ++ stack.drop effect.1

private def callStack : List StackEntry → List StackEntry
  | quotation :: rest => match quotation.effect with
    | some effect => applyEffect effect rest
    | none => quotation :: rest
  | [] => []

private def dipStack : List StackEntry → List StackEntry
  | quotation :: preserved :: rest => match quotation.effect with
    | some effect => preserved :: applyEffect effect rest
    | none => quotation :: preserved :: rest
  | stack => stack

/-- Both branches run on the same stack, so they must change its depth by the
same amount; the deeper of the two inputs is consumed. -/
private def branchEffect : Option (Nat × Nat) → Option (Nat × Nat) → Option (Nat × Nat)
  | some (i, o), some (i', o') =>
      if o + i' = o' + i then some (max i i', max i i' + o - i) else none
  | _, _ => none

private def ifStack : List StackEntry → List StackEntry
  | falseBranch :: trueBranch :: condition :: rest =>
      match branchEffect trueBranch.effect falseBranch.effect with
      | some effect => applyEffect effect rest
      | none => falseBranch :: trueBranch :: condition :: rest
  | stack => stack

private def composeEffect : Option (Nat × Nat) → Option (Nat × Nat) → Option (Nat × Nat)
  | some (i₁, o₁), some (i₂, o₂) => some (i₁ + (i₂ - o₁), o₂ + (o₁ - i₂))
  | _, _ => none

private def composeStack : List StackEntry → List StackEntry
  | second :: first :: rest =>
      { usage := .many, effect := composeEffect first.effect second.effect } :: rest
  | stack => stack

inductive FocusRel (id : Nat) (span : Span) :
    List StackEntry → KernelProgram → List StackEntry → Prop where
  | top {target : StackEntry} {rest : List StackEntry}
      (targeted : isFocusTarget id target = true) :
      FocusRel id span (target :: rest) [] (target :: rest)
  | adjacent {guard target : StackEntry} {rest : List StackEntry}
      (guarded : isFocusTarget id guard = false)
      (targeted : isFocusTarget id target = true) :
      FocusRel id span (guard :: target :: rest) (atomList .swap span)
        (target :: guard :: rest)
  | protect {guard next focusedTarget : StackEntry} {rest after : List StackEntry}
      {inner : KernelProgram}
      (guarded : isFocusTarget id guard = false)
      (notNext : isFocusTarget id next = false)
      (innerFocus : FocusRel id span (next :: rest) inner (focusedTarget :: after)) :
      FocusRel id span (guard :: next :: rest)
        ([locatedQuotation span inner] ++ atomList .dip span ++ atomList .swap span)
        (focusedTarget :: guard :: after)

private theorem FocusRel.focused_ne_nil {id : Nat} {span : Span}
    {stack : List StackEntry} {program : KernelProgram} {focused : List StackEntry}
    (relation : FocusRel id span stack program focused) : focused ≠ [] := by
  cases relation with
  | top | adjacent | protect =>
      intro impossible
      cases impossible

private structure FocusRun (id : Nat) (span : Span) (stack : List StackEntry) where
  program : KernelProgram
  focused : List StackEntry
  evidence : FocusRel id span stack program focused

private def focusAtomsWithProof (id : Nat) (span : Span) :
    (stack : List StackEntry) → Except ErasureError (FocusRun id span stack)
  | [] => .error (.missingStackValue span)
  | target :: rest =>
      match targetEq : isFocusTarget id target with
      | true => .ok { program := [], focused := target :: rest, evidence := .top targetEq }
      | false => match rest with
        | [] => .error (.missingStackValue span)
        | next :: tail => match nextEq : isFocusTarget id next with
          | true => .ok {
              program := atomList .swap span
              focused := next :: target :: tail
              evidence := .adjacent targetEq nextEq }
          | false => match focusAtomsWithProof id span (next :: tail) with
            | .error error => .error error
            | .ok inner => match focusedEq : inner.focused with
              | [] => False.elim (inner.evidence.focused_ne_nil focusedEq)
              | focusedTarget :: after => .ok {
                  program := [locatedQuotation span inner.program] ++ atomList .dip span ++
                    atomList .swap span
                  focused := focusedTarget :: target :: after
                  evidence := .protect targetEq nextEq (focusedEq ▸ inner.evidence) }

private def focusAtoms (id : Nat) (span : Span) (stack : List StackEntry) :
    Except ErasureError (KernelProgram × List StackEntry) :=
  focusAtomsWithProof id span stack |>.map (fun run => (run.program, run.focused))

private def literalAtom : Firth.Elaborator.Literal → Option Firth.Interpreter.Literal
  | .integer value => if value < 0 then none else some (.nat value.toNat)
  | .boolean value => some (.bool value)
  | _ => none

private def applySignature (name : String) (span : Span) (signature : Signature) (state : State) : Except ErasureError State :=
  if state.stack.length < signature.input.length then .error (.effectUnderflow name span)
  else if (signature.input.zip (state.stack.take signature.input.length)).any
      (fun (expected, actual) => expected == .many && actual.usage == .linear) then
    .error (.usageMismatch name span)
  else
    let remaining := state.stack.drop signature.input.length
    let produced := signature.output.map (fun usage => { usage })
    .ok { state with stack := produced ++ remaining }

private def initialState (effect : StackEffect) : State :=
  let usages := effect.input.reverse.map (fun item => match item with
    | .row _ _ => Usage.many
    | .value _ type _ => type.usage)
  { stack := usages.map (fun usage => { usage }) }

private def boundSlots (names : List LocatedName) (state : State) : List Slot :=
  let top := state.stack.take names.length
  let slots : List Slot := (names.zip top.reverse).map (fun (name, entry) =>
    { id := 0, name := name.name, usage := entry.usage, origin := name.span,
      family := state.nextId,
      restoredId := entry.slot.map (·.id) })
  slots.zip (List.range slots.length) |>.map (fun (slot, index) =>
    { slot with id := state.nextId + index })

private def enteredLocalState (names : List LocatedName) (state : State) : State :=
  let slots := boundSlots names state
  let replaced := slots.reverse.map (fun slot => { slot := some slot, usage := slot.usage }) ++
    state.stack.drop names.length
  { stack := replaced, nextId := state.nextId + names.length }

private def localStack (names : List LocatedName) (state : State) : Except ErasureError (State × List Slot) :=
  if state.stack.length < names.length then .error (.missingStackValue (names.head?.map (·.span) |>.getD emptySpan))
  else .ok (enteredLocalState names state, boundSlots names state)

private def restoreParents (slots : List Slot) (stack : List StackEntry) : List StackEntry :=
  stack.map fun entry => match entry.slot with
  | some child => match slots.find? (fun slot => slot.id == child.id) with
    | some declared => match declared.restoredId with
      | some parent => { entry with slot := some { child with id := parent, available := false } }
      | none => entry
    | none => entry
  | none => entry

private def cleanup (slots : List Slot) (state : State) : Except ErasureError (KernelProgram × State) :=
  let rec loop (fuel : Nat) (current : State) (out : KernelProgram) : Except ErasureError (KernelProgram × State) :=
    match fuel with
    | 0 => .ok (out, current)
    | fuel + 1 =>
      match current.stack.find? (fun entry => match entry.slot with
        | some slot => slots.any (fun declared => declared.id == slot.id) && slot.available
        | none => false) with
      | none => .ok (out, current)
      | some entry => match entry.slot with
        | none => .ok (out, current)
        | some candidate =>
          if candidate.usage == .linear then .error (.linearUnused candidate.name candidate.origin)
          else match focusAtoms candidate.id candidate.origin current.stack with
            | .error e => .error e
            | .ok (focus, focused) =>
                loop fuel { current with stack := focused.drop 1 } (out ++ focus ++ atomList .drop candidate.origin)
  loop (state.stack.length + 1) state []

mutual
  private def itemFuel : Item → Nat
    | .quotation body _ | .locals _ body _ => itemsFuel body + 1
    | _ => 1

  private def itemsFuel : List Item → Nat
    | [] => 1
    | item :: rest => itemFuel item + itemsFuel rest + 1
end

mutual
  private def itemNesting : Item → Nat
    | .quotation body _ | .locals _ body _ => itemsNesting body + 1
    | _ => 0

  private def itemsNesting : List Item → Nat
    | [] => 0
    | item :: rest => max (itemNesting item) (itemsNesting rest)
end

/-- The recursion budget for erasing `items`. Lifting captured locals out of
quotations (`liftCaptures`) turns each item into at most five, once per
enclosing quotation level, so the budget grows with nesting as well as size. -/
private def erasureDepth (items : List Item) : Nat :=
  itemsFuel items * 6 ^ (itemsNesting items + 1)

private def demandCountWithFuel (fuel : Nat) (name : String) (items : List Item) : Nat :=
  match fuel with
  | 0 => 0
  | fuel + 1 => match items with
    | [] => 0
    | .word n _ :: xs => (if n == name then 1 else 0) + demandCountWithFuel fuel name xs
    | .locals names body _ :: xs =>
        (if names.any (fun binding => binding.name == name) then 0
          else demandCountWithFuel fuel name body) + demandCountWithFuel fuel name xs
    | .quotation _ _ :: xs => demandCountWithFuel fuel name xs
    | _ :: xs => demandCountWithFuel fuel name xs

private def demandCount (name : String) (items : List Item) : Nat :=
  demandCountWithFuel (itemsFuel items) name items

private def demandSpansWithFuel (fuel : Nat) (name : String) (items : List Item) : List Span :=
  match fuel with
  | 0 => []
  | fuel + 1 => match items with
    | [] => []
    | .word n span :: xs =>
        (if n == name then [span] else []) ++ demandSpansWithFuel fuel name xs
    | .locals names body _ :: xs =>
        (if names.any (fun binding => binding.name == name) then []
          else demandSpansWithFuel fuel name body) ++ demandSpansWithFuel fuel name xs
    | .quotation _ _ :: xs => demandSpansWithFuel fuel name xs
    | _ :: xs => demandSpansWithFuel fuel name xs

private def demandSpans (name : String) (items : List Item) : List Span :=
  demandSpansWithFuel (itemsFuel items) name items

private def captureScanWithFuel (fuel : Nat) (bound visible : List String)
    (items : List Item) : Option (String × Span) :=
  match fuel with
  | 0 => none
  | fuel + 1 => match items with
    | [] => none
    | .word name span :: xs =>
        if bound.contains name then captureScanWithFuel fuel bound visible xs
        else if visible.contains name then some (name, span)
        else captureScanWithFuel fuel bound visible xs
    | .quotation body _ :: xs =>
        match captureScanWithFuel fuel [] (bound ++ visible) body with
        | some result => some result
        | none => captureScanWithFuel fuel bound visible xs
    | .locals names body _ :: xs =>
        match captureScanWithFuel fuel (names.map (·.name) ++ bound) visible body with
        | some result => some result
        | none => captureScanWithFuel fuel bound visible xs
    | _ :: xs => captureScanWithFuel fuel bound visible xs

/-- Splits a quotation body at its references to visible locals:
`[ s0 x s1 ]` becomes `[ s0 ] x quote compose [ s1 ] compose`. The local is
selected when the quotation is built, as any other use of it is, and its
value is carried by `quote`. -/
private def splitQuotation (visible : List String) (span : Span) (body : List Item) :
    List Item :=
  let rec go (items segment : List Item) (out : List Item) : List Item :=
    match items with
    | [] =>
        if segment.isEmpty then out
        else out ++ [.quotation segment.reverse span, .atom "compose" span]
    | .word name wordSpan :: rest =>
        if visible.contains name then
          let flushed := if segment.isEmpty then out
            else out ++ [.quotation segment.reverse span, .atom "compose" span]
          go rest [] (flushed ++ [.word name wordSpan, .atom "quote" wordSpan, .atom "compose" wordSpan])
        else go rest (.word name wordSpan :: segment) out
    | item :: rest => go rest (item :: segment) out
  match body.span (fun item => match item with
      | .word name _ => !visible.contains name
      | _ => true) with
  | (_, []) => [.quotation body span]
  | (first, rest) => go rest [] [.quotation first span]

/-- Lifts local references out of quotation bodies, innermost first, so a
quotation can use the locals of the block it is written in. -/
private def liftCapturesWithFuel (fuel : Nat) (visible : List String) (items : List Item) :
    List Item :=
  match fuel with
  | 0 => items
  | fuel + 1 => items.flatMap fun item => match item with
    | .quotation body span => splitQuotation visible span (liftCapturesWithFuel fuel visible body)
    | other => [other]

private def liftCaptures (visible : List String) (items : List Item) : List Item :=
  liftCapturesWithFuel (itemsFuel items) visible items

private def captureIn (visible : List String) (items : List Item) : Option (String × Span) :=
  captureScanWithFuel (itemsFuel items) [] visible items

private def quotationInferenceFuelWithFuel (fuel : Nat) (env : EffectEnv)
    (items : List Item) : Nat :=
  match fuel with
  | 0 => 1
  | fuel + 1 => match items with
    | [] => 1
    | item :: rest =>
      let itemWidth := match item with
        -- Kernel atoms bypass EffectEnv, but can still demand quotation inputs.
        -- Counting their input arities gives a conservative finite search bound;
        -- the actual erasure attempt and stack-effect checker remain the judges.
        | .atom name _ => match name with
          | "dup" | "drop" | "quote" | "call" => 1
          | "swap" | "dip" | "compose" => 2
          | "if" => 3
          | _ => 0
        | .word name _ => (env.word name).map (·.input.length) |>.getD 0
        | .primitive name _ => (env.primitive name).map (·.input.length) |>.getD 0
        | .quotation body _ => quotationInferenceFuelWithFuel fuel env body
        | .locals names body _ => names.length + quotationInferenceFuelWithFuel fuel env body + 1
        | _ => 0
      itemWidth + quotationInferenceFuelWithFuel fuel env rest

private def quotationInferenceFuel (env : EffectEnv) (items : List Item) : Nat :=
  quotationInferenceFuelWithFuel (itemsFuel items) env items

/- Relational erasure is indexed by the symbolic stack before and after each
   source fragment.  In particular, a local source item relates to a whole
   kernel program, rather than to one atom.  None of these judgements mentions
   the executable `erase` function. -/

inductive AppliesSignature (signature : Signature) (state : State) : State → Prop where
  | apply
      (enough : signature.input.length ≤ state.stack.length)
      (compatible : (signature.input.zip (state.stack.take signature.input.length)).any
        (fun (expected, actual) => expected == .many && actual.usage == .linear) = false) :
      AppliesSignature signature state
        { state with
          stack := signature.output.map (fun usage => { usage }) ++
            state.stack.drop signature.input.length }

inductive BindsLocals (names : List LocatedName) (state : State) : State → List Slot → Prop where
  | bind (enough : names.length ≤ state.stack.length) :
      BindsLocals names state (enteredLocalState names state) (boundSlots names state)

inductive ResolvesSlot (name : String) (stack : List StackEntry) (slot : Slot) : Prop where
  | resolve {shadow : Slot}
      (firstFamily : firstNamedSlot name stack = some shadow)
      (availableInFamily : availableFamily name shadow.family stack = some slot) :
      ResolvesSlot name stack slot

private def cleanupCandidate (slots : List Slot) (entry : StackEntry) : Bool :=
  match entry.slot with
  | some slot => slots.any (fun declared => declared.id == slot.id) && slot.available
  | none => false

inductive CleansLocals (slots : List Slot) : State → KernelProgram → State → Prop where
  | done {state : State}
      (noCandidate : state.stack.find? (cleanupCandidate slots) = none) :
      CleansLocals slots state [] state
  | discard {state : State} {entry : StackEntry} {candidate : Slot}
      {focus tail : KernelProgram} {focused : List StackEntry} {final : State}
      (nearest : state.stack.find? (cleanupCandidate slots) = some entry)
      (isCandidate : entry.slot = some candidate)
      (many : candidate.usage = .many)
      (focusedBy : FocusRel candidate.id candidate.origin state.stack focus focused)
      (rest : CleansLocals slots { state with stack := focused.drop 1 } tail final) :
      CleansLocals slots state (focus ++ atomList .drop candidate.origin ++ tail) final

/-- A use copies the local only when a later use still needs it, and makes
one copy at a time. Copying every later use up front made the stack, and the
code that reaches into it, grow with the number of uses. -/
private def demandCopies (slot : Slot) (name : String) (count : Nat) (state : State) : List Slot :=
  List.range (if count > 1 then 1 else 0) |>.map (fun index =>
    Slot.mk (state.nextId + index) name slot.usage slot.origin none slot.family true true)

/-- `dup` applied to the value `depth` places below the top, leaving the
values above it where they are: `[dup]`, `[[dup] dip]`, `[[[dup] dip] dip]`... -/
private def dupAtDepth (span : Span) : Nat → KernelProgram
  | 0 => atomList .dup span
  | depth + 1 => [locatedQuotation span (dupAtDepth span depth)] ++ atomList .dip span

/-- Extra copies of a local are made where the local already sits, so values
already selected above it keep their places. -/
private def copyProgram (span : Span) (depth : Nat) (copies : List Slot) : KernelProgram :=
  (List.replicate copies.length (dupAtDepth span depth)).flatten

private def copyEntries (copies : List Slot) : List StackEntry :=
  copies.reverse.map (fun fresh => { slot := some fresh, usage := fresh.usage })

/-- The stack after `copyProgram`: the copies sit at `depth`, above the local. -/
private def spliceCopies (depth : Nat) (copies : List Slot) (stack : List StackEntry) :
    List StackEntry :=
  stack.take depth ++ copyEntries copies ++ stack.drop depth

/-- The value the use selects: the nearest copy, or the local itself. -/
private def selectedId (slot : Slot) (copies : List Slot) : Nat :=
  (copies.getLast?).map (·.id) |>.getD slot.id

private def demandState (slot : Slot) (state : State) (focused : List StackEntry)
    (copies : List Slot) : State :=
  { state with
    nextId := state.nextId + copies.length
    stack := markUnavailable (selectedId slot copies) (markExpanded slot.id focused) }

inductive DemandCopiesRel (slot : Slot) (name : String) (count : Nat) (state : State) :
    List Slot → Prop where
  | generate :
      DemandCopiesRel slot name count state
        (List.range (if count > 1 then 1 else 0) |>.map (fun index =>
          Slot.mk (state.nextId + index) name slot.usage slot.origin none slot.family true true))

inductive DemandStateRel (slot : Slot) (state : State) (focused : List StackEntry)
    (copies : List Slot) : State → Prop where
  | advance : DemandStateRel slot state focused copies
      { state with
        nextId := state.nextId + copies.length
        stack := markUnavailable ((copies.getLast?).map (·.id) |>.getD slot.id)
          (markExpanded slot.id focused) }

/-- One use of a local: copy it in place if a later use still needs it, then
bring the selected value to the top. -/
inductive ExpandsDemand (slot : Slot) (name : String) (span : Span) (count : Nat)
    (state : State) : KernelProgram → State → Prop where
  | expand {copies : List Slot} {depth : Nat} {focus : KernelProgram}
      {focused : List StackEntry} {next : State}
      (copiesRule : DemandCopiesRel slot name count state copies)
      (located : state.stack.findIdx? (isFocusTarget slot.id) = some depth)
      (focusedBy : FocusRel ((copies.getLast?).map (·.id) |>.getD slot.id) span
        (state.stack.take depth ++
          copies.reverse.map (fun fresh => { slot := some fresh, usage := fresh.usage }) ++
          state.stack.drop depth) focus focused)
      (stateRule : DemandStateRel slot state focused copies next) :
      ExpandsDemand slot name span count state
        ((List.replicate copies.length (dupAtDepth span depth)).flatten ++ focus) next

inductive ErasesAtomTo : String → Span → State → KernelProgram → State → Prop where
  | swap {span : Span} {state : State} {a b : StackEntry} {rest : List StackEntry}
      (shape : state.stack = a :: b :: rest) :
      ErasesAtomTo "swap" span state
        (atomList .swap span) { state with stack := b :: a :: rest }
  | dup {span : Span} {state : State} {a : StackEntry} {rest : List StackEntry}
      (shape : state.stack = a :: rest)
      (many : a.usage = .many) :
      ErasesAtomTo "dup" span state
        (atomList .dup span) { state with stack := a :: a :: rest }
  | drop {span : Span} {state : State} {a : StackEntry} {rest : List StackEntry}
      (shape : state.stack = a :: rest)
      (many : a.usage = .many) :
      ErasesAtomTo "drop" span state
        (atomList .drop span) { state with stack := rest }
  | quote {span : Span} {state : State} {a : StackEntry} {rest : List StackEntry}
      (shape : state.stack = a :: rest) :
      ErasesAtomTo "quote" span state
        (atomList .quote span)
        { state with stack := { usage := a.usage, effect := some (0, 1) } :: rest }
  | dip {span : Span} {state : State} :
      ErasesAtomTo "dip" span state (atomList .dip span)
        { state with stack := dipStack state.stack }
  | call {span : Span} {state : State} :
      ErasesAtomTo "call" span state (atomList .call span)
        { state with stack := callStack state.stack }
  | compose {span : Span} {state : State} :
      ErasesAtomTo "compose" span state (atomList .compose span)
        { state with stack := composeStack state.stack }
  | ifThenElse {span : Span} {state : State} :
      ErasesAtomTo "if" span state (atomList .ifThenElse span)
        { state with stack := ifStack state.stack }

private def NonWord : Item → Prop
  | .word _ _ => False
  | _ => True

abbrev ScopeState := State
abbrev SurfaceItem := Item

inductive ErasureSubject where
  | items (items : List SurfaceItem) (visible : List String)
  | item (item : SurfaceItem) (visible : List String)
  | localBody (items : List SurfaceItem) (slots : List Slot) (visible : List String)

inductive ErasureRel (env : EffectEnv) :
    ErasureSubject → ScopeState → KernelProgram → ScopeState → Prop where
  | nil {state : ScopeState} {visible : List String} :
      ErasureRel env (.items [] visible) state [] state
  | cons {item : Item} {rest : List Item} {state next final : State}
      {visible : List String} {head tail : KernelProgram}
      (itemRun : ErasureRel env (.item item visible) state head next)
      (restRun : ErasureRel env (.items rest visible) next tail final) :
      ErasureRel env (.items (item :: rest) visible) state (head ++ tail) final
  | literal {literal : Located Literal} {span : Span} {value : Firth.Interpreter.Literal}
      {state : State} {visible : List String}
      (translated : literalAtom literal.value = some value) :
      ErasureRel env (.item (.literal literal span) visible) state (atomList (.lit value) span)
        { state with stack := { usage := .many } :: state.stack }
  | word {name : String} {span : Span} {signature : Signature} {state next : State}
      {visible : List String}
      (resolved : env.word name = some signature)
      (applied : AppliesSignature signature state next) :
      ErasureRel env (.item (.word name span) visible) state (atomList (.word name) span) next
  | primitive {name : String} {span : Span} {signature : Signature} {state next : State}
      {visible : List String}
      (resolved : env.primitive name = some signature)
      (applied : AppliesSignature signature state next) :
      ErasureRel env (.item (.primitive name span) visible) state (atomList (.prim name) span) next
  | atom {name : String} {span : Span} {state next : State} {visible : List String}
      {program : KernelProgram}
      (step : ErasesAtomTo name span state program next) :
      ErasureRel env (.item (.atom name span) visible) state program next
  | quotation {body : List Item} {span : Span} {state bodyFinal : State}
      {visible : List String} {program : KernelProgram} {seedCount : Nat}
      (closed : captureIn visible body = none)
      (bodyRun : ErasureRel env (.items body visible)
        { stack := List.replicate seedCount { usage := .many } } program bodyFinal) :
      ErasureRel env (.item (.quotation body span) visible) state [locatedQuotation span program]
        { state with stack := { usage := .many, effect := some (seedCount, bodyFinal.stack.length) } ::
          state.stack }
  | locals {names : List LocatedName} {body : List Item} {span : Span}
      {state entered final : State} {visible : List String} {slots : List Slot}
      {program : KernelProgram}
      (unique : duplicateName names = none)
      (binding : BindsLocals names state entered slots)
      (bodyRun : ErasureRel env
        (.localBody (liftCaptures (names.map (·.name) ++ visible) body) slots
          (names.map (·.name) ++ visible)) entered program final) :
      ErasureRel env (.item (.locals names body span) visible) state program final
  | localDone {state cleaned : State} {slots : List Slot} {visible : List String}
      {program : KernelProgram}
      (cleanup : CleansLocals slots state program cleaned) :
      ErasureRel env (.localBody [] slots visible) state program
        { cleaned with stack := restoreParents slots cleaned.stack }
  | select {name : String} {span : Span} {rest : List Item} {state next final : State}
      {slots : List Slot} {visible : List String} {slot : Slot}
      {head tail : KernelProgram}
      (active : (slots.any (fun declared => declared.name == name) || visible.contains name) = true)
      (resolved : ResolvesSlot name state.stack slot)
      (linearOnce : slot.usage = .linear → 1 + demandCount name rest = 1)
      (expanded : ExpandsDemand slot name span (1 + demandCount name rest)
        state head next)
      (restRun : ErasureRel env (.localBody rest slots visible) next tail final) :
      ErasureRel env (.localBody (.word name span :: rest) slots visible)
        state (head ++ tail) final
  | globalWord {name : String} {span : Span} {rest : List Item} {state next final : State}
      {slots : List Slot} {visible : List String} {head tail : KernelProgram}
      (inactive : (slots.any (fun declared => declared.name == name) || visible.contains name) = false)
      (itemRun : ErasureRel env (.item (.word name span) visible) state head next)
      (restRun : ErasureRel env (.localBody rest slots visible) next tail final) :
      ErasureRel env (.localBody (.word name span :: rest) slots visible)
        state (head ++ tail) final
  | ordinary {item : Item} {rest : List Item} {state next final : State}
      {slots : List Slot} {visible : List String} {head tail : KernelProgram}
      (nonWord : NonWord item)
      (itemRun : ErasureRel env (.item item visible) state head next)
      (restRun : ErasureRel env (.localBody rest slots visible) next tail final) :
      ErasureRel env (.localBody (item :: rest) slots visible) state (head ++ tail) final

abbrev ErasesToState (env : EffectEnv) (items : List SurfaceItem) (state : ScopeState)
    (visible : List String) (program : KernelProgram) (final : ScopeState) : Prop :=
  ErasureRel env (.items items visible) state program final

abbrev ErasesItemTo (env : EffectEnv) (item : SurfaceItem) (state : ScopeState)
    (visible : List String) (program : KernelProgram) (final : ScopeState) : Prop :=
  ErasureRel env (.item item visible) state program final

abbrev ErasesLocalBodyTo (env : EffectEnv) (items : List SurfaceItem) (state : ScopeState)
    (slots : List Slot) (visible : List String) (program : KernelProgram)
    (final : ScopeState) : Prop :=
  ErasureRel env (.localBody items slots visible) state program final

inductive ErasesToUnder (env : EffectEnv) (effect : StackEffect) :
    List Item → KernelProgram → Prop where
  | run {body : List Item} {program : KernelProgram} {final : State}
      (bodyRun : ErasesToState env body (initialState effect) [] program final) :
      ErasesToUnder env effect body program

def ErasesTo (body : List SurfaceItem) (program : KernelProgram) : Prop :=
  ∃ env effect, ErasesToUnder env effect body program

private structure ErasureRun (env : EffectEnv) (subject : ErasureSubject)
    (initial : State) where
  program : KernelProgram
  final : State
  evidence : ErasureRel env subject initial program final

private abbrev ItemsRun (env : EffectEnv) (items : List Item) (initial : State)
    (visible : List String) := ErasureRun env (.items items visible) initial

private abbrev ItemRun (env : EffectEnv) (item : Item) (initial : State)
    (visible : List String) := ErasureRun env (.item item visible) initial

private abbrev LocalRun (env : EffectEnv) (items : List Item) (initial : State)
    (slots : List Slot) (visible : List String) :=
  ErasureRun env (.localBody items slots visible) initial

private structure CleanupRun (slots : List Slot) (initial : State) where
  program : KernelProgram
  final : State
  evidence : CleansLocals slots initial program final

private structure BindingRun (names : List LocatedName) (initial : State) where
  entered : State
  slots : List Slot
  evidence : BindsLocals names initial entered slots

private structure SlotRun (name : String) (stack : List StackEntry) where
  slot : Slot
  evidence : ResolvesSlot name stack slot

private structure QuotationRun (env : EffectEnv) (body : List Item) (visible : List String) where
  seedCount : Nat
  program : KernelProgram
  final : State
  evidence : ErasesToState env body
    { stack := List.replicate seedCount { usage := .many } } visible program final

private theorem bool_eq_false_of_not_true {value : Bool} (notTrue : ¬value = true) :
    value = false := by
  cases value with
  | false => rfl
  | true => exact False.elim (notTrue rfl)

private theorem focusAtoms_correct (id : Nat) (span : Span) (stack : List StackEntry)
    {program : KernelProgram} {focused : List StackEntry}
    (success : focusAtoms id span stack = .ok (program, focused)) :
    FocusRel id span stack program focused := by
  cases runEq : focusAtomsWithProof id span stack with
  | error error =>
      simp only [focusAtoms, runEq, Except.map] at success
      cases success
  | ok run =>
      simp only [focusAtoms, runEq, Except.map] at success
      cases success
      exact run.evidence

private theorem demandCopies_correct (slot : Slot) (name : String) (count : Nat)
    (state : State) :
    DemandCopiesRel slot name count state (demandCopies slot name count state) := by
  rw [demandCopies]
  exact .generate

private theorem demandState_correct (slot : Slot) (state : State)
    (focused : List StackEntry) (copies : List Slot) :
    DemandStateRel slot state focused copies (demandState slot state focused copies) := by
  rw [demandState, selectedId]
  exact .advance

private def applySignatureWithProof (name : String) (span : Span) (signature : Signature)
    (state : State) : Except ErasureError { next : State // AppliesSignature signature state next } :=
  if short : state.stack.length < signature.input.length then .error (.effectUnderflow name span)
  else
    let bad := (signature.input.zip (state.stack.take signature.input.length)).any
      (fun (expected, actual) => expected == .many && actual.usage == .linear)
    if mismatch : bad = true then .error (.usageMismatch name span)
    else
      let next := { state with
        stack := signature.output.map (fun usage => { usage }) ++
          state.stack.drop signature.input.length }
      have compatible : bad = false := bool_eq_false_of_not_true mismatch
      .ok ⟨next, .apply (Nat.le_of_not_gt short) compatible⟩

private def bindLocalsWithProof (names : List LocatedName) (state : State) :
    Except ErasureError (BindingRun names state) :=
  if short : state.stack.length < names.length then
    .error (.missingStackValue (names.head?.map (·.span) |>.getD emptySpan))
  else .ok {
    entered := enteredLocalState names state
    slots := boundSlots names state
    evidence := .bind (Nat.le_of_not_gt short) }

private def resolveSlotWithProof (name : String) (span : Span) (stack : List StackEntry) :
    Except ErasureError (SlotRun name stack) :=
  match firstEq : firstNamedSlot name stack with
  | none => .error (.unboundLocal name span)
  | some shadow => match availableEq : availableFamily name shadow.family stack with
    | some slot => .ok { slot, evidence := .resolve firstEq availableEq }
    | none => if shadow.usage == .linear then .error (.linearUnused name span)
      else .error (.unboundLocal name span)

private def cleanupWithProof (slots : List Slot) (state : State) :
    Except ErasureError (CleanupRun slots state) :=
  let rec loop (fuel : Nat) (current : State) : Except ErasureError (CleanupRun slots current) :=
    match fuel with
    | 0 => .error (.missingStackValue emptySpan)
    | fuel + 1 => match nearestEq : current.stack.find? (cleanupCandidate slots) with
      | none => .ok { program := [], final := current, evidence := .done nearestEq }
      | some entry => match slotEq : entry.slot with
        | none => .error (.missingStackValue emptySpan)
        | some candidate => match usageEq : candidate.usage with
          | .linear => .error (.linearUnused candidate.name candidate.origin)
          | .many => match focusEq : focusAtoms candidate.id candidate.origin current.stack with
            | .error error => .error error
            | .ok (focus, focused) =>
              let next := { current with stack := focused.drop 1 }
              match loop fuel next with
              | .error error => .error error
              | .ok tail => .ok {
                  program := focus ++ atomList .drop candidate.origin ++ tail.program
                  final := tail.final
                  evidence := .discard nearestEq slotEq usageEq
                    (focusAtoms_correct _ _ _ focusEq) tail.evidence }
  termination_by fuel
  loop (state.stack.length + 1) state

private def quotationAttemptsWithProof (seedCounts : List Nat) (env : EffectEnv)
    (body : List Item) (visible : List String) (span : Span)
    (run : (count : Nat) → Except ErasureError (ItemsRun env body
      { stack := List.replicate count { usage := .many } } visible)) :
    Except ErasureError (QuotationRun env body visible) :=
  match seedCounts with
  | [] => .error (.effectUnderflow "quotation" span)
  | seedCount :: rest => match run seedCount with
    | .ok bodyRun => .ok {
        seedCount
        program := bodyRun.program
        final := bodyRun.final
        evidence := bodyRun.evidence }
    | .error (.effectUnderflow _ _) =>
        quotationAttemptsWithProof rest env body visible span run
    | .error (.missingStackValue _) =>
        quotationAttemptsWithProof rest env body visible span run
    | .error error => .error error

private def quotationWithProof (fuel seedCount : Nat) (env : EffectEnv)
    (body : List Item) (visible : List String) (span : Span)
    (run : (count : Nat) → Except ErasureError (ItemsRun env body
      { stack := List.replicate count { usage := .many } } visible)) :
    Except ErasureError (QuotationRun env body visible) :=
  let seedCounts := List.range fuel |>.map (seedCount + ·)
  quotationAttemptsWithProof seedCounts env body visible span run

private def eraseSubjectWithProof (depth : Nat) (env : EffectEnv)
    (subject : ErasureSubject) (state : State) :
    Except ErasureError (ErasureRun env subject state) :=
  match depth with
  | 0 => .error (.effectUnderflow "erasure-depth" emptySpan)
  | depth + 1 => match subject with
    | .items items visible => match items with
      | [] => .ok { program := [], final := state, evidence := .nil }
      | item :: rest => match eraseSubjectWithProof depth env (.item item visible) state with
        | .error error => .error error
        | .ok head => match eraseSubjectWithProof depth env (.items rest visible) head.final with
          | .error error => .error error
          | .ok tail => .ok {
              program := head.program ++ tail.program
              final := tail.final
              evidence := .cons head.evidence tail.evidence }

    | .item item visible => match item with
      | .literal literal span => match translatedEq : literalAtom literal.value with
        | none => .error (.unsupportedLiteral span)
        | some value => .ok {
            program := atomList (.lit value) span
            final := { state with stack := { usage := .many } :: state.stack }
            evidence := .literal translatedEq }
      | .word name span => match resolvedEq : env.word name with
        | none => .error (.unresolvedEffect name span)
        | some signature => match applySignatureWithProof name span signature state with
          | .error error => .error error
          | .ok applied => .ok {
              program := atomList (.word name) span
              final := applied.val
              evidence := .word resolvedEq applied.property }
      | .primitive name span => match resolvedEq : env.primitive name with
        | none => .error (.unresolvedEffect name span)
        | some signature => match applySignatureWithProof name span signature state with
          | .error error => .error error
          | .ok applied => .ok {
              program := atomList (.prim name) span
              final := applied.val
              evidence := .primitive resolvedEq applied.property }
      | .atom name span => match name with
        | "swap" => match stackEq : state.stack with
          | a :: b :: rest => .ok {
              program := atomList .swap span
              final := { state with stack := b :: a :: rest }
              evidence := .atom (.swap stackEq) }
          | _ => .error (.effectUnderflow name span)
        | "dup" => match stackEq : state.stack with
          | a :: rest => match usageEq : a.usage with
            | .many => .ok {
                program := atomList .dup span
                final := { state with stack := a :: a :: rest }
                evidence := .atom (.dup stackEq usageEq) }
            | .linear => .error (.linearCopy name span)
          | _ => .error (.effectUnderflow name span)
        | "drop" => match stackEq : state.stack with
          | a :: rest => match usageEq : a.usage with
            | .many => .ok {
                program := atomList .drop span
                final := { state with stack := rest }
                evidence := .atom (.drop stackEq usageEq) }
            | .linear => match a.slot with
              | some slot => .error (.linearUnused slot.name span)
              | none => .error (.linearCopy name span)
          | _ => .error (.effectUnderflow name span)
        | "quote" => match stackEq : state.stack with
          | a :: rest => .ok {
              program := atomList .quote span
              final := { state with stack := { usage := a.usage, effect := some (0, 1) } :: rest }
              evidence := .atom (.quote stackEq) }
          | _ => .error (.effectUnderflow name span)
        | "dip" => .ok {
            program := atomList .dip span
            final := { state with stack := dipStack state.stack }
            evidence := .atom .dip }
        | "call" => .ok {
            program := atomList .call span
            final := { state with stack := callStack state.stack }
            evidence := .atom .call }
        | "compose" => .ok {
            program := atomList .compose span
            final := { state with stack := composeStack state.stack }
            evidence := .atom .compose }
        | "if" => .ok {
            program := atomList .ifThenElse span
            final := { state with stack := ifStack state.stack }
            evidence := .atom .ifThenElse }
        | _ => .error (.unsupportedAtom name span)
      | .quotation body quotationSpan => match closedEq : captureIn visible body with
        | some (name, localSpan) => .error (.unsupportedCapture name localSpan)
        | none =>
          match quotationWithProof (quotationInferenceFuel env body) 0 env body visible
              quotationSpan (fun seedCount => eraseSubjectWithProof depth env (.items body visible)
                { stack := List.replicate seedCount { usage := .many } }) with
          | .error error => .error error
          | .ok bodyRun => .ok {
              program := [locatedQuotation quotationSpan bodyRun.program]
              final := { state with stack :=
                { usage := .many, effect := some (bodyRun.seedCount, bodyRun.final.stack.length) } ::
                  state.stack }
              evidence := .quotation closedEq bodyRun.evidence }
      | .locals names body _ => match uniqueEq : duplicateName names with
        | some duplicate => .error (.duplicateLocal duplicate.name duplicate.span)
        | none => match bindLocalsWithProof names state with
          | .error error => .error error
          | .ok binding =>
            let nestedVisible := names.map (·.name) ++ visible
            match eraseSubjectWithProof depth env
                (.localBody (liftCaptures nestedVisible body) binding.slots nestedVisible)
                binding.entered with
            | .error error => .error error
            | .ok bodyRun => .ok {
                program := bodyRun.program
                final := bodyRun.final
                evidence := .locals uniqueEq binding.evidence bodyRun.evidence }

    | .localBody items slots visible => match items with
      | [] => match cleanupWithProof slots state with
        | .error error => .error error
        | .ok cleaned => .ok {
            program := cleaned.program
            final := { cleaned.final with stack := restoreParents slots cleaned.final.stack }
            evidence := .localDone cleaned.evidence }
      | item :: rest => match item with
        | .word name localSpan =>
          if activeEq : slots.any (fun slot => slot.name == name) || visible.contains name then
            let count := 1 + demandCount name rest
            match resolveSlotWithProof name localSpan state.stack with
            | .error error => .error error
            | .ok selected =>
              let proceed (linearOnce : selected.slot.usage = .linear → count = 1) :=
                let copies := demandCopies selected.slot name count state
                match depthEq : state.stack.findIdx? (isFocusTarget selected.slot.id) with
                | none => .error (.unboundLocal name localSpan)
                | some position =>
                match focusEq : focusAtoms (selectedId selected.slot copies) localSpan
                    (spliceCopies position copies state.stack) with
                | .error error => .error error
                | .ok (focus, focused) =>
                  let next := demandState selected.slot state focused copies
                  match eraseSubjectWithProof depth env (.localBody rest slots visible) next with
                  | .error error => .error error
                  | .ok tail => .ok {
                      program := copyProgram localSpan position copies ++ focus ++ tail.program
                      final := tail.final
                      evidence := by
                        exact .select activeEq selected.evidence linearOnce
                          (.expand (demandCopies_correct selected.slot name count state) depthEq
                            (focusAtoms_correct _ _ _ focusEq)
                            (demandState_correct selected.slot state focused copies))
                          tail.evidence }
              match usageEq : selected.slot.usage with
              | .many => proceed (by
                  intro linear
                  have impossible : Usage.many = Usage.linear := usageEq.symm.trans linear
                  cases impossible)
              | .linear =>
                if copied : count > 1 then
                  let useSpan := match demandSpans name rest with
                    | span :: _ => span
                    | [] => localSpan
                  .error (.linearCopy name useSpan)
                else proceed (by
                  intro _
                  have positive : 0 < count := by
                    dsimp [count]
                    exact Nat.add_pos_left (Nat.zero_lt_succ 0) _
                  exact Nat.le_antisymm (Nat.le_of_not_gt copied) positive)
          else match resolvedEq : env.word name with
            | none => .error (.unboundLocal name localSpan)
            | some _ => match eraseSubjectWithProof depth env (.item (.word name localSpan) visible)
                state with
              | .error error => .error error
              | .ok head => match eraseSubjectWithProof depth env (.localBody rest slots visible)
                  head.final with
                | .error error => .error error
                | .ok tail => .ok {
                    program := head.program ++ tail.program
                    final := tail.final
                    evidence := .globalWord (by
                      let active := slots.any (fun slot => slot.name == name) || visible.contains name
                      have inactive : active = false := by
                        cases value : active with
                        | false => rfl
                        | true => exact False.elim (activeEq value)
                      exact inactive) head.evidence tail.evidence }
        | .literal literal span =>
          match eraseSubjectWithProof depth env (.item (.literal literal span) visible) state with
          | .error error => .error error
          | .ok head => match eraseSubjectWithProof depth env (.localBody rest slots visible)
              head.final with
            | .error error => .error error
            | .ok tail => .ok {
                program := head.program ++ tail.program
                final := tail.final
                evidence := .ordinary trivial head.evidence tail.evidence }
        | .atom name span =>
          match eraseSubjectWithProof depth env (.item (.atom name span) visible) state with
          | .error error => .error error
          | .ok head => match eraseSubjectWithProof depth env (.localBody rest slots visible)
              head.final with
            | .error error => .error error
            | .ok tail => .ok {
                program := head.program ++ tail.program
                final := tail.final
                evidence := .ordinary trivial head.evidence tail.evidence }
        | .primitive name span =>
          match eraseSubjectWithProof depth env (.item (.primitive name span) visible) state with
          | .error error => .error error
          | .ok head => match eraseSubjectWithProof depth env (.localBody rest slots visible)
              head.final with
            | .error error => .error error
            | .ok tail => .ok {
                program := head.program ++ tail.program
                final := tail.final
                evidence := .ordinary trivial head.evidence tail.evidence }
        | .quotation body span =>
          match eraseSubjectWithProof depth env (.item (.quotation body span) visible) state with
          | .error error => .error error
          | .ok head => match eraseSubjectWithProof depth env (.localBody rest slots visible)
              head.final with
            | .error error => .error error
            | .ok tail => .ok {
                program := head.program ++ tail.program
                final := tail.final
                evidence := .ordinary trivial head.evidence tail.evidence }
        | .locals names body span =>
          match eraseSubjectWithProof depth env (.item (.locals names body span) visible) state with
          | .error error => .error error
          | .ok head => match eraseSubjectWithProof depth env (.localBody rest slots visible)
              head.final with
            | .error error => .error error
              | .ok tail => .ok {
                  program := head.program ++ tail.program
                  final := tail.final
                  evidence := .ordinary trivial head.evidence tail.evidence }
  termination_by structural depth

private def eraseItemsWithProof (depth : Nat) (env : EffectEnv) (items : List Item)
    (state : State) (visible : List String) : Except ErasureError (ItemsRun env items state visible) :=
  eraseSubjectWithProof depth env (.items items visible) state

private def eraseItemWithProof (depth : Nat) (env : EffectEnv) (item : Item)
    (state : State) (visible : List String) : Except ErasureError (ItemRun env item state visible) :=
  eraseSubjectWithProof depth env (.item item visible) state

private def eraseLocalBodyWithProof (depth : Nat) (env : EffectEnv) (items : List Item)
    (state : State) (slots : List Slot) (visible : List String) :
    Except ErasureError (LocalRun env items state slots visible) :=
  eraseSubjectWithProof depth env (.localBody items slots visible) state

private def eraseItems (env : EffectEnv) (items : List Item) (state : State)
    (visible : List String) : Except ErasureError (KernelProgram × State) :=
  eraseItemsWithProof (erasureDepth items) env items state visible |>.map
    (fun run => (run.program, run.final))

private def localDepthWarningsWithFuel (fuel : Nat) (items : List Item) : List LintWarning :=
  match fuel with
  | 0 => []
  | fuel + 1 => match items with
    | [] => []
    | item :: rest =>
      let nested := match item with
        | .quotation body _ => localDepthWarningsWithFuel fuel body
        | .locals _ body _ => localDepthWarningsWithFuel fuel body
        | _ => []
      let current := match item with
        | .locals names _ span => if names.length > 4 then
            [{ code := "LOCAL_DEPTH", span }] else []
        | _ => []
      current ++ nested ++ localDepthWarningsWithFuel fuel rest

private def localDepthWarnings (items : List Item) : List LintWarning :=
  localDepthWarningsWithFuel (itemsFuel items) items

def erase (env : EffectEnv) (effect : StackEffect) (body : List Item) : Except ErasureError ErasureResult :=
  eraseItems env body (initialState effect) [] |>.map (fun (program, _) =>
    { program,
      warnings := localDepthWarnings body ++
        (if longestStructuralRun program > 4 then [{ code := "STACK_JUGGLE", span := effect.span }] else []) })

theorem erase_sound_under (env : EffectEnv) (effect : StackEffect) (body : List Item)
    {result : ErasureResult} (success : erase env effect body = .ok result) :
    ErasesToUnder env effect body result.program := by
  cases runEq : eraseItemsWithProof (erasureDepth body) env body (initialState effect) [] with
  | error error =>
      simp only [erase, eraseItems, runEq, Except.map] at success
      cases success
  | ok run =>
      simp only [erase, eraseItems, runEq, Except.map] at success
      cases success
      exact .run run.evidence

theorem erase_sound (env : EffectEnv) (effect : StackEffect) (body : List Item)
    {result : ErasureResult} (success : erase env effect body = .ok result) :
    ErasesTo body result.program :=
  ⟨env, effect, erase_sound_under env effect body success⟩

end Firth.Elaborator
