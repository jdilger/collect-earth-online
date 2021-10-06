-- NAMESPACE: project
-- REQUIRES: clear

--
--  MODIFY PROJECT FUNCTIONS
--

-- Create a project
CREATE OR REPLACE FUNCTION create_project(
    _institution_id         integer,
    _name                   text,
    _description            text,
    _privacy_level          text,
    _imagery_id             integer,
    _boundary               jsonb,
    _plot_distribution      text,
    _num_plots              integer,
    _plot_spacing           real,
    _plot_shape             text,
    _plot_size              real,
    _sample_distribution    text,
    _samples_per_plot       integer,
    _sample_resolution      real,
    _allow_drawn_samples    boolean,
    _survey_questions       jsonb,
    _survey_rules           jsonb,
    _token_key              text,
    _options                jsonb,
    _design_settings        jsonb
 ) RETURNS integer AS $$

    INSERT INTO projects (
        institution_rid,
        availability,
        name,
        description,
        privacy_level,
        imagery_rid,
        boundary,
        plot_distribution,
        num_plots,
        plot_spacing,
        plot_shape,
        plot_size,
        sample_distribution,
        samples_per_plot,
        sample_resolution,
        allow_drawn_samples,
        survey_questions,
        survey_rules,
        created_date,
        token_key,
        options,
        design_settings
    ) VALUES (
        _institution_id,
        'unpublished',
        _name,
        _description,
        _privacy_level,
        _imagery_id,
        ST_SetSRID(ST_GeomFromGeoJSON(_boundary), 4326),
        _plot_distribution,
        _num_plots,
        _plot_spacing,
        _plot_shape,
        _plot_size,
        _sample_distribution,
        _samples_per_plot,
        _sample_resolution,
        _allow_drawn_samples,
        _survey_questions,
        _survey_rules,
        now(),
        _token_key,
        _options,
        _design_settings
    )
    RETURNING project_uid

$$ LANGUAGE SQL;

-- Publish project
CREATE OR REPLACE FUNCTION publish_project(_project_id integer)
 RETURNS integer AS $$

    UPDATE projects
    SET availability = 'published',
        published_date = Now()
    WHERE project_uid = _project_id
    RETURNING _project_id

$$ LANGUAGE SQL;

-- Close project
CREATE OR REPLACE FUNCTION close_project(_project_id integer)
 RETURNS integer AS $$

    UPDATE projects
    SET availability = 'closed',
        closed_date = Now()
    WHERE project_uid = _project_id
    RETURNING _project_id

$$ LANGUAGE SQL;

-- Archive project
CREATE OR REPLACE FUNCTION archive_project(_project_id integer)
 RETURNS integer AS $$

    UPDATE projects
    SET availability = 'archived',
        archived_date = Now()
    WHERE project_uid = _project_id
    RETURNING _project_id

$$ LANGUAGE SQL;

-- Delete project items and external files, leave entry for reference
CREATE OR REPLACE FUNCTION deep_archive_project(_project_id integer)
 RETURNS void AS $$

 BEGIN
    DELETE FROM plots WHERE project_rid = _project_id;
    DELETE FROM project_widgets WHERE project_rid = _project_id;
    DELETE FROM project_imagery WHERE project_rid = _project_id;
 END

$$ LANGUAGE PLPGSQL;

-- Delete project and external files
CREATE OR REPLACE FUNCTION delete_project(_project_id integer)
 RETURNS void AS $$

 BEGIN
    -- Delete plots first for performance
    DELETE FROM plots WHERE project_rid = _project_id;
    DELETE FROM projects WHERE project_uid = _project_id;

 END

$$ LANGUAGE PLPGSQL;

-- Update select set of project fields
CREATE OR REPLACE FUNCTION update_project(
    _project_id             integer,
    _name                   text,
    _description            text,
    _privacy_level          text,
    _imagery_id             integer,
    _boundary               jsonb,
    _plot_distribution      text,
    _num_plots              integer,
    _plot_spacing           real,
    _plot_shape             text,
    _plot_size              real,
    _sample_distribution    text,
    _samples_per_plot       integer,
    _sample_resolution      real,
    _allow_drawn_samples    boolean,
    _survey_questions       jsonb,
    _survey_rules           jsonb,
    _options                jsonb,
    _design_settings        jsonb
 ) RETURNS void AS $$

    UPDATE projects
    SET name = _name,
        description = _description,
        privacy_level = _privacy_level,
        imagery_rid = _imagery_id,
        boundary = ST_SetSRID(ST_GeomFromGeoJSON(_boundary), 4326),
        plot_distribution = _plot_distribution,
        num_plots = _num_plots,
        plot_spacing = _plot_spacing,
        plot_shape = _plot_shape,
        plot_size = _plot_size,
        sample_distribution = _sample_distribution,
        samples_per_plot = _samples_per_plot,
        sample_resolution = _sample_resolution,
        allow_drawn_samples = _allow_drawn_samples,
        survey_questions = _survey_questions,
        survey_rules = _survey_rules,
        options = _options,
        design_settings = _design_settings
    WHERE project_uid = _project_id

$$ LANGUAGE SQL;

-- Update counts after plots are created
CREATE OR REPLACE FUNCTION update_project_counts(_project_id integer)
 RETURNS void AS $$

    WITH project_plots AS (
        SELECT project_uid, plot_uid, sample_uid
        FROM projects p
        INNER JOIN plots pl
            ON pl.project_rid = project_uid
        INNER JOIN samples s
            ON plot_uid = s.plot_rid
        WHERE project_uid = _project_id
    )

    UPDATE projects
    SET num_plots = plots,
        samples_per_plot = samples
    FROM (
        SELECT COUNT(DISTINCT plot_uid) as plots,
            (CASE WHEN COUNT(DISTINCT plot_uid) = 0 THEN
                0
            ELSE
                COUNT(sample_uid) / COUNT(DISTINCT plot_uid)
            END) as samples
        FROM project_plots
    ) a
    WHERE project_uid = _project_id

$$ LANGUAGE SQL;

-- Calculates boundary from for csv / shp data
CREATE OR REPLACE FUNCTION set_boundary(_project_id integer, _m_buffer real)
 RETURNS void AS $$

    UPDATE projects SET boundary = b
    FROM (
        SELECT ST_Envelope(ST_Buffer(ST_SetSRID(ST_Extent(plot_geom) , 4326)::geography , _m_buffer)::geometry) as b
        FROM plots
        WHERE project_rid = _project_id
    ) bb
    WHERE project_uid = _project_id

$$ LANGUAGE SQL;

-- Copy plot data and sample data
CREATE OR REPLACE FUNCTION copy_project_plots_samples(_old_project_id integer, _new_project_id integer)
 RETURNS integer AS $$

    WITH project_plots AS (
        SELECT plot_geom,
            visible_id,
            extra_plot_info,
            plot_uid as plid_old,
            row_number() OVER(order by plot_uid) as rowid
        FROM projects p
        INNER JOIN plots pl
            ON project_rid = project_uid
            AND project_rid = _old_project_id
    ), inserting AS (
        INSERT INTO plots
            (project_rid, plot_geom, visible_id, extra_plot_info)
        SELECT _new_project_id, plot_geom, visible_id, extra_plot_info
        FROM project_plots
        RETURNING plot_uid as plid
    ), new_ordered AS (
        SELECT plid, row_number() OVER(order by plid) as rowid FROM inserting
    ), combined AS (
        SELECT * from new_ordered inner join project_plots USING (rowid)
    ), inserting_samples AS (
        INSERT INTO samples
            (plot_rid, sample_geom, visible_id, extra_sample_info)
        SELECT plid, sample_geom, visible_id, extra_sample_info
        FROM (
            SELECT plid, sample_geom, s.visible_id, extra_sample_info
            FROM combined c
            INNER JOIN samples s
                ON c.plid_old = s.plot_rid
        ) B
        RETURNING sample_uid
    )

    SELECT COUNT(1)::int FROM inserting_samples

$$ LANGUAGE SQL;

-- Copy other project fields that may not have been correctly passed from UI
CREATE OR REPLACE FUNCTION copy_project_plots_stats(_old_project_id integer, _new_project_id integer)
 RETURNS void AS $$

    UPDATE projects
    SET boundary = n.boundary,
        imagery_rid = n.imagery_rid,
        plot_distribution = n.plot_distribution,
        num_plots = n.num_plots,
        plot_spacing = n.plot_spacing,
        plot_shape = n.plot_shape,
        plot_size = n.plot_size,
        sample_distribution = n.sample_distribution,
        samples_per_plot = n.samples_per_plot,
        sample_resolution = n.sample_resolution
    FROM (SELECT
            boundary,             imagery_rid,
            plot_distribution,    num_plots,
            plot_spacing,         plot_shape,
            plot_size,            sample_distribution,
            samples_per_plot,     sample_resolution
         FROM projects
         WHERE project_uid = _old_project_id) n
    WHERE
        project_uid = _new_project_id

$$ LANGUAGE SQL;

-- Combines individual functions needed to copy all plot and sample information
CREATE OR REPLACE FUNCTION copy_template_plots(_old_project_id integer, _new_project_id integer)
 RETURNS void AS $$

    SELECT * FROM copy_project_plots_samples(_old_project_id, _new_project_id);
    SELECT * FROM copy_project_plots_stats(_old_project_id, _new_project_id);

$$ LANGUAGE SQL;

-- Copy samples from external file backup
CREATE OR REPLACE FUNCTION copy_project_ext_samples(_project_id integer)
 RETURNS void AS $$

    INSERT INTO samples
        (plot_rid, sample_geom, visible_id, extra_sample_info)
    SELECT plot_rid, sample_geom, visible_id, extra_sample_info
    FROM (
        SELECT plot_rid, sample_geom, es.visible_id, extra_sample_info
        FROM ext_samples es
        INNER JOIN plots
            ON plot_uid = plot_rid
        WHERE project_rid = _project_id
    ) B

$$ LANGUAGE SQL;

-- VALIDATIONS

-- Check if a project was created where plots have no samples
-- This only checks plots with external data. It assumes that auto generated samples generate correctly
CREATE OR REPLACE FUNCTION plots_missing_samples(_project_id integer)
 RETURNS table (visible_id integer) AS $$

    SELECT pl.visible_id
    FROM projects p
    INNER JOIN plots pl
        ON pl.project_rid = project_uid
    LEFT JOIN samples s
        ON plot_uid = s.plot_rid
    WHERE project_uid = _project_id
        AND sample_uid IS NULL

$$ LANGUAGE SQL;

--
-- USING PROJECT FUNCTIONS
--

CREATE OR REPLACE FUNCTION valid_boundary(_boundary geometry)
 RETURNS boolean AS $$

    SELECT EXISTS(
        SELECT 1
        WHERE _boundary IS NOT NULL
            AND ST_Contains(ST_MakeEnvelope(-180, -90, 180, 90, 4326), _boundary)
            AND ST_XMax(_boundary) > ST_XMin(_boundary)
            AND ST_YMax(_boundary) > ST_YMin(_boundary)
    )

$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION valid_project_boundary(_project_id integer)
 RETURNS boolean AS $$

    SELECT * FROM valid_boundary((SELECT boundary FROM projects WHERE project_uid = _project_id))

$$ LANGUAGE SQL;

-- Returns a row in projects by id
CREATE OR REPLACE FUNCTION select_project_by_id(_project_id integer)
 RETURNS table (
    project_id             integer,
    institution_id         integer,
    imagery_id             integer,
    availability           text,
    name                   text,
    description            text,
    privacy_level          text,
    boundary               text,
    plot_distribution      text,
    num_plots              integer,
    plot_spacing           real,
    plot_shape             text,
    plot_size              real,
    sample_distribution    text,
    samples_per_plot       integer,
    sample_resolution      real,
    allow_drawn_samples    boolean,
    survey_questions       jsonb,
    survey_rules           jsonb,
    options                jsonb,
    design_settings        jsonb,
    created_date           date,
    published_date         date,
    closed_date            date,
    has_geo_dash           boolean,
    token_key              text
 ) AS $$

    SELECT project_uid,
        institution_rid,
        imagery_rid,
        availability,
        name,
        description,
        privacy_level,
        ST_AsGeoJSON(boundary),
        plot_distribution,
        num_plots,
        plot_spacing,
        plot_shape,
        plot_size,
        sample_distribution,
        samples_per_plot,
        sample_resolution,
        allow_drawn_samples,
        survey_questions,
        survey_rules,
        options,
        design_settings,
        created_date,
        published_date,
        closed_date,
        count(widget_uid) > 1,
        token_key
    FROM projects
    LEFT JOIN project_widgets
        ON project_rid = project_uid
    WHERE project_uid = _project_id
        AND availability <> 'archived'
    GROUP BY project_uid

$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION user_project(_user_id integer, _role_id integer, _privacy_level text, _availability text)
 RETURNS boolean AS $$

    SELECT (_role_id = 1 AND _availability <> 'archived')
            OR (_availability = 'published'
                AND (_privacy_level = 'public'
                    OR (_user_id > 0 AND _privacy_level = 'users')
                    OR (_role_id = 2 AND _privacy_level = 'institution')))

$$ LANGUAGE SQL IMMUTABLE;

-- Returns all projects the user can see. This is used only on the home page
CREATE OR REPLACE FUNCTION select_user_home_projects(_user_id integer)
 RETURNS table (
    project_id        integer,
    institution_id    integer,
    name              text,
    description       text,
    centroid          text,
    num_plots         integer,
    editable          boolean
 ) AS $$

    SELECT project_uid,
        p.institution_rid,
        name,
        description,
        ST_AsGeoJSON(ST_Centroid(boundary)),
        num_plots,
        (CASE WHEN role_rid IS NULL THEN FALSE ELSE role_rid = 1 END) AS editable
    FROM projects as p
    LEFT JOIN institution_users iu
        ON user_rid = _user_id
        AND p.institution_rid = iu.institution_rid
    WHERE user_project(_user_id, role_rid, p.privacy_level, p.availability)
        AND valid_boundary(boundary) = TRUE
    ORDER BY project_uid

$$ LANGUAGE SQL;

-- Returns percent of plots collected.
CREATE OR REPLACE FUNCTION project_percent_complete(_project_id integer)
 RETURNS real AS $$

    SELECT (
        CASE WHEN count(distinct(plot_uid)) > 0
        THEN (100.0 * count(user_plot_uid) / count(distinct(plot_uid))::real)
        ELSE 0
        END
    )::real
    FROM plots
    LEFT JOIN user_plots
        ON plot_uid = plot_rid
    WHERE project_rid = _project_id

$$ LANGUAGE SQL;

-- Returns all rows in projects for a user_id and institution_rid with roles
CREATE OR REPLACE FUNCTION select_institution_projects(_user_id integer, _institution_id integer)
 RETURNS table (
    project_id       integer,
    name             text,
    num_plots        integer,
    privacy_level    text,
    pct_complete     real
 ) AS $$

    SELECT project_uid,
        name,
        num_plots,
        privacy_level,
        (SELECT project_percent_complete(project_uid))
    FROM projects as p
    LEFT JOIN institution_users iu
        ON user_rid = _user_id
        AND p.institution_rid = iu.institution_rid
    WHERE p.institution_rid = _institution_id
        AND user_project(_user_id, role_rid, p.privacy_level, p.availability)
    ORDER BY project_uid

$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION select_template_projects(_user_id integer)
 RETURNS table (
     project_id    integer,
     name          text
 ) AS $$

    SELECT project_uid, name
    FROM projects as p
    LEFT JOIN institution_users iu
        ON user_rid = _user_id
        AND p.institution_rid = iu.institution_rid
    WHERE (role_rid = 1 AND p.availability <> 'archived')
        OR (role_rid = 2
            AND p.privacy_level IN ('public', 'institution', 'users')
            AND p.availability = 'published')
        OR (_user_id > 0
            AND p.privacy_level IN ('public', 'users')
            AND p.availability = 'published')
        OR (p.privacy_level IN ('public')
            AND p.availability = 'published')
    ORDER BY project_uid

$$ LANGUAGE SQL;


-- Returns project statistics
-- Overlapping queries, consider condensing. Query time is not an issue.
CREATE OR REPLACE FUNCTION select_project_statistics(_project_id integer)
 RETURNS table (
    flagged_plots       integer,
    analyzed_plots      integer,
    unanalyzed_plots    integer,
    contributors        integer,
    created_date        date,
    published_date      date,
    closed_date         date,
    archived_date       date,
    user_stats          text
 ) AS $$

    WITH project_plots AS (
        SELECT project_uid,
            plot_uid,
            (CASE WHEN collection_time IS NULL OR collection_start IS NULL THEN 0
                ELSE EXTRACT(EPOCH FROM (collection_time - collection_start)) END) as seconds,
            (CASE WHEN collection_time IS NULL OR collection_start IS NULL THEN 0 ELSE 1 END) as timed,
            u.email as email
        FROM user_plots up
        INNER JOIN plots pl
            ON up.plot_rid = plot_uid
        INNER JOIN projects p
            ON pl.project_rid = project_uid
        INNER JOIN users u
            ON up.user_rid = user_uid
        WHERE project_uid = _project_id
    ), user_groups AS (
        SELECT email,
            SUM(seconds)::int as seconds,
            COUNT(plot_uid) as plots,
            SUM(timed):: int as timedPlots
        FROM project_plots
        GROUP BY email
        ORDER BY email DESC
    ), user_agg as (
        SELECT
            format('[%s]',
                   string_agg(
                       format('{"user":"%s", "seconds":%s, "plots":%s, "timedPlots":%s}'
                              , email, seconds, plots, timedPlots), ', ')) as user_stats
        FROM user_groups
    ), plotsum AS (
        SELECT SUM(coalesce(flagged::int, 0)) as flagged,
            SUM((user_plot_uid IS NOT NULL)::int) as analyzed,
            plot_uid
        FROM projects prj
        INNER JOIN plots pl
          ON project_uid = pl.project_rid
        LEFT JOIN user_plots up
            ON up.plot_rid = pl.plot_uid
        GROUP BY project_uid, plot_uid
        HAVING project_uid = _project_id
    ), sums AS (
        SELECT MAX(prj.created_date) as created_date,
            MAX(prj.published_date) as published_date,
            MAX(prj.closed_date) as closed_date,
            MAX(prj.archived_date) as archived_date,
            (CASE WHEN SUM(ps.flagged::int) IS NULL THEN 0 ELSE SUM(ps.flagged::int) END) as flagged,
            (CASE WHEN SUM(ps.analyzed::int) IS NULL THEN 0 ELSE SUM(ps.analyzed::int) END) as analyzed,
            COUNT(distinct pl.plot_uid) as plots
        FROM projects prj
        INNER JOIN plots pl
          ON project_uid = pl.project_rid
        LEFT JOIN plotsum ps
          ON ps.plot_uid = pl.plot_uid
        WHERE project_uid = _project_id
    ), users_count AS (
        SELECT COUNT (DISTINCT user_rid) as users
        FROM projects prj
        INNER JOIN plots pl
          ON project_uid = pl.project_rid
            AND project_uid = _project_id
        LEFT JOIN user_plots up
          ON up.plot_rid = plot_uid
    )

    SELECT CAST(flagged as int) as flagged_plots,
        CAST(analyzed as int) analyzed_plots,
        CAST(GREATEST(0, (plots - flagged - analyzed)) as int) as unanalyzed_plots,
        CAST(users_count.users as int) as contributors,
        created_date, published_date, closed_date, archived_date,
        user_stats
    FROM sums, users_count, user_agg

$$ LANGUAGE SQL;

--
--  AGGREGATE FUNCTIONS
--

-- Returns project aggregate data
CREATE OR REPLACE FUNCTION dump_project_plot_data(_project_id integer)
 RETURNS table (
    plot_id                    integer,
    center_lon                 double precision,
    center_lat                 double precision,
    size_m                     text,
    shape                      real,
    email                      text,
    flagged                    boolean,
    flagged_reason             text,
    confidence                 integer,
    collection_time            timestamp,
    analysis_duration          numeric,
    samples                    text,
    common_securewatch_date    text,
    total_securewatch_dates    integer,
    extra_plot_info            jsonb
 ) AS $$

    SELECT plot_uid,
        ST_X(ST_Centroid(plot_geom)) AS lon,
        ST_Y(ST_Centroid(plot_geom)) AS lat,
        plot_shape,
        plot_size,
        email,
        flagged,
        flagged_reason,
        confidence,
        collection_time,
        ROUND(EXTRACT(EPOCH FROM (collection_time - collection_start))::numeric, 1) AS analysis_duration,
        FORMAT('[%s]', STRING_AGG(
            (CASE WHEN saved_answers IS NULL THEN
                FORMAT('{"%s":"%s"}', 'id', sample_uid)
            ELSE
                FORMAT('{"%s":"%s", "%s":%s}', 'id', sample_uid, 'saved_answers', saved_answers)
            END),', '
        )) AS samples,
        MODE() WITHIN GROUP (ORDER BY imagery_attributes->>'imagerySecureWatchDate') AS common_securewatch_date,
        COUNT(DISTINCT(imagery_attributes->>'imagerySecureWatchDate'))::int AS total_securewatch_dates,
        extra_plot_info
    FROM projects p
    INNER JOIN plots pl
        ON project_uid = pl.project_rid
    INNER JOIN samples s
        ON s.plot_rid = pl.plot_uid
    LEFT JOIN user_plots up
        ON up.plot_rid = pl.plot_uid
    LEFT JOIN sample_values sv
        ON sv.sample_rid = s.sample_uid
        AND user_plot_uid = sv.user_plot_rid
    LEFT JOIN users u
        ON u.user_uid = up.user_rid
    WHERE project_rid = _project_id
    GROUP BY project_uid, plot_uid, user_plot_uid, email, extra_plot_info
    ORDER BY plot_uid

$$ LANGUAGE SQL;

-- Returns project raw data
CREATE OR REPLACE FUNCTION dump_project_sample_data(_project_id integer)
 RETURNS table (
        plot_id               integer,
        sample_id             integer,
        lon                   double precision,
        lat                   double precision,
        email                 text,
        flagged               boolean,
        collection_time       timestamp,
        analysis_duration     numeric,
        imagery_title         text,
        imagery_attributes    text,
        sample_geom           text,
        saved_answers         jsonb,
        extra_plot_info       jsonb,
        extra_sample_info     jsonb
 ) AS $$

    SELECT plot_uid,
        sample_uid,
        ST_X(ST_Centroid(sample_geom)) AS lon,
        ST_Y(ST_Centroid(sample_geom)) AS lat,
        email,
        flagged,
        collection_time,
        ROUND(EXTRACT(EPOCH FROM (collection_time - collection_start))::numeric, 1) AS analysis_duration,
        title AS imagery_title,
        imagery_attributes::text,
        ST_AsText(sample_geom),
        saved_answers,
        extra_plot_info,
        extra_sample_info
    FROM plots pl
    INNER JOIN samples s
        ON s.plot_rid = pl.plot_uid
    LEFT JOIN user_plots up
        ON up.plot_rid = pl.plot_uid
    LEFT JOIN sample_values sv
        ON sample_uid = sv.sample_rid
        AND user_plot_uid = sv.user_plot_rid
    LEFT JOIN imagery
        ON imagery_uid = sv.imagery_rid
    LEFT JOIN users u
        ON u.user_uid = up.user_rid
    WHERE pl.project_rid = _project_id
    ORDER BY plot_uid, sample_uid

$$ LANGUAGE SQL;
