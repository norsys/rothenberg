<?php
declare(strict_types=1);

use Symfony\Component\HttpKernel\Kernel;
use Symfony\Component\Config\Loader\LoaderInterface;
use Infrastructure\Fixtures\OverrideFixturesFinderCompilerPass;
use Infrastructure\Validation\ValidatorCompilerPass;

class AppKernel extends Kernel
{
    /**
     * Register bundles
     *
     * @return array
     */
    public function registerBundles()
    {
        $bundles = [
            new Symfony\Bundle\FrameworkBundle\FrameworkBundle(),
            new Symfony\Bundle\SecurityBundle\SecurityBundle(),
            new Symfony\Bundle\TwigBundle\TwigBundle(),
            new Sensio\Bundle\FrameworkExtraBundle\SensioFrameworkExtraBundle(),
            new AppBundle\AppBundle(),
        ];

        if (in_array($this->getEnvironment(), ['dev', 'test'], true)) {
            $bundles[] = new Symfony\Bundle\DebugBundle\DebugBundle();
            $bundles[] = new Symfony\Bundle\WebProfilerBundle\WebProfilerBundle();
            $bundles[] = new Sensio\Bundle\DistributionBundle\SensioDistributionBundle();
        }

        return $bundles;
    }

    /**
     * Get root directory
     *
     * @return string
     */
    public function getRootDir(): string
    {
        return __DIR__;
    }

    /**
     * Get cache directory
     *
     * @return string
     */
    public function getCacheDir(): string
    {
        return dirname(__DIR__).'/var/cache/'.$this->getEnvironment();
    }

    /**
     * Get log directory
     *
     * @return string
     */
    public function getLogDir(): string
    {
        return dirname(__DIR__).'/var/logs';
    }

    /**
     * Load configuration
     *
     * @param LoaderInterface $loader
     */
    public function registerContainerConfiguration(LoaderInterface $loader)
    {
        $loader->load($this->getRootDir().'/config/config_'.$this->getEnvironment().'.yml');
    }
}
