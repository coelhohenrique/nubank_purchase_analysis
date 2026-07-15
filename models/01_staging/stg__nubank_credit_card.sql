with renamed as (
    select
        cast(date as date) as transaction_date,
        cast(amount as double) as transaction_amount,
        cast(title as string) as transaction_description,
        cast(source_file as string) as source_file
    from {{ source('nubank_purchases', 'credit_transactions') }}
),

applying_logic as (
    select
        'Crédito' as transaction_category,
        transaction_date,
        transaction_amount,
        transaction_description,
        source_file,
        case
            when transaction_description ilike '%"IOF de%' then 'Pagamento de IOF'
            when transaction_description ilike '%Pagamento recebido%' then 'Pagamento de fatura'
            else 'Compra no crédito'
        end as transaction_type,
        case
            when transaction_description ilike '%"IOF de%' or transaction_description ilike '%Pagamento recebido%' then null
            else transaction_description
        end as recipient_name,
        date_format(
            case
                when day(transaction_date) >= 9
                    then add_months(transaction_date, 1)
                else transaction_date
            end,
            'MM/yyyy'
        ) as competency_month,
        row_number() over (partition by transaction_date, transaction_amount, transaction_description order by transaction_date) as transaction_index
    from renamed
),

generating_sk as (
    select
        {{ dbt_utils.generate_surrogate_key(['transaction_date', 'transaction_amount', 'transaction_description', 'transaction_index']) }} as credit_card_sk,
        case
            when transaction_type = 'Pagamento de fatura' then {{ dbt_utils.generate_surrogate_key(['transaction_date', 'transaction_amount', 'transaction_type']) }}
            else null
        end as card_payment_sk,
        *
    from applying_logic
)

select * from generating_sk
