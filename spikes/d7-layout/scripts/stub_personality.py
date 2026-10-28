#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""D7 spike (Task 1.1): the core is built with panic = abort, but the
precompiled std is not, so std's rust_eh_personality stays and pulls the
unwinder (_Unwind_*, libgcc_s) into every combination. Nothing unwinds under
panic = abort, so its body becomes abort(); `opt -passes=globaldce` then drops
what only it used.

Usage: stub_personality.py <in.ll> <out.ll>
"""
import re
import sys

src = open(sys.argv[1]).read()
pat = re.compile(r"^(define [^\n]*@rust_eh_personality\([^\n]*?)( personality ptr @rust_eh_personality)? \{\n.*?^\}\n",
                 re.S | re.M)
m = pat.search(src)
if not m:
    sys.exit("stub_personality: rust_eh_personality not found")
body = m.group(1) + " {\n  call void @abort()\n  unreachable\n}\n"
src = src[:m.start()] + body + src[m.end():]
if not re.search(r"^declare [^\n]*@abort\(", src, re.M) and not re.search(r"^define [^\n]*@abort\(", src, re.M):
    src += "\ndeclare void @abort()\n"
open(sys.argv[2], "w").write(src)
print("stub_personality: rust_eh_personality now aborts")
