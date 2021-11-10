

-- jsonb_path_exists ----------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING.eval_jsonb_path_exists(_op SCHEMA_TAG.tag_op_jsonb_path_exists)
RETURNS jsonb[]
AS $func$
    SELECT coalesce(array_agg(jsonb_build_object(a.key_id, a.id)), array[]::jsonb[])
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _op.tag_key
    AND jsonb_path_exists(a.value, _op.value)
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.eval_jsonb_path_exists(SCHEMA_TAG.tag_op_jsonb_path_exists) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.match_jsonb_path_exists(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _op SCHEMA_TAG.tag_op_jsonb_path_exists)
RETURNS boolean
AS $func$
    SELECT _tag_map @> ANY(SCHEMA_TRACING.eval_jsonb_path_exists(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.match_jsonb_path_exists(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TAG.tag_op_jsonb_path_exists) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.tag_map,
        RIGHTARG = SCHEMA_TAG.tag_op_jsonb_path_exists,
        FUNCTION = SCHEMA_TRACING.match_jsonb_path_exists
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_match_jsonb_path_exists(_span SCHEMA_TRACING_PUBLIC.span, _op SCHEMA_TAG.tag_op_jsonb_path_exists)
RETURNS boolean
AS $func$
    SELECT _span.span_tags @> ANY(SCHEMA_TRACING.eval_jsonb_path_exists(_op))
    or _span.resource_tags @> ANY(SCHEMA_TRACING.eval_jsonb_path_exists(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_match_jsonb_path_exists(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TAG.tag_op_jsonb_path_exists) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TAG.tag_op_jsonb_path_exists,
        FUNCTION = SCHEMA_TRACING.span_match_jsonb_path_exists
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_match_jsonb_path_exists(_event SCHEMA_TRACING_PUBLIC.event, _op SCHEMA_TAG.tag_op_jsonb_path_exists)
RETURNS boolean
AS $func$
    SELECT _event.tags @> ANY(SCHEMA_TRACING.eval_jsonb_path_exists(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_match_jsonb_path_exists(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TAG.tag_op_jsonb_path_exists) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TAG.tag_op_jsonb_path_exists,
        FUNCTION = SCHEMA_TRACING.event_match_jsonb_path_exists
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_match_jsonb_path_exists(_link SCHEMA_TRACING_PUBLIC.link, _op SCHEMA_TAG.tag_op_jsonb_path_exists)
RETURNS boolean
AS $func$
    SELECT _link.tags @> ANY(SCHEMA_TRACING.eval_jsonb_path_exists(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_match_jsonb_path_exists(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TAG.tag_op_jsonb_path_exists) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TAG.tag_op_jsonb_path_exists,
        FUNCTION = SCHEMA_TRACING.link_match_jsonb_path_exists
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- regexp matches -------------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING.eval_regexp_matches(_op SCHEMA_TAG.tag_op_regexp_matches)
RETURNS jsonb[]
AS $func$
    SELECT coalesce(array_agg(jsonb_build_object(a.key_id, a.id)), array[]::jsonb[])
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _op.tag_key
    -- if the jsonb value is a string, apply the regex directly
    -- otherwise, convert the value to a text representation, back to a jsonb string, and then apply
    AND CASE jsonb_typeof(a.value)
        WHEN 'string' THEN jsonb_path_exists(a.value, format('$?(@ like_regex "%s")', _op.value)::jsonpath)
        ELSE jsonb_path_exists(to_jsonb(a.value#>>'{}'), format('$?(@ like_regex "%s")', _op.value)::jsonpath)
    END
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.eval_regexp_matches(SCHEMA_TAG.tag_op_regexp_matches) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.match_regexp_matches(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _op SCHEMA_TAG.tag_op_regexp_matches)
RETURNS boolean
AS $func$
    SELECT _tag_map @> ANY(SCHEMA_TRACING.eval_regexp_matches(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.match_regexp_matches(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TAG.tag_op_regexp_matches) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.tag_map,
        RIGHTARG = SCHEMA_TAG.tag_op_regexp_matches,
        FUNCTION = SCHEMA_TRACING.match_regexp_matches
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_match_regexp_matches(_span SCHEMA_TRACING_PUBLIC.span, _op SCHEMA_TAG.tag_op_regexp_matches)
RETURNS boolean
AS $func$
    SELECT _span.span_tags @> ANY(SCHEMA_TRACING.eval_regexp_matches(_op))
    or _span.resource_tags @> ANY(SCHEMA_TRACING.eval_regexp_matches(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_match_regexp_matches(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TAG.tag_op_regexp_matches) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TAG.tag_op_regexp_matches,
        FUNCTION = SCHEMA_TRACING.span_match_regexp_matches
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_match_regexp_matches(_event SCHEMA_TRACING_PUBLIC.event, _op SCHEMA_TAG.tag_op_regexp_matches)
RETURNS boolean
AS $func$
    SELECT _event.tags @> ANY(SCHEMA_TRACING.eval_regexp_matches(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_match_regexp_matches(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TAG.tag_op_regexp_matches) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TAG.tag_op_regexp_matches,
        FUNCTION = SCHEMA_TRACING.event_match_regexp_matches
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_match_regexp_matches(_link SCHEMA_TRACING_PUBLIC.link, _op SCHEMA_TAG.tag_op_regexp_matches)
RETURNS boolean
AS $func$
    SELECT _link.tags @> ANY(SCHEMA_TRACING.eval_regexp_matches(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_match_regexp_matches(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TAG.tag_op_regexp_matches) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TAG.tag_op_regexp_matches,
        FUNCTION = SCHEMA_TRACING.link_match_regexp_matches
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- regexp not matches ---------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING.eval_regexp_not_matches(_op SCHEMA_TAG.tag_op_regexp_not_matches)
RETURNS jsonb[]
AS $func$
    SELECT coalesce(array_agg(jsonb_build_object(a.key_id, a.id)), array[]::jsonb[])
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _op.tag_key
    -- if the jsonb value is a string, apply the regex directly
    -- otherwise, convert the value to a text representation, back to a jsonb string, and then apply
    AND CASE jsonb_typeof(a.value)
        WHEN 'string' THEN jsonb_path_exists(a.value, format('$?(!(@ like_regex "%s"))', _op.value)::jsonpath)
        ELSE jsonb_path_exists(to_jsonb(a.value#>>'{}'), format('$?(!(@ like_regex "%s"))', _op.value)::jsonpath)
    END
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.eval_regexp_not_matches(SCHEMA_TAG.tag_op_regexp_not_matches) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.match_regexp_not_matches(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _op SCHEMA_TAG.tag_op_regexp_not_matches)
RETURNS boolean
AS $func$
    SELECT _tag_map @> ANY(SCHEMA_TRACING.eval_regexp_not_matches(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.match_regexp_not_matches(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TAG.tag_op_regexp_not_matches) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.tag_map,
        RIGHTARG = SCHEMA_TAG.tag_op_regexp_not_matches,
        FUNCTION = SCHEMA_TRACING.match_regexp_not_matches
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_match_regexp_not_matches(_span SCHEMA_TRACING_PUBLIC.span, _op SCHEMA_TAG.tag_op_regexp_not_matches)
RETURNS boolean
AS $func$
    SELECT _span.span_tags @> ANY(SCHEMA_TRACING.eval_regexp_not_matches(_op))
    or _span.resource_tags @> ANY(SCHEMA_TRACING.eval_regexp_not_matches(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_match_regexp_not_matches(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TAG.tag_op_regexp_not_matches) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TAG.tag_op_regexp_not_matches,
        FUNCTION = SCHEMA_TRACING.span_match_regexp_not_matches
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_match_regexp_not_matches(_event SCHEMA_TRACING_PUBLIC.event, _op SCHEMA_TAG.tag_op_regexp_not_matches)
RETURNS boolean
AS $func$
    SELECT _event.tags @> ANY(SCHEMA_TRACING.eval_regexp_not_matches(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_match_regexp_not_matches(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TAG.tag_op_regexp_not_matches) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TAG.tag_op_regexp_not_matches,
        FUNCTION = SCHEMA_TRACING.event_match_regexp_not_matches
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_match_regexp_not_matches(_link SCHEMA_TRACING_PUBLIC.link, _op SCHEMA_TAG.tag_op_regexp_not_matches)
RETURNS boolean
AS $func$
    SELECT _link.tags @> ANY(SCHEMA_TRACING.eval_regexp_not_matches(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_match_regexp_not_matches(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TAG.tag_op_regexp_not_matches) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TAG.tag_op_regexp_not_matches,
        FUNCTION = SCHEMA_TRACING.link_match_regexp_not_matches
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- equals ---------------------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING.eval_equals(_op SCHEMA_TAG.tag_op_equals)
RETURNS jsonb
AS $func$
    SELECT jsonb_build_object(a.key_id, a.id)
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _op.tag_key
    AND a.value = _op.value
    LIMIT 1
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.eval_equals(SCHEMA_TAG.tag_op_equals) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.match_equals(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _op SCHEMA_TAG.tag_op_equals)
RETURNS boolean
AS $func$
    SELECT _tag_map @> (SCHEMA_TRACING.eval_equals(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.match_equals(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TAG.tag_op_equals) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.tag_map,
        RIGHTARG = SCHEMA_TAG.tag_op_equals,
        FUNCTION = SCHEMA_TRACING.match_equals
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_match_equals(_span SCHEMA_TRACING_PUBLIC.span, _op SCHEMA_TAG.tag_op_equals)
RETURNS boolean
AS $func$
    SELECT _span.span_tags @> (SCHEMA_TRACING.eval_equals(_op))
    or _span.resource_tags @> (SCHEMA_TRACING.eval_equals(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_match_equals(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TAG.tag_op_equals) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TAG.tag_op_equals,
        FUNCTION = SCHEMA_TRACING.span_match_equals
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_match_equals(_event SCHEMA_TRACING_PUBLIC.event, _op SCHEMA_TAG.tag_op_equals)
RETURNS boolean
AS $func$
    SELECT _event.tags @> (SCHEMA_TRACING.eval_equals(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_match_equals(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TAG.tag_op_equals) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TAG.tag_op_equals,
        FUNCTION = SCHEMA_TRACING.event_match_equals
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_match_equals(_link SCHEMA_TRACING_PUBLIC.link, _op SCHEMA_TAG.tag_op_equals)
RETURNS boolean
AS $func$
    SELECT _link.tags @> (SCHEMA_TRACING.eval_equals(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_match_equals(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TAG.tag_op_equals) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TAG.tag_op_equals,
        FUNCTION = SCHEMA_TRACING.link_match_equals
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- not equals -----------------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING.eval_not_equals(_op SCHEMA_TAG.tag_op_not_equals)
RETURNS jsonb[]
AS $func$
    SELECT coalesce(array_agg(jsonb_build_object(a.key_id, a.id)), array[]::jsonb[])
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _op.tag_key
    AND a.value != _op.value
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.eval_not_equals(SCHEMA_TAG.tag_op_not_equals) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.match_not_equals(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _op SCHEMA_TAG.tag_op_not_equals)
RETURNS boolean
AS $func$
    SELECT _tag_map @> ANY(SCHEMA_TRACING.eval_not_equals(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.match_not_equals(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TAG.tag_op_not_equals) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.tag_map,
        RIGHTARG = SCHEMA_TAG.tag_op_not_equals,
        FUNCTION = SCHEMA_TRACING.match_not_equals
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_match_not_equals(_span SCHEMA_TRACING_PUBLIC.span, _op SCHEMA_TAG.tag_op_not_equals)
RETURNS boolean
AS $func$
    SELECT _span.span_tags @> ANY(SCHEMA_TRACING.eval_not_equals(_op))
    or _span.resource_tags @> ANY(SCHEMA_TRACING.eval_not_equals(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_match_not_equals(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TAG.tag_op_not_equals) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TAG.tag_op_not_equals,
        FUNCTION = SCHEMA_TRACING.span_match_not_equals
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_match_not_equals(_event SCHEMA_TRACING_PUBLIC.event, _op SCHEMA_TAG.tag_op_not_equals)
RETURNS boolean
AS $func$
    SELECT _event.tags @> ANY(SCHEMA_TRACING.eval_not_equals(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_match_not_equals(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TAG.tag_op_not_equals) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TAG.tag_op_not_equals,
        FUNCTION = SCHEMA_TRACING.event_match_not_equals
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_match_not_equals(_link SCHEMA_TRACING_PUBLIC.link, _op SCHEMA_TAG.tag_op_not_equals)
RETURNS boolean
AS $func$
    SELECT _link.tags @> ANY(SCHEMA_TRACING.eval_not_equals(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_match_not_equals(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TAG.tag_op_not_equals) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TAG.tag_op_not_equals,
        FUNCTION = SCHEMA_TRACING.link_match_not_equals
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- less than ------------------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING.eval_less_than(_op SCHEMA_TAG.tag_op_less_than)
RETURNS jsonb[]
AS $func$
    SELECT coalesce(array_agg(jsonb_build_object(a.key_id, a.id)), array[]::jsonb[])
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _op.tag_key
    AND jsonb_path_exists(a.value, '$?(@ < $x)'::jsonpath, jsonb_build_object('x', _op.value))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.eval_less_than(SCHEMA_TAG.tag_op_less_than) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.match_less_than(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _op SCHEMA_TAG.tag_op_less_than)
RETURNS boolean
AS $func$
    SELECT _tag_map @> ANY(SCHEMA_TRACING.eval_less_than(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.match_less_than(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TAG.tag_op_less_than) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.tag_map,
        RIGHTARG = SCHEMA_TAG.tag_op_less_than,
        FUNCTION = SCHEMA_TRACING.match_less_than
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_match_less_than(_span SCHEMA_TRACING_PUBLIC.span, _op SCHEMA_TAG.tag_op_less_than)
RETURNS boolean
AS $func$
    SELECT _span.span_tags @> ANY(SCHEMA_TRACING.eval_less_than(_op))
    or _span.resource_tags @> ANY(SCHEMA_TRACING.eval_less_than(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_match_less_than(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TAG.tag_op_less_than) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TAG.tag_op_less_than,
        FUNCTION = SCHEMA_TRACING.span_match_less_than
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_match_less_than(_event SCHEMA_TRACING_PUBLIC.event, _op SCHEMA_TAG.tag_op_less_than)
RETURNS boolean
AS $func$
    SELECT _event.tags @> ANY(SCHEMA_TRACING.eval_less_than(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_match_less_than(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TAG.tag_op_less_than) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TAG.tag_op_less_than,
        FUNCTION = SCHEMA_TRACING.event_match_less_than
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_match_less_than(_link SCHEMA_TRACING_PUBLIC.link, _op SCHEMA_TAG.tag_op_less_than)
RETURNS boolean
AS $func$
    SELECT _link.tags @> ANY(SCHEMA_TRACING.eval_less_than(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_match_less_than(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TAG.tag_op_less_than) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TAG.tag_op_less_than,
        FUNCTION = SCHEMA_TRACING.link_match_less_than
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- less than or equal ---------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING.eval_less_than_or_equal(_op SCHEMA_TAG.tag_op_less_than_or_equal)
RETURNS jsonb[]
AS $func$
    SELECT coalesce(array_agg(jsonb_build_object(a.key_id, a.id)), array[]::jsonb[])
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _op.tag_key
    AND jsonb_path_exists(a.value, '$?(@ <= $x)'::jsonpath, jsonb_build_object('x', _op.value))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.eval_less_than_or_equal(SCHEMA_TAG.tag_op_less_than_or_equal) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.match_less_than_or_equal(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _op SCHEMA_TAG.tag_op_less_than_or_equal)
RETURNS boolean
AS $func$
    SELECT _tag_map @> ANY(SCHEMA_TRACING.eval_less_than_or_equal(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.match_less_than_or_equal(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TAG.tag_op_less_than_or_equal) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.tag_map,
        RIGHTARG = SCHEMA_TAG.tag_op_less_than_or_equal,
        FUNCTION = SCHEMA_TRACING.match_less_than_or_equal
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_match_less_than_or_equal(_span SCHEMA_TRACING_PUBLIC.span, _op SCHEMA_TAG.tag_op_less_than_or_equal)
RETURNS boolean
AS $func$
    SELECT _span.span_tags @> ANY(SCHEMA_TRACING.eval_less_than_or_equal(_op))
    or _span.resource_tags @> ANY(SCHEMA_TRACING.eval_less_than_or_equal(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_match_less_than_or_equal(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TAG.tag_op_less_than_or_equal) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TAG.tag_op_less_than_or_equal,
        FUNCTION = SCHEMA_TRACING.span_match_less_than_or_equal
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_match_less_than_or_equal(_event SCHEMA_TRACING_PUBLIC.event, _op SCHEMA_TAG.tag_op_less_than_or_equal)
RETURNS boolean
AS $func$
    SELECT _event.tags @> ANY(SCHEMA_TRACING.eval_less_than_or_equal(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_match_less_than_or_equal(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TAG.tag_op_less_than_or_equal) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TAG.tag_op_less_than_or_equal,
        FUNCTION = SCHEMA_TRACING.event_match_less_than_or_equal
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_match_less_than_or_equal(_link SCHEMA_TRACING_PUBLIC.link, _op SCHEMA_TAG.tag_op_less_than_or_equal)
RETURNS boolean
AS $func$
    SELECT _link.tags @> ANY(SCHEMA_TRACING.eval_less_than_or_equal(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_match_less_than_or_equal(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TAG.tag_op_less_than_or_equal) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TAG.tag_op_less_than_or_equal,
        FUNCTION = SCHEMA_TRACING.link_match_less_than_or_equal
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- greater than ---------------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING.eval_greater_than(_op SCHEMA_TAG.tag_op_greater_than)
RETURNS jsonb[]
AS $func$
    SELECT coalesce(array_agg(jsonb_build_object(a.key_id, a.id)), array[]::jsonb[])
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _op.tag_key
    AND jsonb_path_exists(a.value, '$?(@ > $x)'::jsonpath, jsonb_build_object('x', _op.value))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.eval_greater_than(SCHEMA_TAG.tag_op_greater_than) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.match_greater_than(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _op SCHEMA_TAG.tag_op_greater_than)
RETURNS boolean
AS $func$
    SELECT _tag_map @> ANY(SCHEMA_TRACING.eval_greater_than(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.match_greater_than(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TAG.tag_op_greater_than) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.tag_map,
        RIGHTARG = SCHEMA_TAG.tag_op_greater_than,
        FUNCTION = SCHEMA_TRACING.match_greater_than
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_match_greater_than(_span SCHEMA_TRACING_PUBLIC.span, _op SCHEMA_TAG.tag_op_greater_than)
RETURNS boolean
AS $func$
    SELECT _span.span_tags @> ANY(SCHEMA_TRACING.eval_greater_than(_op))
    or _span.resource_tags @> ANY(SCHEMA_TRACING.eval_greater_than(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_match_greater_than(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TAG.tag_op_greater_than) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TAG.tag_op_greater_than,
        FUNCTION = SCHEMA_TRACING.span_match_greater_than
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_match_greater_than(_event SCHEMA_TRACING_PUBLIC.event, _op SCHEMA_TAG.tag_op_greater_than)
RETURNS boolean
AS $func$
    SELECT _event.tags @> ANY(SCHEMA_TRACING.eval_greater_than(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_match_greater_than(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TAG.tag_op_greater_than) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TAG.tag_op_greater_than,
        FUNCTION = SCHEMA_TRACING.event_match_greater_than
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_match_greater_than(_link SCHEMA_TRACING_PUBLIC.link, _op SCHEMA_TAG.tag_op_greater_than)
RETURNS boolean
AS $func$
    SELECT _link.tags @> ANY(SCHEMA_TRACING.eval_greater_than(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_match_greater_than(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TAG.tag_op_greater_than) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TAG.tag_op_greater_than,
        FUNCTION = SCHEMA_TRACING.link_match_greater_than
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- greater than or equal --------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING.eval_greater_than_or_equal(_op SCHEMA_TAG.tag_op_greater_than_or_equal)
RETURNS jsonb[]
AS $func$
    SELECT coalesce(array_agg(jsonb_build_object(a.key_id, a.id)), array[]::jsonb[])
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _op.tag_key
    AND jsonb_path_exists(a.value, '$?(@ >= $x)'::jsonpath, jsonb_build_object('x', _op.value))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.eval_greater_than_or_equal(SCHEMA_TAG.tag_op_greater_than_or_equal) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.match_greater_than_or_equal(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _op SCHEMA_TAG.tag_op_greater_than_or_equal)
RETURNS boolean
AS $func$
    SELECT _tag_map @> ANY(SCHEMA_TRACING.eval_greater_than_or_equal(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.match_greater_than_or_equal(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TAG.tag_op_greater_than_or_equal) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.tag_map,
        RIGHTARG = SCHEMA_TAG.tag_op_greater_than_or_equal,
        FUNCTION = SCHEMA_TRACING.match_greater_than_or_equal
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_match_greater_than_or_equal(_span SCHEMA_TRACING_PUBLIC.span, _op SCHEMA_TAG.tag_op_greater_than_or_equal)
RETURNS boolean
AS $func$
    SELECT _span.span_tags @> ANY(SCHEMA_TRACING.eval_greater_than_or_equal(_op))
    or _span.resource_tags @> ANY(SCHEMA_TRACING.eval_greater_than_or_equal(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_match_greater_than_or_equal(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TAG.tag_op_greater_than_or_equal) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TAG.tag_op_greater_than_or_equal,
        FUNCTION = SCHEMA_TRACING.span_match_greater_than_or_equal
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_match_greater_than_or_equal(_event SCHEMA_TRACING_PUBLIC.event, _op SCHEMA_TAG.tag_op_greater_than_or_equal)
RETURNS boolean
AS $func$
    SELECT _event.tags @> ANY(SCHEMA_TRACING.eval_greater_than_or_equal(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_match_greater_than_or_equal(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TAG.tag_op_greater_than_or_equal) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TAG.tag_op_greater_than_or_equal,
        FUNCTION = SCHEMA_TRACING.event_match_greater_than_or_equal
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_match_greater_than_or_equal(_link SCHEMA_TRACING_PUBLIC.link, _op SCHEMA_TAG.tag_op_greater_than_or_equal)
RETURNS boolean
AS $func$
    SELECT _link.tags @> ANY(SCHEMA_TRACING.eval_greater_than_or_equal(_op))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_match_greater_than_or_equal(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TAG.tag_op_greater_than_or_equal) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TAG.tag_op_greater_than_or_equal,
        FUNCTION = SCHEMA_TRACING.link_match_greater_than_or_equal
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- tag exists -------------------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING.eval_tags_by_key(_key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS jsonb[]
AS $func$
    SELECT coalesce(array_agg(jsonb_build_object(a.key_id, a.id)), array[]::jsonb[])
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _key
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.eval_tags_by_key(SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.tag_exists(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS boolean
AS $func$
    SELECT _tag_map @> ANY(SCHEMA_TRACING.eval_tags_by_key(_key))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.tag_exists(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.tag_map,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.tag_exists
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_tag_exists(_span SCHEMA_TRACING_PUBLIC.span, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS boolean
AS $func$
    SELECT _span.span_tags @> ANY(SCHEMA_TRACING.eval_tags_by_key(_key))
    or _span.resource_tags @> ANY(SCHEMA_TRACING.eval_tags_by_key(_key))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_tag_exists(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.span_tag_exists
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_tag_exists(_event SCHEMA_TRACING_PUBLIC.event, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS boolean
AS $func$
    SELECT _event.tags @> ANY(SCHEMA_TRACING.eval_tags_by_key(_key))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_tag_exists(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.event_tag_exists
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_tag_exists(_link SCHEMA_TRACING_PUBLIC.link, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS boolean
AS $func$
    SELECT _link.tags @> ANY(SCHEMA_TRACING.eval_tags_by_key(_key))
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_tag_exists(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.? (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.link_tag_exists
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- tag id -------------------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING.get_tag_id(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS bigint
AS $func$
    SELECT (_tag_map->(SELECT k.id::text from _ps_trace.tag_key k WHERE k.key = _key LIMIT 1))::bigint
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.get_tag_id(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.# (
        LEFTARG = SCHEMA_TRACING_PUBLIC.tag_map,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.get_tag_id
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_get_tag_id(_span SCHEMA_TRACING_PUBLIC.span, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS bigint
AS $func$
    SELECT SCHEMA_TRACING.get_tag_id(_span.span_tags, _key)
    UNION ALL
    SELECT SCHEMA_TRACING.get_tag_id(_span.resource_tags, _key)
    LIMIT 1
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_get_tag_id(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.# (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.span_get_tag_id
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_get_tag_id(_event SCHEMA_TRACING_PUBLIC.event, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS bigint
AS $func$
    SELECT SCHEMA_TRACING.get_tag_id(_event.tags, _key)
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_get_tag_id(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.# (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.event_get_tag_id
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_get_tag_id(_link SCHEMA_TRACING_PUBLIC.link, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS bigint
AS $func$
    SELECT SCHEMA_TRACING.get_tag_id(_link.tags, _key)
$func$
LANGUAGE SQL STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_get_tag_id(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.# (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.link_get_tag_id
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- jsonb ------------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING_PUBLIC.jsonb(_tag_map SCHEMA_TRACING_PUBLIC.tag_map)
RETURNS jsonb
AS $func$
    /*
    takes an tag_map which is a map of tag_key.id to tag.id
    and returns a jsonb object containing the key value pairs of tags
    */
    SELECT jsonb_object_agg(a.key, a.value)
    FROM jsonb_each(_tag_map) x -- key is tag_key.id, value is tag.id
    INNER JOIN LATERAL -- inner join lateral enables partition elimination at execution time
    (
        SELECT
            a.key,
            a.value
        FROM SCHEMA_TRACING.tag a
        WHERE a.id = x.value::text::bigint
        -- filter on a.key to eliminate all but one partition of the tag table
        AND a.key = (SELECT k.key from SCHEMA_TRACING.tag_key k WHERE k.id = x.key::bigint)
        LIMIT 1
    ) a on (true)
$func$
LANGUAGE SQL STABLE PARALLEL SAFE STRICT;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING_PUBLIC.jsonb(SCHEMA_TRACING_PUBLIC.tag_map) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING_PUBLIC.jsonb(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, VARIADIC _keys SCHEMA_TRACING_PUBLIC.tag_k[])
RETURNS jsonb
AS $func$
    /*
    takes an tag_map which is a map of tag_key.id to tag.id
    and returns a jsonb object containing the key value pairs of tags
    only the key/value pairs with keys passed as arguments are included in the output
    */
    SELECT jsonb_object_agg(a.key, a.value)
    FROM jsonb_each(_tag_map) x -- key is tag_key.id, value is tag.id
    INNER JOIN LATERAL -- inner join lateral enables partition elimination at execution time
    (
        SELECT
            a.key,
            a.value
        FROM SCHEMA_TRACING.tag a
        WHERE a.id = x.value::text::bigint
        AND a.key = ANY(_keys) -- ANY works with partition elimination
    ) a on (true)
$func$
LANGUAGE SQL STABLE PARALLEL SAFE STRICT;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING_PUBLIC.jsonb(SCHEMA_TRACING_PUBLIC.tag_map) TO prom_reader;


-- val ---------------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING_PUBLIC.val(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS SCHEMA_TRACING_PUBLIC.tag_v
AS $func$
    SELECT a.value
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _key -- partition elimination
    AND a.id = (_tag_map->>(a.key_id::text))::bigint
    LIMIT 1
$func$
LANGUAGE SQL STABLE PARALLEL SAFE STRICT;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING_PUBLIC.val(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_val(_span SCHEMA_TRACING_PUBLIC.span, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS SCHEMA_TRACING_PUBLIC.tag_v
AS $func$
    SELECT coalesce(
        SCHEMA_TRACING_PUBLIC.val(_span.span_tags, _key),
        SCHEMA_TRACING_PUBLIC.val(_span.resource_tags, _key)
    )
$func$
LANGUAGE SQL STABLE PARALLEL SAFE STRICT;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_val(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.-> (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.span_val
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_val(_event SCHEMA_TRACING_PUBLIC.event, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS SCHEMA_TRACING_PUBLIC.tag_v
AS $func$
    SELECT SCHEMA_TRACING_PUBLIC.val(_event.tags, _key)
$func$
LANGUAGE SQL STABLE PARALLEL SAFE STRICT;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_val(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.-> (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.event_val
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_val(_link SCHEMA_TRACING_PUBLIC.link, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS SCHEMA_TRACING_PUBLIC.tag_v
AS $func$
    SELECT SCHEMA_TRACING_PUBLIC.val(_link.tags, _key)
$func$
LANGUAGE SQL STABLE PARALLEL SAFE STRICT;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_val(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.-> (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.link_val
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;


-- val text ------------------------------------------------------


CREATE OR REPLACE FUNCTION SCHEMA_TRACING_PUBLIC.val_text(_tag_map SCHEMA_TRACING_PUBLIC.tag_map, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS text
AS $func$
    SELECT a.value#>>'{}'
    FROM SCHEMA_TRACING.tag a
    WHERE a.key = _key -- partition elimination
    AND a.id = (_tag_map->>(a.key_id::text))::bigint
    LIMIT 1
$func$
LANGUAGE SQL STABLE PARALLEL SAFE STRICT;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING_PUBLIC.val_text(SCHEMA_TRACING_PUBLIC.tag_map, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.span_val_text(_span SCHEMA_TRACING_PUBLIC.span, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS text
AS $func$
    SELECT coalesce(
        SCHEMA_TRACING_PUBLIC.val_text(_span.span_tags, _key),
        SCHEMA_TRACING_PUBLIC.val_text(_span.resource_tags, _key)
    )
$func$
LANGUAGE SQL STABLE PARALLEL SAFE STRICT;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.span_val_text(SCHEMA_TRACING_PUBLIC.span, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.->> (
        LEFTARG = SCHEMA_TRACING_PUBLIC.span,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.span_val_text
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.event_val_text(_event SCHEMA_TRACING_PUBLIC.event, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS text
AS $func$
    SELECT SCHEMA_TRACING_PUBLIC.val_text(_event.tags, _key)
$func$
LANGUAGE SQL STABLE PARALLEL SAFE STRICT;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.event_val_text(SCHEMA_TRACING_PUBLIC.event, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.->> (
        LEFTARG = SCHEMA_TRACING_PUBLIC.event,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.event_val_text
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;

CREATE OR REPLACE FUNCTION SCHEMA_TRACING.link_val_text(_link SCHEMA_TRACING_PUBLIC.link, _key SCHEMA_TRACING_PUBLIC.tag_k)
RETURNS text
AS $func$
    SELECT SCHEMA_TRACING_PUBLIC.val_text(_link.tags, _key)
$func$
LANGUAGE SQL STABLE PARALLEL SAFE STRICT;
GRANT EXECUTE ON FUNCTION SCHEMA_TRACING.link_val_text(SCHEMA_TRACING_PUBLIC.link, SCHEMA_TRACING_PUBLIC.tag_k) TO prom_reader;

DO $do$
BEGIN
    CREATE OPERATOR SCHEMA_TRACING_PUBLIC.->> (
        LEFTARG = SCHEMA_TRACING_PUBLIC.link,
        RIGHTARG = SCHEMA_TRACING_PUBLIC.tag_k,
        FUNCTION = SCHEMA_TRACING.link_val_text
    );
EXCEPTION
    WHEN SQLSTATE '42723' THEN -- operator already exists
        null;
END;
$do$;
