with renamed as (
    select
        cast(date as date) as transaction_date,
        cast(amount as double) as transaction_amount,
        cast(transaction_id as string) as transaction_id,
        cast(description as string) as transaction_description,
        cast(source_file as string) as source_file
    from {{ source('nubank_purchases', 'debit_transactions') }}
),

applying_logic as (
    select
        'Débito' as transaction_category,
        transaction_date,
        transaction_amount,
        transaction_id,
        transaction_description,
        source_file,
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
),

is_credit_pix as (
    select transaction_id
    from generating_sk
    group by transaction_id
    having count(*) > 1
),

transformed as (
    select
        gs.*,
        case
            when ic.transaction_id is null then 0
            else row_number() over (partition by gs.transaction_id order by gs.transaction_amount)
        end as dedup_flag
    from generating_sk gs
    left join is_credit_pix ic
        on gs.transaction_id = ic.transaction_id
),

final as (
    select
        *,
        case
            when dedup_flag = 0 then 0
            else row_number() over (partition by transaction_date, recipient_name order by abs(transaction_amount)) 
        end as transaction_order
    from transformed
    where dedup_flag between 0 and 1
)

select * from final
