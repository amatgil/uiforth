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
#   internally defined primitives through the RunPrimitive function.
# - The second is the "userdefs dict", is implemented as a uiua `map`
#   from word to list of integers. These integers are indices to other words,
#   their sign indicating whether they refer to a primitive (negative)
#   or to another userdef (positive).

# - Numbers: Since uiua works internally in just floats, I'm going to
#            simplify the system substantially by making the call that
#            all numbers are f64s. This removes an entire stack, a
#            whole suite of domain-specific functions and a lot of
#            special casing
#
# - Strings handling: mask out strings before pbbn. Take into account
#           backslashes mask _those_ out with `find $ \"`

┌─╴Word
  |N {Num: °0type}    # number (f64)
  |W {Word: °1type}   # identifier for word
  |S {String: °1type} # quoted string
└─╴
┌─╴Val
  |N {Num: °0type}    # number (f64)
  |S {String: °1type} # string
└─╴

# Stack ? Word Stack
RunPrimitive ← |2 ⍣(
  ⍩(⊂Val~N) °(Word~N)
| ⍩(⊂ ⍜∩°Val~N+ °⊟ ⊃↙↘2) °(Word~W"+") # Primitive nº 0
| ⍩(⊂ ⍜∩°Val~N- °⊟ ⊃↙↘2) °(Word~W"-") # Primitive nº 1
| ⍩(⊂ ⍜∩°Val~N× °⊟ ⊃↙↘2) °(Word~W"*") # etc.
| ⍩(⊂ ⍜∩°Val~N÷ °⊟ ⊃↙↘2) °(Word~W"/")
| ⍩(⊂⊂. ⊃↙↘1) °(Word~W"dup")
| ⍩(⊂↻₁ ⊃↙↘3) °(Word~W"rot")
| ⍩(⊂↻₋₁ ⊃↙↘3) °(Word~W"-rot")
  # | ⍩(⨬(id| ⍢(↘__1|  ) ) ≍1 °(Word~N) ) °(Word~W"if")
| ⍩(&p ⍣(°Val~N|°Val~S) ⊃⊢↘₁) °(Word~W"print")
| ⍤$"Cannot run string: _" ⊙0 °(Word~S)
| ⍤$"Unrecognized word: _" ⊙0 °(Word~W))

BuiltIns ← {Word!(W"+" W"-" W"*" W"/" W"dup" W"rot" W"-rot" W"print")}

# Userdefs Stack ? Word Userdefs Stack
EvalWord ← |3.2 (
  ⍣(?⊸get °Word~W # Run userdef
    ⍩(∧(⨬(𝄐⌞RunPrimitive?°□˜⊏BuiltIns|◇EvalWord?)>₀⊃±⌵ ?)?)
  | 𝄐⌞RunPrimitive)
)
# Userdefs Stack ? Words Userdefs Stack
Eval ← ⋅◌⍢(⊙+₁ ⊃(⋅⋅⊙⊙|⊙⊙⋅⋅) EvalWord ⊃(⊙⋅⋅⊙⊙|⋅⊙⊙⋅⋅) ◡˜⊡|<⧻) ⊙0

# Words ? Input
Parse ← ⊜(⍣(Word~N ⋕|Word~W))¬⊸∊" \n" # TODO: Parse strings

EmptyStack ← ↯0_2 []

# Eval Parse "10 12 + 100 +" [] EmptyStack
# Eval Parse "10 dup dup dup print" [] EmptyStack
# : SQUARE dup * ;

Eval ? Parse "3 2 SQUARE" map {"SQUARE"} [[¯4 ¯2]] EmptyStack
# Eval [Word!(N 10 N 12 W "+" N 100 W "+")] [] EmptyStack
