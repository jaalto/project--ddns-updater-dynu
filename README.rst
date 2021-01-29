..  comment: the source is maintained in ReST format.
    Emacs: http://docutils.sourceforge.net/tools/editors/emacs/rst.el
    Manual: http://docutils.sourceforge.net/docs/user/rst/quickref.html

DESCRIPTION
===========

A dynamic DNS (DDNS) update client for dynu.com[1] implemented in POSIX shell.

How does it work?
-----------------

Based on your domains and your generated API-Key, the program can
be used to periodically update the IP.

1. Create a user account at dynu.com

2. Add Dynamic DNS domain(s) to your account (paid, yearly fee).

3. Create API-Key at https://www.dynu.com/ControlPanel/APICredentials

4. Using the API-Key, get listing of your hosts and their ID values.

   ddns-updater-dynu --apikey <APIKEY> --query

5. Create configuration file(s) at ~/.config/ddns-updater-dynu/*.conf
   See ddns-updater-dynu --help for more information about the content.
   In short: define APIKEY, DOMAINN and ID varbales write "ENABLE=yes"

After setting up configuration file(s), call program periodically from
from cron. You can run in test mode with: ::

    ddns-updater-dynu --confdir ~/.config/ddns-updater-dynu --test --verbose

REQUIREMENTS
============

1. POSIX environment and standard utilities (grep, ...)

2. POSIX ``/bin/sh`` and some client ``curl(1)``

INSTALL
=======

See details in separate INSTALL file.

REFERENCES
==========

- [1] https://www.dynu.com (see "DDNS" menu)

COPYRIGHT AND LICENSE
=====================

Copyright (C) 2021 Jari Aalto <jari.aalto@cante.net>

This project is free; you can redistribute and/or modify it under
the terms of GNU General Public license either version 2 of the
License, or (at your option) any later version.

Project homepage (bugs and source) is at
https://github.com/jaalto/project--ddns-updater-dynu

.. End of file
