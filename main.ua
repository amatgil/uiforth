# Experimental!
#         __            _   _
#  _   _ / _| ___  _ __| |_| |__
# | | | | |_ / _ \| '__| __| '_ \
# | |_| |  _| (_) | |  | |_| | | |
#  \__,_|_|  \___/|_|   \__|_| |_|
#
# Forth, in uiua!
#
# The core is _two_ dictionaries (le gasp!), which are implemented differently.
# - The first is the "internal dict", which maps words to
#   internally defined primitives through the RunPrim function.
# - The second is the "userdefs dict", is implemented as a uiua `map`
#   from word to list of integers. These integers are indices to other words,
#   their sign indicating whether they refer to a primitive (negative)
#   or to another userdef (positive).
#
# - Numbers: Since uiua works internally in just floats, I'm going to
#            simplify the system substantially by making the call that
#            all numbers are f64s. This removes an entire stack, a
#            whole suite of domain-specific functions and a lot of
#            special casing
#
# - Strings handling: mask out strings before pbbn. Take into account
#           backslashes mask _those_ out with `find $ \"`

┌─╴Word
  # Pre-evaluated
  |N {Num: °0type}    # number (f64)
  |W {Word: °1type}   # identifier for word
  |S {String: °1type} # quoted string
└─╴
┌─╴Val
  # Post-evaluated
  |N {Num: °0type}    # number (f64)
  |S {String: °1type} # string
└─╴

RunPrimGen! ←^ (
  ≡◇(⍜°□(▽¬⊸∊" \"") °⊟ ⊜□ ¬⊸⦷ "DEFINEDAS")
  ⊃($"BuiltIns = _" /◇⊂ ˜⊂"}" ∧(˜⊂$"\"_\" ") ⊙"{"
  | /◇⊂ ⍚˜$"| ⍩(_) °(Word~W\"_\")"
    ⊂"⍣(⍩(⊂Val~N) °(Word~N)"
    ˜⊂ $ | ⍤$"Cannot run string: _" ⊙0 °(Word~S)
    ˜⊂ $ | ⍤$"Unrecognized word: _" ⊙0 °(Word~W)
    ˜⊂")"
    $"RunPrim = _"
  )
  $"_\n_"
)

RunPrimGen!(
  "+" DEFINEDAS ⊂ ⍜∩°Val~N+ °⊟ ⊃↙↘2
| "-" DEFINEDAS ⊂ ⍜∩°Val~N- °⊟ ⊃↙↘2
| "*" DEFINEDAS ⊂ ⍜∩°Val~N× °⊟ ⊃↙↘2
| "/" DEFINEDAS ⊂ ⍜∩°Val~N÷ °⊟ ⊃↙↘2
| "dup" DEFINEDAS ⊂⊂. ⊃↙↘1
| "rot" DEFINEDAS ⊂↻₁ ⊃↙↘3
| "-rot" DEFINEDAS ⊂↻₋₁ ⊃↙↘3
| "print" DEFINEDAS &p ⍣(°Val~N|°Val~S) ⊃⊢↘₁)

# Userdefs Stack ? Word Userdefs Stack
EvalWord ← |3.2 (
  ⍣(⊸get °Word~W # Run userdef
    ⍩(∧(⨬(𝄐⌞RunPrim Word~W°□˜⊏BuiltIns|◇EvalWord)>₀⊃±⌵))
  | ⍩(𝄐⌞RunPrim))
)
# Userdefs Stack ? Words Userdefs Stack
Eval ← ⊙⊙⋅◌ ⍢(⊓EvalWord+₁ ◡⋅⋅⊡|⋅⋅(>⊙⧻)) ⤚⋅⊙⊙0

# TODO: Parse strings
Parse ← ⊜(⍣(Word~N ⋕|Word~W))¬⊸∊" \n" # Words ? Input

EmptyStack ← ↯0_2 []

Eval Parse "3 5 SQUARE +" map {"SQUARE"} [¯[⊗ □"dup" BuiltIns ⊗ □"*" BuiltIns]] EmptyStack
