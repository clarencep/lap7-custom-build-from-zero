<?php

error_reporting(E_ALL);
ini_set('display_errors', 'on');

if (PHP_SAPI === 'cli'){
    $isVerbose = in_array('-v', $argv);
} else {
    $isVerbose = @$_GET['v'];
    header('Content-Type: text/plain');
}

$stats = [
    'total' => 0,
    'failed' => 0,
    'ok' => 0,
];

function check_extension($ext, $func) {
    global $isVerbose, $stats;

    $stats['total']++;

    echo "Checking extension $ext ...";
    try {
        $func();

        echo "   OK.\n";
        $stats['ok']++;
    } catch (\Exception $e) {
        echo "   FAILED. \n";
        $stats['failed']++;
        if ($isVerbose){
            echo $e->getMessage() . "\n";
            echo $e->getTraceAsString() . "\n";
        }
    }

    flush();
}

function do_assert($condition){
    if (!$condition){
        $stacks = debug_backtrace(DEBUG_BACKTRACE_PROVIDE_OBJECT | DEBUG_BACKTRACE_IGNORE_ARGS, 2);
        throw new Exception("assertion failed: " . trim(file($stacks[0]['file'])[$stacks[0]['line'] - 1]));
    }
}

set_error_handler(function ($level, $message, $file = '', $line = 0) {
    if (error_reporting() & $level) {
        throw new ErrorException($message, 0, $level, $file, $line);
    }
});

check_extension('redis', function(){
    do_assert(class_exists("Redis"));
});

check_extension('imagick', function(){
    do_assert(class_exists("Imagick"));
});

check_extension('inotify', function(){
    do_assert(function_exists("inotify_init"));
});


check_extension('igbinary', function(){
    do_assert(function_exists("igbinary_serialize"));
});

// check_extension('mysql', function(){
//     do_assert(function_exists("mysql_connect"));
// });

check_extension('mysqli', function(){
    do_assert(class_exists("mysqli"));
});

check_extension('PDO', function(){
    do_assert(class_exists("PDO"));
});


check_extension('PDO_mysql', function(){
    do_assert(extension_loaded("pdo_mysql"));
});

echo $stats['total'] . " Extensions checked. ";
echo $stats['failed'] . " failed. ";
echo $stats['ok'] . " OK.\n";

exit($stats['failed']);

