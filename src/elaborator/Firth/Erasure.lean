import elaborator.Firth.Parser
import Firth.Interpreter

namespace Firth.Elaborator

open Firth.Interpreter

structure LocatedKernel where
  span : Span
  atom : Atom
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
  available : Bool := true
  declared : Bool := false
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

private def atomList (atom : Atom) (span : Span) : KernelProgram := [located span atom]

private def countName (name : String) : List Item → Nat
  | [] => 0
  | .word n _ :: xs => (if n == name then 1 else 0) + countName name xs
  | _ :: xs => countName name xs

private def hasDeepLocal : List Item → Bool
  | [] => false
  | .locals names body _ :: xs => names.length > 4 || hasDeepLocal body || hasDeepLocal xs
  | .quotation body _ :: xs => hasDeepLocal body || hasDeepLocal xs
  | _ :: xs => hasDeepLocal xs

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
  | x :: xs => if xs.any (fun y => y.name == x.name) then some x else duplicateName xs

private def findSlot (name : String) (stack : List StackEntry) : Option Slot :=
  match stack with
  | [] => none
  | x :: xs => match x.slot with
    | some slot => if slot.name == name && slot.available then some slot else findSlot name xs
    | none => findSlot name xs

private def hasNamedSlot (name : String) : List StackEntry → Bool
  | [] => false
  | x :: xs => match x.slot with
    | some slot => slot.name == name || hasNamedSlot name xs
    | none => hasNamedSlot name xs

private def findSlotId (id : Nat) : List StackEntry → Option Slot
  | [] => none
  | x :: xs => match x.slot with
    | some slot => if slot.id == id then some slot else findSlotId id xs
    | none => findSlotId id xs

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

private def focusAtoms (id : Nat) (span : Span) (stack : List StackEntry) : Except ErasureError (KernelProgram × List StackEntry) :=
  let expand (p : KernelProgram) : KernelProgram :=
    if p.isEmpty then atomList .swap span
    else p ++ atomList (.quotation (toProgram p)) span ++ atomList .dip span ++ atomList .swap span
  let rec go : List StackEntry → Except ErasureError (KernelProgram × List StackEntry)
    | [] => .error (.missingStackValue span)
    | x :: xs => match x.slot with
      | some slot => if slot.id == id then .ok ([], x :: xs)
        else go xs |>.map (fun (p, focused) => match focused with
          | target :: rest =>
            (expand p, target :: x :: rest)
          | [] => (p, x :: xs))
      | none => go xs |>.map (fun (p, focused) => match focused with
          | target :: rest =>
            (expand p, target :: x :: rest)
          | [] => (p, x :: xs))
  go stack |>.map (fun (p, focused) => (p, focused))

private def literalAtom : Firth.Elaborator.Literal → Option Firth.Interpreter.Literal
  | .integer value => if value < 0 then none else some (.nat value.toNat)
  | .boolean value => some (.bool value)
  | _ => none

private def applySignature (name : String) (span : Span) (signature : Signature) (state : State) : Except ErasureError State :=
  if state.stack.length < signature.input.length then .error (.effectUnderflow name span)
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
      ({ id := 0, name := name.name, usage := entry.usage, declared := true } : Slot))
    let slots := slots.zip (List.range slots.length) |>.map (fun (slot, index) => { slot with id := state.nextId + index })
    let replaced := (slots.reverse.map (fun slot => { slot := some slot, usage := slot.usage })) ++ state.stack.drop names.length
    .ok ({ stack := replaced, nextId := state.nextId + names.length }, slots)

private def cleanup (slots : List Slot) (span : Span) (state : State) : Except ErasureError (KernelProgram × State) :=
  let rec loop (fuel : Nat) (current : State) (out : KernelProgram) : Except ErasureError (KernelProgram × State) :=
    match fuel with
    | 0 => .ok (out, current)
    | fuel + 1 =>
      let candidates := current.stack.filterMap (fun entry => match entry.slot with
        | some slot => if slots.any (fun declared => declared.id == slot.id) && slot.available then some slot else none
        | none => none)
      match candidates with
      | [] => .ok (out, current)
      | candidate :: _ =>
        if candidate.usage == .linear then .error (.linearUnused candidate.name span) else
        match focusAtoms candidate.id span current.stack with
        | .error e => .error e
        | .ok (focus, focused) =>
          let after := focused.drop 1
          loop fuel { current with stack := after } (out ++ focus ++ atomList .drop span)
  loop (state.stack.length + 1) state []

mutual
  partial def eraseItems (env : EffectEnv) (items : List Item) (state : State) : Except ErasureError (KernelProgram × State) :=
    match items with
    | [] => .ok ([], state)
    | item :: rest =>
      eraseItem env item state >>= fun (head, next) => eraseItems env rest next |>.map (fun (tail, final) => (head ++ tail, final))

  partial def eraseItem (env : EffectEnv) (item : Item) (state : State) : Except ErasureError (KernelProgram × State) :=
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
      | "drop" => match state.stack with | _ :: rest => .ok (atomList .drop span, { state with stack := rest }) | _ => .error (.effectUnderflow name span)
      | "quote" => match state.stack with | a :: rest => .ok (atomList .quote span, { state with stack := { usage := a.usage } :: rest }) | _ => .error (.effectUnderflow name span)
      | "call" => .ok (atomList .call span, state)
      | "compose" => .ok (atomList .compose span, state)
      | "if" => .ok (atomList .ifThenElse span, state)
      | "dip" => .error (.unsupportedAtom name span)
      | _ => .error (.unsupportedAtom name span)
    | .quotation body _ =>
      match body.find? (fun item => match item with | .word name _ => hasNamedSlot name state.stack | _ => false) with
      | some (.word name localSpan) => .error (.unsupportedCapture name localSpan)
      | _ => eraseItems env body { stack := [] } |>.map (fun (program, _) =>
          (atomList (.quotation (toProgram program)) span, { state with stack := { usage := .many } :: state.stack }))
    | .locals names body _ =>
      match duplicateName names with
      | some duplicate => .error (.duplicateLocal duplicate.name duplicate.span)
      | none =>
        localStack names state >>= fun (entered, slots) =>
          eraseLocalBody env body entered slots span

  partial def eraseLocalBody (env : EffectEnv) (items : List Item) (state : State) (slots : List Slot) (scopeSpan : Span) : Except ErasureError (KernelProgram × State) :=
    match items with
    | [] => cleanup slots scopeSpan state
    | item :: rest =>
      match item with
      | .word name localSpan =>
        if slots.any (fun slot => slot.name == name) then
          let count := countName name items
          match findSlot name state.stack with
          | none => .error (.unboundLocal name localSpan)
          | some slot => focusAtoms slot.id localSpan state.stack >>= fun (focus, focused) =>
              if slot.usage == .linear && count > 1 then .error (.linearCopy name localSpan)
              else
                let copiesNeeded := if slot.expanded then 0 else count - 1
                let fresh := List.range copiesNeeded |>.map (fun index =>
                  { id := state.nextId + index, name, usage := slot.usage, available := true, expanded := true })
                let copied := fresh.map (fun freshSlot => { slot := some freshSlot, usage := freshSlot.usage })
                let focused := markExpanded slot.id focused
                let selected := if copiesNeeded > 0 then fresh.getLast? else some slot
                let selectedId := selected.map (·.id) |>.getD slot.id
                let next : State := { state with nextId := state.nextId + fresh.length, stack := markUnavailable selectedId (copied ++ focused) }
                eraseLocalBody env rest next slots scopeSpan |>.map (fun (tail, final) => (focus ++ List.replicate copiesNeeded (located localSpan .dup) ++ tail, final))
        else match env.word name with
          | none => .error (.unboundLocal name localSpan)
          | some _ => eraseItem env item state >>= fun (head, next) => eraseLocalBody env rest next slots scopeSpan |>.map (fun (tail, final) => (head ++ tail, final))
      | _ => eraseItem env item state >>= fun (head, next) => eraseLocalBody env rest next slots scopeSpan |>.map (fun (tail, final) => (head ++ tail, final))

end

def erase (env : EffectEnv) (effect : StackEffect) (body : List Item) : Except ErasureError ErasureResult :=
  eraseItems env body (initialState effect) |>.map (fun (program, _) =>
    { program,
      warnings := (if hasDeepLocal body then [{ code := "LOCAL_DEPTH", span := effect.span }] else []) ++
        (if longestStructuralRun program > 4 then [{ code := "STACK_JUGGLE", span := effect.span }] else []) })

theorem erase_deterministic (env : EffectEnv) (effect : StackEffect) (body : List Item) :
    erase env effect body = erase env effect body := rfl

end Firth.Elaborator
