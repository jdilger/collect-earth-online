DROP DATABASE IF EXISTS ceo;
DROP ROLE IF EXISTS ceo;
CREATE ROLE ceo WITH LOGIN CREATEDB PASSWORD 'ceo'; --ommit after created once
CREATE DATABASE ceo WITH OWNER ceo;
\c ceo
CREATE EXTENSION postgis;