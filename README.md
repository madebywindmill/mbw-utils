# MBWUtils

Copyright (C) 2016-2021 Made by Windmill, LLC - All Rights Reserved

Contact: <hello@madebywindmill.com>

A library of common utility Swift code for use by Made by Windmill, LLC and its clients.

## Requirements

MBWLogger logs to a log file in the shared app group directory, so:

* The app must have the AppGroups entitlement
* For each target that uses MBWLogger, the app group identifier needs to be stored as an environment variable `APP_GROUP_IDENTIFIER` 

