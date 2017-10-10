<?php
declare(strict_types=1);

use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Debug\Debug;

$debug = getenv("SYMFONY_DEBUG") === 'true' ? true : false;
$env   = getenv("SYMFONY_ENV") ?? 'prod';

/**
 * @var Composer\Autoload\ClassLoader $loader
 */
$loader = require __DIR__.'/../app/autoload.php';

if ($env === 'prod') {
    include_once __DIR__.'/../var/bootstrap.php.cache';
}

if ($debug) {
    Debug::enable();
}

$kernel = new AppKernel($env, $debug);
$kernel->loadClassCache();
$request = Request::createFromGlobals();
$response = $kernel->handle($request);
$response->send();
$kernel->terminate($request, $response);
