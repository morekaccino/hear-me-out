#!/usr/bin/env python3
"""Tests for the T6.2 finance model. Stdlib only; run from the repo root:

    python tool/finance/test_model.py
"""

from __future__ import annotations

import contextlib
import io
import json
import subprocess
import sys
import unittest
from pathlib import Path

import model


class AssumptionTests(unittest.TestCase):
    def test_net_per_annual_pro(self) -> None:
        self.assertAlmostEqual(model.NET_PER_ANNUAL_PRO, 55.7175, places=4)

    def test_retention_arithmetic(self) -> None:
        # The ticket's correction: 50% of 713 is 356.5, not a 300-600 range.
        self.assertEqual(model.round_half_up(713 * 0.50), 357)
        self.assertEqual(1_200 + 357, 1_557)
        self.assertEqual(model.round_half_up(225 * 0.50), 113)
        self.assertEqual(600 + 113, 713)

    def test_monthly_churn_equivalents(self) -> None:
        self.assertAlmostEqual(model.monthly_churn_from_annual(0.50), 0.05613, places=5)
        self.assertAlmostEqual(model.monthly_churn_from_annual(0.40), 0.073515, places=4)
        # The plan's old ~4.2%/month would imply ~60% annual retention, not 50%.
        self.assertGreater((1 - 0.042) ** 12, 0.59)


class AnnualTableTests(unittest.TestCase):
    def setUp(self) -> None:
        self.base_rows = model.schedule(model.BASE)
        self.base_years = model.annual_summary(self.base_rows)
        self.down_rows = model.schedule(model.DOWNSIDE)
        self.down_years = model.annual_summary(self.down_rows)

    def test_base_pro_counts(self) -> None:
        self.assertEqual([row["new_pro"] for row in self.base_years], [225.0, 600.0, 1200.0])
        self.assertEqual(
            [round(row["end_active_pro"], 2) for row in self.base_years],
            [225.0, 712.5, 1556.25],
        )

    def test_downside_pro_counts(self) -> None:
        self.assertEqual([row["new_pro"] for row in self.down_years], [150.0, 400.0, 800.0])
        self.assertEqual(
            [round(row["end_active_pro"], 2) for row in self.down_years],
            [150.0, 460.0, 984.0],
        )

    def test_content_calendar_reconciliation(self) -> None:
        content = [row["content"] for row in self.base_years]
        self.assertAlmostEqual(content[0], 69_024.0, places=2)
        self.assertAlmostEqual(content[1], 34_190.0, places=2)
        self.assertAlmostEqual(content[2], 23_940.0, places=2)
        self.assertAlmostEqual(content[0] + content[1], 103_214.0, places=2)
        self.assertAlmostEqual(sum(content), 127_154.0, places=2)

        # The month-0 launch inventory plus months 1-24 must equal T3.9.
        self.assertAlmostEqual(model.content_cost(0), 19_800.0, places=2)
        two_year_content = model.content_cost(0) + sum(
            model.content_cost(month) for month in range(1, 25)
        )
        self.assertAlmostEqual(two_year_content, 103_214.0, places=2)

    def test_content_low_and_high_cases(self) -> None:
        low = model.annual_summary(model.schedule(model.replace(model.BASE, content_case="low")))
        high = model.annual_summary(model.schedule(model.replace(model.BASE, content_case="high")))
        self.assertEqual([round(row["content"]) for row in low], [33_720, 17_260, 11_760])
        self.assertEqual([round(row["content"]) for row in high], [104_268, 51_060, 36_060])
        self.assertEqual(round(low[0]["content"] + low[1]["content"]), 50_980)
        self.assertEqual(round(high[0]["content"] + high[1]["content"]), 155_328)

    def test_content_range_moves_cash_need(self) -> None:
        low = model.content_case_summary("low")
        base = model.content_case_summary("base")
        high = model.content_case_summary("high")
        self.assertAlmostEqual(float(low["cash_need"]), 67_745.0, delta=1.0)
        self.assertAlmostEqual(float(base["cash_need"]), 119_979.0, delta=1.0)
        self.assertAlmostEqual(float(high["cash_need"]), 175_442.0, delta=1.0)
        self.assertEqual(low["trough_month"], 24)
        self.assertEqual(base["trough_month"], 24)
        self.assertEqual(high["trough_month"], 36)

    def test_base_cash_flow(self) -> None:
        low, month = model.trough(self.base_rows)
        self.assertAlmostEqual(low, -119_979.0, delta=1.0)
        self.assertEqual(month, 24)
        self.assertAlmostEqual(self.base_years[0]["profit"], -86_488.0, delta=1.0)
        self.assertAlmostEqual(self.base_years[1]["profit"], -33_491.0, delta=1.0)
        self.assertAlmostEqual(self.base_years[2]["profit"], 8_770.0, delta=1.0)
        self.assertAlmostEqual(self.base_years[2]["cumulative_cash"], -111_208.0, delta=1.0)

    def test_downside_cash_flow(self) -> None:
        low, month = model.trough(self.down_rows)
        self.assertAlmostEqual(low, -161_340.0, delta=1.0)
        self.assertEqual(month, 36)
        self.assertAlmostEqual(self.down_years[0]["profit"], -90_666.0, delta=1.0)
        self.assertAlmostEqual(self.down_years[1]["profit"], -47_560.0, delta=1.0)
        self.assertAlmostEqual(self.down_years[2]["profit"], -23_114.0, delta=1.0)

    def test_recognized_revenue_is_a_memo_not_cash(self) -> None:
        # Annual plans are collected up front. Recognized revenue is lower in
        # the early years because each payment is earned over 12 months.
        self.assertLess(
            self.base_years[0]["recognized_revenue"],
            self.base_years[0]["net_billings"],
        )
        self.assertAlmostEqual(
            sum(row["recognized_revenue"] for row in self.base_years),
            99_203.0,
            delta=2.0,
        )


class BreakEvenTests(unittest.TestCase):
    def test_break_even_counts(self) -> None:
        self.assertAlmostEqual(model.break_even_pro(77_940.0), 1_398.8, delta=0.1)
        self.assertAlmostEqual(model.break_even_pro(114_000.0), 2_046.0, delta=0.1)
        self.assertAlmostEqual(model.break_even_pro(120_000.0), 2_153.7, delta=0.1)
        self.assertAlmostEqual(model.break_even_pro(139_293.75), 2_500.0, delta=0.1)

    def test_steady_state(self) -> None:
        self.assertAlmostEqual(model.steady_state_pro(model.BASE), 2_400.0, places=2)
        self.assertAlmostEqual(model.steady_state_pro(model.DOWNSIDE), 1_333.33, places=2)

    def test_2500_is_not_break_even_at_120k(self) -> None:
        net = 2_500 * model.NET_PER_ANNUAL_PRO
        self.assertAlmostEqual(net - 120_000.0, 19_293.75, delta=0.01)


class SensitivityTests(unittest.TestCase):
    def setUp(self) -> None:
        self.rows = {row["case"]: row for row in model.sensitivity()}

    def test_swing_ranking(self) -> None:
        def swing(low: str, high: str) -> float:
            return abs(float(self.rows[high]["cash_need"]) - float(self.rows[low]["cash_need"]))

        conversion = swing("4% conversion", "1% conversion")
        content = swing("content 75%", "content 125%")
        installs = swing("+25% installs", "-25% installs")
        renewal = swing("60% renewal", "30% renewal")
        self.assertGreater(conversion, content)
        self.assertGreater(content, installs)
        self.assertGreater(installs, renewal)

    def test_conversion_is_largest(self) -> None:
        ranked = sorted(
            self.rows.values(), key=lambda row: float(row["cash_need"]), reverse=True
        )
        self.assertEqual(ranked[0]["case"], "1% conversion")
        self.assertEqual(ranked[-1]["case"], "content 75%")

    def test_renewal_is_small_over_36_months(self) -> None:
        self.assertLess(
            abs(float(self.rows["30% renewal"]["cash_need"]) - float(self.rows["60% renewal"]["cash_need"])),
            5_000.0,
        )


class DeterminismTests(unittest.TestCase):
    def test_print_summary_is_deterministic(self) -> None:
        first = io.StringIO()
        second = io.StringIO()
        with contextlib.redirect_stdout(first):
            model.print_summary()
        with contextlib.redirect_stdout(second):
            model.print_summary()
        self.assertEqual(first.getvalue(), second.getvalue())

    def test_markdown_is_deterministic(self) -> None:
        self.assertEqual(model.markdown_tables(), model.markdown_tables())

    def test_cli_json_is_valid(self) -> None:
        script = Path(__file__).with_name("model.py")
        result = subprocess.run(
            [sys.executable, str(script), "--json"],
            check=True,
            capture_output=True,
            text=True,
        )
        payload = json.loads(result.stdout)
        self.assertEqual(payload["base"]["trough"][1], 24)
        self.assertEqual(payload["downside"]["trough"][1], 36)
        self.assertAlmostEqual(payload["assumptions"]["net_per_annual_pro"], 55.7175)
        self.assertIn("sensitivity", payload)
        self.assertIn("extension", payload["base"])


if __name__ == "__main__":
    unittest.main()
