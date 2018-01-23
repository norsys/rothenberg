<?php

$composerJson = json_decode(file_get_contents($argv[1]), true);

$composerJson["require"]["php"] = ">=7.0.0";

$composerJson["require-dev"]["squizlabs/php_codesniffer"] = "^2.6";
$composerJson["require-dev"]["atoum/atoum"] = "~3.0";
$composerJson["require-dev"]["atoum/stubs"] = "~2.5";
$composerJson["require-dev"]["atoum/bdd-extension"] = "~2.1";

if (($argv[2] ?? 'app') == 'app') {
    $composerJson["extra"]["symfony-app-dir"] = "./app";
    $composerJson["extra"]["symfony-bin-dir"] = "./bin";
    $composerJson["extra"]["symfony-var-dir"] = "./var";
    $composerJson["extra"]["symfony-web-dir"] = "./web";
    $composerJson["extra"]["symfony-tests-dir"] = "./tests";
    $composerJson["extra"]["symfony-assets-install"] = "relative";

    $scripts = [ "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::buildBootstrap", "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::clearCache" ];
    $composerJson["scripts"]["post-install-cmd"] = array_values(array_unique(array_merge($composerJson["scripts"]["post-install-cmd"] ?? [], $scripts)));
    $composerJson["scripts"]["post-update-cmd"] = array_values(array_unique(array_merge($composerJson["scripts"]["post-update-cmd"] ?? [], $scripts)));

    $composerJson["autoload"]["psr-4"][""] = "./src";
    $composerJson["autoload"]["classmap"] = array_values(array_unique(array_merge($composerJson["autoload"]["classmap"] ?? [], [ "./app/AppKernel.php", "./app/AppCache.php" ])));

    $composerJson["autoload-dev"]["psr-4"]["AppBundle\\Tests\\Units\\"] = "./tests/units/src/AppBundle";
    $composerJson["autoload-dev"]["psr-4"]["AppBundle\\Tests\\Functionals\\"] = "./tests/functionals/bootstrap";

    $composerJson["require"]["symfony/symfony"] = "3.1.*";
    $composerJson["require"]["symfony/console"] = "3.1.*";
    $composerJson["require"]["sensio/distribution-bundle"] = "^5.0";
    $composerJson["require"]["sensio/framework-extra-bundle"] = "3.0.*";

    $composerJson["require-dev"]["behat/behat"] = "~3.2";
    $composerJson["require-dev"]["behat/symfony2-extension"] = "^2.1";
    $composerJson["require-dev"]["behat/mink"] = "~1.7";
    $composerJson["require-dev"]["behat/mink-extension"] = "~2.2";
    $composerJson["require-dev"]["behat/mink-browserkit-driver"] = "~1.3";
    $composerJson["require-dev"]["behat/mink-selenium2-driver"] = "~1.3";
    $composerJson["require-dev"]["behat/mink-goutte-driver"] = "^1.2";
}

exit(file_put_contents($argv[1], json_encode($composerJson, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE) . PHP_EOL) === false ? 1 : 0);
