<?php


class Template 
{
	private $template;
	private $vars  = array();

	function __construct($template)
	{
		if (!is_file($template))
		{
			throw new FileNotFoundException("File not found: " . $template);
		}
		elseif(!is_readable($template))
		{
			throw new IOException("Could not access file: " . $template);
		}
		else
		{
			$this->template = $template;
		}
	}

	public function __get($key)
	{
		return $this->vars[$key];
	}

	public function __set($key, $value)
	{
		$this->vars[$key] = $value;
	}

	public function render()
	{
		extract($this->vars);
		ob_start();
		include($this->template);
		return ob_get_clean();
	}
}


?>
