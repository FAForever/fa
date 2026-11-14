import unittest

from changelog_markdown2lua import markdown2lua


class Markdown2LuaTests(unittest.TestCase):
    def convert(self, markdown):
        content = "---\ntitle: 3837 - Hotfix\n---\n\n" + markdown
        return markdown2lua("3837", content)

    def test_standalone_unit_tags_preserve_unit_details(self):
        result = self.convert(
            "{% unit URL0303 %}\n"
            "Loyalist: T3 Siege Assault Bot\n"
            "{% endunit %}\n"
            "Reduce stun duration.\n\n"
            "- Stun duration: 1.5 -> 0.4\n"
        )

        self.assertNotIn("{%", result)
        self.assertIn('"Loyalist: T3 Siege Assault Bot"', result)
        self.assertIn('"Reduce stun duration."', result)
        self.assertIn('"- Stun duration: 1.5 -> 0.4"', result)

    def test_inline_unit_tags_at_end_preserve_surrounding_text(self):
        result = self.convert("Unit: {% unit URL0303 %}Loyalist{% endunit %}")

        self.assertNotIn("{%", result)
        self.assertIn('"Unit: Loyalist"', result)

    def test_multiline_unit_tags_preserve_unit_name(self):
        result = self.convert(
            "{% unit\n"
            "    URL0303\n"
            "%}\n"
            "Loyalist\n"
            "{% endunit %}"
        )

        self.assertNotIn("{%", result)
        self.assertNotIn("%}", result)
        self.assertIn('"Loyalist"', result)


if __name__ == "__main__":
    unittest.main()
