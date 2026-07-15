with nubank_transactions as (
    select *
    from {{ ref('int__nubank_transactions') }}
),

date_info as (
    select *
    from {{ ref('stg__dates') }}
),

base as (
    select
        nu.transaction_sk,
        da.date_sk,
        nu.competency_month,
        nu.transaction_date,
        nu.transaction_category,
        nu.transaction_description,
        nu.transaction_amount,
        nu.recipient_name
    from nubank_transactions nu
    left join date_info da
        on nu.transaction_date = da.date_actual
)

select * from base