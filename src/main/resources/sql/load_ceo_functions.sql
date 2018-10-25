-- Adds a new role to the database.
CREATE OR REPLACE FUNCTION insert_role(_title text)
    RETURNS integer AS
    $$
        INSERT INTO roles(title)
        VALUES (_title)
        RETURNING id
    $$
  LANGUAGE SQL;

-- Adds a new user to the database.
CREATE OR REPLACE FUNCTION add_user(_email text, _password text)
    RETURNS integer AS
    $$
        INSERT INTO users(email, password)
        VALUES (_email, _password)
        RETURNING id
    $$
  LANGUAGE SQL;

-- Adds a new user to the database (3 params for migration).
CREATE OR REPLACE FUNCTION add_user(_user_id integer,_email text, _password text)
  RETURNS integer AS
  $$
      INSERT INTO users(id,email, password)
      VALUES (_user_id,_email, _password)
      RETURNING id
  $$
LANGUAGE SQL;

--set user 1 as admin for migration
CREATE OR REPLACE FUNCTION set_admin()
  RETURNS void AS
  $$
      UPDATE users
	  SET administrator = true
	  WHERE id = 1
  $$
LANGUAGE SQL;

-- manually adding rows while specifying id will not update the sequence
-- update the sequnce at the end of the migration
CREATE OR REPLACE FUNCTION update_sequence(_table text)
  RETURNS void AS
  $$
	BEGIN
	EXECUTE 
			'WITH nextval as (			
			SELECT MAX(id)+1 as nextval FROM ' 
			|| quote_ident(_table) ||
			')
			SELECT setval(pg_get_serial_sequence('''  
			|| quote_ident(_table) || 
			''', ''id''), nextval , false) FROM nextval';
	END
  $$
LANGUAGE PLPGSQL;

-- name: get-user-info-sql
-- Returns all of the user fields associated with the provided email.
CREATE OR REPLACE FUNCTION get_user(_email text)
    RETURNS TABLE(
        id integer,
        identity text,
        password text,
        administrator boolean,
        reset_key text
    ) AS
    $$
        SELECT id, email AS identity, password, administrator, reset_key
        FROM users
        WHERE email = _email
    $$
  LANGUAGE SQL;
-- name: set-user-email-sql
-- Resets the email for the given user.
CREATE OR REPLACE FUNCTION set_user_email(_email text, _new_email text)
RETURNS text AS
    $$
        UPDATE users
        SET email = _new_email
        WHERE email = _email
        RETURNING email;
    $$
  LANGUAGE SQL;

-- name: set-user-email-sql
-- Resets the email for the given user.
CREATE OR REPLACE FUNCTION set_user_email_and_password(_user_id integer, _email text, _password text)
RETURNS text AS
    $$
        UPDATE users
        SET email = _email, 
			password = _password
        WHERE id = _user_id
        RETURNING email;
    $$
  LANGUAGE SQL;

-- Sets the password reset key for the given user. If one already exists, it is replaced.
CREATE OR REPLACE FUNCTION set_password_reset_key(_email text, _reset_key text)
RETURNS text AS
    $$
        UPDATE users
        SET reset_key = _reset_key
        WHERE email = _email
        RETURNING email;
    $$
  LANGUAGE SQL;

-- Sets the password reset key for the given user. If one already exists, it is replaced.
CREATE OR REPLACE FUNCTION update_password(_email text, _password text)
RETURNS text AS
    $$
        UPDATE users
        SET password = _password, 
			reset_key = null
        WHERE email = _email
        RETURNING email;
    $$
  LANGUAGE SQL;

-- Returns all of the user fields associated with the provided email.
CREATE OR REPLACE FUNCTION get_all_users()
    RETURNS TABLE(
        id integer,
        email text,
        administrator boolean,
        reset_key text
    ) AS
    $$
        SELECT id, email, administrator, reset_key
        FROM users
		WHERE email <> 'admin@sig-gis.com'
    $$
  LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_all_users_by_institution_id(_institution_id integer)
    RETURNS TABLE(
        id integer,
        email text,
        administrator boolean,
        reset_key text,
        institution_role text
    ) AS
    $$
        SELECT users.id, email, administrator, reset_key, title AS institution_role
        FROM get_all_users() AS users
        INNER JOIN institution_users ON users.id = institution_users.user_id
        INNER JOIN roles on roles.id = institution_users.role_id
        WHERE institution_users.institution_id = _institution_id
    $$
  LANGUAGE SQL;


-- Adds a new institution to the database.
CREATE OR REPLACE FUNCTION add_institution(_name text, _logo text, _description text, _url text, _archived boolean)
    RETURNS integer AS
    $$
        INSERT INTO institutions(name, logo, description, url, archived)
        VALUES (_name, _logo, _description, _url, _archived)
        RETURNING id
    $$
  LANGUAGE SQL;

-- Adds a new institution to the database(extra param for migration)
CREATE OR REPLACE FUNCTION add_institution(_institution_id integer,_name text, _logo text, _description text, _url text, _archived boolean)
    RETURNS integer AS
    $$
        INSERT INTO institutions(id,name, logo, description, url, archived)
        VALUES (_institution_id,_name, _logo, _description, _url, _archived)
        RETURNING id
    $$
  LANGUAGE SQL;

-- Returns institution from the database.
CREATE OR REPLACE FUNCTION get_institution(_institution_id integer)
    RETURNS TABLE(
        id integer,
        name text,
        logo text,
        description text,
        url text,
        archived boolean
    )  AS
    $$
        SELECT *
        FROM institutions
        WHERE id = _institution_id
    $$
  LANGUAGE SQL;

-- Adds a returns institution user roles from the database.
CREATE OR REPLACE FUNCTION get_institution_user_roles(_user_id integer)
    RETURNS TABLE(
        institution_id integer,
        role text) AS
        $$
            SELECT institution_id, title AS role
            FROM institution_users AS iu
            INNER JOIN roles AS r
                ON iu.role_id = r.id
            WHERE iu.user_id = _user_id
        $$
  LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_role_id_by_role(_role text)
    RETURNS integer AS
    $$
        SELECT id
        FROM roles
        WHERE title = _role
    $$
  LANGUAGE SQL;

CREATE OR REPLACE FUNCTION update_institution_user_role(_institution_id integer, _user_id integer, _role text)
    RETURNS integer AS
    $$
        UPDATE institution_users
        SET role_id = r.id
        FROM roles AS r
        WHERE institution_id = _institution_id
          AND user_id = _user_id
          AND title = _role
        RETURNING institution_users.id
    $$
  LANGUAGE SQL;

-- Adds a update institution to the database.
CREATE OR REPLACE FUNCTION update_institution(_id integer, _name text, _logo text, _description text, _url text, _archived boolean)
    RETURNS integer AS
    $$
        UPDATE institutions
        SET name = _name, 
			logo = _logo, 
			description = _description, 
			url = _url, 
			archived = _archived
        WHERE id = _id
        RETURNING institutions.id
    $$
  LANGUAGE SQL;
-- update only logo.  Id is not know on during add_institution
CREATE OR REPLACE FUNCTION update_institution_logo(_id integer, _logo text)
    RETURNS integer AS
    $$
        UPDATE institutions
        SET logo = _logo 
        WHERE id = _id
        RETURNING institutions.id
    $$
  LANGUAGE SQL;
-- Adds a new institution_user to the database.
CREATE OR REPLACE FUNCTION add_institution_user(_institution_id integer, _user_id integer, _role_id integer)
    RETURNS integer AS
    $$
        INSERT INTO institution_users(
	    institution_id, user_id, role_id)
	    VALUES (_institution_id, _user_id, _role_id)
        RETURNING id
    $$
  LANGUAGE SQL;

-- overload for adding a user from the web site
  CREATE OR REPLACE FUNCTION add_institution_user(_institution_id integer, _user_id integer, _role text)
    RETURNS integer AS
    $$
        INSERT INTO institution_users(
	    institution_id, user_id, role_id)
	    SELECT _institution_id, _user_id, tr.id
		FROM (SELECT id from roles where title = _role) AS tr
        RETURNING id
    $$
  LANGUAGE SQL;

-- name: update-institution-user
-- Adds a updates institution-user to the database.
CREATE OR REPLACE FUNCTION update_institution_user_role(_institution_id integer, _user_id integer, _role text)
    RETURNS integer  AS
    $$
        UPDATE institution_users
        SET role_id = tr.id
        FROM (SELECT id from roles where title = _role) AS tr
        WHERE institution_id = _institution_id AND user_id = _user_id
        RETURNING institution_users.id
    $$
  LANGUAGE SQL;

-- name: update-imagery
--  updates imagery to the database.
CREATE OR REPLACE FUNCTION update_imagery(_id integer, _institution_id integer, _visibility text, _title text, _attribution text, _extent jsonb, _source_config jsonb )
    RETURNS integer  AS
    $$
        UPDATE imagery
        SET institution_id=_institution_id, 
			visibility=_visibility, 
			title=_title, 
			attribution=_attribution, 
			extent=_extent, 
			source_config=_source_config
        WHERE id = _id
        RETURNING id
    $$
  LANGUAGE SQL;

--  deletes a delete_project_widget_by_widget_id from the database.
CREATE OR REPLACE FUNCTION delete_project_widget_by_widget_id(_id integer)
    RETURNS integer  AS
    $$
        DELETE FROM project_widgets
        WHERE id = _id
        RETURNING id
    $$
  LANGUAGE SQL;

--  updates a update_project_widget_by_widget_id from the database.
CREATE OR REPLACE FUNCTION update_project_widget_by_widget_id(_id integer, _widget  jsonb)
    RETURNS integer  AS
    $$
        UPDATE project_widgets
        SET widget = _widget
        WHERE id = _id
        RETURNING id
    $$
  LANGUAGE SQL;

-- name: add-institution
-- Adds a project_widget to the database.
CREATE OR REPLACE FUNCTION add_project_widget(_project_id integer, _dashboard_id  uuid, _widget  jsonb)
    RETURNS integer AS
    $$
        INSERT INTO project_widgets(project_id, dashboard_id, widget)
        VALUES (_project_id, _dashboard_id , _widget)
        RETURNING id
    $$
  LANGUAGE SQL;

-- Gets project_widgets_by_project_id returns a project_widgets from the database.
CREATE OR REPLACE FUNCTION get_project_widgets_by_project_id(_project_id integer)
    RETURNS TABLE(
        id              integer,
        project_id      integer,
        dashboard_id    uuid,
        widget  jsonb
    )  AS
    $$
        SELECT *
        FROM project_widgets
        WHERE project_id = _project_id
    $$
  LANGUAGE SQL;


-- Gets project_widgets_by_dashboard_id returns a project_widgets from the database.
-- FIXME: this seems to be unused
CREATE OR REPLACE FUNCTION get_project_widgets_by_dashboard_id(_dashboard_id uuid)
    RETURNS TABLE(
        id              integer,
        project_id      integer,
        dashboard_id    uuid,
        widget  jsonb
    )  AS
    $$
        SELECT *
        FROM project_widgets
        WHERE dashboard_id = _dashboard_id
    $$
  LANGUAGE SQL;

--Adds institution imagery
 CREATE OR REPLACE  FUNCTION add_institution_imagery_auto_id(_institution_id integer, _visibility text, _title text, _attribution text, _extent jsonb, _source_config jsonb) 
 	RETURNS integer AS 
	$$
		INSERT INTO imagery (institution_id,visibility,title,attribution,extent,source_config)
		VALUES (_institution_id, _visibility, _title, _attribution, _extent, _source_config)
		RETURNING id
	$$ 
LANGUAGE SQL;

--Adds institution imagery(for migration script)
 CREATE OR REPLACE  FUNCTION add_institution_imagery(_imagery_id integer, _institution_id integer, _visibility text, _title text, _attribution text, _extent jsonb, _source_config jsonb) 
 	RETURNS integer AS 
	$$
		INSERT INTO imagery (id, institution_id, visibility, title, attribution, extent, source_config)
		VALUES (_imagery_id, _institution_id, _visibility, _title, _attribution, _extent, _source_config)
		RETURNING id
	$$ 
LANGUAGE SQL;

--Returns all rows in imagery for which visibility  =  "public".
CREATE OR REPLACE FUNCTION select_public_imagery() RETURNS TABLE
	(
		id              integer,
		institution_id  integer,
		visibility      text,
		title           text,
		attribution     text,
		extent          jsonb,
		source_config   jsonb
	) AS $$
	SELECT id, institution_id, visibility, title, attribution, extent, source_config
	FROM imagery
	WHERE visibility = 'public'
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION delete_imagery(_imagery_id integer)
	RETURNS integer AS 
	$$
		DELETE FROM imagery
		WHERE id = _imagery_id
		RETURNING id
	$$ 
LANGUAGE SQL;

--Returns all rows in imagery for with an institution_id.
CREATE OR REPLACE FUNCTION select_public_imagery_by_institution(_institution_id integer) RETURNS TABLE
	(
		id              integer,
		institution_id  integer,
		visibility      text,
		title           text,
		attribution     text,
		extent          jsonb,
		source_config   jsonb
	) AS $$
	WITH images as (
	SELECT * from select_public_imagery()
	UNION
	SELECT *
	FROM imagery
	WHERE institution_id = _institution_id
	)
	
	SELECT * from images 
	ORDER BY visibility DESC, id
	
$$ LANGUAGE SQL;

--for migration
CREATE OR REPLACE FUNCTION create_project(
		_id integer,
		_institution_id integer,
		_availability text,
		_name text,
		_description text,
		_privacy_level text,
		_boundary geometry,
		_base_map_source text,
		_plot_distribution text,
		_num_plots integer,
		_plot_spacing double precision,
		_plot_shape text,
		_plot_size double precision,
		_sample_distribution text,
		_samples_per_plot integer,
		_sample_resolution double precision,
		_sample_survey jsonb,
		_csv_file text,
		_classification_start_date date,
		_classification_end_date date,
		_classification_timestep integer)
  	RETURNS integer AS 
	$$
	INSERT INTO projects (id, institution_id, availability, name, description, privacy_level, boundary, 
							base_map_source, plot_distribution, num_plots, plot_spacing, plot_shape, plot_size,
							sample_distribution, samples_per_plot,sample_resolution, sample_survey, csv_file,
							classification_start_date, classification_end_date, classification_timestep)
	VALUES (_id, _institution_id, _availability, _name, _description, _privacy_level, _boundary,
			_base_map_source, _plot_distribution, _num_plots, _plot_spacing, _plot_shape, _plot_size, 
			_sample_distribution, _samples_per_plot, _sample_resolution, _sample_survey, _csv_file,
			_classification_start_date, _classification_end_date, _classification_timestep)
	RETURNING id
  	$$
	LANGUAGE SQL;

--Create project
CREATE OR REPLACE FUNCTION create_project(
		_institution_id integer,
		_availability text,
		_name text, 
		_description text,
		_privacy_level text, 
		_boundary geometry(Polygon,4326), 
		_base_map_source text, 
		_plot_distribution text, 
		_num_plots integer, 
		_plot_spacing float, 
		_plot_shape text, 
		_plot_size float, 
		_sample_distribution text, 
		_samples_per_plot integer, 
		_sample_resolution float, 
		_sample_survey jsonb, 
		_classification_start_date date, 
		_classification_end_date date, 
		_classification_timestep integer) 
	RETURNS integer AS 
	$$
	INSERT INTO projects (institution_id, availability, name, description, privacy_level, boundary, 
							base_map_source, plot_distribution, num_plots, plot_spacing, plot_shape, plot_size,
							sample_distribution, samples_per_plot,sample_resolution, sample_survey, classification_start_date, 
							classification_end_date, classification_timestep)
	VALUES (_institution_id, _availability, _name, _description, _privacy_level, _boundary, _base_map_source, 
			_plot_distribution, _num_plots, _plot_spacing, _plot_shape, _plot_size, _sample_distribution, _samples_per_plot,
			_sample_resolution, _sample_survey, _classification_start_date, _classification_end_date, _classification_timestep)
	RETURNING id
	$$ 
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION update_project_csv(
		_proj_id integer,
		_csv_file text,
		_boundary geometry(Polygon,4326)
	)
  	RETURNS integer AS 
	$$
	UPDATE projects 
	SET csv_file = _csv_file,
		boundary = _boundary
	WHERE id = _proj_id
	RETURNING id
  	$$
LANGUAGE SQL;


--create project plots for migration
CREATE OR REPLACE FUNCTION create_project_plots(_project_id integer, _flagged integer, _plot_points geometry(Point,4326)) 
	RETURNS integer AS 
	$$
		INSERT INTO plots (project_id, flagged, center)
		(SELECT _project_id, _flagged, _plot_points)
		RETURNING id
	$$ 
LANGUAGE SQL;


--Create project plot samples
CREATE OR REPLACE FUNCTION create_project_plot_samples(_plot_id integer, _sample_points geometry(Point,4326)) 
	RETURNS integer AS 
	$$
		INSERT INTO samples (plot_id, point)
		(SELECT _plot_id, _sample_points)
		RETURNING id
	$$ 
	LANGUAGE SQL;

--Returns a row in projects by id.
CREATE OR REPLACE FUNCTION select_project(_id integer) 
	RETURNS TABLE (
	  id                        integer,
	  institution_id            integer,
	  availability              text,
	  name                      text,
	  description               text,
	  privacy_level             text,
	  boundary                  text,
	  base_map_source           text,
	  plot_distribution         text,
	  num_plots                 integer,
	  plot_spacing              float,
	  plot_shape                text,
	  plot_size                 float,
	  sample_distribution       text,
	  samples_per_plot          integer,
	  sample_resolution         float,
	  sample_survey             jsonb,
	  csv_file					text,
	  classification_start_date	date,
	  classification_end_date   date,
	  classification_timestep   integer
	) AS $$
	SELECT id,institution_id, availability, name, description,privacy_level,  ST_AsGeoJSON(boundary) as boundary, base_map_source,
		plot_distribution, num_plots, plot_spacing, plot_shape, plot_size, sample_distribution, samples_per_plot, sample_resolution,
		sample_survey, csv_file, classification_start_date, classification_end_date, classification_timestep
	FROM projects
	WHERE id = _id
$$ LANGUAGE SQL;


--Returns all rows in projects for a user_id.
CREATE OR REPLACE FUNCTION select_all_projects() 
	RETURNS TABLE (
	  id                        integer,
	  institution_id            integer,
	  availability              text,
	  name                      text,
	  description               text,
	  privacy_level             text,
	  boundary                  text,
	  base_map_source           text,
	  plot_distribution         text,
	  num_plots                 integer,
	  plot_spacing              float,
	  plot_shape                text,
	  plot_size                 float,
	  sample_distribution       text,
	  samples_per_plot          integer,
	  sample_resolution         float,
	  sample_survey             jsonb,
	  csv_file					text,
	  classification_start_date	date,
	  classification_end_date   date,
	  classification_timestep   integer,
	  editable                  boolean
	) AS $$
	SELECT id,institution_id, availability, name, description,privacy_level,  ST_AsGeoJSON(boundary) as boundary, base_map_source,
		plot_distribution, num_plots, plot_spacing, plot_shape, plot_size, sample_distribution, samples_per_plot, sample_resolution,
		sample_survey, csv_file, classification_start_date, classification_end_date, classification_timestep, false AS editable
	FROM projects
	WHERE privacy_level  =  'public'
	  AND availability  =  'published'
$$ LANGUAGE SQL;

--Returns all rows in projects for institution_id.
CREATE OR REPLACE FUNCTION select_all_institution_projects(_institution_id integer) 
	RETURNS TABLE (
	  id                        integer,
	  institution_id            integer,
	  availability              text,
	  name                      text,
	  description               text,
	  privacy_level             text,
	  boundary                  text,
	  base_map_source           text,
	  plot_distribution         text,
	  num_plots                 integer,
	  plot_spacing              float,
	  plot_shape                text,
	  plot_size                 float,
	  sample_distribution       text,
	  samples_per_plot          integer,
	  sample_resolution         float,
	  sample_survey             jsonb,
	  csv_file					text,
	  classification_start_date	date,
	  classification_end_date   date,
	  classification_timestep   integer,
	  editable					boolean
	) AS $$
	SELECT *
	FROM select_all_projects()
	WHERE institution_id = _institution_id
$$ LANGUAGE SQL;


--Returns all rows in projects for a user_id with roles.
CREATE OR REPLACE FUNCTION select_all_user_projects(_user_id integer) 
	RETURNS TABLE (
	  id                        integer,
	  institution_id            integer,
	  availability              text,
	  name                      text,
	  description               text,
	  privacy_level             text,
	  boundary                  text,
	  base_map_source           text,
	  plot_distribution         text,
	  num_plots                 integer,
	  plot_spacing              float,
	  plot_shape                text,
	  plot_size                 float,
	  sample_distribution       text,
	  samples_per_plot          integer,
	  sample_resolution         float,
	  sample_survey             jsonb,
		csv_file				text,
	  classification_start_date	date,
	  classification_end_date   date,
	  classification_timestep   integer,
	  editable					boolean
	) AS $$
	WITH project_roles AS (
		SELECT *
		FROM projects
		LEFT JOIN get_institution_user_roles(_user_id) AS roles USING (institution_id)
	)
	SELECT p.id,p.institution_id,p.availability,p.name,p.description,p.privacy_level,ST_AsGeoJSON(p.boundary) as boundary,p.base_map_source,p.plot_distribution,p.num_plots,p.plot_spacing,p.plot_shape,p.plot_size,p.sample_distribution,p.samples_per_plot,p.sample_resolution
	,p.sample_survey,p.csv_file,p.classification_start_date,p.classification_end_date,p.classification_timestep,true AS editable
	FROM project_roles as p
	WHERE role = 'admin'
    UNION
	SELECT p.id,p.institution_id,p.availability,p.name,p.description,p.privacy_level,ST_AsGeoJSON(p.boundary) as boundary,p.base_map_source,p.plot_distribution,p.num_plots,p.plot_spacing,p.plot_shape,p.plot_size,p.sample_distribution,p.samples_per_plot,p.sample_resolution
	,p.sample_survey,p.csv_file,p.classification_start_date,p.classification_end_date,p.classification_timestep,false AS editable
	FROM project_roles as p
	WHERE role = 'member'
	  AND p.privacy_level IN ('public','institution')
	  AND p.availability  =  'published'
	UNION
	SELECT p.id,p.institution_id,p.availability,p.name,p.description,p.privacy_level,ST_AsGeoJSON(p.boundary) as boundary,p.base_map_source,p.plot_distribution,p.num_plots,p.plot_spacing,p.plot_shape,p.plot_size,p.sample_distribution,p.samples_per_plot,p.sample_resolution
	,p.sample_survey,p.csv_file,p.classification_start_date,p.classification_end_date,p.classification_timestep,false AS editable
	FROM project_roles as p
	WHERE (role NOT IN ('admin','member') OR role IS NULL)
	  AND p.privacy_level IN ('public','institution')
	  AND p.availability  =  'published'

$$ LANGUAGE SQL;


--Returns all rows in projects for a user_id and institution_id with roles.
CREATE OR REPLACE FUNCTION select_institution_projects_with_roles( _user_id integer, _institution_id integer) 
	RETURNS TABLE (
	  id                        integer,
	  institution_id            integer,
	  availability              text,
	  name                      text,
	  description               text,
	  privacy_level             text,
	  boundary                  text,
	  base_map_source           text,
	  plot_distribution         text,
	  num_plots                 integer,
	  plot_spacing              float,
	  plot_shape                text,
	  plot_size                 float,
	  sample_distribution       text,
	  samples_per_plot          integer,
	  sample_resolution         float,
	  sample_survey             jsonb,
	  csv_file					text,
	  classification_start_date	date,
	  classification_end_date   date,
	  classification_timestep   integer,
	  editable					boolean
	) AS $$
	SELECT *
	FROM select_all_user_projects(_user_id)
	WHERE institution_id = _institution_id
$$ LANGUAGE SQL;

-- select plots
CREATE OR REPLACE FUNCTION select_project_plots(_project_id integer, _maximum integer) 
	RETURNS TABLE (
	  id         integer,
	  center     text,
	  flagged    integer,
	  assigned   integer,
	  username 	text
	) AS $$
	WITH username AS (
		SELECT DISTINCT email, plot_id 
		FROM users 
		INNER JOIN user_plots
			ON users.id = user_plots.user_id
	)
	SELECT plots.id, ST_AsGeoJSON(center), flagged, assigned, username.email
	FROM plots
	LEFT JOIN username
		ON plot_id = id
	WHERE project_id = _project_id
	LIMIT _maximum

$$ LANGUAGE SQL;

-- select samples to add to plots
CREATE OR REPLACE FUNCTION select_plot_samples(_plot_id integer) 
	RETURNS TABLE (
	  id         integer,
	  point	 	text,
	  value     jsonb
	) AS $$
	
	SELECT samples.id, ST_AsGeoJSON(point) as point, 
		(CASE WHEN sample_values.value IS NULL THEN '{}' ELSE sample_values.value END)
	FROM samples
	LEFT JOIN sample_values
	ON samples.id = sample_values.sample_id
	WHERE samples.plot_id = _plot_id

$$ LANGUAGE SQL;

--Returns project users
CREATE OR REPLACE FUNCTION select_project_users(_project_id integer) 
	RETURNS TABLE (
		user_id integer
	) AS $$

	WITH matching_projects AS(
		SELECT  *
		FROM projects
		WHERE id = _project_id
	    ),
		matching_institutions AS(
			SELECT *
			FROM projects p
			INNER JOIN institutions i
			   ON p.institution_id = i.id
			WHERE p.id = _project_id

		),
		matching_institution_users AS (
			SELECT *
			FROM matching_institutions mi
			INNER JOIN institution_users ui
				ON mi.institution_id = ui.institution_id
			INNER JOIN users u
				ON u.id = ui.user_id
			INNER JOIN roles r
			    ON r.id = ui.role_id
		)
	SELECT users.id
	FROM matching_projects
	CROSS JOIN users
	WHERE privacy_level = 'public'
	UNION ALL
	SELECT user_id
	FROM matching_institution_users
	WHERE  privacy_level = 'private'
	  AND title = 'admin'
	UNION ALL
	SELECT user_id
	FROM matching_institution_users
	WHERE  privacy_level = 'institution'
	  AND availability = 'published'
	  AND title = 'member'

$$ LANGUAGE SQL;

--Returns project statistics
CREATE OR REPLACE FUNCTION select_project_statistics(_project_id integer) 
	RETURNS TABLE(
		flagged_plots integer,
		assigned_plots integer,
		unassigned_plots integer,
		members integer,
		contributors integer
	) AS $$
	WITH members AS(
		SELECT count(distinct user_id) as members
		FROM select_project_users(_project_id)
	),
		sums AS(
			SELECT count(distinct up.user_id) as contributors, sum(pl.flagged) as flagged, sum(pl.assigned) as assigned,count(distinct pl.id) as plots
			FROM projects prj
			INNER JOIN plots pl
			  ON prj.id =  pl.project_id
			LEFT JOIN user_plots up
			  ON up.plot_id = pl.id
			WHERE prj.id = _project_id
			  
	)
	SELECT CAST(flagged AS int) AS flagged_plots,
		   CAST(assigned AS int) assigned_plots,
		   CAST(GREATEST(0,(plots-flagged-assigned)) as int) AS unassigned_plots,
		   CAST(members AS int) AS members,
	       CAST(contributors AS int) AS contributors
	FROM members, sums
$$ LANGUAGE SQL;

--Returns unanalyzed plots
CREATE OR REPLACE FUNCTION select_unassigned_plot(_project_id integer, _plot_id integer) 
	RETURNS TABLE (
	  id         integer,
	  center     text,
	  flagged    integer,
	  assigned   integer,
	  username 	 text
	) AS
	$$
	SELECT * from select_project_plots(_project_id, 100000000) as spp
	WHERE spp.id <> _plot_id
	AND flagged = 0
	AND assigned = 0
	ORDER BY id
	LIMIT 1

$$ LANGUAGE SQL;

--Returns unanalyzed plots by plot id
CREATE OR REPLACE FUNCTION select_unassigned_plots_by_plot_id(_project_id integer,_plot_id integer) 
	RETURNS TABLE (
	  id         integer,
	  center     text,
	  flagged    integer,
	  assigned   integer,
	  username 	 text
	) AS
	$$
	SELECT * from select_project_plots(_project_id, 100000000) as spp
	WHERE spp.id = _plot_id
	AND flagged = 0
	AND assigned = 0
	
$$ LANGUAGE SQL;

--Returns project aggregate data
CREATE OR REPLACE FUNCTION dump_project_plot_data(_project_id integer) 
	RETURNS TABLE (
	       plot_id integer,
	       lon float,
	       lat float,
		   plot_shape text,
		   plot_size float,
		   user_id integer,
		   confidence integer,
		   flagged boolean,
		   assigned integer,
		   sample_points bigint,
		   collection_time timestamp,
		   imagery_title text,
		   imagery_date date,
		   value jsonb
	) AS $$
	SELECT plots.id as plot_id,
		   ST_X(center) AS lon,
		   ST_Y(center) AS lat,
		   plot_shape,
		   plot_size,
		   user_id,
		   confidence,
		   user_plots.flagged AS flagged,
		   assigned,
		   count(point) AS sample_points,
		   collection_time::timestamp,
		   json_agg(title)::text AS imagery_title,
		   imagery_date,
		   json_agg(value)::jsonb
	FROM projects
	INNER JOIN plots
		ON plots.project_id = projects.id
	INNER JOIN user_plots
		ON user_plots.plot_id = plots.id
	INNER JOIN sample_values
		ON sample_values.user_plot_id = user_plots.id
	INNER JOIN samples
		ON samples.id = sample_values.sample_id
	INNER JOIN imagery
		ON imagery.id = sample_values.imagery_id
	WHERE projects.id = _project_id
	GROUP BY plots.id,center,plot_shape,plot_size,user_id,confidence,user_plots.flagged,assigned,collection_time,imagery_date
$$ LANGUAGE SQL;

--Returns project raw data
--FIXME correct flagged and assigned once we discus
CREATE OR REPLACE FUNCTION dump_project_sample_data(_project_id integer) 
	RETURNS TABLE (
	       plot_id integer,
		   sample_id integer,
	       lon float,
	       lat float,
		   email text,
		   confidence integer,
		   flagged boolean,
			assigned boolean,
		   collection_time timestamp,
		   imagery_title text,
		   imagery_date date,
		   value jsonb
	) AS $$

	SELECT plots.id as plot_id,
	       samples.id AS sample_id,
		   ST_X(point) AS lon,
		   ST_Y(point) AS lat,
		   users.email,
		   confidence,
		   (CASE WHEN user_plots.flagged IS NULL THEN false ELSE user_plots.flagged END) AS flagged,
		   (CASE WHEN user_plots.flagged IS NOT NULL AND user_plots.flagged = false THEN true ELSE false END) AS assigned,
		   collection_time::timestamp,
		   title AS imagery_title,
		   imagery_date,
		   value
	FROM projects
	INNER JOIN plots
		ON plots.project_id = projects.id
	INNER JOIN samples
		ON samples.plot_id = plots.id
	LEFT JOIN user_plots
		ON user_plots.plot_id = plots.id
	LEFT JOIN sample_values
		ON samples.id = sample_values.sample_id
	LEFT JOIN imagery
		ON imagery.id = sample_values.imagery_id
	LEFT JOIN users
		ON users.id = user_id
	WHERE projects.id = _project_id

$$ LANGUAGE SQL;



--Publish project
CREATE OR REPLACE FUNCTION publish_project(_project_id integer) 
	RETURNS integer AS 
	$$
		UPDATE projects
		SET availability = 'published'
		WHERE id = _project_id
		RETURNING _project_id
	$$ 
LANGUAGE SQL;

--Close project
CREATE OR REPLACE FUNCTION close_project(_project_id integer) 
RETURNS integer AS 
	$$
		UPDATE projects
		SET availability = 'closed'
		WHERE id = _project_id
		RETURNING _project_id
	$$ 
LANGUAGE SQL;

--Archive project
CREATE OR REPLACE FUNCTION archive_project(_project_id integer) 
	RETURNS integer AS 
	$$
		UPDATE projects
		SET availability = 'archived'
		WHERE id = _project_id
		RETURNING _project_id
	$$ 
LANGUAGE SQL;

--Flag plot
CREATE OR REPLACE FUNCTION flag_plot(_plot_id integer, _user_name text, _collection_time timestamp) 
	RETURNS integer AS 
	$$
	
	UPDATE user_plots
	SET flagged = true, 
		user_id = _user_id, 
		collection_time = _collection_time
	WHERE plot_id = _plot_id
	RETURNING plot_id
	$$
LANGUAGE SQL;

--Add user samples future design
CREATE OR REPLACE FUNCTION add_user_samples( 
		_project_id integer, 
		_plot_id integer,
		_user_id integer, 
		_confidence integer, 
		_samples jsonb, 
		_imagery_id integer, 
		_imagery_date date
		) 
	RETURNS integer AS 
	$$
		UPDATE plots
		-- should this be assigned = 1?
		SET assigned = assigned + 1
		WHERE id = _plot_id;

		WITH user_plot_table AS(
			INSERT INTO user_plots(user_id, plot_id, confidence) VALUES (_user_id, _plot_id, _confidence)
			RETURNING id
		),
		sample_values AS (
			SELECT CAST(key as integer) as sample_id, value FROM jsonb_each(_samples)
		)

		INSERT INTO sample_values(user_plot_id, sample_id, imagery_id, imagery_date, value)

		(SELECT upt.id, sv.sample_id, _imagery_id, _imagery_date, sv.value
			FROM user_plot_table AS upt, samples AS s
		 	INNER JOIN sample_values as sv
		 		ON s.id = sv.sample_id
			WHERE s.plot_id = _plot_id)

		RETURNING sample_id
	$$ 
LANGUAGE SQL;
--Add user samples for migration
CREATE OR REPLACE FUNCTION add_sample_values(_user_plot_id integer, _sample_id integer, _value jsonb) 
	RETURNS integer AS 
	$$
		INSERT INTO sample_values(user_plot_id, sample_id, value) VALUES ( _user_plot_id, _sample_id, _value)
		RETURNING id
	$$ 
LANGUAGE SQL;

--Add user plots for migration
CREATE OR REPLACE FUNCTION add_user_plots(_plot_id integer, _username text, _flagged boolean) 
	RETURNS integer AS $$
		INSERT INTO user_plots(plot_id, flagged, user_id)
		(SELECT _plot_id, _flagged, (SELECT id FROM users WHERE email = _username) as aa)

		RETURNING id
	$$ 
LANGUAGE SQL;
--Returns all institutions
CREATE OR REPLACE FUNCTION select_all_institutions() 
	RETURNS TABLE (
	  id            integer,
	  name          text,
	  logo          text,
	  description   text,
	  url           text,
	  archived      boolean,
	  members		jsonb,
	  admins		jsonb,
	  pending		jsonb
	) AS $$
	WITH inst_roles as (
		SELECT user_id, title, institution_id
		FROM institution_users as iu
		LEFT JOIN roles
			ON roles.id = iu.role_id
	),
	members as (
		SELECT jsonb_agg(user_id) as member_list, institution_id
		FROM inst_roles		
		WHERE title = 'member'
			OR title = 'admin'
		GROUP BY institution_id
	),
	admins as (
		SELECT jsonb_agg(user_id) as admin_list, institution_id
		FROM inst_roles		
		WHERE title = 'admin'
		GROUP BY institution_id
	),
	pending as (
		SELECT jsonb_agg(user_id) as pending_list, institution_id
		FROM inst_roles		
		WHERE title = 'pending'
		GROUP BY institution_id
	)
	
	SELECT i.*, 
		(CASE WHEN member_list IS NULL THEN '[]' ELSE member_list END), 
		(CASE WHEN admin_list IS NULL THEN '[]' ELSE admin_list END),
		(CASE WHEN pending_list IS NULL THEN '[]' ELSE pending_list END)
	FROM institutions as i
	LEFT JOIN members as m
		ON i.id = m.institution_id
	LEFT JOIN admins as a
		ON i.id = a.institution_id
	LEFT JOIN pending as p
		ON i.id = p.institution_id
	WHERE archived = false
$$ LANGUAGE SQL;

--Returns one institution
CREATE OR REPLACE FUNCTION select_institution_by_id(_institution_id integer) 
	RETURNS TABLE (
	  id            integer,
	  name          text,
	  logo          text,
	  description   text,
	  url           text,
	  archived      boolean,
	  members		jsonb,
	  admins		jsonb,
	  pending		jsonb
	) AS $$
	SELECT *
	FROM select_all_institutions()
	WHERE id = _institution_id
	   AND archived = false
$$ LANGUAGE SQL;

--Returns  institution details
--Unused
CREATE OR REPLACE FUNCTION select_institution_details(_institution_id integer) 
	RETURNS TABLE (
	  id            integer,
	  name          text,
	  logo          text,
	  description   text,
	  url           text,
	  archived      boolean
	)  AS $$
	SELECT *
	FROM institutions
	WHERE id = _institution_id
$$ LANGUAGE SQL;

--Updates institution details
CREATE OR REPLACE FUNCTION update_institution(_institution_id integer, _name text, _logo_path text, _description text, _url text) 
	RETURNS integer AS 
	$$
		UPDATE institutions
		SET name = _name,
			url = _url,
			description = _description,
			logo = _logo_path
		WHERE id = _institution_id
		RETURNING id
	$$
LANGUAGE SQL;

--Archive  institution
CREATE OR REPLACE FUNCTION archive_institution(_institution_id integer) 
	RETURNS integer AS 
	$$
		UPDATE institutions
		SET archived = true
		WHERE id = _institution_id
		RETURNING id
	$$ 
LANGUAGE SQL;

--TS related functions
-- Add packet to a project.
-- Not every project needs packet. If no packet is defined, there is no need to create packet for that project.
CREATE OR REPLACE FUNCTION add_ts_packet(project_id integer, packet_id integer, plots integer[]) RETURNS VOID AS $$
	INSERT INTO ts_packets (project_id, packet_id, plot_id)
	SELECT project_id, packet_id, u.* FROM unnest(ts_plots) u;
$$ LANGUAGE SQL;

-- Assign a project (and packets if there is any) to a user
CREATE OR REPLACE FUNCTION assign_project_to_user(user_id integer, project_id integer) RETURNS VOID as $$
	INSERT INTO ts_project_user (project_id, user_id)
	VALUES (project_id, user_id);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION assign_project_to_user(user_id integer, project_id integer, packet_ids integer[]) RETURNS VOID as $$
	INSERT INTO ts_project_user (project_id, user_id, packet_id)
	SELECT project_id, user_id, u.* FROM unnest(packet_ids) u;
$$ LANGUAGE SQL;

-- Get project and packet if any assigned to a user
CREATE OR REPLACE FUNCTION get_project_for_user(interpreter integer) RETURNS TABLE
(
  project_id    integer,
  name          text,
  description   text,
  interpreter   integer,
  ts_plot_size  integer,
  ts_start_year integer,
  ts_end_year   integer,
  ts_target_day integer,
  packet_ids    text
) AS $$
	SELECT projects.id as project_id, projects.name, projects.description,
		users.id as interpreter, ts_plot_size, ts_start_year, ts_end_year, ts_target_day,
		array_to_string(array_agg(packet_id), ',') as packet_ids
	FROM projects, users, ts_project_user
	WHERE projects.id = ts_project_user.project_id
		AND ts_project_user.user_id = users.id
		AND users.id = interpreter
	GROUP BY projects.id, projects.name, projects.description,
		users.id, ts_plot_size, ts_start_year, ts_end_year, ts_target_day
	ORDER BY projects.id, packet_ids
$$ LANGUAGE SQL;

-- Get all plots from a project for a user
CREATE OR REPLACE FUNCTION get_project_plots_for_user(prj_id integer, interpreter_id integer) RETURNS TABLE
(
	project_id integer,
	plot_id	integer,
	lng float,
	lat float,
	is_complete integer,
	is_example integer,
	packet_id integer
) AS $$
    SELECT plots.project_id, plots.id as plot_id,
       ST_X(center) as lng, ST_Y(center) as lat,
       is_complete, is_example, -1 as packet_id
    FROM plots left outer join ts_plot_comments
    ON plots.id = ts_plot_comments.plot_id
    	AND plots.project_id = ts_plot_comments.project_id
    	AND ts_plot_comments.interpreter = interpreter_id
    WHERE plots.project_id=prj_id
		AND ts_plot_comments.packet_id = -1
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_project_plots_for_user(prj_id integer, interpreter_id integer, packet integer) RETURNS TABLE
(
	project_id integer,
	plot_id	integer,
	lng float,
	lat float,
	is_complete integer,
	is_example integer,
	packet_id integer
) AS $$
	SELECT plots.project_id, plots.id as plot_id,
		   ST_X(center) as lng, ST_Y(center) as lat,
		   is_complete, is_example, packet_id
	FROM plots inner join ts_packets
	ON plots.project_id = ts_packets.project_id
		AND plots.id = ts_packets.plot_id
	LEFT OUTER JOIN ts_plot_comments
	ON plots.id = ts_plot_comments.plot_id
		AND plots.project_id = ts_plot_comments.project_id
		AND ts_plot_comments.interpreter = interpreter_id
	WHERE plots.project_id = prj_id
		AND ts_packets.packet_id = packet
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_plot_comments(interpreter_id integer, prj_id integer, plotid integer, packet integer) RETURNS TABLE
(
	project_id integer,
	plot_id integer,
	interpreter integer,
	comment text,
	is_complete integer,
	is_example integer,
	is_wetland integer,
	uncertainty integer

) AS $$
	SELECT project_id, plot_id, interpreter,
		   comment, is_complete, is_example,
		   is_wetland, uncertainty
	FROM ts_plot_comments
	WHERE project_id = prj_id
	AND plot_id = plotid
	AND packet_id = packet
	AND interpreter = interpreter_id
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION create_plot_comments(interpreter integer, project_id integer, plot_id integer, packet_id integer,
	comments text, complete integer default 0, example integer default 0, wetland integer default 0, certainty integer default 0)
	RETURNS BIGINT
AS $$
	INSERT INTO ts_plot_comments
		(project_id, plot_id, interpreter, packet_id, comment, is_complete, is_example, is_wetland, uncertainty)
		VALUES (project_id, plot_id, interpreter, packet_id, comments, complete, example, wetland, certainty)
	ON CONFLICT (project_id, plot_id, interpreter, packet_id) DO UPDATE
	SET comment = comments,
		is_example=example,
		is_complete=complete,
		is_wetland=wetland,
		uncertainty=certainty

	RETURNING id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_plot_vertices_for_project(prj_id integer) RETURNS TABLE
(
	project_id integer,
	plot_id integer,
	image_year integer,
	image_julday integer,
	dominant_landuse text,
	dominant_landuse_notes text,
	dominant_landcover text,
	dominant_landcover_notes text,
	change_process text,
	change_process_notes text,
	interpreter integer,
	packet_id integer
) AS $$
	SELECT project_id,
		plot_id,
		image_year,
		image_julday,
		dominant_landuse,
		coalesce(dominant_landuse_notes, '') as dominant_landuse_notes,
		dominant_landcover,
		coalesce(dominant_landcover_notes,'') as dominant_landcover_notes,
		change_process,
		coalesce(change_process_notes,'') as change_process_notes,
		interpreter,
		packet_id
	FROM ts_vertex
	WHERE project_id = prj_id
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_plot_vertices(interpreter_id integer, prj_id integer, plotid integer, packet integer) RETURNS TABLE
(
	project_id integer,
	plot_id integer,
	image_year integer,
	image_julday integer,
	dominant_landuse text,
	dominant_landuse_notes text,
	dominant_landcover text,
	dominant_landcover_notes text,
	change_process text,
	change_process_notes text,
	interpreter integer,
	packet_id integer
) AS $$
	SELECT project_id,
		plot_id,
		image_year,
		image_julday,
		dominant_landuse,
		dominant_landuse_notes,
		dominant_landcover,
		dominant_landcover_notes,
		change_process,
		change_process_notes,
		interpreter,
		packet_id
	FROM get_plot_vertices_for_project(prj_id)
	WHERE plot_id = plotid
		AND interpreter = interpreter_id
		AND packet_id = packet
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION create_vertices(project_id integer, plot_id integer, interpreter integer, packet integer, vertices jsonb) RETURNS VOID 
AS $$
	-- remove existing vertex
	DELETE FROM ts_vertex
	WHERE project_id = project_id
		AND plot_id = plot_id
		AND interpreter = interpreter
		AND packet_id = packet;

	-- add new vertices
	INSERT INTO ts_vertex (
		project_id,
		plot_id,
		image_year,
		image_julday,
		image_id,
		dominant_landuse,
		dominant_landuse_notes,
		dominant_landcover,
		dominant_landcover_notes,
		change_process,
		change_process_notes,
		interpreter,
		packet_id
	)
	SELECT 	project_id,
		plot_id,
		image_year,
		image_julday,
		image_id,
		dominant_landuse,
		dominant_landuse_notes,
		dominant_landcover,
		dominant_landcover_notes,
		change_process,
		change_process_notes,
		interpreter,
		packet_id
	FROM jsonb_to_recordset(vertices) as X(
		project_id integer,
		plot_id integer,
		image_year integer,
		image_julday integer,
		image_id text,
		dominant_landuse text,
		dominant_landuse_notes text,
		dominant_landcover text,
		dominant_landcover_notes text,
		change_process text,
		change_process_notes text,
		interpreter integer,
		packet_id integer
	);
$$ LANGUAGE SQL;

CREATE OR REPLACE function get_image_preference(interpreter integer, project_id integer, packet integer, plot_id integer) RETURNS TABLE
(
	project_id integer, 
	plot_id integer, 
	image_id text, 
	image_year integer, 
	image_julday integer, 
	priority integer, 
	interpreter integer, 
	packet_id integer
) AS $$
	SELECT project_id, plot_id, image_id, image_year, image_julday, priority, interpreter, packet_id
	FROM ts_image_preference
	WHERE project_id = project_id
		AND plot_id = plot_id
		AND interpreter = interpreter
		AND packet_id = packet
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION update_image_preference(preference jsonb) RETURNS VOID
AS $$
	INSERT INTO ts_image_preference (
		project_id, 
		plot_id, 
		image_id, 
		image_year, 
		image_julday, 
		priority, 
		interpreter, 
		packet_id)
	SELECT 	project_id, 
		plot_id, 
		image_id, 
		image_year, 
		image_julday, 
		priority, 
		interpreter, 
		packet_id
	FROM jsonb_to_record(preference) as X(
		project_id integer,
		plot_id integer,
		image_id text,
		image_year integer,
		image_julday integer,
		priority integer,
		interpreter integer,
		packet_id integer
	)
	ON CONFLICT (project_id, plot_id, image_year, interpreter, packet_id) DO UPDATE
		SET image_id = EXCLUDED.image_id,
			image_julday = EXCLUDED.image_julday,
			priority = EXCLUDED.priority;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_response_design(project_id) RETURNS TABLE 
(
	project_id integer,
	landuse text,
	landcover text,
	change_process text
) AS $$
	SELECT project_id,
		   landuse,
		   landcover,
		   change_process
	FROM ts_response_design
	WHERE project_id = project_id
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION create_response_design(design jsonb) RETURNS VOID
AS $$
	INSERT INTO ts_response_design (
		project_id, 
		landuse,
		landcover,
		change_process)
	SELECT 	project_id, 
		landuse,
		landcover,
		change_process
	FROM jsonb_to_record(design) as X(
		project_id integer,
		landuse text,
		landcover text,
		change_process text
	)
	ON CONFLICT (project_id) DO UPDATE
		SET landuse = EXCLUDED.landuse,
			landcover = EXCLUDED.landcover,
			change_process = EXCLUDED.change_process;
$$ LANGUAGE SQL;
