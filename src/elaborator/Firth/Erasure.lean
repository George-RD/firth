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
  /-- A local is used after `call`, `dip` or `if` ran a quotation whose stack
  effect is not known here, so where the local sits can't be determined. -/
  | untrackedStack (name : String) (span : Span)
  /-- An operation would take a local that is not yet used, and it could not
  be moved out of the way. A block's locals are off the stack for its body. -/
  | hiddenLocal (name : String) (span : Span)
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
  /-- The stack effect of the quotation the local holds, when known, so that
  running a selected copy keeps the tracked stack exact. -/
  effect : Option (Nat × Nat) := none
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
  /-- Set once a quotation of unknown stack effect has run: from then on the
  tracked stack may not match the real one, so no local may be located. -/
  untracked : Bool := false
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

/-- The slot named `name` of the innermost block that binds it. Blocks name
values where they sit, so an inner block's locals can lie below an outer
block's; scope, not stack position, decides. Families are numbered as blocks
are entered, so the innermost block has the largest. -/
private def firstNamedSlot (name : String) : List StackEntry → Option Slot
  | [] => none
  | x :: xs =>
    let deeper := firstNamedSlot name xs
    match x.slot with
    | some slot =>
        if slot.name == name then match deeper with
          | some other => if other.family > slot.family then some other else some slot
          | none => some slot
        else deeper
    | none => deeper

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

/-- Runs a quotation of known effect on `stack`. Fails, rather than
truncating, when the stack holds fewer values than the effect consumes: the
caller then retries a quotation body with more seed values, so the effect it
records is the body's true depth. -/
private def applyEffect (effect : Nat × Nat) (stack : List StackEntry) :
    Option (List StackEntry) :=
  if stack.length < effect.1 then none
  else some (List.replicate effect.2 { usage := .many } ++ stack.drop effect.1)

/-- Both branches run on the same stack, so they must change its depth by the
same amount; the deeper of the two inputs is consumed. -/
private def branchEffect : Option (Nat × Nat) → Option (Nat × Nat) → Option (Nat × Nat)
  | some (i, o), some (i', o') =>
      if o + i' = o' + i then some (max i i', max i i' + o - i) else none
  | _, _ => none

/-- The tracked stack after a higher-order atom, and whether it is still
exact. A quotation of unknown effect leaves the stack as it was and marks it
inexact; a stack too short for the atom, or for the effect it runs, is an
error. -/
private def runKnown (effect : Option (Nat × Nat)) (stack whole : List StackEntry)
    (wrap : List StackEntry → List StackEntry) : Option (List StackEntry × Bool) :=
  match effect with
  | some effect => (applyEffect effect stack).map (fun next => (wrap next, true))
  | none => some (whole, false)

private def callMove : List StackEntry → Option (List StackEntry × Bool)
  | quotation :: rest => runKnown quotation.effect rest (quotation :: rest) id
  | [] => none

private def dipMove : List StackEntry → Option (List StackEntry × Bool)
  | quotation :: preserved :: rest =>
      runKnown quotation.effect rest (quotation :: preserved :: rest) (preserved :: ·)
  | _ => none

private def ifMove : List StackEntry → Option (List StackEntry × Bool)
  | falseBranch :: trueBranch :: condition :: rest =>
      runKnown (branchEffect trueBranch.effect falseBranch.effect) rest
        (falseBranch :: trueBranch :: condition :: rest) id
  | _ => none

/-- The effect a quotation body records, unless running it lost track of the stack. -/
private def bodyEffect (seedCount : Nat) (final : State) : Option (Nat × Nat) :=
  if final.untracked then none else some (seedCount, final.stack.length)

private def composeEffect : Option (Nat × Nat) → Option (Nat × Nat) → Option (Nat × Nat)
  | some (i₁, o₁), some (i₂, o₂) => some (i₁ + (i₂ - o₁), o₂ + (o₁ - i₂))
  | _, _ => none

private def composeMove : List StackEntry → Option (List StackEntry × Bool)
  | second :: first :: rest =>
      some ({ usage := .many, effect := composeEffect first.effect second.effect } :: rest, true)
  | _ => none

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
  | .integer value => some (.int value)
  | .boolean value => some (.bool value)
  | .integers values => some (.intSeq values)
  | .booleans values => some (.boolSeq values)
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

/-- A local not yet used: a name, not a value the body can see on the stack. -/
def hiddenEntry (entry : StackEntry) : Bool :=
  (entry.slot.map (·.available)).getD false

/-- The top `count` values the body can see, top first, passing over unused
locals: those are off the stack for the body, wherever they physically sit. -/
def bindable : Nat → List StackEntry → List StackEntry
  | 0, _ => []
  | _, [] => []
  | count + 1, entry :: rest =>
      if hiddenEntry entry then bindable (count + 1) rest else entry :: bindable count rest

/-- Replaces the values `bindable` chose with `named`, top first, in place. -/
def nameInPlace : List StackEntry → List StackEntry → List StackEntry
  | [], stack => stack
  | _, [] => []
  | name :: names, entry :: rest =>
      if hiddenEntry entry then entry :: nameInPlace (name :: names) rest
      else name :: nameInPlace names rest

private def boundSlots (names : List LocatedName) (state : State) : List Slot :=
  let top := bindable names.length state.stack
  let slots : List Slot := (names.zip top.reverse).map (fun (name, entry) =>
    { id := 0, name := name.name, usage := entry.usage, origin := name.span,
      family := state.nextId,
      restoredId := entry.slot.map (·.id), effect := entry.effect })
  slots.zip (List.range slots.length) |>.map (fun (slot, index) =>
    { slot with id := state.nextId + index })

/-- A block names values where they sit, so binding emits no code. -/
private def enteredLocalState (names : List LocatedName) (state : State) : State :=
  let slots := boundSlots names state
  let named := slots.reverse.map (fun slot =>
      { slot := some slot, usage := slot.usage, effect := slot.effect })
  { state with stack := nameInPlace named state.stack, nextId := state.nextId + names.length }

private def localStack (names : List LocatedName) (state : State) : Except ErasureError (State × List Slot) :=
  if (bindable names.length state.stack).length < names.length then .error (.missingStackValue (names.head?.map (·.span) |>.getD emptySpan))
  else .ok (enteredLocalState names state, boundSlots names state)

/-- When a block ends its names go out of scope. Whatever is left on the stack
of its locals has been used (cleanup dropped the rest), so it becomes an
anonymous value; a name left on it would hide the same name of an enclosing
block. -/
private def restoreParents (slots : List Slot) (stack : List StackEntry) : List StackEntry :=
  stack.map fun entry => match entry.slot with
  | some child =>
      if slots.any (fun declared => declared.family == child.family) then
        { entry with slot := none }
      else entry
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

/-- The recursion budget for erasing `items`. Closing a quotation over the
locals it uses (`liftCaptures`) adds a prefix and a `locals` block around its
body, once per enclosing quotation level, so the budget grows with nesting as
well as size. It only bounds recursion; erasure never runs it out on a
program the checker could accept without also running out of names. -/
private def erasureDepth (items : List Item) : Nat :=
  (itemsFuel items + 1) * 8 ^ (2 * itemsNesting items + 2)

private def demandCountWithFuel (fuel : Nat) (name : String) (items : List Item) : Nat :=
  match fuel with
  | 0 => 0
  | fuel + 1 => match items with
    | [] => 0
    | .word n _ :: xs => (if n == name then 1 else 0) + demandCountWithFuel fuel name xs
    | .locals names body _ :: xs =>
        (if names.any (fun binding => binding.name == name) then 0
          else demandCountWithFuel fuel name body) + demandCountWithFuel fuel name xs
    -- A use inside a quotation is lifted out to where the quotation is built.
    | .quotation body _ :: xs =>
        demandCountWithFuel fuel name body + demandCountWithFuel fuel name xs
    | _ :: xs => demandCountWithFuel fuel name xs

private def demandCount (name : String) (items : List Item) : Nat :=
  demandCountWithFuel (itemsFuel items) name items

/-- How many uses of a local remain, counting this one. The rest of the
block that bound it shows every later use. A local of an enclosing block may
also be used after the inner block ends, which the inner block can't see, so
a `many` one is always copied and the copy left over is dropped when its own
block ends. -/
private def useCount (slots : List Slot) (slot : Slot) (name : String) (rest : List Item) : Nat :=
  if slots.any (fun declared => declared.family == slot.family) || slot.usage == .linear then
    1 + demandCount name rest
  else 2

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
    | .quotation body _ :: xs =>
        demandSpansWithFuel fuel name body ++ demandSpansWithFuel fuel name xs
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
    -- Names bound inside the scanned items are lifted when their block is
    -- erased, so they may be used from nested quotations too.
    | .quotation body _ :: xs =>
        match captureScanWithFuel fuel bound visible body with
        | some result => some result
        | none => captureScanWithFuel fuel bound visible xs
    | .locals names body _ :: xs =>
        match captureScanWithFuel fuel (names.map (·.name) ++ bound) visible body with
        | some result => some result
        | none => captureScanWithFuel fuel bound visible xs
    | _ :: xs => captureScanWithFuel fuel bound visible xs

/-- The visible locals used in `items` and not shadowed there, first use first. -/
private def freeNamesWithFuel (fuel : Nat) (visible shadow : List String) (items : List Item) :
    List String :=
  match fuel with
  | 0 => []
  | fuel + 1 => items.foldl (fun found item =>
      let more := match item with
        | .word name _ =>
            if visible.contains name && !shadow.contains name then [name] else []
        | .quotation body _ => freeNamesWithFuel fuel visible shadow body
        | .locals names body _ =>
            freeNamesWithFuel fuel visible (names.map LocatedName.name ++ shadow) body
        | _ => []
      found ++ more.filter (fun name => !found.contains name)) []

/-- A quotation body is erased on its own, without the enclosing locals, so a
quotation that uses them is closed over their values where it is built:
`[ s ]` using `x` and `y` becomes `x quote y quote compose [ locals { x y }
{ s } ] compose`. The values are selected like any other use; when the
quotation runs it pushes them and binds them again, so `s` is erased as the
body of an ordinary block. Every name `s` uses is bound there, including uses
in nested quotations and blocks, and the constant prefix has the known effect
`(0, k)`, so running the quotation keeps the tracked stack exact. -/
private def closeQuotation (visible : List String) (fuel : Nat) (span : Span)
    (body : List Item) : List Item :=
  match freeNamesWithFuel fuel visible [] body with
  | [] => [.quotation body span]
  | first :: rest =>
      [.word first span, .atom "quote" span] ++
        rest.flatMap (fun name => [.word name span, .atom "quote" span, .atom "compose" span]) ++
        [.quotation [.locals ((first :: rest).map (fun name => ({ name, span } : LocatedName)))
          body span] span,
         .atom "compose" span]

private def liftCapturesWithFuel (fuel : Nat) (visible : List String) (items : List Item) :
    List Item :=
  match fuel with
  | 0 => items
  | fuel + 1 => items.flatMap fun item => match item with
    | .quotation body span => closeQuotation visible fuel span body
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

/-- A not-yet-used local among the top `count` entries. Those are the values an
operation takes; a local there would be consumed or moved as if it were an
ordinary stack value, which it is not in the body of its block. -/
def hiddenIn (count : Nat) (stack : List StackEntry) : Option Slot :=
  (stack.take count).findSome? fun entry => entry.slot.filter (·.available)

/-- How many top entries an atom takes, including the values a quotation of
known effect takes when the atom runs it. -/
def atomReach (name : String) (stack : List StackEntry) : Nat :=
  let inputs (entry : StackEntry) := (entry.effect.map (·.1)).getD 0
  match name, stack with
  | "call", quotation :: _ => 1 + inputs quotation
  | "dip", quotation :: _ => 2 + inputs quotation
  | "if", falseBranch :: trueBranch :: _ =>
      3 + ((branchEffect trueBranch.effect falseBranch.effect).map (·.1)).getD 0
  | "compose", _ | "swap", _ => 2
  | "dup", _ | "drop", _ | "quote", _ => 1
  | _, _ => 0

inductive AppliesSignature (signature : Signature) (state : State) : State → Prop where
  | apply
      (enough : signature.input.length ≤ state.stack.length)
      (clear : hiddenIn signature.input.length state.stack = none)
      (compatible : (signature.input.zip (state.stack.take signature.input.length)).any
        (fun (expected, actual) => expected == .many && actual.usage == .linear) = false) :
      AppliesSignature signature state
        { state with
          stack := signature.output.map (fun usage => { usage }) ++
            state.stack.drop signature.input.length }

inductive BindsLocals (names : List LocatedName) (state : State) : State → List Slot → Prop where
  | bind (enough : names.length ≤ (bindable names.length state.stack).length) :
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
    Slot.mk (state.nextId + index) name slot.usage slot.origin none slot.family true true slot.effect)

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
  copies.reverse.map (fun fresh => { slot := some fresh, usage := fresh.usage, effect := fresh.effect })

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
          Slot.mk (state.nextId + index) name slot.usage slot.origin none slot.family true true slot.effect))

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
          copies.reverse.map (fun fresh => { slot := some fresh, usage := fresh.usage, effect := fresh.effect }) ++
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
  | dip {span : Span} {state : State} {next : List StackEntry} {exact : Bool}
      (moved : dipMove state.stack = some (next, exact)) :
      ErasesAtomTo "dip" span state (atomList .dip span)
        { state with stack := next, untracked := state.untracked || !exact }
  | call {span : Span} {state : State} {next : List StackEntry} {exact : Bool}
      (moved : callMove state.stack = some (next, exact)) :
      ErasesAtomTo "call" span state (atomList .call span)
        { state with stack := next, untracked := state.untracked || !exact }
  | compose {span : Span} {state : State} {next : List StackEntry} {exact : Bool}
      (moved : composeMove state.stack = some (next, exact)) :
      ErasesAtomTo "compose" span state (atomList .compose span)
        { state with stack := next, untracked := state.untracked || !exact }
  | ifThenElse {span : Span} {state : State} {next : List StackEntry} {exact : Bool}
      (moved : ifMove state.stack = some (next, exact)) :
      ErasesAtomTo "if" span state (atomList .ifThenElse span)
        { state with stack := next, untracked := state.untracked || !exact }

private def NonWord : Item → Prop
  | .word _ _ => False
  | _ => True

/-- `program` run under the top `count` values: `[ [ program ] dip ] dip`... -/
def dipWrap (span : Span) : Nat → KernelProgram → KernelProgram
  | 0, program => program
  | count + 1, program => [locatedQuotation span (dipWrap span count program)] ++ atomList .dip span

/-- Items that take values from the stack, and so may need to run beneath
unused locals sitting on top of it. -/
def itemSpan : Item → Span
  | .literal _ span | .word _ span | .atom _ span | .primitive _ span
  | .quotation _ span | .locals _ _ span => span

def takesValues : Item → Bool
  | .atom .. | .word .. | .primitive .. => true
  | _ => false

/-- How many top values an item takes. -/
def itemReach (env : EffectEnv) (stack : List StackEntry) : Item → Nat
  | .atom name _ => atomReach name stack
  | .word name _ => ((env.word name).map (·.input.length)).getD 0
  | .primitive name _ => ((env.primitive name).map (·.input.length)).getD 0
  | _ => 0

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
      (clear : hiddenIn (atomReach name state.stack) state.stack = none)
      (step : ErasesAtomTo name span state program next) :
      ErasureRel env (.item (.atom name span) visible) state program next
  /-- An unused local lying among the values the item takes is moved to the
  top first, where the item then runs beneath it. Only a name moves; the
  values keep their order. -/
  | raise {item : Item} {span : Span} {state next : State} {visible : List String}
      {id : Nat} {focus program : KernelProgram} {focused : List StackEntry}
      (named : state.stack.any (fun entry => hiddenEntry entry && isFocusTarget id entry) = true)
      (focusedBy : FocusRel id span state.stack focus focused)
      (itemRun : ErasureRel env (.item item visible) { state with stack := focused } program next) :
      ErasureRel env (.item item visible) state (focus ++ program) next
  /-- Unused locals on top are names, not values the item can see: the item
  runs beneath them, and they stay on top. -/
  | beneath {item : Item} {span : Span} {state next : State} {visible : List String}
      {count : Nat} {program : KernelProgram}
      (leading : count ≤ (state.stack.takeWhile hiddenEntry).length)
      (itemRun : ErasureRel env (.item item visible)
        { state with stack := state.stack.drop count } program next) :
      ErasureRel env (.item item visible) state (dipWrap span count program)
        { next with stack := state.stack.take count ++ next.stack }
  | quotation {body : List Item} {span : Span} {state bodyFinal : State}
      {visible : List String} {program : KernelProgram} {seedCount : Nat}
      (closed : captureIn visible body = none)
      (bodyRun : ErasureRel env (.items body visible)
        { stack := List.replicate seedCount { usage := .many } } program bodyFinal) :
      ErasureRel env (.item (.quotation body span) visible) state [locatedQuotation span program]
        { state with stack := { usage := .many, effect := bodyEffect seedCount bodyFinal } ::
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
      (tracked : (!state.untracked || !state.stack.any (cleanupCandidate slots)) = true)
      (cleanup : CleansLocals slots state program cleaned) :
      ErasureRel env (.localBody [] slots visible) state program
        { cleaned with stack := restoreParents slots cleaned.stack }
  | select {name : String} {span : Span} {rest : List Item} {state next final : State}
      {slots : List Slot} {visible : List String} {slot : Slot}
      {head tail : KernelProgram}
      (active : (slots.any (fun declared => declared.name == name) || visible.contains name) = true)
      (tracked : state.untracked = false)
      (resolved : ResolvesSlot name state.stack slot)
      (linearOnce : slot.usage = .linear → useCount slots slot name rest = 1)
      (expanded : ExpandsDemand slot name span (useCount slots slot name rest)
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
  else match clearEq : hiddenIn signature.input.length state.stack with
  | some slot => .error (.hiddenLocal slot.name span)
  | none =>
    let bad := (signature.input.zip (state.stack.take signature.input.length)).any
      (fun (expected, actual) => expected == .many && actual.usage == .linear)
    if mismatch : bad = true then .error (.usageMismatch name span)
    else
      let next := { state with
        stack := signature.output.map (fun usage => { usage }) ++
          state.stack.drop signature.input.length }
      have compatible : bad = false := bool_eq_false_of_not_true mismatch
      .ok ⟨next, .apply (Nat.le_of_not_gt short) clearEq compatible⟩

private def bindLocalsWithProof (names : List LocatedName) (state : State) :
    Except ErasureError (BindingRun names state) :=
  if short : (bindable names.length state.stack).length < names.length then
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

    | .item item visible =>
      let count := (state.stack.takeWhile hiddenEntry).length
      if takesValues item && count > 0 then
        match eraseSubjectWithProof depth env (.item item visible)
            { state with stack := state.stack.drop count } with
        | .error error => .error error
        | .ok inner => .ok {
            program := dipWrap (itemSpan item) count inner.program
            final := { inner.final with stack := state.stack.take count ++ inner.final.stack }
            evidence := .beneath (Nat.le_refl _) inner.evidence }
      else match (if takesValues item then hiddenIn (itemReach env state.stack item) state.stack
          else none) with
      | some slot =>
        if namedEq : state.stack.any (fun entry => hiddenEntry entry && isFocusTarget slot.id entry)
            = true then
          match focusEq : focusAtoms slot.id (itemSpan item) state.stack with
          | .error error => .error error
          | .ok (focus, focused) =>
            match eraseSubjectWithProof depth env (.item item visible) { state with stack := focused } with
            | .error error => .error error
            | .ok inner => .ok {
                program := focus ++ inner.program
                final := inner.final
                evidence := .raise namedEq (focusAtoms_correct _ _ _ focusEq) inner.evidence }
        else .error (.hiddenLocal slot.name (itemSpan item))
      | none => match item with
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
      | .atom name span => (match clearEq : hiddenIn (atomReach name state.stack) state.stack with
      | some slot => .error (.hiddenLocal slot.name span)
      | none => (match name with
        | "swap" => match stackEq : state.stack with
          | a :: b :: rest => .ok {
              program := atomList .swap span
              final := { state with stack := b :: a :: rest }
              evidence := .atom clearEq (.swap stackEq) }
          | _ => .error (.effectUnderflow name span)
        | "dup" => match stackEq : state.stack with
          | a :: rest => match usageEq : a.usage with
            | .many => .ok {
                program := atomList .dup span
                final := { state with stack := a :: a :: rest }
                evidence := .atom clearEq (.dup stackEq usageEq) }
            | .linear => .error (.linearCopy name span)
          | _ => .error (.effectUnderflow name span)
        | "drop" => match stackEq : state.stack with
          | a :: rest => match usageEq : a.usage with
            | .many => .ok {
                program := atomList .drop span
                final := { state with stack := rest }
                evidence := .atom clearEq (.drop stackEq usageEq) }
            | .linear => match a.slot with
              | some slot => .error (.linearUnused slot.name span)
              | none => .error (.linearCopy name span)
          | _ => .error (.effectUnderflow name span)
        | "quote" => match stackEq : state.stack with
          | a :: rest => .ok {
              program := atomList .quote span
              final := { state with stack := { usage := a.usage, effect := some (0, 1) } :: rest }
              evidence := .atom clearEq (.quote stackEq) }
          | _ => .error (.effectUnderflow name span)
        | "dip" => match movedEq : dipMove state.stack with
          | some (next, exact) => .ok {
              program := atomList .dip span
              final := { state with stack := next, untracked := state.untracked || !exact }
              evidence := .atom clearEq (.dip movedEq) }
          | none => .error (.effectUnderflow name span)
        | "call" => match movedEq : callMove state.stack with
          | some (next, exact) => .ok {
              program := atomList .call span
              final := { state with stack := next, untracked := state.untracked || !exact }
              evidence := .atom clearEq (.call movedEq) }
          | none => .error (.effectUnderflow name span)
        | "compose" => match movedEq : composeMove state.stack with
          | some (next, exact) => .ok {
              program := atomList .compose span
              final := { state with stack := next, untracked := state.untracked || !exact }
              evidence := .atom clearEq (.compose movedEq) }
          | none => .error (.effectUnderflow name span)
        | "if" => match movedEq : ifMove state.stack with
          | some (next, exact) => .ok {
              program := atomList .ifThenElse span
              final := { state with stack := next, untracked := state.untracked || !exact }
              evidence := .atom clearEq (.ifThenElse movedEq) }
          | none => .error (.effectUnderflow name span)
        | _ => .error (.unsupportedAtom name span)))
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
                { usage := .many, effect := bodyEffect bodyRun.seedCount bodyRun.final } ::
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
      | [] =>
        if trackedEq : (!state.untracked || !state.stack.any (cleanupCandidate slots)) = true then
          match cleanupWithProof slots state with
          | .error error => .error error
          | .ok cleaned => .ok {
              program := cleaned.program
              final := { cleaned.final with stack := restoreParents slots cleaned.final.stack }
              evidence := .localDone trackedEq cleaned.evidence }
        else
          let unused := (slots.find? (fun slot => state.stack.any (fun entry =>
            cleanupCandidate slots entry && (entry.slot.map (·.id) == some slot.id)))).getD
              (slots.head?.getD { id := 0, name := "local", usage := .many, origin := emptySpan })
          .error (.untrackedStack unused.name unused.origin)
      | item :: rest => match item with
        | .word name localSpan =>
          if activeEq : slots.any (fun slot => slot.name == name) || visible.contains name then
            if untrackedEq : state.untracked = true then .error (.untrackedStack name localSpan) else
            have trackedEq : state.untracked = false := by simpa using untrackedEq
            match resolveSlotWithProof name localSpan state.stack with
            | .error error => .error error
            | .ok selected =>
              let count := useCount slots selected.slot name rest
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
                        exact .select activeEq trackedEq selected.evidence linearOnce
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
                    dsimp [count, useCount]
                    split <;> omega
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
