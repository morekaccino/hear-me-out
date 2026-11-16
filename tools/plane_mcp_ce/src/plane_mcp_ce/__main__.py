"""Entry point for ``python -m plane_mcp_ce stdio``.

Windows Smart App Control blocks the unsigned ``.exe`` launcher that ``uvx``
generates for the console script. Running the installed module through the
virtual environment's interpreter avoids that launcher.

The wrapper itself stays in ``__init__.py`` so the module and the console
script share one implementation.
"""

from plane_mcp_ce import main

main()
