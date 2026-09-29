"""End-to-end builder tests: generate scripts from representative option sets, validate output."""
import os
import re
import subprocess
import sys
import unittest

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

from scripts.builder import build_full_script, check_dependencies  # noqa: E402
from utils.helpers import load_nattd  # noqa: E402

TEMPLATE_PATH = os.path.join(REPO, "template.sh")

def build(options, mode="Verbose"):
    template = open(TEMPLATE_PATH).read()
    return build_full_script(template, options, mode)

class TestBuilderBasics(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.nattd = load_nattd()

    def test_empty_options_produce_valid_script(self):
        script = build({"system_config": {}, "additional_apps": {}, "customization": {}})
        r = subprocess.run(["bash", "-n", "/dev/stdin"], input=script, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, f"bash -n failed: {r.stderr}")

    def test_full_kitchen_sink_verbose(self):
        options = {
            "system_config": {
                "set_hostname": True,
                "enable_multimedia_repos": True,
                "install_multimedia_codecs": True,
                "install_intel_codecs": True,
                "install_amd_codecs": True,
            },
            "additional_apps": {
                "development_tools": {"install_docker": {"selected": True}},
                "internet_communication": {"install_firefox": {"selected": True}},
            },
            "customization": {
                "install_microsoft_fonts": {"selected": True, "installation_type": "windows"},
            },
            "custom_script": "echo hi",
            "hostname": "test-box",
        }
        script = build(options, "Verbose")
        r = subprocess.run(["bash", "-n", "/dev/stdin"], input=script, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, f"bash -n failed: {r.stderr}")
        self.assertIn("hostnamectl set-hostname test-box", script)
        self.assertIn("apt-get install -y ffmpeg", script)
        self.assertIn("libavcodec-extra", script)
        self.assertNotIn("ubuntu-restricted-extras", script)
        self.assertNotIn("mktr.sbs", script)
        self.assertIn("download.docker.com/linux/debian", script)
        self.assertIn("flatpak install -y flathub org.mozilla.firefox", script)
        self.assertIn("win-fonts.zip", script)
        # the destructive Docker config removal must stay gone
        self.assertNotIn("rm -rf $ACTUAL_HOME/.docker", script)

    def test_quiet_mode_control_flow_not_redirected(self):
        options = {
            "system_config": {"set_hostname": True},
            "additional_apps": {"development_tools": {"install_docker": {"selected": True}}},
        }
        script = build(options, "Quiet")
        for line in script.splitlines():
            stripped = line.strip()
            if re.match(r"^(fi|else|then|elif)\b", stripped):
                self.assertFalse(stripped.endswith("> /dev/null 2>&1"),
                                 f"control-flow line redirected in Quiet mode: {stripped}")

    def test_codec_selection_enables_multimedia_repos(self):
        options = {"system_config": {"install_multimedia_codecs": True}}
        updated = check_dependencies(options)
        self.assertTrue(updated["system_config"].get("enable_multimedia_repos"))
        # the phantom legacy key must stay gone
        self.assertNotIn("enable_nonfree_repos", updated["system_config"])

    def test_flatpak_app_enables_flathub_repo_replacement(self):
        options = {"additional_apps": {
            "internet_communication": {"install_firefox": {"selected": True}}}}
        updated = check_dependencies(options)
        self.assertTrue(updated["system_config"].get("remove_debian_flatpak_repos"))

    def test_placeholders_replaced(self):
        script = build({"system_config": {}})
        self.assertNotIn("{{", script)
        self.assertNotIn("{hostname}", script)


if __name__ == "__main__":
    unittest.main()