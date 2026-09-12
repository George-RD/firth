#!/usr/bin/env python3
"""Guard the independent attack corpus and fail-closed result classification."""
import copy
import unittest

import check_compiler_admission as checks


class CompilerAdmissionGateTests(unittest.TestCase):
    def test_fixed_attack_floor_and_unique_names(self):
        cases = checks.corpus()
        self.assertGreaterEqual(len(cases), 40)
        self.assertEqual(len({name for name, _, _ in cases}), len(cases))
        attacks = [case for case in cases if case[0].startswith("kernel:") and case[2] == "reject"]
        self.assertEqual(len(attacks), 15)
        self.assertTrue(all(payload["checked_words"][0]["checking_state"] == "checked"
                            for _, payload, _ in attacks))

    def test_refusal_requires_structured_error_and_no_target(self):
        payload = checks.request([])
        for response, rc in (({"status": "success"}, 0), ({"status": "failure"}, 0),
            ({"status": "error", "error": "bad"}, 0), ({"status": "error", "error": "bad"}, 2),
            ({"status": "error", "error": "bad", "target_program": {}}, 1)):
            self.assertFalse(checks.evaluate("reject", rc, response, payload))
        self.assertTrue(checks.evaluate("reject", 0, {"status": "failure", "compile_error": {"code": "x"}}, payload))
        self.assertTrue(checks.evaluate("reject", 1, {"status": "error", "error": "bad"}, payload))

    def test_success_without_scope_metadata_is_not_evidence(self):
        self.assertFalse(checks.evaluate("kernel-success", 0,
            {"status": "success", "target_program": {}}, checks.request([checks.literal(42)])))

    def test_baseline_is_an_explicit_reproduction_not_normal_acceptance(self):
        response = {"status": "success", "target_program": {}}
        self.assertTrue(checks.evaluate("baseline-acceptance", 0, response, checks.request([])))
        self.assertFalse(checks.evaluate("reject", 0, response, checks.request([])))

    def test_source_attack_is_same_type_not_just_type_invalid(self):
        cases = {name: payload for name, payload, _ in checks.corpus()}
        original = cases["source: literal with unopened path"]
        attack = cases["source: same-type body substitution"]
        self.assertEqual(original["erased_word_types"], attack["erased_word_types"])
        self.assertEqual(original["source"], attack["source"])
        self.assertNotEqual(original["checked_words"], attack["checked_words"])
        coherent = cases["source: consistent new input"]
        self.assertEqual(coherent["checked_words"], attack["checked_words"])
        self.assertNotEqual(coherent["source"], attack["source"])

    def test_cases_are_not_shared_mutable_payloads(self):
        cases = checks.corpus()
        saved = copy.deepcopy(cases)
        cases[0][1]["checked_words"].clear()
        self.assertEqual(cases[1:], saved[1:])
        self.assertEqual(checks.corpus(), saved)


if __name__ == "__main__":
    unittest.main()
