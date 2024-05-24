DROP TABLE IF EXISTS lg_table CASCADE;
CREATE TABLE lg_table
(
    id           SERIAL,
    pg_context_v TEXT,
    log_key      TEXT,
    ctx_id       int8      DEFAULT TXID_CURRENT( ),
    ex_timestamp TIMESTAMP DEFAULT CLOCK_TIMESTAMP( )
);

CREATE OR REPLACE FUNCTION lg_func(log_key TEXT) RETURNS TEXT
    LANGUAGE plpgsql AS
$fnc_body$
DECLARE
    stack TEXT;
BEGIN
    GET DIAGNOSTICS stack = PG_CONTEXT;
    INSERT INTO lg_table(pg_context_v, log_key) VALUES (stack, $1);
    RETURN 'None';
END;
$fnc_body$;

CREATE OR REPLACE VIEW v_lg_info AS
    (
    WITH cte_parse AS (SELECT *, ROW_NUMBER( ) OVER (PARTITION BY id) AS rw_rn
                       FROM (SELECT id,
                                    UNNEST( REGEXP_SPLIT_TO_ARRAY( pg_context_v, '\n' ) ) AS rw,
                                    ctx_id,
                                    ex_timestamp,
                                    log_key
                             FROM lg_table) AS t),
         cte_filter_trace_path AS (SELECT *, ( REGEXP_MATCH( rw, 'function (.*\(.*\)) line .* PERFORM' ) )[1] AS fnc_nm
                                   FROM cte_parse
                                   WHERE ( REGEXP_MATCH( rw, 'function (.*\(.*\)) line .* PERFORM' ) )[1] IS NOT NULL),
         cte_path_trace AS (SELECT *,
                                   ARRAY_AGG( fnc_nm ) OVER (PARTITION BY id ORDER BY rw_rn)       AS agg_path,
                                   ARRAY_AGG( fnc_nm ) OVER (PARTITION BY id ORDER BY rw_rn DESC ) AS reverse,
                                   COUNT( * ) OVER (PARTITION BY id )                              AS cnt_path
                            FROM cte_filter_trace_path),
         cte_top AS (SELECT *,
                            MAX( rw_rn ) OVER (PARTITION BY id) AS top_finction
                     FROM cte_path_trace c),
         cte_c1 AS (SELECT *
                    FROM cte_top
                    WHERE ARRAY_LENGTH( agg_path, 1 ) = cnt_path),
         cte_c2 AS (SELECT *
                    FROM cte_top
                    WHERE ARRAY_LENGTH( reverse, 1 ) = cnt_path),
         cte_fill_with_path AS (SELECT cte_c1.id,
                                       ARRAY_TO_STRING( cte_c2.reverse, ' -> ' ) || ' -> LOG_FUNC()' AS trace_path,
                                       cte_c2.reverse[1]                                             AS top_func,
                                       cte_c1.agg_path[1]                                            AS run_func,
                                       cte_c1.ctx_id,
                                       cte_c1.ex_timestamp,
                                       cte_c1.log_key,
                                       LEAD( cte_c1.log_key )
                                       OVER (PARTITION BY cte_c1.ctx_id ORDER BY cte_c1.id)          AS close_block,
                                       LAG( cte_c1.log_key )
                                       OVER (PARTITION BY cte_c1.ctx_id ORDER BY cte_c1.id)          AS lag_block,
                                       LEAD( cte_c1.ex_timestamp )
                                       OVER (PARTITION BY cte_c1.ctx_id ORDER BY cte_c1.id)          AS close_block_ex_time,
                                       COUNT( * ) OVER (PARTITION BY cte_c1.ctx_id,cte_c1.log_key)   AS cnt
                                FROM cte_c1
                                         INNER JOIN cte_c2 ON cte_c1.id = cte_c2.id),
         cte_with_next AS (SELECT id,
                                  trace_path,
                                  top_func,
                                  run_func,
                                  ctx_id,
                                  log_key                                             AS start_block,
                                  CASE WHEN cnt = 2 THEN log_key ELSE close_block END AS end_block,
                                  ex_timestamp,
                                  close_block_ex_time
                           FROM cte_fill_with_path
                           WHERE lag_block IS NULL
                              OR ( lag_block != log_key ))
    SELECT id,
           trace_path,
           start_block,
           end_block,
           top_func,
           run_func,
           ctx_id,
           ex_timestamp                                                                    AS start_time,
           close_block_ex_time                                                             AS end_time,
           close_block_ex_time - ex_timestamp                                              AS duration,
           MIN( ex_timestamp ) OVER (PARTITION BY ctx_id)                                  AS first_ctx_timestamp,
           MAX( COALESCE( close_block_ex_time, ex_timestamp ) ) OVER (PARTITION BY ctx_id) AS last_ctx_timestamp
    FROM cte_with_next);
