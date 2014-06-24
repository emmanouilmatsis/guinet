<?php


class FrontController
{
	private $model;
	private $view;
	private $controller;

	public function __construct($router, $route, $action)
	{
		$router->setRoute($route);

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


abstract class Controller
{
	protected $model;

	public function __construct(Model $model)
	{
		$this->model = $model;
	}

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


class IndexController extends Controller
{
	public function __construct(Model $model)
	{
		parent::__construct($model);

		if ($this->model->state())
			$this->redirect("home");
	}
}


class HomeController extends Controller
{
	public function __construct(Model $model)
	{
		parent::__construct($model);

		if (!$this->model->state())
			$this->redirect("index");
	}

  public function signout()
  {
    $this->model->signout();
		$this->redirect("index");
  }
}


class SignupController extends Controller
{
	public function __construct(Model $model)
	{
		parent::__construct($model);

		if ($this->model->state())
			$this->redirect("home");
	}

  public function signup()
  {
    if ($this->model->signup())
      $this->redirect("home");
  }
}


class SigninController extends Controller
{
	public function __construct(Model $model)
	{
		parent::__construct($model);

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


class SettingsController extends Controller
{
	public function __construct(Model $model)
	{
		parent::__construct($model);

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


class DataController extends Controller
{
  public function __construct(Model $model)
  {
    parent::__construct($model);
  }

  public function get()
  {
		if ($this->model->state())
      $this->model->get();
  }

  public function set()
  {
		if ($this->model->state())
      $this->model->set();
  }
}


?>
