<?php


// Front Controller
class FrontController
{
	private $model;
	private $view;
	private $controller;

	public function __construct($router, $route, $action)
	{
    // Setup router
		$router->setRoute($route);

    // Initialize model-view-controller from route
		$this->model = new $router->model();
		$this->view = new $router->view($this->model);
		$this->controller = new $router->controller($this->model);

		if(!is_null($action)) $this->controller->{$action}();
	}

	public function output()
	{
		return $this->view->output();
	}
}


// Controller
abstract class Controller
{
	protected $model;

	public function __construct(Model $model)
	{
		$this->model = $model;
	}

  // Construct and redirect to URL
	public function redirect($route, $action=null, $param=null)
	{
    $url = URL_ROOT;
    $url .= '/index.php';
    $url .= '?route=' . $route;
    $url .= is_null($action) ? '' : '&action=' . $action;
    $url .= is_null($param) ? '' : '&param=' . $param;

		header('Location: ' . $url);
		exit;
	}
}


// Index Conrtoller
class IndexController extends Controller
{
	public function __construct(Model $model)
	{
		parent::__construct($model);

    // Redirect to home if user is signedin
		if ($this->model->state())
			$this->redirect("home");
	}
}


// Home Controller
class HomeController extends Controller
{
	public function __construct(Model $model)
	{
		parent::__construct($model);

    // Redirect to index if user is signedout
		if (!$this->model->state())
			$this->redirect("index");
	}

  public function signout()
  {
    $this->model->signout();
		$this->redirect("index");
  }
}


// Signup Controller
class SignupController extends Controller
{
	public function __construct(Model $model)
	{
		parent::__construct($model);

    // Redirect to home if user is signedin
		if ($this->model->state())
			$this->redirect("home");
	}

  public function signup()
  {
    // Redirect to home if user is signedup
    if ($this->model->signup())
      $this->redirect("home");
  }
}


// Signin Controller
class SigninController extends Controller
{
	public function __construct(Model $model)
	{
		parent::__construct($model);

    // Redirect to home if user is signedin
		if ($this->model->state())
			$this->redirect("home");
	}

  public function signin()
  {
    if ($this->model->signin())
      $this->redirect("home");
  }

  public function send()
  {
    if ($this->model->send())
      $this->redirect("index");
  }
}


// Settings Controller
class SettingsController extends Controller
{
	public function __construct(Model $model)
	{
		parent::__construct($model);

    // Redirect to index if user is signedout
		if (!$this->model->state())
			$this->redirect("index");
	}

  public function username()
  {
    $this->model->updateUsername();
  }

  public function password()
  {
    $this->model->updatePassword();
  }
}


// Data Controller
class DataController extends Controller
{
  public function __construct(Model $model)
  {
    parent::__construct($model);
  }

  // Get data to client
  public function get()
  {
		if ($this->model->state())
      $this->model->get();
  }

  // Set data from client
  public function set()
  {
		if ($this->model->state())
      $this->model->set();
  }
}


?>
