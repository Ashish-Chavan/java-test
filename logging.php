<?php
/**
 * Sample PHP Program Demonstrating Different Logging Methods
 */

// ------------------------------
// 1. Basic Logging with error_log()
// ------------------------------
error_log("This is a message logged using error_log().");


// ------------------------------
// 2. Logging to a Custom File Using error_log()
// ------------------------------
$customLogFile = __DIR__ . "/custom.log";
error_log("This message goes to custom.log", 3, $customLogFile);


// ------------------------------
// 3. Custom Logging Function
// ------------------------------
function customLogger($message) {
    $file = __DIR__ . "/app.log";
    $timestamp = date("Y-m-d H:i:s");
    file_put_contents($file, "[$timestamp] $message\n", FILE_APPEND);
}

customLogger("Custom logger: User logged in.");


// ------------------------------
// 4. Logging Exceptions
// ------------------------------
try {
    throw new Exception("Example exception occurred!");
} catch (Exception $e) {
    error_log("Caught exception: " . $e->getMessage());
}


// ------------------------------
// 5. Logging Using Monolog (Advanced / Best Practice)
// ------------------------------
require_once __DIR__ . '/vendor/autoload.php';   // Requires Composer

use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Monolog\Handler\RotatingFileHandler;

// Create Monolog instance
$monolog = new Logger("DemoApp");

// File log handler
$monolog->pushHandler(new StreamHandler(__DIR__ . '/monolog.log', Logger::DEBUG));

// Rotating log handler (keeps 7 days of logs)
$monolog->pushHandler(new RotatingFileHandler(__DIR__ . '/rotating.log', 7, Logger::INFO));

// Log different levels
$monolog->debug("Debug message from Monolog.");
$monolog->info("Info message from Monolog.");
$monolog->warning("Warning message from Monolog.");
$monolog->error("Error message from Monolog.");

echo "Logging demonstration completed! Check log files.\n";


class Car {
    // Attributes (also called properties)
    public $brand;
    public $color;

    // Method
    public function displayInfo() {
        echo "Brand: $this->brand, Color: $this->color";
    }
}

// Creating an object
$myCar = new Car();

// Assigning values to attributes
$myCar->brand = "Toyota";
$myCar->color = "Red";

// Using a method
$myCar->displayInfo();
