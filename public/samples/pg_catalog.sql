--
-- PostgreSQL database dump
--

-- Dumped from database version 12.12 (Ubuntu 12.12-1.pgdg20.04+1)
-- Dumped by pg_dump version 12.12 (Ubuntu 12.12-1.pgdg20.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: pg_aggregate; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_aggregate (
    aggfnoid regproc NOT NULL,
    aggkind "char" NOT NULL,
    aggnumdirectargs smallint NOT NULL,
    aggtransfn regproc NOT NULL,
    aggfinalfn regproc NOT NULL,
    aggcombinefn regproc NOT NULL,
    aggserialfn regproc NOT NULL,
    aggdeserialfn regproc NOT NULL,
    aggmtransfn regproc NOT NULL,
    aggminvtransfn regproc NOT NULL,
    aggmfinalfn regproc NOT NULL,
    aggfinalextra boolean NOT NULL,
    aggmfinalextra boolean NOT NULL,
    aggfinalmodify "char" NOT NULL,
    aggmfinalmodify "char" NOT NULL,
    aggsortop oid NOT NULL,
    aggtranstype oid NOT NULL,
    aggtransspace integer NOT NULL,
    aggmtranstype oid NOT NULL,
    aggmtransspace integer NOT NULL,
    agginitval text COLLATE pg_catalog."C",
    aggminitval text COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_aggregate REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_aggregate OWNER TO postgres;

--
-- Name: pg_am; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_am (
    oid oid NOT NULL,
    amname name NOT NULL,
    amhandler regproc NOT NULL,
    amtype "char" NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_am REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_am OWNER TO postgres;

--
-- Name: pg_amop; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_amop (
    oid oid NOT NULL,
    amopfamily oid NOT NULL,
    amoplefttype oid NOT NULL,
    amoprighttype oid NOT NULL,
    amopstrategy smallint NOT NULL,
    amoppurpose "char" NOT NULL,
    amopopr oid NOT NULL,
    amopmethod oid NOT NULL,
    amopsortfamily oid NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_amop REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_amop OWNER TO postgres;

--
-- Name: pg_amproc; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_amproc (
    oid oid NOT NULL,
    amprocfamily oid NOT NULL,
    amproclefttype oid NOT NULL,
    amprocrighttype oid NOT NULL,
    amprocnum smallint NOT NULL,
    amproc regproc NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_amproc REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_amproc OWNER TO postgres;

--
-- Name: pg_attrdef; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_attrdef (
    oid oid NOT NULL,
    adrelid oid NOT NULL,
    adnum smallint NOT NULL,
    adbin pg_node_tree NOT NULL COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_attrdef REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_attrdef OWNER TO postgres;

--
-- Name: pg_attribute; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_attribute (
    attrelid oid NOT NULL,
    attname name NOT NULL,
    atttypid oid NOT NULL,
    attstattarget integer NOT NULL,
    attlen smallint NOT NULL,
    attnum smallint NOT NULL,
    attndims integer NOT NULL,
    attcacheoff integer NOT NULL,
    atttypmod integer NOT NULL,
    attbyval boolean NOT NULL,
    attstorage "char" NOT NULL,
    attalign "char" NOT NULL,
    attnotnull boolean NOT NULL,
    atthasdef boolean NOT NULL,
    atthasmissing boolean NOT NULL,
    attidentity "char" NOT NULL,
    attgenerated "char" NOT NULL,
    attisdropped boolean NOT NULL,
    attislocal boolean NOT NULL,
    attinhcount integer NOT NULL,
    attcollation oid NOT NULL,
    attacl aclitem[],
    attoptions text[] COLLATE pg_catalog."C",
    attfdwoptions text[] COLLATE pg_catalog."C",
    attmissingval anyarray
);

ALTER TABLE ONLY pg_catalog.pg_attribute REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_attribute OWNER TO postgres;

SET default_tablespace = pg_global;

--
-- Name: pg_auth_members; Type: TABLE; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE TABLE pg_catalog.pg_auth_members (
    roleid oid NOT NULL,
    member oid NOT NULL,
    grantor oid NOT NULL,
    admin_option boolean NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_auth_members REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_auth_members OWNER TO postgres;

--
-- Name: pg_authid; Type: TABLE; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE TABLE pg_catalog.pg_authid (
    oid oid NOT NULL,
    rolname name NOT NULL,
    rolsuper boolean NOT NULL,
    rolinherit boolean NOT NULL,
    rolcreaterole boolean NOT NULL,
    rolcreatedb boolean NOT NULL,
    rolcanlogin boolean NOT NULL,
    rolreplication boolean NOT NULL,
    rolbypassrls boolean NOT NULL,
    rolconnlimit integer NOT NULL,
    rolpassword text COLLATE pg_catalog."C",
    rolvaliduntil timestamp with time zone
);

ALTER TABLE ONLY pg_catalog.pg_authid REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_authid OWNER TO postgres;

--
-- Name: pg_available_extension_versions; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_available_extension_versions AS
 SELECT e.name,
    e.version,
    (x.extname IS NOT NULL) AS installed,
    e.superuser,
    e.relocatable,
    e.schema,
    e.requires,
    e.comment
   FROM (pg_available_extension_versions() e(name, version, superuser, relocatable, schema, requires, comment)
     LEFT JOIN pg_extension x ON (((e.name = x.extname) AND (e.version = x.extversion))));


ALTER TABLE pg_catalog.pg_available_extension_versions OWNER TO postgres;

--
-- Name: pg_available_extensions; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_available_extensions AS
 SELECT e.name,
    e.default_version,
    x.extversion AS installed_version,
    e.comment
   FROM (pg_available_extensions() e(name, default_version, comment)
     LEFT JOIN pg_extension x ON ((e.name = x.extname)));


ALTER TABLE pg_catalog.pg_available_extensions OWNER TO postgres;

SET default_tablespace = '';

--
-- Name: pg_cast; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_cast (
    oid oid NOT NULL,
    castsource oid NOT NULL,
    casttarget oid NOT NULL,
    castfunc oid NOT NULL,
    castcontext "char" NOT NULL,
    castmethod "char" NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_cast REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_cast OWNER TO postgres;

--
-- Name: pg_class; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_class (
    oid oid NOT NULL,
    relname name NOT NULL,
    relnamespace oid NOT NULL,
    reltype oid NOT NULL,
    reloftype oid NOT NULL,
    relowner oid NOT NULL,
    relam oid NOT NULL,
    relfilenode oid NOT NULL,
    reltablespace oid NOT NULL,
    relpages integer NOT NULL,
    reltuples real NOT NULL,
    relallvisible integer NOT NULL,
    reltoastrelid oid NOT NULL,
    relhasindex boolean NOT NULL,
    relisshared boolean NOT NULL,
    relpersistence "char" NOT NULL,
    relkind "char" NOT NULL,
    relnatts smallint NOT NULL,
    relchecks smallint NOT NULL,
    relhasrules boolean NOT NULL,
    relhastriggers boolean NOT NULL,
    relhassubclass boolean NOT NULL,
    relrowsecurity boolean NOT NULL,
    relforcerowsecurity boolean NOT NULL,
    relispopulated boolean NOT NULL,
    relreplident "char" NOT NULL,
    relispartition boolean NOT NULL,
    relrewrite oid NOT NULL,
    relfrozenxid xid NOT NULL,
    relminmxid xid NOT NULL,
    relacl aclitem[],
    reloptions text[] COLLATE pg_catalog."C",
    relpartbound pg_node_tree COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_class REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_class OWNER TO postgres;

--
-- Name: pg_collation; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_collation (
    oid oid NOT NULL,
    collname name NOT NULL,
    collnamespace oid NOT NULL,
    collowner oid NOT NULL,
    collprovider "char" NOT NULL,
    collisdeterministic boolean NOT NULL,
    collencoding integer NOT NULL,
    collcollate name NOT NULL,
    collctype name NOT NULL,
    collversion text COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_collation REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_collation OWNER TO postgres;

--
-- Name: pg_config; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_config AS
 SELECT pg_config.name,
    pg_config.setting
   FROM pg_config() pg_config(name, setting);


ALTER TABLE pg_catalog.pg_config OWNER TO postgres;

--
-- Name: pg_constraint; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_constraint (
    oid oid NOT NULL,
    conname name NOT NULL,
    connamespace oid NOT NULL,
    contype "char" NOT NULL,
    condeferrable boolean NOT NULL,
    condeferred boolean NOT NULL,
    convalidated boolean NOT NULL,
    conrelid oid NOT NULL,
    contypid oid NOT NULL,
    conindid oid NOT NULL,
    conparentid oid NOT NULL,
    confrelid oid NOT NULL,
    confupdtype "char" NOT NULL,
    confdeltype "char" NOT NULL,
    confmatchtype "char" NOT NULL,
    conislocal boolean NOT NULL,
    coninhcount integer NOT NULL,
    connoinherit boolean NOT NULL,
    conkey smallint[],
    confkey smallint[],
    conpfeqop oid[],
    conppeqop oid[],
    conffeqop oid[],
    conexclop oid[],
    conbin pg_node_tree COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_constraint REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_constraint OWNER TO postgres;

--
-- Name: pg_conversion; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_conversion (
    oid oid NOT NULL,
    conname name NOT NULL,
    connamespace oid NOT NULL,
    conowner oid NOT NULL,
    conforencoding integer NOT NULL,
    contoencoding integer NOT NULL,
    conproc regproc NOT NULL,
    condefault boolean NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_conversion REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_conversion OWNER TO postgres;

--
-- Name: pg_cursors; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_cursors AS
 SELECT c.name,
    c.statement,
    c.is_holdable,
    c.is_binary,
    c.is_scrollable,
    c.creation_time
   FROM pg_cursor() c(name, statement, is_holdable, is_binary, is_scrollable, creation_time);


ALTER TABLE pg_catalog.pg_cursors OWNER TO postgres;

SET default_tablespace = pg_global;

--
-- Name: pg_database; Type: TABLE; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE TABLE pg_catalog.pg_database (
    oid oid NOT NULL,
    datname name NOT NULL,
    datdba oid NOT NULL,
    encoding integer NOT NULL,
    datcollate name NOT NULL,
    datctype name NOT NULL,
    datistemplate boolean NOT NULL,
    datallowconn boolean NOT NULL,
    datconnlimit integer NOT NULL,
    datlastsysoid oid NOT NULL,
    datfrozenxid xid NOT NULL,
    datminmxid xid NOT NULL,
    dattablespace oid NOT NULL,
    datacl aclitem[]
);

ALTER TABLE ONLY pg_catalog.pg_database REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_database OWNER TO postgres;

--
-- Name: pg_db_role_setting; Type: TABLE; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE TABLE pg_catalog.pg_db_role_setting (
    setdatabase oid NOT NULL,
    setrole oid NOT NULL,
    setconfig text[] COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_db_role_setting REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_db_role_setting OWNER TO postgres;

SET default_tablespace = '';

--
-- Name: pg_default_acl; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_default_acl (
    oid oid NOT NULL,
    defaclrole oid NOT NULL,
    defaclnamespace oid NOT NULL,
    defaclobjtype "char" NOT NULL,
    defaclacl aclitem[] NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_default_acl REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_default_acl OWNER TO postgres;

--
-- Name: pg_depend; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_depend (
    classid oid NOT NULL,
    objid oid NOT NULL,
    objsubid integer NOT NULL,
    refclassid oid NOT NULL,
    refobjid oid NOT NULL,
    refobjsubid integer NOT NULL,
    deptype "char" NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_depend REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_depend OWNER TO postgres;

--
-- Name: pg_description; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_description (
    objoid oid NOT NULL,
    classoid oid NOT NULL,
    objsubid integer NOT NULL,
    description text NOT NULL COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_description REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_description OWNER TO postgres;

--
-- Name: pg_enum; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_enum (
    oid oid NOT NULL,
    enumtypid oid NOT NULL,
    enumsortorder real NOT NULL,
    enumlabel name NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_enum REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_enum OWNER TO postgres;

--
-- Name: pg_event_trigger; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_event_trigger (
    oid oid NOT NULL,
    evtname name NOT NULL,
    evtevent name NOT NULL,
    evtowner oid NOT NULL,
    evtfoid oid NOT NULL,
    evtenabled "char" NOT NULL,
    evttags text[] COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_event_trigger REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_event_trigger OWNER TO postgres;

--
-- Name: pg_extension; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_extension (
    oid oid NOT NULL,
    extname name NOT NULL,
    extowner oid NOT NULL,
    extnamespace oid NOT NULL,
    extrelocatable boolean NOT NULL,
    extversion text NOT NULL COLLATE pg_catalog."C",
    extconfig oid[],
    extcondition text[] COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_extension REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_extension OWNER TO postgres;

--
-- Name: pg_file_settings; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_file_settings AS
 SELECT a.sourcefile,
    a.sourceline,
    a.seqno,
    a.name,
    a.setting,
    a.applied,
    a.error
   FROM pg_show_all_file_settings() a(sourcefile, sourceline, seqno, name, setting, applied, error);


ALTER TABLE pg_catalog.pg_file_settings OWNER TO postgres;

--
-- Name: pg_foreign_data_wrapper; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_foreign_data_wrapper (
    oid oid NOT NULL,
    fdwname name NOT NULL,
    fdwowner oid NOT NULL,
    fdwhandler oid NOT NULL,
    fdwvalidator oid NOT NULL,
    fdwacl aclitem[],
    fdwoptions text[] COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_foreign_data_wrapper REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_foreign_data_wrapper OWNER TO postgres;

--
-- Name: pg_foreign_server; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_foreign_server (
    oid oid NOT NULL,
    srvname name NOT NULL,
    srvowner oid NOT NULL,
    srvfdw oid NOT NULL,
    srvtype text COLLATE pg_catalog."C",
    srvversion text COLLATE pg_catalog."C",
    srvacl aclitem[],
    srvoptions text[] COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_foreign_server REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_foreign_server OWNER TO postgres;

--
-- Name: pg_foreign_table; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_foreign_table (
    ftrelid oid NOT NULL,
    ftserver oid NOT NULL,
    ftoptions text[] COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_foreign_table REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_foreign_table OWNER TO postgres;

--
-- Name: pg_group; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_group AS
 SELECT pg_authid.rolname AS groname,
    pg_authid.oid AS grosysid,
    ARRAY( SELECT pg_auth_members.member
           FROM pg_auth_members
          WHERE (pg_auth_members.roleid = pg_authid.oid)) AS grolist
   FROM pg_authid
  WHERE (NOT pg_authid.rolcanlogin);


ALTER TABLE pg_catalog.pg_group OWNER TO postgres;

--
-- Name: pg_hba_file_rules; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_hba_file_rules AS
 SELECT a.line_number,
    a.type,
    a.database,
    a.user_name,
    a.address,
    a.netmask,
    a.auth_method,
    a.options,
    a.error
   FROM pg_hba_file_rules() a(line_number, type, database, user_name, address, netmask, auth_method, options, error);


ALTER TABLE pg_catalog.pg_hba_file_rules OWNER TO postgres;

--
-- Name: pg_index; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_index (
    indexrelid oid NOT NULL,
    indrelid oid NOT NULL,
    indnatts smallint NOT NULL,
    indnkeyatts smallint NOT NULL,
    indisunique boolean NOT NULL,
    indisprimary boolean NOT NULL,
    indisexclusion boolean NOT NULL,
    indimmediate boolean NOT NULL,
    indisclustered boolean NOT NULL,
    indisvalid boolean NOT NULL,
    indcheckxmin boolean NOT NULL,
    indisready boolean NOT NULL,
    indislive boolean NOT NULL,
    indisreplident boolean NOT NULL,
    indkey int2vector NOT NULL,
    indcollation oidvector NOT NULL,
    indclass oidvector NOT NULL,
    indoption int2vector NOT NULL,
    indexprs pg_node_tree COLLATE pg_catalog."C",
    indpred pg_node_tree COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_index REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_index OWNER TO postgres;

--
-- Name: pg_indexes; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_indexes AS
 SELECT n.nspname AS schemaname,
    c.relname AS tablename,
    i.relname AS indexname,
    t.spcname AS tablespace,
    pg_get_indexdef(i.oid) AS indexdef
   FROM ((((pg_index x
     JOIN pg_class c ON ((c.oid = x.indrelid)))
     JOIN pg_class i ON ((i.oid = x.indexrelid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
     LEFT JOIN pg_tablespace t ON ((t.oid = i.reltablespace)))
  WHERE ((c.relkind = ANY (ARRAY['r'::"char", 'm'::"char", 'p'::"char"])) AND (i.relkind = ANY (ARRAY['i'::"char", 'I'::"char"])));


ALTER TABLE pg_catalog.pg_indexes OWNER TO postgres;

--
-- Name: pg_inherits; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_inherits (
    inhrelid oid NOT NULL,
    inhparent oid NOT NULL,
    inhseqno integer NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_inherits REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_inherits OWNER TO postgres;

--
-- Name: pg_init_privs; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_init_privs (
    objoid oid NOT NULL,
    classoid oid NOT NULL,
    objsubid integer NOT NULL,
    privtype "char" NOT NULL,
    initprivs aclitem[] NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_init_privs REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_init_privs OWNER TO postgres;

--
-- Name: pg_language; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_language (
    oid oid NOT NULL,
    lanname name NOT NULL,
    lanowner oid NOT NULL,
    lanispl boolean NOT NULL,
    lanpltrusted boolean NOT NULL,
    lanplcallfoid oid NOT NULL,
    laninline oid NOT NULL,
    lanvalidator oid NOT NULL,
    lanacl aclitem[]
);

ALTER TABLE ONLY pg_catalog.pg_language REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_language OWNER TO postgres;

--
-- Name: pg_largeobject; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_largeobject (
    loid oid NOT NULL,
    pageno integer NOT NULL,
    data bytea NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_largeobject REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_largeobject OWNER TO postgres;

--
-- Name: pg_largeobject_metadata; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_largeobject_metadata (
    oid oid NOT NULL,
    lomowner oid NOT NULL,
    lomacl aclitem[]
);

ALTER TABLE ONLY pg_catalog.pg_largeobject_metadata REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_largeobject_metadata OWNER TO postgres;

--
-- Name: pg_locks; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_locks AS
 SELECT l.locktype,
    l.database,
    l.relation,
    l.page,
    l.tuple,
    l.virtualxid,
    l.transactionid,
    l.classid,
    l.objid,
    l.objsubid,
    l.virtualtransaction,
    l.pid,
    l.mode,
    l.granted,
    l.fastpath
   FROM pg_lock_status() l(locktype, database, relation, page, tuple, virtualxid, transactionid, classid, objid, objsubid, virtualtransaction, pid, mode, granted, fastpath);


ALTER TABLE pg_catalog.pg_locks OWNER TO postgres;

--
-- Name: pg_matviews; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_matviews AS
 SELECT n.nspname AS schemaname,
    c.relname AS matviewname,
    pg_get_userbyid(c.relowner) AS matviewowner,
    t.spcname AS tablespace,
    c.relhasindex AS hasindexes,
    c.relispopulated AS ispopulated,
    pg_get_viewdef(c.oid) AS definition
   FROM ((pg_class c
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
     LEFT JOIN pg_tablespace t ON ((t.oid = c.reltablespace)))
  WHERE (c.relkind = 'm'::"char");


ALTER TABLE pg_catalog.pg_matviews OWNER TO postgres;

--
-- Name: pg_namespace; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_namespace (
    oid oid NOT NULL,
    nspname name NOT NULL,
    nspowner oid NOT NULL,
    nspacl aclitem[]
);

ALTER TABLE ONLY pg_catalog.pg_namespace REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_namespace OWNER TO postgres;

--
-- Name: pg_opclass; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_opclass (
    oid oid NOT NULL,
    opcmethod oid NOT NULL,
    opcname name NOT NULL,
    opcnamespace oid NOT NULL,
    opcowner oid NOT NULL,
    opcfamily oid NOT NULL,
    opcintype oid NOT NULL,
    opcdefault boolean NOT NULL,
    opckeytype oid NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_opclass REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_opclass OWNER TO postgres;

--
-- Name: pg_operator; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_operator (
    oid oid NOT NULL,
    oprname name NOT NULL,
    oprnamespace oid NOT NULL,
    oprowner oid NOT NULL,
    oprkind "char" NOT NULL,
    oprcanmerge boolean NOT NULL,
    oprcanhash boolean NOT NULL,
    oprleft oid NOT NULL,
    oprright oid NOT NULL,
    oprresult oid NOT NULL,
    oprcom oid NOT NULL,
    oprnegate oid NOT NULL,
    oprcode regproc NOT NULL,
    oprrest regproc NOT NULL,
    oprjoin regproc NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_operator REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_operator OWNER TO postgres;

--
-- Name: pg_opfamily; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_opfamily (
    oid oid NOT NULL,
    opfmethod oid NOT NULL,
    opfname name NOT NULL,
    opfnamespace oid NOT NULL,
    opfowner oid NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_opfamily REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_opfamily OWNER TO postgres;

--
-- Name: pg_partitioned_table; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_partitioned_table (
    partrelid oid NOT NULL,
    partstrat "char" NOT NULL,
    partnatts smallint NOT NULL,
    partdefid oid NOT NULL,
    partattrs int2vector NOT NULL,
    partclass oidvector NOT NULL,
    partcollation oidvector NOT NULL,
    partexprs pg_node_tree COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_partitioned_table REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_partitioned_table OWNER TO postgres;

SET default_tablespace = pg_global;

--
-- Name: pg_pltemplate; Type: TABLE; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE TABLE pg_catalog.pg_pltemplate (
    tmplname name NOT NULL,
    tmpltrusted boolean NOT NULL,
    tmpldbacreate boolean NOT NULL,
    tmplhandler text NOT NULL COLLATE pg_catalog."C",
    tmplinline text COLLATE pg_catalog."C",
    tmplvalidator text COLLATE pg_catalog."C",
    tmpllibrary text NOT NULL COLLATE pg_catalog."C",
    tmplacl aclitem[]
);

ALTER TABLE ONLY pg_catalog.pg_pltemplate REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_pltemplate OWNER TO postgres;

--
-- Name: pg_policies; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_policies AS
 SELECT n.nspname AS schemaname,
    c.relname AS tablename,
    pol.polname AS policyname,
        CASE
            WHEN pol.polpermissive THEN 'PERMISSIVE'::text
            ELSE 'RESTRICTIVE'::text
        END AS permissive,
        CASE
            WHEN (pol.polroles = '{0}'::oid[]) THEN (string_to_array('public'::text, ''::text))::name[]
            ELSE ARRAY( SELECT pg_authid.rolname
               FROM pg_authid
              WHERE (pg_authid.oid = ANY (pol.polroles))
              ORDER BY pg_authid.rolname)
        END AS roles,
        CASE pol.polcmd
            WHEN 'r'::"char" THEN 'SELECT'::text
            WHEN 'a'::"char" THEN 'INSERT'::text
            WHEN 'w'::"char" THEN 'UPDATE'::text
            WHEN 'd'::"char" THEN 'DELETE'::text
            WHEN '*'::"char" THEN 'ALL'::text
            ELSE NULL::text
        END AS cmd,
    pg_get_expr(pol.polqual, pol.polrelid) AS qual,
    pg_get_expr(pol.polwithcheck, pol.polrelid) AS with_check
   FROM ((pg_policy pol
     JOIN pg_class c ON ((c.oid = pol.polrelid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)));


ALTER TABLE pg_catalog.pg_policies OWNER TO postgres;

SET default_tablespace = '';

--
-- Name: pg_policy; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_policy (
    oid oid NOT NULL,
    polname name NOT NULL,
    polrelid oid NOT NULL,
    polcmd "char" NOT NULL,
    polpermissive boolean NOT NULL,
    polroles oid[] NOT NULL,
    polqual pg_node_tree COLLATE pg_catalog."C",
    polwithcheck pg_node_tree COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_policy REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_policy OWNER TO postgres;

--
-- Name: pg_prepared_statements; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_prepared_statements AS
 SELECT p.name,
    p.statement,
    p.prepare_time,
    p.parameter_types,
    p.from_sql
   FROM pg_prepared_statement() p(name, statement, prepare_time, parameter_types, from_sql);


ALTER TABLE pg_catalog.pg_prepared_statements OWNER TO postgres;

--
-- Name: pg_prepared_xacts; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_prepared_xacts AS
 SELECT p.transaction,
    p.gid,
    p.prepared,
    u.rolname AS owner,
    d.datname AS database
   FROM ((pg_prepared_xact() p(transaction, gid, prepared, ownerid, dbid)
     LEFT JOIN pg_authid u ON ((p.ownerid = u.oid)))
     LEFT JOIN pg_database d ON ((p.dbid = d.oid)));


ALTER TABLE pg_catalog.pg_prepared_xacts OWNER TO postgres;

--
-- Name: pg_proc; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_proc (
    oid oid NOT NULL,
    proname name NOT NULL,
    pronamespace oid NOT NULL,
    proowner oid NOT NULL,
    prolang oid NOT NULL,
    procost real NOT NULL,
    prorows real NOT NULL,
    provariadic oid NOT NULL,
    prosupport regproc NOT NULL,
    prokind "char" NOT NULL,
    prosecdef boolean NOT NULL,
    proleakproof boolean NOT NULL,
    proisstrict boolean NOT NULL,
    proretset boolean NOT NULL,
    provolatile "char" NOT NULL,
    proparallel "char" NOT NULL,
    pronargs smallint NOT NULL,
    pronargdefaults smallint NOT NULL,
    prorettype oid NOT NULL,
    proargtypes oidvector NOT NULL,
    proallargtypes oid[],
    proargmodes "char"[],
    proargnames text[] COLLATE pg_catalog."C",
    proargdefaults pg_node_tree COLLATE pg_catalog."C",
    protrftypes oid[],
    prosrc text NOT NULL COLLATE pg_catalog."C",
    probin text COLLATE pg_catalog."C",
    proconfig text[] COLLATE pg_catalog."C",
    proacl aclitem[]
);

ALTER TABLE ONLY pg_catalog.pg_proc REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_proc OWNER TO postgres;

--
-- Name: pg_publication; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_publication (
    oid oid NOT NULL,
    pubname name NOT NULL,
    pubowner oid NOT NULL,
    puballtables boolean NOT NULL,
    pubinsert boolean NOT NULL,
    pubupdate boolean NOT NULL,
    pubdelete boolean NOT NULL,
    pubtruncate boolean NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_publication REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_publication OWNER TO postgres;

--
-- Name: pg_publication_rel; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_publication_rel (
    oid oid NOT NULL,
    prpubid oid NOT NULL,
    prrelid oid NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_publication_rel REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_publication_rel OWNER TO postgres;

--
-- Name: pg_publication_tables; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_publication_tables AS
 SELECT p.pubname,
    n.nspname AS schemaname,
    c.relname AS tablename
   FROM pg_publication p,
    LATERAL pg_get_publication_tables((p.pubname)::text) gpt(relid),
    (pg_class c
     JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (c.oid = gpt.relid);


ALTER TABLE pg_catalog.pg_publication_tables OWNER TO postgres;

--
-- Name: pg_range; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_range (
    rngtypid oid NOT NULL,
    rngsubtype oid NOT NULL,
    rngcollation oid NOT NULL,
    rngsubopc oid NOT NULL,
    rngcanonical regproc NOT NULL,
    rngsubdiff regproc NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_range REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_range OWNER TO postgres;

SET default_tablespace = pg_global;

--
-- Name: pg_replication_origin; Type: TABLE; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE TABLE pg_catalog.pg_replication_origin (
    roident oid NOT NULL,
    roname text NOT NULL COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_replication_origin REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_replication_origin OWNER TO postgres;

--
-- Name: pg_replication_origin_status; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_replication_origin_status AS
 SELECT pg_show_replication_origin_status.local_id,
    pg_show_replication_origin_status.external_id,
    pg_show_replication_origin_status.remote_lsn,
    pg_show_replication_origin_status.local_lsn
   FROM pg_show_replication_origin_status() pg_show_replication_origin_status(local_id, external_id, remote_lsn, local_lsn);


ALTER TABLE pg_catalog.pg_replication_origin_status OWNER TO postgres;

--
-- Name: pg_replication_slots; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_replication_slots AS
 SELECT l.slot_name,
    l.plugin,
    l.slot_type,
    l.datoid,
    d.datname AS database,
    l.temporary,
    l.active,
    l.active_pid,
    l.xmin,
    l.catalog_xmin,
    l.restart_lsn,
    l.confirmed_flush_lsn
   FROM (pg_get_replication_slots() l(slot_name, plugin, slot_type, datoid, temporary, active, active_pid, xmin, catalog_xmin, restart_lsn, confirmed_flush_lsn)
     LEFT JOIN pg_database d ON ((l.datoid = d.oid)));


ALTER TABLE pg_catalog.pg_replication_slots OWNER TO postgres;

SET default_tablespace = '';

--
-- Name: pg_rewrite; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_rewrite (
    oid oid NOT NULL,
    rulename name NOT NULL,
    ev_class oid NOT NULL,
    ev_type "char" NOT NULL,
    ev_enabled "char" NOT NULL,
    is_instead boolean NOT NULL,
    ev_qual pg_node_tree NOT NULL COLLATE pg_catalog."C",
    ev_action pg_node_tree NOT NULL COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_rewrite REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_rewrite OWNER TO postgres;

--
-- Name: pg_roles; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_roles AS
 SELECT pg_authid.rolname,
    pg_authid.rolsuper,
    pg_authid.rolinherit,
    pg_authid.rolcreaterole,
    pg_authid.rolcreatedb,
    pg_authid.rolcanlogin,
    pg_authid.rolreplication,
    pg_authid.rolconnlimit,
    '********'::text AS rolpassword,
    pg_authid.rolvaliduntil,
    pg_authid.rolbypassrls,
    s.setconfig AS rolconfig,
    pg_authid.oid
   FROM (pg_authid
     LEFT JOIN pg_db_role_setting s ON (((pg_authid.oid = s.setrole) AND (s.setdatabase = (0)::oid))));


ALTER TABLE pg_catalog.pg_roles OWNER TO postgres;

--
-- Name: pg_rules; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_rules AS
 SELECT n.nspname AS schemaname,
    c.relname AS tablename,
    r.rulename,
    pg_get_ruledef(r.oid) AS definition
   FROM ((pg_rewrite r
     JOIN pg_class c ON ((c.oid = r.ev_class)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (r.rulename <> '_RETURN'::name);


ALTER TABLE pg_catalog.pg_rules OWNER TO postgres;

--
-- Name: pg_seclabel; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_seclabel (
    objoid oid NOT NULL,
    classoid oid NOT NULL,
    objsubid integer NOT NULL,
    provider text NOT NULL COLLATE pg_catalog."C",
    label text NOT NULL COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_seclabel REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_seclabel OWNER TO postgres;

--
-- Name: pg_seclabels; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_seclabels AS
 SELECT l.objoid,
    l.classoid,
    l.objsubid,
        CASE
            WHEN (rel.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])) THEN 'table'::text
            WHEN (rel.relkind = 'v'::"char") THEN 'view'::text
            WHEN (rel.relkind = 'm'::"char") THEN 'materialized view'::text
            WHEN (rel.relkind = 'S'::"char") THEN 'sequence'::text
            WHEN (rel.relkind = 'f'::"char") THEN 'foreign table'::text
            ELSE NULL::text
        END AS objtype,
    rel.relnamespace AS objnamespace,
        CASE
            WHEN pg_table_is_visible(rel.oid) THEN quote_ident((rel.relname)::text)
            ELSE ((quote_ident((nsp.nspname)::text) || '.'::text) || quote_ident((rel.relname)::text))
        END AS objname,
    l.provider,
    l.label
   FROM ((pg_seclabel l
     JOIN pg_class rel ON (((l.classoid = rel.tableoid) AND (l.objoid = rel.oid))))
     JOIN pg_namespace nsp ON ((rel.relnamespace = nsp.oid)))
  WHERE (l.objsubid = 0)
UNION ALL
 SELECT l.objoid,
    l.classoid,
    l.objsubid,
    'column'::text AS objtype,
    rel.relnamespace AS objnamespace,
    ((
        CASE
            WHEN pg_table_is_visible(rel.oid) THEN quote_ident((rel.relname)::text)
            ELSE ((quote_ident((nsp.nspname)::text) || '.'::text) || quote_ident((rel.relname)::text))
        END || '.'::text) || (att.attname)::text) AS objname,
    l.provider,
    l.label
   FROM (((pg_seclabel l
     JOIN pg_class rel ON (((l.classoid = rel.tableoid) AND (l.objoid = rel.oid))))
     JOIN pg_attribute att ON (((rel.oid = att.attrelid) AND (l.objsubid = att.attnum))))
     JOIN pg_namespace nsp ON ((rel.relnamespace = nsp.oid)))
  WHERE (l.objsubid <> 0)
UNION ALL
 SELECT l.objoid,
    l.classoid,
    l.objsubid,
        CASE pro.prokind
            WHEN 'a'::"char" THEN 'aggregate'::text
            WHEN 'f'::"char" THEN 'function'::text
            WHEN 'p'::"char" THEN 'procedure'::text
            WHEN 'w'::"char" THEN 'window'::text
            ELSE NULL::text
        END AS objtype,
    pro.pronamespace AS objnamespace,
    (((
        CASE
            WHEN pg_function_is_visible(pro.oid) THEN quote_ident((pro.proname)::text)
            ELSE ((quote_ident((nsp.nspname)::text) || '.'::text) || quote_ident((pro.proname)::text))
        END || '('::text) || pg_get_function_arguments(pro.oid)) || ')'::text) AS objname,
    l.provider,
    l.label
   FROM ((pg_seclabel l
     JOIN pg_proc pro ON (((l.classoid = pro.tableoid) AND (l.objoid = pro.oid))))
     JOIN pg_namespace nsp ON ((pro.pronamespace = nsp.oid)))
  WHERE (l.objsubid = 0)
UNION ALL
 SELECT l.objoid,
    l.classoid,
    l.objsubid,
        CASE
            WHEN (typ.typtype = 'd'::"char") THEN 'domain'::text
            ELSE 'type'::text
        END AS objtype,
    typ.typnamespace AS objnamespace,
        CASE
            WHEN pg_type_is_visible(typ.oid) THEN quote_ident((typ.typname)::text)
            ELSE ((quote_ident((nsp.nspname)::text) || '.'::text) || quote_ident((typ.typname)::text))
        END AS objname,
    l.provider,
    l.label
   FROM ((pg_seclabel l
     JOIN pg_type typ ON (((l.classoid = typ.tableoid) AND (l.objoid = typ.oid))))
     JOIN pg_namespace nsp ON ((typ.typnamespace = nsp.oid)))
  WHERE (l.objsubid = 0)
UNION ALL
 SELECT l.objoid,
    l.classoid,
    l.objsubid,
    'large object'::text AS objtype,
    NULL::oid AS objnamespace,
    (l.objoid)::text AS objname,
    l.provider,
    l.label
   FROM (pg_seclabel l
     JOIN pg_largeobject_metadata lom ON ((l.objoid = lom.oid)))
  WHERE ((l.classoid = ('pg_largeobject'::regclass)::oid) AND (l.objsubid = 0))
UNION ALL
 SELECT l.objoid,
    l.classoid,
    l.objsubid,
    'language'::text AS objtype,
    NULL::oid AS objnamespace,
    quote_ident((lan.lanname)::text) AS objname,
    l.provider,
    l.label
   FROM (pg_seclabel l
     JOIN pg_language lan ON (((l.classoid = lan.tableoid) AND (l.objoid = lan.oid))))
  WHERE (l.objsubid = 0)
UNION ALL
 SELECT l.objoid,
    l.classoid,
    l.objsubid,
    'schema'::text AS objtype,
    nsp.oid AS objnamespace,
    quote_ident((nsp.nspname)::text) AS objname,
    l.provider,
    l.label
   FROM (pg_seclabel l
     JOIN pg_namespace nsp ON (((l.classoid = nsp.tableoid) AND (l.objoid = nsp.oid))))
  WHERE (l.objsubid = 0)
UNION ALL
 SELECT l.objoid,
    l.classoid,
    l.objsubid,
    'event trigger'::text AS objtype,
    NULL::oid AS objnamespace,
    quote_ident((evt.evtname)::text) AS objname,
    l.provider,
    l.label
   FROM (pg_seclabel l
     JOIN pg_event_trigger evt ON (((l.classoid = evt.tableoid) AND (l.objoid = evt.oid))))
  WHERE (l.objsubid = 0)
UNION ALL
 SELECT l.objoid,
    l.classoid,
    l.objsubid,
    'publication'::text AS objtype,
    NULL::oid AS objnamespace,
    quote_ident((p.pubname)::text) AS objname,
    l.provider,
    l.label
   FROM (pg_seclabel l
     JOIN pg_publication p ON (((l.classoid = p.tableoid) AND (l.objoid = p.oid))))
  WHERE (l.objsubid = 0)
UNION ALL
 SELECT l.objoid,
    l.classoid,
    0 AS objsubid,
    'subscription'::text AS objtype,
    NULL::oid AS objnamespace,
    quote_ident((s.subname)::text) AS objname,
    l.provider,
    l.label
   FROM (pg_shseclabel l
     JOIN pg_subscription s ON (((l.classoid = s.tableoid) AND (l.objoid = s.oid))))
UNION ALL
 SELECT l.objoid,
    l.classoid,
    0 AS objsubid,
    'database'::text AS objtype,
    NULL::oid AS objnamespace,
    quote_ident((dat.datname)::text) AS objname,
    l.provider,
    l.label
   FROM (pg_shseclabel l
     JOIN pg_database dat ON (((l.classoid = dat.tableoid) AND (l.objoid = dat.oid))))
UNION ALL
 SELECT l.objoid,
    l.classoid,
    0 AS objsubid,
    'tablespace'::text AS objtype,
    NULL::oid AS objnamespace,
    quote_ident((spc.spcname)::text) AS objname,
    l.provider,
    l.label
   FROM (pg_shseclabel l
     JOIN pg_tablespace spc ON (((l.classoid = spc.tableoid) AND (l.objoid = spc.oid))))
UNION ALL
 SELECT l.objoid,
    l.classoid,
    0 AS objsubid,
    'role'::text AS objtype,
    NULL::oid AS objnamespace,
    quote_ident((rol.rolname)::text) AS objname,
    l.provider,
    l.label
   FROM (pg_shseclabel l
     JOIN pg_authid rol ON (((l.classoid = rol.tableoid) AND (l.objoid = rol.oid))));


ALTER TABLE pg_catalog.pg_seclabels OWNER TO postgres;

--
-- Name: pg_sequence; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_sequence (
    seqrelid oid NOT NULL,
    seqtypid oid NOT NULL,
    seqstart bigint NOT NULL,
    seqincrement bigint NOT NULL,
    seqmax bigint NOT NULL,
    seqmin bigint NOT NULL,
    seqcache bigint NOT NULL,
    seqcycle boolean NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_sequence REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_sequence OWNER TO postgres;

--
-- Name: pg_sequences; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_sequences AS
 SELECT n.nspname AS schemaname,
    c.relname AS sequencename,
    pg_get_userbyid(c.relowner) AS sequenceowner,
    (s.seqtypid)::regtype AS data_type,
    s.seqstart AS start_value,
    s.seqmin AS min_value,
    s.seqmax AS max_value,
    s.seqincrement AS increment_by,
    s.seqcycle AS cycle,
    s.seqcache AS cache_size,
        CASE
            WHEN has_sequence_privilege(c.oid, 'SELECT,USAGE'::text) THEN pg_sequence_last_value((c.oid)::regclass)
            ELSE NULL::bigint
        END AS last_value
   FROM ((pg_sequence s
     JOIN pg_class c ON ((c.oid = s.seqrelid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE ((NOT pg_is_other_temp_schema(n.oid)) AND (c.relkind = 'S'::"char"));


ALTER TABLE pg_catalog.pg_sequences OWNER TO postgres;

--
-- Name: pg_settings; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_settings AS
 SELECT a.name,
    a.setting,
    a.unit,
    a.category,
    a.short_desc,
    a.extra_desc,
    a.context,
    a.vartype,
    a.source,
    a.min_val,
    a.max_val,
    a.enumvals,
    a.boot_val,
    a.reset_val,
    a.sourcefile,
    a.sourceline,
    a.pending_restart
   FROM pg_show_all_settings() a(name, setting, unit, category, short_desc, extra_desc, context, vartype, source, min_val, max_val, enumvals, boot_val, reset_val, sourcefile, sourceline, pending_restart);


ALTER TABLE pg_catalog.pg_settings OWNER TO postgres;

--
-- Name: pg_shadow; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_shadow AS
 SELECT pg_authid.rolname AS usename,
    pg_authid.oid AS usesysid,
    pg_authid.rolcreatedb AS usecreatedb,
    pg_authid.rolsuper AS usesuper,
    pg_authid.rolreplication AS userepl,
    pg_authid.rolbypassrls AS usebypassrls,
    pg_authid.rolpassword AS passwd,
    pg_authid.rolvaliduntil AS valuntil,
    s.setconfig AS useconfig
   FROM (pg_authid
     LEFT JOIN pg_db_role_setting s ON (((pg_authid.oid = s.setrole) AND (s.setdatabase = (0)::oid))))
  WHERE pg_authid.rolcanlogin;


ALTER TABLE pg_catalog.pg_shadow OWNER TO postgres;

SET default_tablespace = pg_global;

--
-- Name: pg_shdepend; Type: TABLE; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE TABLE pg_catalog.pg_shdepend (
    dbid oid NOT NULL,
    classid oid NOT NULL,
    objid oid NOT NULL,
    objsubid integer NOT NULL,
    refclassid oid NOT NULL,
    refobjid oid NOT NULL,
    deptype "char" NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_shdepend REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_shdepend OWNER TO postgres;

--
-- Name: pg_shdescription; Type: TABLE; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE TABLE pg_catalog.pg_shdescription (
    objoid oid NOT NULL,
    classoid oid NOT NULL,
    description text NOT NULL COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_shdescription REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_shdescription OWNER TO postgres;

--
-- Name: pg_shseclabel; Type: TABLE; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE TABLE pg_catalog.pg_shseclabel (
    objoid oid NOT NULL,
    classoid oid NOT NULL,
    provider text NOT NULL COLLATE pg_catalog."C",
    label text NOT NULL COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_shseclabel REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_shseclabel OWNER TO postgres;

--
-- Name: pg_stat_activity; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_activity AS
 SELECT s.datid,
    d.datname,
    s.pid,
    s.usesysid,
    u.rolname AS usename,
    s.application_name,
    s.client_addr,
    s.client_hostname,
    s.client_port,
    s.backend_start,
    s.xact_start,
    s.query_start,
    s.state_change,
    s.wait_event_type,
    s.wait_event,
    s.state,
    s.backend_xid,
    s.backend_xmin,
    s.query,
    s.backend_type
   FROM ((pg_stat_get_activity(NULL::integer) s(datid, pid, usesysid, application_name, state, query, wait_event_type, wait_event, xact_start, query_start, backend_start, state_change, client_addr, client_hostname, client_port, backend_xid, backend_xmin, backend_type, ssl, sslversion, sslcipher, sslbits, sslcompression, ssl_client_dn, ssl_client_serial, ssl_issuer_dn, gss_auth, gss_princ, gss_enc)
     LEFT JOIN pg_database d ON ((s.datid = d.oid)))
     LEFT JOIN pg_authid u ON ((s.usesysid = u.oid)));


ALTER TABLE pg_catalog.pg_stat_activity OWNER TO postgres;

--
-- Name: pg_stat_all_indexes; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_all_indexes AS
 SELECT c.oid AS relid,
    i.oid AS indexrelid,
    n.nspname AS schemaname,
    c.relname,
    i.relname AS indexrelname,
    pg_stat_get_numscans(i.oid) AS idx_scan,
    pg_stat_get_tuples_returned(i.oid) AS idx_tup_read,
    pg_stat_get_tuples_fetched(i.oid) AS idx_tup_fetch
   FROM (((pg_class c
     JOIN pg_index x ON ((c.oid = x.indrelid)))
     JOIN pg_class i ON ((i.oid = x.indexrelid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 't'::"char", 'm'::"char"]));


ALTER TABLE pg_catalog.pg_stat_all_indexes OWNER TO postgres;

--
-- Name: pg_stat_all_tables; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_all_tables AS
 SELECT c.oid AS relid,
    n.nspname AS schemaname,
    c.relname,
    pg_stat_get_numscans(c.oid) AS seq_scan,
    pg_stat_get_tuples_returned(c.oid) AS seq_tup_read,
    (sum(pg_stat_get_numscans(i.indexrelid)))::bigint AS idx_scan,
    ((sum(pg_stat_get_tuples_fetched(i.indexrelid)))::bigint + pg_stat_get_tuples_fetched(c.oid)) AS idx_tup_fetch,
    pg_stat_get_tuples_inserted(c.oid) AS n_tup_ins,
    pg_stat_get_tuples_updated(c.oid) AS n_tup_upd,
    pg_stat_get_tuples_deleted(c.oid) AS n_tup_del,
    pg_stat_get_tuples_hot_updated(c.oid) AS n_tup_hot_upd,
    pg_stat_get_live_tuples(c.oid) AS n_live_tup,
    pg_stat_get_dead_tuples(c.oid) AS n_dead_tup,
    pg_stat_get_mod_since_analyze(c.oid) AS n_mod_since_analyze,
    pg_stat_get_last_vacuum_time(c.oid) AS last_vacuum,
    pg_stat_get_last_autovacuum_time(c.oid) AS last_autovacuum,
    pg_stat_get_last_analyze_time(c.oid) AS last_analyze,
    pg_stat_get_last_autoanalyze_time(c.oid) AS last_autoanalyze,
    pg_stat_get_vacuum_count(c.oid) AS vacuum_count,
    pg_stat_get_autovacuum_count(c.oid) AS autovacuum_count,
    pg_stat_get_analyze_count(c.oid) AS analyze_count,
    pg_stat_get_autoanalyze_count(c.oid) AS autoanalyze_count
   FROM ((pg_class c
     LEFT JOIN pg_index i ON ((c.oid = i.indrelid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 't'::"char", 'm'::"char"]))
  GROUP BY c.oid, n.nspname, c.relname;


ALTER TABLE pg_catalog.pg_stat_all_tables OWNER TO postgres;

--
-- Name: pg_stat_archiver; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_archiver AS
 SELECT s.archived_count,
    s.last_archived_wal,
    s.last_archived_time,
    s.failed_count,
    s.last_failed_wal,
    s.last_failed_time,
    s.stats_reset
   FROM pg_stat_get_archiver() s(archived_count, last_archived_wal, last_archived_time, failed_count, last_failed_wal, last_failed_time, stats_reset);


ALTER TABLE pg_catalog.pg_stat_archiver OWNER TO postgres;

--
-- Name: pg_stat_bgwriter; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_bgwriter AS
 SELECT pg_stat_get_bgwriter_timed_checkpoints() AS checkpoints_timed,
    pg_stat_get_bgwriter_requested_checkpoints() AS checkpoints_req,
    pg_stat_get_checkpoint_write_time() AS checkpoint_write_time,
    pg_stat_get_checkpoint_sync_time() AS checkpoint_sync_time,
    pg_stat_get_bgwriter_buf_written_checkpoints() AS buffers_checkpoint,
    pg_stat_get_bgwriter_buf_written_clean() AS buffers_clean,
    pg_stat_get_bgwriter_maxwritten_clean() AS maxwritten_clean,
    pg_stat_get_buf_written_backend() AS buffers_backend,
    pg_stat_get_buf_fsync_backend() AS buffers_backend_fsync,
    pg_stat_get_buf_alloc() AS buffers_alloc,
    pg_stat_get_bgwriter_stat_reset_time() AS stats_reset;


ALTER TABLE pg_catalog.pg_stat_bgwriter OWNER TO postgres;

--
-- Name: pg_stat_database; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_database AS
 SELECT d.oid AS datid,
    d.datname,
        CASE
            WHEN (d.oid = (0)::oid) THEN 0
            ELSE pg_stat_get_db_numbackends(d.oid)
        END AS numbackends,
    pg_stat_get_db_xact_commit(d.oid) AS xact_commit,
    pg_stat_get_db_xact_rollback(d.oid) AS xact_rollback,
    (pg_stat_get_db_blocks_fetched(d.oid) - pg_stat_get_db_blocks_hit(d.oid)) AS blks_read,
    pg_stat_get_db_blocks_hit(d.oid) AS blks_hit,
    pg_stat_get_db_tuples_returned(d.oid) AS tup_returned,
    pg_stat_get_db_tuples_fetched(d.oid) AS tup_fetched,
    pg_stat_get_db_tuples_inserted(d.oid) AS tup_inserted,
    pg_stat_get_db_tuples_updated(d.oid) AS tup_updated,
    pg_stat_get_db_tuples_deleted(d.oid) AS tup_deleted,
    pg_stat_get_db_conflict_all(d.oid) AS conflicts,
    pg_stat_get_db_temp_files(d.oid) AS temp_files,
    pg_stat_get_db_temp_bytes(d.oid) AS temp_bytes,
    pg_stat_get_db_deadlocks(d.oid) AS deadlocks,
    pg_stat_get_db_checksum_failures(d.oid) AS checksum_failures,
    pg_stat_get_db_checksum_last_failure(d.oid) AS checksum_last_failure,
    pg_stat_get_db_blk_read_time(d.oid) AS blk_read_time,
    pg_stat_get_db_blk_write_time(d.oid) AS blk_write_time,
    pg_stat_get_db_stat_reset_time(d.oid) AS stats_reset
   FROM ( SELECT 0 AS oid,
            NULL::name AS datname
        UNION ALL
         SELECT pg_database.oid,
            pg_database.datname
           FROM pg_database) d;


ALTER TABLE pg_catalog.pg_stat_database OWNER TO postgres;

--
-- Name: pg_stat_database_conflicts; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_database_conflicts AS
 SELECT d.oid AS datid,
    d.datname,
    pg_stat_get_db_conflict_tablespace(d.oid) AS confl_tablespace,
    pg_stat_get_db_conflict_lock(d.oid) AS confl_lock,
    pg_stat_get_db_conflict_snapshot(d.oid) AS confl_snapshot,
    pg_stat_get_db_conflict_bufferpin(d.oid) AS confl_bufferpin,
    pg_stat_get_db_conflict_startup_deadlock(d.oid) AS confl_deadlock
   FROM pg_database d;


ALTER TABLE pg_catalog.pg_stat_database_conflicts OWNER TO postgres;

--
-- Name: pg_stat_gssapi; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_gssapi AS
 SELECT s.pid,
    s.gss_auth AS gss_authenticated,
    s.gss_princ AS principal,
    s.gss_enc AS encrypted
   FROM pg_stat_get_activity(NULL::integer) s(datid, pid, usesysid, application_name, state, query, wait_event_type, wait_event, xact_start, query_start, backend_start, state_change, client_addr, client_hostname, client_port, backend_xid, backend_xmin, backend_type, ssl, sslversion, sslcipher, sslbits, sslcompression, ssl_client_dn, ssl_client_serial, ssl_issuer_dn, gss_auth, gss_princ, gss_enc);


ALTER TABLE pg_catalog.pg_stat_gssapi OWNER TO postgres;

--
-- Name: pg_stat_progress_cluster; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_progress_cluster AS
 SELECT s.pid,
    s.datid,
    d.datname,
    s.relid,
        CASE s.param1
            WHEN 1 THEN 'CLUSTER'::text
            WHEN 2 THEN 'VACUUM FULL'::text
            ELSE NULL::text
        END AS command,
        CASE s.param2
            WHEN 0 THEN 'initializing'::text
            WHEN 1 THEN 'seq scanning heap'::text
            WHEN 2 THEN 'index scanning heap'::text
            WHEN 3 THEN 'sorting tuples'::text
            WHEN 4 THEN 'writing new heap'::text
            WHEN 5 THEN 'swapping relation files'::text
            WHEN 6 THEN 'rebuilding index'::text
            WHEN 7 THEN 'performing final cleanup'::text
            ELSE NULL::text
        END AS phase,
    (s.param3)::oid AS cluster_index_relid,
    s.param4 AS heap_tuples_scanned,
    s.param5 AS heap_tuples_written,
    s.param6 AS heap_blks_total,
    s.param7 AS heap_blks_scanned,
    s.param8 AS index_rebuild_count
   FROM (pg_stat_get_progress_info('CLUSTER'::text) s(pid, datid, relid, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11, param12, param13, param14, param15, param16, param17, param18, param19, param20)
     LEFT JOIN pg_database d ON ((s.datid = d.oid)));


ALTER TABLE pg_catalog.pg_stat_progress_cluster OWNER TO postgres;

--
-- Name: pg_stat_progress_create_index; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_progress_create_index AS
 SELECT s.pid,
    s.datid,
    d.datname,
    s.relid,
    (s.param7)::oid AS index_relid,
        CASE s.param1
            WHEN 1 THEN 'CREATE INDEX'::text
            WHEN 2 THEN 'CREATE INDEX CONCURRENTLY'::text
            WHEN 3 THEN 'REINDEX'::text
            WHEN 4 THEN 'REINDEX CONCURRENTLY'::text
            ELSE NULL::text
        END AS command,
        CASE s.param10
            WHEN 0 THEN 'initializing'::text
            WHEN 1 THEN 'waiting for writers before build'::text
            WHEN 2 THEN ('building index'::text || COALESCE((': '::text || pg_indexam_progress_phasename((s.param9)::oid, s.param11)), ''::text))
            WHEN 3 THEN 'waiting for writers before validation'::text
            WHEN 4 THEN 'index validation: scanning index'::text
            WHEN 5 THEN 'index validation: sorting tuples'::text
            WHEN 6 THEN 'index validation: scanning table'::text
            WHEN 7 THEN 'waiting for old snapshots'::text
            WHEN 8 THEN 'waiting for readers before marking dead'::text
            WHEN 9 THEN 'waiting for readers before dropping'::text
            ELSE NULL::text
        END AS phase,
    s.param4 AS lockers_total,
    s.param5 AS lockers_done,
    s.param6 AS current_locker_pid,
    s.param16 AS blocks_total,
    s.param17 AS blocks_done,
    s.param12 AS tuples_total,
    s.param13 AS tuples_done,
    s.param14 AS partitions_total,
    s.param15 AS partitions_done
   FROM (pg_stat_get_progress_info('CREATE INDEX'::text) s(pid, datid, relid, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11, param12, param13, param14, param15, param16, param17, param18, param19, param20)
     LEFT JOIN pg_database d ON ((s.datid = d.oid)));


ALTER TABLE pg_catalog.pg_stat_progress_create_index OWNER TO postgres;

--
-- Name: pg_stat_progress_vacuum; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_progress_vacuum AS
 SELECT s.pid,
    s.datid,
    d.datname,
    s.relid,
        CASE s.param1
            WHEN 0 THEN 'initializing'::text
            WHEN 1 THEN 'scanning heap'::text
            WHEN 2 THEN 'vacuuming indexes'::text
            WHEN 3 THEN 'vacuuming heap'::text
            WHEN 4 THEN 'cleaning up indexes'::text
            WHEN 5 THEN 'truncating heap'::text
            WHEN 6 THEN 'performing final cleanup'::text
            ELSE NULL::text
        END AS phase,
    s.param2 AS heap_blks_total,
    s.param3 AS heap_blks_scanned,
    s.param4 AS heap_blks_vacuumed,
    s.param5 AS index_vacuum_count,
    s.param6 AS max_dead_tuples,
    s.param7 AS num_dead_tuples
   FROM (pg_stat_get_progress_info('VACUUM'::text) s(pid, datid, relid, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11, param12, param13, param14, param15, param16, param17, param18, param19, param20)
     LEFT JOIN pg_database d ON ((s.datid = d.oid)));


ALTER TABLE pg_catalog.pg_stat_progress_vacuum OWNER TO postgres;

--
-- Name: pg_stat_replication; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_replication AS
 SELECT s.pid,
    s.usesysid,
    u.rolname AS usename,
    s.application_name,
    s.client_addr,
    s.client_hostname,
    s.client_port,
    s.backend_start,
    s.backend_xmin,
    w.state,
    w.sent_lsn,
    w.write_lsn,
    w.flush_lsn,
    w.replay_lsn,
    w.write_lag,
    w.flush_lag,
    w.replay_lag,
    w.sync_priority,
    w.sync_state,
    w.reply_time
   FROM ((pg_stat_get_activity(NULL::integer) s(datid, pid, usesysid, application_name, state, query, wait_event_type, wait_event, xact_start, query_start, backend_start, state_change, client_addr, client_hostname, client_port, backend_xid, backend_xmin, backend_type, ssl, sslversion, sslcipher, sslbits, sslcompression, ssl_client_dn, ssl_client_serial, ssl_issuer_dn, gss_auth, gss_princ, gss_enc)
     JOIN pg_stat_get_wal_senders() w(pid, state, sent_lsn, write_lsn, flush_lsn, replay_lsn, write_lag, flush_lag, replay_lag, sync_priority, sync_state, reply_time) ON ((s.pid = w.pid)))
     LEFT JOIN pg_authid u ON ((s.usesysid = u.oid)));


ALTER TABLE pg_catalog.pg_stat_replication OWNER TO postgres;

--
-- Name: pg_stat_ssl; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_ssl AS
 SELECT s.pid,
    s.ssl,
    s.sslversion AS version,
    s.sslcipher AS cipher,
    s.sslbits AS bits,
    s.sslcompression AS compression,
    s.ssl_client_dn AS client_dn,
    s.ssl_client_serial AS client_serial,
    s.ssl_issuer_dn AS issuer_dn
   FROM pg_stat_get_activity(NULL::integer) s(datid, pid, usesysid, application_name, state, query, wait_event_type, wait_event, xact_start, query_start, backend_start, state_change, client_addr, client_hostname, client_port, backend_xid, backend_xmin, backend_type, ssl, sslversion, sslcipher, sslbits, sslcompression, ssl_client_dn, ssl_client_serial, ssl_issuer_dn, gss_auth, gss_princ, gss_enc);


ALTER TABLE pg_catalog.pg_stat_ssl OWNER TO postgres;

--
-- Name: pg_stat_subscription; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_subscription AS
 SELECT su.oid AS subid,
    su.subname,
    st.pid,
    st.relid,
    st.received_lsn,
    st.last_msg_send_time,
    st.last_msg_receipt_time,
    st.latest_end_lsn,
    st.latest_end_time
   FROM (pg_subscription su
     LEFT JOIN pg_stat_get_subscription(NULL::oid) st(subid, relid, pid, received_lsn, last_msg_send_time, last_msg_receipt_time, latest_end_lsn, latest_end_time) ON ((st.subid = su.oid)));


ALTER TABLE pg_catalog.pg_stat_subscription OWNER TO postgres;

--
-- Name: pg_stat_sys_indexes; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_sys_indexes AS
 SELECT pg_stat_all_indexes.relid,
    pg_stat_all_indexes.indexrelid,
    pg_stat_all_indexes.schemaname,
    pg_stat_all_indexes.relname,
    pg_stat_all_indexes.indexrelname,
    pg_stat_all_indexes.idx_scan,
    pg_stat_all_indexes.idx_tup_read,
    pg_stat_all_indexes.idx_tup_fetch
   FROM pg_stat_all_indexes
  WHERE ((pg_stat_all_indexes.schemaname = ANY (ARRAY['pg_catalog'::name, 'information_schema'::name])) OR (pg_stat_all_indexes.schemaname ~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_stat_sys_indexes OWNER TO postgres;

--
-- Name: pg_stat_sys_tables; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_sys_tables AS
 SELECT pg_stat_all_tables.relid,
    pg_stat_all_tables.schemaname,
    pg_stat_all_tables.relname,
    pg_stat_all_tables.seq_scan,
    pg_stat_all_tables.seq_tup_read,
    pg_stat_all_tables.idx_scan,
    pg_stat_all_tables.idx_tup_fetch,
    pg_stat_all_tables.n_tup_ins,
    pg_stat_all_tables.n_tup_upd,
    pg_stat_all_tables.n_tup_del,
    pg_stat_all_tables.n_tup_hot_upd,
    pg_stat_all_tables.n_live_tup,
    pg_stat_all_tables.n_dead_tup,
    pg_stat_all_tables.n_mod_since_analyze,
    pg_stat_all_tables.last_vacuum,
    pg_stat_all_tables.last_autovacuum,
    pg_stat_all_tables.last_analyze,
    pg_stat_all_tables.last_autoanalyze,
    pg_stat_all_tables.vacuum_count,
    pg_stat_all_tables.autovacuum_count,
    pg_stat_all_tables.analyze_count,
    pg_stat_all_tables.autoanalyze_count
   FROM pg_stat_all_tables
  WHERE ((pg_stat_all_tables.schemaname = ANY (ARRAY['pg_catalog'::name, 'information_schema'::name])) OR (pg_stat_all_tables.schemaname ~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_stat_sys_tables OWNER TO postgres;

--
-- Name: pg_stat_user_functions; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_user_functions AS
 SELECT p.oid AS funcid,
    n.nspname AS schemaname,
    p.proname AS funcname,
    pg_stat_get_function_calls(p.oid) AS calls,
    pg_stat_get_function_total_time(p.oid) AS total_time,
    pg_stat_get_function_self_time(p.oid) AS self_time
   FROM (pg_proc p
     LEFT JOIN pg_namespace n ON ((n.oid = p.pronamespace)))
  WHERE ((p.prolang <> (12)::oid) AND (pg_stat_get_function_calls(p.oid) IS NOT NULL));


ALTER TABLE pg_catalog.pg_stat_user_functions OWNER TO postgres;

--
-- Name: pg_stat_user_indexes; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_user_indexes AS
 SELECT pg_stat_all_indexes.relid,
    pg_stat_all_indexes.indexrelid,
    pg_stat_all_indexes.schemaname,
    pg_stat_all_indexes.relname,
    pg_stat_all_indexes.indexrelname,
    pg_stat_all_indexes.idx_scan,
    pg_stat_all_indexes.idx_tup_read,
    pg_stat_all_indexes.idx_tup_fetch
   FROM pg_stat_all_indexes
  WHERE ((pg_stat_all_indexes.schemaname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])) AND (pg_stat_all_indexes.schemaname !~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_stat_user_indexes OWNER TO postgres;

--
-- Name: pg_stat_user_tables; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_user_tables AS
 SELECT pg_stat_all_tables.relid,
    pg_stat_all_tables.schemaname,
    pg_stat_all_tables.relname,
    pg_stat_all_tables.seq_scan,
    pg_stat_all_tables.seq_tup_read,
    pg_stat_all_tables.idx_scan,
    pg_stat_all_tables.idx_tup_fetch,
    pg_stat_all_tables.n_tup_ins,
    pg_stat_all_tables.n_tup_upd,
    pg_stat_all_tables.n_tup_del,
    pg_stat_all_tables.n_tup_hot_upd,
    pg_stat_all_tables.n_live_tup,
    pg_stat_all_tables.n_dead_tup,
    pg_stat_all_tables.n_mod_since_analyze,
    pg_stat_all_tables.last_vacuum,
    pg_stat_all_tables.last_autovacuum,
    pg_stat_all_tables.last_analyze,
    pg_stat_all_tables.last_autoanalyze,
    pg_stat_all_tables.vacuum_count,
    pg_stat_all_tables.autovacuum_count,
    pg_stat_all_tables.analyze_count,
    pg_stat_all_tables.autoanalyze_count
   FROM pg_stat_all_tables
  WHERE ((pg_stat_all_tables.schemaname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])) AND (pg_stat_all_tables.schemaname !~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_stat_user_tables OWNER TO postgres;

--
-- Name: pg_stat_wal_receiver; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_wal_receiver AS
 SELECT s.pid,
    s.status,
    s.receive_start_lsn,
    s.receive_start_tli,
    s.received_lsn,
    s.received_tli,
    s.last_msg_send_time,
    s.last_msg_receipt_time,
    s.latest_end_lsn,
    s.latest_end_time,
    s.slot_name,
    s.sender_host,
    s.sender_port,
    s.conninfo
   FROM pg_stat_get_wal_receiver() s(pid, status, receive_start_lsn, receive_start_tli, received_lsn, received_tli, last_msg_send_time, last_msg_receipt_time, latest_end_lsn, latest_end_time, slot_name, sender_host, sender_port, conninfo)
  WHERE (s.pid IS NOT NULL);


ALTER TABLE pg_catalog.pg_stat_wal_receiver OWNER TO postgres;

--
-- Name: pg_stat_xact_all_tables; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_xact_all_tables AS
 SELECT c.oid AS relid,
    n.nspname AS schemaname,
    c.relname,
    pg_stat_get_xact_numscans(c.oid) AS seq_scan,
    pg_stat_get_xact_tuples_returned(c.oid) AS seq_tup_read,
    (sum(pg_stat_get_xact_numscans(i.indexrelid)))::bigint AS idx_scan,
    ((sum(pg_stat_get_xact_tuples_fetched(i.indexrelid)))::bigint + pg_stat_get_xact_tuples_fetched(c.oid)) AS idx_tup_fetch,
    pg_stat_get_xact_tuples_inserted(c.oid) AS n_tup_ins,
    pg_stat_get_xact_tuples_updated(c.oid) AS n_tup_upd,
    pg_stat_get_xact_tuples_deleted(c.oid) AS n_tup_del,
    pg_stat_get_xact_tuples_hot_updated(c.oid) AS n_tup_hot_upd
   FROM ((pg_class c
     LEFT JOIN pg_index i ON ((c.oid = i.indrelid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 't'::"char", 'm'::"char"]))
  GROUP BY c.oid, n.nspname, c.relname;


ALTER TABLE pg_catalog.pg_stat_xact_all_tables OWNER TO postgres;

--
-- Name: pg_stat_xact_sys_tables; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_xact_sys_tables AS
 SELECT pg_stat_xact_all_tables.relid,
    pg_stat_xact_all_tables.schemaname,
    pg_stat_xact_all_tables.relname,
    pg_stat_xact_all_tables.seq_scan,
    pg_stat_xact_all_tables.seq_tup_read,
    pg_stat_xact_all_tables.idx_scan,
    pg_stat_xact_all_tables.idx_tup_fetch,
    pg_stat_xact_all_tables.n_tup_ins,
    pg_stat_xact_all_tables.n_tup_upd,
    pg_stat_xact_all_tables.n_tup_del,
    pg_stat_xact_all_tables.n_tup_hot_upd
   FROM pg_stat_xact_all_tables
  WHERE ((pg_stat_xact_all_tables.schemaname = ANY (ARRAY['pg_catalog'::name, 'information_schema'::name])) OR (pg_stat_xact_all_tables.schemaname ~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_stat_xact_sys_tables OWNER TO postgres;

--
-- Name: pg_stat_xact_user_functions; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_xact_user_functions AS
 SELECT p.oid AS funcid,
    n.nspname AS schemaname,
    p.proname AS funcname,
    pg_stat_get_xact_function_calls(p.oid) AS calls,
    pg_stat_get_xact_function_total_time(p.oid) AS total_time,
    pg_stat_get_xact_function_self_time(p.oid) AS self_time
   FROM (pg_proc p
     LEFT JOIN pg_namespace n ON ((n.oid = p.pronamespace)))
  WHERE ((p.prolang <> (12)::oid) AND (pg_stat_get_xact_function_calls(p.oid) IS NOT NULL));


ALTER TABLE pg_catalog.pg_stat_xact_user_functions OWNER TO postgres;

--
-- Name: pg_stat_xact_user_tables; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stat_xact_user_tables AS
 SELECT pg_stat_xact_all_tables.relid,
    pg_stat_xact_all_tables.schemaname,
    pg_stat_xact_all_tables.relname,
    pg_stat_xact_all_tables.seq_scan,
    pg_stat_xact_all_tables.seq_tup_read,
    pg_stat_xact_all_tables.idx_scan,
    pg_stat_xact_all_tables.idx_tup_fetch,
    pg_stat_xact_all_tables.n_tup_ins,
    pg_stat_xact_all_tables.n_tup_upd,
    pg_stat_xact_all_tables.n_tup_del,
    pg_stat_xact_all_tables.n_tup_hot_upd
   FROM pg_stat_xact_all_tables
  WHERE ((pg_stat_xact_all_tables.schemaname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])) AND (pg_stat_xact_all_tables.schemaname !~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_stat_xact_user_tables OWNER TO postgres;

--
-- Name: pg_statio_all_indexes; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_statio_all_indexes AS
 SELECT c.oid AS relid,
    i.oid AS indexrelid,
    n.nspname AS schemaname,
    c.relname,
    i.relname AS indexrelname,
    (pg_stat_get_blocks_fetched(i.oid) - pg_stat_get_blocks_hit(i.oid)) AS idx_blks_read,
    pg_stat_get_blocks_hit(i.oid) AS idx_blks_hit
   FROM (((pg_class c
     JOIN pg_index x ON ((c.oid = x.indrelid)))
     JOIN pg_class i ON ((i.oid = x.indexrelid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 't'::"char", 'm'::"char"]));


ALTER TABLE pg_catalog.pg_statio_all_indexes OWNER TO postgres;

--
-- Name: pg_statio_all_sequences; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_statio_all_sequences AS
 SELECT c.oid AS relid,
    n.nspname AS schemaname,
    c.relname,
    (pg_stat_get_blocks_fetched(c.oid) - pg_stat_get_blocks_hit(c.oid)) AS blks_read,
    pg_stat_get_blocks_hit(c.oid) AS blks_hit
   FROM (pg_class c
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (c.relkind = 'S'::"char");


ALTER TABLE pg_catalog.pg_statio_all_sequences OWNER TO postgres;

--
-- Name: pg_statio_all_tables; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_statio_all_tables AS
 SELECT c.oid AS relid,
    n.nspname AS schemaname,
    c.relname,
    (pg_stat_get_blocks_fetched(c.oid) - pg_stat_get_blocks_hit(c.oid)) AS heap_blks_read,
    pg_stat_get_blocks_hit(c.oid) AS heap_blks_hit,
    (sum((pg_stat_get_blocks_fetched(i.indexrelid) - pg_stat_get_blocks_hit(i.indexrelid))))::bigint AS idx_blks_read,
    (sum(pg_stat_get_blocks_hit(i.indexrelid)))::bigint AS idx_blks_hit,
    (pg_stat_get_blocks_fetched(t.oid) - pg_stat_get_blocks_hit(t.oid)) AS toast_blks_read,
    pg_stat_get_blocks_hit(t.oid) AS toast_blks_hit,
    (sum((pg_stat_get_blocks_fetched(x.indexrelid) - pg_stat_get_blocks_hit(x.indexrelid))))::bigint AS tidx_blks_read,
    (sum(pg_stat_get_blocks_hit(x.indexrelid)))::bigint AS tidx_blks_hit
   FROM ((((pg_class c
     LEFT JOIN pg_index i ON ((c.oid = i.indrelid)))
     LEFT JOIN pg_class t ON ((c.reltoastrelid = t.oid)))
     LEFT JOIN pg_index x ON ((t.oid = x.indrelid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 't'::"char", 'm'::"char"]))
  GROUP BY c.oid, n.nspname, c.relname, t.oid, x.indrelid;


ALTER TABLE pg_catalog.pg_statio_all_tables OWNER TO postgres;

--
-- Name: pg_statio_sys_indexes; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_statio_sys_indexes AS
 SELECT pg_statio_all_indexes.relid,
    pg_statio_all_indexes.indexrelid,
    pg_statio_all_indexes.schemaname,
    pg_statio_all_indexes.relname,
    pg_statio_all_indexes.indexrelname,
    pg_statio_all_indexes.idx_blks_read,
    pg_statio_all_indexes.idx_blks_hit
   FROM pg_statio_all_indexes
  WHERE ((pg_statio_all_indexes.schemaname = ANY (ARRAY['pg_catalog'::name, 'information_schema'::name])) OR (pg_statio_all_indexes.schemaname ~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_statio_sys_indexes OWNER TO postgres;

--
-- Name: pg_statio_sys_sequences; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_statio_sys_sequences AS
 SELECT pg_statio_all_sequences.relid,
    pg_statio_all_sequences.schemaname,
    pg_statio_all_sequences.relname,
    pg_statio_all_sequences.blks_read,
    pg_statio_all_sequences.blks_hit
   FROM pg_statio_all_sequences
  WHERE ((pg_statio_all_sequences.schemaname = ANY (ARRAY['pg_catalog'::name, 'information_schema'::name])) OR (pg_statio_all_sequences.schemaname ~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_statio_sys_sequences OWNER TO postgres;

--
-- Name: pg_statio_sys_tables; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_statio_sys_tables AS
 SELECT pg_statio_all_tables.relid,
    pg_statio_all_tables.schemaname,
    pg_statio_all_tables.relname,
    pg_statio_all_tables.heap_blks_read,
    pg_statio_all_tables.heap_blks_hit,
    pg_statio_all_tables.idx_blks_read,
    pg_statio_all_tables.idx_blks_hit,
    pg_statio_all_tables.toast_blks_read,
    pg_statio_all_tables.toast_blks_hit,
    pg_statio_all_tables.tidx_blks_read,
    pg_statio_all_tables.tidx_blks_hit
   FROM pg_statio_all_tables
  WHERE ((pg_statio_all_tables.schemaname = ANY (ARRAY['pg_catalog'::name, 'information_schema'::name])) OR (pg_statio_all_tables.schemaname ~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_statio_sys_tables OWNER TO postgres;

--
-- Name: pg_statio_user_indexes; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_statio_user_indexes AS
 SELECT pg_statio_all_indexes.relid,
    pg_statio_all_indexes.indexrelid,
    pg_statio_all_indexes.schemaname,
    pg_statio_all_indexes.relname,
    pg_statio_all_indexes.indexrelname,
    pg_statio_all_indexes.idx_blks_read,
    pg_statio_all_indexes.idx_blks_hit
   FROM pg_statio_all_indexes
  WHERE ((pg_statio_all_indexes.schemaname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])) AND (pg_statio_all_indexes.schemaname !~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_statio_user_indexes OWNER TO postgres;

--
-- Name: pg_statio_user_sequences; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_statio_user_sequences AS
 SELECT pg_statio_all_sequences.relid,
    pg_statio_all_sequences.schemaname,
    pg_statio_all_sequences.relname,
    pg_statio_all_sequences.blks_read,
    pg_statio_all_sequences.blks_hit
   FROM pg_statio_all_sequences
  WHERE ((pg_statio_all_sequences.schemaname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])) AND (pg_statio_all_sequences.schemaname !~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_statio_user_sequences OWNER TO postgres;

--
-- Name: pg_statio_user_tables; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_statio_user_tables AS
 SELECT pg_statio_all_tables.relid,
    pg_statio_all_tables.schemaname,
    pg_statio_all_tables.relname,
    pg_statio_all_tables.heap_blks_read,
    pg_statio_all_tables.heap_blks_hit,
    pg_statio_all_tables.idx_blks_read,
    pg_statio_all_tables.idx_blks_hit,
    pg_statio_all_tables.toast_blks_read,
    pg_statio_all_tables.toast_blks_hit,
    pg_statio_all_tables.tidx_blks_read,
    pg_statio_all_tables.tidx_blks_hit
   FROM pg_statio_all_tables
  WHERE ((pg_statio_all_tables.schemaname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])) AND (pg_statio_all_tables.schemaname !~ '^pg_toast'::text));


ALTER TABLE pg_catalog.pg_statio_user_tables OWNER TO postgres;

SET default_tablespace = '';

--
-- Name: pg_statistic; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_statistic (
    starelid oid NOT NULL,
    staattnum smallint NOT NULL,
    stainherit boolean NOT NULL,
    stanullfrac real NOT NULL,
    stawidth integer NOT NULL,
    stadistinct real NOT NULL,
    stakind1 smallint NOT NULL,
    stakind2 smallint NOT NULL,
    stakind3 smallint NOT NULL,
    stakind4 smallint NOT NULL,
    stakind5 smallint NOT NULL,
    staop1 oid NOT NULL,
    staop2 oid NOT NULL,
    staop3 oid NOT NULL,
    staop4 oid NOT NULL,
    staop5 oid NOT NULL,
    stacoll1 oid NOT NULL,
    stacoll2 oid NOT NULL,
    stacoll3 oid NOT NULL,
    stacoll4 oid NOT NULL,
    stacoll5 oid NOT NULL,
    stanumbers1 real[],
    stanumbers2 real[],
    stanumbers3 real[],
    stanumbers4 real[],
    stanumbers5 real[],
    stavalues1 anyarray,
    stavalues2 anyarray,
    stavalues3 anyarray,
    stavalues4 anyarray,
    stavalues5 anyarray
);

ALTER TABLE ONLY pg_catalog.pg_statistic REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_statistic OWNER TO postgres;

--
-- Name: pg_statistic_ext; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_statistic_ext (
    oid oid NOT NULL,
    stxrelid oid NOT NULL,
    stxname name NOT NULL,
    stxnamespace oid NOT NULL,
    stxowner oid NOT NULL,
    stxkeys int2vector NOT NULL,
    stxkind "char"[] NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_statistic_ext REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_statistic_ext OWNER TO postgres;

--
-- Name: pg_statistic_ext_data; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_statistic_ext_data (
    stxoid oid NOT NULL,
    stxdndistinct pg_ndistinct COLLATE pg_catalog."C",
    stxddependencies pg_dependencies COLLATE pg_catalog."C",
    stxdmcv pg_mcv_list COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_statistic_ext_data REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_statistic_ext_data OWNER TO postgres;

--
-- Name: pg_stats; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stats WITH (security_barrier='true') AS
 SELECT n.nspname AS schemaname,
    c.relname AS tablename,
    a.attname,
    s.stainherit AS inherited,
    s.stanullfrac AS null_frac,
    s.stawidth AS avg_width,
    s.stadistinct AS n_distinct,
        CASE
            WHEN (s.stakind1 = 1) THEN s.stavalues1
            WHEN (s.stakind2 = 1) THEN s.stavalues2
            WHEN (s.stakind3 = 1) THEN s.stavalues3
            WHEN (s.stakind4 = 1) THEN s.stavalues4
            WHEN (s.stakind5 = 1) THEN s.stavalues5
            ELSE NULL::anyarray
        END AS most_common_vals,
        CASE
            WHEN (s.stakind1 = 1) THEN s.stanumbers1
            WHEN (s.stakind2 = 1) THEN s.stanumbers2
            WHEN (s.stakind3 = 1) THEN s.stanumbers3
            WHEN (s.stakind4 = 1) THEN s.stanumbers4
            WHEN (s.stakind5 = 1) THEN s.stanumbers5
            ELSE NULL::real[]
        END AS most_common_freqs,
        CASE
            WHEN (s.stakind1 = 2) THEN s.stavalues1
            WHEN (s.stakind2 = 2) THEN s.stavalues2
            WHEN (s.stakind3 = 2) THEN s.stavalues3
            WHEN (s.stakind4 = 2) THEN s.stavalues4
            WHEN (s.stakind5 = 2) THEN s.stavalues5
            ELSE NULL::anyarray
        END AS histogram_bounds,
        CASE
            WHEN (s.stakind1 = 3) THEN s.stanumbers1[1]
            WHEN (s.stakind2 = 3) THEN s.stanumbers2[1]
            WHEN (s.stakind3 = 3) THEN s.stanumbers3[1]
            WHEN (s.stakind4 = 3) THEN s.stanumbers4[1]
            WHEN (s.stakind5 = 3) THEN s.stanumbers5[1]
            ELSE NULL::real
        END AS correlation,
        CASE
            WHEN (s.stakind1 = 4) THEN s.stavalues1
            WHEN (s.stakind2 = 4) THEN s.stavalues2
            WHEN (s.stakind3 = 4) THEN s.stavalues3
            WHEN (s.stakind4 = 4) THEN s.stavalues4
            WHEN (s.stakind5 = 4) THEN s.stavalues5
            ELSE NULL::anyarray
        END AS most_common_elems,
        CASE
            WHEN (s.stakind1 = 4) THEN s.stanumbers1
            WHEN (s.stakind2 = 4) THEN s.stanumbers2
            WHEN (s.stakind3 = 4) THEN s.stanumbers3
            WHEN (s.stakind4 = 4) THEN s.stanumbers4
            WHEN (s.stakind5 = 4) THEN s.stanumbers5
            ELSE NULL::real[]
        END AS most_common_elem_freqs,
        CASE
            WHEN (s.stakind1 = 5) THEN s.stanumbers1
            WHEN (s.stakind2 = 5) THEN s.stanumbers2
            WHEN (s.stakind3 = 5) THEN s.stanumbers3
            WHEN (s.stakind4 = 5) THEN s.stanumbers4
            WHEN (s.stakind5 = 5) THEN s.stanumbers5
            ELSE NULL::real[]
        END AS elem_count_histogram
   FROM (((pg_statistic s
     JOIN pg_class c ON ((c.oid = s.starelid)))
     JOIN pg_attribute a ON (((c.oid = a.attrelid) AND (a.attnum = s.staattnum))))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE ((NOT a.attisdropped) AND has_column_privilege(c.oid, a.attnum, 'select'::text) AND ((c.relrowsecurity = false) OR (NOT row_security_active(c.oid))));


ALTER TABLE pg_catalog.pg_stats OWNER TO postgres;

--
-- Name: pg_stats_ext; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_stats_ext WITH (security_barrier='true') AS
 SELECT cn.nspname AS schemaname,
    c.relname AS tablename,
    sn.nspname AS statistics_schemaname,
    s.stxname AS statistics_name,
    pg_get_userbyid(s.stxowner) AS statistics_owner,
    ( SELECT array_agg(a.attname ORDER BY a.attnum) AS array_agg
           FROM (unnest(s.stxkeys) k(k)
             JOIN pg_attribute a ON (((a.attrelid = s.stxrelid) AND (a.attnum = k.k))))) AS attnames,
    s.stxkind AS kinds,
    sd.stxdndistinct AS n_distinct,
    sd.stxddependencies AS dependencies,
    m.most_common_vals,
    m.most_common_val_nulls,
    m.most_common_freqs,
    m.most_common_base_freqs
   FROM (((((pg_statistic_ext s
     JOIN pg_class c ON ((c.oid = s.stxrelid)))
     JOIN pg_statistic_ext_data sd ON ((s.oid = sd.stxoid)))
     LEFT JOIN pg_namespace cn ON ((cn.oid = c.relnamespace)))
     LEFT JOIN pg_namespace sn ON ((sn.oid = s.stxnamespace)))
     LEFT JOIN LATERAL ( SELECT array_agg(pg_mcv_list_items."values") AS most_common_vals,
            array_agg(pg_mcv_list_items.nulls) AS most_common_val_nulls,
            array_agg(pg_mcv_list_items.frequency) AS most_common_freqs,
            array_agg(pg_mcv_list_items.base_frequency) AS most_common_base_freqs
           FROM pg_mcv_list_items(sd.stxdmcv) pg_mcv_list_items(index, "values", nulls, frequency, base_frequency)) m ON ((sd.stxdmcv IS NOT NULL)))
  WHERE ((NOT (EXISTS ( SELECT 1
           FROM (unnest(s.stxkeys) k(k)
             JOIN pg_attribute a ON (((a.attrelid = s.stxrelid) AND (a.attnum = k.k))))
          WHERE (NOT has_column_privilege(c.oid, a.attnum, 'select'::text))))) AND ((c.relrowsecurity = false) OR (NOT row_security_active(c.oid))));


ALTER TABLE pg_catalog.pg_stats_ext OWNER TO postgres;

SET default_tablespace = pg_global;

--
-- Name: pg_subscription; Type: TABLE; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE TABLE pg_catalog.pg_subscription (
    oid oid NOT NULL,
    subdbid oid NOT NULL,
    subname name NOT NULL,
    subowner oid NOT NULL,
    subenabled boolean NOT NULL,
    subconninfo text NOT NULL COLLATE pg_catalog."C",
    subslotname name NOT NULL,
    subsynccommit text NOT NULL COLLATE pg_catalog."C",
    subpublications text[] NOT NULL COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_subscription REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_subscription OWNER TO postgres;

SET default_tablespace = '';

--
-- Name: pg_subscription_rel; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_subscription_rel (
    srsubid oid NOT NULL,
    srrelid oid NOT NULL,
    srsubstate "char" NOT NULL,
    srsublsn pg_lsn NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_subscription_rel REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_subscription_rel OWNER TO postgres;

--
-- Name: pg_tables; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_tables AS
 SELECT n.nspname AS schemaname,
    c.relname AS tablename,
    pg_get_userbyid(c.relowner) AS tableowner,
    t.spcname AS tablespace,
    c.relhasindex AS hasindexes,
    c.relhasrules AS hasrules,
    c.relhastriggers AS hastriggers,
    c.relrowsecurity AS rowsecurity
   FROM ((pg_class c
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
     LEFT JOIN pg_tablespace t ON ((t.oid = c.reltablespace)))
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 'p'::"char"]));


ALTER TABLE pg_catalog.pg_tables OWNER TO postgres;

SET default_tablespace = pg_global;

--
-- Name: pg_tablespace; Type: TABLE; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE TABLE pg_catalog.pg_tablespace (
    oid oid NOT NULL,
    spcname name NOT NULL,
    spcowner oid NOT NULL,
    spcacl aclitem[],
    spcoptions text[] COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_tablespace REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_tablespace OWNER TO postgres;

--
-- Name: pg_timezone_abbrevs; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_timezone_abbrevs AS
 SELECT pg_timezone_abbrevs.abbrev,
    pg_timezone_abbrevs.utc_offset,
    pg_timezone_abbrevs.is_dst
   FROM pg_timezone_abbrevs() pg_timezone_abbrevs(abbrev, utc_offset, is_dst);


ALTER TABLE pg_catalog.pg_timezone_abbrevs OWNER TO postgres;

--
-- Name: pg_timezone_names; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_timezone_names AS
 SELECT pg_timezone_names.name,
    pg_timezone_names.abbrev,
    pg_timezone_names.utc_offset,
    pg_timezone_names.is_dst
   FROM pg_timezone_names() pg_timezone_names(name, abbrev, utc_offset, is_dst);


ALTER TABLE pg_catalog.pg_timezone_names OWNER TO postgres;

SET default_tablespace = '';

--
-- Name: pg_transform; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_transform (
    oid oid NOT NULL,
    trftype oid NOT NULL,
    trflang oid NOT NULL,
    trffromsql regproc NOT NULL,
    trftosql regproc NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_transform REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_transform OWNER TO postgres;

--
-- Name: pg_trigger; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_trigger (
    oid oid NOT NULL,
    tgrelid oid NOT NULL,
    tgname name NOT NULL,
    tgfoid oid NOT NULL,
    tgtype smallint NOT NULL,
    tgenabled "char" NOT NULL,
    tgisinternal boolean NOT NULL,
    tgconstrrelid oid NOT NULL,
    tgconstrindid oid NOT NULL,
    tgconstraint oid NOT NULL,
    tgdeferrable boolean NOT NULL,
    tginitdeferred boolean NOT NULL,
    tgnargs smallint NOT NULL,
    tgattr int2vector NOT NULL,
    tgargs bytea NOT NULL,
    tgqual pg_node_tree COLLATE pg_catalog."C",
    tgoldtable name,
    tgnewtable name
);

ALTER TABLE ONLY pg_catalog.pg_trigger REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_trigger OWNER TO postgres;

--
-- Name: pg_ts_config; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_ts_config (
    oid oid NOT NULL,
    cfgname name NOT NULL,
    cfgnamespace oid NOT NULL,
    cfgowner oid NOT NULL,
    cfgparser oid NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_ts_config REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_ts_config OWNER TO postgres;

--
-- Name: pg_ts_config_map; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_ts_config_map (
    mapcfg oid NOT NULL,
    maptokentype integer NOT NULL,
    mapseqno integer NOT NULL,
    mapdict oid NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_ts_config_map REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_ts_config_map OWNER TO postgres;

--
-- Name: pg_ts_dict; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_ts_dict (
    oid oid NOT NULL,
    dictname name NOT NULL,
    dictnamespace oid NOT NULL,
    dictowner oid NOT NULL,
    dicttemplate oid NOT NULL,
    dictinitoption text COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_ts_dict REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_ts_dict OWNER TO postgres;

--
-- Name: pg_ts_parser; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_ts_parser (
    oid oid NOT NULL,
    prsname name NOT NULL,
    prsnamespace oid NOT NULL,
    prsstart regproc NOT NULL,
    prstoken regproc NOT NULL,
    prsend regproc NOT NULL,
    prsheadline regproc NOT NULL,
    prslextype regproc NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_ts_parser REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_ts_parser OWNER TO postgres;

--
-- Name: pg_ts_template; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_ts_template (
    oid oid NOT NULL,
    tmplname name NOT NULL,
    tmplnamespace oid NOT NULL,
    tmplinit regproc NOT NULL,
    tmpllexize regproc NOT NULL
);

ALTER TABLE ONLY pg_catalog.pg_ts_template REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_ts_template OWNER TO postgres;

--
-- Name: pg_type; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_type (
    oid oid NOT NULL,
    typname name NOT NULL,
    typnamespace oid NOT NULL,
    typowner oid NOT NULL,
    typlen smallint NOT NULL,
    typbyval boolean NOT NULL,
    typtype "char" NOT NULL,
    typcategory "char" NOT NULL,
    typispreferred boolean NOT NULL,
    typisdefined boolean NOT NULL,
    typdelim "char" NOT NULL,
    typrelid oid NOT NULL,
    typelem oid NOT NULL,
    typarray oid NOT NULL,
    typinput regproc NOT NULL,
    typoutput regproc NOT NULL,
    typreceive regproc NOT NULL,
    typsend regproc NOT NULL,
    typmodin regproc NOT NULL,
    typmodout regproc NOT NULL,
    typanalyze regproc NOT NULL,
    typalign "char" NOT NULL,
    typstorage "char" NOT NULL,
    typnotnull boolean NOT NULL,
    typbasetype oid NOT NULL,
    typtypmod integer NOT NULL,
    typndims integer NOT NULL,
    typcollation oid NOT NULL,
    typdefaultbin pg_node_tree COLLATE pg_catalog."C",
    typdefault text COLLATE pg_catalog."C",
    typacl aclitem[]
);

ALTER TABLE ONLY pg_catalog.pg_type REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_type OWNER TO postgres;

--
-- Name: pg_user; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_user AS
 SELECT pg_shadow.usename,
    pg_shadow.usesysid,
    pg_shadow.usecreatedb,
    pg_shadow.usesuper,
    pg_shadow.userepl,
    pg_shadow.usebypassrls,
    '********'::text AS passwd,
    pg_shadow.valuntil,
    pg_shadow.useconfig
   FROM pg_shadow;


ALTER TABLE pg_catalog.pg_user OWNER TO postgres;

--
-- Name: pg_user_mapping; Type: TABLE; Schema: pg_catalog; Owner: postgres
--

CREATE TABLE pg_catalog.pg_user_mapping (
    oid oid NOT NULL,
    umuser oid NOT NULL,
    umserver oid NOT NULL,
    umoptions text[] COLLATE pg_catalog."C"
);

ALTER TABLE ONLY pg_catalog.pg_user_mapping REPLICA IDENTITY NOTHING;


ALTER TABLE pg_catalog.pg_user_mapping OWNER TO postgres;

--
-- Name: pg_user_mappings; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_user_mappings AS
 SELECT u.oid AS umid,
    s.oid AS srvid,
    s.srvname,
    u.umuser,
        CASE
            WHEN (u.umuser = (0)::oid) THEN 'public'::name
            ELSE a.rolname
        END AS usename,
        CASE
            WHEN (((u.umuser <> (0)::oid) AND (a.rolname = CURRENT_USER) AND (pg_has_role(s.srvowner, 'USAGE'::text) OR has_server_privilege(s.oid, 'USAGE'::text))) OR ((u.umuser = (0)::oid) AND pg_has_role(s.srvowner, 'USAGE'::text)) OR ( SELECT pg_authid.rolsuper
               FROM pg_authid
              WHERE (pg_authid.rolname = CURRENT_USER))) THEN u.umoptions
            ELSE NULL::text[]
        END AS umoptions
   FROM ((pg_user_mapping u
     JOIN pg_foreign_server s ON ((u.umserver = s.oid)))
     LEFT JOIN pg_authid a ON ((a.oid = u.umuser)));


ALTER TABLE pg_catalog.pg_user_mappings OWNER TO postgres;

--
-- Name: pg_views; Type: VIEW; Schema: pg_catalog; Owner: postgres
--

CREATE VIEW pg_catalog.pg_views AS
 SELECT n.nspname AS schemaname,
    c.relname AS viewname,
    pg_get_userbyid(c.relowner) AS viewowner,
    pg_get_viewdef(c.oid) AS definition
   FROM (pg_class c
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (c.relkind = 'v'::"char");


ALTER TABLE pg_catalog.pg_views OWNER TO postgres;

--
-- Name: pg_aggregate_fnoid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_aggregate_fnoid_index ON pg_catalog.pg_aggregate USING btree (aggfnoid);


--
-- Name: pg_am_name_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_am_name_index ON pg_catalog.pg_am USING btree (amname);


--
-- Name: pg_am_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_am_oid_index ON pg_catalog.pg_am USING btree (oid);


--
-- Name: pg_amop_fam_strat_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_amop_fam_strat_index ON pg_catalog.pg_amop USING btree (amopfamily, amoplefttype, amoprighttype, amopstrategy);


--
-- Name: pg_amop_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_amop_oid_index ON pg_catalog.pg_amop USING btree (oid);


--
-- Name: pg_amop_opr_fam_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_amop_opr_fam_index ON pg_catalog.pg_amop USING btree (amopopr, amoppurpose, amopfamily);


--
-- Name: pg_amproc_fam_proc_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_amproc_fam_proc_index ON pg_catalog.pg_amproc USING btree (amprocfamily, amproclefttype, amprocrighttype, amprocnum);


--
-- Name: pg_amproc_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_amproc_oid_index ON pg_catalog.pg_amproc USING btree (oid);


--
-- Name: pg_attrdef_adrelid_adnum_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_attrdef_adrelid_adnum_index ON pg_catalog.pg_attrdef USING btree (adrelid, adnum);


--
-- Name: pg_attrdef_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_attrdef_oid_index ON pg_catalog.pg_attrdef USING btree (oid);


--
-- Name: pg_attribute_relid_attnam_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_attribute_relid_attnam_index ON pg_catalog.pg_attribute USING btree (attrelid, attname);


--
-- Name: pg_attribute_relid_attnum_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_attribute_relid_attnum_index ON pg_catalog.pg_attribute USING btree (attrelid, attnum);


SET default_tablespace = pg_global;

--
-- Name: pg_auth_members_member_role_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_auth_members_member_role_index ON pg_catalog.pg_auth_members USING btree (member, roleid);


--
-- Name: pg_auth_members_role_member_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_auth_members_role_member_index ON pg_catalog.pg_auth_members USING btree (roleid, member);


--
-- Name: pg_authid_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_authid_oid_index ON pg_catalog.pg_authid USING btree (oid);


--
-- Name: pg_authid_rolname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_authid_rolname_index ON pg_catalog.pg_authid USING btree (rolname);


SET default_tablespace = '';

--
-- Name: pg_cast_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_cast_oid_index ON pg_catalog.pg_cast USING btree (oid);


--
-- Name: pg_cast_source_target_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_cast_source_target_index ON pg_catalog.pg_cast USING btree (castsource, casttarget);


--
-- Name: pg_class_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_class_oid_index ON pg_catalog.pg_class USING btree (oid);


--
-- Name: pg_class_relname_nsp_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_class_relname_nsp_index ON pg_catalog.pg_class USING btree (relname, relnamespace);


--
-- Name: pg_class_tblspc_relfilenode_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE INDEX pg_class_tblspc_relfilenode_index ON pg_catalog.pg_class USING btree (reltablespace, relfilenode);


--
-- Name: pg_collation_name_enc_nsp_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_collation_name_enc_nsp_index ON pg_catalog.pg_collation USING btree (collname, collencoding, collnamespace);


--
-- Name: pg_collation_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_collation_oid_index ON pg_catalog.pg_collation USING btree (oid);


--
-- Name: pg_constraint_conname_nsp_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE INDEX pg_constraint_conname_nsp_index ON pg_catalog.pg_constraint USING btree (conname, connamespace);


--
-- Name: pg_constraint_conparentid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE INDEX pg_constraint_conparentid_index ON pg_catalog.pg_constraint USING btree (conparentid);


--
-- Name: pg_constraint_conrelid_contypid_conname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_constraint_conrelid_contypid_conname_index ON pg_catalog.pg_constraint USING btree (conrelid, contypid, conname);


--
-- Name: pg_constraint_contypid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE INDEX pg_constraint_contypid_index ON pg_catalog.pg_constraint USING btree (contypid);


--
-- Name: pg_constraint_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_constraint_oid_index ON pg_catalog.pg_constraint USING btree (oid);


--
-- Name: pg_conversion_default_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_conversion_default_index ON pg_catalog.pg_conversion USING btree (connamespace, conforencoding, contoencoding, oid);


--
-- Name: pg_conversion_name_nsp_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_conversion_name_nsp_index ON pg_catalog.pg_conversion USING btree (conname, connamespace);


--
-- Name: pg_conversion_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_conversion_oid_index ON pg_catalog.pg_conversion USING btree (oid);


SET default_tablespace = pg_global;

--
-- Name: pg_database_datname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_database_datname_index ON pg_catalog.pg_database USING btree (datname);


--
-- Name: pg_database_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_database_oid_index ON pg_catalog.pg_database USING btree (oid);


--
-- Name: pg_db_role_setting_databaseid_rol_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_db_role_setting_databaseid_rol_index ON pg_catalog.pg_db_role_setting USING btree (setdatabase, setrole);


SET default_tablespace = '';

--
-- Name: pg_default_acl_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_default_acl_oid_index ON pg_catalog.pg_default_acl USING btree (oid);


--
-- Name: pg_default_acl_role_nsp_obj_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_default_acl_role_nsp_obj_index ON pg_catalog.pg_default_acl USING btree (defaclrole, defaclnamespace, defaclobjtype);


--
-- Name: pg_depend_depender_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE INDEX pg_depend_depender_index ON pg_catalog.pg_depend USING btree (classid, objid, objsubid);


--
-- Name: pg_depend_reference_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE INDEX pg_depend_reference_index ON pg_catalog.pg_depend USING btree (refclassid, refobjid, refobjsubid);


--
-- Name: pg_description_o_c_o_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_description_o_c_o_index ON pg_catalog.pg_description USING btree (objoid, classoid, objsubid);


--
-- Name: pg_enum_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_enum_oid_index ON pg_catalog.pg_enum USING btree (oid);


--
-- Name: pg_enum_typid_label_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_enum_typid_label_index ON pg_catalog.pg_enum USING btree (enumtypid, enumlabel);


--
-- Name: pg_enum_typid_sortorder_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_enum_typid_sortorder_index ON pg_catalog.pg_enum USING btree (enumtypid, enumsortorder);


--
-- Name: pg_event_trigger_evtname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_event_trigger_evtname_index ON pg_catalog.pg_event_trigger USING btree (evtname);


--
-- Name: pg_event_trigger_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_event_trigger_oid_index ON pg_catalog.pg_event_trigger USING btree (oid);


--
-- Name: pg_extension_name_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_extension_name_index ON pg_catalog.pg_extension USING btree (extname);


--
-- Name: pg_extension_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_extension_oid_index ON pg_catalog.pg_extension USING btree (oid);


--
-- Name: pg_foreign_data_wrapper_name_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_foreign_data_wrapper_name_index ON pg_catalog.pg_foreign_data_wrapper USING btree (fdwname);


--
-- Name: pg_foreign_data_wrapper_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_foreign_data_wrapper_oid_index ON pg_catalog.pg_foreign_data_wrapper USING btree (oid);


--
-- Name: pg_foreign_server_name_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_foreign_server_name_index ON pg_catalog.pg_foreign_server USING btree (srvname);


--
-- Name: pg_foreign_server_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_foreign_server_oid_index ON pg_catalog.pg_foreign_server USING btree (oid);


--
-- Name: pg_foreign_table_relid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_foreign_table_relid_index ON pg_catalog.pg_foreign_table USING btree (ftrelid);


--
-- Name: pg_index_indexrelid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_index_indexrelid_index ON pg_catalog.pg_index USING btree (indexrelid);


--
-- Name: pg_index_indrelid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE INDEX pg_index_indrelid_index ON pg_catalog.pg_index USING btree (indrelid);


--
-- Name: pg_inherits_parent_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE INDEX pg_inherits_parent_index ON pg_catalog.pg_inherits USING btree (inhparent);


--
-- Name: pg_inherits_relid_seqno_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_inherits_relid_seqno_index ON pg_catalog.pg_inherits USING btree (inhrelid, inhseqno);


--
-- Name: pg_init_privs_o_c_o_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_init_privs_o_c_o_index ON pg_catalog.pg_init_privs USING btree (objoid, classoid, objsubid);


--
-- Name: pg_language_name_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_language_name_index ON pg_catalog.pg_language USING btree (lanname);


--
-- Name: pg_language_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_language_oid_index ON pg_catalog.pg_language USING btree (oid);


--
-- Name: pg_largeobject_loid_pn_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_largeobject_loid_pn_index ON pg_catalog.pg_largeobject USING btree (loid, pageno);


--
-- Name: pg_largeobject_metadata_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_largeobject_metadata_oid_index ON pg_catalog.pg_largeobject_metadata USING btree (oid);


--
-- Name: pg_namespace_nspname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_namespace_nspname_index ON pg_catalog.pg_namespace USING btree (nspname);


--
-- Name: pg_namespace_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_namespace_oid_index ON pg_catalog.pg_namespace USING btree (oid);


--
-- Name: pg_opclass_am_name_nsp_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_opclass_am_name_nsp_index ON pg_catalog.pg_opclass USING btree (opcmethod, opcname, opcnamespace);


--
-- Name: pg_opclass_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_opclass_oid_index ON pg_catalog.pg_opclass USING btree (oid);


--
-- Name: pg_operator_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_operator_oid_index ON pg_catalog.pg_operator USING btree (oid);


--
-- Name: pg_operator_oprname_l_r_n_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_operator_oprname_l_r_n_index ON pg_catalog.pg_operator USING btree (oprname, oprleft, oprright, oprnamespace);


--
-- Name: pg_opfamily_am_name_nsp_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_opfamily_am_name_nsp_index ON pg_catalog.pg_opfamily USING btree (opfmethod, opfname, opfnamespace);


--
-- Name: pg_opfamily_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_opfamily_oid_index ON pg_catalog.pg_opfamily USING btree (oid);


--
-- Name: pg_partitioned_table_partrelid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_partitioned_table_partrelid_index ON pg_catalog.pg_partitioned_table USING btree (partrelid);


SET default_tablespace = pg_global;

--
-- Name: pg_pltemplate_name_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_pltemplate_name_index ON pg_catalog.pg_pltemplate USING btree (tmplname);


SET default_tablespace = '';

--
-- Name: pg_policy_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_policy_oid_index ON pg_catalog.pg_policy USING btree (oid);


--
-- Name: pg_policy_polrelid_polname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_policy_polrelid_polname_index ON pg_catalog.pg_policy USING btree (polrelid, polname);


--
-- Name: pg_proc_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_proc_oid_index ON pg_catalog.pg_proc USING btree (oid);


--
-- Name: pg_proc_proname_args_nsp_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_proc_proname_args_nsp_index ON pg_catalog.pg_proc USING btree (proname, proargtypes, pronamespace);


--
-- Name: pg_publication_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_publication_oid_index ON pg_catalog.pg_publication USING btree (oid);


--
-- Name: pg_publication_pubname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_publication_pubname_index ON pg_catalog.pg_publication USING btree (pubname);


--
-- Name: pg_publication_rel_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_publication_rel_oid_index ON pg_catalog.pg_publication_rel USING btree (oid);


--
-- Name: pg_publication_rel_prrelid_prpubid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_publication_rel_prrelid_prpubid_index ON pg_catalog.pg_publication_rel USING btree (prrelid, prpubid);


--
-- Name: pg_range_rngtypid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_range_rngtypid_index ON pg_catalog.pg_range USING btree (rngtypid);


SET default_tablespace = pg_global;

--
-- Name: pg_replication_origin_roiident_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_replication_origin_roiident_index ON pg_catalog.pg_replication_origin USING btree (roident);


--
-- Name: pg_replication_origin_roname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_replication_origin_roname_index ON pg_catalog.pg_replication_origin USING btree (roname);


SET default_tablespace = '';

--
-- Name: pg_rewrite_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_rewrite_oid_index ON pg_catalog.pg_rewrite USING btree (oid);


--
-- Name: pg_rewrite_rel_rulename_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_rewrite_rel_rulename_index ON pg_catalog.pg_rewrite USING btree (ev_class, rulename);


--
-- Name: pg_seclabel_object_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_seclabel_object_index ON pg_catalog.pg_seclabel USING btree (objoid, classoid, objsubid, provider);


--
-- Name: pg_sequence_seqrelid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_sequence_seqrelid_index ON pg_catalog.pg_sequence USING btree (seqrelid);


SET default_tablespace = pg_global;

--
-- Name: pg_shdepend_depender_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE INDEX pg_shdepend_depender_index ON pg_catalog.pg_shdepend USING btree (dbid, classid, objid, objsubid);


--
-- Name: pg_shdepend_reference_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE INDEX pg_shdepend_reference_index ON pg_catalog.pg_shdepend USING btree (refclassid, refobjid);


--
-- Name: pg_shdescription_o_c_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_shdescription_o_c_index ON pg_catalog.pg_shdescription USING btree (objoid, classoid);


--
-- Name: pg_shseclabel_object_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_shseclabel_object_index ON pg_catalog.pg_shseclabel USING btree (objoid, classoid, provider);


SET default_tablespace = '';

--
-- Name: pg_statistic_ext_data_stxoid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_statistic_ext_data_stxoid_index ON pg_catalog.pg_statistic_ext_data USING btree (stxoid);


--
-- Name: pg_statistic_ext_name_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_statistic_ext_name_index ON pg_catalog.pg_statistic_ext USING btree (stxname, stxnamespace);


--
-- Name: pg_statistic_ext_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_statistic_ext_oid_index ON pg_catalog.pg_statistic_ext USING btree (oid);


--
-- Name: pg_statistic_ext_relid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE INDEX pg_statistic_ext_relid_index ON pg_catalog.pg_statistic_ext USING btree (stxrelid);


--
-- Name: pg_statistic_relid_att_inh_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_statistic_relid_att_inh_index ON pg_catalog.pg_statistic USING btree (starelid, staattnum, stainherit);


SET default_tablespace = pg_global;

--
-- Name: pg_subscription_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_subscription_oid_index ON pg_catalog.pg_subscription USING btree (oid);


SET default_tablespace = '';

--
-- Name: pg_subscription_rel_srrelid_srsubid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_subscription_rel_srrelid_srsubid_index ON pg_catalog.pg_subscription_rel USING btree (srrelid, srsubid);


SET default_tablespace = pg_global;

--
-- Name: pg_subscription_subname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_subscription_subname_index ON pg_catalog.pg_subscription USING btree (subdbid, subname);


--
-- Name: pg_tablespace_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_tablespace_oid_index ON pg_catalog.pg_tablespace USING btree (oid);


--
-- Name: pg_tablespace_spcname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres; Tablespace: pg_global
--

CREATE UNIQUE INDEX pg_tablespace_spcname_index ON pg_catalog.pg_tablespace USING btree (spcname);


SET default_tablespace = '';

--
-- Name: pg_transform_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_transform_oid_index ON pg_catalog.pg_transform USING btree (oid);


--
-- Name: pg_transform_type_lang_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_transform_type_lang_index ON pg_catalog.pg_transform USING btree (trftype, trflang);


--
-- Name: pg_trigger_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_trigger_oid_index ON pg_catalog.pg_trigger USING btree (oid);


--
-- Name: pg_trigger_tgconstraint_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE INDEX pg_trigger_tgconstraint_index ON pg_catalog.pg_trigger USING btree (tgconstraint);


--
-- Name: pg_trigger_tgrelid_tgname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_trigger_tgrelid_tgname_index ON pg_catalog.pg_trigger USING btree (tgrelid, tgname);


--
-- Name: pg_ts_config_cfgname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_ts_config_cfgname_index ON pg_catalog.pg_ts_config USING btree (cfgname, cfgnamespace);


--
-- Name: pg_ts_config_map_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_ts_config_map_index ON pg_catalog.pg_ts_config_map USING btree (mapcfg, maptokentype, mapseqno);


--
-- Name: pg_ts_config_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_ts_config_oid_index ON pg_catalog.pg_ts_config USING btree (oid);


--
-- Name: pg_ts_dict_dictname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_ts_dict_dictname_index ON pg_catalog.pg_ts_dict USING btree (dictname, dictnamespace);


--
-- Name: pg_ts_dict_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_ts_dict_oid_index ON pg_catalog.pg_ts_dict USING btree (oid);


--
-- Name: pg_ts_parser_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_ts_parser_oid_index ON pg_catalog.pg_ts_parser USING btree (oid);


--
-- Name: pg_ts_parser_prsname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_ts_parser_prsname_index ON pg_catalog.pg_ts_parser USING btree (prsname, prsnamespace);


--
-- Name: pg_ts_template_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_ts_template_oid_index ON pg_catalog.pg_ts_template USING btree (oid);


--
-- Name: pg_ts_template_tmplname_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_ts_template_tmplname_index ON pg_catalog.pg_ts_template USING btree (tmplname, tmplnamespace);


--
-- Name: pg_type_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_type_oid_index ON pg_catalog.pg_type USING btree (oid);


--
-- Name: pg_type_typname_nsp_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_type_typname_nsp_index ON pg_catalog.pg_type USING btree (typname, typnamespace);


--
-- Name: pg_user_mapping_oid_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_user_mapping_oid_index ON pg_catalog.pg_user_mapping USING btree (oid);


--
-- Name: pg_user_mapping_user_server_index; Type: INDEX; Schema: pg_catalog; Owner: postgres
--

CREATE UNIQUE INDEX pg_user_mapping_user_server_index ON pg_catalog.pg_user_mapping USING btree (umuser, umserver);


--
-- Name: pg_settings pg_settings_n; Type: RULE; Schema: pg_catalog; Owner: postgres
--

CREATE RULE pg_settings_n AS
    ON UPDATE TO pg_catalog.pg_settings DO INSTEAD NOTHING;


--
-- Name: pg_settings pg_settings_u; Type: RULE; Schema: pg_catalog; Owner: postgres
--

CREATE RULE pg_settings_u AS
    ON UPDATE TO pg_catalog.pg_settings
   WHERE (new.name = old.name) DO  SELECT set_config(old.name, new.setting, false) AS set_config;


--
-- PostgreSQL database dump complete
--

