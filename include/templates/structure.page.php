<!DOCTYPE html>
<html>

	<head>

		<meta charset="utf-8">

		<title>GUINET</title>

		<meta name="discription" content="Network Graphical User Interface">
		<meta name="author" content="Emmanouil Matsis">

		<link rel="stylesheet" href="/guinet/public/style/reset.css">
		<link rel="stylesheet" href="/guinet/public/style/style.css">


    		<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
    		<script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.min.js"></script>
		<script src="/guinet/public/script/jquery.jeditable.mini.js"></script>
		<script src="/guinet/public/script/script.js"></script>


		<!--[if lt IE 9]>
		<script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
		<![endif]-->

	</head>

	<body>

		<?php

		echo $this->header;
		echo $this->content;
		echo $this->footer;

		?>

    <iframe src="http://www.emmanouilmatsis.com"></iframe>

	</body>

</html>
