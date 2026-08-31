# Pagy::DEFAULT is frozen as of v43 — Pagy::OPTIONS (merged into every #pagy
# call, see Pagy::Method) is the mutable app-wide default now.
Pagy::OPTIONS[:limit] = 20

# Total page-number slots shown by @pagy.series_nav (first/last page + gaps
# + pages around current, all counted together — see Pagy::SERIES_SLOTS).
# Set explicitly, at the gem's own default, so it's a one-line change if a
# view ever needs a longer or shorter page series.
Pagy::OPTIONS[:slots] = 7
