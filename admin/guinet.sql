-- phpMyAdmin SQL Dump
-- version 3.4.10.1deb1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jun 06, 2014 at 03:24 PM
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

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_AppendChild`(
            IN choosen_tree INTEGER UNSIGNED,
            IN parent_id INTEGER UNSIGNED,
            OUT new_id INTEGER UNSIGNED,
            OUT cur_tree_id INTEGER UNSIGNED)
    DETERMINISTIC
BEGIN

    DECLARE num INTEGER UNSIGNED;

    START TRANSACTION;
    
    SET cur_tree_id = IF(choosen_tree > 0,
                         choosen_tree,
                         IFNULL((SELECT MAX(tree_id)+1 FROM component),1)
                        );
    
    IF parent_id = 0 THEN /* inserting a new root node*/

        UPDATE component
        SET lft = lft+1, rgt = rgt+1
        WHERE tree_id=cur_tree_id;

        SET num = IFNULL((SELECT MAX(rgt)+1 FROM component WHERE tree_id=cur_tree_id),2);

        INSERT INTO component(tree_id, id, lft, rgt)
        VALUES (cur_tree_id, NULL, 1, num);

    ELSE /* append a new node as last right child of his parent */
        
        SET num = (SELECT rgt
                   FROM component
                   WHERE id = parent_id
                  );

        UPDATE component
        SET lft = CASE WHEN lft > num
                     THEN lft + 2
                     ELSE lft END,
            rgt = CASE WHEN rgt >= num
                     THEN rgt + 2
                     ELSE rgt END
        WHERE tree_id=cur_tree_id AND rgt >= num;

        INSERT INTO component(tree_id, id, lft, rgt)
        VALUES (cur_tree_id,NULL, num, (num + 1));

    END IF;

    SELECT LAST_INSERT_ID() INTO new_id;

    COMMIT;

  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_Close_Gaps`(
    IN choosen_tree INTEGER UNSIGNED)
    DETERMINISTIC
BEGIN
  
    UPDATE component
    SET lft = (SELECT COUNT(*)
               FROM (
                     SELECT lft as seq_nbr FROM component WHERE tree_id=choosen_tree
                     UNION ALL
                     SELECT rgt FROM component WHERE tree_id=choosen_tree
                    ) AS LftRgt
               WHERE tree_id=choosen_tree AND seq_nbr <= lft
              ),
        rgt = (SELECT COUNT(*)
               FROM (
                     SELECT lft as seq_nbr FROM component WHERE tree_id=choosen_tree
                     UNION ALL
                     SELECT rgt FROM component WHERE tree_id=choosen_tree
                    ) AS LftRgt
               WHERE tree_id=choosen_tree AND seq_nbr <= rgt
              )
    WHERE tree_id=choosen_tree;
  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_DropTree`(
                    IN node INTEGER UNSIGNED,
                    IN update_numbers INTEGER)
    MODIFIES SQL DATA
    DETERMINISTIC
BEGIN
    
    DECLARE drop_tree_id INTEGER UNSIGNED;
    DECLARE drop_id INTEGER UNSIGNED;
    DECLARE drop_lft INTEGER UNSIGNED;
    DECLARE drop_rgt INTEGER UNSIGNED;
    

    /*
    declare exit handler for not found rollback;
    declare exit handler for sqlexception rollback;
    declare exit handler for sqlwarning rollback;
    */

    /* save the dropped subtree data with a singleton SELECT */

    START TRANSACTION;

    /* save the dropped subtree data with a singleton SELECT */

    SELECT tree_id, id, lft, rgt
    INTO drop_tree_id, drop_id, drop_lft, drop_rgt
    FROM component
    WHERE id = node;

    /* subtree deletion is easy */

    DELETE FROM component
    WHERE tree_id=drop_tree_id AND lft BETWEEN drop_lft and drop_rgt;
    
    IF update_numbers = 1 THEN
        /* close up the gap left by the subtree */
        
        UPDATE component
        SET lft = CASE WHEN lft > drop_lft
                THEN lft - (drop_rgt - drop_lft + 1)
                ELSE lft END,
          rgt = CASE WHEN rgt > drop_lft
                THEN rgt - (drop_rgt - drop_lft + 1)
                ELSE rgt END
        WHERE tree_id=drop_tree_id AND lft > drop_lft OR rgt > drop_lft;
        
    END IF;

    COMMIT;

  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_getNthChild`(
            IN parent_id INTEGER UNSIGNED,
            IN idx INTEGER,
            OUT nth_child INTEGER UNSIGNED,
            OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
main:BEGIN

    DECLARE num_children INTEGER;
    
    SET error_code=0;

    SELECT COUNT(*)
    INTO num_children
    FROM component_AdjTree WHERE parent = parent_id;

    IF num_children = 0 OR IF(idx<0,(-idx)-1,idx) >= num_children THEN
        /* idx is out of range */
        BEGIN
            SELECT Baobab_getErrCode('INDEX_OUT_OF_RANGE') INTO error_code;
            LEAVE main;
        END;
    ELSE

        SELECT child
        INTO nth_child
        FROM component_AdjTree as t1
        WHERE (SELECT count(*) FROM component_AdjTree as t2
               WHERE parent = parent_id AND t2.lft<=t1.lft AND t1.tree_id=t2.tree_id
              )
              = (CASE
                  WHEN idx >= 0
                  THEN idx+1
                  ELSE num_children+1+idx
                 END
                )
        LIMIT 1;
    
    END IF;

  END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_insertAfter`(
            IN sibling_id INTEGER UNSIGNED,
            OUT new_id INTEGER UNSIGNED,
            OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
main:BEGIN
    
    IF 1 = (SELECT lft FROM component WHERE id = sibling_id) THEN
        BEGIN
            SELECT Baobab_getErrCode('ROOT_ERROR') INTO error_code;
            LEAVE main;
        END;
    ELSE
        BEGIN

          DECLARE lft_sibling INTEGER UNSIGNED;
          DECLARE choosen_tree INTEGER UNSIGNED;

          START TRANSACTION;

          SELECT tree_id,rgt
          INTO choosen_tree,lft_sibling
          FROM component
          WHERE id = sibling_id;
          
          IF ISNULL(lft_sibling) THEN
              BEGIN
                SELECT Baobab_getErrCode('NODE_DOES_NOT_EXIST') INTO error_code;
                LEAVE main;
              END;
          END IF;

          UPDATE component
          SET lft = CASE WHEN lft < lft_sibling
                         THEN lft
                         ELSE lft + 2 END,
              rgt = CASE WHEN rgt < lft_sibling
                         THEN rgt
                         ELSE rgt + 2 END
          WHERE tree_id=choosen_tree AND rgt > lft_sibling;

          INSERT INTO component(tree_id,id,lft,rgt)
          VALUES (choosen_tree,NULL, (lft_sibling + 1),(lft_sibling + 2));

          SELECT LAST_INSERT_ID() INTO new_id;

          COMMIT;

        END;
    END IF;

  END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_insertBefore`(
            IN sibling_id INTEGER UNSIGNED,
            OUT new_id INTEGER UNSIGNED,
            OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
main:BEGIN

    IF 1 = (SELECT lft FROM component WHERE id = sibling_id) THEN
        BEGIN
            SELECT Baobab_getErrCode('ROOT_ERROR') INTO error_code;
            LEAVE main;
        END;
    ELSE
      BEGIN

        DECLARE rgt_sibling INTEGER UNSIGNED;
        DECLARE choosen_tree INTEGER UNSIGNED;

        START TRANSACTION;

        SELECT tree_id,lft
        INTO choosen_tree,rgt_sibling
        FROM component
        WHERE id = sibling_id;
        
        IF ISNULL(rgt_sibling) THEN
            BEGIN
                SELECT Baobab_getErrCode('NODE_DOES_NOT_EXIST') INTO error_code;
                LEAVE main;
            END;
        END IF;

        UPDATE IGNORE component
        SET lft = CASE WHEN lft < rgt_sibling
                     THEN lft
                     ELSE lft + 2 END,
            rgt = CASE WHEN rgt < rgt_sibling
                     THEN rgt
                     ELSE rgt + 2 END
        WHERE tree_id=choosen_tree AND rgt >= rgt_sibling
        ORDER BY lft DESC; /* order by is meant to avoid uniqueness violation on update */

        INSERT INTO component(tree_id,id,lft,rgt)
        VALUES (choosen_tree,NULL, rgt_sibling, rgt_sibling + 1);

        SELECT LAST_INSERT_ID() INTO new_id;

        COMMIT;

      END;
    END IF;

END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_InsertChildAtIndex`(
            IN parent_id INTEGER UNSIGNED,
            IN idx INTEGER,
            OUT new_id INTEGER UNSIGNED,
            OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
BEGIN
    
    DECLARE nth_child INTEGER UNSIGNED;
    DECLARE cur_tree_id INTEGER UNSIGNED;
    
    SET error_code=0;
    SET new_id=0;

    CALL Baobab_component_getNthChild(parent_id,idx,nth_child,error_code);
    
    IF NOT error_code THEN
        CALL Baobab_component_insertBefore(nth_child,new_id,error_code);
    ELSE IF idx = 0 AND error_code = (SELECT Baobab_getErrCode('INDEX_OUT_OF_RANGE')) THEN
        BEGIN
          SET error_code = 0;
          CALL Baobab_component_AppendChild((SELECT tree_id FROM component WHERE id = parent_id),
                                           parent_id,
                                           new_id,
                                           cur_tree_id);
        END;
      END IF;
    END IF;
    
  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_MoveSubtreeAfter`(
        IN node_id_to_move INTEGER UNSIGNED,
        IN reference_node INTEGER UNSIGNED,
        OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
BEGIN
    
    SELECT 0 INTO error_code; /* 0 means no error */
    
    CALL Baobab_component_MoveSubtree_real(
        node_id_to_move,reference_node,FALSE,error_code
    );

  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_MoveSubtreeAtIndex`(
        IN node_id_to_move INTEGER UNSIGNED,
        IN parent_id INTEGER UNSIGNED,
        IN idx INTEGER,
        OUT error_code INTEGER)
    DETERMINISTIC
main:BEGIN

    DECLARE nth_child INTEGER UNSIGNED;
    DECLARE num_children INTEGER;
    DECLARE parent_of_node_to_move INTEGER UNSIGNED;
    DECLARE s_lft INTEGER UNSIGNED;
    DECLARE current_idx INTEGER;
    
    SET error_code=0;

    SELECT COUNT(*)
    INTO num_children
    FROM component_AdjTree WHERE parent = parent_id;

    IF idx < 0 THEN
        SET idx = num_children + idx;
    ELSEIF idx > 0 THEN BEGIN

        SELECT parent, lft
        INTO parent_of_node_to_move, s_lft
        FROM component_AdjTree WHERE child = node_id_to_move;

        IF parent_of_node_to_move = parent_id THEN BEGIN
            SELECT count(*)
            INTO current_idx
            FROM component_AdjTree
            WHERE parent = parent_id AND lft < s_lft;

            IF idx > current_idx THEN
                SET idx = idx + 1;
            END IF;
          END;
        END IF;

      END;
    END IF;
    
    SET idx = IF(idx<0,num_children+idx,idx);
    
    IF idx = 0 THEN /* moving as first child, special case */
        CALL Baobab_component_MoveSubtree_real(node_id_to_move,parent_id,TRUE,error_code);
    ELSE
      BEGIN
        /* search the node before idx, and we wil move our node after that */
        CALL Baobab_component_getNthChild(parent_id,idx-1,nth_child,error_code);

        IF NOT error_code THEN
            CALL Baobab_component_MoveSubtree_real(node_id_to_move,nth_child,FALSE,error_code);
        END IF;
      END;
    END IF;

  END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_MoveSubtreeBefore`(
        IN node_id_to_move INTEGER UNSIGNED,
        IN reference_node INTEGER UNSIGNED,
        OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
main:BEGIN
  
    DECLARE node_revised INTEGER UNSIGNED;
    DECLARE move_as_first_sibling BOOLEAN;
    DECLARE ref_left INTEGER UNSIGNED;
    DECLARE ref_node_tree INTEGER UNSIGNED;
    
    SET error_code=0; /* 0 means no error */
    SET move_as_first_sibling = TRUE;
    
    SELECT tree_id,lft
    INTO ref_node_tree,ref_left
    FROM component WHERE id = reference_node;
    
    IF ref_left = 1 THEN
        BEGIN
            /* cannot move a parent node before or after root */
            SELECT Baobab_getErrCode('ROOT_ERROR') INTO error_code;
            LEAVE main;
        END;
    END IF;
    
    /* if reference_node is the first child of his parent, set node_revised
       to the parent id, else set node_revised to NULL */
    SET node_revised = ( SELECT id FROM component WHERE tree_id=ref_node_tree AND lft = -1+ ref_left);
    
    IF ISNULL(node_revised) THEN    /* if node_revised is NULL we must find the previous sibling */
      BEGIN
        SET node_revised= (SELECT id FROM component
                           WHERE tree_id=ref_node_tree AND rgt = -1 + ref_left);
        SET move_as_first_sibling = FALSE;
      END;
    END IF;
    
    CALL Baobab_component_MoveSubtree_real(
        node_id_to_move, node_revised , move_as_first_sibling, error_code
    );

  END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_MoveSubtree_Different_Trees`(
        IN node_id_to_move INTEGER UNSIGNED,
        IN reference_node INTEGER UNSIGNED,
        IN move_as_first_sibling BOOLEAN
        )
    DETERMINISTIC
main:BEGIN
  
    DECLARE s_lft INTEGER UNSIGNED;
    DECLARE s_rgt INTEGER UNSIGNED;
    DECLARE ref_lft INTEGER UNSIGNED;
    DECLARE ref_rgt INTEGER UNSIGNED;
    
    DECLARE source_node_tree INTEGER UNSIGNED;
    DECLARE ref_node_tree INTEGER UNSIGNED;
    
    START TRANSACTION;

    /* select tree, left and right of the node to move */
    SELECT tree_id,lft, rgt
    INTO source_node_tree, s_lft, s_rgt
    FROM component
    WHERE id = node_id_to_move;
    
    /* The current select will behave differently whether we're moving
       the node as first sibling or not.
        
       If move_as_first_sibling,
         ref_lft will have the value of the "lft" field of node_id_to_move at end
            of move (ref_rgt here is discarded)
       else
         ref_lft and ref_rgt will have the values of the node before node_id_to_move
            at end of move
    */
    SELECT tree_id, IF(move_as_first_sibling,lft+1,lft), rgt
    INTO ref_node_tree, ref_lft, ref_rgt
    FROM component
    WHERE id = reference_node;
    
    IF (move_as_first_sibling) THEN BEGIN
        
        /* create a gap in the destination tree to hold the subtree */
        UPDATE component
        SET lft = CASE WHEN lft < ref_lft
                       THEN lft
                       ELSE lft + s_rgt-s_lft+1 END,
            rgt = CASE WHEN rgt < ref_lft
                       THEN rgt
                       ELSE rgt + s_rgt-s_lft+1 END
        WHERE tree_id=ref_node_tree AND rgt >= ref_lft;
        
        /* move the subtree to the new tree */
        UPDATE component
        SET lft = ref_lft + (lft-s_lft),
            rgt = ref_lft + (rgt-s_lft),
            tree_id = ref_node_tree
        WHERE tree_id = source_node_tree AND lft >= s_lft AND rgt <= s_rgt;
        
        END;
    ELSE BEGIN
        
        /* create a gap in the destination tree to hold the subtree */
        UPDATE component
        SET lft = CASE WHEN lft < ref_rgt
                       THEN lft
                       ELSE lft + s_rgt-s_lft+1 END,
            rgt = CASE WHEN rgt <= ref_rgt
                       THEN rgt
                       ELSE rgt + s_rgt-s_lft+1 END
        WHERE tree_id=ref_node_tree AND rgt > ref_rgt;
        
        /* move the subtree to the new tree */
        UPDATE component
        SET lft = ref_rgt+1 + (lft-s_lft),
            rgt = ref_rgt+1 + (rgt-s_lft),
            tree_id = ref_node_tree
        WHERE tree_id = source_node_tree AND lft >= s_lft AND rgt <= s_rgt;
    
        END;
    
    END IF;
    
    /* close the gap in the source tree */
    CALL Baobab_component_Close_Gaps(source_node_tree);
    
    COMMIT;
  
  END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_component_MoveSubtree_real`(
        IN node_id_to_move INTEGER UNSIGNED,
        IN reference_node INTEGER UNSIGNED,
        IN move_as_first_sibling BOOLEAN,
        OUT error_code INTEGER
        )
    DETERMINISTIC
main:BEGIN

    DECLARE s_lft INTEGER UNSIGNED;
    DECLARE s_rgt INTEGER UNSIGNED;
    DECLARE ref_lft INTEGER UNSIGNED;
    DECLARE ref_rgt INTEGER UNSIGNED;
    
    DECLARE source_node_tree INTEGER UNSIGNED;
    DECLARE ref_node_tree INTEGER UNSIGNED;
    
    DECLARE diff_when_inside_sourcetree BIGINT SIGNED;
    DECLARE diff_when_next_sourcetree BIGINT SIGNED;
    DECLARE ext_bound_1 INTEGER UNSIGNED;
    DECLARE ext_bound_2 INTEGER UNSIGNED;
    
    SET error_code=0;
    
    START TRANSACTION;

    /* select tree, left and right of the node to move */
    SELECT tree_id,lft, rgt
    INTO source_node_tree, s_lft, s_rgt
    FROM component
    WHERE id = node_id_to_move;
    
    /* select left and right of the reference node
        
        If moving as first sibling, ref_lft will become the new lft value of node_id_to_move,
         (and ref_rgt is unused), else we're saving left and right value of soon to be
         previous sibling
    
    */
    SELECT tree_id, IF(move_as_first_sibling,lft+1,lft), rgt
    INTO ref_node_tree, ref_lft, ref_rgt
    FROM component
    WHERE id = reference_node;
    
    
    IF move_as_first_sibling = TRUE THEN
        
        IF s_lft <= ref_lft AND s_rgt >= ref_rgt AND source_node_tree=ref_node_tree THEN
            /* cannot move a parent node inside his own subtree */
            BEGIN
                SELECT Baobab_getErrCode('CHILD_OF_YOURSELF_ERROR') INTO error_code;
                LEAVE main;
            END;
        ELSE
                
            IF s_lft > ref_lft THEN BEGIN
                SET diff_when_inside_sourcetree = -(s_lft-ref_lft);
                SET diff_when_next_sourcetree = s_rgt-s_lft+1;
                SET ext_bound_1 = ref_lft;
                SET ext_bound_2 = s_lft-1;
                
                END;
            ELSEIF s_lft = ref_lft THEN BEGIN
                /* we have been asked to move a node to his same position */
                LEAVE main;
                END;
            ELSE BEGIN
                SET diff_when_inside_sourcetree = ref_lft-s_rgt-1;
                SET diff_when_next_sourcetree = -(s_rgt-s_lft+1);
                SET ext_bound_1 = s_rgt+1;
                SET ext_bound_2 = ref_lft-1;
               
                END;
            END IF;
            
        END IF;
    ELSE    /* moving after an existing child */
        
        IF ref_lft = 1 THEN /* cannot move a node before or after root */
            BEGIN
                SELECT Baobab_getErrCode('ROOT_ERROR') INTO error_code;
                LEAVE main;
            END;
        ELSEIF s_lft < ref_lft AND s_rgt > ref_rgt AND source_node_tree=ref_node_tree THEN
            /* cannot move a parent node inside his own subtree */
            BEGIN
                SELECT Baobab_getErrCode('CHILD_OF_YOURSELF_ERROR') INTO error_code;
                LEAVE main;
            END;
        ELSE
            
            IF s_lft > ref_rgt THEN BEGIN
                SET diff_when_inside_sourcetree = -(s_lft-ref_rgt-1);
                SET diff_when_next_sourcetree = s_rgt-s_lft+1;
                SET ext_bound_1 = ref_rgt+1;
                SET ext_bound_2 = s_lft-1;
               
                END;
            ELSE BEGIN
                SET diff_when_inside_sourcetree = ref_rgt-s_rgt;
                SET diff_when_next_sourcetree = -(s_rgt-s_lft+1);
                SET ext_bound_1 = s_rgt+1;
                SET ext_bound_2 = ref_rgt;
               
                END;
            END IF;
            
        END IF;

    END IF;
    
    
    IF source_node_tree <> ref_node_tree THEN
        BEGIN
            CALL Baobab_component_MoveSubtree_Different_Trees(
                node_id_to_move,reference_node,move_as_first_sibling);
            LEAVE main;
        END;
    END IF;
    
    UPDATE component
    SET lft =
        lft + CASE
          WHEN lft BETWEEN s_lft AND s_rgt
          THEN diff_when_inside_sourcetree
          WHEN lft BETWEEN ext_bound_1 AND ext_bound_2
          THEN diff_when_next_sourcetree
          ELSE 0 END
        ,
        rgt =
        rgt + CASE
          
          WHEN rgt BETWEEN s_lft AND s_rgt
          THEN diff_when_inside_sourcetree
          WHEN rgt BETWEEN ext_bound_1 AND ext_bound_2
          THEN diff_when_next_sourcetree
          ELSE 0 END
    WHERE tree_id=source_node_tree;

    COMMIT;
    
  END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_AppendChild`(
            IN choosen_tree INTEGER UNSIGNED,
            IN parent_id INTEGER UNSIGNED,
            OUT new_id INTEGER UNSIGNED,
            OUT cur_tree_id INTEGER UNSIGNED)
    DETERMINISTIC
BEGIN

    DECLARE num INTEGER UNSIGNED;

    START TRANSACTION;
    
    SET cur_tree_id = IF(choosen_tree > 0,
                         choosen_tree,
                         IFNULL((SELECT MAX(tree_id)+1 FROM tree),1)
                        );
    
    IF parent_id = 0 THEN /* inserting a new root node*/

        UPDATE tree
        SET lft = lft+1, rgt = rgt+1
        WHERE tree_id=cur_tree_id;

        SET num = IFNULL((SELECT MAX(rgt)+1 FROM tree WHERE tree_id=cur_tree_id),2);

        INSERT INTO tree(tree_id, id, lft, rgt)
        VALUES (cur_tree_id, NULL, 1, num);

    ELSE /* append a new node as last right child of his parent */
        
        SET num = (SELECT rgt
                   FROM tree
                   WHERE id = parent_id
                  );

        UPDATE tree
        SET lft = CASE WHEN lft > num
                     THEN lft + 2
                     ELSE lft END,
            rgt = CASE WHEN rgt >= num
                     THEN rgt + 2
                     ELSE rgt END
        WHERE tree_id=cur_tree_id AND rgt >= num;

        INSERT INTO tree(tree_id, id, lft, rgt)
        VALUES (cur_tree_id,NULL, num, (num + 1));

    END IF;

    SELECT LAST_INSERT_ID() INTO new_id;

    COMMIT;

  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_Close_Gaps`(
    IN choosen_tree INTEGER UNSIGNED)
    DETERMINISTIC
BEGIN
  
    UPDATE tree
    SET lft = (SELECT COUNT(*)
               FROM (
                     SELECT lft as seq_nbr FROM tree WHERE tree_id=choosen_tree
                     UNION ALL
                     SELECT rgt FROM tree WHERE tree_id=choosen_tree
                    ) AS LftRgt
               WHERE tree_id=choosen_tree AND seq_nbr <= lft
              ),
        rgt = (SELECT COUNT(*)
               FROM (
                     SELECT lft as seq_nbr FROM tree WHERE tree_id=choosen_tree
                     UNION ALL
                     SELECT rgt FROM tree WHERE tree_id=choosen_tree
                    ) AS LftRgt
               WHERE tree_id=choosen_tree AND seq_nbr <= rgt
              )
    WHERE tree_id=choosen_tree;
  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_DropTree`(
                    IN node INTEGER UNSIGNED,
                    IN update_numbers INTEGER)
    MODIFIES SQL DATA
    DETERMINISTIC
BEGIN
    
    DECLARE drop_tree_id INTEGER UNSIGNED;
    DECLARE drop_id INTEGER UNSIGNED;
    DECLARE drop_lft INTEGER UNSIGNED;
    DECLARE drop_rgt INTEGER UNSIGNED;
    

    /*
    declare exit handler for not found rollback;
    declare exit handler for sqlexception rollback;
    declare exit handler for sqlwarning rollback;
    */

    /* save the dropped subtree data with a singleton SELECT */

    START TRANSACTION;

    /* save the dropped subtree data with a singleton SELECT */

    SELECT tree_id, id, lft, rgt
    INTO drop_tree_id, drop_id, drop_lft, drop_rgt
    FROM tree
    WHERE id = node;

    /* subtree deletion is easy */

    DELETE FROM tree
    WHERE tree_id=drop_tree_id AND lft BETWEEN drop_lft and drop_rgt;
    
    IF update_numbers = 1 THEN
        /* close up the gap left by the subtree */
        
        UPDATE tree
        SET lft = CASE WHEN lft > drop_lft
                THEN lft - (drop_rgt - drop_lft + 1)
                ELSE lft END,
          rgt = CASE WHEN rgt > drop_lft
                THEN rgt - (drop_rgt - drop_lft + 1)
                ELSE rgt END
        WHERE tree_id=drop_tree_id AND lft > drop_lft OR rgt > drop_lft;
        
    END IF;

    COMMIT;

  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_getNthChild`(
            IN parent_id INTEGER UNSIGNED,
            IN idx INTEGER,
            OUT nth_child INTEGER UNSIGNED,
            OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
main:BEGIN

    DECLARE num_children INTEGER;
    
    SET error_code=0;

    SELECT COUNT(*)
    INTO num_children
    FROM tree_AdjTree WHERE parent = parent_id;

    IF num_children = 0 OR IF(idx<0,(-idx)-1,idx) >= num_children THEN
        /* idx is out of range */
        BEGIN
            SELECT Baobab_getErrCode('INDEX_OUT_OF_RANGE') INTO error_code;
            LEAVE main;
        END;
    ELSE

        SELECT child
        INTO nth_child
        FROM tree_AdjTree as t1
        WHERE (SELECT count(*) FROM tree_AdjTree as t2
               WHERE parent = parent_id AND t2.lft<=t1.lft AND t1.tree_id=t2.tree_id
              )
              = (CASE
                  WHEN idx >= 0
                  THEN idx+1
                  ELSE num_children+1+idx
                 END
                )
        LIMIT 1;
    
    END IF;

  END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_insertAfter`(
            IN sibling_id INTEGER UNSIGNED,
            OUT new_id INTEGER UNSIGNED,
            OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
main:BEGIN
    
    IF 1 = (SELECT lft FROM tree WHERE id = sibling_id) THEN
        BEGIN
            SELECT Baobab_getErrCode('ROOT_ERROR') INTO error_code;
            LEAVE main;
        END;
    ELSE
        BEGIN

          DECLARE lft_sibling INTEGER UNSIGNED;
          DECLARE choosen_tree INTEGER UNSIGNED;

          START TRANSACTION;

          SELECT tree_id,rgt
          INTO choosen_tree,lft_sibling
          FROM tree
          WHERE id = sibling_id;
          
          IF ISNULL(lft_sibling) THEN
              BEGIN
                SELECT Baobab_getErrCode('NODE_DOES_NOT_EXIST') INTO error_code;
                LEAVE main;
              END;
          END IF;

          UPDATE tree
          SET lft = CASE WHEN lft < lft_sibling
                         THEN lft
                         ELSE lft + 2 END,
              rgt = CASE WHEN rgt < lft_sibling
                         THEN rgt
                         ELSE rgt + 2 END
          WHERE tree_id=choosen_tree AND rgt > lft_sibling;

          INSERT INTO tree(tree_id,id,lft,rgt)
          VALUES (choosen_tree,NULL, (lft_sibling + 1),(lft_sibling + 2));

          SELECT LAST_INSERT_ID() INTO new_id;

          COMMIT;

        END;
    END IF;

  END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_insertBefore`(
            IN sibling_id INTEGER UNSIGNED,
            OUT new_id INTEGER UNSIGNED,
            OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
main:BEGIN

    IF 1 = (SELECT lft FROM tree WHERE id = sibling_id) THEN
        BEGIN
            SELECT Baobab_getErrCode('ROOT_ERROR') INTO error_code;
            LEAVE main;
        END;
    ELSE
      BEGIN

        DECLARE rgt_sibling INTEGER UNSIGNED;
        DECLARE choosen_tree INTEGER UNSIGNED;

        START TRANSACTION;

        SELECT tree_id,lft
        INTO choosen_tree,rgt_sibling
        FROM tree
        WHERE id = sibling_id;
        
        IF ISNULL(rgt_sibling) THEN
            BEGIN
                SELECT Baobab_getErrCode('NODE_DOES_NOT_EXIST') INTO error_code;
                LEAVE main;
            END;
        END IF;

        UPDATE IGNORE tree
        SET lft = CASE WHEN lft < rgt_sibling
                     THEN lft
                     ELSE lft + 2 END,
            rgt = CASE WHEN rgt < rgt_sibling
                     THEN rgt
                     ELSE rgt + 2 END
        WHERE tree_id=choosen_tree AND rgt >= rgt_sibling
        ORDER BY lft DESC; /* order by is meant to avoid uniqueness violation on update */

        INSERT INTO tree(tree_id,id,lft,rgt)
        VALUES (choosen_tree,NULL, rgt_sibling, rgt_sibling + 1);

        SELECT LAST_INSERT_ID() INTO new_id;

        COMMIT;

      END;
    END IF;

END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_InsertChildAtIndex`(
            IN parent_id INTEGER UNSIGNED,
            IN idx INTEGER,
            OUT new_id INTEGER UNSIGNED,
            OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
BEGIN
    
    DECLARE nth_child INTEGER UNSIGNED;
    DECLARE cur_tree_id INTEGER UNSIGNED;
    
    SET error_code=0;
    SET new_id=0;

    CALL Baobab_tree_getNthChild(parent_id,idx,nth_child,error_code);
    
    IF NOT error_code THEN
        CALL Baobab_tree_insertBefore(nth_child,new_id,error_code);
    ELSE IF idx = 0 AND error_code = (SELECT Baobab_getErrCode('INDEX_OUT_OF_RANGE')) THEN
        BEGIN
          SET error_code = 0;
          CALL Baobab_tree_AppendChild((SELECT tree_id FROM tree WHERE id = parent_id),
                                           parent_id,
                                           new_id,
                                           cur_tree_id);
        END;
      END IF;
    END IF;
    
  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_MoveSubtreeAfter`(
        IN node_id_to_move INTEGER UNSIGNED,
        IN reference_node INTEGER UNSIGNED,
        OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
BEGIN
    
    SELECT 0 INTO error_code; /* 0 means no error */
    
    CALL Baobab_tree_MoveSubtree_real(
        node_id_to_move,reference_node,FALSE,error_code
    );

  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_MoveSubtreeAtIndex`(
        IN node_id_to_move INTEGER UNSIGNED,
        IN parent_id INTEGER UNSIGNED,
        IN idx INTEGER,
        OUT error_code INTEGER)
    DETERMINISTIC
main:BEGIN

    DECLARE nth_child INTEGER UNSIGNED;
    DECLARE num_children INTEGER;
    DECLARE parent_of_node_to_move INTEGER UNSIGNED;
    DECLARE s_lft INTEGER UNSIGNED;
    DECLARE current_idx INTEGER;
    
    SET error_code=0;

    SELECT COUNT(*)
    INTO num_children
    FROM tree_AdjTree WHERE parent = parent_id;

    IF idx < 0 THEN
        SET idx = num_children + idx;
    ELSEIF idx > 0 THEN BEGIN

        SELECT parent, lft
        INTO parent_of_node_to_move, s_lft
        FROM tree_AdjTree WHERE child = node_id_to_move;

        IF parent_of_node_to_move = parent_id THEN BEGIN
            SELECT count(*)
            INTO current_idx
            FROM tree_AdjTree
            WHERE parent = parent_id AND lft < s_lft;

            IF idx > current_idx THEN
                SET idx = idx + 1;
            END IF;
          END;
        END IF;

      END;
    END IF;
    
    SET idx = IF(idx<0,num_children+idx,idx);
    
    IF idx = 0 THEN /* moving as first child, special case */
        CALL Baobab_tree_MoveSubtree_real(node_id_to_move,parent_id,TRUE,error_code);
    ELSE
      BEGIN
        /* search the node before idx, and we wil move our node after that */
        CALL Baobab_tree_getNthChild(parent_id,idx-1,nth_child,error_code);

        IF NOT error_code THEN
            CALL Baobab_tree_MoveSubtree_real(node_id_to_move,nth_child,FALSE,error_code);
        END IF;
      END;
    END IF;

  END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_MoveSubtreeBefore`(
        IN node_id_to_move INTEGER UNSIGNED,
        IN reference_node INTEGER UNSIGNED,
        OUT error_code INTEGER UNSIGNED)
    DETERMINISTIC
main:BEGIN
  
    DECLARE node_revised INTEGER UNSIGNED;
    DECLARE move_as_first_sibling BOOLEAN;
    DECLARE ref_left INTEGER UNSIGNED;
    DECLARE ref_node_tree INTEGER UNSIGNED;
    
    SET error_code=0; /* 0 means no error */
    SET move_as_first_sibling = TRUE;
    
    SELECT tree_id,lft
    INTO ref_node_tree,ref_left
    FROM tree WHERE id = reference_node;
    
    IF ref_left = 1 THEN
        BEGIN
            /* cannot move a parent node before or after root */
            SELECT Baobab_getErrCode('ROOT_ERROR') INTO error_code;
            LEAVE main;
        END;
    END IF;
    
    /* if reference_node is the first child of his parent, set node_revised
       to the parent id, else set node_revised to NULL */
    SET node_revised = ( SELECT id FROM tree WHERE tree_id=ref_node_tree AND lft = -1+ ref_left);
    
    IF ISNULL(node_revised) THEN    /* if node_revised is NULL we must find the previous sibling */
      BEGIN
        SET node_revised= (SELECT id FROM tree
                           WHERE tree_id=ref_node_tree AND rgt = -1 + ref_left);
        SET move_as_first_sibling = FALSE;
      END;
    END IF;
    
    CALL Baobab_tree_MoveSubtree_real(
        node_id_to_move, node_revised , move_as_first_sibling, error_code
    );

  END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_MoveSubtree_Different_Trees`(
        IN node_id_to_move INTEGER UNSIGNED,
        IN reference_node INTEGER UNSIGNED,
        IN move_as_first_sibling BOOLEAN
        )
    DETERMINISTIC
main:BEGIN
  
    DECLARE s_lft INTEGER UNSIGNED;
    DECLARE s_rgt INTEGER UNSIGNED;
    DECLARE ref_lft INTEGER UNSIGNED;
    DECLARE ref_rgt INTEGER UNSIGNED;
    
    DECLARE source_node_tree INTEGER UNSIGNED;
    DECLARE ref_node_tree INTEGER UNSIGNED;
    
    START TRANSACTION;

    /* select tree, left and right of the node to move */
    SELECT tree_id,lft, rgt
    INTO source_node_tree, s_lft, s_rgt
    FROM tree
    WHERE id = node_id_to_move;
    
    /* The current select will behave differently whether we're moving
       the node as first sibling or not.
        
       If move_as_first_sibling,
         ref_lft will have the value of the "lft" field of node_id_to_move at end
            of move (ref_rgt here is discarded)
       else
         ref_lft and ref_rgt will have the values of the node before node_id_to_move
            at end of move
    */
    SELECT tree_id, IF(move_as_first_sibling,lft+1,lft), rgt
    INTO ref_node_tree, ref_lft, ref_rgt
    FROM tree
    WHERE id = reference_node;
    
    IF (move_as_first_sibling) THEN BEGIN
        
        /* create a gap in the destination tree to hold the subtree */
        UPDATE tree
        SET lft = CASE WHEN lft < ref_lft
                       THEN lft
                       ELSE lft + s_rgt-s_lft+1 END,
            rgt = CASE WHEN rgt < ref_lft
                       THEN rgt
                       ELSE rgt + s_rgt-s_lft+1 END
        WHERE tree_id=ref_node_tree AND rgt >= ref_lft;
        
        /* move the subtree to the new tree */
        UPDATE tree
        SET lft = ref_lft + (lft-s_lft),
            rgt = ref_lft + (rgt-s_lft),
            tree_id = ref_node_tree
        WHERE tree_id = source_node_tree AND lft >= s_lft AND rgt <= s_rgt;
        
        END;
    ELSE BEGIN
        
        /* create a gap in the destination tree to hold the subtree */
        UPDATE tree
        SET lft = CASE WHEN lft < ref_rgt
                       THEN lft
                       ELSE lft + s_rgt-s_lft+1 END,
            rgt = CASE WHEN rgt <= ref_rgt
                       THEN rgt
                       ELSE rgt + s_rgt-s_lft+1 END
        WHERE tree_id=ref_node_tree AND rgt > ref_rgt;
        
        /* move the subtree to the new tree */
        UPDATE tree
        SET lft = ref_rgt+1 + (lft-s_lft),
            rgt = ref_rgt+1 + (rgt-s_lft),
            tree_id = ref_node_tree
        WHERE tree_id = source_node_tree AND lft >= s_lft AND rgt <= s_rgt;
    
        END;
    
    END IF;
    
    /* close the gap in the source tree */
    CALL Baobab_tree_Close_Gaps(source_node_tree);
    
    COMMIT;
  
  END;$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Baobab_tree_MoveSubtree_real`(
        IN node_id_to_move INTEGER UNSIGNED,
        IN reference_node INTEGER UNSIGNED,
        IN move_as_first_sibling BOOLEAN,
        OUT error_code INTEGER
        )
    DETERMINISTIC
main:BEGIN

    DECLARE s_lft INTEGER UNSIGNED;
    DECLARE s_rgt INTEGER UNSIGNED;
    DECLARE ref_lft INTEGER UNSIGNED;
    DECLARE ref_rgt INTEGER UNSIGNED;
    
    DECLARE source_node_tree INTEGER UNSIGNED;
    DECLARE ref_node_tree INTEGER UNSIGNED;
    
    DECLARE diff_when_inside_sourcetree BIGINT SIGNED;
    DECLARE diff_when_next_sourcetree BIGINT SIGNED;
    DECLARE ext_bound_1 INTEGER UNSIGNED;
    DECLARE ext_bound_2 INTEGER UNSIGNED;
    
    SET error_code=0;
    
    START TRANSACTION;

    /* select tree, left and right of the node to move */
    SELECT tree_id,lft, rgt
    INTO source_node_tree, s_lft, s_rgt
    FROM tree
    WHERE id = node_id_to_move;
    
    /* select left and right of the reference node
        
        If moving as first sibling, ref_lft will become the new lft value of node_id_to_move,
         (and ref_rgt is unused), else we're saving left and right value of soon to be
         previous sibling
    
    */
    SELECT tree_id, IF(move_as_first_sibling,lft+1,lft), rgt
    INTO ref_node_tree, ref_lft, ref_rgt
    FROM tree
    WHERE id = reference_node;
    
    
    IF move_as_first_sibling = TRUE THEN
        
        IF s_lft <= ref_lft AND s_rgt >= ref_rgt AND source_node_tree=ref_node_tree THEN
            /* cannot move a parent node inside his own subtree */
            BEGIN
                SELECT Baobab_getErrCode('CHILD_OF_YOURSELF_ERROR') INTO error_code;
                LEAVE main;
            END;
        ELSE
                
            IF s_lft > ref_lft THEN BEGIN
                SET diff_when_inside_sourcetree = -(s_lft-ref_lft);
                SET diff_when_next_sourcetree = s_rgt-s_lft+1;
                SET ext_bound_1 = ref_lft;
                SET ext_bound_2 = s_lft-1;
                
                END;
            ELSEIF s_lft = ref_lft THEN BEGIN
                /* we have been asked to move a node to his same position */
                LEAVE main;
                END;
            ELSE BEGIN
                SET diff_when_inside_sourcetree = ref_lft-s_rgt-1;
                SET diff_when_next_sourcetree = -(s_rgt-s_lft+1);
                SET ext_bound_1 = s_rgt+1;
                SET ext_bound_2 = ref_lft-1;
               
                END;
            END IF;
            
        END IF;
    ELSE    /* moving after an existing child */
        
        IF ref_lft = 1 THEN /* cannot move a node before or after root */
            BEGIN
                SELECT Baobab_getErrCode('ROOT_ERROR') INTO error_code;
                LEAVE main;
            END;
        ELSEIF s_lft < ref_lft AND s_rgt > ref_rgt AND source_node_tree=ref_node_tree THEN
            /* cannot move a parent node inside his own subtree */
            BEGIN
                SELECT Baobab_getErrCode('CHILD_OF_YOURSELF_ERROR') INTO error_code;
                LEAVE main;
            END;
        ELSE
            
            IF s_lft > ref_rgt THEN BEGIN
                SET diff_when_inside_sourcetree = -(s_lft-ref_rgt-1);
                SET diff_when_next_sourcetree = s_rgt-s_lft+1;
                SET ext_bound_1 = ref_rgt+1;
                SET ext_bound_2 = s_lft-1;
               
                END;
            ELSE BEGIN
                SET diff_when_inside_sourcetree = ref_rgt-s_rgt;
                SET diff_when_next_sourcetree = -(s_rgt-s_lft+1);
                SET ext_bound_1 = s_rgt+1;
                SET ext_bound_2 = ref_rgt;
               
                END;
            END IF;
            
        END IF;

    END IF;
    
    
    IF source_node_tree <> ref_node_tree THEN
        BEGIN
            CALL Baobab_tree_MoveSubtree_Different_Trees(
                node_id_to_move,reference_node,move_as_first_sibling);
            LEAVE main;
        END;
    END IF;
    
    UPDATE tree
    SET lft =
        lft + CASE
          WHEN lft BETWEEN s_lft AND s_rgt
          THEN diff_when_inside_sourcetree
          WHEN lft BETWEEN ext_bound_1 AND ext_bound_2
          THEN diff_when_next_sourcetree
          ELSE 0 END
        ,
        rgt =
        rgt + CASE
          
          WHEN rgt BETWEEN s_lft AND s_rgt
          THEN diff_when_inside_sourcetree
          WHEN rgt BETWEEN ext_bound_1 AND ext_bound_2
          THEN diff_when_next_sourcetree
          ELSE 0 END
    WHERE tree_id=source_node_tree;

    COMMIT;
    
  END;$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `Baobab_getErrCode`(x TINYTEXT) RETURNS int(11)
    DETERMINISTIC
RETURN (SELECT code from Baobab_Errors WHERE name=x);$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `Baobab_Errors`
--

CREATE TABLE IF NOT EXISTS `Baobab_Errors` (
  `code` int(10) unsigned NOT NULL,
  `name` varchar(50) NOT NULL,
  `msg` tinytext NOT NULL,
  PRIMARY KEY (`code`),
  UNIQUE KEY `unique_codename` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `Baobab_Errors`
--

INSERT INTO `Baobab_Errors` (`code`, `name`, `msg`) VALUES
(1000, 'VERSION', '1.3.0'),
(1100, 'ROOT_ERROR', 'Cannot add or move a node next to root'),
(1200, 'CHILD_OF_YOURSELF_ERROR', 'Cannot move a node inside his own subtree'),
(1300, 'INDEX_OUT_OF_RANGE', 'The index is out of range'),
(1400, 'NODE_DOES_NOT_EXIST', 'Node doesn''t exist'),
(1500, 'VERSION_NOT_MATCH', 'The library and the sql schema have different versions');

-- --------------------------------------------------------

--
-- Table structure for table `Baobab_ForestsNames`
--

CREATE TABLE IF NOT EXISTS `Baobab_ForestsNames` (
  `name` varchar(200) NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `Baobab_ForestsNames`
--

INSERT INTO `Baobab_ForestsNames` (`name`) VALUES
('tree');

-- --------------------------------------------------------

--
-- Table structure for table `tree`
--

CREATE TABLE IF NOT EXISTS `tree` (
  `tree_id` int(10) unsigned NOT NULL,
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `lft` int(11) NOT NULL,
  `rgt` int(11) NOT NULL,
  `user_id` int(10) NOT NULL,
  `name` varchar(100) NOT NULL,
  `type` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tree_id` (`tree_id`),
  KEY `lft` (`lft`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `tree_AdjTree`
--
CREATE TABLE IF NOT EXISTS `tree_AdjTree` (
`tree_id` int(10) unsigned
,`parent` int(10) unsigned
,`child` int(10) unsigned
,`lft` int(11)
);
-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE IF NOT EXISTS `user` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=72 ;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`id`, `username`, `password`) VALUES
(71, 'em', '0000');

-- --------------------------------------------------------

--
-- Structure for view `tree_AdjTree`
--
DROP TABLE IF EXISTS `tree_AdjTree`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `tree_AdjTree` AS select `E`.`tree_id` AS `tree_id`,`B`.`id` AS `parent`,`E`.`id` AS `child`,`E`.`lft` AS `lft` from (`tree` `E` left join `tree` `B` on(((`B`.`lft` = (select max(`S`.`lft`) from `tree` `S` where ((`E`.`lft` > `S`.`lft`) and (`E`.`lft` < `S`.`rgt`) and (`E`.`tree_id` = `S`.`tree_id`)))) and (`B`.`tree_id` = `E`.`tree_id`)))) order by `E`.`lft`;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `tree`
--
ALTER TABLE `tree`
  ADD CONSTRAINT `tree_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
