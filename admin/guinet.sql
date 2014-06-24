-- phpMyAdmin SQL Dump
-- version 3.4.10.1deb1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jun 23, 2014 at 11:56 AM
-- Server version: 5.5.37
-- PHP Version: 5.3.10-1ubuntu3.11

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `guinet`
--

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE IF NOT EXISTS `user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=2 ;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`id`, `username`, `password`) VALUES
(1, 'em', '0000');

-- --------------------------------------------------------

--
-- Table structure for table `widget`
--

CREATE TABLE IF NOT EXISTS `widget` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `type` varchar(50) NOT NULL,
  `html` text NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=102 ;

--
-- Dumping data for table `widget`
--

INSERT INTO `widget` (`id`, `user_id`, `type`, `html`) VALUES
(100, 1, 'note', '<article style="position: absolute; display: block; opacity: 1; z-index: 1; left: 303px; top: 92px;" class="widget note ui-draggable"><div class="window"><header class="titlebar clearfix"><h1 class="label">Notes</h1></header><div class="toolbar clearfix"><select class="dropdown"><option>Select Widget:</option><option value="bookmark">Bookmark</option><option value="texteditor">Text Editor</option><option value="chat">Chat</option><option value="imageviewer">Image Viewer</option><option value="browser">Browser</option></select></div><ul class="listbox"><li class="item"><h1 class="label">Add widget from the drop-down menu.</h1></li><li class="item"><h1 class="label">Delete widget from the delete button on the right of the titlebar.</h1></li><li class="item"><h1 class="label">Move widget from the titlebar.</h1></li><li class="item"><h1 class="label">Right-click widget titlebar to rename.</h1></li></ul></div></article>'),
(101, 1, 'bookmark', '<article style="position: absolute; display: block; z-index: 2; left: 143px; top: 92px;" class="widget bookmark ui-draggable ui-draggable-dragging"><div class="window"><header class="titlebar clearfix"><h1 class="label">Right-click to edit</h1><button type="button" value="delete" class="button">-</button></header><div class="toolbar clearfix"><input placeholder="New Item" class="textbox" type="text"><button type="button" value="add" class="button">+</button></div><ul class="listbox ui-sortable"><li style="display: list-item;" class="item clearfix"><a href="https://mail.google.com/mail/u/0/?shva=1#inbox" target="_blank" class="link">https://mail</a><button type="button" value="delete" class="button">-</button></li><li style="display: list-item;" class="item clearfix"><a href="http://emmanouilmatsis.com/" target="_blank" class="link">http://emmanouilmatsis</a><button type="button" value="delete" class="button">-</button></li><li style="" class="item clearfix"><a href="#" target="_blank" class="link">Right-click to edit</a><button type="button" value="delete" class="button">-</button></li></ul></div></article>');

--
-- Constraints for dumped tables
--

--
-- Constraints for table `widget`
--
ALTER TABLE `widget`
  ADD CONSTRAINT `widget_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
