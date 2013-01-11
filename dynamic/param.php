<?php

$output = <<<EOF
    The displayed name stays <b>{$_GET['name']}</b>.
    Because varnish replaces anything passed to "bob". \n
EOF;

echo $output;