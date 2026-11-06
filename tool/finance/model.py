#!/usr/bin/env python3
"""Costed P&L and downside cash model for Hear Me Out (T6.2).

This is a planning tool, not a forecast. It is stdlib-only and has no
dependency on the Flutter app. Run it from the repository root:

    python tool/finance/model.py
    python tool/finance/model.py --json
    python tool/finance/model.py --markdown

The model is a monthly cohort model for annual Pro plans:

- installs are spread evenly through each year;
- a fixed share converts in the install month;
- each annual plan pays $69 up front and renews at each anniversary with the
  stated annual renewal probability;
- store fee (15%) and refunds/tax reserve (5%) are taken from every payment;
- content costs follow the T3.9 24-month calendar and extend month 25-36 at
  the month-21-24 run rate;
- non-content costs follow the plan's section 11.3 annual lines, spread
  monthly, with the one-time legal review booked in month 0.

Month 0 is launch preparation (launch content and the one-time legal review).
Year 1 is months 1-12. Month 36 is the end of Year 3.
"""

from __future__ import annotations

import argparse
import json
import math
from dataclasses import dataclass, replace


# ---------------------------------------------------------------------------
# Assumptions
# ---------------------------------------------------------------------------

MONTHS = 36
LAUNCH_PRICE = 69.00
STORE_FEE = 0.15
REFUND_TAX_RESERVE = 0.05
NET_PER_ANNUAL_PRO = LAUNCH_PRICE * (1.0 - STORE_FEE) * (1.0 - REFUND_TAX_RESERVE)

# T3.9 content calendar. Month 0 is the launch inventory.
# Months 1-6: 2 pieces + 8.67 etudes + 1 video + 1 etude take.
# Months 7-12: 3 pieces + 8.67 etudes + 1 video + 1 etude take.
# Months 13-20: 2 pieces + 4 etudes + 1 video + 1 etude take.
# Months 21-24: 1 piece + 4 etudes + 1 video + 1 etude take.
# Exam packs are one-time additions in months 13, 16, and 19.
# Month 25-36 is an extension at the month-21-24 run rate.
CONTENT_CASES = {
    "low": {
        "launch": 9600.0,
        "monthly": {
            **{month: 1760.0 for month in range(1, 7)},
            **{month: 2260.0 for month in range(7, 13)},
            **{month: 1480.0 for month in range(13, 21)},
            **{month: 980.0 for month in range(21, 25)},
        },
        "exam_packs": {13: 500.0, 16: 500.0, 19: 500.0},
        "year_3_monthly": 980.0,
    },
    "base": {
        "launch": 19800.0,
        "monthly": {
            **{month: 3602.0 for month in range(1, 7)},
            **{month: 4602.0 for month in range(7, 13)},
            **{month: 2995.0 for month in range(13, 21)},
            **{month: 1995.0 for month in range(21, 25)},
        },
        "exam_packs": {13: 750.0, 16: 750.0, 19: 750.0},
        "year_3_monthly": 1995.0,
    },
    "high": {
        "launch": 30000.0,
        "monthly": {
            **{month: 5439.0 for month in range(1, 7)},
            **{month: 6939.0 for month in range(7, 13)},
            **{month: 4505.0 for month in range(13, 21)},
            **{month: 3005.0 for month in range(21, 25)},
        },
        "exam_packs": {13: 1000.0, 16: 1000.0, 19: 1000.0},
        "year_3_monthly": 3005.0,
    },
}

# Plan section 11.3 non-content lines. Founder salary is excluded.
NON_CONTENT_ANNUAL = {
    1: {
        "dsp_dev": 15000.0,
        "legal": 8000.0,
        "hosting_support": 2000.0,
        "marketing": 3000.0,
        "tools_ops": 2000.0,
    },
    2: {
        "dsp_dev": 20000.0,
        "legal": 3000.0,
        "hosting_support": 5000.0,
        "marketing": 8000.0,
        "tools_ops": 3000.0,
    },
    3: {
        "dsp_dev": 25000.0,
        "legal": 3000.0,
        "hosting_support": 10000.0,
        "marketing": 12000.0,
        "tools_ops": 4000.0,
    },
}

# The one-time T6.3 territory/legal review is the midpoint of the plan's
# $5-10k estimate. The rest of the Year 1 legal line is routine review.
ONE_TIME_LEGAL_REVIEW = 6000.0


@dataclass(frozen=True)
class Scenario:
    name: str
    installs: tuple[int, int, int]
    conversion: float
    annual_renewal: float
    content_case: str = "base"
    content_scale: float = 1.0


BASE = Scenario(
    name="base",
    installs=(7500, 20000, 40000),
    conversion=0.03,
    annual_renewal=0.50,
)

DOWNSIDE = Scenario(
    name="downside",
    installs=(7500, 20000, 40000),
    conversion=0.02,
    annual_renewal=0.40,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def round_half_up(value: float) -> int:
    """Round positive values the way the plan's tables do (356.5 -> 357)."""
    return int(math.floor(value + 0.5))


def months_in_year(year: int) -> range:
    start = (year - 1) * 12 + 1
    return range(start, start + 12)


def year_of(month: int) -> int:
    return (month - 1) // 12 + 1


def monthly_installs(scenario: Scenario, month: int) -> float:
    if month < 1:
        return 0.0
    year = year_of(month)
    if year > len(scenario.installs):
        return 0.0
    return scenario.installs[year - 1] / 12.0


def content_cost(month: int, content_case: str = "base", content_scale: float = 1.0) -> float:
    """T3.9 content cash cost for one month (low/base/high, then scaled)."""
    case = CONTENT_CASES[content_case]
    if month == 0:
        return case["launch"] * content_scale
    if 1 <= month <= 24:
        return (
            case["monthly"][month] + case["exam_packs"].get(month, 0.0)
        ) * content_scale
    if 25 <= month <= MONTHS:
        return case["year_3_monthly"] * content_scale
    return 0.0


def non_content_cost(month: int) -> dict[str, float]:
    """Non-content cash cost for one month, split by line."""
    if month == 0:
        return {
            "dsp_dev": 0.0,
            "legal": ONE_TIME_LEGAL_REVIEW,
            "hosting_support": 0.0,
            "marketing": 0.0,
            "tools_ops": 0.0,
        }
    year = year_of(month)
    if year > len(NON_CONTENT_ANNUAL):
        year = len(NON_CONTENT_ANNUAL)
    annual = NON_CONTENT_ANNUAL[year]
    if year == 1:
        # The one-time review is already booked in month 0.
        legal = (annual["legal"] - ONE_TIME_LEGAL_REVIEW) / 12.0
    else:
        legal = annual["legal"] / 12.0
    return {
        "dsp_dev": annual["dsp_dev"] / 12.0,
        "legal": legal,
        "hosting_support": annual["hosting_support"] / 12.0,
        "marketing": annual["marketing"] / 12.0,
        "tools_ops": annual["tools_ops"] / 12.0,
    }


def cohort_payments(scenario: Scenario) -> dict[int, list[float]]:
    """Return {month: [payment, ...]} where each payment is one expected renewal.

    A cohort of new Pro that starts in month c pays in months c, c+12, c+24,
    ... The expected number of paying subscribers in a renewal month is the
    cohort size multiplied by the renewal probability for each anniversary.
    """
    payments: dict[int, list[float]] = {month: [] for month in range(MONTHS + 1)}
    for cohort_month in range(1, MONTHS + 1):
        cohort_size = monthly_installs(scenario, cohort_month) * scenario.conversion
        if cohort_size <= 0:
            continue
        renewal_index = 0
        payment_month = cohort_month
        while payment_month <= MONTHS:
            expected = cohort_size * (scenario.annual_renewal ** renewal_index)
            if expected > 0:
                payments[payment_month].append(expected)
            renewal_index += 1
            payment_month += 12
    return payments


def recognized_revenue_by_month(scenario: Scenario) -> list[float]:
    """Net revenue recognized in each month, spreading each annual payment."""
    revenue = [0.0] * (MONTHS + 1)
    for cohort_month in range(1, MONTHS + 1):
        cohort_size = monthly_installs(scenario, cohort_month) * scenario.conversion
        if cohort_size <= 0:
            continue
        renewal_index = 0
        payment_month = cohort_month
        while payment_month <= MONTHS:
            expected = cohort_size * (scenario.annual_renewal ** renewal_index)
            monthly = expected * NET_PER_ANNUAL_PRO / 12.0
            for month in range(payment_month, min(payment_month + 12, MONTHS + 1)):
                revenue[month] += monthly
            renewal_index += 1
            payment_month += 12
    return revenue


def schedule(scenario: Scenario) -> list[dict[str, float]]:
    """Build the full month 0-36 schedule."""
    payments = cohort_payments(scenario)
    recognized = recognized_revenue_by_month(scenario)
    rows: list[dict[str, float]] = []
    active = 0.0
    cumulative = 0.0
    for month in range(0, MONTHS + 1):
        if month >= 1:
            # Active count is the expected number of subscribers who have paid
            # and not yet lapsed at this anniversary.
            active = sum(
                monthly_installs(scenario, cohort_month)
                * scenario.conversion
                * (scenario.annual_renewal ** ((month - cohort_month) // 12))
                for cohort_month in range(1, month + 1)
                if month >= cohort_month
            )
        new_pro = monthly_installs(scenario, month) * scenario.conversion
        paying = sum(payments[month])
        gross = paying * LAUNCH_PRICE
        net = paying * NET_PER_ANNUAL_PRO
        content = content_cost(
            month, scenario.content_case, scenario.content_scale
        )
        other = non_content_cost(month)
        other_total = sum(other.values())
        total_cost = content + other_total
        profit = net - total_cost
        cumulative += profit
        rows.append(
            {
                "month": month,
                "year": 0 if month == 0 else year_of(month),
                "installs": monthly_installs(scenario, month),
                "new_pro": new_pro,
                "active_pro": active,
                "paying_pro": paying,
                "gross_billings": gross,
                "net_billings": net,
                "recognized_revenue": recognized[month],
                "content": content,
                "dsp_dev": other["dsp_dev"],
                "legal": other["legal"],
                "hosting_support": other["hosting_support"],
                "marketing": other["marketing"],
                "tools_ops": other["tools_ops"],
                "other_costs": other_total,
                "total_costs": total_cost,
                "profit": profit,
                "cumulative_cash": cumulative,
            }
        )
    return rows


def annual_summary(rows: list[dict[str, float]]) -> list[dict[str, float]]:
    """Aggregate the monthly schedule into Years 1-3.

    Year 1 includes the month 0 launch spend so it can be compared with the
    plan's Year 1 content line. Year 2 and Year 3 contain only their months.
    """
    years: list[dict[str, float]] = []
    for year in (1, 2, 3):
        months = [0, *months_in_year(year)] if year == 1 else list(months_in_year(year))
        selected = [row for row in rows if row["month"] in months]
        total = {
            "year": year,
            "installs": sum(row["installs"] for row in selected),
            "new_pro": sum(row["new_pro"] for row in selected),
            "end_active_pro": max(row["active_pro"] for row in selected),
            "gross_billings": sum(row["gross_billings"] for row in selected),
            "net_billings": sum(row["net_billings"] for row in selected),
            "recognized_revenue": sum(row["recognized_revenue"] for row in selected),
            "content": sum(row["content"] for row in selected),
            "dsp_dev": sum(row["dsp_dev"] for row in selected),
            "legal": sum(row["legal"] for row in selected),
            "hosting_support": sum(row["hosting_support"] for row in selected),
            "marketing": sum(row["marketing"] for row in selected),
            "tools_ops": sum(row["tools_ops"] for row in selected),
            "other_costs": sum(row["other_costs"] for row in selected),
            "total_costs": sum(row["total_costs"] for row in selected),
            "profit": sum(row["profit"] for row in selected),
        }
        total["cumulative_cash"] = cumulative_at(rows, year * 12)
        years.append(total)
    return years


def cumulative_at(rows: list[dict[str, float]], month: int) -> float:
    for row in rows:
        if row["month"] == month:
            return row["cumulative_cash"]
    raise ValueError(f"month {month} is outside the schedule")


def trough(rows: list[dict[str, float]]) -> tuple[float, int]:
    """Return (lowest cumulative cash, first month it happens)."""
    lowest = 0.0
    lowest_month = 0
    for row in rows:
        if row["cumulative_cash"] < lowest:
            lowest = row["cumulative_cash"]
            lowest_month = int(row["month"])
    return lowest, lowest_month


def break_even_pro(annual_cost: float) -> float:
    return annual_cost / NET_PER_ANNUAL_PRO


def steady_state_pro(scenario: Scenario, installs_per_year: float | None = None) -> float:
    if installs_per_year is None:
        installs_per_year = float(scenario.installs[-1])
    new_pro = installs_per_year * scenario.conversion
    return new_pro / (1.0 - scenario.annual_renewal)


def monthly_churn_from_annual(annual_renewal: float) -> float:
    """Equivalent geometric monthly churn, for comparison only."""
    return 1.0 - annual_renewal ** (1.0 / 12.0)


def year_3_cost_base() -> float:
    rows = schedule(BASE)
    return sum(row["total_costs"] for row in rows if year_of(row["month"]) == 3)


def flat_extension(scenario: Scenario, years: int = 3) -> list[dict[str, float]]:
    """Continue at the Year 3 install and cost run rates.

    This is an extension beyond the required 36-month schedule. It is used only
    to answer when cumulative cash recovers, and it is clearly labelled in the
    document. It assumes the Year 3 install rate, conversion, renewal, content
    run rate, and non-content cost base continue unchanged.
    """
    rows = schedule(scenario)
    active = rows[-1]["active_pro"]
    cumulative = rows[-1]["cumulative_cash"]
    year_3_costs = sum(row["total_costs"] for row in rows if year_of(row["month"]) == 3)
    extension: list[dict[str, float]] = []
    for year in range(4, 4 + years):
        new_pro = scenario.installs[-1] * scenario.conversion
        active = new_pro + scenario.annual_renewal * active
        revenue = active * NET_PER_ANNUAL_PRO
        profit = revenue - year_3_costs
        cumulative += profit
        extension.append(
            {
                "year": year,
                "installs": float(scenario.installs[-1]),
                "new_pro": new_pro,
                "end_active_pro": active,
                "net_billings": revenue,
                "total_costs": year_3_costs,
                "profit": profit,
                "cumulative_cash": cumulative,
            }
        )
    return extension


def content_case_summary(case: str) -> dict[str, object]:
    """Base demand with T3.9 low/base/high content costs."""
    rows = schedule(replace(BASE, content_case=case))
    low, month = trough(rows)
    return {
        "case": case,
        "annual": annual_summary(rows),
        "cash_need": -low,
        "trough_month": month,
        "month_36_cash": rows[-1]["cumulative_cash"],
    }


def sensitivity() -> list[dict[str, float | str]]:
    """Peak cash need and month-36 cash for each single-variable change."""
    results: list[dict[str, float | str]] = []
    scenarios: list[tuple[str, Scenario]] = []

    for name, factor in (("-25% installs", 0.75), ("+25% installs", 1.25)):
        scenarios.append(
            (
                name,
                replace(
                    BASE,
                    installs=tuple(round_half_up(value * factor) for value in BASE.installs),
                ),
            )
        )
    for conversion in (0.01, 0.02, 0.04):
        scenarios.append((f"{conversion:.0%} conversion", replace(BASE, conversion=conversion)))
    for renewal in (0.30, 0.40, 0.60):
        scenarios.append((f"{renewal:.0%} renewal", replace(BASE, annual_renewal=renewal)))
    for scale in (0.75, 1.25):
        scenarios.append((f"content {scale:.0%}", replace(BASE, content_scale=scale)))

    for name, scenario in scenarios:
        rows = schedule(scenario)
        low, month = trough(rows)
        results.append(
            {
                "case": name,
                "cash_need": -low,
                "trough_month": month,
                "month_36_cash": rows[-1]["cumulative_cash"],
                "year_3_cost": sum(
                    row["total_costs"] for row in rows if year_of(row["month"]) == 3
                ),
            }
        )
    return results


def fmt_money(value: float) -> str:
    sign = "-" if value < 0 else ""
    value = abs(value)
    if value >= 1_000_000:
        return f"{sign}${value / 1_000_000:,.2f}M"
    return f"{sign}${value:,.0f}"


def fmt_money_exact(value: float) -> str:
    sign = "-" if value < 0 else ""
    return f"{sign}${abs(value):,.2f}"


def print_summary() -> None:
    base_rows = schedule(BASE)
    down_rows = schedule(DOWNSIDE)
    base_years = annual_summary(base_rows)
    down_years = annual_summary(down_rows)

    print("Hear Me Out - costed P&L and downside cash model (T6.2)")
    print("Planning tool, not a forecast. Month 0 is launch preparation.")
    print()
    print("Assumptions")
    print(f"  Annual price:              ${LAUNCH_PRICE:,.2f}")
    print(f"  Store fee:                 {STORE_FEE:.0%}")
    print(f"  Refunds/tax reserve:       {REFUND_TAX_RESERVE:.0%}")
    print(f"  Net per annual Pro:        {fmt_money_exact(NET_PER_ANNUAL_PRO)}/year")
    print(f"  50% annual retention:      {monthly_churn_from_annual(0.50):.2%}/month equivalent")
    print(f"  40% annual retention:      {monthly_churn_from_annual(0.40):.2%}/month equivalent")
    print()

    for label, years in (("Base case", base_years), ("Downside case", down_years)):
        print(label)
        print(
            "  Year  Installs  NewPro  EndPro  GrossBillings  NetBillings  "
            "Recognized  Content   OtherCosts  TotalCosts  Profit  Cumulative"
        )
        for row in years:
            print(
                "  {year:>4}  {installs:>8,.0f}  {new_pro:>6,.0f}  {end_active_pro:>6,.1f}  "
                "{gross_billings:>13,.0f}  {net_billings:>11,.0f}  "
                "{recognized_revenue:>10,.0f}  {content:>8,.0f}  {other_costs:>10,.0f}  "
                "{total_costs:>10,.0f}  {profit:>7,.0f}  {cumulative_cash:>10,.0f}".format(**row)
            )
        low, month = trough(
            base_rows if label == "Base case" else down_rows
        )
        print(f"  Peak cash need: {fmt_money(-low)} at month {month}")
        extension = flat_extension(BASE if label == "Base case" else DOWNSIDE)
        print("  Flat extension at the Year 3 run rate (not part of the 36-month model):")
        for row in extension:
            print(
                "    Year {year:>2}  EndPro {end_active_pro:>7,.0f}  "
                "NetBillings {net_billings:>9,.0f}  Costs {total_costs:>9,.0f}  "
                "Profit {profit:>9,.0f}  Cumulative {cumulative_cash:>10,.0f}".format(**row)
            )
        print()

    print("Break-even")
    print(f"  Reconciled Year 3 cost base: {fmt_money(year_3_cost_base())}/year")
    print(
        f"  Operating break-even at that cost: "
        f"{break_even_pro(year_3_cost_base()):,.0f} annual Pro"
    )
    for cost in (114000.0, 120000.0, 139293.75):
        print(
            f"  At {fmt_money(cost)} annual cost: {break_even_pro(cost):,.0f} Pro"
        )
    print(f"  Base steady state at 40k installs/year: {steady_state_pro(BASE):,.0f} Pro")
    print(f"  Downside steady state at 40k installs/year: {steady_state_pro(DOWNSIDE):,.0f} Pro")
    print()

    print("Sensitivity - peak cash need through month 36")
    print("  Case                 Cash need   Trough   Month-36 cash")
    for row in sensitivity():
        print(
            f"  {row['case']:<20} {fmt_money(float(row['cash_need'])):>10}   "
            f"{int(row['trough_month']):>4}   {fmt_money(float(row['month_36_cash'])):>12}"
        )
    print()
    print("T3.9 content range at base demand")
    for case in ("low", "base", "high"):
        row = content_case_summary(case)
        print(
            f"  {case:<5}  cash need {fmt_money(float(row['cash_need'])):>9}  "
            f"trough month {int(row['trough_month']):>2}  "
            f"month-36 cash {fmt_money(float(row['month_36_cash'])):>10}"
        )
    print()

    print("Selected monthly checkpoints (base / downside)")
    print("  Month  Base cumulative   Downside cumulative")
    for month in (0, 6, 12, 18, 24, 30, 36):
        base_row = base_rows[month]
        down_row = down_rows[month]
        print(
            f"  {month:>5}  {fmt_money(base_row['cumulative_cash']):>15}   "
            f"{fmt_money(down_row['cumulative_cash']):>19}"
        )


def markdown_tables() -> str:
    base_rows = schedule(BASE)
    down_rows = schedule(DOWNSIDE)
    base_years = annual_summary(base_rows)
    down_years = annual_summary(down_rows)

    def annual_table(years: list[dict[str, float]]) -> str:
        lines = [
            "| Line | Year 1 | Year 2 | Year 3 |",
            "|---|---:|---:|---:|",
            "| Installs | "
            + " | ".join(f"{row['installs']:,.0f}" for row in years)
            + " |",
            "| New Pro | "
            + " | ".join(f"{row['new_pro']:,.1f}" for row in years)
            + " |",
            "| End-of-year active Pro | "
            + " | ".join(f"{row['end_active_pro']:,.1f}" for row in years)
            + " |",
            "| Gross billings | "
            + " | ".join(fmt_money(row["gross_billings"]) for row in years)
            + " |",
            "| Net billings | "
            + " | ".join(fmt_money(row["net_billings"]) for row in years)
            + " |",
            "| Recognized revenue (memo) | "
            + " | ".join(fmt_money(row["recognized_revenue"]) for row in years)
            + " |",
            "| Content | "
            + " | ".join(fmt_money(row["content"]) for row in years)
            + " |",
            "| DSP/dev | "
            + " | ".join(fmt_money(row["dsp_dev"]) for row in years)
            + " |",
            "| Legal/compliance | "
            + " | ".join(fmt_money(row["legal"]) for row in years)
            + " |",
            "| Hosting/support | "
            + " | ".join(fmt_money(row["hosting_support"]) for row in years)
            + " |",
            "| Marketing | "
            + " | ".join(fmt_money(row["marketing"]) for row in years)
            + " |",
            "| Tools/ops | "
            + " | ".join(fmt_money(row["tools_ops"]) for row in years)
            + " |",
            "| **Total costs** | "
            + " | ".join(f"**{fmt_money(row['total_costs'])}**" for row in years)
            + " |",
            "| **Cash profit** | "
            + " | ".join(f"**{fmt_money(row['profit'])}**" for row in years)
            + " |",
            "| **Cumulative cash** | "
            + " | ".join(f"**{fmt_money(row['cumulative_cash'])}**" for row in years)
            + " |",
        ]
        return "\n".join(lines)

    lines = ["### Base case", "", annual_table(base_years), "", "### Downside case", "", annual_table(down_years), ""]
    lines.append("### Monthly checkpoints")
    lines.append("")
    lines.append("| Month | Base cumulative cash | Downside cumulative cash |")
    lines.append("|---:|---:|---:|")
    for month in (0, 6, 12, 18, 24, 30, 36):
        lines.append(
            f"| {month} | {fmt_money(base_rows[month]['cumulative_cash'])} | "
            f"{fmt_money(down_rows[month]['cumulative_cash'])} |"
        )
    lines.append("")
    lines.append("### Sensitivity")
    lines.append("")
    lines.append("| Case | Peak cash need | Trough month | Month-36 cumulative cash |")
    lines.append("|---|---:|---:|---:|")
    for row in sensitivity():
        lines.append(
            f"| {row['case']} | {fmt_money(float(row['cash_need']))} | "
            f"{int(row['trough_month'])} | {fmt_money(float(row['month_36_cash']))} |"
        )
    lines.append("")
    lines.append("### T3.9 content range at base demand")
    lines.append("")
    lines.append("| Content case | Peak cash need | Trough month | Month-36 cumulative cash |")
    lines.append("|---|---:|---:|---:|")
    for case in ("low", "base", "high"):
        row = content_case_summary(case)
        lines.append(
            f"| {case} | {fmt_money(float(row['cash_need']))} | "
            f"{int(row['trough_month'])} | {fmt_money(float(row['month_36_cash']))} |"
        )
    lines.append("")
    lines.append("### Flat extension at the Year 3 run rate")
    lines.append("")
    lines.append("| Case | Year | End active Pro | Net billings | Total costs | Profit | Cumulative cash |")
    lines.append("|---|---:|---:|---:|---:|---:|---:|")
    for label, scenario in (("Base", BASE), ("Downside", DOWNSIDE)):
        for row in flat_extension(scenario):
            lines.append(
                f"| {label} | {int(row['year'])} | {row['end_active_pro']:,.0f} | "
                f"{fmt_money(row['net_billings'])} | {fmt_money(row['total_costs'])} | "
                f"{fmt_money(row['profit'])} | {fmt_money(row['cumulative_cash'])} |"
            )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--json", action="store_true", help="print one JSON object")
    group.add_argument("--markdown", action="store_true", help="print Markdown tables")
    args = parser.parse_args()

    if args.json:
        base_rows = schedule(BASE)
        down_rows = schedule(DOWNSIDE)
        payload = {
            "assumptions": {
                "price": LAUNCH_PRICE,
                "store_fee": STORE_FEE,
                "refund_tax_reserve": REFUND_TAX_RESERVE,
                "net_per_annual_pro": NET_PER_ANNUAL_PRO,
                "base": {
                    "installs": BASE.installs,
                    "conversion": BASE.conversion,
                    "annual_renewal": BASE.annual_renewal,
                },
                "downside": {
                    "installs": DOWNSIDE.installs,
                    "conversion": DOWNSIDE.conversion,
                    "annual_renewal": DOWNSIDE.annual_renewal,
                },
            },
            "base": {
                "annual": annual_summary(base_rows),
                "trough": trough(base_rows),
                "extension": flat_extension(BASE),
                "schedule": base_rows,
            },
            "downside": {
                "annual": annual_summary(down_rows),
                "trough": trough(down_rows),
                "extension": flat_extension(DOWNSIDE),
                "schedule": down_rows,
            },
            "break_even": {
                "year_3_cost": year_3_cost_base(),
                "at_year_3_cost": break_even_pro(year_3_cost_base()),
                "at_114k": break_even_pro(114000.0),
                "at_120k": break_even_pro(120000.0),
                "at_139293_75": break_even_pro(139293.75),
                "base_steady_state": steady_state_pro(BASE),
                "downside_steady_state": steady_state_pro(DOWNSIDE),
            },
            "sensitivity": sensitivity(),
            "content_cases": {
                case: content_case_summary(case) for case in ("low", "base", "high")
            },
        }
        print(json.dumps(payload, indent=2, sort_keys=True))
    elif args.markdown:
        print(markdown_tables())
    else:
        print_summary()


if __name__ == "__main__":
    main()
