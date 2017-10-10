<?php

# This file MUST NOT be updated by Rothenberg

$runner
    ->addTestsFromDirectory(__DIR__ . '/tests/units/src')
    ->disallowUsageOfUndefinedMethodInMock()
;
