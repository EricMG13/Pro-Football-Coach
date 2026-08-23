"""One loop over the registry. No per-surface branch lives here or anywhere else --
if a surface needs special rendering it declares a `Custom`, and check 13 caps how
many may do that before the primitives have rotted back into per-surface renderers.
"""

from __future__ import annotations

import chrome
from registry import REGISTRY
from surface import Surface


def render_surface(s: Surface) -> str:
    return chrome.frame(s, s.body.render())


def render_all() -> list[tuple[Surface, str]]:
    return [(s, render_surface(s)) for s in REGISTRY]
