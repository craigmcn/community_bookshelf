# Pagy::DEFAULT is frozen as of v43 — Pagy::OPTIONS (merged into every #pagy
# call, see Pagy::Method) is the mutable app-wide default now.
Pagy::OPTIONS[:limit] = 20
