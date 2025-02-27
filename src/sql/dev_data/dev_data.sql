-- NAMESPACE: dev-data

-- Adds an administrator and a user
INSERT INTO users
    (user_uid, email, password, administrator, reset_key, verified)
VALUES
    (1, 'admin@ceo.dev', crypt('admin', gen_salt('bf')), TRUE, null, TRUE),
    (2, 'user@ceo.dev', crypt('user', gen_salt('bf')), FALSE, null, TRUE),
    (3, 'test@ceo.dev', crypt('test', gen_salt('bf')), FALSE, null, TRUE);

SELECT setval(pg_get_serial_sequence('users', 'user_uid'), (SELECT MAX(user_uid) FROM users) + 1);

-- Adds an institution
INSERT INTO institutions
    (institution_uid, name, description, url)
VALUES
    (1, 'DEV Institution', 'DEV Institution Description', 'https://collect.earth');

SELECT setval(pg_get_serial_sequence('institutions', 'institution_uid'), (SELECT MAX(institution_uid) FROM institutions) + 1);

-- Adds administrator and user to an institution
INSERT INTO institution_users
    (inst_user_uid, institution_rid, user_rid, role_rid)
VALUES
    (1, 1, 1, 1),
    (2, 1, 2, 1),
    (3, 1, 3, 2);

SELECT setval(pg_get_serial_sequence('institution_users', 'inst_user_uid'), (SELECT MAX(inst_user_uid) FROM institution_users) + 1);

-- Adds an institution imagery
INSERT INTO imagery
    (imagery_uid, institution_rid, visibility, title, attribution, extent, source_config)
VALUES
    (1, 1, 'public', 'Open Street Maps', 'Open Street Maps', null, '{"type": "OSM"}');

SELECT setval(pg_get_serial_sequence('imagery', 'imagery_uid'), (SELECT MAX(imagery_uid) FROM imagery) + 1);

-- Adds a project
INSERT INTO projects (
    project_uid,
    institution_rid,
    availability,
    name,
    description,
    privacy_level,
    boundary,
    plot_distribution,
    num_plots,
    plot_shape,
    plot_size,
    sample_distribution,
    samples_per_plot,
    survey_questions,
    survey_rules,
    published_date,
    created_date,
    options,
    imagery_rid,
    allow_drawn_samples,
    aoi_features
) VALUES (
    1,
    1,
    'published',
    'Test Project',
    'This project is a default project for development testing.',
    'public',
    ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[95,10.5],[95,22.5],[107,22.5],[107,10.5],[95,10.5]]]}'), 4326),
    'random',
    3,
    'circle',
    200,
    'random',
    10,
    '{"0":{"answers":{"0":{"color":"#1ec61b","answer":"Forest"},"1":{"color":"#9cf135","answer":"Grassland"},"2":{"color":"#d5de85","answer":"Bare Surface"},"3":{"color":"#8b9084","answer":"Impervious Surface"},"4":{"color":"#f2c613","answer":"Agriculture"},"5":{"color":"#6a3a75","answer":"Urban"},"6":{"color":"#2f4dc0","answer":"Water"},"7":{"color":"#ffffff","answer":"Cloud"},"8":{"color":"#000000","answer":"Unknown"}},"dataType":"text","question":"Land Use","componentType":"button","parentAnswerIds":[],"parentQuestionId":-1},"1":{"answers":{"0":{"color":"#1527f6","answer":"Placeholder Text"}},"dataType":"text","question":"Test Regex Match","componentType":"input","parentAnswerIds":[],"parentQuestionId":-1},"2":{"answers":{"0":{"color":"#1527f6","answer":"100"}},"dataType":"number","question":"Test Numeric Range","componentType":"input","parentAnswerIds":[],"parentQuestionId":-1},"3":{"answers":{"0":{"color":"#1527f6","answer":"100"}},"dataType":"number","question":"Test Sum of Answers","componentType":"input","parentAnswerIds":[],"parentQuestionId":-1},"4":{"answers":{"0":{"color":"#1527f6","answer":"100"}},"dataType":"number","question":"Test Matching Sums 1","componentType":"input","parentAnswerIds":[],"parentQuestionId":-1},"5":{"answers":{"0":{"color":"#1527f6","answer":"100"}},"dataType":"number","question":"Test Matching Sums 2","componentType":"input","parentAnswerIds":[],"parentQuestionId":-1},"6":{"answers":{"0":{"color":"#1ec61b","answer":"Forest"},"1":{"color":"#9cf135","answer":"Grassland"},"2":{"color":"#d5de85","answer":"Bare Surface"},"3":{"color":"#8b9084","answer":"Impervious Surface"},"4":{"color":"#f2c613","answer":"Agriculture"},"5":{"color":"#6a3a75","answer":"Urban"},"6":{"color":"#2f4dc0","answer":"Water"},"7":{"color":"#ffffff","answer":"Cloud"},"8":{"color":"#000000","answer":"Unknown"}},"dataType":"text","question":"Test Incompatible Answers","componentType":"button","parentAnswerIds":[],"parentQuestionId":-1}}',
    '[{"id":0,"regex":"^[a-zA-Z0-9_.-]*$","ruleType":"text-match","questionId":1},{"id":1,"max":100,"min":0,"ruleType":"numeric-range","questionId":2},{"id":2,"ruleType":"sum-of-answers","validSum":200,"questionIds":[2,3]},{"id":3,"ruleType":"matching-sums","questionIds1":[2,3],"questionIds2":[4,5]},{"id":4,"ruleType":"incompatible-answers","answerId1":0,"answerId2":8,"questionId1":0,"questionId2":6}]',
    Now(),
    Now(),
    '{"showGEEScript": false, "autoLaunchGeoDash": false, "collectConfidence": true, "showPlotInformation": false}',
    1,
    FALSE,
    '[{"type": "Polygon", "coordinates": [[[95, 10.5], [95, 22.5], [107, 22.5], [107, 10.5], [95, 10.5]]]}]'
);

SELECT setval(pg_get_serial_sequence('projects', 'project_uid'), (SELECT MAX(project_uid) FROM projects) + 1);

-- Adds imagery associated with a project
INSERT INTO project_imagery
    (project_rid, imagery_rid)
VALUES
    (1, 1);

-- Add 4 plots
INSERT INTO plots
    (plot_uid, project_rid, plot_geom, visible_id)
VALUES
    (1, 1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999640127073,22.0468074686287]}'), 4326), 1),
    (2, 1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5680216776391,12.3793535946933]}'), 4326), 2),
    (3, 1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.718471401115,13.7459074361384]}'), 4326), 3);

SELECT setval(pg_get_serial_sequence('plots', 'plot_uid'), (SELECT MAX(plot_uid) FROM plots) + 1);

-- Add 10 samples per 3 plots
INSERT INTO samples
    (plot_rid, sample_geom, visible_id)
VALUES
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[103.000003879452,22.0468975929135]}'), 4326), 1),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999659597506,22.0468036237562]}'), 4326), 2),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999501703938,22.0467991514296]}'), 4326), 3),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.998949185863,22.0466248615901]}'), 4326), 4),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.99966198978,22.0466084221078]}'), 4326), 5),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999566464554,22.0463120389197]}'), 4326), 6),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999740489714,22.0468942725417]}'), 4326), 7),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999223221942,22.0465117917509]}'), 4326), 8),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999452134532,22.0466484482659]}'), 4326), 9),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999890834681,22.0467964915768]}'), 4326), 10),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[103.000254645522,22.04669295608]}'), 4326), 11),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999719482979,22.0465994297173]}'), 4326), 12),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999139315219,22.0466135869806]}'), 4326), 13),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999807083116,22.0466539723281]}'), 4326), 14),
    (1, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[102.999723982592,22.0474907559667]}'), 4326), 15),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5680208639992,12.3792772955153]}'), 4326), 16),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5681408052842,12.378997629299]}'), 4326), 17),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5674893527881,12.3791403221257]}'), 4326), 18),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5676406856725,12.3790404496009]}'), 4326), 19),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5680795299306,12.3792172223556]}'), 4326), 20),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5685366624246,12.3787821289617]}'), 4326), 21),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5680099128529,12.3795410368552]}'), 4326), 22),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5681464703452,12.3792672309771]}'), 4326), 23),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5673981032599,12.3791330862771]}'), 4326), 24),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5688706092875,12.3796102435328]}'), 4326), 25),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5684360084512,12.3792116012074]}'), 4326), 26),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5681511311399,12.3795313477436]}'), 4326), 27),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5673749749785,12.3789225927278]}'), 4326), 28),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5679345010481,12.3795452545641]}'), 4326), 29),
    (2, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[98.5677401971136,12.3791719391359]}'), 4326), 30),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.719017040138,13.7464939415532]}'), 4326), 31),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.718555513054,13.7463215099279]}'), 4326), 32),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.7185236659,13.7464061467244]}'), 4326), 33),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.718791845779,13.7464815711221]}'), 4326), 34),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.718712185681,13.7457456666488]}'), 4326), 35),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.717733763325,13.7459559669583]}'), 4326), 36),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.718182494124,13.7456356732466]}'), 4326), 37),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.718202305812,13.7457602170494]}'), 4326), 38),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.718580714415,13.7457414612821]}'), 4326), 39),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.718156929973,13.7455628153881]}'), 4326), 40),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.718658109221,13.74519156337]}'), 4326), 41),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.717683299127,13.7458568865769]}'), 4326), 42),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.718498811146,13.7459316835242]}'), 4326), 43),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.718562527415,13.7452788216232]}'), 4326), 44),
    (3, ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[106.717809924561,13.7458799404487]}'), 4326), 45);

-- Add 3 widgets
INSERT INTO project_widgets
    (project_rid, widget)
VALUES
    (1, '{"name":"Image Collection","type":"preImageCollection","layout":{"h":1,"w":3,"x":0,"y":0},"endDate":"2022-01-07","basemapId":1,"indexName":"NDVI","startDate":"2022-01-01"}'),
    (1, '{"name":"Time Series Graph","type":"timeSeries","layout":{"h":1,"w":3,"x":3,"y":0},"endDate":"2022-01-07","indexName":"EVI","startDate":"2017-12-31"}'),
    (1, '{"name":"Statistics","type":"statistics","layout":{"h":1,"w":3,"x":6,"y":0}}');
