#!/usr/bin/env python3
"""The inventory cases must run the image the allocator's proof records name.

`examples/inventory/run_cases.py` hands the allocator to the VM and, through
`check_image`, requires the image it ran to publish exactly the words, target
names and body digests that each target theorem in `src/proofs/records.json`
is about. These tests plant miscompiled images, each a change the VM and the
reference interpreter could agree on (the code of one word changed, two
words' code swapped, a word missing or added, another entry), and require each
to be refused. The last test runs `run_case` with the gate and the host
stubbed, so removing the call to `check_image` fails it. They need no Lean
toolchain.
"""
from __future__ import annotations

import copy
import json
import sys
import unittest
from pathlib import Path
from typing import Any
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "examples" / "inventory"))
import run_cases as host  # noqa: E402

RECORDS = json.loads(host.RECORDS.read_text(encoding="utf-8"))


def proved_observation() -> dict[str, Any]:
    """What `rebuild` reports for the image the first target theorem is about."""
    _, entry, words = host.proved_images(RECORDS)[0]
    return {"target_entry": entry,
            "image": [{"name": name, "body_digest": digest} for name, digest in words.items()]}


class CheckImageTest(unittest.TestCase):
    def assert_refused(self, observation: dict[str, Any], records: dict[str, Any] = RECORDS,
                       reason: str = "differs") -> None:
        problems = host.check_image(observation, records)
        self.assertTrue(problems, "a planted image was accepted")
        self.assertTrue(any(reason in problem for problem in problems), problems)

    def test_both_allocator_records_name_one_image(self) -> None:
        images = host.proved_images(RECORDS)
        self.assertEqual(sorted(theorem for theorem, _, _ in images), [
            "Firth.Proofs.Inventory.Target.allocate_batch_host_target",
            "Firth.Proofs.Inventory.Target.allocate_batch_target"])
        self.assertEqual(images[0][1:], images[1][1:])
        self.assertEqual(images[0][1], "allocate_hbatch")
        self.assertEqual(len(images[0][2]), 10)

    def test_the_proved_image_passes(self) -> None:
        self.assertEqual(host.check_image(proved_observation(), RECORDS), [])

    def test_a_word_compiled_to_other_code_is_refused(self) -> None:
        for index in range(len(proved_observation()["image"])):
            observation = proved_observation()
            word = observation["image"][index]
            word["body_digest"] = "0" * 64
            with self.subTest(word=word["name"]):
                self.assert_refused(observation, reason=word["name"])

    def test_two_words_with_swapped_code_are_refused(self) -> None:
        observation = proved_observation()
        first, second = observation["image"][0], observation["image"][1]
        first["body_digest"], second["body_digest"] = second["body_digest"], first["body_digest"]
        self.assert_refused(observation)

    def test_a_missing_or_extra_word_is_refused(self) -> None:
        observation = proved_observation()
        observation["image"].pop()
        self.assert_refused(observation)
        observation = proved_observation()
        observation["image"].append({"name": "extra", "body_digest": "1" * 64})
        self.assert_refused(observation)

    def test_a_name_published_twice_is_refused(self) -> None:
        observation = proved_observation()
        observation["image"].append(dict(observation["image"][0]))
        self.assert_refused(observation, reason="twice")

    def test_another_entry_is_refused(self) -> None:
        observation = proved_observation()
        observation["target_entry"] = "allocate_hone"
        self.assert_refused(observation, reason="entry")

    def test_records_without_a_target_refuse_every_image(self) -> None:
        records = copy.deepcopy(RECORDS)
        for record in records["records"]:
            record.pop("target", None)
            record.pop("target_theorem", None)
        self.assert_refused(proved_observation(), records, reason="names a target theorem")

    def test_a_record_that_lost_its_whole_target_is_refused(self) -> None:
        records = copy.deepcopy(RECORDS)
        lost = next(record for record in records["records"] if "target" in record)
        del lost["target"], lost["target_theorem"]
        self.assert_refused(proved_observation(), records, reason="expected")

    def test_a_record_that_lost_its_target_image_is_refused(self) -> None:
        records = copy.deepcopy(RECORDS)
        lost = next(record for record in records["records"] if "target" in record)
        del lost["target"]
        self.assert_refused(proved_observation(), records, reason="carries no target image")


class RunCaseTest(unittest.TestCase):
    """`run_case` with the toolchain stubbed: the VM's answer is right, so only
    the image check can fail the case."""

    def run_with(self, observation: dict[str, Any]) -> dict[str, Any]:
        case = next(case for case in json.loads(
            (ROOT / "specs" / "inventory-allocation-cases.json").read_text())["cases"]
            if isinstance(host.host_check(case["input"]), tuple))
        observation = {**observation, "stack": [], "kernel_cost": 0}
        with mock.patch.object(host, "host_decode", return_value=[0]), \
                mock.patch.object(host.gate, "rebuild", return_value=observation), \
                mock.patch.object(host, "host_encode", return_value=case["expected"]):
            return host.run_case(0, case)

    def test_run_case_passes_the_proved_image(self) -> None:
        self.assertEqual(self.run_with(proved_observation())["outcome"], "pass")

    def test_run_case_fails_a_miscompiled_image(self) -> None:
        observation = proved_observation()
        observation["image"][-1]["body_digest"] = "0" * 64
        result = self.run_with(observation)
        self.assertEqual(result["outcome"], "fail")
        self.assertIn("allocate_hbatch", result["detail"])

    def test_run_case_keeps_the_cost_detail(self) -> None:
        observation = proved_observation()
        observation["image"][-1]["body_digest"] = "0" * 64
        with mock.patch.object(host, "cost_bound", return_value=-1):
            result = self.run_with(observation)
        self.assertIn("over the bound", result["detail"])
        self.assertIn("allocate_hbatch", result["detail"])


if __name__ == "__main__":
    unittest.main()
