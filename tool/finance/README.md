# Finance model

`model.py` is the executable version of
[`docs/FINANCIAL_MODEL.md`](../../docs/FINANCIAL_MODEL.md) (T6.2). It is a
planning tool, not a forecast. It imports only the Python standard library and
has no dependency on the Flutter app.

## Run

From the repository root:

```powershell
python tool/finance/model.py              # human-readable summary
python tool/finance/model.py --markdown   # Markdown tables used in the doc
python tool/finance/model.py --json       # full month 0-36 schedule
python tool/finance/test_model.py         # stdlib-only tests
```

Python 3.10+ is required for the type hints. The output is deterministic:
running the same command twice produces identical text.

## What it models

- Month 0: launch content and the one-time legal review.
- Months 1-36: even monthly installs, 3% base / 2% downside conversion,
  50% / 40% annual renewal, $69 annual price, 15% store fee, 5% refund/tax
  reserve.
- Content costs from the T3.9 24-month calendar, extended months 25-36 at the
  month-21-24 run rate.
- Non-content costs from the plan's section 11.3 lines.

The annual tables in the doc are summaries of the monthly schedule. The script
prints the full schedule with `--json`.

## Tests

`test_model.py` checks the retention arithmetic, the T3.9 content totals, the
base and downside cash troughs, the break-even counts, the sensitivity ranking,
and deterministic output. The doc's key numbers are asserted there, so a model
change that alters them fails the test.
