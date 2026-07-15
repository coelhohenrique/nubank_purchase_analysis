with excluding_sks_card_invoice_payments as (
    select distinct
        de.debit_card_sk
    from {{ ref('stg__nubank_credit_card') }} cr
    inner join {{ ref('stg__nubank_debit_card') }} de
        on cr.card_payment_sk = de.card_payment_sk
    where de.transaction_category = 'Débito'
),

debit as (
    select
        de.debit_card_sk as transaction_sk,
        de.transaction_category,
        de.transaction_date,
        de.transaction_type,
        de.transaction_description,
        de.transaction_amount,
        de.recipient_name,
        de.competency_month,
        de.source_file
    from {{ ref('stg__nubank_debit_card') }} de
    left join excluding_sks_card_invoice_payments ex_sk
        on de.debit_card_sk = ex_sk.debit_card_sk
    where de.is_credit_pix = false and ex_sk.debit_card_sk is null
),

credit as (
    select
        cr.credit_card_sk as transaction_sk,
        cr.transaction_category,
        cr.transaction_date,
        cr.transaction_type,
        case
            when cr.transaction_type = 'Pagamento de fatura' then cr.transaction_type
            else cr.transaction_description
        end as transaction_description,
        case
            when cr.transaction_type = 'Pagamento de fatura' then cr.transaction_amount
            else - cr.transaction_amount
        end as transaction_amount,
        cr.recipient_name,
        cr.competency_month,
        cr.source_file
    from {{ ref('stg__nubank_credit_card') }} cr
),

unioned as (
   
    select * from debit

    union all

    select * from credit
    
)

select * from unioned