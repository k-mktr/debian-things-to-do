"""Tests for the UX widgets module (select-all buttons, counters)."""
import os
import sys
import unittest

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

from ui.widgets import select_all_buttons, _visible_count  # noqa: E402


class _FakeStreamlit:
    """Minimal st stub: buttons always False, columns/captions recorded."""

    def __init__(self):
        self.captions = []

    class _Col:
        def __enter__(self):
            return self

        def __exit__(self, *a):
            return False

        def button(self, *a, **k):
            return False

    def columns(self, spec):
        return [_FakeStreamlit._Col() for _ in spec]

    def caption(self, text):
        self.captions.append(text)

    def button(self, *a, **k):
        return False

    def rerun(self):
        pass


class TestWidgets(unittest.TestCase):
    def test_visible_count(self):
        self.assertEqual(_visible_count(3, 10, "gimp"), 3)
        self.assertEqual(_visible_count(3, 10, ""), 10)

    def test_counter_states(self):
        fake = _FakeStreamlit()
        import ui.widgets as w
        orig = w.st
        try:
            w.st = fake
            w.selection_counter("essential", [("a", True), ("b", True)])
            self.assertEqual(len(fake.captions), 1)
            self.assertIn("2", fake.captions[0])
            fake2 = _FakeStreamlit()
            w.st = fake2
            w.selection_counter("essential", [("a", False), ("b", True), ("c", False)])
            self.assertIn("1", fake2.captions[0])
            fake3 = _FakeStreamlit()
            w.st = fake3
            w.selection_counter("essential", [("a", False), ("b", False)])
            self.assertIn("0", fake3.captions[0])
        finally:
            w.st = orig

    def test_select_all_no_items_noop(self):
        written = []
        select_all_buttons("k", [], [], "", lambda i, v: written.append((i, v)))
        self.assertEqual(written, [])

    def _run_with_clicked_button(self, items, visible, search, cb):
        import ui.widgets as w
        fake = _FakeStreamlit()

        def fake_button(label, **k):
            return str(k.get("key", "")).endswith("select_all")

        fake.button = fake_button
        orig = w.st
        try:
            w.st = fake
            select_all_buttons("k", items, visible, search, cb)
        finally:
            w.st = orig

    def test_select_all_targets_all_items_when_no_search(self):
        written = []
        items = [("a", False), ("b", False), ("c", False)]
        self._run_with_clicked_button(items, ["a"], "", lambda i, v: written.append((i, v)))
        self.assertEqual(sorted(written), [("a", True), ("b", True), ("c", True)])

    def test_select_all_targets_visible_only_when_searching(self):
        written = []
        items = [("a", False), ("b", False), ("c", False)]
        self._run_with_clicked_button(items, ["a"], "gimp", lambda i, v: written.append((i, v)))
        self.assertEqual(written, [("a", True)])


if __name__ == "__main__":
    unittest.main()
