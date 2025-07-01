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
#   internally defined primitives through the RunBuiltin function.
# - The second is the "userdefs dict", is implemented as a uiua `map`
#   from word to list of words

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
RunBuiltIn ← |2 ⍣(
  ⍩(⊂Val~N) °(Word~N)
| ⍩(⊂ ⍜∩°Val~N+ °⊟ ⊃↙↘2) °(Word~W"+")
| ⍩(⊂ ⍜∩°Val~N- °⊟ ⊃↙↘2) °(Word~W"-")
| ⍤$"Cannot run string: _" ⊙0 °(Word~S)
| ⍤$"Unrecognized word: _" ⊙0 °(Word~W))

# Dict Stack ? Word Dict Stack
EvalWord ← (
  ⍣(⊙◌|"whar") # this will be a lookup in the userdefs dict
  [] RunBuiltIn
)
# Dict Stack ? Words Dict Stack
# you might think 'this is a fold but worse' and you'd be right
# Eval ← ⍢(⊃(⋅⋅∘|⊙∘) ?EvalWord?⊃(⊙⋅⊙∘|⋅∘) ⊃⊢↘₁|±⧻)
Eval ← |3.2 ∧EvalWord ⊙¤

# Eval map[][] "+" [Val!(N 10 N 20)]

# Words ? Input
Parse ← ⊜(⍣(Word~N ⋕|Word~W))¬⊸∊" \n" # TODO: Parse strings

# Parse "1 2 + 3 +"
# Eval [] ⊃⊢↘₁
EmptyStack ← ↯0_2 []
Eval Parse "10 12 + 100 +" [] EmptyStack
# Eval [Word!(N 10 N 12 W "+" N 100 W "+")] [] EmptyStack
