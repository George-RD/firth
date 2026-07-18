import elaborator.Firth.Parser
import Firth.Interpreter

namespace Firth.Elaborator

open Firth.Interpreter

structure LocatedKernel where
  span : Span
  atom : Atom
  childSpans : List Span := []
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
  deriving Repr, BEq

structure State where
  stack : List StackEntry
  nextId : Nat := 0
  deriving Repr, BEq

private def located (span : Span) (atom : Atom) : LocatedKernel := { span, atom }

private def emptySpan : Span :=
  { start := { offset := 0, line := 1, column := 1 }, stop := { offset := 0, line := 1, column := 1 } }

private def toProgram : KernelProgram → Program
  | [] => .empty
  | x :: xs => .cons x.atom (toProgram xs)

private def locatedQuotation (span : Span) (program : KernelProgram) : LocatedKernel :=
  { span, atom := .quotation (toProgram program), childSpans := program.map (·.span) }

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

private def findSlotFrom (name : String) (span : Span) (family : Option Nat) : List StackEntry → Except ErasureError Slot
  | [] => .error (.unboundLocal name span)
  | x :: xs => match x.slot with
    | some slot => if slot.name == name then
        match family with
        | some owner => if slot.family == owner then
            if slot.available then .ok slot else findSlotFrom name span family xs
          else if slot.usage == .linear then .error (.linearUnused name span)
          else .error (.unboundLocal name span)
        | none => if slot.available then .ok slot else findSlotFrom name span (some slot.family) xs
      else findSlotFrom name span family xs
    | none => findSlotFrom name span family xs

private def findSlot (name : String) (span : Span) (stack : List StackEntry) : Except ErasureError Slot :=
  findSlotFrom name span none stack

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

private def focusAtoms (id : Nat) (span : Span) : List StackEntry → Except ErasureError (KernelProgram × List StackEntry)
  | [] => .error (.missingStackValue span)
  | target :: rest => match target.slot with
    | some slot => if slot.id == id then .ok ([], target :: rest) else descend target rest
    | none => descend target rest
  where
    descend (guard : StackEntry) : List StackEntry → Except ErasureError (KernelProgram × List StackEntry)
      | [] => .error (.missingStackValue span)
      | next :: tail => match next.slot with
        | some slot => if slot.id == id then
            .ok (atomList .swap span, next :: guard :: tail)
          else focusAtoms id span (next :: tail) |>.map (fun (inner, focused) =>
            match focused with
            | focusedTarget :: after =>
                ([locatedQuotation span inner] ++ atomList .dip span ++ atomList .swap span,
                 focusedTarget :: guard :: after)
            | [] => (inner, guard :: next :: tail))
        | none => focusAtoms id span (next :: tail) |>.map (fun (inner, focused) =>
            match focused with
            | focusedTarget :: after =>
                ([locatedQuotation span inner] ++ atomList .dip span ++ atomList .swap span,
                 focusedTarget :: guard :: after)
            | [] => (inner, guard :: next :: tail))
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

private def localStack (names : List LocatedName) (state : State) : Except ErasureError (State × List Slot) :=
  if state.stack.length < names.length then .error (.missingStackValue (names.head?.map (·.span) |>.getD emptySpan))
  else
    let top := state.stack.take names.length
    let slots : List Slot := (names.zip top.reverse).map (fun (name, entry) =>
      { id := 0, name := name.name, usage := entry.usage, origin := name.span,
        family := state.nextId,
        restoredId := entry.slot.map (·.id) })
    let slots := slots.zip (List.range slots.length) |>.map (fun (slot, index) =>
      { slot with id := state.nextId + index })
    let replaced := slots.reverse.map (fun slot => { slot := some slot, usage := slot.usage }) ++
      state.stack.drop names.length
    .ok ({ stack := replaced, nextId := state.nextId + names.length }, slots)

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

private def demandCount (name : String) : List Item → Nat
  | [] => 0
  | .word n _ :: xs => (if n == name then 1 else 0) + demandCount name xs
  | .locals names body _ :: xs =>
      (if names.any (fun binding => binding.name == name) then 0 else demandCount name body) + demandCount name xs
  | .quotation _ _ :: xs => demandCount name xs
  | _ :: xs => demandCount name xs

private def demandSpans (name : String) : List Item → List Span
  | [] => []
  | .word n span :: xs => (if n == name then [span] else []) ++ demandSpans name xs
  | .locals names body _ :: xs =>
      (if names.any (fun binding => binding.name == name) then [] else demandSpans name body) ++ demandSpans name xs
  | .quotation _ _ :: xs => demandSpans name xs
  | _ :: xs => demandSpans name xs

private def captureScan (bound visible : List String) : List Item → Option (String × Span)
  | [] => none
  | .word name span :: xs =>
      if bound.contains name then captureScan bound visible xs
      else if visible.contains name then some (name, span) else captureScan bound visible xs
  | .quotation body _ :: xs =>
      match captureScan [] (bound ++ visible) body with
      | some result => some result
      | none => captureScan bound visible xs
  | .locals names body _ :: xs =>
      match captureScan (names.map (·.name) ++ bound) visible body with
      | some result => some result
      | none => captureScan bound visible xs
  | _ :: xs => captureScan bound visible xs

private def captureIn (visible : List String) : List Item → Option (String × Span) :=
  captureScan [] visible

mutual
  partial def eraseQuotation (env : EffectEnv) (body : List Item) (visible : List String) (span : Span) :
      Except ErasureError KernelProgram :=
    let rec attempt (fuel : Nat) (seed : List StackEntry) : Except ErasureError KernelProgram :=
      match fuel with
      | 0 => .error (.effectUnderflow "quotation" span)
      | fuel + 1 => match eraseItems env body { stack := seed } visible with
        | .ok (program, _) => .ok program
        | .error (.effectUnderflow _ _) => attempt fuel ({ usage := .many } :: seed)
        | .error error => .error error
    attempt (body.length + 1) []

  partial def eraseItems (env : EffectEnv) (items : List Item) (state : State) (visible : List String) : Except ErasureError (KernelProgram × State) :=
    match items with
    | [] => .ok ([], state)
    | item :: rest =>
      eraseItem env item state visible >>= fun (head, next) =>
        eraseItems env rest next visible |>.map (fun (tail, final) => (head ++ tail, final))

  partial def eraseItem (env : EffectEnv) (item : Item) (state : State) (visible : List String) : Except ErasureError (KernelProgram × State) :=
    let span := match item with
      | .literal _ s | .word _ s | .atom _ s | .primitive _ s | .quotation _ s | .locals _ _ s => s
    match item with
    | .literal literal _ => match literalAtom literal.value with
      | some value => .ok (atomList (.lit value) span, { state with stack := { usage := .many } :: state.stack })
      | none => .error (.unsupportedLiteral span)
    | .word name _ => match env.word name with
        | some signature => applySignature name span signature state |>.map (fun next => (atomList (.word name) span, next))
        | none => .error (.unresolvedEffect name span)
    | .primitive name _ => match env.primitive name with
      | some signature => applySignature name span signature state |>.map (fun next => (atomList (.prim name) span, next))
      | none => .error (.unresolvedEffect name span)
    | .atom name _ => match name with
      | "swap" => match state.stack with | a :: b :: rest => .ok (atomList .swap span, { state with stack := b :: a :: rest }) | _ => .error (.effectUnderflow name span)
      | "dup" => match state.stack with | a :: rest => if a.usage == .many then .ok (atomList .dup span, { state with stack := a :: a :: rest }) else .error (.linearCopy name span) | _ => .error (.effectUnderflow name span)
      | "drop" => match state.stack with
        | a :: rest => if a.usage == .many then .ok (atomList .drop span, { state with stack := rest })
          else match a.slot with
            | some slot => .error (.linearUnused slot.name span)
            | none => .error (.linearCopy name span)
        | _ => .error (.effectUnderflow name span)
      | "quote" => match state.stack with | a :: rest => .ok (atomList .quote span, { state with stack := { usage := a.usage } :: rest }) | _ => .error (.effectUnderflow name span)
      | "call" => .ok (atomList .call span, state)
      | "compose" => .ok (atomList .compose span, state)
      | "if" => .ok (atomList .ifThenElse span, state)
      | "dip" => .error (.unsupportedAtom name span)
      | _ => .error (.unsupportedAtom name span)
    | .quotation body _ => match captureIn visible body with
      | some (name, localSpan) => .error (.unsupportedCapture name localSpan)
      | none => eraseQuotation env body visible span |>.map (fun program =>
          ([locatedQuotation span program], { state with stack := { usage := .many } :: state.stack }))
    | .locals names body _ => match duplicateName names with
      | some duplicate => .error (.duplicateLocal duplicate.name duplicate.span)
      | none => localStack names state >>= fun (entered, slots) =>
          eraseLocalBody env body entered slots (names.map (·.name) ++ visible)

  partial def eraseLocalBody (env : EffectEnv) (items : List Item) (state : State)
      (slots : List Slot) (visible : List String) : Except ErasureError (KernelProgram × State) :=
    match items with
    | [] => cleanup slots state >>= fun (program, cleaned) =>
        .ok (program, { cleaned with stack := restoreParents slots cleaned.stack })
    | item :: rest => match item with
      | .word name localSpan =>
        if slots.any (fun slot => slot.name == name) || visible.contains name then
          let count := demandCount name items
          match findSlot name localSpan state.stack with
          | .error error => .error error
          | .ok slot =>
            if slot.usage == .linear && count > 1 then
              let useSpan := match (demandSpans name items).drop 1 with
                | span :: _ => span
                | [] => localSpan
              .error (.linearCopy name useSpan)
            else
              focusAtoms slot.id localSpan state.stack >>= fun (focus, focused) =>
                let copiesNeeded := count - 1
                let fresh : List Slot := List.range (if slot.expanded then 0 else copiesNeeded) |>.map (fun index =>
                  Slot.mk (state.nextId + index) name slot.usage slot.origin none slot.family true true)
                let copied : List StackEntry := fresh.reverse.map (fun freshSlot => { slot := some freshSlot, usage := freshSlot.usage })
                let selected := (fresh.getLast?).map (·.id) |>.getD slot.id
                let expandedStack := markExpanded slot.id focused
                let nextState := { state with nextId := state.nextId + fresh.length }
                let nextState := { nextState with stack := markUnavailable selected (copied ++ expandedStack) }
                eraseLocalBody env rest nextState slots visible |>.map (fun (tail, final) =>
                  (focus ++ List.replicate fresh.length (located localSpan .dup) ++ tail, final))
        else match env.word name with
          | none => .error (.unboundLocal name localSpan)
          | some _ => eraseItem env item state visible >>= fun (head, next) =>
              eraseLocalBody env rest next slots visible |>.map (fun (tail, final) => (head ++ tail, final))
      | _ => eraseItem env item state visible >>= fun (head, next) =>
          eraseLocalBody env rest next slots visible |>.map (fun (tail, final) => (head ++ tail, final))
end

def erase (env : EffectEnv) (effect : StackEffect) (body : List Item) : Except ErasureError ErasureResult :=
  eraseItems env body (initialState effect) [] |>.map (fun (program, _) =>
    { program,
      warnings := (if body.any (fun item => match item with | .locals names _ _ => names.length > 4 | _ => false)
        then [{ code := "LOCAL_DEPTH", span := effect.span }] else []) ++
        (if longestStructuralRun program > 4 then [{ code := "STACK_JUGGLE", span := effect.span }] else []) })

theorem erase_deterministic (env : EffectEnv) (effect : StackEffect) (body : List Item)
    {first second : ErasureResult}
    (first_run : erase env effect body = .ok first)
    (second_run : erase env effect body = .ok second) :
    first = second := by
  have same : (Except.ok first : Except ErasureError ErasureResult) = .ok second :=
    first_run.symm.trans second_run
  injection same

end Firth.Elaborator
