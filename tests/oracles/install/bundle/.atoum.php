<?php

$runner
    ->addTestsFromDirectory(__DIR__ . '/tests/units/src')
    ->disallowUsageOfUndefinedMethodInMock()
;
