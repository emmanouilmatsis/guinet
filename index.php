<?php


// Set the error reporting level
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Start a PHP session
session_start();

// Include site constants
include_once $_SERVER['DOCUMENT_ROOT'] . "/guinet/admin/constants.php";

// Include classes
include_once $_SERVER['DOCUMENT_ROOT'] . '/guinet/include/model.php';
include_once $_SERVER['DOCUMENT_ROOT'] . '/guinet/include/view.php';
include_once $_SERVER['DOCUMENT_ROOT'] . '/guinet/include/controller.php';
include_once $_SERVER['DOCUMENT_ROOT'] . '/guinet/include/router.php';
include_once $_SERVER['DOCUMENT_ROOT'] . '/guinet/include/template.php';
include_once $_SERVER['DOCUMENT_ROOT'] . '/guinet/include/database.php';
include_once $_SERVER['DOCUMENT_ROOT'] . '/guinet/include/user.php';
include_once $_SERVER['DOCUMENT_ROOT'] . '/guinet/include/widget.php';

// Instantiate front controller
$router = new Router();
$route = $_GET['route'];
$action =  isset($_GET['action']) ? $_GET['action'] : null;

$frontController = new FrontController($router, $route, $action);
echo $frontController->output();


?>
