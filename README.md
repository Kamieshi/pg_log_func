# pg_log_func

### Example usege:

```sql
CREATE OR REPLACE FUNCTION fnc1() RETURNS TEXT
    LANGUAGE plpgsql AS
$fnc_body$
BEGIN
    PERFORM lg_func( 'block_1' );

    PERFORM PG_SLEEP( 1 );

    PERFORM lg_func( 'block_1' );

    PERFORM lg_func( 'block_2' );
    PERFORM PG_SLEEP( 1 );
    PERFORM lg_func( 'block_2' );


    PERFORM PG_SLEEP( 1 );
    PERFORM lg_func( 'block_3' );
    PERFORM PG_SLEEP( 1 );
    PERFORM lg_func( 'block_4' );
    PERFORM PG_SLEEP( 1 );
    PERFORM lg_func( 'block_4' );
    RETURN 'None';

END;
$fnc_body$;

CREATE OR REPLACE FUNCTION fnc2(arg_s TEXT) RETURNS TEXT
    LANGUAGE plpgsql AS
$fnc_body$
BEGIN
    PERFORM fnc1( );
    RETURN 'None';
END;
$fnc_body$;

CREATE OR REPLACE FUNCTION fnc3() RETURNS TEXT
    LANGUAGE plpgsql AS
$fnc_body$
BEGIN
    PERFORM fnc2( 'kek' );
    RETURN 'None';
END;
$fnc_body$;

SELECT fnc1( );
SELECT fnc2('cheburek' );
SELECT fnc3( );

select * from v_log_info;
```
| id | trace\_path | start\_block | end\_block | top\_func | run\_func | ctx\_id | start\_time | end\_time | duration | first\_ctx\_timestamp | last\_ctx\_timestamp |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_1 | block\_1 | fnc1\(\) | fnc1\(\) | 739 | 2024-05-24 14:59:46.864642 | 2024-05-24 14:59:47.866108 | 0 years 0 mons 0 days 0 hours 0 mins 1.001466 secs | 2024-05-24 14:59:46.864642 | 2024-05-24 14:59:51.873585 |
| 3 | fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_2 | block\_2 | fnc1\(\) | fnc1\(\) | 739 | 2024-05-24 14:59:47.866151 | 2024-05-24 14:59:48.867607 | 0 years 0 mons 0 days 0 hours 0 mins 1.001456 secs | 2024-05-24 14:59:46.864642 | 2024-05-24 14:59:51.873585 |
| 5 | fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_3 | block\_4 | fnc1\(\) | fnc1\(\) | 739 | 2024-05-24 14:59:49.869614 | 2024-05-24 14:59:50.872107 | 0 years 0 mons 0 days 0 hours 0 mins 1.002493 secs | 2024-05-24 14:59:46.864642 | 2024-05-24 14:59:51.873585 |
| 6 | fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_4 | block\_4 | fnc1\(\) | fnc1\(\) | 739 | 2024-05-24 14:59:50.872107 | 2024-05-24 14:59:51.873534 | 0 years 0 mons 0 days 0 hours 0 mins 1.001427 secs | 2024-05-24 14:59:46.864642 | 2024-05-24 14:59:51.873585 |
| 8 | fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_5 | null | fnc1\(\) | fnc1\(\) | 739 | 2024-05-24 14:59:51.873585 | null | null | 2024-05-24 14:59:46.864642 | 2024-05-24 14:59:51.873585 |
| 9 | fnc2\(text\) -&gt; fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_1 | block\_1 | fnc2\(text\) | fnc1\(\) | 740 | 2024-05-24 14:59:51.938429 | 2024-05-24 14:59:52.939913 | 0 years 0 mons 0 days 0 hours 0 mins 1.001484 secs | 2024-05-24 14:59:51.938429 | 2024-05-24 14:59:56.947718 |
| 11 | fnc2\(text\) -&gt; fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_2 | block\_2 | fnc2\(text\) | fnc1\(\) | 740 | 2024-05-24 14:59:52.939972 | 2024-05-24 14:59:53.942056 | 0 years 0 mons 0 days 0 hours 0 mins 1.002084 secs | 2024-05-24 14:59:51.938429 | 2024-05-24 14:59:56.947718 |
| 13 | fnc2\(text\) -&gt; fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_3 | block\_4 | fnc2\(text\) | fnc1\(\) | 740 | 2024-05-24 14:59:54.943708 | 2024-05-24 14:59:55.945530 | 0 years 0 mons 0 days 0 hours 0 mins 1.001822 secs | 2024-05-24 14:59:51.938429 | 2024-05-24 14:59:56.947718 |
| 14 | fnc2\(text\) -&gt; fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_4 | block\_4 | fnc2\(text\) | fnc1\(\) | 740 | 2024-05-24 14:59:55.945530 | 2024-05-24 14:59:56.947050 | 0 years 0 mons 0 days 0 hours 0 mins 1.00152 secs | 2024-05-24 14:59:51.938429 | 2024-05-24 14:59:56.947718 |
| 16 | fnc2\(text\) -&gt; fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_5 | null | fnc2\(text\) | fnc1\(\) | 740 | 2024-05-24 14:59:56.947718 | null | null | 2024-05-24 14:59:51.938429 | 2024-05-24 14:59:56.947718 |
| 17 | fnc3\(\) -&gt; fnc2\(text\) -&gt; fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_1 | block\_1 | fnc3\(\) | fnc1\(\) | 741 | 2024-05-24 14:59:57.017461 | 2024-05-24 14:59:58.019480 | 0 years 0 mons 0 days 0 hours 0 mins 1.002019 secs | 2024-05-24 14:59:57.017461 | 2024-05-24 15:00:02.025352 |
| 19 | fnc3\(\) -&gt; fnc2\(text\) -&gt; fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_2 | block\_2 | fnc3\(\) | fnc1\(\) | 741 | 2024-05-24 14:59:58.019513 | 2024-05-24 14:59:59.020953 | 0 years 0 mons 0 days 0 hours 0 mins 1.00144 secs | 2024-05-24 14:59:57.017461 | 2024-05-24 15:00:02.025352 |
| 21 | fnc3\(\) -&gt; fnc2\(text\) -&gt; fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_3 | block\_4 | fnc3\(\) | fnc1\(\) | 741 | 2024-05-24 15:00:00.022381 | 2024-05-24 15:00:01.023739 | 0 years 0 mons 0 days 0 hours 0 mins 1.001358 secs | 2024-05-24 14:59:57.017461 | 2024-05-24 15:00:02.025352 |
| 22 | fnc3\(\) -&gt; fnc2\(text\) -&gt; fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_4 | block\_4 | fnc3\(\) | fnc1\(\) | 741 | 2024-05-24 15:00:01.023739 | 2024-05-24 15:00:02.025278 | 0 years 0 mons 0 days 0 hours 0 mins 1.001539 secs | 2024-05-24 14:59:57.017461 | 2024-05-24 15:00:02.025352 |
| 24 | fnc3\(\) -&gt; fnc2\(text\) -&gt; fnc1\(\) -&gt; LOG\_FUNC\(\) | block\_5 | null | fnc3\(\) | fnc1\(\) | 741 | 2024-05-24 15:00:02.025352 | null | null | 2024-05-24 14:59:57.017461 | 2024-05-24 15:00:02.025352 |
