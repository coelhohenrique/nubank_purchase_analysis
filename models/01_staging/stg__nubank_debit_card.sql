with renamed as (
    select
        cast(date as date) as transaction_date,
        cast(amount as double) as transaction_amount,
        cast(transaction_id as string) as transaction_id,
        cast(description as string) as transaction_description
    from {{ source('nubank_purchases', 'debit_transactions') }}
),

applying_logic as (
    select
        'Débito' as transaction_category,
        transaction_date,
        transaction_amount,
        transaction_id,
        transaction_description,
        case
            when transaction_description ilike '%Transferência Recebida - HEN.CO DESENVOLVIMENTO LTDA%' then 'Recebimento de Salário'
            when transaction_description ilike '%Pagamento de fatura%' then 'Pagamento de fatura'
            when transaction_description ilike '%Aplicação RDB%' then 'Aplicação em caixinha'
            when transaction_description ilike '%Transferência enviada pelo Pix%' then 'Pagamento PIX'
            when transaction_description ilike '%Compra no débito%' then 'Compra no débito'
            when transaction_description ilike '%Transferência Recebida%' then 'Recebimento PIX'
            when transaction_description ilike '%Resgate RDB%' then 'Resgate em caixinha'
            when transaction_description ilike '%Valor adicionado na conta por cartão de crédito%' then 'Adição para pagamento PIX no Crédito'
            when transaction_description ilike '%Débito em conta%' then 'Débito em conta'
            else null
        end as transaction_type,
        trim(
            replace(
                get(split(transaction_description, ' - '), 1),
                '(Transferência enviada)',
                ''
            )
        ) as recipient_name,
        date_format(transaction_date, 'MM/yyyy') as competency_month
    from renamed
),

generating_sk as (
    select
        {{ dbt_utils.generate_surrogate_key(['transaction_id']) }} as debit_card_sk,
        case
            when transaction_type = 'Pagamento de fatura' then {{ dbt_utils.generate_surrogate_key(['transaction_date', 'transaction_amount', 'transaction_type']) }}
            else null
        end as card_payment_sk,
        *
    from applying_logic
)

select * from generating_sk
