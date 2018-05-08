--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.12
-- Dumped by pg_dump version 9.5.12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: konga_api_health_checks; Type: TABLE; Schema: public; Owner: konga
--

CREATE TABLE public.konga_api_health_checks (
    id integer NOT NULL,
    api_id text,
    api json,
    health_check_endpoint text,
    notification_endpoint text,
    active boolean,
    data json,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    "createdUserId" integer,
    "updatedUserId" integer
);


ALTER TABLE public.konga_api_health_checks OWNER TO konga;

--
-- Name: konga_api_health_checks_id_seq; Type: SEQUENCE; Schema: public; Owner: konga
--

CREATE SEQUENCE public.konga_api_health_checks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.konga_api_health_checks_id_seq OWNER TO konga;

--
-- Name: konga_api_health_checks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: konga
--

ALTER SEQUENCE public.konga_api_health_checks_id_seq OWNED BY public.konga_api_health_checks.id;


--
-- Name: konga_email_transports; Type: TABLE; Schema: public; Owner: konga
--

CREATE TABLE public.konga_email_transports (
    id integer NOT NULL,
    name text,
    description text,
    schema json,
    settings json,
    active boolean,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    "createdUserId" integer,
    "updatedUserId" integer
);


ALTER TABLE public.konga_email_transports OWNER TO konga;

--
-- Name: konga_email_transports_id_seq; Type: SEQUENCE; Schema: public; Owner: konga
--

CREATE SEQUENCE public.konga_email_transports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.konga_email_transports_id_seq OWNER TO konga;

--
-- Name: konga_email_transports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: konga
--

ALTER SEQUENCE public.konga_email_transports_id_seq OWNED BY public.konga_email_transports.id;


--
-- Name: konga_kong_nodes; Type: TABLE; Schema: public; Owner: konga
--

CREATE TABLE public.konga_kong_nodes (
    id integer NOT NULL,
    name text,
    type text,
    kong_admin_url text,
    kong_api_key text,
    jwt_algorithm text,
    jwt_key text,
    jwt_secret text,
    kong_version text,
    health_checks boolean,
    health_check_details json,
    active boolean,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    "createdUserId" integer,
    "updatedUserId" integer
);


ALTER TABLE public.konga_kong_nodes OWNER TO konga;

--
-- Name: konga_kong_nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: konga
--

CREATE SEQUENCE public.konga_kong_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.konga_kong_nodes_id_seq OWNER TO konga;

--
-- Name: konga_kong_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: konga
--

ALTER SEQUENCE public.konga_kong_nodes_id_seq OWNED BY public.konga_kong_nodes.id;


--
-- Name: konga_kong_snapshot_schedules; Type: TABLE; Schema: public; Owner: konga
--

CREATE TABLE public.konga_kong_snapshot_schedules (
    id integer NOT NULL,
    connection integer,
    active boolean,
    cron text,
    "lastRunAt" date,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    "createdUserId" integer,
    "updatedUserId" integer
);


ALTER TABLE public.konga_kong_snapshot_schedules OWNER TO konga;

--
-- Name: konga_kong_snapshot_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: konga
--

CREATE SEQUENCE public.konga_kong_snapshot_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.konga_kong_snapshot_schedules_id_seq OWNER TO konga;

--
-- Name: konga_kong_snapshot_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: konga
--

ALTER SEQUENCE public.konga_kong_snapshot_schedules_id_seq OWNED BY public.konga_kong_snapshot_schedules.id;


--
-- Name: konga_kong_snapshots; Type: TABLE; Schema: public; Owner: konga
--

CREATE TABLE public.konga_kong_snapshots (
    id integer NOT NULL,
    name text,
    kong_node_name text,
    kong_node_url text,
    kong_version text,
    data json,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    "createdUserId" integer,
    "updatedUserId" integer
);


ALTER TABLE public.konga_kong_snapshots OWNER TO konga;

--
-- Name: konga_kong_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: konga
--

CREATE SEQUENCE public.konga_kong_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.konga_kong_snapshots_id_seq OWNER TO konga;

--
-- Name: konga_kong_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: konga
--

ALTER SEQUENCE public.konga_kong_snapshots_id_seq OWNED BY public.konga_kong_snapshots.id;


--
-- Name: konga_passports; Type: TABLE; Schema: public; Owner: konga
--

CREATE TABLE public.konga_passports (
    id integer NOT NULL,
    protocol text,
    password text,
    provider text,
    identifier text,
    tokens json,
    "user" integer,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone
);


ALTER TABLE public.konga_passports OWNER TO konga;

--
-- Name: konga_passports_id_seq; Type: SEQUENCE; Schema: public; Owner: konga
--

CREATE SEQUENCE public.konga_passports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.konga_passports_id_seq OWNER TO konga;

--
-- Name: konga_passports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: konga
--

ALTER SEQUENCE public.konga_passports_id_seq OWNED BY public.konga_passports.id;


--
-- Name: konga_settings; Type: TABLE; Schema: public; Owner: konga
--

CREATE TABLE public.konga_settings (
    id integer NOT NULL,
    data json,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    "createdUserId" integer,
    "updatedUserId" integer
);


ALTER TABLE public.konga_settings OWNER TO konga;

--
-- Name: konga_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: konga
--

CREATE SEQUENCE public.konga_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.konga_settings_id_seq OWNER TO konga;

--
-- Name: konga_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: konga
--

ALTER SEQUENCE public.konga_settings_id_seq OWNED BY public.konga_settings.id;


--
-- Name: konga_users; Type: TABLE; Schema: public; Owner: konga
--

CREATE TABLE public.konga_users (
    id integer NOT NULL,
    username text,
    email text,
    "firstName" text,
    "lastName" text,
    admin boolean,
    node_id text,
    active boolean,
    "activationToken" text,
    node integer,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    "createdUserId" integer,
    "updatedUserId" integer
);


ALTER TABLE public.konga_users OWNER TO konga;

--
-- Name: konga_users_id_seq; Type: SEQUENCE; Schema: public; Owner: konga
--

CREATE SEQUENCE public.konga_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.konga_users_id_seq OWNER TO konga;

--
-- Name: konga_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: konga
--

ALTER SEQUENCE public.konga_users_id_seq OWNED BY public.konga_users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_api_health_checks ALTER COLUMN id SET DEFAULT nextval('public.konga_api_health_checks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_email_transports ALTER COLUMN id SET DEFAULT nextval('public.konga_email_transports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_kong_nodes ALTER COLUMN id SET DEFAULT nextval('public.konga_kong_nodes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_kong_snapshot_schedules ALTER COLUMN id SET DEFAULT nextval('public.konga_kong_snapshot_schedules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_kong_snapshots ALTER COLUMN id SET DEFAULT nextval('public.konga_kong_snapshots_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_passports ALTER COLUMN id SET DEFAULT nextval('public.konga_passports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_settings ALTER COLUMN id SET DEFAULT nextval('public.konga_settings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_users ALTER COLUMN id SET DEFAULT nextval('public.konga_users_id_seq'::regclass);


--
-- Data for Name: konga_api_health_checks; Type: TABLE DATA; Schema: public; Owner: konga
--

COPY public.konga_api_health_checks (id, api_id, api, health_check_endpoint, notification_endpoint, active, data, "createdAt", "updatedAt", "createdUserId", "updatedUserId") FROM stdin;
1	99d3ea5d-c4c4-4afe-bd3f-298f24c520f7	{"created_at":1524029631256,"strip_uri":true,"id":"99d3ea5d-c4c4-4afe-bd3f-298f24c520f7","hosts":["nma-dev.conaltuohy.com"],"name":"nma-api-dev","methods":["GET"],"http_if_terminated":false,"https_only":false,"retries":5,"uris":["/object","/party","/place","/media","/collection"],"preserve_host":false,"upstream_connect_timeout":60000,"upstream_read_timeout":60000,"upstream_send_timeout":60000,"upstream_url":"http://nma-dev.conaltuohy.com/api"}			f	\N	2018-04-18 05:33:59+00	2018-04-18 05:33:59+00	\N	\N
\.


--
-- Name: konga_api_health_checks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: konga
--

SELECT pg_catalog.setval('public.konga_api_health_checks_id_seq', 1, true);


--
-- Data for Name: konga_email_transports; Type: TABLE DATA; Schema: public; Owner: konga
--

COPY public.konga_email_transports (id, name, description, schema, settings, active, "createdAt", "updatedAt", "createdUserId", "updatedUserId") FROM stdin;
1	smtp	Send emails using the SMTP protocol	[{"name":"host","description":"The SMTP host","type":"text","required":true},{"name":"port","description":"The SMTP port","type":"text","required":true},{"name":"username","model":"auth.user","description":"The SMTP user username","type":"text","required":true},{"name":"password","model":"auth.pass","description":"The SMTP user password","type":"text","required":true},{"name":"secure","model":"secure","description":"Use secure connection","type":"boolean"}]	{"host":"","port":"","auth":{"user":"","pass":""},"secure":false}	t	2018-04-18 04:39:30+00	2018-04-18 05:40:23+00	\N	\N
2	sendmail	Pipe messages to the sendmail command	\N	{"sendmail":true}	f	2018-04-18 04:39:30+00	2018-04-18 05:40:23+00	\N	\N
3	mailgun	Send emails through Mailgun’s Web API	[{"name":"api_key","model":"auth.api_key","description":"The API key that you got from www.mailgun.com/cp","type":"text","required":true},{"name":"domain","model":"auth.domain","description":"One of your domain names listed at your https://mailgun.com/app/domains","type":"text","required":true}]	{"auth":{"api_key":"","domain":""}}	f	2018-04-18 04:39:30+00	2018-04-18 05:40:23+00	\N	\N
\.


--
-- Name: konga_email_transports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: konga
--

SELECT pg_catalog.setval('public.konga_email_transports_id_seq', 3, true);


--
-- Data for Name: konga_kong_nodes; Type: TABLE DATA; Schema: public; Owner: konga
--

COPY public.konga_kong_nodes (id, name, type, kong_admin_url, kong_api_key, jwt_algorithm, jwt_key, jwt_secret, kong_version, health_checks, health_check_details, active, "createdAt", "updatedAt", "createdUserId", "updatedUserId") FROM stdin;
1	default	default	http://kong:8001		HS256	\N	\N	0-10-x	f	\N	t	2018-04-18 04:39:30+00	2018-04-18 04:39:30+00	\N	\N
2	NMA	default	http://localhost:8001		HS256	\N	\N	0.13.0	f	\N	f	2018-04-18 05:17:47+00	2018-04-18 05:17:48+00	1	1
\.


--
-- Name: konga_kong_nodes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: konga
--

SELECT pg_catalog.setval('public.konga_kong_nodes_id_seq', 2, true);


--
-- Data for Name: konga_kong_snapshot_schedules; Type: TABLE DATA; Schema: public; Owner: konga
--

COPY public.konga_kong_snapshot_schedules (id, connection, active, cron, "lastRunAt", "createdAt", "updatedAt", "createdUserId", "updatedUserId") FROM stdin;
\.


--
-- Name: konga_kong_snapshot_schedules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: konga
--

SELECT pg_catalog.setval('public.konga_kong_snapshot_schedules_id_seq', 1, false);


--
-- Data for Name: konga_kong_snapshots; Type: TABLE DATA; Schema: public; Owner: konga
--

COPY public.konga_kong_snapshots (id, name, kong_node_name, kong_node_url, kong_version, data, "createdAt", "updatedAt", "createdUserId", "updatedUserId") FROM stdin;
\.


--
-- Name: konga_kong_snapshots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: konga
--

SELECT pg_catalog.setval('public.konga_kong_snapshots_id_seq', 1, false);


--
-- Data for Name: konga_passports; Type: TABLE DATA; Schema: public; Owner: konga
--

COPY public.konga_passports (id, protocol, password, provider, identifier, tokens, "user", "createdAt", "updatedAt") FROM stdin;
1	local	$2a$10$DGe7nejOEPGQmvYMcuvuQ.0uKPorAEqsGtlpe9goIHmoE3ZJQzFW2	\N	\N	\N	1	2018-04-18 04:39:30+00	2018-04-18 04:39:30+00
2	local	$2a$10$iWt3RWqKv6Y4LKfRZKHQnuhXPkzjtaTsWO8IToT3sDMWKcffHSJrC	\N	\N	\N	2	2018-04-18 04:39:30+00	2018-04-18 04:39:30+00
3	local	$2a$10$QSgQf4A7uJo4oicqqc1wuOJ.SroJbPn2Io5t.kfV9B7YnJM9nFq2.	\N	\N	\N	1	2018-04-18 04:44:58+00	2018-04-18 04:44:58+00
4	local	$2a$10$mCDM/dMF3sKytHt1hiTEtOMj48qULxBsEkS99COeq6WhNW9roTDWm	\N	\N	\N	2	2018-04-18 04:44:58+00	2018-04-18 04:44:58+00
5	local	$2a$10$YShKBEwJF67mqkukUOQUDuPYtu0PCntxisNaEtBVoVmnzj5GrwTHm	\N	\N	\N	1	2018-04-18 04:59:03+00	2018-04-18 04:59:03+00
6	local	$2a$10$98YCT/8WzAATdWccu/2SOu8nbG3jU3/ULdMcU71eKiYEZh4La9NU.	\N	\N	\N	2	2018-04-18 04:59:03+00	2018-04-18 04:59:03+00
7	local	$2a$10$6lCUDf483Ttct2u4S/uLe.4/AwJteKr8iMwBgCq/5kjkAnYDPWbAS	\N	\N	\N	1	2018-04-18 05:01:25+00	2018-04-18 05:01:25+00
8	local	$2a$10$W/gH6RYsyntbTxS/rjvcme.v5Q77mo7Qv/mjnpGJyH1XTstsRAz2i	\N	\N	\N	2	2018-04-18 05:01:25+00	2018-04-18 05:01:25+00
9	local	$2a$10$tsjJOLKCh78LuMQgwbjBJOGDanjozAcc1KkHsAVg4iITyKvtnb1L.	\N	\N	\N	1	2018-04-18 05:08:39+00	2018-04-18 05:08:39+00
10	local	$2a$10$2N5P0VfbTbbDVel3ay.ktuLqGjhWnJ5UfFY29JKmL.AyEY94LXiSm	\N	\N	\N	2	2018-04-18 05:08:39+00	2018-04-18 05:08:39+00
11	local	$2a$10$TroaqNrAe/Zu8FO51bsV.uGiGg.EPBsbmKzQjP14hKVp5br7NgHTe	\N	\N	\N	1	2018-04-18 05:11:22+00	2018-04-18 05:11:22+00
12	local	$2a$10$5ib9vnAL5GdBVONByiD43ur5yuCqoMJzOsQCu7EV8X.VrS1bTY9wi	\N	\N	\N	2	2018-04-18 05:11:22+00	2018-04-18 05:11:22+00
13	local	$2a$10$AFUu/AKiZtTxotfq4EuibeXc9hIWSPdMCw2PtP4SQBgiz87zSpbmu	\N	\N	\N	1	2018-04-18 05:16:23+00	2018-04-18 05:16:23+00
14	local	$2a$10$AF32oHQxpPPw6h7pWVGsCuo.LkToGG.5hRvLzwZNTYH.fMQKeqqEy	\N	\N	\N	2	2018-04-18 05:16:23+00	2018-04-18 05:16:23+00
15	local	$2a$10$WKvEU1Og2hgnGARCpEFDAuPUNuTLlhvs4okjr6ApdzndRU9Z9KIgq	\N	\N	\N	1	2018-04-18 05:17:10+00	2018-04-18 05:17:10+00
16	local	$2a$10$72j5ENPP3Ev9GeTBq1rQ/enJ3AZF7KVA10pOpDJYIywZ6gzLQHJ2O	\N	\N	\N	2	2018-04-18 05:17:10+00	2018-04-18 05:17:10+00
17	local	$2a$10$Xt0gd.jBkC6xJGklw0r6bumBI84/A//LBwRCWIJazTBsdV0k2bi6q	\N	\N	\N	2	2018-04-18 05:40:23+00	2018-04-18 05:40:23+00
18	local	$2a$10$Kryeoxl3pz1nsZpeiLjoqeNV8zj2nrJDYaaU0rkXMhXOMdLcM8ERC	\N	\N	\N	1	2018-04-18 05:40:23+00	2018-04-18 05:40:23+00
\.


--
-- Name: konga_passports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: konga
--

SELECT pg_catalog.setval('public.konga_passports_id_seq', 18, true);


--
-- Data for Name: konga_settings; Type: TABLE DATA; Schema: public; Owner: konga
--

COPY public.konga_settings (id, data, "createdAt", "updatedAt", "createdUserId", "updatedUserId") FROM stdin;
1	{"signup_enable":false,"signup_require_activation":false,"info_polling_interval":5000,"email_default_sender_name":"KONGA","email_default_sender":"konga@konga.test","email_notifications":false,"default_transport":"sendmail","notify_when":{"node_down":{"title":"A node is down or unresponsive","description":"Health checks must be enabled for the nodes that need to be monitored.","active":false},"api_down":{"title":"An API is down or unresponsive","description":"Health checks must be enabled for the APIs that need to be monitored.","active":false}},"integrations":[{"id":"slack","name":"Slack","image":"slack_rgb.png","config":{"enabled":false,"fields":[{"id":"slack_webhook_url","name":"Slack Webhook URL","type":"text","required":true,"value":""}],"slack_webhook_url":""}}],"user_permissions":{"apis":{"create":false,"read":true,"update":false,"delete":false},"consumers":{"create":false,"read":true,"update":false,"delete":false},"plugins":{"create":false,"read":true,"update":false,"delete":false},"upstreams":{"create":false,"read":true,"update":false,"delete":false},"certificates":{"create":false,"read":true,"update":false,"delete":false},"connections":{"create":false,"read":true,"update":false,"delete":false},"users":{"create":false,"read":true,"update":false,"delete":false}}}	2018-04-18 04:39:31+00	2018-04-18 05:40:23+00	\N	\N
\.


--
-- Name: konga_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: konga
--

SELECT pg_catalog.setval('public.konga_settings_id_seq', 1, true);


--
-- Data for Name: konga_users; Type: TABLE DATA; Schema: public; Owner: konga
--

COPY public.konga_users (id, username, email, "firstName", "lastName", admin, node_id, active, "activationToken", node, "createdAt", "updatedAt", "createdUserId", "updatedUserId") FROM stdin;
2	demo	demo@some.domain	John	Doe	f	http://kong:8001	t	8ec8f312-ab16-4679-b756-f5fa8bc1791c	\N	2018-04-18 04:39:30+00	2018-04-18 04:39:31+00	\N	\N
1	admin	admin@some.domain	Arnold	Administrator	t	http://kong:8001	t	8ec8f312-ab16-4679-b756-f5fa8bc1791c	2	2018-04-18 04:39:30+00	2018-04-18 05:17:48+00	\N	1
\.


--
-- Name: konga_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: konga
--

SELECT pg_catalog.setval('public.konga_users_id_seq', 2, true);


--
-- Name: konga_api_health_checks_api_id_key; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_api_health_checks
    ADD CONSTRAINT konga_api_health_checks_api_id_key UNIQUE (api_id);


--
-- Name: konga_api_health_checks_pkey; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_api_health_checks
    ADD CONSTRAINT konga_api_health_checks_pkey PRIMARY KEY (id);


--
-- Name: konga_email_transports_name_key; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_email_transports
    ADD CONSTRAINT konga_email_transports_name_key UNIQUE (name);


--
-- Name: konga_email_transports_pkey; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_email_transports
    ADD CONSTRAINT konga_email_transports_pkey PRIMARY KEY (id);


--
-- Name: konga_kong_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_kong_nodes
    ADD CONSTRAINT konga_kong_nodes_pkey PRIMARY KEY (id);


--
-- Name: konga_kong_snapshot_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_kong_snapshot_schedules
    ADD CONSTRAINT konga_kong_snapshot_schedules_pkey PRIMARY KEY (id);


--
-- Name: konga_kong_snapshots_name_key; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_kong_snapshots
    ADD CONSTRAINT konga_kong_snapshots_name_key UNIQUE (name);


--
-- Name: konga_kong_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_kong_snapshots
    ADD CONSTRAINT konga_kong_snapshots_pkey PRIMARY KEY (id);


--
-- Name: konga_passports_pkey; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_passports
    ADD CONSTRAINT konga_passports_pkey PRIMARY KEY (id);


--
-- Name: konga_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_settings
    ADD CONSTRAINT konga_settings_pkey PRIMARY KEY (id);


--
-- Name: konga_users_email_key; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_users
    ADD CONSTRAINT konga_users_email_key UNIQUE (email);


--
-- Name: konga_users_pkey; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_users
    ADD CONSTRAINT konga_users_pkey PRIMARY KEY (id);


--
-- Name: konga_users_username_key; Type: CONSTRAINT; Schema: public; Owner: konga
--

ALTER TABLE ONLY public.konga_users
    ADD CONSTRAINT konga_users_username_key UNIQUE (username);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

