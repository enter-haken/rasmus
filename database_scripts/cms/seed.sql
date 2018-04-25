SET search_path TO cms,public;

DO $$
DECLARE 
    id_jemand UUID;
BEGIN    
    SELECT id INTO id_jemand FROM core.user_account WHERE first_name = 'Jemand'; 
    INSERT INTO article (id_author, title, raw, html) VALUES
        (id_jemand, 'Test article', '# Test Title', '<h1> Test Title </h1>');

    -- categories can be used for a menue
    
    --                1 home 8
    --                   |
    --    +--------------+--------------+  
    --    |              |              |
    -- 2 blog 3 ---- 4 project 5 --- 6 books 7 

    INSERT INTO category (LNUM, RNUM, name, is_active, is_visible) VALUES
        (1,8, 'Home', true, true),
        (2,3, 'Blog', true, true),
        (4,5, 'Project', true, true),
        (6,7, 'Books', true, true);

END
$$ LANGUAGE plpgsql
