<?php


// Router
class Router
{
	private $table = array();
	private $route;

	public function __construct()
	{
    // Statically populate table with each page
		$this->table['index'] = array('model'=>'IndexModel', 'view'=>'IndexView', 'controller'=>'IndexController');
		$this->table['home'] = array('model'=>'HomeModel', 'view'=>'HomeView', 'controller'=>'HomeController');
		$this->table['signup'] = array('model'=>'SignupModel', 'view'=>'SignupView', 'controller'=>'SignupController');
		$this->table['signin'] = array('model'=>'SigninModel', 'view'=>'SigninView', 'controller'=>'SigninController');
		$this->table['settings'] = array('model'=>'SettingsModel', 'view'=>'SettingsView', 'controller'=>'SettingsController');
		$this->table['data'] = array('model'=>'DataModel', 'view'=>'DataView', 'controller'=>'DataController');
	}

	public function setRoute($route)
	{
		$this->route = $route;
	}

  public function __get($key)
  {
    // Return the triplet (Model-View-Controller) for requested route.
    return $this->table[$this->route][$key];
  }
}


?>
