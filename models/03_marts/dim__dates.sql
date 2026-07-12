with dates as (
    select
        -- Surrogate Key
        date_sk,

        -- Base Date
        date_actual,

        -- Calendar
        year_actual,
        quarter_actual,
        quarter_name,
        month_actual,
        month_name,
        month_short_name,
        day_of_month,
        day_of_year,
        week_of_year,
        day_of_week_number,
        day_of_week_name,
        day_of_week_short_name,

        -- Period Starts / Ends
        week_start_date,
        week_end_date,
        month_start_date,
        month_end_date,
        quarter_start_date,
        quarter_end_date,
        year_start_date,
        year_end_date,

        -- Flags
        is_weekend,
        is_first_day_of_month,
        is_last_day_of_month,
        is_first_day_of_year,
        is_last_day_of_year,

        -- Labels
        year_month,
        year_quarter,
        date_label
    from {{ ref('stg__dates') }}
)

select * from dates