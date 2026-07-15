with date_generation as (

    {{
        dbt_utils.date_spine(
            datepart="day",
            start_date="cast('2019-01-01' as date)",
            end_date="add_months(current_date(), 12)"
        )
    }}

),

structure as (

    select

        {{ dbt_utils.generate_surrogate_key(['date_day']) }} as date_sk,

        date_day as date_actual,

        year(date_day) as year_actual,
        quarter(date_day) as quarter_actual,
        concat('Q', quarter(date_day)) as quarter_name,

        month(date_day) as month_actual,
        monthname(date_day) as month_name,
        date_format(date_day, 'MMM') as month_short_name,

        day(date_day) as day_of_month,
        dayofyear(date_day) as day_of_year,

        weekofyear(date_day) as week_of_year,

        dayofweek(date_day) as day_of_week_number,
        date_format(date_day, 'EEEE') as day_of_week_name,
        date_format(date_day, 'EEE') as day_of_week_short_name,

        date_trunc('week', date_day) as week_start_date,
        date_add(date_trunc('week', date_day), 6) as week_end_date,

        date_trunc('month', date_day) as month_start_date,
        last_day(date_day) as month_end_date,

        date_trunc('quarter', date_day) as quarter_start_date,
        date_sub(add_months(date_trunc('quarter', date_day), 3), 1) as quarter_end_date,

        date_trunc('year', date_day) as year_start_date,
        make_date(year(date_day), 12, 31) as year_end_date,

        case
            when dayofweek(date_day) in (1, 7) then true
            else false
        end as is_weekend,

        case
            when day(date_day) = 1 then true
            else false
        end as is_first_day_of_month,

        case
            when date_day = last_day(date_day) then true
            else false
        end as is_last_day_of_month,

        case
            when month(date_day) = 1
             and day(date_day) = 1 then true
            else false
        end as is_first_day_of_year,

        case
            when month(date_day) = 12
             and day(date_day) = 31 then true
            else false
        end as is_last_day_of_year,

        concat(
            cast(year(date_day) as string),
            '-',
            lpad(cast(month(date_day) as string), 2, '0')
        ) as year_month,

        concat(
            cast(year(date_day) as string),
            '-Q',
            quarter(date_day)
        ) as year_quarter,

        concat(
            lpad(cast(day(date_day) as string), 2, '0'),
            '/',
            lpad(cast(month(date_day) as string), 2, '0'),
            '/',
            cast(year(date_day) as string)
        ) as date_label

    from date_generation

)

select *
from structure