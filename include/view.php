<?php


abstract class View
{
	protected $model;

	public function __construct(Model $model)
	{
		$this->model = $model;
	}

  public function output()
  {
		$this->page = new Template(FP_ROOT . 'include/templates/structure.page.php');
		$this->page->header = $this->header();
		$this->page->content = $this->content();
		$this->page->footer = $this->footer();
		return $this->page->render();
  }

  abstract protected function header();

  abstract protected function content();

  abstract protected function footer();
}


class IndexView extends View
{
	public function __construct(Model $model)
	{
		parent::__construct($model);
	}

	protected function header()
	{
		$header = new Template(FP_ROOT . 'include/templates/structure.header.php');
		$header->href1 = URL_ROOT . 'index.php?route=signup';
		$header->href2 = URL_ROOT . 'index.php?route=signin';
		$header->title1 = 'SIGNUP';
		$header->title2 = 'SIGNIN';
		return $header->render();
	}

	protected function content()
	{
		$content = new Template(FP_ROOT . 'include/templates/structure.content.php');
		$content->content = file_get_contents(FP_ROOT . 'include/templates/message.index.php');
		return $content->render();
	}

	protected function footer()
	{
		$footer = new Template(FP_ROOT . 'include/templates/structure.footer.php');
		return $footer->render();
	}
}


class HomeView extends View
{
	public function __construct(Model $model)
	{
		parent::__construct($model);
	}

	protected function header()
	{
		$header = new Template(FP_ROOT . 'include/templates/structure.header.php');
		$header->href1 = URL_ROOT . 'index.php?route=settings';
		$header->href2 = URL_ROOT . 'index.php?route=home&action=signout';
		$header->title1 = 'SETTINGS';
		$header->title2 = 'SIGNOUT';
		return $header->render();
	}

	protected function content()
	{
    $preloader = new Template(FP_ROOT . 'include/templates/message.home.php'); // FIXME: templates
    $preloader->filename = URL_ROOT . 'public/image/preloader.png';

		$content = new Template(FP_ROOT . 'include/templates/structure.content.php');
		$content->content = $preloader->render();
		return $content->render();
	}

	protected function footer()
	{
		$footer = new Template(FP_ROOT . 'include/templates/structure.footer.php');
		return $footer->render();
	}
}


class SignupView extends View
{
	public function __construct(Model $model)
	{
		parent::__construct($model);
	}

	protected function header()
	{
		$header = new Template(FP_ROOT . 'include/templates/structure.header.php');
		$header->href1 = '#';
		$header->href2 = URL_ROOT . 'index.php?route=index';
		$header->title1 = '';
		$header->title2 = 'BACK';
		return $header->render();
	}

	protected function content()
	{
    $form = new Template(FP_ROOT . 'include/templates/form.signup.php');
    $form->signup = URL_ROOT . 'index.php?route=signup&action=signup';

		$content = new Template(FP_ROOT . 'include/templates/structure.content.php');
		$content->content = $form->render();
		return $content->render();
	}

	protected function footer()
	{
		$footer = new Template(FP_ROOT . 'include/templates/structure.footer.php');
		return $footer->render();
	}
}


class SigninView extends View
{
	public function __construct(Model $model)
	{
		parent::__construct($model);
	}

	protected function header()
	{
		$header = new Template(FP_ROOT . 'include/templates/structure.header.php');
		$header->href1 = '#';
		$header->href2 = URL_ROOT . 'index.php?route=index';
		$header->title1 = '';
		$header->title2 = 'BACK';
		return $header->render();
	}

	protected function content()
	{
    $form = new Template(FP_ROOT . 'include/templates/form.signin.php');
    $form->signin = URL_ROOT . 'index.php?route=signin&action=signin';
    $form->send = URL_ROOT . 'index.php?route=signin&action=send';

		$content = new Template(FP_ROOT . 'include/templates/structure.content.php');
		$content->content = $form->render();
		return $content->render();
	}

	protected function footer()
	{
		$footer = new Template(FP_ROOT . 'include/templates/structure.footer.php');
		return $footer->render();
	}
}


class SettingsView extends View
{
	public function __construct(Model $model)
	{
		parent::__construct($model);
	}

	protected function header()
	{
		$header = new Template(FP_ROOT . 'include/templates/structure.header.php');
		$header->href1 = '#';
		$header->href2 = URL_ROOT . 'index.php?route=home';
		$header->title1 = '';
		$header->title2 = 'BACK';
		return $header->render();
	}

	protected function content()
	{
    $form = new Template(FP_ROOT . 'include/templates/form.settings.php');
    $form->username = URL_ROOT . 'index.php?route=settings&action=username';
    $form->password = URL_ROOT . 'index.php?route=settings&action=password';

		$content = new Template(FP_ROOT . 'include/templates/structure.content.php');
		$content->content = $form->render();
		return $content->render();
	}

	protected function footer()
	{
		$footer = new Template(FP_ROOT . 'include/templates/structure.footer.php');
		return $footer->render();
	}
}


class DataView extends View
{
	public function __construct(Model $model)
	{
		parent::__construct($model);
	}

  public function output()
  {
    return $this->model->data;
  }

  protected function header(){}
  protected function content(){}
  protected function footer(){}
}


?>
