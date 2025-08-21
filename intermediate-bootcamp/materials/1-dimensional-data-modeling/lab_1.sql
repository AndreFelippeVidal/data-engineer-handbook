-- create type season_stats as (
-- 	season INTEGER,
-- 	gp INTEGER,
-- 	pts REAL,
-- 	reb REAL,
-- 	ast REAL
-- )

-- create type scoring_class AS ENUM ('star', 'good', 'average', 'bad');


-- drop table players;

-- create table players (
-- 	player_name TEXT,
-- 	height TEXT,
-- 	college TEXT,
-- 	country TEXT,
-- 	draft_year TEXT,
-- 	draft_round TEXT,
-- 	draft_number TEXT,
-- 	season_stats season_stats[],
-- 	scoring_class scoring_class,
-- 	years_since_last_season INTEGER,
-- 	current_season INTEGER,
-- 	PRIMARY KEY (player_name, current_season)
-- )

-- SELECT min(season) from player_seasons; 1996


-- Seed query for accumulation
INSERT INTO PLAYERS
WITH yesterday as (
	select * from players
	where current_season = 2000
), 
	today as (
	select * from player_seasons
	where season = 2001
	)
select 
		COALESCE(t.player_name, y.player_name) as player_name,
		COALESCE(t.height, y.height) as height,
		COALESCE(t.college, y.college) as college,
		COALESCE(t.country, y.country) as country,
		COALESCE(t.draft_year, y.draft_year) as draft_year,
		COALESCE(t.draft_round, y.draft_round) as draft_round,
		COALESCE(t.draft_number, y.draft_number) as draft_number,
		CASE WHEN y.season_stats IS NULL 
				THEN ARRAY[ROW(
							t.season,
							t.gp,
							t.pts,
							t.reb,
							t.ast
							)::season_stats]
			WHEN t.season IS NOT NULL 
				THEN y.season_stats || ARRAY[ROW(
												t.season,
												t.gp,
												t.pts,
												t.reb,
												t.ast
												)::season_stats]
		ELSE y.season_stats
		END as season_stats,
		CASE WHEN t.season IS NOT NULL THEN 
				 CASE WHEN t.pts > 20 THEN 'star'
				 	  WHEN t.pts > 15 THEN 'star'
					  WHEN t.pts > 10 THEN 'star'
					  ELSE 'bad'
				 END::scoring_class
			 ELSE y.scoring_class
		END as scoring_class,
		CASE WHEN t.season IS NOT NULL THEN 0 
			ELSE y.years_since_last_season + 1
		END as years_since_last_season,
		COALESCE(t.season, y.current_season + 1) as current_season
	from today t 
	full outer join yesterday y 
	on t.player_name = y.player_name;

-- WITH unnested as (
-- select player_name,
-- 	   UNNEST(season_stats) as season_stats
-- 	from players 
-- where current_season = 2001
-- and player_name = 'Michael Jordan')
-- select player_name,
-- 		(season_stats::season_stats).pts
-- 	from unnested;


-- select player_name, years_since_last_season, scoring_class,
-- 	   (UNNEST(season_stats)).* as season_stats
-- 	from players 
-- where current_season = 2000
-- and player_name = 'Michael Jordan'


select 
	player_name,
	(season_stats[CARDINALITY(season_stats)]).pts/
	CASE WHEN (season_stats[1]).pts = 0 THEN 1
		ELSE (season_stats[1]).pts
	END, 
	(season_stats[1]).pts as first_season_pts,
	(season_stats[CARDINALITY(season_stats)]).pts as last_season_pts
	from players
where current_season= 2001 and scoring_class = 'star'
order by 2 desc;