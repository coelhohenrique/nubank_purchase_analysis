with renamed as (
    select
        cast(date as date) as transaction_date,
        cast(amount as double) as transaction_amount,
        cast(transaction_id as string) as transaction_id,
        cast(description as string) as transaction_description
    from {{ source('nubank_purchases', 'transactions') }}
)

select *from renamed
