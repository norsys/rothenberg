<?php

namespace AppBundle\Tests\Units;

use mageekguy\atoum;
use mageekguy\atoum\mock;

class Test extends atoum
{
    public function beforeTestMethod($method)
    {
        mock\controller::disableAutoBindForNewMock();

        $this->mockGenerator
            ->allIsInterface()
            ->eachInstanceIsUnique()
        ;

        return parent::beforeTestMethod($method);
    }
}
